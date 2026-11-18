//
//  VTMBabyPatchView.h
//  VTMProductSDK
//
//  翻身贴指令测试页的 View：顶部实时状态、中间指令列表、底部日志。
//  只负责布局和显示，不持有数据，也不处理事件 —— 事件由 Controller 绑定。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTMBabyPatchView : UIView

/// 指令列表，dataSource / delegate 由 Controller 设置
@property (nonatomic, strong, readonly) UITableView *tableView;
/// 清空日志按钮，target-action 由 Controller 绑定
@property (nonatomic, strong, readonly) UIButton *clearLogButton;

/// 按当前语言刷新静态文案（日志标题、清空按钮、无障碍标签）
- (void)applyLocalization;

/// 更新顶部实时状态（姿态上报）
- (void)showLiveText:(NSString *)text;
/// 整体刷新日志并滚到底部
- (void)showLogText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
