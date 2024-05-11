//
//  VTMProductURATUtils.h
//  VTMProductSDKDemo
//
//  Created by Viatom3 on 2021/2/20.
//  Copyright © 2021 viatom. All rights reserved.
//

//#import "VTMURATUtils.h"
typedef enum : NSUInteger {
    BPStateInactive = 0,
    BPStateMemory,
    BPStateCharging,
    BPStateReady,
    BPStateBPMeasuring,
    BPStateBPMeasureEnd,
    BPStateECGMeasuring,
    BPStateECGMeasureEnd,
} BPState;

NS_ASSUME_NONNULL_BEGIN

@interface VTMProductURATUtils : VTMURATUtils
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
