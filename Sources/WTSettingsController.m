#import "WTSettingsController.h"
#import "WTInputSettingsController.h"

@interface WTSettingItem : NSObject
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;
@property(nonatomic, copy) NSString *symbol;
@property(nonatomic, assign) BOOL isToggle;
@property(nonatomic, assign) BOOL enabled;
@end
@implementation WTSettingItem
@end

@interface WTSettingsCard : UIControl
@property(nonatomic, strong) UIVisualEffectView *blurView;
@property(nonatomic, strong) UILabel *symbolLabel;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *subtitleLabel;
@property(nonatomic, strong) UISwitch *toggle;
@property(nonatomic, strong) WTSettingItem *item;
@end

@implementation WTSettingsCard
- (instancetype)initWithItem:(WTSettingItem *)item {
    if ((self = [super initWithFrame:CGRectZero])) {
        _item = item;
        self.backgroundColor = UIColor.clearColor;
        self.layer.cornerRadius = 27;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.68].CGColor;
        self.clipsToBounds = YES;

        _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialLight]];
        _blurView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_blurView];
        [NSLayoutConstraint activateConstraints:@[
            [_blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];

        _symbolLabel = [UILabel new];
        _symbolLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _symbolLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightMedium];
        _symbolLabel.textColor = [UIColor colorWithRed:0.02 green:0.37 blue:0.21 alpha:1];
        _symbolLabel.textAlignment = NSTextAlignmentCenter;
        _symbolLabel.text = item.symbol ?: @"circle.grid.2x2.fill";
        [self addSubview:_symbolLabel];

        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.text = item.title;
        _titleLabel.numberOfLines = 1;
        [self addSubview:_titleLabel];

        _subtitleLabel = [UILabel new];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        _subtitleLabel.textColor = UIColor.secondaryLabelColor;
        _subtitleLabel.text = item.subtitle;
        _subtitleLabel.numberOfLines = 1;
        [self addSubview:_subtitleLabel];

        if (item.isToggle) {
            _toggle = [UISwitch new];
            _toggle.translatesAutoresizingMaskIntoConstraints = NO;
            _toggle.on = item.enabled;
            _toggle.onTintColor = [UIColor colorWithRed:0.02 green:0.55 blue:0.31 alpha:1];
            [_toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
            [self addSubview:_toggle];
        }

        NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
            [_symbolLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:17],
            [_symbolLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_symbolLabel.widthAnchor constraintEqualToConstant:48],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:_symbolLabel.trailingAnchor constant:9],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-12],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-12],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
            [_subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-10],
            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:7]
        ]];
        if (_toggle) {
            [constraints addObjectsFromArray:@[
                [_toggle.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
                [_toggle.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
                [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_toggle.leadingAnchor constant:-7],
                [_subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_toggle.leadingAnchor constant:-7]
            ]];
        }
        [NSLayoutConstraint activateConstraints:constraints];
    }
    return self;
}
- (void)toggleChanged:(UISwitch *)sender { self.item.enabled = sender.isOn; }
@end

@interface WTSettingsController () <UISearchBarDelegate>
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIStackView *contentStack;
@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic, strong) NSArray<WTSettingItem *> *allItems;
@end

@implementation WTSettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"wtchet";
    self.view.backgroundColor = [UIColor colorWithRed:0.88 green:0.94 blue:0.91 alpha:1];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"日志" style:UIBarButtonItemStylePlain target:self action:@selector(showLogPlaceholder)];
    [self buildItems];
    [self buildInterface];
    [self renderItems:self.allItems];
}

- (WTSettingItem *)item:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol toggle:(BOOL)toggle enabled:(BOOL)enabled {
    WTSettingItem *item = [WTSettingItem new];
    item.title = title; item.subtitle = subtitle; item.symbol = symbol; item.isToggle = toggle; item.enabled = enabled;
    return item;
}

- (void)buildItems {
    self.allItems = @[
      [self item:@"总开关" subtitle:@"Liquid Glass" symbol:@"sparkles" toggle:YES enabled:YES],
      [self item:@"开启磨砂" subtitle:@"关闭强制液态效果" symbol:@"drop.fill" toggle:YES enabled:NO],
      [self item:@"常规设置" subtitle:@"菜单 / 手势" symbol:@"slider.horizontal.3" toggle:NO enabled:NO],
      [self item:@"磨砂设置" subtitle:@"顶栏背景 / 渐隐" symbol:@"circle.grid.3x3.fill" toggle:NO enabled:NO],
      [self item:@"下载中心" subtitle:@"气泡 / 卡片 / 图标" symbol:@"square.and.arrow.down.fill" toggle:NO enabled:NO],
      [self item:@"主题中心" subtitle:@"已导入气泡 / 卡片 / 图标" symbol:@"square.grid.2x2.fill" toggle:NO enabled:NO],
      [self item:@"分组" subtitle:@"液态 / QQ / 全屏 / 侧边" symbol:@"folder.fill" toggle:NO enabled:NO],
      [self item:@"气泡/合并/引用" subtitle:@"液态 / 流光 / 合并" symbol:@"bubble.left.and.bubble.right.fill" toggle:NO enabled:NO],
      [self item:@"顶栏设置/美化" subtitle:@"标题 / 头像 / 渐隐" symbol:@"rectangle.topthird.inset.filled" toggle:NO enabled:NO],
      [self item:@"悬浮底栏设置/美化" subtitle:@"底栏 / 搜索" symbol:@"rectangle.bottomthird.inset.filled" toggle:NO enabled:NO],
      [self item:@"输入框设置/美化" subtitle:@"胶囊 / 短信 / TG" symbol:@"character.cursor.ibeam" toggle:NO enabled:NO],
      [self item:@"我的页面设置/美化" subtitle:@"HTML 卡片" symbol:@"person.text.rectangle.fill" toggle:NO enabled:NO],
      [self item:@"朋友圈设置/美化" subtitle:@"功能迁移 / 自定义美化" symbol:@"camera.aperture" toggle:NO enabled:NO],
      [self item:@"发现页设置/美化" subtitle:@"头像 / 功能键 / 整页卡片" symbol:@"safari.fill" toggle:NO enabled:NO],
      [self item:@"通讯录设置/美化" subtitle:@"收纳 / 搜索框 / 顶部美化" symbol:@"person.2.fill" toggle:NO enabled:NO],
      [self item:@"资料/详情页设置" subtitle:@"液态详情 / 私聊页 / 大头像" symbol:@"person.crop.square.fill" toggle:NO enabled:NO],
      [self item:@"圆角与列表" subtitle:@"圆角 / 列表 / 改色" symbol:@"rectangle.roundedtop" toggle:NO enabled:NO],
      [self item:@"壁纸" subtitle:@"浅色 / 深色" symbol:@"photo.fill" toggle:NO enabled:NO],
      [self item:@"主页卡片/胶囊" subtitle:@"文字 / 头像 / 胶囊 / 功能" symbol:@"line.3.horizontal" toggle:NO enabled:NO],
      [self item:@"头像" subtitle:@"群聊 / 私信隐藏" symbol:@"person.crop.circle" toggle:NO enabled:NO],
      [self item:@"字体替换" subtitle:@"导入 / 选择 / 网页同步" symbol:@"textformat" toggle:NO enabled:NO],
      [self item:@"公众号" subtitle:@"跳转公众号" symbol:@"megaphone.fill" toggle:NO enabled:NO],
      [self item:@"授权联系公众号" subtitle:@"授权功能请私信公众号" symbol:@"envelope.fill" toggle:NO enabled:NO],
      [self item:@"备份/恢复/恢复配置" subtitle:@"统一管理插件配置" symbol:@"arrow.triangle.2.circlepath.icloud.fill" toggle:NO enabled:NO]
    ];
}

- (void)buildInterface {
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.backgroundColor = UIColor.clearColor;

    self.scrollView = [UIScrollView new];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    self.contentStack = [UIStackView new];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 15;
    [self.scrollView addSubview:self.contentStack];

    [NSLayoutConstraint activateConstraints:@[
      [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
      [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14],
      [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14],
      [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-92],
      [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:8],
      [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
      [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
      [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-12],
      [self.contentStack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor]
    ]];

    UIVisualEffectView *header = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialLight]];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.layer.cornerRadius = 28;
    header.clipsToBounds = YES;
    UILabel *brand = [UILabel new];
    brand.translatesAutoresizingMaskIntoConstraints = NO;
    brand.text = @"wtchet";
    brand.font = [UIFont systemFontOfSize:27 weight:UIFontWeightBold];
    brand.textAlignment = NSTextAlignmentCenter;
    UILabel *caption = [UILabel new];
    caption.translatesAutoresizingMaskIntoConstraints = NO;
    caption.text = @"Liquid Glass · 设置中心";
    caption.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    caption.textColor = UIColor.secondaryLabelColor;
    caption.textAlignment = NSTextAlignmentCenter;
    [header.contentView addSubview:brand];
    [header.contentView addSubview:caption];
    [NSLayoutConstraint activateConstraints:@[
      [brand.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
      [brand.topAnchor constraintEqualToAnchor:header.topAnchor constant:17],
      [caption.centerXAnchor constraintEqualToAnchor:header.centerXAnchor],
      [caption.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:4],
      [caption.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-15]
    ]];
    [self.contentStack addArrangedSubview:header];
    [header.heightAnchor constraintEqualToConstant:88].active = YES;

    self.searchBar = [UISearchBar new];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"搜索插件设置";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.backgroundImage = [UIImage new];
    self.searchBar.layer.cornerRadius = 23;
    self.searchBar.clipsToBounds = YES;
    [self.view addSubview:self.searchBar];
    [NSLayoutConstraint activateConstraints:@[
      [self.searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:22],
      [self.searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-22],
      [self.searchBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-5],
      [self.searchBar.heightAnchor constraintEqualToConstant:55]
    ]];
}

- (void)renderItems:(NSArray<WTSettingItem *> *)items {
    UIView *header = self.contentStack.arrangedSubviews.firstObject;
    for (UIView *view in self.contentStack.arrangedSubviews.copy) {
        if (view != header) {
            [self.contentStack removeArrangedSubview:view];
            [view removeFromSuperview];
        }
    }
    for (NSUInteger i = 0; i < items.count; i += 2) {
        UIStackView *row = [UIStackView new];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 14;
        row.distribution = UIStackViewDistributionFillEqually;
        for (NSUInteger j = i; j < MIN(i + 2, items.count); j++) {
            WTSettingsCard *card = [[WTSettingsCard alloc] initWithItem:items[j]];
            [card addTarget:self action:@selector(cardTapped:) forControlEvents:UIControlEventTouchUpInside];
            [row addArrangedSubview:card];
            [card.heightAnchor constraintEqualToConstant:112].active = YES;
        }
        if (items.count % 2 && i + 1 >= items.count) [row addArrangedSubview:[UIView new]];
        [self.contentStack addArrangedSubview:row];
    }
}

- (void)cardTapped:(WTSettingsCard *)card {
    if ([card.item.title containsString:@"输入框"]) {
        WTInputSettingsController *input = [WTInputSettingsController new];
        [self.navigationController pushViewController:input animated:YES];
        return;
    }
    if (card.item.isToggle) return;
    UIViewController *placeholder = [UIViewController new];
    placeholder.view.backgroundColor = [UIColor colorWithRed:0.89 green:0.94 blue:0.92 alpha:1];
    placeholder.title = card.item.title;
    UIVisualEffectView *panel = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.layer.cornerRadius = 26;
    panel.clipsToBounds = YES;
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"该设置项的界面入口已预留\n具体功能将在后续版本逐项实现";
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    label.textColor = UIColor.secondaryLabelColor;
    [panel.contentView addSubview:label];
    [placeholder.view addSubview:panel];
    [NSLayoutConstraint activateConstraints:@[
      [panel.leadingAnchor constraintEqualToAnchor:placeholder.view.leadingAnchor constant:22],
      [panel.trailingAnchor constraintEqualToAnchor:placeholder.view.trailingAnchor constant:-22],
      [panel.centerYAnchor constraintEqualToAnchor:placeholder.view.centerYAnchor],
      [panel.heightAnchor constraintEqualToConstant:190],
      [label.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
      [label.centerYAnchor constraintEqualToAnchor:panel.centerYAnchor],
      [label.leadingAnchor constraintGreaterThanOrEqualToAnchor:panel.leadingAnchor constant:15],
      [label.trailingAnchor constraintLessThanOrEqualToAnchor:panel.trailingAnchor constant:-15]
    ]];
    [self.navigationController pushViewController:placeholder animated:YES];
}

- (void)showLogPlaceholder {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"wtchet 日志" message:@"当前为设置界面原型版本，日志模块尚未接入。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!searchText.length) { [self renderItems:self.allItems]; return; }
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(WTSettingItem *item, NSDictionary *bindings) {
        return [item.title localizedCaseInsensitiveContainsString:searchText] || [item.subtitle localizedCaseInsensitiveContainsString:searchText];
    }];
    [self renderItems:[self.allItems filteredArrayUsingPredicate:predicate]];
}
@end
