//
//  VTMBabyPatchVC.m
//  VTMProductSDK
//
//  Controller：把 View 的事件绑到 SDK 指令上，把 SDK 回调交给 Model 解析，再刷新 View。
//
//  关于 0x03 姿态：协议里是设备主动上报（Slave → Master），这里只被动接收显示在顶部，
//  不提供「请求姿态」按钮。SDK 对 BabyPatch 的 0x03 一律按主动上报处理、不释放指令锁，
//  如果主动调用 baby_requestGesture，之后的指令会一直等锁发不出去。
//

#import "VTMBabyPatchVC.h"
#import "VTMBabyPatchModel.h"
#import "VTMBabyPatchView.h"
#import "VTMLocalization.h"
#import "UIViewController+VTMLanguage.h"

static NSString * const kCellIdentifier = @"VTMBabyPatchCell";
/// 单条指令（含读文件的每一包）等待应答的时间
static const NSTimeInterval kCommandTimeout = 5.0;

@interface VTMBabyPatchVC () <UITableViewDataSource, UITableViewDelegate,
                              VTMURATUtilsDelegate, VTMURATDeviceDelegate, VTBLEUtilsDelegate>
@property (nonatomic, strong) VTMBabyPatchModel *model;
@property (nonatomic, strong, readonly) VTMBabyPatchView *patchView;
@property (nonatomic, strong, nullable) MBProgressHUD *hud;
/// 等待应答的指令，用于决定何时收起 HUD（0x03 主动上报不影响它）
@property (nonatomic, strong, nullable) NSNumber *pendingCommand;
/// 每次发指令或收到读文件进度时递增，用来让过期的超时检查失效
@property (nonatomic, assign) NSUInteger timeoutGeneration;
@property (nonatomic, assign) BOOL didAutoProbe;
/// 自动探测进行中：设备信息应答后接着发运行参数
@property (nonatomic, assign) BOOL autoProbePending;
/// 标题状态，切换语言时用来重新生成标题
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, copy, nullable) NSString *deviceName;
@end

@implementation VTMBabyPatchVC

#pragma mark - 生命周期

- (void)loadView {
    self.view = [[VTMBabyPatchView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (VTMBabyPatchView *)patchView {
    return (VTMBabyPatchView *)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.model = [[VTMBabyPatchModel alloc] init];
    self.connected = YES;
    self.deviceName = [VTBLEUtils sharedInstance].device.advName;

    // 事件绑定
    self.patchView.tableView.dataSource = self;
    self.patchView.tableView.delegate = self;
    [self.patchView.clearLogButton addTarget:self action:@selector(clearLogTapped:)
                            forControlEvents:UIControlEventTouchUpInside];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageDidChange:)
                                                 name:VTMLanguageDidChangeNotification object:nil];

    [self applyLocalization];
#ifdef VTM_BABY_PATCH_V3
    [self log:VTMLocalized(@"baby.log.connectedV3")];
#else
    [self log:VTMLocalized(@"baby.log.connectedV1Only")];
#endif
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 多语言

- (void)languageDidChange:(NSNotification *)note {
    [self.model reloadLocalizedContent];
    [self applyLocalization];
    [self log:VTMLocalized(@"baby.log.languageChanged")];
}

/// 按当前语言刷新本页所有静态文案。日志里已写入的行保持原语言
- (void)applyLocalization {
    [self updateTitle];
    self.navigationItem.leftBarButtonItem = [self vtm_makeLanguageBarButtonItem];
    UIBarButtonItem *disconnect = [[UIBarButtonItem alloc] initWithTitle:VTMLocalized(@"baby.nav.disconnect")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self action:@selector(disconnectTapped:)];
    disconnect.accessibilityHint = VTMLocalized(@"baby.nav.disconnect.hint");
    self.navigationItem.rightBarButtonItem = disconnect;
    [self.patchView applyLocalization];
    [self.patchView.tableView reloadData];
    [self.patchView showLiveText:[self.model liveText]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [VTMProductURATUtils sharedInstance].delegate = self;
    [VTMProductURATUtils sharedInstance].deviceDelegate = self;
    [VTBLEUtils sharedInstance].delegate = self;

    // 首次进入自动探测：设备信息（看固件版本）→ 运行参数（按长度判定一代 / V3）。
    // 稍等一下再发，让连接页发起的加密握手先完成。
    if (!self.didAutoProbe) {
        self.didAutoProbe = YES;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self.view.window) {
                return; // 已经点了「断开」离开本页
            }
            [self log:VTMLocalized(@"baby.log.autoProbe")];
            self.autoProbePending = YES;
            [self performAction:VTMBabyPatchActionDeviceInfo sourceView:self.view];
        });
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 弹出 UIAlertController 不会触发 viewDidDisappear，只有页面真正离开时才解绑
    [VTMProductURATUtils sharedInstance].delegate = nil;
    [VTMProductURATUtils sharedInstance].deviceDelegate = nil;
}

#pragma mark - UITableViewDataSource / Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.model.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.model.sections[section].items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.model.sections[section].title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
        cell.detailTextLabel.numberOfLines = 0;
    }
    VTMBabyPatchMenuItem *item = self.model.sections[indexPath.section].items[indexPath.row];
    cell.textLabel.text = item.title;
    cell.textLabel.textColor = item.destructive ? UIColor.redColor : nil;
    cell.detailTextLabel.text = item.subtitle;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    VTMBabyPatchMenuItem *item = self.model.sections[indexPath.section].items[indexPath.row];
    [self performAction:item.action sourceView:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - 用户操作

- (void)performAction:(VTMBabyPatchAction)action sourceView:(UIView *)sourceView {
    VTMProductURATUtils *util = [VTMProductURATUtils sharedInstance];
    switch (action) {
        case VTMBabyPatchActionDeviceInfo: {
            [self send:VTMBLECmdGetDeviceInfo block:^{ [util requestDeviceInfo]; }];
            break;
        }
        case VTMBabyPatchActionSyncTime: {
            [self send:VTMBLECmdSyncTime block:^{ [util syncTime:[NSDate date]]; }];
            break;
        }
        case VTMBabyPatchActionFactoryReset: {
            [self confirmFactoryReset];
            break;
        }
        case VTMBabyPatchActionGetConfig: {
            [self send:VTMBabyCmdGetConfig block:^{ [util baby_requestConfig]; }];
            break;
        }
        case VTMBabyPatchActionSetConfig: {
            [self chooseSettingFrom:sourceView];
            break;
        }
        case VTMBabyPatchActionRunParams: {
            [self send:VTMBabyCmdGetRunParams block:^{ [util baby_requestRunParams]; }];
            break;
        }
        case VTMBabyPatchActionBuzzer: {
#ifdef VTM_BABY_PATCH_V3
            [self inputBuzzer];
#endif
            break;
        }
        case VTMBabyPatchActionFileList: {
            [self send:VTMBLECmdGetFileList block:^{ [util requestFilelist]; }];
            break;
        }
    }
}

/// 断开并回到扫描页，用来切换到另一台设备（例如一代和 V3 对比测试）。
/// 主动断开时 VTBLEUtils 收到的 error 为 nil，不会触发自动重连。
- (void)disconnectTapped:(UIBarButtonItem *)sender {
    VTMProductURATUtils *util = [VTMProductURATUtils sharedInstance];
    util.delegate = nil;
    util.deviceDelegate = nil;
    self.autoProbePending = NO;
    self.pendingCommand = nil;
    [self hideHUD];

    // 先换根控制器：扫描页在 viewDidLoad 里同步接管 VTBLEUtils.delegate（assign 属性），
    // 再断开，断开回调就不会落到即将释放的本页面上
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIApplication.sharedApplication.delegate.window.rootViewController = [storyboard instantiateInitialViewController];
    [[VTBLEUtils sharedInstance] cancelConnect];
}

- (void)clearLogTapped:(UIButton *)sender {
    [self.model clearLogs];
    [self.patchView showLogText:@""];
}

/// 统一的发指令入口：登记等待的指令、显示 HUD、写日志。上一条还没应答时不发，返回 NO。
- (BOOL)send:(u_char)cmd block:(void (^)(void))block {
    if (self.pendingCommand) {
        [self log:[NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.busy"),
                   [VTMBabyPatchModel nameForCommand:self.pendingCommand.unsignedCharValue]]];
        return NO;
    }
    self.pendingCommand = @(cmd);
    [self showHUD:[VTMBabyPatchModel nameForCommand:cmd]];
    [self log:[NSString stringWithFormat:@"→ %@", [VTMBabyPatchModel nameForCommand:cmd]]];
    [self armTimeout];
    block();
    return YES;
}

/// SDK 本身没有指令超时；设备不应答时 HUD 会一直挂着，这里给页面兜底。
/// 只释放页面状态，SDK 内部的指令锁不受影响，之后的指令仍可能排队等待。
- (void)armTimeout {
    NSUInteger generation = ++self.timeoutGeneration;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kCommandTimeout * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (generation != self.timeoutGeneration || !self.pendingCommand) {
            return;
        }
        u_char cmd = self.pendingCommand.unsignedCharValue;
        self.pendingCommand = nil;
        [self.model cancelDownload];
        [self hideHUD];
        [self log:[NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.timeout"),
                   [VTMBabyPatchModel nameForCommand:cmd], kCommandTimeout]];
        [self continueAutoProbeAfter:cmd];
    });
}

- (void)confirmFactoryReset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:VTMLocalized(@"baby.menu.factoryReset")
                                                                   message:VTMLocalized(@"baby.alert.reset.message")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"common.cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"baby.alert.reset.confirm")
                                              style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self send:VTMBLECmdRestore block:^{ [[VTMProductURATUtils sharedInstance] factoryReset]; }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)chooseSettingFrom:(UIView *)sourceView {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:VTMLocalized(@"baby.alert.chooseSetting")
                                                                   message:self.model.hasConfig ? nil : VTMLocalized(@"baby.alert.chooseSetting.noConfig")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (VTMBabyPatchSettingItem *item in self.model.settingItems) {
        NSNumber *current = [self.model currentValueForSetting:item];
        NSString *title = current ? [NSString stringWithFormat:VTMLocalized(@"baby.fmt.setting.current"), item.title, current]
                                  : item.title;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self inputValueForSetting:item];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"common.cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet from:sourceView];
}

- (void)inputValueForSetting:(VTMBabyPatchSettingItem *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:item.title
                                                                   message:item.hint
                                                            preferredStyle:UIAlertControllerStyleAlert];
    NSNumber *current = [self.model currentValueForSetting:item];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.placeholder = [NSString stringWithFormat:@"%ld - %ld", (long)item.minValue, (long)item.maxValue];
        textField.text = current.stringValue;
        textField.accessibilityLabel = item.title;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"common.cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"baby.alert.send") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        VTMOxiParamsOption option;
        NSString *error = [self.model validateSetting:item input:weakAlert.textFields.firstObject.text ?: @""
                                               option:&option];
        if (error) {
            [self showMessage:error];
            return;
        }
        BOOL sent = [self send:VTMBabyCmdSetConfig block:^{
            self.model.pendingSetting = item;
            [[VTMProductURATUtils sharedInstance] baby_syncConfigParam:option];
        }];
        if (sent) {
            [self log:[NSString stringWithFormat:@"  %@ = %u (type %u)", item.title, option.param.val, item.type]];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#ifdef VTM_BABY_PATCH_V3
- (void)inputBuzzer {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:VTMLocalized(@"baby.menu.buzzer")
                                                                   message:VTMLocalized(@"baby.alert.buzzer.message")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    NSArray *placeholders = @[VTMLocalized(@"baby.alert.buzzer.on"),
                              VTMLocalized(@"baby.alert.buzzer.time"),
                              VTMLocalized(@"baby.alert.buzzer.intensity")];
    NSArray *defaults = @[@"1", @"5", @"50"];
    for (NSUInteger i = 0; i < placeholders.count; i++) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.placeholder = placeholders[i];
            textField.text = defaults[i];
            textField.accessibilityLabel = placeholders[i];
        }];
    }
    [alert addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"common.cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak UIAlertController *weakAlert = alert;
    [alert addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"baby.alert.send") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSArray<UITextField *> *fields = weakAlert.textFields;
        VTMBabyBuzzerInfo info;
        NSString *error = [self.model validateBuzzerOn:fields[0].text ?: @""
                                                  time:fields[1].text ?: @""
                                             intensity:fields[2].text ?: @""
                                                  info:&info];
        if (error) {
            [self showMessage:error];
            return;
        }
        BOOL sent = [self send:VTMBabyCmdBuzzer block:^{
            [[VTMProductURATUtils sharedInstance] baby_controlBuzzer:info];
        }];
        if (sent) {
            [self log:[NSString stringWithFormat:@"  on=%u time=%us intensity=%u", info.on, info.time, info.sound_intens]];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
#endif

- (void)chooseFileToDownload {
    NSArray<NSString *> *names = self.model.fileNames;
    if (names.count == 0) {
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:VTMLocalized(@"baby.alert.chooseFile")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *name in names) {
        [sheet addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self.model prepareDownload:name];
            [self send:VTMBLECmdStartRead block:^{
                [[VTMProductURATUtils sharedInstance] prepareReadFile:name];
            }];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"common.cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentSheet:sheet from:self.patchView.tableView];
}

#pragma mark - VTMURATUtilsDelegate

- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType
    response:(NSData *)response {
    if (deviceType != VTMDeviceTypeBabyPatch) {
        return;
    }
    // 0x03 是设备主动上报，频率高，只刷新顶部状态，不写日志、不影响 HUD
    if (cmdType == VTMBabyCmdGetGesture) {
        [self.model applyAttitude:response ?: [NSData data]];
        NSString *live = [self.model liveText];
        [self onMain:^{ [self.patchView showLiveText:live]; }];
        return;
    }

    VTMProductURATUtils *shared = [VTMProductURATUtils sharedInstance];
    switch (cmdType) {
        case VTMBLECmdGetDeviceInfo:
            [self finish:cmdType log:[self.model applyDeviceInfo:response]];
            break;
        case VTMBLECmdSyncTime:
            [self finish:cmdType log:VTMLocalized(@"baby.log.syncTimeDone")];
            break;
        case VTMBLECmdRestore:
            [self finish:cmdType log:VTMLocalized(@"baby.log.resetDone")];
            break;
        case VTMBabyCmdGetConfig:
            [self finish:cmdType log:[self.model applyConfig:response]];
            break;
        case VTMBabyCmdSetConfig: {
            NSString *name = self.model.pendingSetting.title ?: @"";
            self.model.pendingSetting = nil;
            [self finish:cmdType log:[NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.setDone"), name]];
            break;
        }
        case VTMBabyCmdGetRunParams:
            [self finish:cmdType log:[self.model applyRunParams:response]];
            break;
#ifdef VTM_BABY_PATCH_V3
        case VTMBabyCmdBuzzer:
            [self finish:cmdType log:VTMLocalized(@"baby.log.buzzerDone")];
            break;
#endif
        case VTMBLECmdGetFileList: {
            NSString *text = [self.model applyFileList:response];
            [self finish:cmdType log:text];
            if (self.model.fileNames.count > 0) {
                [self onMain:^{ [self chooseFileToDownload]; }];
            }
            break;
        }
        // ── 读文件：沿用 Demo 其它页面的写法，在回调里同步发下一条读指令 ──
        case VTMBLECmdStartRead: {
            VTMOpenFileReturn ret = [VTMBLEParser parseFileLength:response];
            [self.model beginDownloadWithLength:ret.file_size];
            [self log:[NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.fileLength"), ret.file_size]];
            self.pendingCommand = @(VTMBLECmdEndRead); // 整个读取流程结束前保持 HUD
            [self onMain:^{ [self armTimeout]; }];
            if (ret.file_size == 0) {
                [shared endReadFile];
            } else {
                [shared readFile:0];
            }
            break;
        }
        case VTMBLECmdReadFile: {
            [self.model appendDownloadData:response];
            u_int done = self.model.downloadedLength, total = self.model.expectedLength;
            [self onMain:^{
                self.hud.label.text = [NSString stringWithFormat:VTMLocalized(@"baby.fmt.hud.downloading"), done, total];
                [self armTimeout];
            }];
            if ([self.model isDownloadComplete]) {
                [shared endReadFile];
            } else {
                [shared readFile:done];
            }
            break;
        }
        case VTMBLECmdEndRead: {
            NSString *text = self.model.downloadingFileName ? [self.model finishDownload]
                                                            : VTMLocalized(@"baby.log.readAborted");
            [self finish:VTMBLECmdEndRead log:text];
            break;
        }
        default:
            [self finish:cmdType log:[NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.response"),
                                      [VTMBabyPatchModel nameForCommand:cmdType], (unsigned long)response.length]];
            break;
    }
}

- (void)util:(VTMURATUtils *)util commandFailed:(u_char)cmdType deviceType:(VTMDeviceType)deviceType
  failedType:(VTMBLEPkgType)type {
    NSString *text = [NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.failed"),
                      [VTMBabyPatchModel nameForCommand:cmdType], [VTMBabyPatchModel descriptionForFailure:type]];
    if (cmdType == VTMBLECmdReadFile) {
        // 读到一半失败：结束本次读取，让设备关闭文件
        [self.model cancelDownload];
        self.pendingCommand = @(VTMBLECmdEndRead);
        [self log:text];
        [self onMain:^{ [self armTimeout]; }];
        [[VTMProductURATUtils sharedInstance] endReadFile];
        return;
    }
    if (cmdType == VTMBLECmdStartRead) {
        [self.model cancelDownload];
    }
    if (cmdType == VTMBabyCmdSetConfig) {
        self.model.pendingSetting = nil;
    }
    [self finish:cmdType log:text];
}

- (void)util:(VTMURATUtils *)util commandSendFailed:(u_char)errorCode {
    [self.model cancelDownload];
    self.pendingCommand = nil;
    self.autoProbePending = NO;
    [self log:[NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.sendFailed"),
               [VTMBabyPatchModel descriptionForSendError:errorCode]]];
    [self onMain:^{ [self hideHUD]; }];
}

/// 一条指令结束：写日志，若是正在等待的指令则收起 HUD。
/// 不是当前等待的指令（如重连后的握手应答）只写日志。
- (void)finish:(u_char)cmd log:(NSString *)text {
    if (self.pendingCommand && self.pendingCommand.unsignedCharValue == cmd) {
        self.pendingCommand = nil;
    }
    BOOL idle = (self.pendingCommand == nil);
    [self log:text];
    NSString *live = [self.model liveText]; // 运行参数 / 配置 / 记录文件都可能更新协议判定
    [self onMain:^{
        [self.patchView showLiveText:live];
        if (idle) {
            [self hideHUD];
        }
    }];
    [self continueAutoProbeAfter:cmd];
}

/// 自动探测的第二步。设备信息不论成功失败都接着发运行参数，运行参数结束即探测结束。
/// 异步到下一轮主循环再发：此时本次应答的分发已结束，pendingCommand 也已清掉。
- (void)continueAutoProbeAfter:(u_char)cmd {
    if (!self.autoProbePending) {
        return;
    }
    if (cmd == VTMBabyCmdGetRunParams) {
        self.autoProbePending = NO;
        [self log:[self.model generationSummary]];
        return;
    }
    if (cmd == VTMBLECmdGetDeviceInfo) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self.autoProbePending || !self.view.window) {
                return;
            }
            [self performAction:VTMBabyPatchActionRunParams sourceView:self.view];
        });
    }
}

#pragma mark - VTMURATDeviceDelegate（自动重连后重新握手）

- (void)utilDeployCompletion:(VTMURATUtils *)util {
    [util openupEncryptWithToken:@"" secretKey:@""];
    [self log:VTMLocalized(@"baby.log.reconnected")];
}

- (void)utilDeployFailed:(VTMURATUtils *)util {
    [self log:VTMLocalized(@"baby.log.reconnectFailed")];
}

#pragma mark - VTBLEUtilsDelegate

- (void)didConnectedDevice:(VTDevice *)device {
    self.connected = YES;
    self.deviceName = device.rawPeripheral.name;
    [self updateTitle];
    [[VTMProductURATUtils sharedInstance] setPeripheral:device.rawPeripheral advertisementData:device.adv];
}

- (void)didDisconnectedDevice:(VTDevice *)device andError:(NSError *)error {
    self.connected = NO;
    self.deviceName = device.rawPeripheral.name ?: self.deviceName;
    [self updateTitle];
    [self.model cancelDownload];
    self.pendingCommand = nil;
    self.autoProbePending = NO;
    [self log:error ? [NSString stringWithFormat:VTMLocalized(@"baby.fmt.log.disconnectedError"), error.localizedDescription]
                    : VTMLocalized(@"baby.log.disconnected")];
    [self onMain:^{ [self hideHUD]; }];
}

#pragma mark - View 辅助

- (void)log:(NSString *)text {
    [self.model appendLog:text];
    NSString *all = self.model.logText;
    [self onMain:^{ [self.patchView showLogText:all]; }];
}

- (void)updateTitle {
    NSString *key = self.connected ? @"baby.fmt.title.connected" : @"baby.fmt.title.disconnected";
    NSString *title = [NSString stringWithFormat:VTMLocalized(key), self.deviceName ?: @"BabyPatch"];
    [self onMain:^{ self.title = title; }];
}

- (void)showHUD:(NSString *)text {
    [self hideHUD];
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.label.text = text;
}

- (void)hideHUD {
    [self.hud hideAnimated:YES];
    self.hud = nil;
}

- (void)showMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"common.ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

/// iPad 上 action sheet 必须指定弹出位置
- (void)presentSheet:(UIAlertController *)sheet from:(UIView *)sourceView {
    sheet.popoverPresentationController.sourceView = sourceView ?: self.view;
    sheet.popoverPresentationController.sourceRect = (sourceView ?: self.view).bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

/// SDK 回调目前在主线程（CBCentralManager 的 queue 为 nil），这里兜底
- (void)onMain:(dispatch_block_t)block {
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@end
