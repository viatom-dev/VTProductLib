//
//  VTMBabyPatchView.m
//  VTMProductSDK
//

#import "VTMBabyPatchView.h"
#import <Masonry/Masonry.h>
#import "VTMLocalization.h"

@interface VTMBabyPatchView ()
@property (nonatomic, strong, readwrite) UITableView *tableView;
@property (nonatomic, strong, readwrite) UIButton *clearLogButton;
@property (nonatomic, strong) UILabel *liveLabel;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UILabel *logTitleLabel;
@end

// Demo 的部署版本是 iOS 9，系统语义色和安全区都要带降级
static UIColor *VTMBabyBackgroundColor(void) {
    if (@available(iOS 13.0, *)) { return UIColor.systemGroupedBackgroundColor; }
    return [UIColor groupTableViewBackgroundColor];
}
static UIColor *VTMBabyCardColor(void) {
    if (@available(iOS 13.0, *)) { return UIColor.secondarySystemGroupedBackgroundColor; }
    return UIColor.whiteColor;
}
static UIColor *VTMBabyTextColor(void) {
    if (@available(iOS 13.0, *)) { return UIColor.labelColor; }
    return UIColor.blackColor;
}
static UIColor *VTMBabySecondaryTextColor(void) {
    if (@available(iOS 13.0, *)) { return UIColor.secondaryLabelColor; }
    return UIColor.darkGrayColor;
}

@implementation VTMBabyPatchView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
        [self applyLocalization];
    }
    return self;
}

- (void)setupSubviews {
    self.backgroundColor = VTMBabyBackgroundColor();

    // ── 顶部：姿态实时上报 ──
    UIView *liveCard = [[UIView alloc] init];
    liveCard.backgroundColor = VTMBabyCardColor();
    liveCard.layer.cornerRadius = 10;
    [self addSubview:liveCard];

    _liveLabel = [[UILabel alloc] init];
    _liveLabel.numberOfLines = 0;
    _liveLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
    _liveLabel.textColor = VTMBabyTextColor();
    [liveCard addSubview:_liveLabel];

    // ── 中间：指令列表 ──
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 52;
    [self addSubview:_tableView];

    // ── 底部：日志 ──
    UILabel *logTitle = [[UILabel alloc] init];
    _logTitleLabel = logTitle;
    logTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    logTitle.textColor = VTMBabySecondaryTextColor();
    [self addSubview:logTitle];

    _clearLogButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _clearLogButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    [self addSubview:_clearLogButton];

    _logView = [[UITextView alloc] init];
    _logView.editable = NO;
    _logView.font = [UIFont fontWithName:@"Menlo" size:11] ?: [UIFont systemFontOfSize:11];
    _logView.backgroundColor = VTMBabyCardColor();
    _logView.textColor = VTMBabyTextColor();
    _logView.layer.cornerRadius = 10;
    _logView.textContainerInset = UIEdgeInsetsMake(8, 6, 8, 6);
    [self addSubview:_logView];

    // ── 布局 ──
    // iOS 11 以下没有安全区，Controller 设置了 edgesForExtendedLayout = None，直接贴边即可
    MASViewAttribute *topAnchor = self.mas_top;
    MASViewAttribute *bottomAnchor = self.mas_bottom;
    if (@available(iOS 11.0, *)) {
        topAnchor = self.mas_safeAreaLayoutGuideTop;
        bottomAnchor = self.mas_safeAreaLayoutGuideBottom;
    }
    [liveCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(topAnchor).offset(8);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    }];
    [_liveLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(liveCard).insets(UIEdgeInsetsMake(8, 10, 8, 10));
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(liveCard.mas_bottom);
        make.left.right.equalTo(self);
    }];
    [logTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tableView.mas_bottom).offset(4);
        make.left.equalTo(self).offset(20);
    }];
    [_clearLogButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(logTitle);
        make.right.equalTo(self).offset(-20);
        make.height.mas_greaterThanOrEqualTo(44); // 满足最小点击区域
    }];
    [_logView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.clearLogButton.mas_bottom);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.bottom.equalTo(bottomAnchor).offset(-8);
        // 日志区占屏幕约 1/3，其余给指令列表
        make.height.equalTo(self.mas_height).multipliedBy(0.32);
    }];
}

- (void)applyLocalization {
    self.liveLabel.accessibilityLabel = VTMLocalized(@"baby.view.live.a11y");
    self.logTitleLabel.text = VTMLocalized(@"baby.view.log");
    [self.clearLogButton setTitle:VTMLocalized(@"baby.view.clear") forState:UIControlStateNormal];
    self.clearLogButton.accessibilityLabel = VTMLocalized(@"baby.view.clear.a11y");
    self.logView.accessibilityLabel = VTMLocalized(@"baby.view.log.a11y");
}

- (void)showLiveText:(NSString *)text {
    self.liveLabel.text = text;
}

- (void)showLogText:(NSString *)text {
    self.logView.text = text;
    if (text.length > 0) {
        [self.logView scrollRangeToVisible:NSMakeRange(text.length - 1, 1)];
    }
}

@end
