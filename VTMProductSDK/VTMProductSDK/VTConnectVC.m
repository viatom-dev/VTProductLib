//
//  VTConnectVC.m
//  VTMProductSDK
//
//  Created by viatom on 2020/6/22.
//  Copyright © 2020 viatom. All rights reserved.
//

#import "VTConnectVC.h"
#import "VTBLEUtils.h"
#import "VTMECGMenuVC.h"
#import "VTMBPMenuVC.h"
#import "VTMScaleMenuVC.h"
#import "AppDelegate.h"
#import "VTMDeviceRouting.h"
#import "VTMCommShared.h"

// 同时实现两套通信模块的 delegate：
//   Module A  VTMURATDeviceDelegate + VTMURATUtilsDelegate
//   Module B  VTO2CommunicateDelegate
// 连上之后只有一套会收到回调，取决于 VTMDeviceRouting 把设备路由到了哪个模块。
@interface VTConnectVC ()<UITableViewDelegate, UITableViewDataSource, VTBLEUtilsDelegate,
                          VTMURATDeviceDelegate, VTMURATUtilsDelegate,
                          VTO2CommunicateDelegate>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (nonatomic, strong) NSMutableArray *deviceListArray;
@property (nonatomic, strong) NSMutableArray *deviceIDArray;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

/// 正在连接的设备用哪个模块。在 didSelectRow 时定下来，didConnectedDevice 时照此分流。
@property (nonatomic, assign) VTMCommModule pendingModule;

/// 手动指定「改用 Module A 连接」的设备（key 为外设 identifier 字符串）。
///
/// 兜底用：二代设备绝大多数会在广播包里带协议版本，所以自动判定通常够用。
/// 但万一遇到二代设备没发广播包（iOS 重连已配对设备时也可能拿不到），
/// 自动判定会退化成 Module B —— 能通但走的是转包路径。这时可以长按列表项强制切换。
@property (nonatomic, strong) NSMutableSet<NSString *> *forcedURATDevices;
@end

@implementation VTConnectVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Scaner";
    [_myTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:54 green:216 blue:192 alpha:1]];
    [VTBLEUtils sharedInstance].delegate = self;

    self.forcedURATDevices = [NSMutableSet set];

    // 长按列表项可以为单个设备强制切换通信模块，见 forcedURATDevices 的说明
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [_myTableView addGestureRecognizer:longPress];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [VTMProductURATUtils sharedInstance].deviceDelegate = self;
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [VTMProductURATUtils sharedInstance].deviceDelegate = nil;
}

- (NSMutableArray *)deviceListArray{
    if (!_deviceListArray) {
        _deviceListArray = [NSMutableArray arrayWithCapacity:10];
    }
    return _deviceListArray;
}

#pragma mark --  tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.deviceListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"deviceList";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    VTDevice *device = self.deviceListArray[indexPath.row];
    cell.textLabel.text = device.rawPeripheral.name;

    // 把路由结果直接显示出来：该走哪个模块、广播包报的是几代。
    // 这是排查「设备为什么走了这条路径」最快的入口。
    VTMDeviceRoute route = [self routeForDevice:device];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@ · %@",
                                 [VTMDeviceRouting descriptionForModule:route.module],
                                 [VTMDeviceRouting descriptionForGeneration:route.generation],
                                 device.RSSI];
    return cell;
}

/// 设备的最终路由 = 自动判定结果，再叠加手动强制项
- (VTMDeviceRoute)routeForDevice:(VTDevice *)device {
    VTMDeviceRoute route = [VTMDeviceRouting routeForDeviceName:device.rawPeripheral.name
                                              advertisementData:device.adv];
    NSString *key = device.rawPeripheral.identifier.UUIDString;
    if (route.module == VTMCommModuleO2 && [self.forcedURATDevices containsObject:key]) {
        // 手动强制走 Module A。设备类型交给 SDK 连上后自己判，
        // 对于靠 VTMURATDeviceExtension 扩展识别的名字会得到 WOxi。
        route.module = VTMCommModuleURAT;
    }
    return route;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    VTDevice *device = self.deviceListArray[indexPath.row];
    VTMDeviceRoute route = [self routeForDevice:device];

    if (route.module == VTMCommModuleUnsupported) {
        [self showAlertWithTitle:@"This device is not supported." message:nil handler:nil];
        return;
    }

    self.pendingModule = route.module;
    [self.progressHUD showAnimated:YES];
    [[VTBLEUtils sharedInstance] stopScan];
    [[VTBLEUtils sharedInstance] connectToDevice:device];
}

#pragma mark -- 手动切换模块（兜底）

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    NSIndexPath *indexPath = [_myTableView indexPathForRowAtPoint:[gesture locationInView:_myTableView]];
    if (!indexPath || indexPath.row >= self.deviceListArray.count) {
        return;
    }

    VTDevice *device = self.deviceListArray[indexPath.row];
    VTMDeviceRoute autoRoute = [VTMDeviceRouting routeForDeviceName:device.rawPeripheral.name
                                                  advertisementData:device.adv];
    // 只有自动判定落在 Module B 的设备才需要这个开关。
    // 本来就走 Module A 的设备没有另一条路可切。
    if (autoRoute.module != VTMCommModuleO2) {
        return;
    }

    NSString *key = device.rawPeripheral.identifier.UUIDString;
    BOOL forced = [self.forcedURATDevices containsObject:key];
    NSString *title = forced ? @"Use VTO2Communicate" : @"Use VTMURATUtils (woxi_*)";

    UIAlertController *sheet =
        [UIAlertController alertControllerWithTitle:device.rawPeripheral.name
                                            message:@"Override the communication module for this device."
                                     preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:title
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        if (forced) {
            [self.forcedURATDevices removeObject:key];
        } else {
            [self.forcedURATDevices addObject:key];
        }
        [self->_myTableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}
#pragma mark --  ble
- (void)updateBleState:(VTBLEState)state{
    if (state == VTBLEStatePoweredOn) {
        [[VTBLEUtils sharedInstance] startScan];
    }
}

- (void)didDiscoverDevice:(VTDevice *)device{
    NSUUID *identifier = [device.rawPeripheral identifier];
    if ([_deviceIDArray containsObject:identifier]) {
        NSUInteger index = [_deviceIDArray indexOfObject:identifier];
        [_deviceListArray replaceObjectAtIndex:index withObject:device];
        [_myTableView beginUpdates];
        [_myTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [_myTableView endUpdates];
    }else{
        [_deviceListArray addObject:device];
        [_deviceIDArray addObject:identifier];
        [_myTableView reloadData];
    }
}

- (void)didConnectedDevice:(VTDevice *)device{
    DLog(@"Connected：%@  module=%@", device.rawPeripheral.name,
         [VTMDeviceRouting descriptionForModule:self.pendingModule]);

    // 两个模块的通信对象是不同的类、不同的 delegate 协议，没有共同基类，
    // 所以分流必须发生在创建通信对象之前 —— 也就是这里。
    //
    // 两处都要用 setPeripheral:advertisementData: 而不是直接赋值 peripheral：
    // 加密设备缺了广播数据无法正确识别类型。
    if (self.pendingModule == VTMCommModuleO2) {
        [VTMCommShared sharedInstance].o2Delegate = self;
        [[VTMCommShared sharedInstance] setPeripheral:device.rawPeripheral
                                    advertisementData:device.adv];
    } else {
        [[VTMProductURATUtils sharedInstance] setPeripheral:device.rawPeripheral
                                         advertisementData:device.adv];
    }
}

/// @brief This device has been disconnected. Note: If error == nil ，user manually disconnect.
- (void)didDisconnectedDevice:(VTDevice *)device andError:(NSError *)error{
    
}

#pragma mark ---deviceDelegate
- (void)utilDeployFailed:(VTMURATUtils *)util{
    [_progressHUD hideAnimated:YES];
    [self showAlertWithTitle:@"Failed" message:nil handler:^(UIAlertAction *action) {
        [[VTBLEUtils sharedInstance] startScan];
    }];
}

- (void)utilDeployCompletion:(VTMURATUtils *)util{
    [_progressHUD hideAnimated:YES];

    // 加密设备必须先完成握手，否则后续指令全部失败。
    //
    // 这一步对二代血氧尤其关键：二代设备绝大多数是加密的，走 Module A 时如果
    // 跳过握手，woxi_* 会一条都发不出去 —— 看起来像「二代走 Module A 不通」，
    // 其实只是没握手。
    //
    // 两个参数都传 @"" 表示使用 SDK 内置的默认凭证（1.5.7 起支持）。
    // 有自己的 token/secretKey 就填在这里。
    //
    // 非加密设备上这一步是安全的：SDK 内部走 secretUnsupport 直接返回，
    // 本类没有实现 commandFailed:，所以不会弹多余的提示。
    [util openupEncryptWithToken:@"" secretKey:@""];

    [self showAlertWithTitle:@"Completion" message:nil handler:^(UIAlertAction *action) {
        AppDelegate *appDelagete = [UIApplication sharedApplication].delegate;
        if (util.currentType == VTMDeviceTypeWOxi || util.currentType == VTMDeviceTypeFOxi) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
            UITabBarController *tabBarController = [storyboard instantiateViewControllerWithIdentifier:@"myTabBarController"];
            appDelagete.window.rootViewController = tabBarController;
        } else if (util.currentType == VTMDeviceTypeBP){
            VTMBPMenuVC *vc = [[VTMBPMenuVC alloc]init];
           UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
           appDelagete.window.rootViewController = nav;
        }else if (util.currentType == VTMDeviceTypeScale){
            VTMScaleMenuVC *vc = [[VTMScaleMenuVC alloc]init];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
            appDelagete.window.rootViewController = nav;
        }else{
            VTMECGMenuVC *vc =  [[VTMECGMenuVC alloc]init];
            UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:vc];
            appDelagete.window.rootViewController = nav;
            
        }
    }];
}

#pragma mark -- VTO2CommunicateDelegate（Module B）

- (void)o2_serviceDeployed:(BOOL)completed {
    [_progressHUD hideAnimated:YES];

    if (!completed) {
        [self showAlertWithTitle:@"Failed" message:nil handler:^(UIAlertAction *action) {
            [[VTBLEUtils sharedInstance] startScan];
        }];
        return;
    }

    // 加密设备需要先做握手。
    //
    // 两个参数都传 @"" 表示使用 SDK 内置的默认凭证（1.5.7 起支持）。
    // 有 Viatom 颁发的 token/secretKey 就填在这里 —— 注意不能填
    // @"0xXXXX" 这类占位串：那是非空字符串，SDK 不会回落到默认凭证，
    // 会把它当真凭证解析成乱码，握手必然失败。
    NSString *token = @"";
    NSString *secretKey = @"";
    [[VTMCommShared sharedInstance] openupEncryptWithToken:token secretKey:secretKey];
}

- (void)openupEncryptResult:(VTCommonResult)result {
    // 不论握手成功还是设备本来就不加密，都进入 O2 功能菜单。
    // 真正的权限问题会在后续指令的回调里体现。
    [self enterO2Menu];
}

/// 进入 Module B 的功能页。
///
/// Module B 的整套 UI 来自原 VTO2Lib，是 storyboard + segue 驱动的，
/// 所以原样保留成独立的 O2.storyboard，按 storyboardIdentifier 实例化入口页，
/// 不去和 Main.storyboard 合并 XML。
- (void)enterO2Menu {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"O2" bundle:[NSBundle mainBundle]];
    UIViewController *menu = [storyboard instantiateViewControllerWithIdentifier:@"VTMenuViewController"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:menu];
    appDelegate.window.rootViewController = nav;
}

#pragma mark --
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                   handler:(void (^ __nullable)(UIAlertAction *action))handler{
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:handler];
    [alertVC addAction:confirmAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}
- (MBProgressHUD *)progressHUD {
    if (_progressHUD == nil) {
        _progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _progressHUD.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

@end
