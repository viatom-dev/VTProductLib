//
//  VTMBabyPatchModel.h
//  VTMProductSDK
//
//  翻身贴（BBSM P1 / BS1）指令测试页的 Model。
//
//  职责：菜单与设置项的定义、设备应答的解析与格式化、日志、文件下载缓冲、输入校验。
//  不依赖 UIKit，也不直接发指令 —— 发指令是 Controller 的事。
//
//  V3 协议新增的内容（蜂鸣器、DropTemp、姿态里的睡眠输出、记录文件睡眠统计）用
//  `VTM_BABY_PATCH_V3` 包起来：Demo 在 release 模式下依赖的 trunk 二进制可能还没有这些 API，
//  没有这个宏时页面只保留一代指令，照样能编译和使用。
//

#import <Foundation/Foundation.h>
#import <VTMProductLib/VTMProductLib.h>

NS_ASSUME_NONNULL_BEGIN

/// 根据设备应答推断的协议代际。设备信息里没有可靠的代际字段，只能看应答长度和文件版本：
///   运行参数 0x02  一代 28 字节 / V3 68 字节（末尾多 40 字节睡眠信息）
///   姿态上报 0x03  一代 26 字节 / V3 28 字节（末尾多 2 字节睡眠输出）
///   配置信息 0x00  V3 45 字节，更短视为一代（文档写 37，SDK 结构体按 40）
///   记录文件 R     file_version >= 2 视为 V3（与 SDK 解析规则一致）
typedef NS_ENUM(NSInteger, VTMBabyProtocolGeneration) {
    VTMBabyProtocolGenerationUnknown = 0,
    VTMBabyProtocolGenerationV1,
    VTMBabyProtocolGenerationV3,
    /// 不同来源的判定互相矛盾，说明固件或 SDK 解析有问题，需要重点看
    VTMBabyProtocolGenerationConflict,
};

typedef NS_ENUM(NSInteger, VTMBabyPatchAction) {
    VTMBabyPatchActionDeviceInfo,
    VTMBabyPatchActionSyncTime,
    VTMBabyPatchActionFactoryReset,
    VTMBabyPatchActionGetConfig,
    VTMBabyPatchActionSetConfig,
    VTMBabyPatchActionRunParams,
    VTMBabyPatchActionBuzzer,
    VTMBabyPatchActionFileList,
};

@interface VTMBabyPatchMenuItem : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
@property (nonatomic, assign, readonly) VTMBabyPatchAction action;
/// 会改动设备状态、需要二次确认的操作
@property (nonatomic, assign, readonly) BOOL destructive;
@end

@interface VTMBabyPatchMenuSection : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSArray<VTMBabyPatchMenuItem *> *items;
@end

/// 0x01 设置配置信息里的一个设置项（对应协议 SystemSettingEnum）
@interface VTMBabyPatchSettingItem : NSObject
@property (nonatomic, assign, readonly) u_char type;
@property (nonatomic, copy, readonly) NSString *title;
/// 取值说明，显示在输入框上方
@property (nonatomic, copy, readonly) NSString *hint;
@property (nonatomic, assign, readonly) NSInteger minValue;
@property (nonatomic, assign, readonly) NSInteger maxValue;
@end

@interface VTMBabyPatchModel : NSObject

@property (nonatomic, copy, readonly) NSArray<VTMBabyPatchMenuSection *> *sections;
@property (nonatomic, copy, readonly) NSArray<VTMBabyPatchSettingItem *> *settingItems;

/// 切换语言后调用：按当前语言重建菜单和设置项。协议判定和姿态文案取值时自动按当前语言生成
- (void)reloadLocalizedContent;

#pragma mark - 状态

/// 是否已从设备读到过配置（用来给设置项输入框填当前值）
@property (nonatomic, assign, readonly) BOOL hasConfig;
@property (nonatomic, assign, readonly) VTMBabyConfig config;

/// 收到的 0x03 姿态上报次数（测试固件以 26Hz 主动上报）
@property (nonatomic, assign, readonly) NSUInteger attitudePushCount;

/// 最近一次 0x01 设置下发的设置项，应答回来时用于日志
@property (nonatomic, strong, nullable) VTMBabyPatchSettingItem *pendingSetting;

/// 最近一次文件列表
@property (nonatomic, copy, readonly) NSArray<NSString *> *fileNames;

#pragma mark - 日志

@property (nonatomic, copy, readonly) NSString *logText;
- (void)appendLog:(NSString *)text;
- (void)clearLogs;

#pragma mark - 应答解析（返回写进日志的描述）

- (NSString *)applyDeviceInfo:(NSData *)response;
- (NSString *)applyConfig:(NSData *)response;
- (NSString *)applyRunParams:(NSData *)response;
/// 姿态上报频率高，不写日志；结果并入 `liveText` 显示在顶部
- (NSString *)applyAttitude:(NSData *)response;
- (NSString *)applyFileList:(NSData *)response;

#pragma mark - 协议代际

@property (nonatomic, assign, readonly) VTMBabyProtocolGeneration generation;
/// 一行判定结论 + 各来源依据，例如「协议：V3 ｜ 运行参数 68B→V3  姿态 28B→V3」
- (NSString *)generationSummary;

/// 顶部状态栏：协议判定 + 最近一次姿态上报
- (NSString *)liveText;

#pragma mark - 设置项

/// 当前配置里该设置项的值；没读过配置时返回 nil
- (nullable NSNumber *)currentValueForSetting:(VTMBabyPatchSettingItem *)item;
/// 校验输入，合法时通过 option 返回要下发的数据并返回 nil，否则返回错误说明
- (nullable NSString *)validateSetting:(VTMBabyPatchSettingItem *)item
                                 input:(NSString *)input
                                option:(VTMOxiParamsOption *)option;

#ifdef VTM_BABY_PATCH_V3
/// 校验蜂鸣器输入，合法时通过 info 返回并返回 nil，否则返回错误说明
- (nullable NSString *)validateBuzzerOn:(NSString *)on
                                   time:(NSString *)time
                              intensity:(NSString *)intensity
                                   info:(VTMBabyBuzzerInfo *)info;
#endif

#pragma mark - 文件下载

@property (nonatomic, copy, readonly, nullable) NSString *downloadingFileName;
@property (nonatomic, assign, readonly) u_int expectedLength;
@property (nonatomic, assign, readonly) u_int downloadedLength;

- (void)prepareDownload:(NSString *)fileName;
- (void)beginDownloadWithLength:(u_int)length;
- (void)appendDownloadData:(NSData *)data;
- (BOOL)isDownloadComplete;
/// 解析已下载的文件（R 开头为记录文件，E 开头为事件文件），返回摘要并清空下载状态
- (NSString *)finishDownload;
- (void)cancelDownload;

#pragma mark - 文案

+ (NSString *)nameForCommand:(u_char)cmd;
+ (NSString *)descriptionForFailure:(VTMBLEPkgType)type;
+ (NSString *)descriptionForSendError:(u_char)errorCode;

@end

NS_ASSUME_NONNULL_END
