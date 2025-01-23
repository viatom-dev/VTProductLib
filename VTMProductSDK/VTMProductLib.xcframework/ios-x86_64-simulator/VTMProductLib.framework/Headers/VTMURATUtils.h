//
//  VTMURATUtils
//  ViHealth
//
//  Created by Viatom on 2018/6/5.
//  Copyright © 2018年 Viatom. All rights reserved.
//

/**
 *   CN
 *   @brief 该类仅用于蓝牙通信。 传入peripheral属性， 待VTMURATDeviceDelegate 完成后， 即可以进行蓝牙通信。
 *
 *   EN
 *   @brief Communication with the peripheral. Set the peripheral property, after the VTMURATDeviceDelegate callback, you can use this class communicate with the peripheral.
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "VTMBLEStruct.h"
#import "VTMBLEEnum.h"

@class VTMURATUtils;

@protocol VTMURATDeviceExtension <NSObject>

@optional
/// @brief extend the device name prefix
/// @param deviceType device type
- (NSArray<NSString *> *_Nullable)extensionNamePrefixsWithType:(VTMDeviceType)deviceType;

@end

@protocol VTMURATDeviceDelegate <NSObject>

@optional

/// @brief services and characteristics complete deployed.
/// @param util util
- (void)utilDeployCompletion:(VTMURATUtils * _Nonnull)util;


/// @brief services or characteristics error.  unable to comminicate.
/// @param util util
- (void)utilDeployFailed:(VTMURATUtils * _Nonnull)util;

/// @brief RSSI
/// @param RSSI RSSI
- (void)util:(VTMURATUtils * _Nonnull)util updateDeviceRSSI:(NSNumber *_Nonnull)RSSI;

@end

@protocol VTMURATUtilsDelegate <NSObject>

@optional

/// @brief an error occured at send command to device.
/// @param util util
/// @param errorCode  0: peripheral == nil  1: txcharacteristic == nil  2:peripheral.state != connected 3: timeout
- (void)util:(VTMURATUtils * _Nonnull)util commandSendFailed:(u_char)errorCode;



/// @brief Response .
/// @param util util
/// @param cmdType cmdType. ``VTMBLECmd`` ``VTMECGCmd`` ``VTMBPCmd`` ``VTMSCALECmd``
/// @param deviceType device type ``VTMDeviceType``
/// @param response response data .  use ``VTMBLEParser`` to parse.
- (void)util:(VTMURATUtils * _Nonnull)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData * _Nullable)response;


/// @brief an error occured.
/// @param util util
/// @param cmdType cmdType.  ``VTMBLECmd`` ``VTMECGCmd`` ``VTMBPCmd`` ``VTMSCALECmd``
/// @param deviceType device type  ``VTMDeviceType``
/// @param type error type. ``VTMBLEPkgType``
- (void)util:(VTMURATUtils * _Nonnull)util commandFailed:(u_char)cmdType deviceType:(VTMDeviceType)deviceType failedType:(VTMBLEPkgType)type;


/// @brief receive heart rate from standard service.
/// @param hrByte heart rate value.
- (void)receiveHeartRateByStandardService:(Byte)hrByte;

@end

@interface VTMURATUtils : NSObject

/// @brief manage communicate.
@property (nonatomic, assign) id<VTMURATUtilsDelegate> _Nullable delegate;

/// @brief manage discover services and characteristics.
@property (nonatomic, assign) id <VTMURATDeviceDelegate> _Nullable deviceDelegate;

/// @brief extension device
@property (nonatomic, weak) id<VTMURATDeviceExtension> _Nullable extension;

/// @brief notify standard service
@property (nonatomic) BOOL notifyHeartRate;

/// @brief notify device RSSI
@property (nonatomic) BOOL notifyDeviceRSSI;

/// @brief connected peripheral.
@property (nonatomic, strong) CBPeripheral * _Nonnull peripheral;

@property (nonatomic, assign, readonly) VTMDeviceType currentType;

/// @brief The name of the file currently being read
@property (nonatomic, copy, readonly) NSString * _Nullable curReadFileName;

/// @brief The key of the wearable oximeter
@property (nonatomic, copy) NSString * _Nullable wearablePPGKey;

/// @brief request device's information.
- (void)requestDeviceInfo;

/// @brief request device's battery information.
- (void)requestBatteryInfo;

/// @brief sync time.
/// @param date  NSDate
- (void)syncTime:(NSDate * _Nullable)date;

/// @brief request file's list.
- (void)requestFilelist;

/// @brief read file's length by file name.  Lock util send `endReadFile`
/// @param fileName  file name.
- (void)prepareReadFile:(NSString * _Nonnull)fileName;

/// @brief read file's content.
/// @param offset  specified offset.  [0, file's length]
- (void)readFile:(u_int)offset;

/// @brief end read file.
- (void)endReadFile;

/// @brief factory reset
- (void)factoryReset;


#pragma mark ----- Now supported BP2 Pro & O2Ring S  ------

/// @brief sync time and time zone.
/// @param date  NSDate
- (void)syncTimeZone:(NSDate * _Nullable)date;


#pragma mark ----- Now only support BP2 Pro  ------

/// @brief write file data to peripheral.
/// @param data  file data
/// @param fileName  file name
- (void)writeFile:(NSData * _Nonnull)data withName:(NSString * _Nonnull)fileName;

/// @brief delete target file by name. if name is nil, delete all files.
/// @param fileName file name
- (void)deleteFile:(NSString * _Nullable)fileName;

#pragma mark ----- ------------------------  ------


@end


@interface VTMURATUtils (ECG)

/// @brief 请求ECG系列相关配置信息
- (void)requestECGConfig;

/// @brief 请求ECG系列实时数据
- (void)requestECGRealData;

/// @brief 同步ER1/VBeat配置信息
/// @param config  ER1/VBeat配置信息
- (void)syncER1Config:(VTMER1Config)config;

/// @brief 同步ER1/VBeat配置信息  ---  when software version higher than 1.0.2.0
/// @param config  ER1/VBeat配置信息
- (void)syncER1NewConfig:(VTMER1NewConfig)config;

/// @brief 退出测量
- (void)exitER1MeasurementMode;

/// @brief 同步ER2/DuoEK配置信息
/// @param config ER2/DuoEK配置信息
- (void)syncER2Config:(VTMER2Config)config;

@end


@interface VTMURATUtils (BP)

/// @brief 请求改变BP设备当前运行状态
/// @param state   0 :- 进入血压测量 1 :-  进入心电测量 2 :- 进入历史 3 :- 进入开机 4 :- 关机
- (void)requestChangeBPState:(u_char)state;

/// @brief 请求BP2/BP2A/BP2W配置信息
- (void)requestBPConfig;

/// @brief 同步BP2/BP2A/BP2W配置信息
/// @param config  配置信息
- (void)syncBPConfig:(VTMBPConfig)config;

/// @brief 请求BP系列实时数据
- (void)requestBPRealData;

/// @brief 请求扫描 BP Wi-FI 列表
- (void)requestScanWiFiList;

/// @brief 请求配置 BP Wi-Fi 设置
- (void)requestBPConfigureWiFi:(VTMWiFiConfig)wifiConfig;

/// @brief 请求获取 BP Wi-Fi 配置
- (void)requestBPWiFiConfiguration;

/// @brief 请求获取 用户文件的CRC32校验码
- (void)requestCRCFromBPWUserList;

/// real-time run status.
- (void)bp_requestRealStatus;

- (void)bp3_syncAlarmInfo:(VTMBP3AlarmInfo)info;

- (void)bp3_requestAlarmInfo;

- (void)bp3_syncBindStatus:(u_char)status;

@end


@interface VTMURATUtils (Scale)

/// @brief 请求体脂秤实时心电波形
- (void)requestScaleRealWve;

/// @brief 请求体脂秤实时运行状态
- (void)requestScaleRunPrams;

/// @brief 请求体脂秤实时数据
- (void)requestScaleRealData;

@end


@interface VTMURATUtils (ER3)

/// @brief 请求ECG系列相关配置信息
- (void)requestER3Config;

- (void)syncER3Config:(VTMER3Config)config;

/// @brief 请求ER3实时数据
- (void)requestER3ECGRealData;

/// @brief 退出测量
- (void)exitER3MeasurementMode;

/// @brief 开启测量
- (void)startER3MeasurementMode;

/// @brief 获取配置参数
- (void)getER3ConfigParams;

/// @brief 设置配置参数
- (void)setER3ConfigParams:(VTMER3ConfigParams)params;

@end

@interface VTMURATUtils (WearableOximeter)
/**
 * include O2Ring S /
 */
- (void)woxi_requestConfig;

- (void)woxi_syncConfigParam:(VTMOxiParamsOption)param;

- (void)woxi_requestWOxiRealData;

- (void)woxi_requestWOxiPPGData:(VTMWOxiRawSampleInfo)info;

- (void)woxi_requestPPGList;

- (void)woxi_prepareReadPPGFile:(NSString * _Nonnull)fileName;

- (void)woxi_readPPGFile:(u_int)offset;

- (void)woxi_endReadPPGFile;

@end

@interface VTMURATUtils (FingerClipOximeter)
/**
 * include PF-10BWS /
 */

- (void)foxi_requestConfig;

- (void)foxi_syncConfigParam:(VTMOxiParamsOption)param;

- (void)foxi_makeInfoSend:(BOOL)send;

- (void)foxi_makeWaveSend:(BOOL)send;


@end

@interface VTMURATUtils (BabyMonitor)

- (void)baby_requestConfig;

- (void)baby_syncConfigParam:(VTMOxiParamsOption)param;

/// 获取运行状态
- (void)baby_requestRunParams;

/// 获取姿势
- (void)baby_requestGesture;

@end
