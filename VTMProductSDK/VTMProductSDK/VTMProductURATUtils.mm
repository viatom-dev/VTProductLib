//
//  VTMProductURATUtils.m
//  VTMProductSDKDemo
//
//  Created by Viatom3 on 2021/2/20.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMProductURATUtils.h"
#import "VTMDeviceRouting.h"

@interface VTMProductURATUtils () <VTMURATDeviceExtension>

@end

@implementation VTMProductURATUtils

static VTMProductURATUtils *URATUtils = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URATUtils = [[self alloc] init];
        URATUtils.extension = URATUtils;
    });
    return URATUtils;
}

#pragma mark - VTMURATDeviceExtension

/// 把 SDK 默认认不出来的蓝牙名映射到设备类型。
///
/// 两类设备需要这个扩展：
///   1. 同名双代血氧的二代设备（如二代 O2Ring）—— 蓝牙名和一代一样，
///      不在 SDK 的内置识别链里
///   2. 定制改名产品
///
/// 前缀统一由 VTMDeviceRouting 提供，保证「路由表认为该走 Module A」
/// 和「SDK 实际识别出的类型」一致。要增减前缀改那边的表，不要改这里。
- (NSArray<NSString *> *)extensionNamePrefixsWithType:(VTMDeviceType)deviceType {
    return [VTMDeviceRouting extensionNamePrefixesForDeviceType:deviceType];
}

@end
