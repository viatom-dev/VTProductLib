//
//  VTMBLEEnum.h
//  VTMProductDemo
//
//  Created by viatom on 2020/10/26.
//

#ifndef VTMBLEEnum_h
#define VTMBLEEnum_h

typedef enum : u_char {
    VTMDeviceTypeUnknown,
    VTMDeviceTypeECG,           // ER1/ER2/VBeat/DuoEK/DuoEKS
    VTMDeviceTypeBP,            // BP2/BP2A/BP2T/BP2W/BP2Pro
    VTMDeviceTypeScale,         // S1/
    VTMDeviceTypeER3,           // Lepod/
    VTMDeviceTypeMSeries,       // M12/M5
    VTMDeviceTypeWOxi,          // O2Ring S/
    VTMDeviceTypeFOxi,          // PF-10BWS/
    VTMDeviceTypeBabyPatch,     // BBSM P1/
} VTMDeviceType;

typedef enum : u_char {
    VTMBLEHeaderDefault = 0xA5,
} VTMBLEHeader;

typedef enum : u_char {
    VTMBLEPkgTypeRequest = 0x00,            ///< request
    VTMBLEPkgTypeNormal = 0x01,             ///< normal
    VTMBLEPkgTypeNotFound = 0xE0,           ///< not found file
    VTMBLEPkgTypeOpenFailed = 0xE1,         ///< open file failed
    VTMBLEPkgTypeReadFailed = 0xE2,         ///< read file failed
    VTMBLEPkgTypeWriteFailed = 0xE3,        ///< write file failed
    VTMBLEPkgTypeReadFileListFailed = 0xF1, ///< read file's list failed
    VTMBLEPkgTypeDeviceOccupied = 0xFB,     ///< device occupied, e.g. use occupied
    VTMBLEPkgTypeFormatError = 0xFC,
    VTMBLEPkgTypeFormatUnsupport = 0xFD,
    VTMBLEPkgTypeCommonError = 0xFF,
    VTMBLEPkgTypeHeadError = 0xCC,
    VTMBLEPkgTypeCRCError = 0xCD,
} VTMBLEPkgType;

typedef enum : u_char {
    VTMBLECmdEcho = 0xE0,                   // 回显
    VTMBLECmdGetDeviceInfo = 0xE1,          // 获取设备信息
    VTMBLECmdReset = 0xE2,                  // 复位
    VTMBLECmdRestore = 0xE3,                // 恢复出厂
    VTMBLECmdGetBattery = 0xE4,             // 获取电池状态
    VTMBLECmdUpdateFirmware = 0xE5,         // 开始固件升升级
    VTMBLECmdUpdateFirmwareData = 0xE6,     // 发送固件升级数据
    VTMBLECmdUpdateFirmwareEnd = 0xE7,      // 固件升级结束
    VTMBLECmdUpdateLangua = 0xE8,           // 开始升级语言包
    VTMBLECmdUpdateLanguaData = 0xF8,       // 发送语言包数据
    VTMBLECmdUpdateLanguaEnd = 0xE9,        // 结束升级语言包
    VTMBLECmdRestoreInfo = 0xEA,            // 烧录出厂信息
    VTMBLECmdEncrypt = 0xEB,                // 加密Flash
    VTMBLECmdSyncTime = 0xEC,               // 同步时间
    VTMBLECmdGetDeviceTemp = 0xED,          // 获取设备温度
    VTMBLECmdProductReset = 0xEE,           // 恢复生产出厂设置
    VTMBLECmdGetFileList = 0xF1,            //读取文件列表
    VTMBLECmdStartRead = 0xF2,              // 读文件开始
    VTMBLECmdReadFile = 0xF3,               // 读文件
    VTMBLECmdEndRead = 0xF4,                // 读文件结束
    VTMBLECmdStartWrite = 0xF5,             // 写文件开始
    VTMBLECmdWriteData = 0xF6,              // 写文件
    VTMBLECmdEndWrite = 0xF7,               // 写文件结束
    VTMBLECmdDeleteFile = 0xF8,
    VTMBLECmdGetUserList = 0xF9,
    VTMBLECmdEnterDFU = 0xFA,
    
    VTMBLECmdSyncTimeZone = 0xC0            // 同步时间时区
} VTMBLECmd;

typedef enum : u_char {
    VTMECGCmdGetConfig = 0x00,
    VTMECGCmdGetRealWave = 0x01,            //获取实时波形
    VTMECGCmdGetRunStatus = 0x02,           // 获取运行状态
    VTMECGCmdGetRealData = 0x03,            // 获取实时数据
    VTMECGCmdSetConfig = 0x04,              // 设置参数
    VTMECGCmdExitMeasure = 0x05,            // ER1S 结束测量
    
    VTMER3ECGCmdGetRealData = 0x03,         //  ER3获取实时数据
    VTMMSeriesCmdGetRealData = 0x06,        // M5/M12 获取实时数据
    VTMER3ECGCmdExitMeasure = 0x07,         // ER3退出测量模式
    VTMER3ECGCmdStartMeasure = 0x08,        // ER3启动测量模式
    VTMER3ECGCmdGetConfigParams = 0x09,     // ER3获取配置参数
    VTMER3ECGCmdSetConfigParams = 0x0A,     // ER3设备配置参数
} VTMECGCmd;

typedef enum : u_char {
    VTMBPCmdGetConfig = 0x00,
    VTMBPCmdCalibrateZero = 0x01,
    VTMBPCmdCalibrateSlope = 0x02,
    VTMBPCmdGetRealPressure = 0x05,
    VTMBPCmdGetRealStatus = 0x06,
    VTMBPCmdGetRealWave = 0x07,
    VTMBPCmdGetRealData = 0x08,
    VTMBPCmdSwiRunStatus = 0x09,
    VTMBPCmdStartMeasure = 0x0A,
    VTMBPCmdSetConfig = 0x0B,
    /** BP2 WiFi / bp3 */
    VTMBPCmdScanWiFiList = 0x11,
    VTMBPCmdSetWiFiConfig = 0x12,
    VTMBPCmdGetWiFiConfig = 0x13,
    /** BP3 */
    VTMBPCmdSetAlarmInfo = 0x14,
    VTMBPCmdGetAlarmInfo = 0x15,
    VTMBPCmdGetCRCUserList = 0x30,     // 获取用户列表校验
    VTMBPCmdGetCRCECGList = 0x31,
    VTMBPCmdGetCRCBPList = 0x32,
    VTMBPCmdBindStatus = 0x35, 
} VTMBPCmd;

typedef enum : u_char {
    VTMSCALECmdGetConfig = 0x00,
    VTMSCALECmdGetRealWave = 0x01,
    VTMSCALECmdGetRunParams = 0x02,
    VTMSCALECmdGetRealData = 0x03,
} VTMSCALECmd;

// MARK: O2Ring S

typedef enum : u_char {
    VTMWOxiCmdGetConfig = 0x00,
    VTMWOxiCmdSetConfig = 0x01,
    VTMWOxiCmdGetRealData = 0x04,
    VTMWOxiCmdGetRawdata = 0x05,
    VTMWOxiCmdGetPPGList = 0x06,
    VTMWOxiCmdGetPPGStart = 0x07,
    VTMWOxiCmdGetPPGContent = 0x08,
    VTMWOxiCmdGetPPGEnd = 0x09,
    VTMWOxiCmdSetUTCTime = 0xC0,
} VTMWOxiCmd;


typedef enum: NSUInteger {
    VTMWOxiSetParamsAll = 0,               // 预留，后续可能支持批量设置
    VTMWOxiSetParamsSpO2Sw,                // 血氧提醒开关 bit0:震动 bit1:声音
    VTMWOxiSetParamsSpO2Thr,               // 血氧阈值
    VTMWOxiSetParamsHRSw,                  // 心率提醒开关 bit0:震动 bit1:声音
    VTMWOxiSetParamsHRThrLow,              // 心率提醒低阈值
    VTMWOxiSetParamsHRThrHigh,             // 心率提醒高阈值
    VTMWOxiSetParamsMotor,                 // 震动强(震动强度不随开关的改变而改变)
    VTMWOxiSetParamsBuzzer,                // 声音强度 (checkO2Plus：最低：20，低:40，中：60，高：80，最高：100)
    VTMWOxiSetParamsDisplayMode,           // 显示模式
    VTMWOxiSetParamsBrightness,            // 屏幕亮度 0：息屏 1：低亮屏 2：中 3：高
    VTMWOxiSetParamsInterval,              // 存储间隔
} VTMWOxiSetParams;

typedef enum: NSUInteger {
    VTMWOxiChannelSpO2PR = 0,
    VTMWOxiChannelSpO2PRMotion,
} VTMWOxiChannel;


// MARK: PF-10BWS
typedef enum: NSUInteger {
    VTMFOxiESModeOff = 0,
    VTMFOxiESMode1Min ,
    VTMFOxiESMode3Min ,
    VTMFOxiESMode5Min ,
} VTMFOxiESMode;

typedef enum: u_char {
    VTMFOxiCmdGetConfig = 0x00,
    VTMFOxiCmdSetConfig = 0x01,
    VTMFOxiCmdMakeInfoSend = 0x02,
    VTMFOxiCmdMakeWaveSend = 0x03,
    VTMFOxiCmdInfoResp = 0x04,
    VTMFOxiCmdWaveResp = 0x05,
    VTMFOxiCmdWorkMode = 0x06,
} VTMFOxiCmd;

typedef enum: NSUInteger {
    VTMFOxiSetParamsAll = 0,               // 预留，后续可能支持批量设置
    VTMFOxiSetParamsSpO2Low,               // 血氧提醒阈值 85%-99% 步进：1%
    VTMFOxiSetParamsPRHigh,                // 脉搏高阈值 100bpm-240bpm；步进：5bpm
    VTMFOxiSetParamsPRLow,                 // 脉搏低阈值  30bpm-60bpm；步进：5bpm
    VTMFOxiSetParamsAlram,                 // 阈值提醒开关 0:关 1：开
    VTMFOxiSetParamsMeasureMode,           // 测量模式 1：点测 2：连续（预留）
    VTMFOxiSetParamsBeep,                  // 蜂鸣器开关  0:关 1：开
    VTMFOxiSetParamsLanguage,              // 语言包 0:英文 1：中文
    VTMFOxiSetParamsBleSw,                 // 蓝牙开关 0:关 1：开（预留）
    VTMFOxiSetParamsESMode,                // 测量过程，定时息屏
} VTMFOxiSetParams;



// MARK: BP2W

typedef enum : u_char {
    VTMBPTargetStatusBP = 0,
    VTMBPTargetStatusECG = 1,
    VTMBPTargetStatusHistory = 2,
    VTMBPTargetStatusStart = 3,
    VTMBPTargetStatusEnd = 4
} VTMBPTargetStatus;

typedef enum : u_char {
    VTMBPStatusSleep = 0,               // 关机
    VTMBPStatusMemery,                  // 数据回顾
    VTMBPStatusCharge,                  // 充电
    VTMBPStatusReady,                   // 开机预备状态
    VTMBPStatusBPMeasuring,             // 血压测量中
    VTMBPStatusBPMeasureEnd,            // 血压测量结束
    VTMBPStatusECGMeasuring,            // 心电测量中
    VTMBPStatusECGMeasureEnd,           // 心电测量结束
    VTMBPStatusBPAVGMeasure = 15,       // BP2WIFI血压测量x3中
    VTMBPStatusBPAVGMeasureWait = 16,   // BP2WIFI血压测量x3等待开始状态
    VTMBPStatusBPAVGMeasureEnd = 17,    // BP2WIFI血压测量x3结束
    VTMBPStatusVEN = 20,    //BP2理疗 理疗模式中
    VTMBPStatusBPMeasuringBP3 = 21,  // BP3血压心电测量中
    VTMBPStatusBPMeasureEndBP3 = 22,  // BP3血压心电测量结束
    VTMBPStatusECGMeasuringBP3 = 23,    //BP3血压心电测量x3中
    VTMBPStatusECGMeasureEndBP3 = 24,    //BP3血压心电测量x3结束
    VTMBPStatusNetworkConfig = 25,    //配置WiFi和服务器
    VTMBPStatusDataUploading = 26,    //数据上传服务器
    VTMBPStatusINVAIL = 0xFF,

} VTMBPStatus;

// MARK: BP3
//week_repeat的最高位表示是否重复，1表示每个星期都重复，0表示永不重复，若是永不重复则week_repeat的低7位要全部填1(即0x7F)，以表示每天都有效，这样设备则会仅定时测量一次后删除。
typedef enum : u_char {
    VTMBPRepeatSun     = 1<<0,  //  every Sunday repeat
    VTMBPRepeatMon     = 1<<1,  //  every Monday repeat
    VTMBPRepeatTues    = 1<<2,  //  every Tuesday repeat
    VTMBPRepeatWed     = 1<<3,  //  every Wednesday repeat
    VTMBPRepeatThu     = 1<<4,  //  every Thursday repeat
    VTMBPRepeatFri     = 1<<5,  //  every Friday repeat
    VTMBPRepeatSat     = 1<<6,  //  every Saturday repeat
    VTMBPRepeatNone    = 1<<7,  //  1:重复, 0:不重复
} VTMBPRepeat;


// MARK: LepodPro

/// 显示导联 @[@"I", @"II", @"III", @"aVR", @"aVL", @"aVF", @"V1", @"V2", @"V3", @"V4", @"V5", @"V6"];
typedef NS_ENUM(NSUInteger, VTMER3ShowLead) {
    VTMER3ShowLead_I = 0,
    VTMER3ShowLead_II,
    VTMER3ShowLead_III,
    VTMER3ShowLead_aVR,
    VTMER3ShowLead_aVL,
    VTMER3ShowLead_aVF,
    VTMER3ShowLead_V1,
    VTMER3ShowLead_V2,
    VTMER3ShowLead_V3,
    VTMER3ShowLead_V4,
    VTMER3ShowLead_V5,
    VTMER3ShowLead_V6,
};

/// ER3导联类型
typedef enum : u_char {
    VTMER3Cable_LEAD_10 = 0x00,       // 10导            8通道
    VTMER3Cable_LEAD_6 = 0x01,        // 6导             4通道
    VTMER3Cable_LEAD_5 = 0x02,        // 5导             4通道
    VTMER3Cable_LEAD_3 = 0x03,        // 3导             4通道
    VTMER3Cable_LEAD_3_TEMP = 0x04,   // 3导 带体温       4通道
    VTMER3Cable_LEAD_4_LEG = 0x05,    // 4导 带胸贴       4通道
    VTMER3Cable_LEAD_5_LEG = 0x06,    // 5导 带胸贴       4通道
    VTMER3Cable_LEAD_6_LEG = 0x07,    // 6导 带胸贴       4通道
    VTMER3Cable_LEAD_Unidentified = 0xff,// 未识别的导联线
} VTMER3Cable;

// MAKR: BABY
typedef enum: u_char {
    VTMBabyCmdGetConfig = 0x00,
    VTMBabyCmdSetConfig ,
    VTMBabyCmdGetRunParams,
    VTMBabyCmdGetGesture,
} VTMBabyCmd;

typedef enum: u_char {
    VTMBabySetParamsAll = 0,        // 预留，后续可能支持批量设置
    VTMBabySetParamsLED ,           // 设置指示灯报警开关
    VTMBabySetParamsBEEP ,          // 设置声音报警开关
    VTMBabySetParamsWAIT ,          // 设置报警等待类型
    VTMBabySetParamsTEMPLow ,       // 温度报警阈值下限
    VTMBabySetParamsTEMPHigh,       // 温度报警阈值上限
    VTMBabySetParamsRRLow,          // 呼吸率报警阈值下限
    VTMBabySetParamsRRHigh ,        // 呼吸率报警阈值上限
    VTMBabySetParamsSensivity,      // 设置报警灵敏度-->范围[1,3]
    VTMBabySetParamsWearLEDTime,    // 佩戴指示灯工作时间设置
} VTMBabySetParams;

/* 姿势类型 */
typedef enum {
    VTMGyrosStatusSupine = 0,   // 仰卧
    VTMGyrosStatusRight,        // 右侧卧
    VTMGyrosStatusLeft,         // 左侧卧
    VTMGyrosStatusLieProne,     // 俯卧
    VTMGyrosStatusSitUp,        // 坐起
} VTMGyrosStatus;
/* 温度报警类型 */
typedef enum {
    VTMTempAlermNormal = 0x00,      // Normal temperature
    VTMTempAlermLow ,               // Low temperature alarm
    VTMTempAlermHigh,               // High temperature alarm
    VTMTempAlermFast,               // Cooling too fast (alarm when the temperature drops by more than 3 ℃ within 15 minutes)
} VTMTempAlerm;
 
/* 系统工作状态 */
typedef enum {
    VTMBabyWorkStatusIDLE = 0x00,           // 待机模式（未佩戴）
    VTMBabyWorkStatusWORK,                  // 工作模式（已佩戴）
    VTMBabyWorkStatusCHARGE,                // 充电模式
    VTMBabyWorkStatusTEST = 0x70,           // 测试模式
    VTMBabyWorkStatusABNORMA = 0x80,        // 设备异常（软件、硬件设备自检异常）
} VTMBabyWorkStatus;




#endif /* VTMBLEEnum_h */
