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
    self.title = [NSString stringWithFormat:@"%@ connected", [VTBLEUtils sharedInstance].device.advName];
    _funcArray = [[NSMutableArray alloc]initWithObjects:@"Device info",@"Battery Info", @"Sync time", @"Download file",@"Factory Reset",@"Burn SN&Code",@"Scale Run Prams", @"Scale Real-time Data",nil];
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
    cell.textLabel.text = _funcArray[indexPath.section];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *textStr = _funcArray[indexPath.section];
    if ([textStr isEqualToString:@"Device info"]) {
        
        [[VTMProductURATUtils sharedInstance] requestDeviceInfo];
        [self.progressHUD showAnimated:YES];
    }else if ([textStr isEqualToString:@"Battery Info"]){
        [[VTMProductURATUtils sharedInstance] requestBatteryInfo];
        [self.progressHUD showAnimated:YES];
    }else if ([textStr isEqualToString:@"Sync time"]){
        
        [[VTMProductURATUtils sharedInstance] syncTime:[NSDate date]];//CallBack cmdType:VTMBLECmdSyncTime
        [self.progressHUD showAnimated:YES];
    }else if ([textStr isEqualToString:@"Download file"]){
        
        //CallBack cmdType order：VTMBLECmdGetFileList -> VTMBLECmdStartRead -> VTMBLECmdReadFile -> VTMBLECmdEndRead
        [[VTMProductURATUtils sharedInstance] requestFilelist];
        [self.progressHUD showAnimated:YES];
    }else if ([textStr isEqualToString:@"Factory Reset"]){
        
        //CallBack cmdType:VTMBLECmdRestore
        [[VTMProductURATUtils sharedInstance] factoryReset];
        [self.progressHUD showAnimated:YES];
        
    }else if ([textStr isEqualToString:@"Burn SN&Code"]){
        
        UIAlertController *inputAlert = [UIAlertController alertControllerWithTitle:@"Enter Config" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [inputAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"SN：（length>=10,length<=18）";
            textField.tag = 100;
        }];
        [inputAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"Hardware version：A/B/C/D";
            textField.tag = 101;
        }];
        [inputAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"brachCode：(length==8)"; //8 digits
            textField.tag = 102;
        }];
        UIAlertAction *cancelAa = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *sureAa = [UIAlertAction actionWithTitle:@"Sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            VTMConfig config;
            for (UITextField *t in inputAlert.textFields) {
                if (t.tag == 100) {
                    if (t.text.length >= 10 && t.text.length <= 18) {
                        config.burn_flag |= (1 << 0);
                        config.sn.len = t.text.length;
                        for (int i = 0; i < t.text.length; i ++) {
                            config.sn.serial_num[i] = [t.text characterAtIndex:i];
                        }
                    }else{
                        // error
                    }
                }else if (t.tag == 101) {
                    if ([t.text isEqualToString:@"A"] ||
                        [t.text isEqualToString:@"B"] ||
                        [t.text isEqualToString:@"C"] ||
                        [t.text isEqualToString:@"D"]) {
                        config.burn_flag |= (1 << 1);
                        config.hw_version = [t.text characterAtIndex:0];
                    }else{
                        // error
                    }
                }else{
                    if (t.text.length == 8) {
                        config.burn_flag |= (1 << 2);
                        for (int i = 0; i < t.text.length; i ++) {
                            config.branch_code[i] = [t.text characterAtIndex:i];
                        }
                    }else{
                        // error
                    }
                }
            }
            if (config.burn_flag != 0) {
                //CallBack cmdType:VTMBLECmdRestoreInfo
                [self.progressHUD showAnimated:YES];
                [[VTMProductURATUtils sharedInstance] factorySet:config];
            }else{
                
            }
        }];
        [inputAlert addAction:cancelAa];
        [inputAlert addAction:sureAa];
        [self presentViewController:inputAlert animated:YES completion:^{
            
        }];
        
    }else if ([textStr isEqualToString:@"Scale Run Prams"]){
        
        [self.progressHUD showAnimated:YES];
        [[VTMProductURATUtils sharedInstance] requestScaleRealData];
    }else if ([textStr isEqualToString:@"Scale Real-time Data"]){
        
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
        [self showAlertWithTitle:@"Get information successfully" message:[NSString stringWithFormat:@"sn:%s", info.sn.serial_num] handler:nil];
         
    }else if(cmdType == VTMBLECmdGetBattery){
        VTMBatteryInfo info = [VTMBLEParser parseBatteryInfo:response];
        DLog(@"state:%hhu,percent:%hhu,voltage:%hhu",info.state,info.percent,info.voltage);
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Get information successfully" message:[NSString stringWithFormat:@"percent:%hhu%%", info.percent] handler:nil];
        
    }else if(cmdType == VTMBLECmdSyncTime){
        DLog(@"Synchronize time successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Synchronize time successfully" message:nil handler:nil];
        
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
        [self showAlertWithTitle:[NSString stringWithFormat:@"%lu%@", (unsigned long)downloadArr.count, downloadArr.count > 1 ? @"records" : @"record"] message:fileStr handler:nil];
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
        [self showAlertWithTitle:@"Download successfully" message:nil handler:nil];
        [VTMBLEParser parseScaleFile:[_downloadData copy] completion:^(VTMScaleFileHead head, VTMScaleFileData fileData) {
            DLog(@"hr : %d", fileData.ecg_result.hr);
            DLog(@"recordTime: %d", fileData.ecg_result.recording_time);
            DLog(@"weight : %d", fileData.scale_data.weight);
        }];
        
    }else if (cmdType == VTMBLECmdRestore) {
        DLog(@"Factory Settings restored successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Factory Settings restored successfully" message:nil handler:nil];
    }else if (cmdType == VTMBLECmdRestoreInfo) {
        
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Set successfully" message:nil handler:nil];
    }else if (cmdType == VTMBLECmdProductReset){
        
        DLog(@"Production factory Settings restored successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Reset successfully" message:nil handler:nil];
    }else if (cmdType == VTMSCALECmdGetRealData){
        
        [self.progressHUD hideAnimated:YES];
        VTMScaleRealData realData = [VTMBLEParser parseScaleRealData:response];
        [self showAlertWithTitle:@"Get RunParams successfully" message:[NSString stringWithFormat:@"status:%hhu", realData.run_para.run_status] handler:nil];
    }
}

#pragma mark -- vt ble
- (void)didConnectedDevice:(VTDevice *)device{
    DLog(@"connected successfully：%@",device.rawPeripheral.name);
    self.title = [NSString stringWithFormat:@"%@ connected", device.rawPeripheral.name];
    CBPeripheral *rawPeripheral = device.rawPeripheral;
    [VTMProductURATUtils sharedInstance].peripheral = rawPeripheral;
}

- (void)didDisconnectedDevice:(VTDevice *)device andError:(NSError *)error{
    self.title = [NSString stringWithFormat:@"%@ disconnected", device.rawPeripheral.name];
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
