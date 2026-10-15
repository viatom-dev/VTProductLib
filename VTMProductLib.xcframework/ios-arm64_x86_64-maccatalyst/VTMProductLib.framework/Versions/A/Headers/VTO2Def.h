//
//  VTO2Def.h
//  VTO2Lib
//
//  Created by viatom on 2020/6/28.
//  Copyright © 2020 viatom. All rights reserved.
//

#ifndef VTO2Def_h
#define VTO2Def_h

#ifdef DEBUG
    #define DLog( s, ... ) NSLog( @"<%@,(line=%d)> %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
    #define DLog( s, ... )
#endif

typedef enum : NSUInteger {
    VTFileLoadResultSuccess,
    VTFileLoadResultTimeOut,
    VTFileLoadResultFailed,
    VTFileLoadResultNotExist,
} VTFileLoadResult;  /// @brief result of download file from peripheral

typedef enum : NSUInteger {
    VTCommonResultFailed,
    VTCommonResultSuccess,
    VTCommonResultUnsupport,
} VTCommonResult; /// @brief result of normal command

typedef enum : u_char {
    VTCmdStartWrite = 0x0,
    VTCmdWriteContent = 0x01,
    VTCmdEndWrite = 0x02,
    VTCmdStartRead = 0x03,
    VTCmdReadContent = 0x04,
    VTCmdEndRead = 0x05,
    VTCmdLangStartUpdate = 0x0A,
    VTCmdLangUpdateData = 0x0B,
    VTCmdLangEndUpdate = 0x0C,
    VTCmdAppStartUpdate = 0x0D,
    VTCmdAppUpdateData = 0x0E,
    VTCmdAppEndUpdate = 0x0F,
    VTCmdGetInfo = 0x14,
    VTCmdPing = 0x15,
    VTCmdSyncTime = 0x16,
    VTCmdGetRealData = 0x17,
    VTCmdSetFactory = 0x18,
    VTCmdGetRealWave = 0x1B,
    VTCmdGetPPG = 0x1C,
    VTCmdGetStationInfo = 0x1D,
    
    VTCmdOpenupEncryption = 0xFF,
    
} VTCmd;

typedef enum : u_char {
    VTA5CmdMakeSend = 0x10,
    VTA5CmdRealParams = 0x11,
    VTA5CmdRealWave = 0x12,
    VTA5CmdRealPPG = 0x13,
    VTA5CmdRealACC = 0x14,
    VTA5CmdOpenupEncryption = 0xFF,
} VTA5Cmd;

typedef enum : u_char {
    VTBabyS3CmdRunParams = 0x02,
} VTBabyS3Cmd;

typedef enum : u_char {
    VTA5RespRequest = 0x00,            ///< request
    VTA5RespNormal = 0x01,             ///< normal
    VTA5RespNotFound = 0xE0,           ///< not found file
    VTA5RespOpenFailed = 0xE1,         ///< open file failed
    VTA5RespReadFailed = 0xE2,         ///< read file failed
    VTA5RespWriteFailed = 0xE3,        ///< write file failed
    VTA5RespReadFileListFailed = 0xF1, ///< read file's list failed
    VTA5RespDeviceOccupied = 0xFB,     ///< device occupied, e.g. use occupied
    VTA5RespFormatError = 0xFC,
    VTA5RespFormatUnsupport = 0xFD,
    VTA5RespCommonError = 0xFF,
    VTA5RespHeadError = 0xCC,
    VTA5RespCRCError = 0xCD,
} VTA5RespRes;


typedef enum : u_char{
    CHANNAL_SPO2_PR = 0,                //SpO2 + PR
    CHANNEL_SPO2_PR_MOTION,             //SpO2 + PR + Motion
} VTSleepO2Channel_t;


#pragma mark - peripheral information's params
// Supported parameters refer to protocol documentation
typedef enum : NSUInteger {
    VTParamTypeDate,                // Date
    VTParamTypeOxiThr,              // threshold of spo2
    VTParamTypeMotor,               // vibrate motor. View Readme.md
    VTParamTypePedtar,              // pedter,
    VTParamTypeLightingMode,        // 0：normal，1：always off，2：always on
    VTParamTypeHeartRateSwitch,     // switch 0 - off 1 - on
    VTParamTypeHeartRateLowThr,     // threshold. View Readme.md
    VTParamTypeHeartRateHighThr,    // threshold. View Readme.md
    VTParamTypeLightStrength,       // lightness. 0-2
    VTParamTypeOxiSwitch,           // switch 0 - off 1 - on
    VTParamTypeBuzzer,              // Buzzer. 0、20、40、80、100
    VTParamTypeMtSw,                // switch 0 - off 1 - on
    VTParamTypeMtThr,               // Motion thershold.  0-255
    VTParamTypeIvSw,                // switch 0 - off 1 - on
    VTParamTypeIvThr,               // invalid value threshold.
    VTParamTypeSpO2Sw,              // switch 0 - off 1 - on
    VTParamTypeHandedness           // handedness 0 - left 1 - right
} VTParamType;


#pragma mark - station babyo2 s2

typedef struct {
    u_char burn_flag;       //烧录标记    e.g. bit0:SN  bit1:硬件版本  bit2:Branch Code
    u_char sn[11];
    u_char hw_version;      //硬件版本    ‘A’-‘Z’
    u_char branch_code[8];  //Branch编码
} VTO2FactoryConfig;

typedef struct {
    u_char len;                     // serial numbers length  e.g. 10
    u_char serial_num[18];          // serial numbers
} VTO2StationSN;

typedef struct{
    u_char hw_version;              // hardware version    e.g. ‘A’ : A
    u_int  fw_version;              // firmware version    e.g. 0x010100 : V1.1.0
    u_int  bl_version;              // bootloader version    e.g. 0x010100 : V1.1.0
    u_char branch_code[8];          // branchcode e.g. “40020000” : Ezcardio Plus
    u_char reserved0[3];            // reserved
    u_short device_type;            // device type   e.g. 0x8611
    u_short protocol_version;       // protocal version   e.g.0x0100:V1.0
    u_char cur_time[7];             // current time    e.g.0xE1070301090000:2017-03-01 09:00:00
    u_short protocol_data_max_len;  // max length
    u_char reserved1[4];            // reserved
    VTO2StationSN sn;
    u_char reserved2[1];            // reserved
} VTO2StationInfo;


#pragma pack (1)
typedef struct{
    uint32_t    record_time;        ///< duration    unit: second    暂无使用
    uint8_t     run_state;          ///< run state  0: prepare 1: prepare to measure  2: measuring 3: end
    uint8_t     sensor_state;       ///< sensor state 0: normal 1: finger out 2: SENSOR_STA_PROBE_OUT 3:  error
    uint8_t     spo2;
    uint8_t     pi;                 ///< PI *10 e.g.  15 : PI = 1.5
    uint16_t    pr;
    uint8_t     flag;               ///< bit0: Pulse mark
    uint8_t     motion;
    uint8_t     battery_state;      ///< battery state    0: normal  1: charging  2: charge full 3: low
    uint8_t     battery_percent;    ///< battery percent
    uint8_t     reserved[6];
} VTParameters;

typedef struct {
    uint32_t index;            //波形数据第一个点相对于起始点的编号 暂无使用
    uint16_t sampling_num;                //波形数据采样点
    uint8_t *waveform_data;    //125Hz波形数据
} VTA5Wave;


typedef struct {
    short ir;
    short red;
} VTA5PPG;

typedef struct {
    uint16_t sampling_num;
    VTA5PPG *raw_data;
} VTA5Raw;

typedef struct {
    int16_t x;
    int16_t y;
    int16_t z;
} VTA5Axis;


typedef struct {
    uint16_t sampling_num;
    VTA5Axis *data;
} VTA5Acc;




#pragma pack()


#endif /* VTO2Def_h */
