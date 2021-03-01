//
//  VTMECGMenuVC.m
//  VTMProductSDK
//
//  Created by Viatom3 on 2021/2/24.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMECGMenuVC.h"
#import "VTMRealVC.h"
#import "VTMECGConfigVC.h"

@interface VTMECGMenuVC ()<UITableViewDelegate, UITableViewDataSource, VTBLEUtilsDelegate,VTMURATUtilsDelegate>

@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@property (nonatomic, strong) NSMutableArray *funcArray;
@property (nonatomic, assign) NSInteger funcRow;
@property (nonatomic, assign) u_int downloadLen;
@property (nonatomic, strong) NSMutableData *downloadData;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end
static NSString *identifier = @"funcCell";

@implementation VTMECGMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"%@ connected", [VTBLEUtils sharedInstance].device.advName];
    if ([[VTBLEUtils sharedInstance].device.advName hasPrefix:ER1_ShowPre] || [[VTBLEUtils sharedInstance].device.advName hasPrefix:VisualBeat_ShowPre]) {
        _funcArray = [[NSMutableArray alloc]initWithObjects:@"Device info",@"Battery Info", @"Sync time" , @"Download file",@"Factory Reset",@"Burn SN&Code",@"Get Config",@"ECG Real-time Data",@"Sync Config", nil];
    }else{
        _funcArray = [[NSMutableArray alloc]initWithObjects:@"Device info",@"Battery Info", @"Sync time" , @"Download file",@"Factory Reset",@"Burn SN&Code",@"Get Config",@"ECG Real-time Data",@"Heartbeat switch", nil];
    }
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
    NSString *str = _funcArray[indexPath.section];
    cell.textLabel.text = str;
    if (([[VTBLEUtils sharedInstance].device.advName hasSuffix:ER2_ShowPre] || [[VTBLEUtils sharedInstance].device.advName hasSuffix:DuoEK_ShowPre]) && [str isEqualToString:@"Heartbeat switch"]) {
        UISwitch *swi  = [[UISwitch alloc]init];
        cell.accessoryView = swi;
        [swi addTarget:self action:@selector(syncER2ConfigSwitch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}
-(void)syncER2ConfigSwitch:(UISwitch *)swi{
    [self.progressHUD showAnimated:YES];
    VTMER2Config er2Config ;
    er2Config.ecgSwitch = swi.on;
    [[VTMProductURATUtils sharedInstance] syncER2Config:er2Config];
    
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
        
    }else if ([textStr isEqualToString:@"Get Config"]){
        
        [self.progressHUD showAnimated:YES];
        [[VTMProductURATUtils sharedInstance] requestECGConfig];
    }else if ([textStr isEqualToString:@"ECG Real-time Data"]){
        
        VTMRealVC *vc = [[VTMRealVC alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }else if ([textStr isEqualToString:@"Sync Config"] && [[VTBLEUtils sharedInstance].device.advName hasPrefix:ER1_ShowPre]){
        
        VTMECGConfigVC *vc = [[VTMECGConfigVC alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -- vt communicate
- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData *)response{
    DLog(@"response:%@",response);
    if(cmdType == VTMBLECmdGetDeviceInfo) {
        VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
        DLog(@"hw_version:%hhu,fw_version:%hhu,sn:%s,branch_code:%s",info.hw_version,info.fw_version,info.sn.serial_num,info.branch_code);
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Get information successfully" message:[NSString stringWithFormat:@"sn:%s", info.sn.serial_num] handler:^(UIAlertAction *action) {
            
        }];
        
    }else if(cmdType == VTMBLECmdGetBattery){
        VTMBatteryInfo info = [VTMBLEParser parseBatteryInfo:response];
        DLog(@"state:%hhu,percent:%hhu,voltage:%hhu",info.state,info.percent,info.voltage);
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Get information successfully" message:[NSString stringWithFormat:@"percent:%hhu%%", info.percent] handler:^(UIAlertAction *action) {
            
        }];
        
    }else if(cmdType == VTMBLECmdSyncTime){
        DLog(@"Synchronize time successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Synchronize time successfully" message:nil handler:^(UIAlertAction *action) {
            
        }];
        
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
        int fileIndex = 0;//Which one to download, eg:0,
        if (downloadArr.count > 0){
            [[VTMProductURATUtils sharedInstance] prepareReadFile:downloadArr[fileIndex]];
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
        
    }else if (cmdType == VTMECGCmdGetConfig){
        DLog(@"Get ECG Config successfully");
        [self.progressHUD hideAnimated:YES];
        if ([[VTBLEUtils sharedInstance].device.advName hasPrefix:ER1_ShowPre] || [[VTBLEUtils sharedInstance].device.advName hasPrefix:VisualBeat_ShowPre] ) {
            VTMER1Config er1Config = [VTMBLEParser parseER1Config:response];
            DLog(@"vibeSw:%hhu,hrTarget1:%hhu,hrTarget2:%hhu",er1Config.vibeSw,er1Config.hrTarget1,er1Config.hrTarget2);
            [self showAlertWithTitle:@"Get Config successfully" message:[NSString stringWithFormat:@"hrTarget1:%hhu \n hrTarget2:%hhu", er1Config.hrTarget1,er1Config.hrTarget2] handler:nil];
        }else if ([[VTBLEUtils sharedInstance].device.advName hasPrefix:ER2_ShowPre] || [[VTBLEUtils sharedInstance].device.advName hasPrefix:VisualBeat_ShowPre]){
            VTMER2Config er2Config = [VTMBLEParser parseER2Config:response];
            DLog(@"ecgSwitch:%hhu,vector:%hhu,motion_count:%hhu,motion_windows:%hu",er2Config.ecgSwitch,er2Config.vector,er2Config.motion_count,er2Config.motion_windows);
            
            [self showAlertWithTitle:@"Get Config successfully" message:[NSString stringWithFormat:@"heartbeat switch:%hhu", er2Config.ecgSwitch] handler:nil];
        }
        
    }else if (cmdType == VTMECGCmdSetConfig){
        DLog(@"Set Config successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Set Config successfully" message:nil handler:nil];
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
