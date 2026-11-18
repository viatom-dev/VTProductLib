//
//  VTMLocalization.m
//  VTMProductSDK
//

#import "VTMLocalization.h"

NSNotificationName const VTMLanguageDidChangeNotification = @"VTMLanguageDidChangeNotification";

static NSString * const kLanguageDefaultsKey = @"VTMDemoLanguage";

@implementation VTMLocalization

+ (VTMLanguage)currentLanguage {
    NSInteger stored = [[NSUserDefaults standardUserDefaults] integerForKey:kLanguageDefaultsKey];
    // 没存过时 integerForKey 返回 0，正好是英文；存了无效值也按英文处理
    return stored == VTMLanguageChineseSimplified ? VTMLanguageChineseSimplified : VTMLanguageEnglish;
}

+ (void)setCurrentLanguage:(VTMLanguage)language {
    if (language == [self currentLanguage]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:language forKey:kLanguageDefaultsKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:VTMLanguageDidChangeNotification object:nil];
}

+ (NSString *)nativeNameForLanguage:(VTMLanguage)language {
    // 固定用各自的语言书写，不随当前语言翻译，便于看不懂当前语言的人也能切回来
    return language == VTMLanguageChineseSimplified ? @"简体中文" : @"English";
}

+ (NSString *)localizedString:(NSString *)key {
    // 用不可能出现在文案里的值判断「缺 key」：localizedStringForKey 缺 key 时原样返回 value
    static NSString * const missing = @"__VTM_MISSING_LOCALIZATION__";
    NSBundle *current = [self bundleForLanguage:[self currentLanguage]];
    NSString *value = [current localizedStringForKey:key value:missing table:nil];
    if (![value isEqualToString:missing]) {
        return value;
    }
    NSBundle *english = [self bundleForLanguage:VTMLanguageEnglish];
    value = [english localizedStringForKey:key value:missing table:nil];
    return [value isEqualToString:missing] ? key : value;
}

+ (NSBundle *)bundleForLanguage:(VTMLanguage)language {
    static NSMutableDictionary<NSNumber *, NSBundle *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary dictionary];
    });
    @synchronized (cache) {
        NSBundle *bundle = cache[@(language)];
        if (!bundle) {
            NSString *name = language == VTMLanguageChineseSimplified ? @"zh-Hans" : @"en";
            NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"lproj"];
            bundle = (path ? [NSBundle bundleWithPath:path] : nil) ?: [NSBundle mainBundle];
            cache[@(language)] = bundle;
        }
        return bundle;
    }
}

@end
