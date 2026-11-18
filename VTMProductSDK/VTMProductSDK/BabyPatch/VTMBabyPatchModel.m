//
//  VTMBabyPatchModel.m
//  VTMProductSDK
//
//  所有面向用户的文案都走 VTMLocalized(key)，key 定义在 en.lproj / zh-Hans.lproj 的
//  Localizable.strings 里，统一以 `baby.` 开头。格式串的占位符顺序在两种语言里必须一致。
//
//  菜单、协议判定、顶部姿态都在取值时才按当前语言格式化，切换语言后重新取即可；
//  已经写进日志的行保持写入时的语言。
//

#import "VTMBabyPatchModel.h"
#import "VTMLocalization.h"

#pragma mark - 菜单与设置项

@interface VTMBabyPatchMenuItem ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *subtitle;
@property (nonatomic, assign, readwrite) VTMBabyPatchAction action;
@property (nonatomic, assign, readwrite) BOOL destructive;
@end

@implementation VTMBabyPatchMenuItem
+ (instancetype)itemWithTitle:(NSString *)title subtitle:(NSString *)subtitle
                       action:(VTMBabyPatchAction)action destructive:(BOOL)destructive {
    VTMBabyPatchMenuItem *item = [[self alloc] init];
    item.title = title;
    item.subtitle = subtitle;
    item.action = action;
    item.destructive = destructive;
    return item;
}
@end

@interface VTMBabyPatchMenuSection ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSArray<VTMBabyPatchMenuItem *> *items;
@end

@implementation VTMBabyPatchMenuSection
+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<VTMBabyPatchMenuItem *> *)items {
    VTMBabyPatchMenuSection *section = [[self alloc] init];
    section.title = title;
    section.items = items;
    return section;
}
@end

@interface VTMBabyPatchSettingItem ()
@property (nonatomic, assign, readwrite) u_char type;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *hint;
@property (nonatomic, assign, readwrite) NSInteger minValue;
@property (nonatomic, assign, readwrite) NSInteger maxValue;
@end

@implementation VTMBabyPatchSettingItem
+ (instancetype)itemWithType:(u_char)type title:(NSString *)title hint:(NSString *)hint
                         min:(NSInteger)min max:(NSInteger)max {
    VTMBabyPatchSettingItem *item = [[self alloc] init];
    item.type = type;
    item.title = title;
    item.hint = hint;
    item.minValue = min;
    item.maxValue = max;
    return item;
}
@end

#pragma mark - Model

/// 日志最多保留的行数，避免长时间测试时 UITextView 越来越卡
static const NSUInteger kMaxLogLines = 300;

/// 代际判定的来源。配置长度只作参考，不参与结论（见 VTMBabyProtocolGeneration 的说明）
typedef NS_ENUM(NSInteger, VTMBabyEvidenceSource) {
    VTMBabyEvidenceRunParams = 0,
    VTMBabyEvidenceAttitude,
    VTMBabyEvidenceRecord,
    VTMBabyEvidenceConfig,
};

// 设备字节流长度（与 SDK 结构体里 hasSleepInfo / hasSleepOut 之前的偏移一致）
static const NSUInteger kRunParamsV1Length = 28;
static const NSUInteger kRunParamsV3Length = 28 + 40;
static const NSUInteger kAttitudeV1Length  = 26;
static const NSUInteger kAttitudeV3Length  = 26 + 2;
static const NSUInteger kConfigV3Length    = 45;

@interface VTMBabyPatchModel ()
@property (nonatomic, strong) NSMutableArray<NSString *> *logLines;
@property (nonatomic, strong) NSDateFormatter *logTimeFormatter;
@property (nonatomic, assign, readwrite) BOOL hasConfig;
@property (nonatomic, assign, readwrite) VTMBabyConfig config;
@property (nonatomic, assign, readwrite) NSUInteger attitudePushCount;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *fileNames;
@property (nonatomic, copy, readwrite, nullable) NSString *downloadingFileName;
@property (nonatomic, assign, readwrite) u_int expectedLength;
@property (nonatomic, strong, nullable) NSMutableData *downloadBuffer;
/// 代际判定依据：来源 → 判定结果；来源 → 依据数值（字节长度或文件版本）。
/// 只存原始值，文案在 generationSummary 里按当前语言生成
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *evidenceGeneration;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *evidenceValue;
/// 最近一次姿态上报的原始数据，liveText 按当前语言重新格式化
@property (nonatomic, copy, nullable) NSData *latestAttitude;
@end

@implementation VTMBabyPatchModel

- (instancetype)init {
    if (self = [super init]) {
        _logLines = [NSMutableArray array];
        _logTimeFormatter = [[NSDateFormatter alloc] init];
        _logTimeFormatter.dateFormat = @"HH:mm:ss.SSS";
        _fileNames = @[];
        _evidenceGeneration = [NSMutableDictionary dictionary];
        _evidenceValue = [NSMutableDictionary dictionary];
        [self reloadLocalizedContent];
    }
    return self;
}

- (void)reloadLocalizedContent {
    _sections = [self buildSections];
    _settingItems = [self buildSettingItems];
}

- (NSArray<VTMBabyPatchMenuSection *> *)buildSections {
    NSMutableArray *realtime = [NSMutableArray arrayWithObject:
        [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.runParams")
                                   subtitle:VTMLocalized(@"baby.menu.runParams.sub")
                                     action:VTMBabyPatchActionRunParams destructive:NO]];
#ifdef VTM_BABY_PATCH_V3
    [realtime addObject:
        [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.buzzer")
                                   subtitle:VTMLocalized(@"baby.menu.buzzer.sub")
                                     action:VTMBabyPatchActionBuzzer destructive:NO]];
#endif
    return @[
        [VTMBabyPatchMenuSection sectionWithTitle:VTMLocalized(@"baby.section.common") items:@[
            [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.deviceInfo") subtitle:@"0xE1"
                                         action:VTMBabyPatchActionDeviceInfo destructive:NO],
            [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.syncTime")
                                       subtitle:VTMLocalized(@"baby.menu.syncTime.sub")
                                         action:VTMBabyPatchActionSyncTime destructive:NO],
            [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.factoryReset")
                                       subtitle:VTMLocalized(@"baby.menu.factoryReset.sub")
                                         action:VTMBabyPatchActionFactoryReset destructive:YES],
        ]],
        [VTMBabyPatchMenuSection sectionWithTitle:VTMLocalized(@"baby.section.config") items:@[
            [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.getConfig") subtitle:@"0x00"
                                         action:VTMBabyPatchActionGetConfig destructive:NO],
            [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.setConfig")
                                       subtitle:VTMLocalized(@"baby.menu.setConfig.sub")
                                         action:VTMBabyPatchActionSetConfig destructive:NO],
        ]],
        [VTMBabyPatchMenuSection sectionWithTitle:VTMLocalized(@"baby.section.realtime") items:realtime],
        [VTMBabyPatchMenuSection sectionWithTitle:VTMLocalized(@"baby.section.file") items:@[
            [VTMBabyPatchMenuItem itemWithTitle:VTMLocalized(@"baby.menu.fileList")
                                       subtitle:VTMLocalized(@"baby.menu.fileList.sub")
                                         action:VTMBabyPatchActionFileList destructive:NO],
        ]],
    ];
}

- (NSArray<VTMBabyPatchSettingItem *> *)buildSettingItems {
    NSString *bits = VTMLocalized(@"baby.setting.alarmBits.hint");
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsLED title:VTMLocalized(@"baby.setting.led")
                                         hint:bits min:0 max:15],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsBEEP title:VTMLocalized(@"baby.setting.beep")
                                         hint:bits min:0 max:15],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsWAIT title:VTMLocalized(@"baby.setting.notify")
                                         hint:bits min:0 max:15],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsTEMPLow title:VTMLocalized(@"baby.setting.tempLow")
                                         hint:VTMLocalized(@"baby.setting.tempLow.hint") min:150 max:320],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsTEMPHigh title:VTMLocalized(@"baby.setting.tempHigh")
                                         hint:VTMLocalized(@"baby.setting.tempHigh.hint") min:320 max:430],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsRRLow title:VTMLocalized(@"baby.setting.rrLow")
                                         hint:VTMLocalized(@"baby.setting.rrLow.hint") min:0 max:70],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsRRHigh title:VTMLocalized(@"baby.setting.rrHigh")
                                         hint:VTMLocalized(@"baby.setting.rrHigh.hint") min:0 max:70],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsSensivity title:VTMLocalized(@"baby.setting.sensitivity")
                                         hint:VTMLocalized(@"baby.setting.sensitivity.hint") min:1 max:3],
        [VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsWearLEDTime title:VTMLocalized(@"baby.setting.ledTime")
                                         hint:VTMLocalized(@"baby.setting.ledTime.hint") min:0 max:255],
    ]];
#ifdef VTM_BABY_PATCH_V3
    [items addObject:[VTMBabyPatchSettingItem itemWithType:VTMBabySetParamsDropTemp
                                                     title:VTMLocalized(@"baby.setting.dropTemp")
                                                      hint:VTMLocalized(@"baby.setting.dropTemp.hint") min:1 max:5]];
#endif
    return items;
}

#pragma mark - 日志

- (NSString *)logText {
    return [self.logLines componentsJoinedByString:@"\n"];
}

- (void)appendLog:(NSString *)text {
    NSString *time = [self.logTimeFormatter stringFromDate:[NSDate date]];
    [self.logLines addObject:[NSString stringWithFormat:@"[%@] %@", time, text]];
    if (self.logLines.count > kMaxLogLines) {
        [self.logLines removeObjectsInRange:NSMakeRange(0, self.logLines.count - kMaxLogLines)];
    }
}

- (void)clearLogs {
    [self.logLines removeAllObjects];
}

#pragma mark - 应答解析

- (NSString *)applyDeviceInfo:(NSData *)response {
    VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
    NSUInteger snLen = MIN((NSUInteger)info.sn.len, sizeof(info.sn.serial_num));
    NSString *sn = [[NSString alloc] initWithBytes:info.sn.serial_num length:snLen encoding:NSASCIIStringEncoding] ?: @"";
    return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.deviceInfo"),
            info.hw_version ?: '?',
            [self.class versionString:info.fw_version],
            [self.class versionString:info.bl_version],
            info.protocol_version, info.protocol_data_max_len, sn];
}

- (NSString *)applyConfig:(NSData *)response {
    VTMBabyConfig c = [VTMBLEParser baby_parseConfig:response];
    self.config = c;
    self.hasConfig = YES;
    [self recordEvidence:VTMBabyEvidenceConfig
              generation:response.length >= kConfigV3Length ? VTMBabyProtocolGenerationV3 : VTMBabyProtocolGenerationV1
                   value:response.length];
    return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.config"),
            (unsigned long)response.length,
            [self.class alarmBitsString:c.alarm_led],
            [self.class alarmBitsString:c.alarm_beep],
            [self.class alarmBitsString:c.alarm_wait],
            c.temp_thr_low / 10.0, c.temp_thr_high / 10.0,
            c.rr_thr_low, c.rr_thr_high,
            c.alarm_sensitivity,
            [self.class ledWorkTimeString:c.wear_led_work_time],
            c.drop_temp];
}

- (NSString *)applyRunParams:(NSData *)response {
    VTMBabyRunParams p = [VTMBLEParser baby_parseRunParams:response];
    VTMBabyProtocolGeneration gen = VTMBabyProtocolGenerationUnknown;
    if (response.length >= kRunParamsV3Length) {
        gen = VTMBabyProtocolGenerationV3;
    } else if (response.length == kRunParamsV1Length) {
        gen = VTMBabyProtocolGenerationV1;
    }
    [self recordEvidence:VTMBabyEvidenceRunParams generation:gen value:response.length];
    NSMutableString *s = [NSMutableString stringWithFormat:VTMLocalized(@"baby.fmt.runParams"),
        (unsigned long)response.length,
        [self.class runStatusString:p.run_status],
        [self.class gestureString:p.attitude_status],
        VTMLocalized(p.wear_status ? @"baby.wear.off" : @"baby.wear.on"),
        p.rr, p.alarm_type_rr,
        p.cur_temperature / 10.0, p.alarm_type_temp, p.gesture_alarm,
        p.batInfo.percent, p.batInfo.state, p.batInfo.voltage,
        p.record_time, p.startup_time];
    if (p.hasSleepInfo) {
        VTMBabySleepInfo si = p.sleepInfo;
        [s appendFormat:VTMLocalized(@"baby.fmt.runParams.sleep"),
         [self.class sleepStateString:si.Sleep_state], si.cough_display_flag, si.playpnea, si.awake_cnt,
         [self.class timestampString:si.falling_asleep], [self.class timestampString:si.awake_time],
         si.sleep_time, si.deep_time, si.light_time, si.wake_time];
    } else {
        [s appendString:VTMLocalized(@"baby.runParams.noSleep")];
    }
    return s;
}

- (NSString *)applyAttitude:(NSData *)response {
    self.attitudePushCount += 1;
    self.latestAttitude = response;
    VTMBabyProtocolGeneration gen = VTMBabyProtocolGenerationUnknown;
    if (response.length >= kAttitudeV3Length) {
        gen = VTMBabyProtocolGenerationV3;
    } else if (response.length == kAttitudeV1Length) {
        gen = VTMBabyProtocolGenerationV1;
    }
    [self recordEvidence:VTMBabyEvidenceAttitude generation:gen value:response.length];
    return [self attitudeText];
}

/// 按当前语言格式化最近一次姿态上报
- (NSString *)attitudeText {
    NSData *response = self.latestAttitude;
    if (!response) {
        return VTMLocalized(@"baby.attitude.waiting");
    }
    VTMBabyAtt a = [VTMBLEParser baby_parseAttitude:response];
    NSMutableString *s = [NSMutableString stringWithFormat:VTMLocalized(@"baby.fmt.attitude"),
        (unsigned long)self.attitudePushCount, (unsigned long)response.length,
        [self.class gestureString:a.alg_result.gesture], a.alg_result.RR,
        a.alg_result.Pitch, a.alg_result.Roll, a.alg_result.Yaw,
        a.acc_x, a.acc_y, a.acc_z, a.g_x, a.g_y, a.g_z];
#ifdef VTM_BABY_PATCH_V3
    if (a.hasSleepOut) {
        [s appendFormat:VTMLocalized(@"baby.fmt.attitude.sleep"),
         [self.class sleepStateString:a.sleepOut.sleep_state], a.sleepOut.cough_event_flag];
    } else {
        [s appendString:VTMLocalized(@"baby.attitude.noSleep")];
    }
#endif
    return s;
}

- (NSString *)applyFileList:(NSData *)response {
    VTMFileList list = [VTMBLEParser parseFileList:response];
    NSMutableArray *names = [NSMutableArray array];
    for (int i = 0; i < list.file_num; i++) {
        // 文件名最多 15 个字符，按 strnlen 截断，避免缺少结尾 0 时越界
        const char *raw = (const char *)list.fileName[i].str;
        NSString *name = [[NSString alloc] initWithBytes:raw
                                                  length:strnlen(raw, sizeof(list.fileName[i].str))
                                                encoding:NSASCIIStringEncoding];
        if (name.length > 0) {
            [names addObject:name];
        }
    }
    self.fileNames = names;
    if (names.count == 0) {
        return VTMLocalized(@"baby.fileList.empty");
    }
    return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.fileList"),
            (unsigned long)names.count, [names componentsJoinedByString:@"\n  "]];
}

#pragma mark - 协议代际

- (void)recordEvidence:(VTMBabyEvidenceSource)source generation:(VTMBabyProtocolGeneration)gen value:(NSUInteger)value {
    self.evidenceGeneration[@(source)] = @(gen);
    self.evidenceValue[@(source)] = @(value);
}

- (void)recordFileEvidenceWithVersion:(u_char)fileVersion {
    [self recordEvidence:VTMBabyEvidenceRecord
              generation:fileVersion >= 2 ? VTMBabyProtocolGenerationV3 : VTMBabyProtocolGenerationV1
                   value:fileVersion];
}

- (VTMBabyProtocolGeneration)generation {
    BOOL v1 = NO, v3 = NO;
    for (NSNumber *source in @[@(VTMBabyEvidenceRunParams), @(VTMBabyEvidenceAttitude), @(VTMBabyEvidenceRecord)]) {
        VTMBabyProtocolGeneration g = (VTMBabyProtocolGeneration)self.evidenceGeneration[source].integerValue;
        v1 |= (g == VTMBabyProtocolGenerationV1);
        v3 |= (g == VTMBabyProtocolGenerationV3);
    }
    if (v1 && v3) return VTMBabyProtocolGenerationConflict;
    if (v3) return VTMBabyProtocolGenerationV3;
    if (v1) return VTMBabyProtocolGenerationV1;
    return VTMBabyProtocolGenerationUnknown;
}

+ (NSString *)verdictForGeneration:(VTMBabyProtocolGeneration)gen {
    switch (gen) {
        case VTMBabyProtocolGenerationV1:       return VTMLocalized(@"baby.gen.v1");
        case VTMBabyProtocolGenerationV3:       return VTMLocalized(@"baby.gen.v3");
        case VTMBabyProtocolGenerationConflict: return VTMLocalized(@"baby.gen.conflict");
        default:                                return VTMLocalized(@"baby.gen.badLength");
    }
}

- (nullable NSString *)evidenceTextForSource:(VTMBabyEvidenceSource)source {
    NSNumber *gen = self.evidenceGeneration[@(source)];
    if (!gen) {
        return nil;
    }
    NSString *verdict = [self.class verdictForGeneration:(VTMBabyProtocolGeneration)gen.integerValue];
    NSUInteger value = self.evidenceValue[@(source)].unsignedIntegerValue;
    switch (source) {
        case VTMBabyEvidenceRunParams:
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.evidence.runParams"), (unsigned long)value, verdict];
        case VTMBabyEvidenceAttitude:
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.evidence.attitude"), (unsigned long)value, verdict];
        case VTMBabyEvidenceRecord:
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.evidence.record"), (unsigned long)value, verdict];
        case VTMBabyEvidenceConfig:
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.evidence.config"), (unsigned long)value, verdict];
    }
    return nil;
}

- (NSString *)generationSummary {
    VTMBabyProtocolGeneration gen = self.generation;
    NSString *verdict = gen == VTMBabyProtocolGenerationUnknown ? VTMLocalized(@"baby.gen.unknown")
                                                                : [self.class verdictForGeneration:gen];
    NSMutableArray *details = [NSMutableArray array];
    for (NSNumber *source in @[@(VTMBabyEvidenceRunParams), @(VTMBabyEvidenceAttitude),
                               @(VTMBabyEvidenceRecord), @(VTMBabyEvidenceConfig)]) {
        NSString *text = [self evidenceTextForSource:(VTMBabyEvidenceSource)source.integerValue];
        if (text) {
            [details addObject:text];
        }
    }
    NSString *head = [NSString stringWithFormat:VTMLocalized(@"baby.fmt.protocol"), verdict];
    if (details.count == 0) {
        return head;
    }
    return [NSString stringWithFormat:@"%@\n%@", head, [details componentsJoinedByString:@"  "]];
}

- (NSString *)liveText {
    return [NSString stringWithFormat:@"%@\n─────\n%@", [self generationSummary], [self attitudeText]];
}

#pragma mark - 设置项

- (nullable NSNumber *)currentValueForSetting:(VTMBabyPatchSettingItem *)item {
    if (!self.hasConfig) {
        return nil;
    }
    VTMBabyConfig c = self.config;
    switch (item.type) {
        case VTMBabySetParamsLED:         return @(c.alarm_led);
        case VTMBabySetParamsBEEP:        return @(c.alarm_beep);
        case VTMBabySetParamsWAIT:        return @(c.alarm_wait);
        case VTMBabySetParamsTEMPLow:     return @(c.temp_thr_low);
        case VTMBabySetParamsTEMPHigh:    return @(c.temp_thr_high);
        case VTMBabySetParamsRRLow:       return @(c.rr_thr_low);
        case VTMBabySetParamsRRHigh:      return @(c.rr_thr_high);
        case VTMBabySetParamsSensivity:   return @(c.alarm_sensitivity);
        case VTMBabySetParamsWearLEDTime: return @(c.wear_led_work_time);
        default: break;
    }
#ifdef VTM_BABY_PATCH_V3
    if (item.type == VTMBabySetParamsDropTemp) {
        return @(c.drop_temp);
    }
#endif
    return nil;
}

- (nullable NSString *)validateSetting:(VTMBabyPatchSettingItem *)item
                                 input:(NSString *)input
                                option:(VTMOxiParamsOption *)option {
    NSInteger value = 0;
    NSString *error = [self.class parseInteger:input min:item.minValue max:item.maxValue
                                          name:item.title value:&value];
    if (error) {
        return error;
    }
    // 上下阈值的相对关系只在读过配置时才能校验
    if (self.hasConfig) {
        VTMBabyConfig c = self.config;
        if (item.type == VTMBabySetParamsTEMPLow && value >= c.temp_thr_high) {
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.err.tempLow"), (int)c.temp_thr_high];
        }
        if (item.type == VTMBabySetParamsTEMPHigh && value <= c.temp_thr_low) {
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.err.tempHigh"), (int)c.temp_thr_low];
        }
        if (item.type == VTMBabySetParamsRRLow && value >= c.rr_thr_high) {
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.err.rrLow"), (int)c.rr_thr_high];
        }
        if (item.type == VTMBabySetParamsRRHigh && value <= c.rr_thr_low) {
            return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.err.rrHigh"), (int)c.rr_thr_low];
        }
    }
    VTMOxiParamsOption opt;
    memset(&opt, 0, sizeof(opt));
    opt.type = item.type;
    // 每个设置项占 4 字节，小端；short 类的温度阈值写进低 2 字节，与协议一致
    opt.param.val = (u_int)value;
    *option = opt;
    return nil;
}

#ifdef VTM_BABY_PATCH_V3
- (nullable NSString *)validateBuzzerOn:(NSString *)on
                                   time:(NSString *)time
                              intensity:(NSString *)intensity
                                   info:(VTMBabyBuzzerInfo *)info {
    NSInteger onValue = 0, timeValue = 0, intensValue = 0;
    NSString *error = [self.class parseInteger:on min:0 max:1 name:VTMLocalized(@"baby.buzzer.on") value:&onValue]
                   ?: [self.class parseInteger:time min:0 max:UINT16_MAX name:VTMLocalized(@"baby.buzzer.time") value:&timeValue]
                   ?: [self.class parseInteger:intensity min:1 max:100 name:VTMLocalized(@"baby.buzzer.intensity") value:&intensValue];
    if (error) {
        return error;
    }
    VTMBabyBuzzerInfo b;
    memset(&b, 0, sizeof(b));
    b.on = (u_char)onValue;
    b.time = (u_short)timeValue;
    b.sound_intens = (u_char)intensValue;
    *info = b;
    return nil;
}
#endif

#pragma mark - 文件下载

- (u_int)downloadedLength {
    return (u_int)self.downloadBuffer.length;
}

- (void)prepareDownload:(NSString *)fileName {
    self.downloadingFileName = fileName;
    self.expectedLength = 0;
    self.downloadBuffer = [NSMutableData data];
}

- (void)beginDownloadWithLength:(u_int)length {
    self.expectedLength = length;
    self.downloadBuffer = [NSMutableData dataWithCapacity:length];
}

- (void)appendDownloadData:(NSData *)data {
    if (data.length > 0) {
        [self.downloadBuffer appendData:data];
    }
}

- (BOOL)isDownloadComplete {
    return self.downloadBuffer.length >= self.expectedLength;
}

- (void)cancelDownload {
    self.downloadingFileName = nil;
    self.expectedLength = 0;
    self.downloadBuffer = nil;
}

- (NSString *)finishDownload {
    NSString *name = self.downloadingFileName ?: @"";
    NSData *data = [self.downloadBuffer copy] ?: [NSData data];
    [self cancelDownload];

    NSString *header = [NSString stringWithFormat:VTMLocalized(@"baby.fmt.download.done"), name, (unsigned long)data.length];
    if ([name hasPrefix:@"R"]) {
        return [NSString stringWithFormat:@"%@\n%@", header, [self summaryForRecordFile:data]];
    }
    if ([name hasPrefix:@"E"]) {
        return [NSString stringWithFormat:@"%@\n%@", header, [self summaryForEventFile:data]];
    }
    return [NSString stringWithFormat:@"%@\n%@", header, VTMLocalized(@"baby.download.unknownType")];
}

/// 记录文件只列前几条，完整数据看 Xcode 控制台
static const NSInteger kPreviewCount = 5;

- (NSString *)summaryForRecordFile:(NSData *)data {
    __block NSString *summary = VTMLocalized(@"baby.download.parseFailed");
    [VTMBLEParser baby_parseRecordFile:data completion:^(VTMOxiFileHead fileHead, VTMBabyRecordHead head,
                                                         VTMBabyRecord_t *records, NSInteger recordNum) {
        if (data.length >= sizeof(VTMOxiFileHead)) {
            [self recordFileEvidenceWithVersion:fileHead.file_version];
        }
        NSMutableString *s = [NSMutableString stringWithFormat:VTMLocalized(@"baby.fmt.record.head"),
            fileHead.file_version, fileHead.file_type, fileHead.device_model,
            [self.class timestampString:head.measuring_timestamp], head.recording_time, head.interval,
            (long)recordNum];
#ifdef VTM_BABY_PATCH_V3
        if (fileHead.file_version >= 2) {
            VTMBabySleepRTT rtt = head.sleep_rtt;
            [s appendFormat:VTMLocalized(@"baby.fmt.record.sleep"),
             [self.class timestampString:rtt.falling_asleep], [self.class timestampString:rtt.awake_time],
             rtt.sleep_time, rtt.deep_time, rtt.light_time, rtt.wake_time, rtt.awake_cnt];
        }
#endif
        for (NSInteger i = 0; i < MIN(recordNum, kPreviewCount); i++) {
            VTMBabyRecord_t r = records[i];
            [s appendFormat:VTMLocalized(@"baby.fmt.record.item"), (long)i, r.resp,
             [self.class gestureString:r.status], r.temp / 10.0];
#ifdef VTM_BABY_PATCH_V3
            if (fileHead.file_version >= 2) {
                [s appendFormat:VTMLocalized(@"baby.fmt.record.item.sleep"), r.sleep_state];
            }
#endif
        }
        if (recordNum > kPreviewCount) {
            [s appendFormat:VTMLocalized(@"baby.fmt.record.more"), (long)(recordNum - kPreviewCount)];
        }
        summary = s;
    }];
    return summary;
}

- (NSString *)summaryForEventFile:(NSData *)data {
    __block NSString *summary = VTMLocalized(@"baby.download.parseFailed");
    [VTMBLEParser baby_parseEventFile:data completion:^(VTMOxiFileHead fileHead, VTMBabyEventHead head,
                                                        VTMBabyEventLog_t *events, NSInteger recordNum) {
        NSMutableString *s = [NSMutableString stringWithFormat:VTMLocalized(@"baby.fmt.event.head"),
                              fileHead.file_version, fileHead.file_type, (long)recordNum];
        // 事件文件通常不大，全部列出
        for (NSInteger i = 0; i < recordNum; i++) {
            VTMBabyEventLog_t e = events[i];
            [s appendFormat:@"\n  %@  %@", [self.class timestampString:e.measuring_timestamp],
             [self.class eventString:e.event_id]];
        }
        summary = s;
    }];
    return summary;
}

#pragma mark - 文案

+ (NSString *)nameForCommand:(u_char)cmd {
    NSString *key = nil;
    switch (cmd) {
        case VTMBLECmdGetDeviceInfo:    key = @"baby.cmd.deviceInfo"; break;
        case VTMBLECmdRestore:          key = @"baby.cmd.factoryReset"; break;
        case VTMBLECmdSyncTime:         key = @"baby.cmd.syncTime"; break;
        case VTMBLECmdGetFileList:      key = @"baby.cmd.fileList"; break;
        case VTMBLECmdStartRead:        key = @"baby.cmd.startRead"; break;
        case VTMBLECmdReadFile:         key = @"baby.cmd.readFile"; break;
        case VTMBLECmdEndRead:          key = @"baby.cmd.endRead"; break;
        case VTMBLECmdOpenupEncryption: key = @"baby.cmd.encrypt"; break;
        case VTMBabyCmdGetConfig:       key = @"baby.cmd.getConfig"; break;
        case VTMBabyCmdSetConfig:       key = @"baby.cmd.setConfig"; break;
        case VTMBabyCmdGetRunParams:    key = @"baby.cmd.runParams"; break;
        case VTMBabyCmdGetGesture:      key = @"baby.cmd.attitude"; break;
        case 0x04:                      key = @"baby.cmd.buzzer"; break;
        default: break;
    }
    if (!key) {
        return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.cmd.unknown"), cmd];
    }
    return [NSString stringWithFormat:@"%@ 0x%02X", VTMLocalized(key), cmd];
}

+ (NSString *)descriptionForFailure:(VTMBLEPkgType)type {
    // 按《翻身贴通讯协议-V3》2.2 的 Pkg.Type 表描述。
    // SDK 的 VTMBLEPkgType 命名与该表不完全一致（如 0xE1/0xE2），这里直接用原始值，
    // 也不依赖较新 SDK 才有的枚举（如 0xCE）。
    NSString *key = nil;
    switch ((u_char)type) {
        case 0xE0: key = @"baby.fail.notFound"; break;
        case 0xE1: key = @"baby.fail.readFailed"; break;
        case 0xE2: key = @"baby.fail.writeFailed"; break;
        case 0xE3: key = @"baby.fail.firmware"; break;
        case 0xE4: key = @"baby.fail.language"; break;
        case 0xFB: key = @"baby.fail.busy"; break;
        case 0xFC: key = @"baby.fail.format"; break;
        case 0xFD: key = @"baby.fail.unsupported"; break;
        case 0xFF: key = @"baby.fail.common"; break;
        case 0xCC: key = @"baby.fail.head"; break;
        case 0xCD: key = @"baby.fail.crc"; break;
        case 0xCE: key = @"baby.fail.unauthorized"; break;
        default: break;
    }
    if (!key) {
        return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.fail.unknown"), (u_char)type];
    }
    return [NSString stringWithFormat:@"%@ 0x%02X", VTMLocalized(key), (u_char)type];
}

+ (NSString *)descriptionForSendError:(u_char)errorCode {
    switch (errorCode) {
        case 0: return VTMLocalized(@"baby.sendErr.noPeripheral");
        case 1: return VTMLocalized(@"baby.sendErr.noCharacteristic");
        case 2: return VTMLocalized(@"baby.sendErr.notConnected");
        case 3: return VTMLocalized(@"baby.sendErr.timeout");
        default: return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.sendErr.unknown"), errorCode];
    }
}

+ (NSString *)versionString:(u_int)v {
    return [NSString stringWithFormat:@"%u.%u.%u", (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];
}

+ (NSString *)alarmBitsString:(u_char)bits {
    NSArray *keys = @[@"baby.alarm.kick", @"baby.alarm.temp", @"baby.alarm.rr", @"baby.alarm.posture"];
    NSMutableArray *on = [NSMutableArray array];
    for (NSUInteger i = 0; i < keys.count; i++) {
        if (bits & (1 << i)) {
            [on addObject:VTMLocalized(keys[i])];
        }
    }
    return [NSString stringWithFormat:@"0x%02X(%@)", bits,
            on.count ? [on componentsJoinedByString:@"/"] : VTMLocalized(@"baby.alarm.allOff")];
}

+ (NSString *)ledWorkTimeString:(u_char)v {
    if (v == 0x00) return VTMLocalized(@"baby.ledTime.alwaysOn");
    if (v == 0xFF) return VTMLocalized(@"baby.ledTime.off");
    return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.ledTime.minutes"), v];
}

+ (NSString *)runStatusString:(u_char)s {
    switch (s) {
        case VTMBabyWorkStatusIDLE:    return VTMLocalized(@"baby.status.idle");
        case VTMBabyWorkStatusWORK:    return VTMLocalized(@"baby.status.work");
        case VTMBabyWorkStatusCHARGE:  return VTMLocalized(@"baby.status.charge");
        case 0x03:                     return VTMLocalized(@"baby.status.upgrade");
        case VTMBabyWorkStatusTEST:    return VTMLocalized(@"baby.status.test");
        case VTMBabyWorkStatusABNORMA: return VTMLocalized(@"baby.status.abnormal");
        default: return [NSString stringWithFormat:@"0x%02X", s];
    }
}

+ (NSString *)gestureString:(u_char)g {
    switch (g) {
        case VTMBabyGyrosStatusSupine: return VTMLocalized(@"baby.gesture.supine");
        case VTMBabyGyrosStatusRight:  return VTMLocalized(@"baby.gesture.right");
        case VTMBabyGyrosStatusLeft:   return VTMLocalized(@"baby.gesture.left");
        case VTMBabyGyrosStatusProne:  return VTMLocalized(@"baby.gesture.prone");
        case VTMBabyGyrosStatusSitUp:  return VTMLocalized(@"baby.gesture.sitUp");
        default: return [NSString stringWithFormat:@"0x%02X", g];
    }
}

+ (NSString *)sleepStateString:(u_char)s {
    switch (s) {
        case VTMBabySleepStateDeep:    return VTMLocalized(@"baby.sleep.deep");
        case VTMBabySleepStateLight:   return VTMLocalized(@"baby.sleep.light");
        case VTMBabySleepStateWake:    return VTMLocalized(@"baby.sleep.wake");
        case VTMBabySleepStateUnknown: return VTMLocalized(@"baby.sleep.unknown");
        default: return [NSString stringWithFormat:@"0x%02X", s];
    }
}

+ (NSString *)eventString:(u_short)eventId {
    switch (eventId) {
        case VTMBabyEventIdLieProne: return VTMLocalized(@"baby.event.prone");
        case VTMBabyEventIdTempLow:  return VTMLocalized(@"baby.event.tempLow");
        case VTMBabyEventIdTempHigh: return VTMLocalized(@"baby.event.tempHigh");
        case VTMBabyEventIdTempDrop: return VTMLocalized(@"baby.event.kick");
        case VTMBabyEventIdRRLow:    return VTMLocalized(@"baby.event.rrLow");
        case VTMBabyEventIdRRHigh:   return VTMLocalized(@"baby.event.rrHigh");
        case 0x0007:                 return VTMLocalized(@"baby.event.cough");
        case 0x0008:                 return VTMLocalized(@"baby.event.tachypnea");
        default: return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.event.unknown"), eventId];
    }
}

+ (NSString *)timestampString:(u_int)ts {
    if (ts == 0) {
        return @"-";
    }
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"MM-dd HH:mm:ss";
    });
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:ts]];
}

/// 解析非负整数输入，失败时返回错误说明
+ (nullable NSString *)parseInteger:(NSString *)input min:(NSInteger)min max:(NSInteger)max
                               name:(NSString *)name value:(NSInteger *)value {
    NSString *trimmed = [input stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSScanner *scanner = [NSScanner scannerWithString:trimmed];
    NSInteger v = 0;
    if (trimmed.length == 0 || ![scanner scanInteger:&v] || !scanner.isAtEnd) {
        return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.err.notInteger"), name];
    }
    if (v < min || v > max) {
        return [NSString stringWithFormat:VTMLocalized(@"baby.fmt.err.range"), name, (long)min, (long)max];
    }
    *value = v;
    return nil;
}

@end
