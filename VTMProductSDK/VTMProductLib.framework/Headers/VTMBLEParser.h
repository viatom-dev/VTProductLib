//
//  VTMBLEParser.h
//  VTMProductDemo
//
//  Created by viatom on 2020/10/29.
//

#import <Foundation/Foundation.h>
#import <VTMProductLib/VTMBLEStruct.h>

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

#pragma mark --- Besides DuoEK's a-file
+ (void)parseWaveHeadAndTail:(NSData *)data result:(void(^)(VTMFileHead head, VTMER2FileTail tail))finished;
#pragma mark --- DuoEK a-file
+ (void)parseFileA:(NSData *)data result:(void(^)(VTMDuoEKFileAHead head, VTMDuoEKFileAResult * results))finished;

#pragma mark --- VBeat

+ (NSArray *)parseVBeatWaveData:(NSData *)waveData;


#pragma mark -- config
#pragma mark --- ER1/VBeat

+ (VTMER1Config)parseER1Config:(NSData *)data;

#pragma mark --- ER2/DuoEK

+ (VTMER2Config)parseER2Config:(NSData *)data;

//MARK: - ER3

+ (VTMER3Config)parseER3Config:(NSData *)data;

+ (VTMER3RealTimeData)parseER3RealTimeData:(NSData *)data;

+ (CGFloat)er3MvFromShort:(short)n;

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

@end

@interface VTMBLEParser (BP)

+ (float)bpMvFromShort:(short)n;

+ (VTMRealTimePressure)parseBPRealTimePressure:(NSData *)data;

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


+ (NSArray *)parseWiFiList:(NSData *)data;

+ (VTMWiFiInfo)parseWiFiInfo:(NSData *)data;

+ (VTMWiFiConfig)parseWiFiConfig:(NSData *)data;

+ (NSData *)getByteWithWiFiConfig:(VTMWiFiConfig)config;

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

NS_ASSUME_NONNULL_END
