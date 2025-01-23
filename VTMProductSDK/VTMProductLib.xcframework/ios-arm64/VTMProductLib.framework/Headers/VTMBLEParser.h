//
//  VTMBLEParser.h
//  VTMProductDemo
//
//  Created by viatom on 2020/10/29.
//

#import <Foundation/Foundation.h>
#import "VTMBLEStruct.h"

NS_ASSUME_NONNULL_BEGIN

/// @brief support for all viatom devices.
@interface VTMBLEParser : NSObject

+ (VTMDeviceInfo)parseDeviceInfo:(NSData *)data;

+ (VTMBatteryInfo)parseBatteryInfo:(NSData *)data;

//+ (VTMTemperature)parseTemperature:(NSData *)data;

+ (VTMFileList)parseFileList:(NSData *)data;

+ (VTMOpenFileReturn)parseFileLength:(NSData *)data;

+ (VTMFileData)parseFileData:(NSData *)data;

//+ (VTMUserList)parseUserList:(NSData *)data;

@end

@interface VTMBLEParser (ECG)


+ (float)mVFromShort:(short)n;

+ (VTMRunStatus)parseStatus:(u_char)status;

+ (VTMFlagDetail)parseFlag:(u_char)flag;

+ (VTMRealTimeWF)parseRealTimeWaveform:(NSData *)data;

+ (VTMRealTimeData)parseRealTimeData:(NSData *)data;



#pragma mark -- Wave

+ (NSData *)pointDataFromOriginalData:(NSData *)data;
#pragma mark --- ER1/DuoEK/ER2

+ (NSData *)parseWaveData:(NSData *)pointData;

+ (NSArray *)parsePoints:(NSData *)pointData;

+ (NSArray *)parseOrignalPoints:(NSData *)pointData;

+ (void)parseEventData:(NSData *)data result:(void(^)(VTMFileHead head, NSUInteger count,  VTMEREventLog * _Nullable logs))finished;

#pragma mark --- Besides DuoEK's a-file
+ (void)parseWaveHeadAndTail:(NSData *)data result:(void(^)(VTMFileHead head, VTMER2FileTail tail))finished;
#pragma mark --- DuoEK a-file
+ (void)parseFileA:(NSData *)data result:(void(^)(VTMDuoEKFileAHead head, VTMDuoEKFileAResult * results))finished;

#pragma mark --- VBeat

+ (NSArray *)parseVBeatWaveData:(NSData *)waveData ;

+ (void)parseVBeatData:(NSData *)originalData completion:(void(^)(VTMER1PointData *points, int len))completion;


#pragma mark -- config
#pragma mark --- ER1/VBeat

+ (VTMER1Config)parseER1Config:(NSData *)data;

+ (VTMER1NewConfig)parseER1NewConfig:(NSData *)data;

#pragma mark --- ER2/DuoEK

+ (VTMER2Config)parseER2Config:(NSData *)data;

//MARK: - ER3

+ (VTMER3Config)parseER3Config:(NSData *)data;

+ (VTMER3RealTimeData)parseER3RealTimeData:(NSData *)data;

+ (CGFloat)er3MvFromShort:(short)n;

/// 解析配置参数
+ (VTMER3ConfigParams)parseER3ConfigParams:(NSData *)data;


/// 解压实时波形数据
/// @param data 波形数据
/// @param cable 导联类型
+ (NSData *)parseER3WaveData:(NSData *)data withCable:(VTMER3Cable)cable;

/// 解压原始文件数据
/// @param fileData 原始文件数据
/// @param head 文件头
/// @param fragment 解压后数据片段
/// @param tail 文件尾
+ (void)parseER3OriginFile:(NSData *)fileData head:(void(^)(VTMER3FileHead head))head fragment:(void(^)(NSData *subData))fragment tail:(void(^)(VTMER3FileTail tail))tail;

/// ER3解压原始文件数据
/// @param fileData 原始文件
/// @param leadFragments 12组对应导联的数据，根本不同导线线，一些导联data为空
+ (void)parseER3OriginFile:(NSData *)fileData head:(void(^)(VTMER3FileHead head))tailBlock leadFragments:(void(^)(NSArray<NSData *> *leadDatas))leadFragments tail:(void(^)(VTMER3FileTail tail))tailBlock;

/// 解析实时波形数据，返回12组波形数据
/// - Parameters:
///   - waveData: 波形数据
///   - cable: 线缆类型
///   - state: 电极状态
+ (NSArray<NSArray *> *)parseER3RealWaveData:(NSData *)waveData withCable:(VTMER3Cable)cable andState:(uint16_t)state;


/// 电极脱落状态 -> 导联信号状态
/// - Parameters:
///   - cable: 线缆类型
///   - state: 电极状态
+ (VTMER3LeadState)parseCable:(VTMER3Cable)cable state:(uint16_t)state;
        
/// 显示的导联标题
/// - Parameter cable: 线缆类型
+ (NSArray<NSString *> *)showTitlesWithCable:(VTMER3Cable)cable;

/// 显示的导联类型 与标题对应
/// - Parameter cable: 线缆类型
+ (NSArray<NSNumber *> *)showTypesWithCable:(VTMER3Cable)cable;


+ (NSString *)titleWithCable:(VTMER3Cable)cable showLeadState:(VTMER3ShowLead)showLead;

/// 解析事件文件数据
+ (void)parseER3EventData:(NSData *)data result:(void(^)(VTMER3FileHead head, VTMER3FileTail tail, NSUInteger count,  VTMEREventLog * _Nullable logs))finished;

@end

@interface VTMBLEParser (BP)

+ (float)bpMvFromShort:(short)n;

+ (VTMRealTimePressure)parseBPRealTimePressure:(NSData *)data;

+ (VTMBPRunStatus)parseBPRealTimeStatus:(NSData *)data;

+ (VTMBPRealTimeWaveform)parseBPRealTimeWaveform:(NSData *)data;

+ (VTMBPRealTimeData)parseBPRealTimeData:(NSData *)data;

+ (VTMBPConfig)parseBPConfig:(NSData *)data;

+ (VTMBPBPResult)parseBPResult:(NSData *)data;

+ (VTMBPECGResult)parseECGResult:(NSData *)data;

+ (VTMBPMeasuringData)parseBPMeasuringData:(NSData *)data;

+ (VTMBPEndMeasureData)parseBPEndMeasureData:(NSData *)data;

+ (VTMECGMeasuringData)parseECGMeasuringData:(NSData *)data;

+ (VTMECGEndMeasureData)parseECGEndMeasureData:(NSData *)data;

+ (NSArray *)parseBPPoints:(NSData *)data;

+ (NSArray *)parseBPOrignalPoints:(NSData *)pointData;


+ (VTMBPWBPFileData)parseBPWBPFileData:(NSData *)data;

+ (VTMBPWECGFileData)parseBPWECGFileData:(NSData *)data;


+ (NSArray *)parseWiFiList:(NSData *)data;

+ (VTMWiFiInfo)parseWiFiInfo:(NSData *)data;

+ (VTMWiFiConfig)parseWiFiConfig:(NSData *)data;

+ (NSData *)getByteWithWiFiConfig:(VTMWiFiConfig)config;

+ (VTMBP3AlarmInfo)bp3_parseAlarmInfo:(NSData *)data;

+ (NSData *)getByteWithAlarmInfo:(VTMBP3AlarmInfo)info;

+ (VTMBP3FileData)bp3_parseBPFileData:(NSData *)data;

+ (VTMBP3ECGFileData)bp3_parseECGFileData:(NSData *)data;

@end

@interface VTMBLEParser (Scale)

+ (VTMRealTimeWF)parseScaleRealTimeWaveform:(NSData *)data;

/// @brief Parse params that Scale S1 running.
/// @param data `getScaleRunParams` response
+ (VTMScaleRunParams)parseScaleRunParams:(NSData *)data;

/// @brief Parse real-time data that from Scale S1.
/// @param data `getScaleRealTimeData` response
+ (VTMScaleRealData)parseScaleRealData:(NSData *)data;

/// @brief Parse file downloaded from Scale S1
/// @param data scale.dat
/// @param completion callback result
+ (void)parseScaleFile:(NSData *)data completion:(void(^)(VTMScaleFileHead head, VTMScaleFileData fileData))completion;

@end

@interface VTMBLEParser (Oximeter)

// MARK: common
+ (void)oxi_parseFile:(NSData *)data completion:(void(^)(VTMOxiFileHead head, VTMOxiPoint *point, VTMOxiFileTail tail))completion;

// MARK: Wearable Oximeter

+ (VTMWOxiInfo)woxi_parseConfig:(NSData *)data;

+ (VTMWOxiRealData)woxi_parseRealData:(NSData *)data;

// MARK: Finger Clip Oximeter

+ (VTMFOxiConfig)foxi_parseConfig:(NSData *)data;

+ (VTMFOxiMeasureInfo)foxi_parseMeasureInfo:(NSData *)data;

+ (void)foxi_parseMeasureWave:(NSData *)data completion:(void(^)(int num, VTMFOxiMeasureWave *wave))completion;


+ (VTMFOxiWorkStatus)foxi_parseWorkStatus:(NSData *)data;



@end

@interface VTMBLEParser (BabyMonitor)

+ (VTMBabyConfig)baby_parseConfig:(NSData *)data;

+ (VTMBabyRunParams)baby_parseRunParams:(NSData *)data;

+ (VTMBabyAtt)baby_parseAttitude:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
