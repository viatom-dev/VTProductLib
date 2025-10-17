//
//  VTMBabyMonitorMenuVC.m
//  VTMProductSDK
//
//  Created by viatom on 2025/9/3.
//  Copyright © 2025 viatom. All rights reserved.
//

#import "VTMBabyMonitorMenuVC.h"

@interface VTMBabyMonitorMenuVC () <UITableViewDataSource, UITableViewDelegate, VTMURATUtilsDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *listArr;
@property (nonatomic, strong) NSMutableArray *downloadArr;
@property (nonatomic, strong) NSString *downloadName;
@property (nonatomic, assign) u_int downloadLen;
@property (nonatomic, strong) NSMutableData *downloadData;

@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

@implementation VTMBabyMonitorMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = [NSString stringWithFormat:@"%@ connected", [VTBLEUtils sharedInstance].device.advName];
    self.listArr = @[@"Device info", @"Sync time", @"Download file", @"Factory Reset", @"Get Config"];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.tableView = tableView;
    [self.view addSubview:tableView];
    
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [VTMProductURATUtils sharedInstance].delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [VTMProductURATUtils sharedInstance].delegate = nil;
}


- (void)readFile {
    if (!self.downloadArr.count) {
        DLog(@"Download End");
        return;
    }
    self.downloadName = self.downloadArr.firstObject;
    [[VTMProductURATUtils sharedInstance] prepareReadFile:self.downloadName];
}

- (void)parseDownloadFile {
    if ([self.downloadName hasPrefix:@"R"]) {
        // Record File
        [VTMBLEParser baby_parseRecordFile:self.downloadData completion:^(VTMOxiFileHead fileHead, VTMBabyRecordHead head, VTMBabyRecord_t * _Nonnull records, NSInteger recordNum) {
            for (int i = 0 ; i < recordNum; i ++) {
                VTMBabyRecord_t cur_t = records[i];
            }
        }];
    } else if ([self.downloadName hasPrefix:@"E"]) {
        // Event File
        [VTMBLEParser baby_parseEventFile:self.downloadData completion:^(VTMOxiFileHead fileHead, VTMBabyEventHead head, VTMBabyEventLog_t * _Nonnull events, NSInteger recordNum) {
            for (int i = 0; i < recordNum; i ++) {
                VTMBabyEventLog_t t = events[i];
                
            }
        }];
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = self.listArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.progressHUD showAnimated:YES];
    NSInteger row = indexPath.row;
    DLog(@"send: %@", self.listArr[row]);
    switch (row) {
        case 0:
            [[VTMProductURATUtils sharedInstance] requestDeviceInfo];
            break;
        case 1:
            [[VTMProductURATUtils sharedInstance] syncTime:[NSDate date]];
            break;
        case 2:
            [[VTMProductURATUtils sharedInstance] requestFilelist];
            break;
        case 3:
            [[VTMProductURATUtils sharedInstance] factoryReset];
            break;
        case 4:
            [[VTMProductURATUtils sharedInstance] baby_requestConfig];
            break;
        case 5:
            break;
        case 6:
            break;
        default:
            break;
    }
}




- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData *)response {
//    DLog(@"response: %@", response);
    switch (cmdType) {
        case VTMBLECmdGetDeviceInfo: {
            VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
            DLog(@"hw_version: %hhu, fw_version: %hhu, fw_version: %hhu, sn: %s, branch_code: %s", info.hw_version, info.fw_version, info.fw_version, info.sn.serial_num, info.branch_code);
            [self.progressHUD hideAnimated:YES];
            [self showAlertWithTitle:@"Get information successfully" message:[NSString stringWithFormat:@"sn:%s", info.sn.serial_num] handler:nil];
        }
            break;
        case VTMBLECmdSyncTime: {
            DLog(@"Synchronize time successfully");
            [self.progressHUD hideAnimated:YES];
            [self showAlertWithTitle:@"Synchronize time successfully" message:nil handler:nil];
        }
            break;
        case VTMBLECmdGetFileList: {
            VTMFileList list = [VTMBLEParser parseFileList:response];
            self.downloadArr = [NSMutableArray arrayWithCapacity:list.file_num];
            NSMutableString *fileStr = [NSMutableString string];
            for (int i = 0; i < list.file_num; i++) {
                NSMutableString *temp = [NSMutableString string];
                u_char *file_name = list.fileName[i].str;
                size_t fileLen = strlen((char *)file_name);
                for (int j = 0; j < fileLen; j++) {
                    [temp appendString:[NSString stringWithFormat:@"%c",file_name[j]]];
                }
                [self.downloadArr addObject:temp];
                if (i == list.file_num - 1) {
                    [fileStr appendString:[NSString stringWithFormat:@"%@", temp]];
                } else {
                    [fileStr appendString:[NSString stringWithFormat:@"%@\n", temp]];
                }
            }
            
            [self showAlertWithTitle:[NSString stringWithFormat:@"%lu%@", (unsigned long)_downloadArr.count, _downloadArr.count > 1 ? @"records" : @"record"] message:fileStr handler:^(UIAlertAction *action) {
                if (self.downloadArr.count > 0) {
                    [self readFile];
                }else{
                    [self.progressHUD hideAnimated:YES];
                }
            }];
        }
            break;
        case VTMBLECmdStartRead: {
            _downloadLen = 0;
            _downloadData = [NSMutableData data];
            VTMOpenFileReturn fsrr = [VTMBLEParser parseFileLength:response];
            DLog(@"file length: %d", fsrr.file_size);
            _downloadLen = fsrr.file_size;
            if (fsrr.file_size == 0) {
                [[VTMProductURATUtils sharedInstance] endReadFile];
            } else {
                [[VTMProductURATUtils sharedInstance] readFile:0];
            }
        }
            break;
        case VTMBLECmdReadFile: {
            [_downloadData appendData:response];
            DLog(@"Download data length: %d",(int)_downloadData.length);
            if (_downloadData.length == _downloadLen){
                [[VTMProductURATUtils sharedInstance] endReadFile];
            }else{
                [[VTMProductURATUtils sharedInstance] readFile:(u_int)_downloadData.length];
            }
        }
            break;
        case VTMBLECmdEndRead: {
            DLog(@"file: %@ Download successfully", self.downloadName);
            [self.progressHUD hideAnimated:YES];
            
            [self parseDownloadFile];
            
            [self.downloadArr removeObjectAtIndex:0];
            [self readFile];
        }
            break;
        case VTMBLECmdRestore: {
            DLog(@"Factory Settings restored successfully");
            [self.progressHUD hideAnimated:YES];
            [self showAlertWithTitle:@"Factory Settings restored successfully" message:nil handler:nil];
        }
            break;
        case VTMBabyCmdGetConfig: {
            VTMBabyConfig config = [VTMBLEParser baby_parseConfig:response];
            DLog(@"%d", config.alarm_led);
        }
            break;
        case VTMBabyCmdGetRunParams: {
            VTMBabyRunParams runpara = [VTMBLEParser baby_parseRunParams:response];
            DLog(@"Gyros Status: %d Respiratory rate: %d temp: %.01f", runpara.attitude_status, runpara.rr, runpara.cur_temperature / 10.0);
            [self.progressHUD hideAnimated:YES];
        }
            break;
        default:
            break;
    }
}


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
