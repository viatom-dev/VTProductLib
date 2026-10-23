//
//  VTConnectViewController.m
//  VTO2Lib
//
//  Created by viatom on 2020/6/22.
//  Copyright © 2020 viatom. All rights reserved.
//

#import "VTConnectViewController.h"
#import "VTBLEUtils.h"
#import "VTMCommShared.h"

@interface VTConnectViewController ()<UITableViewDelegate, UITableViewDataSource, VTBLEUtilsDelegate, VTO2CommunicateDelegate, VTO2A5RespDelegate>

@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (nonatomic, strong) NSMutableArray *deviceListArray;
@property (nonatomic, strong) NSMutableArray *deviceIDArray;

@end

@implementation VTConnectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [VTBLEUtils sharedInstance].delegate = self;
    
}

- (NSMutableArray *)deviceListArray{
    if (!_deviceListArray) {
        _deviceListArray = [NSMutableArray arrayWithCapacity:10];
    }
    return _deviceListArray;
}

- (NSMutableArray *)deviceIDArray {
    if (!_deviceIDArray) {
        _deviceIDArray = [NSMutableArray arrayWithCapacity:10];
    }
    return _deviceIDArray;
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
    if ([self.deviceIDArray containsObject:identifier]) {
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
//    [VTO2Communicate sharedInstance].peripheral = device.rawPeripheral;
//    [VTO2Communicate sharedInstance].delegate = self;
    
    [VTMCommShared sharedInstance].o2Delegate = self;
    /** for bbsm s3 **/
    [VTMCommShared sharedInstance].a5Delegate = self;
    
    /** The app needs to send a advertisementData packet when connecting to an encrypted device for the first time after startup.  */
    [[VTMCommShared sharedInstance] setPeripheral:device.rawPeripheral advertisementData:device.adv];
}

/// @brief This device has been disconnected. Note: If error == nil ，user manually disconnect.
- (void)didDisconnectedDevice:(VTDevice *)device andError:(NSError *)error{
    
}



- (void)o2_serviceDeployed:(BOOL)completed{
    if (completed) {
        /** 两个参数都传 @"" 表示使用 SDK 内置的默认凭证；有 Viatom 颁发的
            token/secretKey 就填在这里。不要填占位串 —— 非空字符串会被当真凭证解析。 */
        NSString *token = @"";
        NSString *key = @"";
        [[VTMCommShared sharedInstance] openupEncryptWithToken:token secretKey:key];
        [self showAlertWithTitle:@"Good !!!" message:@"Start work" handler:^(UIAlertAction *action) {
            [self performSegueWithIdentifier:@"presentViewController" sender:nil];
        }];
    }else{
        [self showAlertWithTitle:@"The peripheral is not supported !!!" message:@"" handler:^(UIAlertAction *action) {
            [self.deviceListArray removeAllObjects];
            [[VTBLEUtils sharedInstance] startScan];
        }];
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
