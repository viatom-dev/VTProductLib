//
//  VTMBLEParser+ECG.h
//  VTMProductLib
//
//  Created by yangweichao on 2021/6/7.
//

#import <VTMProductLib/VTMProductLib.h>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
