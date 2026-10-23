//
//  VTMenuViewController.m
//  VTO2Lib
//
//  Created by viatom on 2020/6/29.
//  Copyright © 2020 viatom. All rights reserved.
//
#import "VTMenuViewController.h"
#import "VTMCommShared.h"
#import "VTBLEUtils.h"
#import "VTRealViewController.h"
@interface VTMenuItem : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, copy) void(^clickFuction)(void);
@end
@implementation VTMenuItem
+ (instancetype)itemWithTitle:(NSString *)title selector:(void(^)(void))selector {
    VTMenuItem *item = [[VTMenuItem alloc] init];
    item.title = title;
    item.clickFuction = selector;
    return item;
}
@end
@interface VTMenuViewController ()<UITableViewDelegate, UITableViewDataSource, VTO2CommunicateDelegate, VTBLEUtilsDelegate, VTO2A5RespDelegate>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (nonatomic, copy) NSArray *funcArray;
@property (nonatomic, assign) NSInteger funcRow;
@end
@implementation VTMenuViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    __weak typeof(self) weakself = self;
    VTMenuItem *infoItem = [VTMenuItem itemWithTitle:@"Get Info" selector:^{
        [weakself performSegueWithIdentifier:@"gotoVTInfoViewController" sender:nil];
    }];
    VTMenuItem *realdataItem = [VTMenuItem itemWithTitle:@"Real-time data" selector:^{
        weakself.funcRow = 0;
        [weakself performSegueWithIdentifier:@"gotoVTRealViewController" sender:nil];
    }];
    VTMenuItem *realPPGItem = [VTMenuItem itemWithTitle:@"Real-PPG data" selector:^{
        weakself.funcRow = 1;
        [weakself performSegueWithIdentifier:@"gotoVTRealViewController" sender:nil];
    }];
    VTMenuItem *realWaveItem = [VTMenuItem itemWithTitle:@"Real-Waveform data" selector:^{
        weakself.funcRow = 2;
        [weakself performSegueWithIdentifier:@"gotoVTRealViewController" sender:nil];
    }];
    VTMenuItem *realParamsItem = [VTMenuItem itemWithTitle:@"Real-Params data" selector:^{
        weakself.funcRow = 3;
        [weakself performSegueWithIdentifier:@"gotoVTRealViewController" sender:nil];
    }];
    VTMenuItem *resetItem = [VTMenuItem itemWithTitle:@"Reset" selector:^{
        [weakself showAlertWithTitle:@"It will erase all files" message:@"" handler:^(UIAlertAction *action) {
            [VTMCommShared sharedInstance].o2Delegate = weakself;
            [[VTMCommShared sharedInstance] beginFactory];
        }];
    }];
    _funcArray = @[infoItem, realdataItem, realPPGItem, realWaveItem, realParamsItem, resetItem];
    [_myTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [VTBLEUtils sharedInstance].delegate = self;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"gotoVTRealViewController"]) {
        VTRealViewController *vc = segue.destinationViewController;
        vc.type = (int)_funcRow;
    }
}
#pragma mark -- tableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _funcArray.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"funcCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    VTMenuItem *item = _funcArray[indexPath.section];
    cell.textLabel.text = item.title;
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    VTMenuItem *item = _funcArray[indexPath.section];
    item.clickFuction();
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mark -- vt communicate
- (void)commonResponse:(VTCmd)cmdType andResult:(VTCommonResult)result{
    if (cmdType == VTCmdSetFactory) {
        // restore factory completed.
    }
}
- (void)a5_openupEncryptResult:(VTA5RespRes)respRes {
}
- (void)serviceDeployed:(BOOL)completed{
    if (completed) {
        [self showAlertWithTitle:@"Good !!!" message:@"Start work" handler:^(UIAlertAction *action) {
        }];
    }
}
#pragma mark -- vt ble
- (void)didConnectedDevice:(VTDevice *)device{
    self.title = [NSString stringWithFormat:@"%@ connected", device.rawPeripheral.name];
    [VTMCommShared sharedInstance].o2Delegate = self;
    /** The app needs to send a advertisementData packet when connecting to an encrypted device for the first time after startup.  */
    [[VTMCommShared sharedInstance] setPeripheral:device.rawPeripheral advertisementData:device.adv];
}
- (void)didDisconnectedDevice:(VTDevice *)device andError:(NSError *)error{
    self.title = [NSString stringWithFormat:@"%@ disconnected", device.rawPeripheral.name];
}
- (void)o2_serviceDeployed:(BOOL)completed{
    if (completed) {
        /** 两个参数都传 @"" 表示使用 SDK 内置的默认凭证；有自己的 token/secretKey 就填在这里。
            不要填 @"your-token" 这类占位串 —— 非空字符串会被当真凭证解析，握手必然失败。 */
        [[VTMCommShared sharedInstance] openupEncryptWithToken:@"" secretKey:@""];
    }
}
- (void)openupEncryptResult:(VTCommonResult)result {
    if (result == VTCommonResultSuccess) {
        DLog(@"Encryption device detected");
    } else {
        DLog(@"Unencrypted device detected");
    }
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
@end
