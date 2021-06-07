//
//  VTMBLEParser+Scale.h
//  VTMProductLib
//
//  Created by yangweichao on 2021/6/7.
//

#import <VTMProductLib/VTMProductLib.h>

NS_ASSUME_NONNULL_BEGIN

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
