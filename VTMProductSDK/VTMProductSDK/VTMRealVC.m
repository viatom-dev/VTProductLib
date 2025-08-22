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

@interface VTMRealVC () <VTMURATUtilsDelegate>

@property (nonatomic, strong) UILabel *descLab;
@property (nonatomic, copy) NSArray *array;
@property (nonatomic, strong) LPEcgRealWaveformView *waveformView;
@property (nonatomic, strong) UILabel *weightLabel;

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
    self.title = @"Real-time data";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.waveformView];
    [self.view addSubview:self.weightLabel];
    
    // correct interval of request real-data.
    float interval = 0.5;
    if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeECG) {
        interval = 0.5;
    } else if ([VTMProductURATUtils sharedInstance].currentType == VTMDeviceTypeBP) {
        interval = 0.2;
    }
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

- (void)requestRealtimeData {
    DLog(@"Request real-time data");
    if ([[VTBLEUtils sharedInstance].device.advName hasPrefix:LeS1_ShowPre]) {
        [[VTMProductURATUtils sharedInstance]requestScaleRealData];
    }else if ([[VTBLEUtils sharedInstance].device.advName hasPrefix:BP2_ShowPre] || [[VTBLEUtils sharedInstance].device.advName hasPrefix:BP2A_ShowPre] ||
              [[VTBLEUtils sharedInstance].device.advName hasPrefix:BP2W_ShowPre] || [[VTBLEUtils sharedInstance].device.advName hasPrefix:BP3_ShowPre]){
        [[VTMProductURATUtils sharedInstance] requestBPRealData];
    }else{
        [[VTMProductURATUtils sharedInstance] requestECGRealData];
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
                VTMBPRealTimeWaveform waveform = bpData.rt_wav;
                DLog(@"run_status: %hhu", bpData.run_status.status);
                switch (bpData.run_status.status) {
                    case VTMBPStatusReady: {
                        self.weightLabel.text = @"";
                    }
                        break;
                    case VTMBPStatusBPMeasuring :
                    case VTMBPStatusBPAVGMeasure: {
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMBPMeasuringData measuringData = [VTMBLEParser parseBPMeasuringData:data];
                        self.weightLabel.text = [NSString stringWithFormat:@"pressure: %d", measuringData.pressure/100];
                        if (measuringData.is_deflating_2) {
                            // Plot the pulse wave
                            for (int i = 0; i < bpData.rt_wav.wav.sampling_num ; i++) {
                                short val = bpData.rt_wav.wav.wave_data[i];
                            }
                        }
                    }
                        break;
                    case VTMBPStatusBPMeasureEnd: {
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMBPEndMeasureData endMeasureData = [VTMBLEParser parseBPEndMeasureData:data];
                        if (endMeasureData.state_code == 0 || endMeasureData.state_code == 0x0E) {
                            // Display the result
                            DLog(@"SYS: %d ~ DIA: %d", endMeasureData.systolic_pressure, endMeasureData.diastolic_pressure);
                        }else {
                            // Measure failed. View state_code.
                        }
                    }
                        break;
                    case VTMBPStatusECGMeasuring: {
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMECGMeasuringData ecgMeasuringData = [VTMBLEParser parseECGMeasuringData:data];
                        self.weightLabel.text = ecgMeasuringData.pulse_rate != 0xffff ? [NSString stringWithFormat:@"pulse_rate: %d", ecgMeasuringData.pulse_rate] : @"";
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
                    case VTMBPStatusECGMeasureEnd:{
                        NSData *data = [NSData dataWithBytes:bpData.rt_wav.data length:sizeof(bpData.rt_wav.data)];
                        VTMECGEndMeasureData ecgEndMeasueData = [VTMBLEParser parseECGEndMeasureData:data];
                        
                    }
                        break;
                    case VTMBPStatusBPMeasuringBP3:
                    case VTMBPStatusECGMeasuringBP3:{
                        NSData *data = [NSData dataWithBytes:waveform.data length:sizeof(waveform.data)];
                        if (waveform.type == 0) {
                            VTMBP3RealDataType0 measuringData ;
                            [data getBytes:&measuringData length:20];
                            self.weightLabel.text = [NSString stringWithFormat:@"pressure: %d", measuringData.pressure/100];
                        } else if (waveform.type == 2) {
                            VTMBP3RealDataType2 measuringData ;
                            [data getBytes:&measuringData length:20];
                            self.weightLabel.text = measuringData.hr_rate != 0xffff ? [NSString stringWithFormat:@"pulse_rate: %d", measuringData.hr_rate] : @"";
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
                        } else if (waveform.type == 4) {
                            VTMBP3RealDataType4 measuringData ;
                            [data getBytes:&measuringData length:20];
                            self.weightLabel.text = [NSString stringWithFormat:@"pressure: %d pulse_rate: %d", measuringData.pressure/100, measuringData.hr_rate != 0xffff ? measuringData.hr_rate : 0];
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
                    }
                        break;
                    case VTMBPStatusECGMeasureEndBP3:
                    case VTMBPStatusBPMeasureEndBP3: {
                        if (waveform.type == 1) {
                            NSData *data = [NSData dataWithBytes:waveform.data length:sizeof(waveform.data)];
                            VTMBPEndMeasureData resultData = [VTMBLEParser parseBPEndMeasureData:data];
                        } else if (waveform.type == 3) {
                            NSData *tempData = [NSData dataWithBytes:waveform.data length:sizeof(waveform.data)];
                            VTMECGEndMeasureData measuredData = [VTMBLEParser parseECGEndMeasureData:tempData];
                        }
                    }
                        break;
                    default:
                        break;
                }
                
            }
        }
            break;
        default:
            break;
    }
   
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


@end
