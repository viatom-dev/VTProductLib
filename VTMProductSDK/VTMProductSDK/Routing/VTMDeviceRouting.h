//
//  VTMDeviceRouting.h
//  VTMProductSDK
//
//  设备 → 通信模块 的路由。
//
//  SDK 有两套互不兼容的通信模块，README 明确要求不要混用：
//
//    Module A  VTMURATUtils       心电/血压/体脂秤/ER3/M系列/腕式血氧/指夹血氧/婴儿监护/呼吸机
//    Module B  VTO2Communicate    O2 系列（O2Ring、Oxylink、BabyO2、KidsO2、BBSM S3 …）
//
//  选哪一个由两件事决定：
//
//    1. 蓝牙名前缀 —— 大多数设备靠名字就能定下来
//    2. 广播数据里的协议代际 —— 少数产品蓝牙名没变但协议升级了，
//       这类设备用 Module A 的 woxi_* 指令通信更好（Module B 虽然也能通，
//       但内部要做一层转包）
//
//  代际信息在 kCBAdvDataManufacturerData 里，扫描阶段就能拿到，
//  不需要先连接。结构体 UserAdvData_t 定义在公开头 VTMBLEStruct.h。
//

#import <Foundation/Foundation.h>
#import <VTMProductLib/VTMProductLib.h>

NS_ASSUME_NONNULL_BEGIN

/// 该用哪个通信模块
typedef NS_ENUM(NSInteger, VTMCommModule) {
    /// 两张表都不认识这个设备
    VTMCommModuleUnsupported = 0,
    /// Module A：VTMURATUtils
    VTMCommModuleURAT,
    /// Module B：VTO2Communicate
    VTMCommModuleO2,
};

/// 设备支持的协议代际，解析自广播数据
typedef NS_ENUM(NSInteger, VTMProtocolGeneration) {
    /// 广播数据缺失或长度不足，无法判断。
    /// 注意：iOS 重连已配对设备时可能拿不到广播数据，所以这个值是正常会出现的，
    /// 不代表设备有问题。此时按蓝牙名走保守路线。
    VTMProtocolGenerationUnknown = 0,
    /// 只有老 UUID 服务
    VTMProtocolGenerationLegacy,
    /// 新 UUID 服务可用（即「二代」）
    VTMProtocolGenerationSecond,
};

/// 路由结果
typedef struct {
    VTMCommModule module;
    /// 仅当 module == VTMCommModuleURAT 时有意义。
    /// 这是**期望**的设备类型；SDK 连接后会自己再判一次，
    /// 对于靠 VTMURATDeviceExtension 扩展识别的设备，两者应当一致。
    VTMDeviceType expectedDeviceType;
    VTMProtocolGeneration generation;
} VTMDeviceRoute;

@interface VTMDeviceRouting : NSObject

/// 解析广播数据得到协议代际。
/// @param adv CBCentralManager 扫描回调给的 advertisementData，可为 nil
+ (VTMProtocolGeneration)generationFromAdvertisementData:(nullable NSDictionary *)adv;

/// 这个蓝牙名是不是我们认识的设备 —— 扫描列表的过滤依据。
+ (BOOL)isKnownDeviceName:(nullable NSString *)name;

/// 完整路由：名字 + 广播数据 → 用哪个模块、期望什么设备类型、什么代际。
+ (VTMDeviceRoute)routeForDeviceName:(nullable NSString *)name
                   advertisementData:(nullable NSDictionary *)adv;

/// 需要通过 VTMURATDeviceExtension 扩展识别的蓝牙名前缀。
///
/// 包含两类：同名双代血氧的二代设备（如二代 O2Ring），以及定制改名产品。
/// 这两类的蓝牙名都不在 SDK 的内置识别链里，必须靠扩展协议告诉 SDK 该当成
/// 什么类型，否则 SDK 会判成 VTMDeviceTypeUnknown，指令发不出去。
///
/// VTMProductURATUtils 实现该协议时直接返回这里的结果，保证「路由表认为
/// 该走 Module A」和「SDK 实际识别出的类型」一致。
+ (nullable NSArray<NSString *> *)extensionNamePrefixesForDeviceType:(VTMDeviceType)deviceType;

/// 调试/展示用的可读名称
+ (NSString *)descriptionForModule:(VTMCommModule)module;
+ (NSString *)descriptionForGeneration:(VTMProtocolGeneration)generation;

@end

NS_ASSUME_NONNULL_END
