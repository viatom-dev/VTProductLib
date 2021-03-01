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

/// @brief support for series of ecg.
@interface VTMBLEParser (ECG)

// All ecg product.
+ (void)parseWaveHeadAndTail:(NSData *)data result:(void(^)(VTMFileHead head, VTMER2FileTail tail))finished;

+ (float)mVFromShort:(short)n;

+ (VTMRunStatus)parseStatus:(u_char)status;

+ (VTMFlagDetail)parseFlag:(u_char)flag;

+ (VTMRealTimeWF)parseRealTimeWaveform:(NSData *)data;

+ (VTMRealTimeData)parseRealTimeData:(NSData *)data;

#pragma mark -- Wave
#pragma mark --- ER1/DuoEK/ER2

+ (NSData *)parseWaveData:(NSData *)data;

+ (NSArray *)parsePoints:(NSData *)pointData;

+ (NSArray *)parseOrignalPoints:(NSData *)pointData;

#pragma mark --- VBeat

+ (NSArray *)parseVBeatWaveData:(NSData *)waveData;


#pragma mark -- config
#pragma mark --- ER1/VBeat

+ (VTMER1Config)parseER1Config:(NSData *)data;

#pragma mark --- ER2/DuoEK

+ (VTMER2Config)parseER2Config:(NSData *)data;

@end


/// @brief support for series of blood pressure.
@interface VTMBLEParser (BP)

+ (VTMRealTimePressure)parseBPRealTimePressure:(NSData *)data;

+ (VTMBPRealTimeWaveform)parseBPRealTimeWaveform:(NSData *)data;

+ (VTMBPRealTimeData)parseBPRealTimeData:(NSData *)data;

+ (VTMBPConfig)parseBPConfig:(NSData *)data;

+ (VTMBPBPResult)parseBPResult:(NSData *)data;

+ (VTMECGResult)parseECGResult:(NSData *)data;

+ (VTMBPMeasuringData)parseBPMeasuringData:(NSData *)data;

+ (VTMBPEndMeasureData)parseBPEndMeasureData:(NSData *)data;

+ (VTMECGMeasuringData)parseECGMeasuringData:(NSData *)data;

+ (VTMECGEndMeasureData)parseECGEndMeasureData:(NSData *)data;

@end

/// @brief support for scale s1
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