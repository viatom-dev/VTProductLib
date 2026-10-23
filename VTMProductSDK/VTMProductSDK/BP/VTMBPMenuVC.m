//
//  VTMBPMenuVC.m
//  VTMProductSDK
//
//  Created by Viatom3 on 2021/2/24.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMBPMenuVC.h"
#import "VTMRealVC.h"
#import "VTMProductSDK-Swift.h"

// 主机状态用 SDK 的 VTMBPStatus（VTMBLEEnum.h），不要在 Demo 里另外定义一份。
// 这里原先有个本地 DeviceStatus 枚举，0–7 和 VTMBPStatus 完全重复，但缺了
// BP2WIFI 三次测量（15–17）、BP2 理疗（20）、BP3 血压心电（21–24）、
// 配网与数据上传（25/26）和无效值（0xFF）。

@interface VTMBPMenuVC ()<UITableViewDelegate, UITableViewDataSource, VTBLEUtilsDelegate,VTMURATUtilsDelegate>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (nonatomic, strong) NSMutableArray *funcArray;
@property (nonatomic, assign) NSInteger funcRow;
@property (nonatomic, assign) u_int downloadLen;
@property (nonatomic, strong) NSMutableData *downloadData;
@property (nonatomic, copy) NSString *downloadName;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@property (nonatomic, copy) NSData *configData;

@property (nonatomic, strong) NSIndexPath *curIdxPath;

@end

static NSString *identifier = @"funcCell";

@implementation VTMBPMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"%@ connected", [VTBLEUtils sharedInstance].device.advName];
    _funcArray = [[NSMutableArray alloc]initWithObjects:@"Device info",@"Battery Info", @"Sync time", @"Download file",@"Factory Reset",@"Get Config",@"BP Real-time Data", @"Heartbeat switch", @"delete first file", nil];
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
    if ([str isEqualToString:@"Heartbeat switch"]) {
        UISwitch *swi  = [[UISwitch alloc]init];
        cell.accessoryView = swi;
        [swi addTarget:self action:@selector(syncHeartbeatSwitch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}
-(void)syncHeartbeatSwitch:(UISwitch *)swi{
    [self.progressHUD showAnimated:YES];
    VTMBPConfig bpConfig = [VTMBLEParser parseBPConfig:self.configData];
    bpConfig.device_switch = swi.isOn;
    [[VTMProductURATUtils sharedInstance] syncBPConfig:bpConfig];
    //[[VTMProductURATUtils sharedInstance] syncBPSwitch:swi.on];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    _curIdxPath = indexPath;
    NSString *textStr = _funcArray[indexPath.section];
    if ([textStr isEqualToString:@"Device info"]) {
        
        [[VTMProductURATUtils sharedInstance] requestDeviceInfo];
        [self.progressHUD showAnimated:YES];
    }else if ([textStr isEqualToString:@"Battery Info"]){
        
        [[VTMProductURATUtils sharedInstance] requestBPRealData];
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
    } else if ([textStr isEqualToString:@"delete first file"]) {
        [[VTMProductURATUtils sharedInstance] requestFilelist];
        [self.progressHUD showAnimated:YES];
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
        
    }else if(cmdType == VTMBPCmdGetRealData){
        VTMBPRealTimeData bpData = [VTMBLEParser parseBPRealTimeData:response];
        VTMBatteryInfo info = bpData.run_status.battery;
        DLog(@"state:%hhu,percent:%hhu,voltage:%hhu",info.state,info.percent,info.voltage);
        VTMBPRunStatus status = bpData.run_status;
        VTMBPRealTimeWaveform waveform = bpData.rt_wav;
        switch ((VTMBPStatus)status.status) {
            case VTMBPStatusSleep:{
            }
                break;
            case VTMBPStatusMemery:{
                
            }
                break;
            case VTMBPStatusCharge:{
                
            }
                break;
            case VTMBPStatusReady:{
            }
                break;
            case VTMBPStatusBPMeasuring:{
                NSData *tempData = [NSData dataWithBytes:waveform.data length:sizeof(waveform.data)];
                VTMBPMeasuringData measuringData = [VTMBLEParser parseBPMeasuringData:tempData];
                if (measuringData.is_deflating_2) {
                    for (int i = 0; i < waveform.wav.sampling_num ; i++) {
                        short prWave = waveform.wav.wave_data[i];
                    }
                }
            }
                break;
            case VTMBPStatusBPMeasureEnd:{
                NSData *tempData = [NSData dataWithBytes:waveform.data length:sizeof(waveform.data)];
                VTMBPEndMeasureData endMeasureData = [VTMBLEParser parseBPEndMeasureData:tempData];

            }
                break;
            case VTMBPStatusECGMeasuring:{
    
                NSData *tempData = [NSData dataWithBytes:waveform.data length:sizeof(waveform.data)];
                VTMECGMeasuringData ecgMeasuringData = [VTMBLEParser parseECGMeasuringData:tempData];
                for (int i = 0; i < waveform.wav.sampling_num ; i++) {
                    if (waveform.wav.wave_data[i] != 0x7FFF) {
                        float mV = [VTMBLEParser bpMvFromShort:waveform.wav.wave_data[i]];
                    }
                }
            }
                break;
            case VTMBPStatusECGMeasureEnd:{
                NSData *tempData = [NSData dataWithBytes:waveform.data length:sizeof(waveform.data)];
                VTMECGEndMeasureData ecgEndMeasueData = [VTMBLEParser parseECGEndMeasureData:tempData];

            }
                break;

            // ── 这个菜单只演示「取一次实时数据」，不做完整状态机 ──────────────
            //
            // 完整的状态处理（三次测量、BP3 按 rt_wav.type 取 payload、
            // is_deflating 与 is_deflating_2 的区别）在 VTMRealVC 的
            // handleBPRealTimeData: 里，那里是逐包渲染的场景。
            case VTMBPStatusBPAVGMeasure:         // 15  BP2WIFI 血压三次测量中
            case VTMBPStatusBPAVGMeasureWait:     // 16  BP2WIFI 血压三次测量等待开始
            case VTMBPStatusBPAVGMeasureEnd:      // 17  BP2WIFI 血压三次测量结束
            case VTMBPStatusVEN:                  // 20  BP2 理疗模式中
            case VTMBPStatusBPMeasuringBP3:       // 21  BP3 血压心电测量中
            case VTMBPStatusBPMeasureEndBP3:      // 22  BP3 血压心电测量结束
            case VTMBPStatusECGMeasuringBP3:      // 23  BP3 血压心电三次测量中
            case VTMBPStatusECGMeasureEndBP3:     // 24  BP3 血压心电三次测量结束
            case VTMBPStatusNetworkConfig:        // 25  配置 WiFi 和服务器
            case VTMBPStatusDataUploading:        // 26  数据上传服务器
                DLog(@"BP status %d not demonstrated yet (rt_wav.type=%d)",
                     status.status, waveform.type);
                break;

            case VTMBPStatusINVAIL:               // 0xFF
                DLog(@"BP status invalid (0xFF)");
                break;
        }

        // packet_t 在堆上，用完必须释放
        VTMFreeBPRealTimeData(&bpData);

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
        NSString *textStr = _funcArray[_curIdxPath.section];
        if ([textStr isEqual:@"Download file"]) {
            [self showAlertWithTitle:[NSString stringWithFormat:@"%lu%@", (unsigned long)downloadArr.count, downloadArr.count > 1 ? @"records" : @"record"] message:fileStr handler:^(UIAlertAction *action) {
                if (downloadArr.count > 0) {
                    self.downloadName = downloadArr[arc4random() % downloadArr.count];
                    [[VTMProductURATUtils sharedInstance] prepareReadFile:self.downloadName];
                }else{
                    [self.progressHUD hideAnimated:YES];
                }
            }];
        } else {
            if (!downloadArr.count) return;
            NSString *firstFile = downloadArr[0];
            [[VTMProductURATUtils sharedInstance] deleteFile:firstFile];
            [self.progressHUD showAnimated:YES];
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
        Byte *b = _downloadData.mutableBytes;
        int type = b[1]; // BP2 -- ECG/BP ; BP2A -- BP
        if (type == 2) { //   ECG
            VTMBPECGResult result = [VTMBLEParser parseECGResult:[_downloadData subdataWithRange:NSMakeRange(0, sizeof(VTMBPECGResult))]];
            DLog(@"fileName:%@\tHeart Rate: %d", self.downloadName,result.hr);
            NSArray *ecgWaveArr = [VTMBLEParser parseBPPoints:[_downloadData subdataWithRange:NSMakeRange(sizeof(VTMBPECGResult), _downloadData.length - sizeof(VTMBPECGResult))]];
            VTRecordEcgController *vc = [[VTRecordEcgController alloc] init];
            vc.ecgPoints = ecgWaveArr;
            vc.title = self->_downloadName;
//            vc.sampleRate = 250;
            [self.navigationController pushViewController:vc animated:YES];
        }else if (type == 1){ // BP
            VTMBPBPResult result = [VTMBLEParser parseBPResult:_downloadData];
            DLog(@"fileName:%@\tDIA: %d\tSYS: %d\tMAP: %d\tPR: %d", self.downloadName,result.diastolic_pressure, result.systolic_pressure, result.mean_pressure, result.pulse_rate);
        }else {
            DLog(@"Error");
        }
        
        [self showAlertWithTitle:@"Download successfully" message:nil handler:^(UIAlertAction *action) {
            
            
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
        
    } else if (cmdType == VTMBLECmdDeleteFile) {
        [self.progressHUD hideAnimated:YES];
        [self showAlertWithTitle:@"Deleted" message:nil handler:nil];
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
