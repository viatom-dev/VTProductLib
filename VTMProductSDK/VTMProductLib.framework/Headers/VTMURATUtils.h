//
//  VTMURATUtils
//  ViHealth
//
//  Created by Viatom on 2018/6/5.
//  Copyright © 2018年 Viatom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <VTMProductLib/VTMBLEEnum.h>
#import <VTMProductLib/VTMBLEStruct.h>

@class VTMURATUtils;
@protocol VTMURATDeviceDelegate <NSObject>

@optional
- (void)utilDeployCompletion:(VTMURATUtils * _Nonnull)util;

- (void)utilDeployFailed:(VTMURATUtils * _Nonnull)util;

/// @brief 监听设备的信号强度
/// @param RSSI RSSI
- (void)util:(VTMURATUtils * _Nonnull)util updateDeviceRSSI:(NSNumber *_Nonnull)RSSI;

@end

@protocol VTMURATUtilsDelegate <NSObject>

@optional
- (void)util:(VTMURATUtils * _Nonnull)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData * _Nullable)response;

- (void)util:(VTMURATUtils * _Nonnull)util commandFailed:(u_char)cmdType deviceType:(VTMDeviceType)deviceType failedType:(VTMBLEPkgType)type;

//- (void)commandTimeOut:(u_char)cmd;   //将命令传入  方便区分

/// @brief 从标准服务接收到动态心率值
/// @param hrByte 心率值
- (void)receiveHeartRateByStandardService:(Byte)hrByte;

@end

@interface VTMURATUtils : NSObject

/// @brief 此代理负责app和设备端通信
@property (nonatomic, assign) id<VTMURATUtilsDelegate> _Nullable delegate;

/// @brief 此代理检测设备服务与特征是否处理完成，完成之后才能进行读写通信
@property (nonatomic, assign) id <VTMURATDeviceDelegate> _Nullable deviceDelegate;

/// @brief 监听标准服务心率变化， 需要设置VTMURATUtilsDelegate
@property (nonatomic) BOOL notifyHeartRate;

/// @brief 监听设备信号强弱，需要设置VTMURATDeviceDelegate
@property (nonatomic) BOOL notifyDeviceRSSI;

/// @brief 连接成功的设备
@property (nonatomic, strong) CBPeripheral * _Nonnull peripheral;

/// @brief MTU.  Default is 20.  Range of 20 to 247.
/// @warning The mtu change only support a part of devices.
@property (nonatomic, assign) NSUInteger mtu;

/// @brief 初始化添加设备并设置代理
/// @param device  连接的设备
/// @param target  设备代理
//- (instancetype _Nullable)initWithDevice:(CBPeripheral * _Nonnull)device deviceDelegate:(id <VTMURATDeviceDelegate> _Nullable)target;

/**
*   确定好读写特征之后，可通过以下方法进行数据交互
*   After determining the read and write characteristics, you can use the following methods for data interaction
*/

/// @brief 获取设备信息
- (void)requestDeviceInfo;

/// @brief 获取电池电量信息
- (void)requestBatteryInfo;

/// @brief 同步时间
/// @param date  任意时间点，默认为当前时间
- (void)syncTime:(NSDate * _Nullable)date;

/// @brief 获取文件列表
- (void)requestFilelist;

/// @brief 准备读取文件
/// @param fileName  文件名称
- (void)prepareReadFile:(NSString * _Nonnull)fileName;

/// @brief 根据文件的偏移量，多次读取，最终得到完整的文件
/// @param offset  文件数据的偏移量即已读取文件的长度，从0开始
- (void)readFile:(u_int)offset;

/// @brief 结束文件读取
- (void)endReadFile;

/// @brief 恢复出厂设置
- (void)factoryReset;

/// @brief 烧录出厂配置信息
/// @param config 出厂配置
- (void)factorySet:(VTMConfig)config;

@end

@interface VTMURATUtils (ECG)

/// @brief 请求ECG系列相关配置信息
- (void)requestECGConfig;

/// @brief 请求ECG系列实时数据
- (void)requestECGRealData;

/// @brief 同步ER1/VBeat配置信息
/// @param config  ER1/VBeat配置信息
- (void)syncER1Config:(VTMER1Config)config;

/// @brief 同步ER2/DuoEK配置信息
/// @param config ER2/DuoEK配置信息
- (void)syncER2Config:(VTMER2Config)config;

@end

@interface VTMURATUtils (BP)

/// @brief 请求BP2/BP2A配置信息
- (void)requestBPConfig;

/// @brief 声音开关
/// @param swi 开关
- (void)syncBPSwitch:(BOOL)swi;

/// @brief 请求BP系列实时数据
- (void)requestBPRealData;

@end

@interface VTMURATUtils (Scale)

/// @brief 请求体脂秤实时心电波形
- (void)requestScaleRealWve;

/// @brief 请求体脂秤实时运行状态
- (void)requestScaleRunPrams;

/// @brief 请求体脂秤实时数据
- (void)requestScaleRealData;

@end

