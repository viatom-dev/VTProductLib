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

@interface VTConnectVC ()<UITableViewDelegate, UITableViewDataSource, VTBLEUtilsDelegate,VTMURATDeviceDelegate,VTMURATUtilsDelegate>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (nonatomic, strong) NSMutableArray *deviceListArray;
@property (nonatomic, strong) NSMutableArray *deviceIDArray;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@end

@implementation VTConnectVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Scaner";
    [_myTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:54 green:216 blue:192 alpha:1]];
    [VTBLEUtils sharedInstance].delegate = self;
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",device.RSSI];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.progressHUD showAnimated:YES];
    VTDevice *device = self.deviceListArray[indexPath.row];
    [[VTBLEUtils sharedInstance] stopScan];
    [[VTBLEUtils sharedInstance] connectToDevice:device];
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
    DLog(@"Connected：%@",device.rawPeripheral.name);
    CBPeripheral *rawPeripheral = device.rawPeripheral;
    [VTMProductURATUtils sharedInstance].peripheral = rawPeripheral;
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
    
    [self showAlertWithTitle:@"Completion" message:nil handler:^(UIAlertAction *action) {
        AppDelegate *appDelagete = [UIApplication sharedApplication].delegate;
        
       if(util.currentType == VTMDeviceTypeBP){
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
