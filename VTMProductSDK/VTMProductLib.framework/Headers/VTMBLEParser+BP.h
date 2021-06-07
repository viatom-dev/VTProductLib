//
//  VTMBLEParser+BP.h
//  VTMProductLib
//
//  Created by yangweichao on 2021/6/7.
//

#import <VTMProductLib/VTMProductLib.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTMBLEParser (BP)

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

+ (float)bpMvFromShort:(short)n;

+ (NSArray *)parseBPPoints:(NSData *)data;

+ (NSArray *)parseBPOrignalPoints:(NSData *)pointData;

@end

NS_ASSUME_NONNULL_END
