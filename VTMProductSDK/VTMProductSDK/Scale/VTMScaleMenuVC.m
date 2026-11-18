//
//  VTMScaleMenuVC.m
//  VTMProductSDK
//
//  Created by Viatom3 on 2021/2/24.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMScaleMenuVC.h"
#import "VTMRealVC.h"

@interface VTMScaleMenuVC ()<UITableViewDelegate, UITableViewDataSource, VTBLEUtilsDelegate,VTMURATUtilsDelegate>

@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@property (nonatomic, strong) NSMutableArray *funcArray;
@property (nonatomic, assign) NSInteger funcRow;
@property (nonatomic, assign) u_int downloadLen;
@property (nonatomic, strong) NSMutableData *downloadData;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

static NSString *identifier = @"funcCell";
@implementation VTMScaleMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:VTMLocalized(@"scale.fmt.title.connected"), [VTBLEUtils sharedInstance].device.advName];
    // _funcArray 里存的是本地化 key，不是显示文案：显示时用 VTMLocalized(key)，
    // 点击分发时比较 key，这样切换语言不影响菜单行为。
    _funcArray = [[NSMutableArray alloc]initWithObjects:@"scale.menu.deviceInfo", @"scale.menu.battery", @"scale.menu.syncTime", @"scale.menu.download", @"scale.menu.factoryReset", @"scale.menu.runParams", @"scale.menu.realtime", nil];
    _myTableView.delegate = self;
    _myTableView.dataSource = self;
    [_myTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [VTMProductURATUtils sharedInstance].delegate = self;
    [VTBLEUtils sharedInstance].delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [VTMProductURATUtils sharedInstance].delegate = nil;
}

#pragma mark -- tableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _funcArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = VTMLocalized(_funcArray[indexPath.section]);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *key = _funcArray[indexPath.section];
    if ([key isEqualToString:@"scale.menu.deviceInfo"]) {
        
        [[VTMProductURATUtils sharedInstance] requestDeviceInfo];
        [self.progressHUD showAnimated:YES];
    }else if ([key isEqualToString:@"scale.menu.battery"]){
        [[VTMProductURATUtils sharedInstance] requestBatteryInfo];
        [self.progressHUD showAnimated:YES];
    }else if ([key isEqualToString:@"scale.menu.syncTime"]){
        
        [[VTMProductURATUtils sharedInstance] syncTime:[NSDate date]];//CallBack cmdType:VTMBLECmdSyncTime
        [self.progressHUD showAnimated:YES];
    }else if ([key isEqualToString:@"scale.menu.download"]){
        
        //CallBack cmdType order：VTMBLECmdGetFileList -> VTMBLECmdStartRead -> VTMBLECmdReadFile -> VTMBLECmdEndRead
        [[VTMProductURATUtils sharedInstance] requestFilelist];
        [self.progressHUD showAnimated:YES];
    }else if ([key isEqualToString:@"scale.menu.factoryReset"]){
        
        //CallBack cmdType:VTMBLECmdRestore
        [[VTMProductURATUtils sharedInstance] factoryReset];
        [self.progressHUD showAnimated:YES];
        
    }else if ([key isEqualToString:@"scale.menu.runParams"]){
        
        [self.progressHUD showAnimated:YES];
        [[VTMProductURATUtils sharedInstance] requestScaleRealData];
    }else if ([key isEqualToString:@"scale.menu.realtime"]){
        
        VTMRealVC *vc = [[VTMRealVC alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -- vt communicate
- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData *)response{
    DLog(@"response:%@",response);
     if(cmdType == VTMBLECmdGetDeviceInfo) {
        VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
        DLog(@"hw_version:%hhu,fw_version:%hhu,fw_version:%hhu,sn:%s,branch_code:%s",info.hw_version,info.fw_version,info.fw_version,info.sn.serial_num,info.branch_code);
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.infoDone") message:[NSString stringWithFormat:VTMLocalized(@"scale.fmt.alert.sn"), info.sn.serial_num] handler:nil];
         
    }else if(cmdType == VTMBLECmdGetBattery){
        VTMBatteryInfo info = [VTMBLEParser parseBatteryInfo:response];
        DLog(@"state:%hhu,percent:%hhu,voltage:%hhu",info.state,info.percent,info.voltage);
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.infoDone") message:[NSString stringWithFormat:VTMLocalized(@"scale.fmt.alert.battery"), info.percent] handler:nil];
        
    }else if(cmdType == VTMBLECmdSyncTime){
        DLog(@"Synchronize time successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.syncTimeDone") message:nil handler:nil];
        
    }else if(cmdType == VTMBLECmdGetFileList){//
        VTMFileList list = [VTMBLEParser parseFileList:response];
        NSMutableArray *downloadArr = [NSMutableArray array];
        NSMutableString *fileStr = [NSMutableString string];
        for (int i = 0; i < list.file_num; i++) {
            NSMutableString *temp = [NSMutableString string];
            u_char *file_name = list.fileName[i].str;
            size_t fileLen = strlen((char *)file_name);
            for (int j = 0; j < fileLen; j++) {
                [temp appendString:[NSString stringWithFormat:@"%c",file_name[j]]];
            }
            [downloadArr addObject:temp];
            [fileStr appendString:[NSString stringWithFormat:@"%@\n", temp]];
        }
        NSString *countFmt = VTMLocalized(downloadArr.count > 1 ? @"scale.fmt.alert.records" : @"scale.fmt.alert.record");
        [self showAlertWithTitle:[NSString stringWithFormat:countFmt, (unsigned long)downloadArr.count] message:fileStr handler:nil];
        if (downloadArr.count > 0) {
            [[VTMProductURATUtils sharedInstance] prepareReadFile:downloadArr[0]];
        }else{
              [self.progressHUD hideAnimated:YES];
        }
        
    }else if(cmdType == VTMBLECmdStartRead){
        _downloadLen = 0;
        _downloadData = [NSMutableData data];
        VTMOpenFileReturn fsrr = [VTMBLEParser parseFileLength:response];
        DLog(@"file length: %d", fsrr.file_size);
        _downloadLen = fsrr.file_size;
        if (fsrr.file_size == 0) {
            [[VTMProductURATUtils sharedInstance] endReadFile];
        }else{
            [[VTMProductURATUtils sharedInstance] readFile:0];
        }
        
    }else if (cmdType == VTMBLECmdReadFile) {
        [_downloadData appendData:response];
        DLog(@"Download data length: %d",(int)_downloadData.length);
        if (_downloadData.length == _downloadLen){
            [[VTMProductURATUtils sharedInstance] endReadFile];
        }else{
            [[VTMProductURATUtils sharedInstance] readFile:(u_int)_downloadData.length];
        }
        
    }else if(cmdType == VTMBLECmdEndRead){
        DLog(@"Download successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.downloadDone") message:nil handler:nil];
        [VTMBLEParser parseScaleFile:[_downloadData copy] completion:^(VTMScaleFileHead head, VTMScaleFileData fileData) {
            DLog(@"hr : %d", fileData.ecg_result.hr);
            DLog(@"recordTime: %d", fileData.ecg_result.recording_time);
            DLog(@"weight : %d", fileData.scale_data.weight);
        }];
        
    }else if (cmdType == VTMBLECmdRestore) {
        DLog(@"Factory Settings restored successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.factoryResetDone") message:nil handler:nil];
    }else if (cmdType == VTMBLECmdRestoreInfo) {
        
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.setDone") message:nil handler:nil];
    }else if (cmdType == VTMBLECmdProductReset){
        
        DLog(@"Production factory Settings restored successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.resetDone") message:nil handler:nil];
    }else if (cmdType == VTMSCALECmdGetRealData){
        
        [self.progressHUD hideAnimated:YES];
        VTMScaleRealData realData = [VTMBLEParser parseScaleRealData:response];
        [self showAlertWithTitle:VTMLocalized(@"scale.alert.runParamsDone") message:[NSString stringWithFormat:VTMLocalized(@"scale.fmt.alert.status"), realData.run_para.run_status] handler:nil];
    }
}

#pragma mark -- vt ble
- (void)didConnectedDevice:(VTDevice *)device{
    DLog(@"connected successfully：%@",device.rawPeripheral.name);
    self.title = [NSString stringWithFormat:VTMLocalized(@"scale.fmt.title.connected"), device.rawPeripheral.name];
    CBPeripheral *rawPeripheral = device.rawPeripheral;
    [VTMProductURATUtils sharedInstance].peripheral = rawPeripheral;
}

- (void)didDisconnectedDevice:(VTDevice *)device andError:(NSError *)error{
    self.title = [NSString stringWithFormat:VTMLocalized(@"scale.fmt.title.disconnected"), device.rawPeripheral.name];
}

#pragma mark --

- (void)showAlertWithTitle:(NSString *)title
                  message:(NSString *)message
                   handler:(void (^ __nullable)(UIAlertAction *action))handler{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:VTMLocalized(@"common.ok") style:UIAlertActionStyleDefault handler:handler];
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
