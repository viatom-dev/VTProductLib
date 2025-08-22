//
//  VTMBPMenuVC.m
//  VTMProductSDK
//
//  Created by Viatom3 on 2021/2/24.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMBPMenuVC.h"
#import "VTMRealVC.h"

@interface VTMBPMenuVC ()<UITableViewDelegate, UITableViewDataSource, VTBLEUtilsDelegate, VTMURATUtilsDelegate>

@property (nonatomic, weak) IBOutlet UITableView *myTableView;
@property (nonatomic, strong) NSMutableArray *funcArray;
@property (nonatomic, assign) NSInteger funcRow;

@property (nonatomic, assign) u_int downloadLen;
@property (nonatomic, strong) NSString *downloadName;
@property (nonatomic, strong) NSMutableArray *downloadArr;
@property (nonatomic, strong) NSMutableData *downloadData;

@property (nonatomic, strong) MBProgressHUD *progressHUD;

@property (nonatomic, copy) NSData *configData;

@end

static NSString *identifier = @"funcCell";

@implementation VTMBPMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [NSString stringWithFormat:@"%@ connected", [VTBLEUtils sharedInstance].device.advName];
    
    _funcArray = [[NSMutableArray alloc]initWithObjects:@"Device info",@"Battery Info", @"Sync time", @"Download file",@"Factory Reset",@"Get Config",@"BP Real-time Data", @"Heartbeat switch",nil];
    _myTableView.delegate = self;
    _myTableView.dataSource = self;
    [_myTableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [VTBLEUtils sharedInstance].delegate = self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [VTMProductURATUtils sharedInstance].delegate = self;
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
    if ([str isEqualToString:@"Heartbeat switch"]) {
        UISwitch *swi  = [[UISwitch alloc]init];
        cell.accessoryView = swi;
        [swi addTarget:self action:@selector(syncHeartbeatSwitch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}
- (void)syncHeartbeatSwitch:(UISwitch *)swi {
    [self.progressHUD showAnimated:YES];
    VTMBPConfig bpConfig = [VTMBLEParser parseBPConfig:self.configData];
    bpConfig.device_switch = swi.isOn;
    [[VTMProductURATUtils sharedInstance] syncBPConfig:bpConfig];
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
        
    }else if ([textStr isEqualToString:@"Get Config"]){
        
        [self.progressHUD showAnimated:YES];
        [[VTMProductURATUtils sharedInstance] requestBPConfig];
    }else if ([textStr isEqualToString:@"BP Real-time Data"]){
        VTMRealVC *vc = [[VTMRealVC alloc]init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)readFile {
    if (!self.downloadArr.count) {
        DLog(@"Download End");
        return;
    }
    self.downloadName = self.downloadArr.firstObject;
    [[VTMProductURATUtils sharedInstance] prepareReadFile:self.downloadName];
}

#pragma mark -- vt communicate
- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData *)response{
    DLog(@"response:%@",response);
    if(cmdType == VTMBLECmdGetDeviceInfo) {
        VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
        DLog(@"hw_version: %hhu, fw_version: %hhu, fw_version: %hhu, sn: %s, branch_code: %s",info.hw_version,info.fw_version,info.fw_version,info.sn.serial_num, info.branch_code);
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Get information successfully" message:[NSString stringWithFormat:@"sn:%s", info.sn.serial_num] handler:nil];
        
    } else if (cmdType == VTMBLECmdGetBattery) {
        VTMBatteryInfo battery = [VTMBLEParser parseBatteryInfo:response];
        DLog(@"battery: %d", battery.percent);
        [self.progressHUD hideAnimated:YES];
    } else if(cmdType == VTMBLECmdSyncTime) {
        DLog(@"Synchronize time successfully");
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Synchronize time successfully" message:nil handler:nil];
        
    }else if(cmdType == VTMBLECmdGetFileList){//
        VTMFileList list = [VTMBLEParser parseFileList:response];
        self.downloadArr = [NSMutableArray arrayWithCapacity:10];
        NSMutableString *fileStr = [NSMutableString string];
        for (int i = 0; i < list.file_num; i++) {
            NSMutableString *temp = [NSMutableString string];
            u_char *file_name = list.fileName[i].str;
            size_t fileLen = strlen((char *)file_name);
            for (int j = 0; j < fileLen; j++) {
                [temp appendString:[NSString stringWithFormat:@"%c",file_name[j]]];
            }
            [self.downloadArr addObject:temp];
            [fileStr appendString:[NSString stringWithFormat:@"%@\n", temp]];
        }
        [self showAlertWithTitle:[NSString stringWithFormat:@"%lu%@", (unsigned long)_downloadArr.count, _downloadArr.count > 1 ? @"records" : @"record"] message:fileStr handler:^(UIAlertAction *action) {
            if (self.downloadArr.count > 0) {
                [self readFile];
            }else{
                [self.progressHUD hideAnimated:YES];
            }
        }];
        
        
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
        DLog(@"file: %@ Download successfully", self.downloadName);
        [self.progressHUD hideAnimated:YES];
        Byte *b = _downloadData.mutableBytes;
        
        if ([self.downloadName isEqualToString:@"user.list"]) {

        } else if ([self.downloadName isEqualToString:@"bp.list"]) {
            VTMBP3FileData bpData = [VTMBLEParser bp3_parseBPFileData:_downloadData];
            u_char num = (_downloadData.length - sizeof(VTMBPWFileDataHead)) / sizeof(VTMBP3BPResult);
            for (int i = 0; i < num; i++) {
                VTMBP3BPResult res = bpData.list[i];
                VTMBPWBPResult result = res.result;
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:result.measuring_timestamp - [NSTimeZone localTimeZone].secondsFromGMT];
                DLog(@"time: %@", date);
                if (res.pulse_flag) {
                    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
                    fmt.dateFormat = @"YYMMddHHmmss";
                    NSString *waveFile =  [NSString stringWithFormat:@"BP%@", [fmt stringFromDate:date]] ;
                    [self.downloadArr addObject:waveFile];
                }
            }
            
        } else if ([self.downloadName isEqualToString:@"ecg.list"]) {
            VTMBP3ECGFileData ecgData = [VTMBLEParser bp3_parseECGFileData:_downloadData];
            u_char num = (_downloadData.length - sizeof(VTMBPWFileDataHead)) / sizeof(VTMBPWECGResult);
            for (int i = 0; i < num; i++) {
                VTMBPWECGResult result = ecgData.list[i];
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:result.measuring_timestamp - [NSTimeZone localTimeZone].secondsFromGMT];
                DLog(@"time: %@", date);
                // waveFile
                NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
                fmt.dateFormat = @"YYYYMMddHHmmss";
                NSString *waveFile = [fmt stringFromDate:date];
                [self.downloadArr addObject:waveFile];
            }
        } else {
            int fileTpye = b[1]; // BP2 -- ECG/BP ; BP2A -- BP
            if (fileTpye == 1) { // BP
                VTMBPBPResult result = [VTMBLEParser parseBPResult:_downloadData];
                DLog(@"fileName:%@\tDIA: %d\tSYS: %d\tMAP: %d\tPR: %d", self.downloadName,result.diastolic_pressure, result.systolic_pressure, result.mean_pressure, result.pulse_rate);
            } else if (fileTpye == 2) { //   ECG
                if ([[VTBLEUtils sharedInstance].device.advName hasPrefix:BP2_ShowPre] || [[VTBLEUtils sharedInstance].device.advName hasPrefix:BP2A_ShowPre]) {
                    // old protocal
                    VTMBPECGResult result = [VTMBLEParser parseECGResult:[_downloadData subdataWithRange:NSMakeRange(0, sizeof(VTMBPECGResult))]];
                    DLog(@"fileName: %@ Heart Rate: %d", self.downloadName, result.hr);
                    NSArray *ecgWaveArr = [VTMBLEParser parseBPPoints:[_downloadData subdataWithRange:NSMakeRange(sizeof(VTMBPECGResult), _downloadData.length - sizeof(VTMBPECGResult))]];
                } else {
                    VTMBPWECGWaveFileHead head;
                    [_downloadData getBytes:&head length:sizeof(VTMBPWECGWaveFileHead)];
                    NSArray *ecgWaveArr = [VTMBLEParser parseBPPoints:[_downloadData subdataWithRange:NSMakeRange(sizeof(VTMBPWECGWaveFileHead), _downloadData.length - sizeof(VTMBPWECGWaveFileHead))]];
                }
                
            } else if (fileTpye == 7) {
                
            } else {
                DLog(@"Error");
            }
        }
        
        [self.downloadArr removeObjectAtIndex:0];
        [self readFile];
        
    } else if (cmdType == VTMBLECmdRestore) {
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
        
    }else if (cmdType == VTMBPCmdGetConfig){
        DLog(@"Get Config successfully");
        [self.progressHUD hideAnimated:YES];
        VTMBPConfig  bpConfig =  [VTMBLEParser parseBPConfig:response];
        [self showAlertWithTitle:@"Get Config successfully" message:nil handler:nil];
        self.configData = response;
        
    }else if (cmdType == VTMBPCmdSetConfig){
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
