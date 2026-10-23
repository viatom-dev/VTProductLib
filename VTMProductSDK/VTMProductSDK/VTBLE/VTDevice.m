//
//  VTDevice.m
//  VTMProductSDK
//
//  Created by viatom on 2020/6/23.
//  Copyright © 2020 viatom. All rights reserved.
//

#import "VTDevice.h"
#import "VTMDeviceRouting.h"

@implementation VTDevice

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral adv:(NSDictionary *)advDic RSSI:(NSNumber *)RSSI{
    self = [super init];
    if (self) {
        self.RSSI = RSSI;
        self.adv = advDic;
        self.advName = [advDic objectForKey:@"kCBAdvDataLocalName"];
        if (![self.advName isKindOfClass:[NSNull class]] &&
            ![self.advName isEqualToString:@""] &&
            self.advName != nil && 
            ![peripheral.name isEqualToString:self.advName]) {
            [peripheral setValue:self.advName forKey:@"name"];
        }
        self.rawPeripheral = peripheral;
        DLog(@"scan device:%@",peripheral.name);

        // 过滤由 VTMDeviceRouting 的前缀表统一决定，不再在这里逐个 hasPrefix。
        // 那张表同时驱动「扫不扫」和「连上以后用哪个通信模块」，
        // 两者必须一致，否则会出现扫得出来但连上没法通信的设备。
        if (![VTMDeviceRouting isKnownDeviceName:peripheral.name]) {
            return nil;
        }
    }
    return self;
}

@end
