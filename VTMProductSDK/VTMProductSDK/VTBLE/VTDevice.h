//
//  VTDevice.h
//  VTMProductSDK
//
//  Created by viatom on 2020/6/23.
//  Copyright © 2020 viatom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTDevice : NSObject

@property (nonatomic, strong) CBPeripheral *rawPeripheral;

@property (nonatomic, copy) NSString *advName;

/// 扫描时拿到的原始广播数据。
/// 必须保留下来，连接后要原样传给 -setPeripheral:advertisementData:，
/// 部分加密设备缺了它无法正确识别类型。
@property (nonatomic, strong) NSDictionary *adv;

@property (nonatomic, strong) NSNumber *RSSI;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral adv:(NSDictionary *)advDic RSSI:(NSNumber *)RSSI;


@end

NS_ASSUME_NONNULL_END
