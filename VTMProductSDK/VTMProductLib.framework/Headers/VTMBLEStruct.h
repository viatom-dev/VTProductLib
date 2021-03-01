//
//  VTMBLEStruct.h
//  VTMProductDemo
//
//  Created by viatom on 2020/10/26.
//

#ifndef VTMBLEStruct_h
#define VTMBLEStruct_h

#include <CoreGraphics/CGBase.h>

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
    u_char burn_flag; //烧录标记    e.g. bit0:SN  bit1:硬件版本  bit2:Branch Code
    u_char hw_version; //硬件版本    ‘A’-‘Z’
    u_char branch_code[8]; //Branch编码
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

/// @brief start read and open the file system of viatom's device. EqulTo FileReadStart.
struct
VTMOpenFile {
    u_char file_name[16]; //支持15个字符长度文件名
    u_int file_offset; //文件偏移,用于断点续传
};
typedef struct CG_BOXABLE VTMOpenFile VTMOpenFile;

/// @brief Read the file at the specified offset.  EqulTo FileRead.
struct
VTMReadFile {
    unsigned addr_offset;
};
typedef struct CG_BOXABLE VTMReadFile VTMReadFile;

/// @brief information of viatom's device
struct
VTMDeviceInfo {
    u_char hw_version; //hardware version           e.g. ‘A’ : A
    u_int  fw_version; //firmware version           e.g. 0x010100 : V1.1.0
    u_int  bl_version; //bootloader version         e.g. 0x010100 : V1.1.0
    u_char branch_code[8]; // brach code            e.g. “40020000” : Ezcardio Plus
    u_char reserved0[3]; // reserved
    u_short device_type; // device type             e.g. 0x8611: sphygmometer
    u_short protocol_version; //protocol version    e.g.0x0100:V1.0
    u_char cur_time[7]; // date                     e.g.0xE1070301090000:2017-03-01 09:00:00
    u_short protocol_data_max_len; // Max length that protocol support
    u_char reserved1[4]; //reserved
    VTMSN sn;
    u_char reserved2[1]; //reserved
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
    u_char file_name[16]; //支持14个字符长度文件名
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
    u_short hr;                    //当前主机实时心率 bpm
    u_char sys_flag;                // bit0:R波标记(主机缓存有R波标记200ms)  bit6-7:电池状态(0:正常使用 1:充电中 2:充满 3:低电量)  bit3:导联状态(0:OFF  1:ON)
    u_char percent;                 //电池状态 e.g.    100:100%
    u_int record_time;            //已记录时长    单位:second
    u_char run_status;             //  运行状态
    u_char reserved[11];            //预留
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
/// @brief config of er1. EqulTo Configuartion of ER1.
struct
VTMER1Config {
    u_char vibeSw;  // 配置开关
    u_char hrTarget1;     //  下限
    u_char hrTarget2;  // 上限
};
typedef struct CG_BOXABLE VTMER1Config VTMER1Config;

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

#pragma mark --- BP2/BP2A
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
    u_char device_switch;      // 蜂鸣器开关 0：关  1：开
    u_char reserved[15];        //预留
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
    u_char reserved[4];                  //预留
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

#pragma pack()


#endif /* VTMBLEStruct_h */
