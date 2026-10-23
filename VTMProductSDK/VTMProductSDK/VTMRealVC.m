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


// 主机状态用 SDK 的 VTMBPStatus（VTMBLEEnum.h），不要在 Demo 里另外定义一份。
// 这里原先有个本地 DeviceStatus 枚举，0–7 和 VTMBPStatus 完全重复，但缺了
// BP2WIFI 三次测量（15–17）、BP2 理疗（20）、BP3 血压心电（21–24）、
// 配网与数据上传（25/26）和无效值（0xFF）。


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
#pragma mark -- BP 实时数据

/// 处理一包血压机实时数据。
///
/// 这里的结构照 ViHealth 的做法来，有三点是单看头文件不容易想到的：
///
/// 1. **payload 的解析方式由 `rt_wav.type` 决定，不是由 `run_status.status` 决定。**
///    `rt_wav.data[20]` 是一块复用的缓冲区，type 才是它的判别字段：
///    0 = 血压测量中，1 = 血压测量结束，3 = 心电测量结束。
///    BP3 必须按 type 取，否则会把测量中的包按结束包解析出一组垃圾血压值。
///
/// 2. **三次测量（x3）复用普通测量的状态处理**，只是多一个 isX3 标记：
///    BPAVGMeasure(15) 等同 BPMeasuring(4)，BPAVGMeasureEnd(17) 等同
///    BPMeasureEnd(5)。只有 BPAVGMeasureWait(16) 是独立的一档，用来显示
///    两次测量之间的倒计时。
///
/// 3. **放气标志分两个字段**：BP3 看 `is_deflating`，BP2 系列看
///    `is_deflating_2`。用错的那个会导致脉搏波画不出来。
- (void)handleBPRealTimeData:(VTMBPRealTimeData)bpData {
    VTMBPRunStatus status = bpData.run_status;
    VTMBPRealTimeWaveform wav = bpData.rt_wav;

    // 电池信息在任何状态下都有效，先取出来。state: 0 正常 1 充电中 2 充满
    VTMBatteryInfo battery = status.battery;
    DLog(@"battery percent:%d state:%d low:%@",
         battery.percent, battery.state, battery.percent < 15 ? @"YES" : @"NO");

    // SDK 的 VTMDeviceType 只区分到「血压计」，分不出 BP2/BP3。
    // 要做型号差异只能看蓝牙名，前缀表在 VTMDeviceRouting 里。
    BOOL isBP3 = [[VTBLEUtils sharedInstance].device.advName hasPrefix:@"BP3"];

    NSData *payload = [NSData dataWithBytes:wav.data length:sizeof(wav.data)];

    switch ((VTMBPStatus)status.status) {
        // ── 非测量状态 ───────────────────────────────────────────────────
        // 真实 App 在这几个状态下显示引导页。注意 VEN（BP2 理疗模式）也归在
        // 这里 —— 理疗中不产生血压或心电数据。
        case VTMBPStatusSleep:          // 0   关机
        case VTMBPStatusMemery:         // 1   数据回顾
        case VTMBPStatusCharge:         // 2   充电
        case VTMBPStatusReady:          // 3   开机预备
        case VTMBPStatusVEN:            // 20  BP2 理疗模式中
            _waveformView.receiveArray = @[];
            break;

        // ── 血压测量中 ───────────────────────────────────────────────────
        case VTMBPStatusBPMeasuring:    // 4
        case VTMBPStatusBPAVGMeasure: { // 15  三次测量中
            BOOL isX3 = (status.status == VTMBPStatusBPAVGMeasure);

            // BP3 在测量中会复用 rt_wav 发别的 type，只有 type==0 是血压测量包
            if (isBP3 && wav.type != 0) {
                DLog(@"BP3 measuring: skip rt_wav.type=%d", wav.type);
                break;
            }

            VTMBPMeasuringData md = [VTMBLEParser parseBPMeasuringData:payload];
            DLog(@"BP measuring%@ pressure:%d pulse:%d getPulse:%d",
                 isX3 ? @" (x3)" : @"", md.pressure, md.pulse_rate, md.is_get_pulse);

            // 放气阶段才有脉搏波。两个字段按型号取，不能混用。
            BOOL deflating = isBP3 ? md.is_deflating : md.is_deflating_2;
            if (deflating) {
                NSMutableArray *pulse = [NSMutableArray array];
                for (int i = 0; i < wav.wav.sampling_num; i++) {
                    [pulse addObject:@(wav.wav.wave_data[i])];
                }
                // 脉搏波是原始 AD 值，不走 mV 转换，量程 0–255
                _waveformView.isBpWave = NO;
                _waveformView.receiveArray = pulse;
            }
        }
            break;

        // ── 三次测量的间隔等待 ───────────────────────────────────────────
        // 这一档没有波形，只有倒计时。bp_avg_cnt 是第几次，
        // bp_avg_wait_tick 是已等待的秒数，总时长来自设备的 avg_measure_mode
        // 配置（本 Demo 没读配置，所以只打印原始值）。
        case VTMBPStatusBPAVGMeasureWait:   // 16
            DLog(@"BP x3 waiting: count=%d tick=%d", status.bp_avg_cnt, status.bp_avg_wait_tick);
            break;

        // ── 血压测量结束 ─────────────────────────────────────────────────
        case VTMBPStatusBPMeasureEnd:       // 5
        case VTMBPStatusBPAVGMeasureEnd: {  // 17  三次测量结束
            if (isBP3 && wav.type != 1) {
                DLog(@"BP3 measure end: skip rt_wav.type=%d", wav.type);
                break;
            }

            VTMBPEndMeasureData result = [VTMBLEParser parseBPEndMeasureData:payload];

            // state_code 0 = 正常，0x0E = 心率不齐但结果有效，其余为测量失败
            if (result.state_code == 0 || result.state_code == 0x0E) {
                // 偶尔会收到一包全 0 或 65535 的占位结果，要丢掉
                if (result.systolic_pressure == 0 || result.diastolic_pressure == 0 ||
                    result.systolic_pressure == 65535) {
                    DLog(@"BP result incomplete, ignored");
                    break;
                }
                DLog(@"BP result: %d/%d mmHg  mean:%d  pulse:%d  arrhythmia:%@",
                     result.systolic_pressure, result.diastolic_pressure,
                     result.mean_pressure, result.pulse_rate,
                     result.state_code == 0x0E ? @"YES" : @"NO");
                [self showBPResult:result];
            } else {
                DLog(@"BP measure failed, state_code=0x%02X", result.state_code);
            }

            // 同一份 payload 也可以在 Swift 侧解析，演示混编
            [VTSwiftParser swift_parseBPEndMeasureDataWithResponse:payload];
            _waveformView.receiveArray = @[];
        }
            break;

        // ── 心电测量中 ───────────────────────────────────────────────────
        case VTMBPStatusECGMeasuring: { // 6
            VTMECGMeasuringData md = [VTMBLEParser parseECGMeasuringData:payload];
            // special_status bit0 信号弱，bit1 导联脱落
            DLog(@"ECG measuring: %us  pulse:%d  weakSignal:%@  leadOff:%@",
                 md.duration, md.pulse_rate,
                 (md.special_status & 0x01) ? @"YES" : @"NO",
                 (md.special_status & 0x02) ? @"YES" : @"NO");

            NSMutableArray *points = [NSMutableArray array];
            for (int i = 0; i < wav.wav.sampling_num; i++) {
                if (wav.wav.wave_data[i] == 0x7FFF) continue;   // 无效点
                // 用 SDK 的转换方法，不要自己写系数
                [points addObject:@([VTMBLEParser bpMvFromShort:wav.wav.wave_data[i]])];
            }
            _waveformView.isBpWave = YES;
            _waveformView.receiveArray = [[VTMFilter shared] sfilterPointValue:points];
        }
            break;

        // ── 心电测量结束 ─────────────────────────────────────────────────
        case VTMBPStatusECGMeasureEnd: {    // 7
            if (isBP3 && wav.type != 3) {
                DLog(@"BP3 ECG end: skip rt_wav.type=%d", wav.type);
                break;
            }

            VTMECGEndMeasureData result = [VTMBLEParser parseECGEndMeasureData:payload];
            // 0xFFFFFFFE 是哨兵值：测量不足 30 秒，设备不保存这条记录
            if (result.result == 0xFFFFFFFE) {
                DLog(@"ECG less than 30s, not saved by device");
            } else {
                DLog(@"ECG result: hr:%d qrs:%dms pvcs:%d qtc:%dms diagnosis:0x%X",
                     result.hr, result.qrs, result.pvcs, result.qtc, result.result);
            }
        }
            break;

        // ── BP3 血压心电联测 ─────────────────────────────────────────────
        // ViHealth 把 BP3F/HDM3G 这类设备走的是另一条独立渲染路径，不在这个
        // switch 里。本 Demo 没有对应 UI，先打日志把状态和 type 暴露出来。
        case VTMBPStatusBPMeasuringBP3:     // 21
        case VTMBPStatusBPMeasureEndBP3:    // 22
        case VTMBPStatusECGMeasuringBP3:    // 23
        case VTMBPStatusECGMeasureEndBP3:   // 24
            DLog(@"BP3 combined BP+ECG status=%d rt_wav.type=%d (not demonstrated)",
                 status.status, wav.type);
            break;

        // ── 联网相关 ─────────────────────────────────────────────────────
        case VTMBPStatusNetworkConfig:      // 25  配置 WiFi 和服务器
        case VTMBPStatusDataUploading:      // 26  数据上传服务器
            DLog(@"BP network status=%d (no measurement data)", status.status);
            break;

        case VTMBPStatusINVAIL:             // 0xFF
            DLog(@"BP status invalid (0xFF)");
            break;
    }
}

/// 把血压结果显示出来。真实 App 在这里弹结果卡片并落库，Demo 只弹个 alert。
- (void)showBPResult:(VTMBPEndMeasureData)result {
    NSString *msg = [NSString stringWithFormat:@"%d/%d mmHg\npulse %d bpm%@",
                     result.systolic_pressure, result.diastolic_pressure,
                     result.pulse_rate,
                     result.state_code == 0x0E ? @"\n(irregular heartbeat)" : @""];
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"BP Result"
                                            message:msg
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    if (self.presentedViewController == nil) {
        [self presentViewController:alert animated:YES completion:nil];
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
                [self handleBPRealTimeData:bpData];
                // VTMBPRealTimeData 里的 packet_t 是堆上分配的，用完必须释放，
                // 否则每个实时包都会漏一次（这里 0.2 秒一个包）。
                VTMFreeBPRealTimeData(&bpData);
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
                //    注意传的是上面用 parseCable:state: 转换出来的 leadState，
                //    不是 runParams.electrodes_state —— 电极状态与导联状态的位含义不同。
                NSArray<NSArray *> *leadsPoints = [VTMBLEParser parseER3RealWaveData:waveData withCable:runParams.cable_type andState:leadState];
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
    // ⚠️ 这两个指令受 controlKey 保护。未设置 VTMURATUtils.controlKey 时，
    //    Debug 构建会触发断言。Key 由 Viatom 颁发，见 README 的 Notes 章节。
    if (sender.isSelected) {
        // stop measure
        [[VTMProductURATUtils sharedInstance] er3_notifyMeasurementEnd];
    } else {
        // start measure
        [[VTMProductURATUtils sharedInstance] er3_notifyMeasurementStart];
    }
}

@end
