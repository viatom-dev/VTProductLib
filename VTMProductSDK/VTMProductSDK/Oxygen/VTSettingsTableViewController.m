//
//  VTSettingsTableViewController.m
//  VTMProductSDK
//
//  Created by yangweichao on 2023/8/10.
//  Copyright © 2023 viatom. All rights reserved.
//

#import "VTSettingsTableViewController.h"


@interface VTSettingCellModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, assign) int type;
@property (nonatomic, copy) void(^DidSelected)(void);
@property (nonatomic, copy) void(^DidChanged)(BOOL on);

@end

@implementation VTSettingCellModel

- (instancetype)initWithTitle:(NSString *)title detail:(NSString *)detail type:(int)type {
    self = [super init];
    if (self) {
        self.title = title;
        self.detail = detail;
        self.type = type;
    }
    return self;
}

@end


@interface VTSettingsTableViewController ()

@property (nonatomic, strong) NSMutableArray *infoArr;

@property (nonatomic, strong) NSMutableArray *configArr;

@property (nonatomic, strong) UIAlertController *alertController;

@property (nonatomic, copy) NSData *configData;


@end

@implementation VTSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestDeivceInfo];
    
}


#pragma mark - request

- (void)requestDeivceInfo {
    __weak typeof(self) weakself = self;
    
    [[VTCOMMPresenter sharedInstance] requestDeviceInfoHandle:^(VTMDeviceInfo info) {
        [weakself.infoArr removeAllObjects];
        u_char kf = (info.fw_version >> 24) & 0xff;
        u_char k0 = (info.fw_version >> 16) & 0xff;
        u_char k1 = (info.fw_version >> 8) & 0xff;
        u_char k2 = info.fw_version;
        NSString *fwVersion = [NSString stringWithFormat:@"%d.%d.%d.%d",kf == 0 ? 1 : kf,k0,k1,k2];
        VTSettingCellModel *cellModel0 = [[VTSettingCellModel alloc] initWithTitle:@"Firmware Version" detail:fwVersion type:2];
        [weakself.infoArr addObject:cellModel0];
        
        NSString *hwVersion = [NSString stringWithFormat:@"%c", info.hw_version];
        VTSettingCellModel *cellModel1 = [[VTSettingCellModel alloc] initWithTitle:@"Hardware Version" detail:hwVersion type:2];
        [weakself.infoArr addObject:cellModel1];
        
        NSMutableString *snStr = [NSMutableString string];
        for (int i = 0; i < info.sn.len; i ++) {
            [snStr appendFormat:@"%c", info.sn.serial_num[i]];
        }
        VTSettingCellModel *cellModel2 = [[VTSettingCellModel alloc] initWithTitle:@"SN" detail:snStr type:2];
        [weakself.infoArr addObject:cellModel2];
        
        short year = *((short *)&info.cur_time[0]);
        char month = info.cur_time[2];
        char day = info.cur_time[3];
        char hour = info.cur_time[4];
        char minute = info.cur_time[5];
        char second = info.cur_time[6];
        
        NSString *timeStr = [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second];
        
        VTSettingCellModel *cellModel3 = [[VTSettingCellModel alloc] initWithTitle:@"Date" detail:timeStr type:0];
        [weakself.infoArr addObject:cellModel3];
        cellModel3.DidSelected = ^{
            [[VTCOMMPresenter sharedInstance] syncDeviceTime:[NSDate date] response:^(BOOL succeed) {
                if (succeed) {
                    // 刷新当前时间
                    [weakself requestDeivceInfo];
                }
            }];
        };
        
        [weakself.tableView reloadData];
        
        [weakself requestConfig];
    }];
}

- (void)requestConfig {
    __weak typeof(self) weakself = self;
    
    [[VTCOMMPresenter sharedInstance] requestDeviceConfigHandle:^(NSData * _Nonnull configData, VTMDeviceType type) {
        weakself.configData = configData;
        [weakself.configArr removeAllObjects];
        if (type == VTMDeviceTypeECG) {
//            VTMConfig config = [VTMBLEParser parseER1Config:configData];
            if (configData.length == sizeof(VTMER1Config)) {
                VTMER1Config er1Config = [VTMBLEParser parseER1Config:configData];
                
                VTSettingCellModel *swiModel = [[VTSettingCellModel alloc] initWithTitle:@"Vibrate switch" detail:[NSString stringWithFormat:@"%d", er1Config.vibeSw] type:1];
                [weakself.configArr addObject:swiModel];
                swiModel.DidChanged = ^(BOOL on) {
                    VTMER1Config er1Config = [VTMBLEParser parseER1Config:weakself.configData];
                    er1Config.vibeSw = on;
                    [[VTCOMMPresenter sharedInstance] syncDeivceConfig:[NSValue value:&er1Config withObjCType:@encode(VTMER1Config)] configSize:sizeof(VTMER1Config) response:^(BOOL succeed) {
                        if (succeed) {
                            [weakself requestConfig];
                        }
                    }];
                };
                
                VTSettingCellModel *lowModel = [[VTSettingCellModel alloc] initWithTitle:@"Low" detail:[NSString stringWithFormat:@"%d /min", er1Config.hrTarget1] type:0];
                [weakself.configArr addObject:lowModel];
                lowModel.DidSelected = ^{
                    VTMER1Config er1Config = [VTMBLEParser parseER1Config:weakself.configData];
                    er1Config.hrTarget1 = er1Config.hrTarget2 - arc4random()%80;
                    NSValue *value = [NSValue value:&er1Config withObjCType:@encode(VTMER1Config)];
                    [[VTCOMMPresenter sharedInstance] syncDeivceConfig:value configSize:sizeof(VTMER1Config) response:^(BOOL succeed) {
                        if (succeed) {
                            [weakself requestConfig];
                        }
                    }];
                };
            
                VTSettingCellModel *highModel = [[VTSettingCellModel alloc] initWithTitle:@"High" detail:[NSString stringWithFormat:@"%d /min", er1Config.hrTarget2] type:0];
                [weakself.configArr addObject:highModel];
                lowModel.DidSelected = ^{
                    VTMER1Config er1Config = [VTMBLEParser parseER1Config:weakself.configData];
                    er1Config.hrTarget2 = er1Config.hrTarget1 + arc4random()%80;
                    NSValue *value = [NSValue value:&er1Config withObjCType:@encode(VTMER1Config)];
                    [[VTCOMMPresenter sharedInstance] syncDeivceConfig:value configSize:sizeof(VTMER1Config) response:^(BOOL succeed) {
                        if (succeed) {
                            [weakself requestConfig];
                        }
                    }];
                };
                
                

            } else {
                VTMER2Config er2Config = [VTMBLEParser parseER2Config:configData];
                VTSettingCellModel *swiModel = [[VTSettingCellModel alloc] initWithTitle:@"Beat switch" detail:[NSString stringWithFormat:@"%d", er2Config.ecgSwitch] type:YES];
                [weakself.configArr addObject:swiModel];
                swiModel.DidChanged = ^(BOOL on) {
                    VTMER2Config er2Config = [VTMBLEParser parseER2Config:weakself.configData];
                    er2Config.ecgSwitch = on;
                    [[VTCOMMPresenter sharedInstance] syncDeivceConfig:[NSValue value:&er2Config withObjCType:@encode(VTMER2Config)] configSize:sizeof(VTMER2Config) response:^(BOOL succeed) {
                        if (succeed) {
                            [weakself requestConfig];
                        }
                    }];
                };
            }
        } else if ( type == VTMDeviceTypeBP ) {
            
            VTMBPConfig bpConfig = [VTMBLEParser parseBPConfig:configData];
            
            VTSettingCellModel *swiModel = [[VTSettingCellModel alloc] initWithTitle:@"switch" detail:[NSString stringWithFormat:@"%d", bpConfig.device_switch] type:1];
            [weakself.configArr addObject:swiModel];
            swiModel.DidChanged = ^(BOOL on) {
                VTMBPConfig bpConfig = [VTMBLEParser parseBPConfig:weakself.configData];
                bpConfig.device_switch = on;
                [[VTCOMMPresenter sharedInstance] syncDeivceConfig:[NSValue value:&bpConfig withObjCType:@encode(VTMBPConfig)] configSize:sizeof(VTMBPConfig) response:^(BOOL succeed) {
                    if (succeed) {
                        [weakself requestConfig];
                    }
                }];
            };

        } else if ( type == VTMDeviceTypeWOxi) {
            VTMWOxiInfo info = [VTMBLEParser woxi_parseConfig:configData];
            VTSettingCellModel *spo2thrModel = [[VTSettingCellModel alloc] initWithTitle:@"SpO2 threshold" detail:[NSString stringWithFormat:@"%d %%", info.spo2_thr] type:0];
            [weakself.configArr addObject:spo2thrModel];
            spo2thrModel.DidSelected = ^{
                // Adjust according to PRD.
                [weakself paramValue:arc4random()%16+80 type:VTMWOxiSetParamsSpO2Thr];
            };
            
            VTSettingCellModel *motorModel = [[VTSettingCellModel alloc] initWithTitle:@"Motor" detail:[NSString stringWithFormat:@"%d", info.motor] type:0];
            [weakself.configArr addObject:motorModel];
            motorModel.DidSelected = ^{
                // [0, 100]
                [weakself paramValue:arc4random()%101 type:VTMWOxiSetParamsMotor];
            };
            
            
            VTSettingCellModel *lightModeModel = [[VTSettingCellModel alloc] initWithTitle:@"lighting Mode" detail:[NSString stringWithFormat:@"%d", info.display_mode] type:0];
            [weakself.configArr addObject:lightModeModel];
            lightModeModel.DidSelected = ^{
                // 0 or 2
                [weakself paramValue:arc4random()%2*2 type:VTMWOxiSetParamsDisplayMode];
            };
            
            VTSettingCellModel *prSwiModel = [[VTSettingCellModel alloc] initWithTitle:@"PR switch" detail:[NSString stringWithFormat:@"%d", (info.remind_switch >> 4) & 0x01] type:1];
            [weakself.configArr addObject:prSwiModel];
            prSwiModel.DidChanged = ^(BOOL on) {
                [weakself paramValue:on type:VTMWOxiSetParamsHRSw];
            };
            
            VTSettingCellModel *lowModel = [[VTSettingCellModel alloc] initWithTitle:@"PR Low threshold" detail:[NSString stringWithFormat:@"%d /min", info.hr_thr_low] type:0];
            [weakself.configArr addObject:lowModel];
            lowModel.DidSelected = ^{
                // Adjust according to PRD.
                [weakself paramValue:arc4random()%41 + 30  type:VTMWOxiSetParamsHRThrLow];
            };
            
            VTSettingCellModel *highModel = [[VTSettingCellModel alloc] initWithTitle:@"PR High threshold" detail:[NSString stringWithFormat:@"%d /min", info.hr_thr_high] type:0];
            [weakself.configArr addObject:highModel];
            highModel.DidSelected = ^{
                // Adjust according to PRD.
                [weakself paramValue:arc4random()%111 + 90  type:VTMWOxiSetParamsHRThrHigh];
            };
            
            VTSettingCellModel *strengthModel = [[VTSettingCellModel alloc] initWithTitle:@"Light strength" detail:[NSString stringWithFormat:@"%d", info.brightness] type:0];
            [weakself.configArr addObject:strengthModel];
            strengthModel.DidSelected = ^{
                // [0, 2]
                [weakself paramValue:arc4random()%3 type:VTMWOxiSetParamsBrightness];
            };
            
            VTSettingCellModel *buzzerModel = [[VTSettingCellModel alloc] initWithTitle:@"Buzzer" detail:[NSString stringWithFormat:@"%d", info.buzzer] type:0];
            [weakself.configArr addObject:buzzerModel];
            buzzerModel.DidSelected = ^{
                // [0, 100]
                [weakself paramValue:arc4random()%101 type:VTMWOxiSetParamsBuzzer];
            };
            
            VTSettingCellModel *spo2SwiModel = [[VTSettingCellModel alloc] initWithTitle:@"SpO2 switch" detail:[NSString stringWithFormat:@"%d", (info.remind_switch >> 0) & 0x01] type:1];
            [weakself.configArr addObject:spo2SwiModel];
            spo2SwiModel.DidChanged = ^(BOOL on) {
                [weakself paramValue:on type:VTMWOxiSetParamsSpO2Sw];
            };
            
            VTSettingCellModel *intervalModel = [[VTSettingCellModel alloc] initWithTitle:@"Store interval" detail:[NSString stringWithFormat:@"%d s", info.interval] type:0];
            [weakself.configArr addObject:intervalModel];
            intervalModel.DidSelected = ^{
                // default is 4s, you can set 1 or 2 or 4.
                [weakself paramValue:4 type:VTMWOxiSetParamsInterval];
            };

            
        } else if ( type == VTMDeviceTypeFOxi) {
            VTMFOxiConfig info = [VTMBLEParser foxi_parseConfig:configData];
            VTSettingCellModel *spo2thrModel = [[VTSettingCellModel alloc] initWithTitle:@"SpO2 threshold" detail:[NSString stringWithFormat:@"%d %%", info.spo2Low] type:0];
            [weakself.configArr addObject:spo2thrModel];
            spo2thrModel.DidSelected = ^{
                // Adjust according to PRD.
                [weakself paramValue:arc4random()%16+80 type:VTMFOxiSetParamsSpO2Low];
            };
            
            VTSettingCellModel *lowModel = [[VTSettingCellModel alloc] initWithTitle:@"PR Low threshold" detail:[NSString stringWithFormat:@"%d /min", info.prLow] type:0];
            [weakself.configArr addObject:lowModel];
            lowModel.DidSelected = ^{
                // Adjust according to PRD.
                [weakself paramValue:arc4random()%41 + 30  type:VTMFOxiSetParamsPRLow];
            };
            
            VTSettingCellModel *highModel = [[VTSettingCellModel alloc] initWithTitle:@"PR High threshold" detail:[NSString stringWithFormat:@"%d /min", info.prHigh] type:0];
            [weakself.configArr addObject:highModel];
            highModel.DidSelected = ^{
                // Adjust according to PRD.
                [weakself paramValue:arc4random()%111 + 90  type:VTMFOxiSetParamsPRHigh];
            };
            
            VTSettingCellModel *alarmModel = [[VTSettingCellModel alloc] initWithTitle:@"Alarm" detail:[NSString stringWithFormat:@"%d", info.alramIsOn] type:1];
            [weakself.configArr addObject:alarmModel];
            alarmModel.DidChanged = ^(BOOL on) {
                [weakself paramValue:on type:VTMFOxiSetParamsAlram];
            };
            
            VTSettingCellModel *beepModel = [[VTSettingCellModel alloc] initWithTitle:@"PR High threshold" detail:[NSString stringWithFormat:@"%d", info.beepIsOn] type:1];
            [weakself.configArr addObject:beepModel];
            beepModel.DidChanged = ^(BOOL on) {
                [weakself paramValue:on type:VTMFOxiSetParamsBeep];
            };
            
            VTSettingCellModel *delayModel = [[VTSettingCellModel alloc] initWithTitle:@"Delay screen" detail:[NSString stringWithFormat:@"%d s", info.esmode] type:0];
            [weakself.configArr addObject:delayModel];
            delayModel.DidSelected = ^{
                // Adjust according to PRD.
                [weakself paramValue:arc4random()%20 type:VTMFOxiSetParamsESMode];
            };
            
            VTSettingCellModel *modeModel = [[VTSettingCellModel alloc] initWithTitle:@"Measure Mode" detail:[NSString stringWithFormat:@"%d", info.measureMode] type:2];
            [weakself.configArr addObject:modeModel];
            
            
        }
        
        [weakself.tableView reloadData];
        
    }];
}

- (void)paramValue:(u_char)val type:(u_char)type {
    VTMOxiParamsOption op;
    op.type = type;
    op.param.val = val;  // [80, 95]
    NSValue *value = [NSValue value:&op withObjCType:@encode(VTMOxiParamsOption)];
    __weak typeof(self) weakself = self;
    [[VTCOMMPresenter sharedInstance] syncDeivceConfig:value configSize:sizeof(VTMOxiParamsOption) response:^(BOOL succeed) {
        if (succeed) {
            [weakself requestConfig];
        }
    }];
}

#pragma mark - setter & getter

- (NSMutableArray *)infoArr {
    if (!_infoArr) {
        _infoArr = [NSMutableArray array];
    }
    return _infoArr;
}

- (NSMutableArray *)configArr {
    if (!_configArr) {
        _configArr = [NSMutableArray array];
    }
    return _configArr;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section)
        return self.configArr.count;
    return self.infoArr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier1 = @"normal";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier1];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier1];
    }
    cell.accessoryView = nil;
    if (indexPath.section == 0) {
        VTSettingCellModel *model = self.infoArr[indexPath.row];
        cell.textLabel.text = model.title;
        cell.detailTextLabel.text = model.detail;
        if (model.type == 0) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

    } else {
        
        VTSettingCellModel *model = self.configArr[indexPath.row];
        cell.textLabel.text = model.title;
        cell.accessoryView = nil;
        if (model.type == 1) {
            cell.detailTextLabel.text = @"";
            UISwitch *swi = [[UISwitch alloc] init];
            swi.on = model.detail.boolValue;
            [swi addTarget:self action:@selector(changeSwitchValue:) forControlEvents:UIControlEventValueChanged];
            swi.tag = 100 + indexPath.row;
            cell.accessoryView = swi;
        } else if (model.type == 0) {
            cell.detailTextLabel.text = model.detail;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.detailTextLabel.text = model.detail;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    }
    // Configure the cell...
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section) {
        return @"Config";
    }
    return @"Info";
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        VTSettingCellModel *model = _infoArr[indexPath.row];
        if(model.DidSelected) model.DidSelected();
    } else {
        VTSettingCellModel *model = _configArr[indexPath.row];
        if(model.DidSelected) model.DidSelected();
    }
    
}

#pragma mark - event

- (void)changeSwitchValue:(UISwitch *)swi {
    NSInteger idx = swi.tag - 100;
    VTSettingCellModel *model = _configArr[idx];
    if (model.DidChanged) model.DidChanged(swi.on);
}

@end
