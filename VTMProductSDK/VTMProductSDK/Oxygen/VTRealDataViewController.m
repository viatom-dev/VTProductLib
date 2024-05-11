//
//  VTRealDataViewController.m
//  VTMProductSDK
//
//  Created by yangweichao on 2023/7/6.
//  Copyright © 2023 viatom. All rights reserved.
//

#import "VTRealDataViewController.h"
#import "LPEcgRealWaveformView.h"
#import "VTRealParamsView.h"
#import "Pulsewave.h"

@interface VTRealDataViewController ()

@property (nonatomic, weak) LPEcgRealWaveformView *waveform;

@property (nonatomic, weak) VTRealParamsView *paramsView;

@property (nonatomic, weak) Pulsewave *pulsewave;


@property (nonatomic, strong) NSTimer *timer;


@end

@implementation VTRealDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.timer setFireDate:[NSDate distantPast]];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (NSTimer *)timer {
    if (!_timer) {
        float interval = 0.5;
        if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeECG) {
            interval = 0.5;
        } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeBP) {
            interval = 0.2;
        } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeER3) {
            
        } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeWOxi) {
            interval = 1;
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(requestRealData) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    return _timer;
}

- (LPEcgRealWaveformView *)waveform {
    if (!_waveform) {
        LPEcgRealWaveformView *waveform = [[LPEcgRealWaveformView alloc] init];
        [self.view addSubview:waveform];
        _waveform = waveform;
        [waveform mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view);
            make.height.equalTo(self.view).multipliedBy(0.6);
        }];
    }
    return _waveform;
}

- (Pulsewave *)pulsewave {
    if (!_pulsewave) {
        Pulsewave *wave = [[Pulsewave alloc] init];
        [self.view addSubview:wave];
        _pulsewave = wave;
        [wave mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(self.view);
            make.height.equalTo(self.view).multipliedBy(0.6);
        }];
    }
    return _pulsewave;
}

- (VTRealParamsView *)paramsView {
    if (!_paramsView) {
        VTRealParamsView *paramsView = [[VTRealParamsView alloc] init];
        [self.view addSubview:paramsView];
        _paramsView = paramsView;
        [paramsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.equalTo(self.view);
            make.height.equalTo(self.view).multipliedBy(0.4);
        }];
    }
    return _paramsView;
}

- (void)requestRealData {
    __weak typeof (self) weakself = self;
    [[VTCOMMPresenter sharedInstance] requestRealDataHandle:^(NSData * _Nonnull realdata, VTMDeviceType type) {
        switch (type) {
            case VTMDeviceTypeECG:
            {
                NSMutableArray *tempArray = [NSMutableArray array];
                VTMRealTimeData rd = [VTMBLEParser parseRealTimeData:realdata];
                VTMRealTimeWF wf = rd.waveform;
                for (int i = 0; i < wf.sampling_num; i ++) {
                    short mv = wf.wave_data[i];
                    if (wf.wave_data[i] != 0x7FFF) {// invalid Value
                        [tempArray addObject:@([VTMBLEParser mVFromShort:mv])];
                    }
                }
                NSArray *filterArr = [[VTMFilter shared] sfilterPointValue:tempArray];
                weakself.waveform.receiveArray = filterArr;
                weakself.paramsView.batteryLabel.text = [NSString stringWithFormat:@"%d %%", rd.run_para.percent];
                NSString *batStaStr = @"normal";
                switch ((rd.run_para.sys_flag >> 6)&0x03) {
                    case 1:
                        batStaStr = @"charging";
                        break;
                    case 2:
                        batStaStr = @"charge full";
                        break;
                    case 3:
                        batStaStr = @"low";
                        break;
                    default:
                        
                        break;
                }
                
                weakself.paramsView.batteryStaLabel.text = batStaStr;
                weakself.paramsView.runStaLabel.text = [NSString stringWithFormat:@"run status: %d", rd.run_para.run_status&0x0F];
                weakself.paramsView.timeLabel.text = [NSString stringWithFormat:@"%dh%dm%ds", rd.run_para.record_time/3600, rd.run_para.record_time/60, rd.run_para.record_time%60];
                weakself.paramsView.param1Label.text = [NSString stringWithFormat:@"HR: %d /min", rd.run_para.hr];
                weakself.paramsView.param2Label.text = [NSString stringWithFormat:@"lead: %d, signal: %d", (rd.run_para.sys_flag >> 3)&0x01, (rd.run_para.sys_flag >> 2)&0x01];
                
                
                // MARK: heart rate
                DLog(@"heart rate: %d", rd.run_para.hr);
                // MARK: recording time
                DLog(@"recording time: %d s", rd.run_para.record_time);
                // MARK: battery
                DLog(@"battery: %d %%", rd.run_para.percent);
                // MARK: battery status  0x00-normal  0x01-charging  0x02-full 0x03-low
                DLog(@"battery status: %d", (rd.run_para.sys_flag >> 6)&0x03);
                // MARK: run status 0x00-standby  0x01-prepare  0x02-recording 0x03-saving 0x04-saved 0x05-record time less than 30s 0x06-
                DLog(@"run status: %d", rd.run_para.run_status&0x0F);
                // MARK: reinitialize
                DLog(@"reinitialize: %d", (rd.run_para.sys_flag >> 1)&0x01);
                // MARK: weak signal
                DLog(@"weak signal: %d", (rd.run_para.sys_flag >> 2)&0x01);
                
            }
                break;
            case VTMDeviceTypeScale:
            {
                
                NSMutableArray *tempArray = [NSMutableArray array];
                NSMutableString *tempStr = [NSMutableString string];
                VTMScaleRealData rd = [VTMBLEParser parseScaleRealData:realdata];
//                CGFloat weight =  [VTMScaleUtils getRealWeightFormOriginal:rd.scale_data];;
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
                weakself.waveform.receiveArray = filterArr;
//                _weightLabel.text = [NSString stringWithFormat:@"weight:%.1fkg",weight];
                //run status  0:待机 1:秤端测量中 2:秤端测量结束 3:心电准备阶段 4:心电测量中 5:心电正常结束 6:带阻抗心电异常结束  7:不带阻抗异常结束
                if (status == 5 || status == 6 || status == 7) {
                    DLog(@"Complete Measure");
                }
                
            }
                break;
            case VTMDeviceTypeBP:
            {
                
                VTMBPRealTimeData bpData = [VTMBLEParser parseBPRealTimeData:realdata];
//                DLog(@"run_status:%hhu",bpData.run_status);
                self.paramsView.batteryLabel.text = [NSString stringWithFormat:@"%d%%", bpData.run_status.battery.percent];
                
                // 0:Normal 1:Charging 2:charge full 3:low
                NSString *batStaStr = @"normal";
                switch (bpData.run_status.battery.state) {
                    case 1:
                        batStaStr = @"charging";
                        break;
                    case 2:
                        batStaStr = @"charge full";
                        break;
                    case 3:
                        batStaStr = @"low";
                        break;
                    default:
                        
                        break;
                }
                self.paramsView.batteryStaLabel.text = batStaStr;
                NSString *runStaStr = @"";
                switch (bpData.run_status.status) {
                    case BPStateInactive:
                        runStaStr = @"inactive";
                        break;
                    case BPStateMemory:
                        runStaStr = @"History";
                        break;
                    case BPStateReady:
                        runStaStr = @"ready";
                        [weakself.waveform clearChache];
                        break;
                    case BPStateBPMeasuring:{
                        runStaStr = @"BP measuring";
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMBPMeasuringData measuringData = [VTMBLEParser parseBPMeasuringData:data];
                        
                        weakself.paramsView.param1Label.text = [NSString stringWithFormat:@"pressure: %d mmHg", measuringData.pressure /100];
//                        self.paramsView.param2Label.text = [NSString stringWithFormat:@"PR: %d /min", measuringData.pulse_rate ];
                        if (measuringData.is_deflating_2) {
                            // Plot the pulse wave
                            for (int i = 0; i < bpData.rt_wav.wav.sampling_num ; i++) {
                                short val = bpData.rt_wav.wav.wave_data[i];
                            }
                        }
                    }
                        break;
                    case BPStateBPMeasureEnd:{
                        runStaStr = @"BP result";
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMBPEndMeasureData endMeasureData = [VTMBLEParser parseBPEndMeasureData:data];
                        if (endMeasureData.state_code == 0 ||
                            endMeasureData.state_code == 0x0E) {
                            // Display the result
                            
                            weakself.paramsView.param1Label.text = [NSString stringWithFormat:@"%d/%d mmHg", endMeasureData.systolic_pressure,endMeasureData.diastolic_pressure];
                            weakself.paramsView.param2Label.text = [NSString stringWithFormat:@"PR: %d /min", endMeasureData.pulse_rate];
                            
                        }else {
                            // Measure failed. View state_code.
                            weakself.paramsView.param1Label.text = [NSString stringWithFormat:@"error: %d", endMeasureData.state_code];
                            weakself.paramsView.param2Label.text = [NSString stringWithFormat:@"--"];
                        }
                    }
                        break;
                    case BPStateECGMeasuring:{
                        runStaStr = @"ECG measuring";
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMECGMeasuringData ecgMeasuringData = [VTMBLEParser parseECGMeasuringData:data];
                        weakself.paramsView.timeLabel.text = [NSString stringWithFormat:@"%d s", ecgMeasuringData.duration];
                        weakself.paramsView.param1Label.text = [NSString stringWithFormat:@"HR: %d", ecgMeasuringData.pulse_rate];
                        weakself.paramsView.param2Label.text = [NSString stringWithFormat:@"lead: %d, signal: %d", (ecgMeasuringData.special_status >> 1) & 0x01, ecgMeasuringData.special_status & 0x01];
                        
                        NSMutableArray *tempArray = [NSMutableArray array];
                        
                        for (int i = 0; i < bpData.rt_wav.wav.sampling_num ; i++) {
                            if (bpData.rt_wav.wav.wave_data[i] != 0x7FFF) {
                                float mV = [VTMBLEParser bpMvFromShort:bpData.rt_wav.wav.wave_data[i]];  // BP2 covert mV
                                [tempArray addObject:@(mV)];
                            }
                        }
                        NSArray *filterArr = [[VTMFilter shared] sfilterPointValue:tempArray];//心电波形
                        weakself.waveform.isBpWave = YES;
                        weakself.waveform.receiveArray = filterArr;
                    }
                        break;
                    case BPStateECGMeasureEnd:{
                        runStaStr = @"ECG result";
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMECGEndMeasureData ecgEndMeasueData = [VTMBLEParser parseECGEndMeasureData:data];
                        weakself.paramsView.param1Label.text = [NSString stringWithFormat:@"HR: %d", ecgEndMeasueData.hr];
                        weakself.paramsView.param2Label.text = [NSString stringWithFormat:@"result: %d", ecgEndMeasueData.result];
                        [weakself.waveform clearChache];
                    }
                        break;
                    default:
                        break;
                }
                
                self.paramsView.runStaLabel.text = runStaStr;
                
            }
                break;
            case VTMDeviceTypeER3:
                
                break;
            case VTMDeviceTypeWOxi: 
            {
                VTMWOxiRealData rd = [VTMBLEParser woxi_parseRealData:realdata];
                weakself.paramsView.batteryLabel.text = [NSString stringWithFormat:@"%d%%", rd.run_para.battery_percent];
                
                // 0:Normal 1:Charging 2:charge full 3:low
                NSString *batStaStr = @"normal";
                switch (rd.run_para.battery_state) {
                    case 1:
                        batStaStr = @"charging";
                        break;
                    case 2:
                        batStaStr = @"charge full";
                        break;
                    case 3:
                        batStaStr = @"low";
                        break;
                    default:
                        
                        break;
                }
                weakself.paramsView.batteryStaLabel.text = batStaStr;
                
                NSString *runStaStr = @"normal";
                switch (rd.run_para.run_status) {
                    case 0:
                        runStaStr = @"standby";
                        break;
                    case 1:
                        runStaStr = @"prepare to measure";
                        break;
                    case 2:
                        runStaStr = @"measuring";
                        break;
                    case 3:
                        runStaStr = @"measure end";
                        break;
                    default:
                        break;
                }
                weakself.paramsView.runStaLabel.text = runStaStr;
                
                weakself.paramsView.timeLabel.text = [NSString stringWithFormat:@"%d s", rd.run_para.record_time];
                
                weakself.paramsView.param1Label.text = [NSString stringWithFormat:@"SpO2:%d, PR: %d", rd.run_para.spo2, rd.run_para.pr];
                
                weakself.paramsView.param2Label.text = [NSString stringWithFormat:@"Motion:%d, PI: %.1f", rd.run_para.motion, rd.run_para.pi/10.0];
                
                NSMutableArray *tempArr = [NSMutableArray array];
                for (int i = 0; i < rd.waveform.sampling_num; i ++) {
                    [tempArr addObject:@(rd.waveform.waveform_data[i])];
                }
                weakself.pulsewave.receiveArray = tempArr.copy;
            }
                break;
            default:
                break;
        }
    }];
    
}

@end
