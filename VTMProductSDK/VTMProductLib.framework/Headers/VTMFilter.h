//
//  VTMFilter.h
//  DuoEK
//
//  Created by Viatom on 2019/5/5.
//  Copyright © 2019年 Viatom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTMFilter : NSObject

+ (VTMFilter *)shared;

/// @brief Use before deal with real-time data.
- (void)resetParams;

/// @brief Only support for dynamic data.  Input array contains NSNumber with double type.
/// @param ptArray points of real-time waveform.
- (NSArray *)sfilterPointValue:(NSArray <NSNumber *>*)ptArray;

/// @brief ECG mV value.
/// @param ptValue value
- (NSArray *)filterPointValue:(double)ptValue;

/// @brief Only support for history data. Input array contains NSNumber with double type.
/// @param ptArray waveform from history file.
- (NSArray *)offlineFilterPoints:(NSArray <NSNumber *>*)ptArray;

@end

NS_ASSUME_NONNULL_END
