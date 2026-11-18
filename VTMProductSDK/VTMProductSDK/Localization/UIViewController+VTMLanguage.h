//
//  UIViewController+VTMLanguage.h
//  VTMProductSDK
//
//  导航栏上的语言切换按钮。点击弹出 English / 简体中文 选择，选中后由 VTMLocalization
//  发送 VTMLanguageDidChangeNotification，各页面自行刷新文案。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (VTMLanguage)

/// 新建一个语言切换按钮，标题随当前语言（Language / 语言）
- (UIBarButtonItem *)vtm_makeLanguageBarButtonItem;

@end

NS_ASSUME_NONNULL_END
