//
//  VTMProductURATUtils.m
//  VTMProductSDKDemo
//
//  Created by Viatom3 on 2021/2/20.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMProductURATUtils.h"

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

/// 把定制化的蓝牙名前缀映射到设备类型。
///
/// SDK 默认按出厂蓝牙名识别设备。如果你的产品改过蓝牙名，在这里按设备类型返回
/// 对应的前缀，SDK 就会把它识别成该类型，之后用该类型的指令（例如腕式血氧的
/// `woxi_*`）正常通信。
///
/// 返回 nil 表示该类型不需要扩展，走 SDK 默认识别。
- (NSArray<NSString *> *)extensionNamePrefixsWithType:(VTMDeviceType)deviceType {
    switch (deviceType) {
        // 示例：自家改名后的心电设备和腕式血氧设备
        // case VTMDeviceTypeECG:
        //     return @[@"MyECG", @"CardioMonitor"];
        // case VTMDeviceTypeWOxi:
        //     return @[@"MyO2Ring"];
        default:
            return nil;
    }
}

@end
