//
//  VTMBLEStruct.h
//  VTMProductDemo
//
//  Created by viatom on 2020/10/26.
//

#ifndef VTMBLEStruct_h
#define VTMBLEStruct_h

#include <CoreGraphics/CGBase.h>
#import "VTMBLEEnum.h"

// 对齐方式 首字节对齐
#pragma pack(1)
/// @brief start update firmware . EqulTo  StartFirmwareUpdate.
struct
VTMStartFirmwareUpdate {
    u_char device_type;
    u_char fw_version[3];
};
typedef struct CG_BOXABLE VTMStartFirmwareUpdate VTMStartFirmwareUpdate;

/// @brief update firmware. EqulTo FirmwareUpdate.
struct
VTMFirmwareUpdate {
    unsigned addr_offset;
    u_char *fw_data;
};
typedef struct CG_BOXABLE VTMFirmwareUpdate VTMFirmwareUpdate;

/// @brief start update language pkg. EqulTo StartLanguageUpdate
struct
VTMStartLanguageUpdate {
    u_char device_type; //设备类型,chekme产品ID高位
    u_char lang_version; //语言包版本
    u_int  size; //大小
};
typedef struct CG_BOXABLE VTMStartLanguageUpdate VTMStartLanguageUpdate;

/// @brief update language pkg. EqulTo LanguageUpdate.
struct
VTMLanguageUpdate {
    unsigned addr_offset; //地址偏移
    u_char *lang_data; //固件数据
};
typedef struct CG_BOXABLE VTMLanguageUpdate VTMLanguageUpdate;

/// @brief serial number of viatom's device.  EqulTo SN.
struct
VTMSN {
    u_char len; // length of sn  e.g. 10
    u_char serial_num[18]; // sn
};
typedef struct CG_BOXABLE VTMSN VTMSN;

/// @brief factory config of viatom's device. EqulTo FactoryConfig.
struct
VTMConfig {
    u_char burn_flag;       //烧录标记    e.g. bit0:SN  bit1:硬件版本  bit2:Branch Code
    u_char hw_version;      //硬件版本    ‘A’-‘Z’
    u_char branch_code[8];  //Branch编码
    VTMSN sn;
};
typedef struct CG_BOXABLE VTMConfig VTMConfig;

/// @brief time of viatom's device. EqulTo DeviceTime.
struct
VTMDeviceTime {
    u_short year;
    u_char month;
    u_char day;
    u_char hour;
    u_char minute;
    u_char second;
};
typedef struct CG_BOXABLE VTMDeviceTime VTMDeviceTime;

/// @brief time of viatom's device. EqulTo DeviceTime.
struct
VTMDeviceTimeZone {
    u_short year;
    u_char month;
    u_char day;
    u_char hour;
    u_char minute;
    u_char second;
    char timeZone;
};
typedef struct CG_BOXABLE VTMDeviceTimeZone VTMDeviceTimeZone;

/// @brief start read and open the file system of viatom's device. EqulTo FileReadStart.
struct
VTMOpenFile {
    u_char file_name[16];       // 支持15个字符长度文件名
    u_int file_offset;          // 文件偏移,用于断点续传
};
typedef struct CG_BOXABLE VTMOpenFile VTMOpenFile;

/// @brief Read a part of the file at the specified offset.  EqulTo FileRead.
struct
VTMReadFile {
    unsigned addr_offset;           // offset. length which has read file.
};
typedef struct CG_BOXABLE VTMReadFile VTMReadFile;

/// @brief information of viatom's device
struct
VTMDeviceInfo {
    u_char hw_version;              // hardware version           e.g. ‘A’ : A
    u_int  fw_version;              // firmware version           e.g. 0x010100 : V1.1.0
    u_int  bl_version;              // bootloader version         e.g. 0x010100 : V1.1.0
    u_char branch_code[8];          // brach code            e.g. “40020000” : Ezcardio Plus
    u_char reserved0[3];            // reserved
    u_short device_type;            // device type             e.g. 0x8611: sphygmometer
    u_short protocol_version;       // protocol version    e.g.0x0100:V1.0
    u_char cur_time[7];             // date                     e.g.0xE1070301090000:2017-03-01 09:00:00
    u_short protocol_data_max_len;  // Max length that protocol support
    u_char reserved1[4];            // reserved
    VTMSN sn;
    u_char reserved2[4];            // reserved
};
typedef struct CG_BOXABLE VTMDeviceInfo VTMDeviceInfo;

/// @brief battery info of viatom's device. EqulTo BatteryInfo.
struct
VTMBatteryInfo {
    u_char state; //电池状态 e.g.   0:正常使用 1:充电中 2:充满 3:低电量
    u_char percent; //电池状态 e.g.    电池电量百分比
    u_short voltage; //电池电压(mV)    e.g.    3950 : 3.95V
};
typedef struct CG_BOXABLE VTMBatteryInfo VTMBatteryInfo;

/// @brief file name .  EqulTo FileName
struct
VTMFileName {
    u_char str[16];
};
typedef struct CG_BOXABLE VTMFileName VTMFileName;

/// @brief file list.  EqulTo FileList
struct
VTMFileList {
    u_char file_num;
    VTMFileName fileName[255];
};
typedef struct CG_BOXABLE VTMFileList VTMFileList;

/// @brief start read  return.  EqulTo FileStartReadReturn
struct
VTMOpenFileReturn {
    u_int file_size;  // 读取文件的总长度
};
typedef struct CG_BOXABLE VTMOpenFileReturn VTMOpenFileReturn;

/// @brief file data. EqulTo FileData.
struct
VTMFileData {
    u_char *file_data;
};
typedef struct CG_BOXABLE VTMFileData VTMFileData;

/// @brief start write return.  EqulTo FileWriteStartReturn.
struct
VTMWriteFileReturn {
    u_char file_name[16]; //支持15个字符长度文件名
    u_int file_offset; //文件偏移,支持续写改写
    u_int file_size; //文件大小
};
typedef struct CG_BOXABLE VTMWriteFileReturn VTMWriteFileReturn;

/// @brief user list of viatom's device. EqulTo UserList.
struct
VTMUserList {
    u_short user_num; //用户数量
    u_char *user_ID[30]; //用户唯一ID
};
typedef struct CG_BOXABLE VTMUserList VTMUserList;

/// @brief temperature . EqulTo Temperature.
struct
VTMTemperature {
    short temp; //温度*100    e.g. 2410:24.1摄氏度
};
typedef struct CG_BOXABLE VTMTemperature VTMTemperature;

#pragma mark --- ECG
/// @brief send rate.  EqulTo SendRate
struct
VTMRate {
    u_char rate;
};
typedef struct CG_BOXABLE VTMRate VTMRate;

/// @brief head of file. EqulTo FileHead_t
struct
VTMFileHead {
    u_char file_version;        //文件版本 e.g.  0x01 :  V1
    u_char reserved[9];        //预留
};
typedef struct CG_BOXABLE VTMFileHead VTMFileHead;

/// @brief real-time waveform. EqulTo RealTimeWaveform.
struct
VTMRealTimeWF {
    u_short sampling_num;        //采样点数
    short wave_data[300];        //原始数据
};
typedef struct CG_BOXABLE VTMRealTimeWF VTMRealTimeWF;

/// @brief parameters of device run.  EqulTo DeviceRunParameters of
struct
VTMRunParams {
    u_short hr;                     // 当前主机实时心率 bpm
    u_char sys_flag;                // bit0:R波标记(主机缓存有R波标记200ms)  bit6-7:电池状态(0:正常使用 1:充电中 2:充满 3:低电量)  bit3:导联状态(0:OFF  1:ON)
    u_char percent;                 // 电池状态 e.g.    100:100%
    u_int record_time;              // 已记录时长    单位:second
    u_char run_status;              // 运行状态
    u_char reserved[11];            // 预留
};
typedef struct CG_BOXABLE VTMRunParams VTMRunParams;

/// @brief Split flag to detail params.
struct
VTMFlagDetail {
    u_char rMark;
    u_char signalWeak;
    u_char signalPoor;
    u_char batteryStatus;
};
typedef struct CG_BOXABLE VTMFlagDetail VTMFlagDetail;

/// @brief Split run_status.
struct
VTMRunStatus {
    u_char curStatus;// 本次运行状态  0x0 空闲待机(导联脱落) 0x1 测量准备（主机丢弃前段波形阶段）  0x2记录中 0x3分析存储中 0x4 已存储成功(满时间测量结束后一直停留此状态  直至回到空闲状态) 0x5 少于30s  0x6
    u_char preStatus;
};
typedef struct CG_BOXABLE VTMRunStatus VTMRunStatus;


/// @brief real-time data. EqulTo RealTimeData.
struct
VTMRealTimeData {
    VTMRunParams run_para;
    VTMRealTimeWF waveform;
};
typedef struct CG_BOXABLE VTMRealTimeData VTMRealTimeData;

/// @brief analysis total result.  EqulTo AnalysisTotalResult
struct
VTMECGTotalResult {
    u_char file_version;        //文件版本 e.g.  0x01 :  V1
    u_char reserved0[9];        // 预留
    u_int recording_time;        //同波形文件recording_time
    u_char reserved1[66];        //预留
};
typedef struct CG_BOXABLE VTMECGTotalResult VTMECGTotalResult;

/// @brief analysis result. EqulTo AnalysisResult
struct
VTMECGResult {
    u_int  result;            //诊断结果，见诊断结果表[诊断结果表
    u_short hr;                //心率 单位：bpm
    u_short qrs;                //QRS 单位：ms
    u_short pvcs;            //PVC个数
    u_short qtc;                //QTc 单位：ms
    u_char reserved[20];    //预留
};
typedef struct CG_BOXABLE VTMECGResult VTMECGResult;

#pragma mark ------ ER1/VBeat


/*
 * @brief config of er1. EqulTo Configuartion of ER1.
 *
 * # update -- "vibeSw" define. Support for ER1 Plus.
 *
 */
struct
VTMER1Config {
    u_char vibeSw;          // bit0: for heart rate. bit1: for low battery. bit2: for waveform error.  the 0 is off, the 1 is on.
    u_char hrTarget1;       // low threshold. the device vibrates if real-time HR value is lower this value. one vibration per ten secs.
    u_char hrTarget2;       // high threshold. the device vibrates if real-time HR value is higher this value. one vibration per two secs.
};
typedef struct CG_BOXABLE VTMER1Config VTMER1Config;

/*
 * Pls use this struct when er1 software version higher than 1.0.2.0
 */
struct
VTMER1NewConfig {
    // bit0: high HR. bit1: for low battery. bit2: for waveform error.
    // bit3: . bit4: mark. bit5: low HR
    u_char threshold_switch;
    u_char hrTarget1;       // lower of high threshold . the device vibrates if real-time HR value is higher this value. one vibration per ten secs.
    u_char hrTarget2;       // higher of high threshold. the device vibrates if real-time HR value is higher this value. one vibration per two secs.
    u_char hrLowThreshold;  // low threshold. the device vibrates if real-time HR value is lower this value. one vibration per ten secs.
    u_char reserved[8];
};
typedef struct CG_BOXABLE VTMER1NewConfig VTMER1NewConfig;


/// @brief point. EqulTo PointData_t
struct
VTMER1PointData {
    u_char hr;
    u_char motion;
    u_char vibration;
};
typedef struct CG_BOXABLE VTMER1PointData VTMER1PointData;

/// @brief file tail of er1. EqulTo FileTail_t of er1.
struct
VTMER1FileTail {
    u_int recoring_time;
    u_char reserved[12];
    u_int magic;
};
typedef struct CG_BOXABLE VTMER1FileTail VTMER1FileTail;

#pragma mark ------ ER2/DuoEK
/// @brief config of er2. EqulTo Configuartion of ER2.
struct
VTMER2Config {
    u_char ecgSwitch;  // 配置开关  bit0: 心跳声
    u_char vector;     // 加速度值
    u_char motion_count;  // 加速度检测次数
    u_short motion_windows;  // 加速度检测窗口
};
typedef struct CG_BOXABLE VTMER2Config VTMER2Config;

/// @brief file tail of er2. EqulTo FileTail_t of er2.
struct
VTMER2FileTail {
    u_int recording_time;        //测量时间 e.g. 3600 :  3600s
    u_short data_crc;        //文件头部+原始波形和校验
    u_char reserved[10];                //预留
    u_int magic;            //文件标志 固定值为0xA55A0438
};
typedef struct CG_BOXABLE VTMER2FileTail VTMER2FileTail;

/// @brief a-file head of DuoEK.
struct
VTMDuoEKFileAHead {
    u_char file_version;         //文件版本 e.g.  0x01 :  V1
    u_char reserved0[9];         // 预留
    u_int recording_time;        //同波形文件recording_time
    u_char reserved1[66];        //预留
};
typedef struct CG_BOXABLE VTMDuoEKFileAHead VTMDuoEKFileAHead;

/// @brief a-file result of DuoEK.
struct
VTMDuoEKFileAResult {
    u_int  result;              //诊断结果，见诊断结果表[诊断结果表
    u_short hr;                 //心率 单位：bpm
    u_short qrs;                //QRS 单位：ms
    u_short pvcs;               //PVC个数
    u_short qtc;                //QTc 单位：ms
    u_char reserved[20];        //预留
};
typedef struct CG_BOXABLE VTMDuoEKFileAResult VTMDuoEKFileAResult;

#pragma mark --- BP

/// @brief blood pressure result of bp2/bp2a. EqulTo BPResult.
struct
VTMBPBPResult {
    u_char file_version;            //文件版本 e.g.  0x01 :  V1
    u_char file_type;               //文件类型 1：血压；2：心电
    u_int measuring_timestamp;      //测量时间时间戳 e.g.  0:  1970.01.01 00:00:00时间戳
    u_char reserved1[4];            //预留
    u_char status_code;             //状态码，后续补充
    u_short systolic_pressure;      //收缩压
    u_short diastolic_pressure;     //舒张压
    u_short mean_pressure;          //平均压
    u_char pulse_rate;              // 脉率
    u_char medical_result;          //诊断结果 bit0:心率不齐
    u_char reserved2[19];           //预留
};
typedef struct CG_BOXABLE VTMBPBPResult VTMBPBPResult;

/// @brief ecg result of bp2/bp2a.  EqulTo ECGResult.
struct
VTMBPECGResult {
    u_char file_version;          //文件版本 e.g.  0x01 :  V1
    u_char file_type;             //文件类型 1：血压；2：心电
    u_int measuring_timestamp;    //测量时间时间戳 e.g.  0:  1970.01.01 00:00:00时间戳
    u_char reserved1[4];          //预留
    u_int recording_time;         //记录时长
    u_char reserved2[2];          //预留
    u_int result;                 //诊断结果，见诊断结果表[诊断结果表
    u_short hr;                   //心率 单位：bpm
    u_short qrs;                  //QRS 单位：ms
    u_short pvcs;                 //PVC个数
    u_short qtc;                  //QTc 单位：ms
    u_char reserved3[20];         //预留
};
typedef struct CG_BOXABLE VTMBPECGResult VTMBPECGResult;

/// @brief configuartion of bp2.  EqulTo Configuartion.
struct
VTMBPConfig {
    u_int prev_calib_zero;      //上一次校零adc值    e.g.    2800<=zero<=12000 128mV~550mV
    u_int last_calib_zero;      //最后一次校零adc值    e.g.    2800<=zero<=12000 128mV~550mV
    u_int calib_slope;          //校准斜率值*100    e.g.    13630<=slope<=17040 136.3LSB/mmHg-170.4LSB/mmHg
    u_short slope_pressure;     //校准斜率时用的压力值
    u_int calib_ticks;         //最后一次校准时间   time_t转NSData-->NSDate *date = [NSDate dateWithTimeIntervalSince1970:calib_ticks];
    u_int sleep_ticks;         //上次进休眠待机时间
    u_short bp_test_target_pressure; // 血压测试目标打气阈值
    u_char device_switch;      // 蜂鸣器开关 0：关  1：开 bit0:声音 bit1:快速心电
    u_char avg_measure_mode;        //BP2WiFi X3测量档位可设置0-4共5个档 Off/30s/60s/90s/120s（默认关闭）
    u_char volume;                    //语音播报音量，0：关闭
    u_char reserved1[4];  // 国内bp2WiFi userid
    u_char time_utc;  // 设备时区，默认8时区
    u_char reserved2;  // 定制BP2A_Sibel 熄屏开关 0：关，1：开
    u_char reserved3;  // 运行状态
    u_char wifi_4g_switch;    // BP3 WiFi/4G开关,0:关1:开
    u_char unit;    //单位设置。bit0：（血压单位， 0：mmHg，1：KPa。1Kpa = 7.5mmHg）
    u_char reserved4[4];    //预留
};
typedef struct CG_BOXABLE VTMBPConfig VTMBPConfig;

/// @brief calibrate zero.  EqulTo CalibrationZero.
struct
VTMCalibrateZero {
    u_int calib_zero;           //校零adc值（LSB） e.g. 2800<=zero<=12000 128mV~550mV
};
typedef struct CG_BOXABLE VTMCalibrateZero VTMCalibrateZero;

/// @brief calibrate slope. EqulTo CalibrationSlope.
struct
VTMCalibrateSlope {
    u_short calib_pressure;     //用于校准压力值
};
typedef struct CG_BOXABLE VTMCalibrateSlope VTMCalibrateSlope;

/// @brief return of calibrate slope. EqulTo CalibrationSlopeReturn
struct
VTMCalibrateSlopeReturn {
    u_int calib_slope;          //校准斜率值*100    e.g.    13630<=slope<=17040 136.3LSB/mmHg-170.4LSB/mmHg
};
typedef struct CG_BOXABLE VTMCalibrateSlopeReturn VTMCalibrateSlopeReturn;

/// @brief real-time pressure.  EqulTo RealTimePressure
struct
VTMRealTimePressure {
    short pressure;  //实时压（mmHg）*100
};
typedef struct CG_BOXABLE VTMRealTimePressure VTMRealTimePressure;

/// @brief run status. EqulTo RunStatus
struct
VTMBPRunStatus {
    u_char status;                 //主机状态
    VTMBatteryInfo battery;                 //电池信息
    u_char bp_avg_cnt;            //BP2WIFI X3测量有效,测量的索引
    u_char bp_avg_wait_tick;        //BP2WIFI X3测量有效,等待的计时器
    u_char reserved[2];                  //预留
};
typedef struct CG_BOXABLE VTMBPRunStatus VTMBPRunStatus;

/// @brief bp's data in the measuring.  EqulTo  BPMeasuringData
struct
VTMBPMeasuringData {
    u_char is_deflating;            //是否放气 0：否；1：是  （打气后放气）
    short pressure;                 //实时压
    u_char is_get_pulse;            //是否检测到脉搏波 0：否；1：是
    u_short pulse_rate;             //脉率
    u_char is_deflating_2;           //是否在放气状态  0：否 1：是
    u_char reverse[14];             //预留
};
typedef struct CG_BOXABLE VTMBPMeasuringData VTMBPMeasuringData;

/// @brief bp's result at the measure completion. EqulTo BPEndMeasureData.
struct
VTMBPEndMeasureData {
    u_char is_deflating;            //是否放气 0：否；1：是
    short pressure;                 //实时压
    u_short systolic_pressure;      //收缩压
    u_short diastolic_pressure;     //舒张压
    u_short mean_pressure;          //平均圧
    u_short pulse_rate;             //脉率
    u_char state_code;              //状态码
    u_char medical_result;          //诊断结果
    u_char reverse[7];              //预留
};
typedef struct CG_BOXABLE VTMBPEndMeasureData VTMBPEndMeasureData;

/// @brief ecg's data in the measuring. EqulTo ECGMeasuringData.
struct
VTMECGMeasuringData {
    u_int duration;                 //当前测量时长（单位：秒）
    u_int special_status;           // 特殊状态bit0：是否信号弱  bit1：是否导联脱落
    u_short pulse_rate;             // 脉率
    u_char reverse[10];             //预留
};
typedef struct CG_BOXABLE VTMECGMeasuringData VTMECGMeasuringData;

/// @brief ecg's result at the ecg measure completion. EqulTo ECGEndMeasureData.
struct
VTMECGEndMeasureData {
    u_int result;                   //诊断结果
    u_short hr;                     //心率 单位：bpm
    u_short qrs;                    //QRS 单位：ms
    u_short pvcs;                   //PVC个数
    u_short qtc;                    //QTc 单位：ms
    u_char reverse[8];              //预留
};
typedef struct CG_BOXABLE VTMECGEndMeasureData VTMECGEndMeasureData;

/// @brief real-time waveform. EqulTo BPRealTimeWaveform.
struct
VTMBPRealTimeWaveform {
    u_char type;                  //测量类型 1
    u_char data[20];                  //实时数据
    VTMRealTimeWF wav;                 //波形数据
};
typedef struct CG_BOXABLE VTMBPRealTimeWaveform VTMBPRealTimeWaveform;

/// @brief real-time data of bp. EqulTo BPRealTimeData
struct
VTMBPRealTimeData {
    VTMBPRunStatus run_status;
    VTMBPRealTimeWaveform rt_wav; 
};
typedef struct CG_BOXABLE VTMBPRealTimeData VTMBPRealTimeData;

#pragma mark --- BP2W

struct
VTMBPWFileDataHead {
    u_char file_version;            //文件版本 e.g.  0x01 :  V1
    u_char file_type;                //文件类型 1：血压；2：心电
    u_char reserved[8];             //预留
};
typedef struct CG_BOXABLE VTMBPWFileDataHead VTMBPWFileDataHead;

struct
VTMBPWBPResult {
    u_int measuring_timestamp;    //测量时间时间戳 e.g.  0:  1970.01.01 00:00:0时间戳
    int uid;                    //用户id
    u_char mode;                //测量模式 0:单次模式 1:X3模式
    u_char reserved1;                //预留
    u_short measure_interval;        //BP2WIFI测量间隔单位s 仅非单次模式有效
    u_char status_code;            //状态码，后续补充
    u_short systolic_pressure;        //收缩压
    u_short diastolic_pressure;        //舒张压
    u_short mean_pressure;        //平均压
    u_char pulse_rate;            //脉率
    u_char medical_result;        //诊断结果 bit0:心率不齐 bit1:动作干扰
    u_char bp_level;                //血压等级
    u_char reserved2[15];            //预留
};
typedef struct CG_BOXABLE VTMBPWBPResult VTMBPWBPResult;

struct
VTMBPWBPFileData {
    VTMBPWFileDataHead head;
    VTMBPWBPResult list[50];
};
typedef struct CG_BOXABLE VTMBPWBPFileData VTMBPWBPFileData;

struct
VTMBPWECGResult {
    u_int measuring_timestamp;    //测量时间时间戳 e.g.  0:  1970.01.01 00:00:0时间戳
    int uid;                    //用户id
    u_char mode;                //测量模式 预留
    u_char reserved1;            //预留
    u_int recording_time;        //记录时长  35:测量35秒
    u_int result;                //诊断结果，见诊断结果表[诊断结果表]
    u_short hr;                //心率 单位：bpm
    u_short qrs;                //QRS 单位：ms
    u_short pvcs;            //PVC个数
    u_short qtc;                //QTc 单位：ms
    u_char reserved2[20];        //预留
};
typedef struct CG_BOXABLE VTMBPWECGResult VTMBPWECGResult;

struct
VTMBPWECGFileData {
    VTMBPWFileDataHead head;
    VTMBPWECGResult list[10];
};
typedef struct CG_BOXABLE VTMBPWECGFileData VTMBPWECGFileData;

struct
VTMBPWECGWaveFileHead {
    u_char file_version;            //文件版本 e.g.  0x01 :  V1
    u_char file_type;                //文件类型 1：血压；2：心电
    u_int measuring_timestamp;    //测量时间时间戳 e.g.  0:  1970.01.01 00:00:0时间戳
    u_char reserved[4];            //预留
};
typedef struct CG_BOXABLE VTMBPWECGWaveFileHead VTMBPWECGWaveFileHead;

struct
VTMWiFiElement {
    u_char len;
    u_char *str;
};
typedef struct CG_BOXABLE VTMWiFiElement VTMWiFiElement;

struct
VTMWiFiInfo {
    u_char state;        //当前连接状态 0:断开 1:连接中 2:已连接 0xff:密码错误 0xfd:找不到SSID
    VTMWiFiElement ssid;                //ssid
    u_char type;        //wifi类型    0:2.4G   1:5G
    char rssi;            //信号强度    设置时无效
    VTMWiFiElement pwd;                //password
    u_char mac_addr[6];    //wifi模块mac地址
    u_char ip_type;        //ip类型 0动态 1静态
    VTMWiFiElement ip_addr;            //设置时当地址为空时为动态获取ip，获取时返回当前转接器ip信息
    VTMWiFiElement netmask_addr;        //子网掩码
    VTMWiFiElement gateway_addr;        //网关
};
typedef struct CG_BOXABLE VTMWiFiInfo VTMWiFiInfo;

struct
VTMServerInfo {                //服务器信息
    u_char state;        //当前连接状态 0:断开 1:连接中 2:已连接 0xff:服务器无法连接
    u_char server_addr_type;    //服务器地址类型  0:ipv4  1:域名形式
    VTMWiFiElement server_addr;        //服务器地址 e.g. “192.168.1.33”
    u_short server_port;    //服务器端口号
};
typedef struct CG_BOXABLE VTMServerInfo VTMServerInfo;

struct
VTMWiFiConfig {
    u_char option;        //对应接收到的option bit0:wifi配置有效 bit1:server配置有效 bit2:device配置有效
    VTMWiFiInfo wifi;
    VTMServerInfo server;
};
typedef struct CG_BOXABLE VTMWiFiConfig VTMWiFiConfig;


struct
VTMBPUserInfoHead {
    u_char file_version;        //文件版本 e.g.  0x01 :  V1
    u_char file_type;            //文件类型 固定0x0
    u_char reserved[8];        //预留
};
typedef struct CG_BOXABLE VTMBPUserInfoHead VTMBPUserInfoHead;

struct
VTMBitMap {
    u_char typed;        //BMP格式 0:1位
    u_short size_w;        //宽
    u_short size_h;        //高
    u_short data_length;    //图标内容数据长度
    u_char *data;//[data_length];
};
typedef struct CG_BOXABLE VTMBitMap VTMBitMap;

struct
VTMBPUserInfo {
    u_short info_length;        //用户信息长度
    u_int AID;                //主账号唯一码 account id
    int UID;                //用户唯一码    ， 0为guest默认账户
    u_char fname[32];            //姓        utf8格式
    u_char name[32];            //名        utf8格式
    u_int birthdate;            //0x19970505 代表生日为1997年5月5日
    u_short hight;                //身高        0.1cm
    u_short weight;                //体重
    u_char gender;                //性别 0男 1女
    u_char reserved[11];            //预留
    VTMBitMap bitMap;                //用户图标，BP2用于显示姓名
};
typedef struct CG_BOXABLE VTMBPUserInfo VTMBPUserInfo;


#pragma mark --- BP3


// 不同type的值对应不同的Data结构体（固定20个字节）
// Type = 0:（血压测量中）
struct
VTMBP3RealDataType0 {
    unsigned char  is_deflating;     //是否放气 0：否；1：是
    short pressure;  //实时压（mmHg）*100
    unsigned char  is_get_pulse;   //是否检测到脉搏信号 0：否；1：是
    unsigned short pulse_rate;       //脉率
    unsigned char  reserved[14];      //预留
} ;
typedef struct CG_BOXABLE VTMBP3RealDataType0 VTMBP3RealDataType0;

// Type = 1:（血压测量结束）
struct
VTMBP3RealDataType1 {
    unsigned char  is_deflating;     //是否放气 0：否；1：是
    short pressure;  //实时压
    unsigned short systolic_pressure;    //收缩压
    unsigned short diastolic_pressure;  //舒张压
    unsigned short mean_pressure;       //平均压
    unsigned short pulse_rate;       //脉率
    unsigned char  state_code;      //状态码（见下方血压测量状态码释义）
    unsigned char  medical_result;       //诊断结果 bit0:心率不齐
    unsigned char  reserved[7];//预留
};
typedef struct CG_BOXABLE VTMBP3RealDataType1 VTMBP3RealDataType1;

// Type = 2:（心电测量中）
struct
VTMBP3RealDataType2 {
    unsigned int     duration;  //当前测量时长（单位：秒）
    unsigned int     special_status; //特殊状态 bit0:是否信号弱，bit1:是否导联脱落
    unsigned short hr_rate;       //心率
    unsigned char  reserved[10];      //预留
} ;
typedef struct CG_BOXABLE VTMBP3RealDataType2 VTMBP3RealDataType2;

// Type = 3:（心电测量结束）
struct
VTMBP3RealDataType3 {
    unsigned int    result;       //诊断结果（见下方心电测量状态码释义）
    unsigned short hr;     //心率 单位：bpm
    unsigned short qrs;   //QRS 单位：ms
    unsigned short pvcs; //PVC个数
    unsigned short qtc;   //QTc 单位：ms
    unsigned char  reserved[8];//预留
} ;
typedef struct CG_BOXABLE VTMBP3RealDataType3 VTMBP3RealDataType3;

// Type = 4:（血压心电测量中）
struct
VTMBP3RealDataType4 {
    unsigned char  is_deflating;     //是否放气 0：否；1：是
    short pressure;  //实时压
    unsigned char  is_get_pulse;   //是否检测到脉搏信号 0：否；1：是
    unsigned short pulse_rate;       //脉率
    unsigned int     duration;  //当前测量时长（单位：秒）
    unsigned int     special_status; //特殊状态 bit0:是否信号弱，bit1:是否导联脱落
    unsigned short hr_rate;       //心率
    unsigned char  reserved[4];      //预留
} ;
typedef struct CG_BOXABLE VTMBP3RealDataType4 VTMBP3RealDataType4;



struct
VTMBP3AlarmItem{
    unsigned char week_repeat;  // week repeat bit set, week_repeat_enum
    unsigned char hour;
    unsigned char min;
    unsigned char reserved;     // 预留
};
typedef struct CG_BOXABLE VTMBP3AlarmItem VTMBP3AlarmItem;


struct
VTMBP3AlarmInfo{
    unsigned char status;    // 0: 关闭，1:打开
    unsigned char items;     // items number, max 5
    VTMBP3AlarmItem* info;  // items info , maybe has much more
};
typedef struct CG_BOXABLE VTMBP3AlarmInfo VTMBP3AlarmInfo;

struct 
VTMBP3BPResult {
    VTMBPWBPResult result;
    u_char pulse_flag;
};
typedef struct CG_BOXABLE VTMBP3BPResult VTMBP3BPResult;

struct
VTMBP3FileData {
    VTMBPWFileDataHead head;
    VTMBP3BPResult list[50];
};
typedef struct CG_BOXABLE VTMBP3FileData VTMBP3FileData;

struct
VTMBP3ECGFileData {
    VTMBPWFileDataHead head;
    VTMBPWECGResult list[20];
};
typedef struct CG_BOXABLE VTMBP3ECGFileData VTMBP3ECGFileData;


#pragma mark --- Scale 1
/// @brief run parameters of s1. EqulTo DeviceRunParameters of s1
struct
VTMScaleRunParams {
    u_char run_status;    //运行状态  0:待机 1:秤端测量中 2:秤端测量结束 3:心电准备阶段 4:心电测量中 5:心电正常结束 6:带阻抗心电异常结束  7:不带阻抗异常结束
    u_short hr;                //当前主机实时心率 bpm 30-250有效
    u_int record_time;        //已记录时长    单位:second
    u_char lead_status;        //导联状态  0:导联off  1:导联on
    u_char reserved[8];        //预留
};
typedef struct CG_BOXABLE VTMScaleRunParams VTMScaleRunParams;

/// @brief data of s1. EqulTo ScaleData.
struct
VTMScaleData {
    u_char subtype;            //固定 0x1A
    u_char vendor;            //固定0x41
    /*测量标识
     1. 对于体脂称： 纯体重数据： 0xA0， 带阻值数据： 0xAA
     2. 对于体重秤： 实时数据： 0xB0， 定格数据： 0xBB（根据
     不同测量阶段修改，当数据从定格数据变为实时数据视为重新上秤测量）
     */
    u_char measure_mark;
    u_char precision_uint;
    //bit0-3:单位 0:kg, 1:LB, 2:ST, 3:LB-ST, 4:斤
    //bit4-7:精度 表示后面的重量被放大了10^n
    u_short weight;        //重量 单位:KG    大端模式
    u_int resistance;       //阻值 单位:Ω    大端模式
    u_char crc;            //0-9 所有字节的异或校验
};
typedef struct CG_BOXABLE VTMScaleData VTMScaleData;

/// @brief real-time data of s1. EqulTo RealTimeData of s1
struct
VTMScaleRealData {
    VTMScaleRunParams run_para;
    VTMScaleData scale_data;
    VTMRealTimeWF waveform; 
};
typedef struct CG_BOXABLE VTMScaleRealData VTMScaleRealData;

/// @brief file head of scale.
struct
VTMScaleFileHead {
    u_char file_version;
    u_char file_type;
    u_char reserved[8];
};
typedef struct CG_BOXABLE VTMScaleFileHead VTMScaleFileHead;

/// @brief ecg result of scale.
struct
VTMScaleEcgResult {
    u_int recording_time;    //记录时长
    u_char reserved[2];        //预留
    u_int result;            //诊断结果，见诊断结果表
    u_short hr;                //心率 单位：bpm
    u_short qrs;                //QRS 单位：ms
    u_short pvcs;            //PVC个数
    u_short qtc;                //QTc 单位：ms
    u_char reserved2[20];        //预留
};
typedef struct CG_BOXABLE VTMScaleEcgResult VTMScaleEcgResult;

/// @brief scale.dat file.
struct
VTMScaleFileData {
    u_char record_valid; //数据有效标记，当对应位置位时数据才存在  bit0:秤端  bit1:心电
    VTMScaleData scale_data;   //秤端定格数据
    VTMScaleEcgResult ecg_result; //ecg分析结果
    short ecg_data[3750]; ////30s 125Hz心电波形数据
};
typedef struct CG_BOXABLE VTMScaleFileData VTMScaleFileData;

//MARK: ER3

/// @brief config of er3. EqulTo Configuartion of ER3.
typedef struct {
    unsigned char ecg_mode;      ///< 心电测量模式 0：监护模式，1：手术模式，2：ST模式
} CG_BOXABLE VTMER3Config;

/// @brief er3. BoxGetData
typedef struct {
    uint32_t first_index;       ///< 上次接受的数据起始点，首包赋值0
} CG_BOXABLE VTMER3BoxGetData;

typedef struct {
    unsigned short year;
    unsigned char mon;
    unsigned char day;
    unsigned char hour;
    unsigned char min;
    unsigned char sec;
} CG_BOXABLE VTMER3UTCTime;



/// 电极转换为对应的导联状态
typedef union {
    struct {
        unsigned char I: 1;         // LA电极脱落
        unsigned char II: 1;        // LL电极脱落
        unsigned char III: 1;       // I or II 脱落就脱落
        unsigned char aVR: 1;       // I or II 脱落就脱落
        unsigned char aVL: 1;       // I or II 脱落就脱落
        unsigned char aVF: 1;       // I or II 脱落就脱落
        unsigned char V1: 1;        // V1电极脱落
        unsigned char V2: 1;        // V2电极脱落
        unsigned char V3: 1;        // V3电极脱落
        unsigned char V4: 1;        // V4电极脱落
        unsigned char V5: 1;        // V5电极脱落
        unsigned char V6: 1;        // V6电极脱落
        unsigned char reserved: 4;
    } lead;
    unsigned short value;
} VTMER3LeadState;

/// 设备返回电极状态
typedef union {
    struct {
        unsigned char RA: 1;    // RA 电极脱落
        unsigned char LA: 1;    // LA 电极脱落
        unsigned char LL: 1;    // LL 电极脱落
        unsigned char RL: 1;    // LL 电极脱落
        unsigned char V1: 1;    // V1电极脱落
        unsigned char V2: 1;    // V2电极脱落
        unsigned char V3: 1;    // V3电极脱落
        unsigned char V4: 1;    // V4电极脱落
        unsigned char V5: 1;    // V5电极脱落
        unsigned char V6: 1;    // V6电极脱落
    } electrodes;
    unsigned short value;
} VTMER3ElectrodesState;

/// @brief er3. RealTimeParameters
typedef  struct {
    unsigned char run_status;           ///< 运行状态 0：空闲，1：检测导联，2：测量准备，3：记录中
    VTMER3UTCTime start_time;           ///< 测量开始时间
    unsigned int record_time;           ///< 已记录时长 单位：second
    unsigned char battery_state;        ///< 电池状态 0：正常使用，1：充电中，2：充满，3：低电量
    unsigned char battery_percent;      ///< 电池电量 e.g. 100: 100%
    unsigned char reserved[6];          ///< 预留
    // 心电
    unsigned char ecg_cable_state;      ///< 线缆状态
    VTMER3Cable cable_type;             ///< 线缆类型
    unsigned short electrodes_state;    ///< 电极状态 bit0-9 RA LA LL RL V1 V2 V3 V4 V5 V6     (0:ON  1:OFF)
    unsigned short ecg_hr;              ///< 心率
    unsigned char ecg_flag;             ///< 实时运行标记 bit0：R波标识
    unsigned char ecg_resp_rate;        ///< 呼吸率
    // 血氧
    unsigned char oxi_probe_state;      ///< 探头状态 0:未插入 1：正常 2：手指脱落 3：探头故障
    unsigned char oxi_spo2;             ///< 血氧
    unsigned short oxi_pr;              ///< 脉率
    unsigned char oxi_pi;               ///< 灌注 0- 200 e.g. 25 : PI = 2.5
    unsigned char oxi_flag;             ///< 实时运行标记 bit0:R波标记
    unsigned char oxi_reserved[2];      ///< 预留
    // 血氧
    unsigned char temp_probe_state;     ///< 探头状态 0:未插入 1：正常
    unsigned short temp_val;            ///< 体温 无效值0xFFFF e.g. 2500 temp = 25.0℃
    // 其他
    unsigned char temp_reserved[1];     ///< 预留
} CG_BOXABLE VTMER3RunParams;

/// @brief er3. RealTimeWavefrom
typedef struct {
    unsigned char wave_info;        ///< bit0~bit3：采样率 0：250HZ，1:125HZ，2:62.5HZ。 bit4~bit7 压缩类型 0：未压缩，1：Viatom 差分压缩
    unsigned char reserved[3];      ///< 预留
    unsigned int offset;            ///< 相对起始测量时间的采样点偏移
    unsigned short sampling_num;    ///< 采样点数
    //short wave_data[2600];      ///< 原始数据 压缩后
} CG_BOXABLE VTMER3Waveform;

/// @brief er3. RealTimeData_2
typedef struct {
    VTMER3RunParams run_params; ///< 运行参数
    VTMER3Waveform waveform;    ///< 波形数据
} CG_BOXABLE VTMER3RealTimeData;


/// @brief file tail of er3. EqulTo FileHead_t of er3.
typedef struct {
    u_char file_version;    ///< 文件版本 e.g.  0x01 :  V1
    u_char type;            ///< 文件类型 数据文件：固定为0x04
    u_char cable_type;      ///< 线缆类型 数据文件：无效数据    波形文件：线缆类型
    u_char reserved[7];     ///< 预留
} CG_BOXABLE VTMER3FileHead;

/// @brief file tail of er3. EqulTo FileTail_t of er3.
typedef struct {
    u_int recoring_time;    ///< 记录时长，e.g 3600: 3600s
    u_short data_crc;       ///< 文件头部+原始波形和校验
    u_char reserved[10];    ///< 预留
    u_int magic;            ///< 文件标识 固定值为 0xA55A0438
} CG_BOXABLE VTMER3FileTail;

/// @brief point. EqulTo Data_t
typedef struct {
    uint16_t heartReate;    ///< 心率
    uint16_t temperature;   ///< 体温
    uint8_t spO2;           ///< 血压
    uint16_t pulseRate;     ///< 脉率
    uint16_t respRate;      ///< 呼吸率
    uint8_t reserved[1];    ///< 预留
} CG_BOXABLE VTMER3PointData;

typedef struct {
    uint8_t ISO;            ///< 导联是欧标 0x01显示欧标 否则 显示美标
    uint8_t logo;           ///< 开机页面 0x00 中性 0x01：LePu Medical 0x02:Wellue
    uint8_t reserved[18];   ///< 预留
} CG_BOXABLE VTMER3ConfigParams;

typedef struct {
    u_int event_tag_index;      // 测量时标记当前点数
    u_short event_tag_type;     // 事件类型
    u_char reserved[10];        // 预留
} CG_BOXABLE VTMEREventLog;

// MARK: O2Ring II struct
typedef struct {
    u_char remind_switch;   // 提醒开关  bit0-bit3:血氧提醒开关  bit4-bit7:心率提醒开关   bit0/bit4震动  bit1/bit5声音  其他预留
    u_char spo2_thr;        // 血氧阈值80-95% 步进%1 默认 88%
    u_char hr_thr_low;      // 心率提醒低阈值 30-70 步进5 默认 50
    u_char hr_thr_high;     // 心率提醒高阈值 70-200 步进5 默认 120
    u_char motor;           // 震动强(震动强度不随开关的改变而改变) KidsO2(5/10/17/22/35) Oxylink(5/10/17/22/35)  O2Ring(20/40/60/80/100)
    u_char buzzer;          // 声音强度 (O2M：最低：20，低:40，中：60，高：80，最高：100)
    u_char display_mode;    // 显示模式 0:Standard模式 2:Always On模式
    u_char brightness;      // 屏幕亮度    0：低 1：中 2：高
    u_char interval;        // 存储间隔 单位S
    u_char timezone;        // 时区 默认80
    u_char reserved[30];    // 预留
} CG_BOXABLE VTMWOxiInfo;

/**
 typedef struct{
     unsigned char val;  //血氧提醒开关 bit0:震动 bit1:声音
     char reserved[3];
 } SpO2SwitchSetting
 typedef struct
 {
   unsigned char val;  //血氧阈值
   char reserved[3];
 }SpO2Thr Setting;
 typedef struct
 {
     unsigned char val;  //心率提醒开关 bit0:震动 bit1:声音
     char reserved[3];
 } HRSwitchSetting
 typedef struct
 {
     unsigned char val;  //心率提醒低阈值
     char reserved[3];
 } HRThrLowSetting
 typedef struct
 {
     unsigned char val;  //心率提醒高阈值
     char reserved[3];
 } HRThrHighSetting
 typedef struct
 {
     unsigned char val;  //震动强(震动强度不随开关的改变而改变)
 KidsO2(5/10/17/22/35) Oxylink(5/10/17/22/35)  O2Ring(20/40/60/80/100)
     char reserved[3];
 } MotorSetting
 typedef struct
 {
     unsigned char val;  //声音强度 (checkO2Plus：最低：20，低:40，中：60，高：80，最高：100)
     char reserved[3];
 } BuzzerSetting
 typedef struct
 {
     unsigned char val;  //显示模式 0:Standard模式 1:Always Off模式2:Always On模式
     char reserved[3];
 } DisplayModeSetting
 typedef struct
 {
     unsigned char val;  //屏幕亮度
     char reserved[3];
 } BrightnessSetting
 typedef struct
 {
     unsigned char val;  //存储间隔
     char reserved[3];
 } IntervalSetting
 */
typedef struct {
    u_char val;             // 参考文档
    char reserved[3];
} CG_BOXABLE VTMOxiParam;



typedef struct {
    u_char type;            // 见 `VTMWOxiSetParams`
    char reserved[3];
    VTMOxiParam param;        // 每个设置项占4个字节，与type相对应
} CG_BOXABLE VTMOxiParamsOption;


typedef struct {
    u_int record_time;      // 已记录时长    单位:second    暂无使用
    u_char run_status;      // 运行状态 0:准备阶段 1:测量准备阶段 2:测量中 3:测量结束
    u_char sensor_state;    // 传感器状态 0:正常状态 1:未放手指 2:SENSOR_STA_PROBE_OUT 3: 传感器或探头故障
    u_char spo2;
    u_char pi;              // PI值*10 e.g.  15 : PI = 1.5
    u_short pr;
    u_char flag;            // 标志参数 bit0:脉搏音标志
    u_char motion;
    u_char battery_state;   // 电池状态 e.g.   0:正常使用 1:充电中 2:充满 3:低电量
    u_char battery_percent; // 电池状态 e.g.    电池电量百分比
    u_char reserved[6];
} CG_BOXABLE VTMWOxiRunParams;

typedef struct {
    u_int index;            //波形数据第一个点相对于起始点的编号 暂无使用
    u_short sampling_num;   //波形数据采样点
    u_char *waveform_data;  //波形数据
} CG_BOXABLE VTMWOxiRealWave;

typedef struct {
    VTMWOxiRunParams run_para;
    VTMWOxiRealWave waveform;
} CG_BOXABLE VTMWOxiRealData;

typedef struct {
    u_char marker;          // 原始数据标识 不能为0 bit0:IR红外 bit1:RED红光 bit2:motion三轴
    u_char sample_rate;     // 原始数据采样率  0:150HZ 1:200HZ
} CG_BOXABLE VTMWOxiRawSampleInfo;

typedef struct {
    int ir;                 // 当marker bit0=1时有效
    int red;                // 当marker bit1=1时有效
    u_char motion;          // 当marker bit2=1时有效
} CG_BOXABLE VTMWOxiRawDataUint;

typedef struct {
    u_short sampling_num;
    VTMWOxiRawDataUint *raw_data;
} CG_BOXABLE VTMWOxiRawData;


typedef struct {
    u_short asleep_time;
    u_char average_spo2;
    u_char lowest_spo2;
    u_char percent3_drops;
    u_char percent4_drops;
    u_char t90;
    u_short _90percent_time;
    u_char _90percent_drops;
    u_char o2_score;
    u_int step_counter;
    u_char average_pr;
} CG_BOXABLE VTMWOxiResult;



// MARK: PF-10

typedef struct {
    u_char spo2Low;         // 血氧阈值 85%-99% 步进：1%
    u_char prHigh;          // 脉搏高阈值 100bpm-240bpm；步进：5bpm
    u_char prLow;           // 脉搏低阈值  30bpm-60bpm；步进：5bpm
    u_char alramIsOn;       // 阈值提醒开关 0:关 1：开
    u_char measureMode;     // 测量模式 1：点测 2：连续（预留）
    u_char beepIsOn;        // 蜂鸣器开关  0:关 1：开
    u_char language;        // 语言包 0:英文 1：中文
    u_char bleIsOn;         // 蓝牙开关 0:关 1：开（预留）
    u_char esmode;          // 测量过程，定时息屏
    u_char reserved[8];
} CG_BOXABLE VTMFOxiConfig;

/**
 typedef struct{
     unsigned char val;  //血氧提醒阈值 85%-99% 步进：1%
     char reserved[3];
 } SpO2LoSetting

 typedef struct{
     unsigned char val;  //脉搏高阈值
     char reserved[3];
 } PrHiSetting

 typedef struct{
     unsigned char val;  //脉搏低阈值
     char reserved[3];
 } PrLoSetting

 typedef struct{
     unsigned char val;  //闹钟开关
     char reserved[3];
 } AlramSetting

 typedef struct{
     unsigned char val;  //测量模式
     char reserved[3];
 } MeasureModeSetting

 typedef struct{
     unsigned char val;  //蜂鸣器开关
     char reserved[3];
 } BeepSetting

 typedef struct{
     unsigned char val;  //语言包
     char reserved[3];
 } LanguageSetting

 typedef struct{
     unsigned char val;  //蓝牙开关
     char reserved[3];
 } BleSwitchSetting

 typedef struct{
     unsigned char val;  //测量过程，定时息屏
     char reserved[3];
 } EsModeSetting
 */

typedef struct {
    u_char spo2;            // 氧数据。范围为0%~100%；0代表无效值。
    u_char pr;              // 脉率数据。范围0~250bpm。0代表无效值。
    u_char pi;              //（血流灌注指数）数据。范围0%~25.5%；0代表无效值
    u_char status;          // 血氧状态信息。Bit1:Probe off（探头脱落、手指未插入）
    u_char res;             // bit6~bit7：电池电量等级，0， 1， 2， 3共4级。
} CG_BOXABLE VTMFOxiMeasureInfo;

typedef struct {
    u_char wavedata[5];        // Bit 0~6 波形数据     Bit 7 脉搏搏动标志  0无搏动 1 有搏动
} CG_BOXABLE VTMFOxiMeasureWave;

typedef struct {
    u_char mode;            // 当前模式 0x01: spot check 0x02:  continuous 0x03: menu
    u_char stage;           // mode = 0x01: 0x00 idle  0x01 prepare 0x02 measuring 0x03 oxi result 0x04 PR result; mode = 0x02: 0x00 prepare 0x01 measuring 0x02 finished 0x03 <2mins 0x03 enter menu
    u_char param1;          // mode = 0x01: 0x02 countdown 30sec 0x03 oxygen val 0x04 PR result code; mode = 0x02: 0x01 record time
    u_char param2;          // mode = 0x01: 0x04 PR val ;  mode = 0x02: 0x01 record time
} CG_BOXABLE VTMFOxiWorkStatus;

// MARK: Oximeter file

typedef struct {
    u_char file_version;
    u_char file_type;       // Oxi  0x03
    u_char reserved[6];
    u_short device_model;
} CG_BOXABLE VTMOxiFileHead;

typedef struct {
    u_char spo2;
    u_char pr;
    u_char motion;
    u_char spo2_mark;
    u_char pr_mark;
} CG_BOXABLE VTMOxiPoint;

typedef struct {
    u_int check_sum;
    u_int magic;                    // 0xDA5A1248
    u_int timestamp;                // since 1970.01.01 00:00:00
    u_int records;                  // number of points
    u_char interval;
    u_char channel_type;
    u_char channel_bytes;
    u_char reserved[13];
    VTMWOxiResult result;           // Wearable Oximeter
} CG_BOXABLE VTMOxiFileTail;


// MARK: Baby


typedef struct {
    u_char alarm_led;               // 指示灯报警开关 bit0:踢被警告 bit1:温度报警 bit2:呼吸率报警 bit3:姿态报警 其他预留
    u_char alarm_beep;              // 声音报警开关 bit0:踢被警告 bit1:温度报警 bit2:呼吸率报警 bit3:姿态报警 其他预留
    u_char alarm_wait;              // 报警等待 bit0:踢被警告 bit1:温度报警 bit2:呼吸率报警 bit3:姿态报警
    u_char temp_thr_low;            // 温度报警低阈值。范围[15,36],单位：℃，步进:1℃，下限不可高于上限
    u_char temp_thr_high;           // 温度报警高阈值。范围[15,36],单位：℃，步进:1℃，上限不可低于下限
    u_char rr_thr_low;              // 呼吸率报警低阈值。范围[0,70],单位：次/每分钟，步进:1，下限不可高于上限
    u_char rr_thr_high;             // 呼吸率报警高阈值。范围[0,70],单位：次/每分钟，步进:1，上限不可低于下限
    u_char alarm_sensitivity;       // 报警灵敏度，范围[1,3]
    u_char wear_led_work_time;      // 佩戴指示灯工作时间，单位：分钟。0为一直工作, 1是关闭
    u_char reserved[31];
} CG_BOXABLE VTMBabyConfig;

/*
 typedef struct {
 unsigned char type;    //见SystemSettingEnum
 char reserved[3];
 char setting[4];    //每个设置项占4个字节，与type相对应
 } SystemOption

 typedef struct{
 unsigned char val;  //指示灯提醒开关 bit0:踢被 bit1:温度 bit2:呼吸率 bit3:趴睡
 char reserved[3];
 } LampSwitch
 typedef struct{
 unsigned char val;  //声音提醒开关 bit0:踢被 bit1:温度 bit2:呼吸率 bit3:趴睡
 char reserved[3];
 } BeepSwitch
 typedef struct{
 unsigned char val;  //通知提醒开关 bit0:踢被 bit1:温度 bit2:呼吸率 bit3:趴睡
 char reserved[3];
 } RemindSwitch
 typedef struct{
 unsigned char low;  //温度低阈值
 char reserved[3];
 } TempLow
 typedef struct{
 unsigned char high;  //温度高阈值
 char reserved[3];
 } TempHigh
 typedef struct{
 unsigned char low;  //呼吸率低阈值
 char reserved[3];
 } RrLow
 typedef struct{
 unsigned char high;  //呼吸率高阈值
 char reserved[3];
 } RrHigh
 typedef struct{
 unsigned char sensitive;  //报警灵敏度
 char reserved[3];
 } WarningSensitive
 typedef struct{
 unsigned char time;  //指示灯工作时间
 char reserved[3];
 } LampWorkTime
 */

typedef struct {
    u_int record_time;                  // 已记录时长    单位:second    暂无使用
    u_char run_status;                  // 运行状态,见系统运行状态
    VTMGyrosStatus attitude_status;     // 姿态(1Byte),见姿态类型 注：俯卧和坐起会报警
    u_char wear_status;                 // 脱落标识，0：未脱落  1：脱落
    u_char rr;                          // 当前呼吸率，范围[0,255]
    u_char alarm_type_rr;               // 呼吸报警类型(1Byte)，0：正常  1：报警
    short cur_temperature;              // 当前温度，单位：摄氏度,范围[-32767,32767]。数据为*10的结果,
    VTMTempAlerm alarm_type_temp;       // 温度报警类型(1Byte)，见温度报警类型
    VTMBatteryInfo batInfo;             // 电量信息
    u_char reserved[4];
} CG_BOXABLE VTMBabyRunParams;


typedef struct {
    float Pitch;                        // 俯仰角
    float Roll;                         // 翻滚角
    float Yaw;                          // 偏航角
    VTMGyrosStatus gesture;             // 姿势类型 (1Byte)
    uint8_t RR;                         // 呼吸率
} CG_BOXABLE VTMBabyAttRes;
 
typedef struct {
    int16_t acc_x;
    int16_t acc_y;
    int16_t acc_z;
    int16_t g_x;
    int16_t g_y;
    int16_t g_z;
    VTMBabyAttRes alg_result;
} VTMBabyAtt;




#pragma pack()


#endif /* VTMBLEStruct_h */
