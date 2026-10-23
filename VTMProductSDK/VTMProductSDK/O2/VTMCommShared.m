//
//  VTMCommShared.m
//  VTO2Lib
//
//  Created by yangweichao on 2026/7/23.
//  Copyright © 2026 viatom. All rights reserved.
//

#import "VTMCommShared.h"

@implementation VTMCommShared

static VTMCommShared *_instance = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    return [VTMCommShared sharedInstance];
}
-(id)copyWithZone:(NSZone *)zone{
    return [VTMCommShared sharedInstance];
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [VTMCommShared sharedInstance];
}


@end
