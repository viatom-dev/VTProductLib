//
//  VTMRealVC.m
//  VTMProductSDK
//
//  Created by viatom on 2020/6/29.
//  Copyright © 2020 viatom. All rights reserved.
//

#import "VTMRealVC.h"
#import "LPEcgRealWaveformView.h"
#import "VTMScaleUtils.h"

#import "VTMProductSDK-Swift.h"


typedef enum : NSUInteger {
    DeviceStatusSleep = 0,
    DeviceStatusMemery,
    DeviceStatusCharge,
    DeviceStatusReady,
    DeviceStatusBPMeasuring,
    DeviceStatusBPMeasureEnd,
    DeviceStatusECGMeasuring,
    DeviceStatusECGMeasureEnd,
} DeviceStatus;


@interface VTMRealVC ()<VTMURATUtilsDelegate>
@property (nonatomic, strong) UILabel *descLab;
@property (nonatomic, copy) NSArray *array;
@property (nonatomic, strong) LPEcgRealWaveformView *waveformView;
@property (nonatomic, strong) UILabel *weightLabel;

@property (nonatomic, strong) UIButton *measureButton;

@property (nonatomic, assign) VTMER3ShowLead showLead;

@end

@implementation VTMRealVC
{
    NSTimer *_timer;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [VTMProductURATUtils sharedInstance].delegate = self;
}
- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [VTMProductURATUtils sharedInstance].delegate = nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.waveformView];
    self.title = @"Real-time data";
    if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeScale) {
        [self.view addSubview:self.weightLabel];
    }
    
    // correct interval of request real-data.
    float interval = 0.5;
    if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeECG) {
        interval = 0.5;
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeBP) {
        interval = 0.2;
    }
    _showLead = VTMER3ShowLead_II;
    _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(requestRealtimeData) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer
                                 forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void)dealloc{
    [_timer invalidate];
    _timer = nil;
}

- (void)setType:(int)type{
    _type = type;
}

- (void)requestRealtimeData{
    DLog(@"Request real-time data");
    if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeScale) {
        [[VTMProductURATUtils sharedInstance]requestScaleRealData];
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeBP){
        [[VTMProductURATUtils sharedInstance]requestBPRealData];
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeER3) {
        [[VTMProductURATUtils sharedInstance] requestER3ECGRealData];
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeWOxi) {
        [[VTMProductURATUtils sharedInstance] woxi_requestWOxiRealData];
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeFOxi) {
        //
    }else{
        [[VTMProductURATUtils sharedInstance]requestECGRealData];
    }
}
#pragma mark -- vt communicate
- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData *)response{
    
    switch (deviceType) {
        case VTMDeviceTypeECG:
        {
            if (cmdType == VTMECGCmdGetRealData) {
                NSMutableArray *tempArray = [NSMutableArray array];
                VTMRealTimeData rd = [VTMBLEParser parseRealTimeData:response];
                VTMRealTimeWF wf = rd.waveform;
                for (int i = 0; i < wf.sampling_num; i ++) {
                    short mv = wf.wave_data[i];
                    if (wf.wave_data[i] != 0x7FFF) {// invalid Value
                        [tempArray addObject:@([VTMBLEParser mVFromShort:mv])];
                    }
                }
                NSArray *filterArr = [[VTMFilter shared] sfilterPointValue:tempArray];
                _waveformView.receiveArray = filterArr;
                
                // MARK: heart rate
                NSLog(@"heart rate: %d", rd.run_para.hr);
                // MARK: recording time
                NSLog(@"recording time: %d s", rd.run_para.record_time);
                // MARK: battery
                NSLog(@"battery: %d %%", rd.run_para.percent);
                // MARK: battery status  0x00-normal  0x01-charging  0x02-full 0x03-low
                NSLog(@"battery status: %d", (rd.run_para.sys_flag >> 6)&0x03);
                // MARK: run status 0x00-standby  0x01-prepare  0x02-recording 0x03-saving 0x04-saved 0x05-record time less than 30s 0x06-
                NSLog(@"run status: %d", rd.run_para.run_status&0x0F);
                // MARK: reinitialize
                NSLog(@"reinitialize: %d", (rd.run_para.sys_flag >> 1)&0x01);
                // MARK: weak signal
                NSLog(@"weak signal: %d", (rd.run_para.sys_flag >> 2)&0x01);
            }
        }
            break;
        case VTMDeviceTypeScale:
        {
            if (cmdType == VTMSCALECmdGetRealData) {
                NSMutableArray *tempArray = [NSMutableArray array];
                NSMutableString *tempStr = [NSMutableString string];
                VTMScaleRealData rd = [VTMBLEParser parseScaleRealData:response];
                CGFloat weight =  [VTMScaleUtils getRealWeightFormOriginal:rd.scale_data];;
                NSInteger status = (int)rd.run_para.run_status ;
                VTMRealTimeWF wf = rd.waveform;
                for (int i = 0; i < wf.sampling_num; i ++) {
                    short mv = wf.wave_data[i];
                    [tempStr appendString:[NSString stringWithFormat:@"%d\n", mv]];
                    if (wf.wave_data[i] != 0x7FFF) {
                        [tempArray addObject:@([VTMBLEParser mVFromShort:mv])];
                    }
                }
                NSArray *filterArr = [[VTMFilter shared] sfilterPointValue:tempArray];//心电波形
                _waveformView.receiveArray = filterArr;
                _weightLabel.text = [NSString stringWithFormat:@"weight:%.1fkg",weight];
                //run status  0:待机 1:秤端测量中 2:秤端测量结束 3:心电准备阶段 4:心电测量中 5:心电正常结束 6:带阻抗心电异常结束  7:不带阻抗异常结束
                if (status == 5 || status == 6 || status == 7) {
                    DLog(@"Complete Measure");
                }
            }
        }
            break;
        case VTMDeviceTypeBP:{
            if (cmdType == VTMBPCmdGetRealData) {
                VTMBPRealTimeData bpData = [VTMBLEParser parseBPRealTimeData:response];
                DLog(@"run_status:%hhu",bpData.run_status);
                switch (bpData.run_status.status) {
                    case DeviceStatusSleep:
                        break;
                    case DeviceStatusMemery:
                        break;
                    case DeviceStatusReady:
                        break;
                    case DeviceStatusBPMeasuring:{
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMBPMeasuringData measuringData = [VTMBLEParser parseBPMeasuringData:data];
                        if (measuringData.is_deflating_2) {
                            // Plot the pulse wave
                            for (int i = 0; i < bpData.rt_wav.wav.sampling_num ; i++) {
                                short val = bpData.rt_wav.wav.wave_data[i];
                            }
                        }
                    }
                        break;
                    case DeviceStatusBPMeasureEnd:{
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMBPEndMeasureData endMeasureData = [VTMBLEParser parseBPEndMeasureData:data];
                        if (endMeasureData.state_code == 0 ||
                            endMeasureData.state_code == 0x0E) {
                            // Display the result
                            NSLog(@"%d. %d", endMeasureData.diastolic_pressure , endMeasureData.systolic_pressure);
                        }else {
                            // Measure failed. View state_code.
                        }
                        
                        [VTSwiftParser swift_parseBPEndMeasureDataWithResponse:data];
                        
                    }
                        break;
                    case DeviceStatusECGMeasuring:{
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMECGMeasuringData ecgMeasuringData = [VTMBLEParser parseECGMeasuringData:data];
                        NSMutableArray *tempArray = [NSMutableArray array];
                        
                        for (int i = 0; i < bpData.rt_wav.wav.sampling_num ; i++) {
                            if (bpData.rt_wav.wav.wave_data[i] != 0x7FFF) {
                                float mV = [VTMBLEParser bpMvFromShort:bpData.rt_wav.wav.wave_data[i]];  // BP2 covert mV
                                [tempArray addObject:@(mV)];
                            }
                        }
                        NSArray *filterArr = [[VTMFilter shared] sfilterPointValue:tempArray];//心电波形
                        NSLog(@"%@", tempArray);
                        _waveformView.isBpWave = YES;
                        _waveformView.receiveArray = filterArr;
                    }
                        break;
                    case DeviceStatusECGMeasureEnd:{
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMECGEndMeasureData ecgEndMeasueData = [VTMBLEParser parseECGEndMeasureData:data];
        
                    }
                        break;
                    default:
                        break;
                }
                
            }
        }
            break;
        case VTMDeviceTypeER3: {
            if (cmdType == VTMER3ECGCmdGetRealData) {
                NSMutableArray *tempArray = [NSMutableArray array];
                // 1、Parsing real-time data
                VTMER3RealTimeData rd = [VTMBLEParser parseER3RealTimeData:response];
                VTMER3RunParams runParams = rd.run_params;
                /* Notes
                 /// @brief er3. RealTimeParameters
                 typedef  struct {
                     unsigned char run_status;           ///< Running status 0: Idle, 1: Detecting leads, 2: Preparing for measurement, 3: Recording
                     VTMER3UTCTime start_time;           ///< Measurement start time
                     unsigned int record_time;           ///< Recorded duration unit: second
                     unsigned char battery_state;        ///< Battery status 0: normal use, 1: charging, 2: fully charged, 3: low battery
                     unsigned char battery_percent;      ///< Battery power e.g. 100: 100%
                     unsigned char reserved[6];          ///< reserved
                     // ECG
                     unsigned char ecg_cable_state;      ///< Cable status
                     VTMER3Cable cable_type;             ///< Cable type
                     unsigned short electrodes_state;    ///< Electrode status bit0-9 RA LA LL RL V1 V2 V3 V4 V5 V6     (0:ON  1:OFF)
                     unsigned short ecg_hr;              ///< heart rate
                     unsigned char ecg_flag;             ///< Real-time running mark bit0: R wave identification
                     unsigned char ecg_resp_rate;        ///< respiratory rate
                     ....
                 } CG_BOXABLE VTMER3RunParams;
                 */
                if (runParams.run_status == 1) {
                    self.measureButton.hidden = YES;
                } else {
                    self.measureButton.hidden = NO;
                    if (runParams.run_status == 0) {
                        self.measureButton.selected = NO;
                    } else {
                        self.measureButton.selected = YES;
                    }
                }
                
                NSArray *titleArr = [VTMBLEParser showTitlesWithCable:runParams.cable_type];
                NSArray *typeArr = [VTMBLEParser showTypesWithCable:runParams.cable_type];
                VTMER3LeadState leadState = [VTMBLEParser parseCable:runParams.cable_type state:runParams.electrodes_state];
                if (self.view.subviews.count <= 2) {
                    for (int i = 0; i < titleArr.count; i ++) {
                        UIButton *btn = [[UIButton alloc] init];
                        btn.tag = 100 + i;
                        [btn setTitle:titleArr[i] forState:UIControlStateNormal];
                        [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
                        [btn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
                        [btn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
                        [btn addTarget:self action:@selector(changeLead:) forControlEvents:UIControlEventTouchUpInside];
                        [self.view addSubview:btn];
                        int row = i / 6;
                        int col = i % 6;
                        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.left.equalTo(self.view).with.offset(20 + col * (50 + 8));
                            make.top.equalTo(self.measureButton.mas_bottom).with.offset(40 + row * (50 + 8));
                            make.width.mas_equalTo(50);
                            make.height.mas_equalTo(50);
                        }];
                    }
                }
                
                for (int i = 0; i < titleArr.count; i ++) {
                    UIButton *btn = (UIButton *)[self.view viewWithTag:i+100];
                    btn.enabled = !((leadState.value >> i ) & 0x01);
                    if (i == _showLead) {
                        [btn setSelected:YES];
                    }
                }
                
                
                // 2、Intercept waveform data
                NSUInteger loc = sizeof(VTMER3RealTimeData);
                NSData *waveData = [response subdataWithRange:NSMakeRange(loc, response.length - loc)];
                // 3、All waveform points for all 12 leads。VTMER3ShowLead_I, VTMER3ShowLead_II, .., VTMER3ShowLead_V6
                NSArray<NSArray *> *leadsPoints = [VTMBLEParser parseER3RealWaveData:waveData withCable:runParams.cable_type andState:runParams.electrodes_state];
                // 4、Draw one of the leads。eg VTMER3ShowLead_II
                _waveformView.isBpWave = YES;
                _waveformView.receiveArray = leadsPoints[_showLead];
            } else if (cmdType == VTMER3ECGCmdExitMeasure) {
                DLog(@"Exit Measure");
            } else if (cmdType == VTMER3ECGCmdStartMeasure) {
                DLog(@"Start Measure");
            }
        }
            break;
        default:
            break;
    }
}

- (void)changeLead:(UIButton *)sender {
    UIButton *preBtn = [self.view viewWithTag:_showLead + 100];
    preBtn.selected = NO;
    sender.selected = !sender.selected;
    _showLead = sender.tag - 100;
}


- (LPEcgRealWaveformView *)waveformView {
    if (!_waveformView) {
        _waveformView = [[LPEcgRealWaveformView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height+40, self.view.frame.size.width, 258)];
    }
    return  _waveformView;
}

- (UILabel *)weightLabel{
    if (!_weightLabel) {
        _weightLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.waveformView.frame)+10, self.view.frame.size.width, 100)];
        _weightLabel.textAlignment = NSTextAlignmentCenter;
        _weightLabel.font = [UIFont systemFontOfSize:20.f];
        [self.view addSubview:_weightLabel];
    }
    return _weightLabel;
}


- (UIButton *)measureButton {
    if (!_measureButton) {
        _measureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _measureButton.frame = CGRectMake((self.view.frame.size.width - 100) * 0.5, CGRectGetMaxY(self.waveformView.frame) + 20, 100, 34.0);
        [_measureButton setTitle:@"Start" forState:UIControlStateNormal];
        [_measureButton setTitleColor:[UIColor colorWithRed:82/255.f green:211/255.f blue:106/255.f alpha:1] forState:UIControlStateNormal];

        [_measureButton setTitle:@"Stop" forState:UIControlStateSelected];
        [_measureButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        
        _measureButton.layer.borderWidth = 0.5;
        _measureButton.layer.borderColor = [UIColor blackColor].CGColor;
        [self.view addSubview:_measureButton];
        [_measureButton addTarget:self action:@selector(clickMeasureButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _measureButton;
}

- (void)clickMeasureButton:(UIButton *)sender {
    if (sender.isSelected) {
        // stop measure
        [[VTMProductURATUtils sharedInstance] exitER3MeasurementMode];
    } else {
        // start measure
        [[VTMProductURATUtils sharedInstance] startER3MeasurementMode];
    }
}

@end
