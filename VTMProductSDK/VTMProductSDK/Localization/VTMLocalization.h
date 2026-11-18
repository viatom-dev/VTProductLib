//
//  VTMLocalization.h
//  VTMProductSDK
//
//  Demo 的应用内语言切换。
//
//  - 默认英文，不跟随系统语言：对外 Demo 以英文为主。
//  - 文案放在 en.lproj / zh-Hans.lproj 的 Localizable.strings，按当前语言直接取对应 lproj，
//    所以切换后不用重启 App。
//  - 切换后发 `VTMLanguageDidChangeNotification`，页面收到后自行刷新文案。
//  - 当前语言缺 key 时回落到英文，英文也缺时返回 key 本身，方便一眼看出漏翻。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VTMLanguage) {
    VTMLanguageEnglish = 0,
    VTMLanguageChineseSimplified,
};

FOUNDATION_EXPORT NSNotificationName const VTMLanguageDidChangeNotification;

@interface VTMLocalization : NSObject

/// 当前语言，持久化在 NSUserDefaults；没设置过时为英文
+ (VTMLanguage)currentLanguage;
/// 切换语言并发送 `VTMLanguageDidChangeNotification`（语言不变时不发）
+ (void)setCurrentLanguage:(VTMLanguage)language;

+ (NSString *)localizedString:(NSString *)key;
/// 语言自身的名称（English / 简体中文），用于切换菜单
+ (NSString *)nativeNameForLanguage:(VTMLanguage)language;

@end

/// 取当前语言的文案
#define VTMLocalized(key) [VTMLocalization localizedString:(key)]

NS_ASSUME_NONNULL_END
