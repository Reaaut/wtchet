#import "WTInputSettingsController.h"

static NSString * const WTInputEnabledKey = @"wt.input.enabled";
static NSString * const WTInputPlaceholderEnabledKey = @"wt.input.placeholder.enabled";
static NSString * const WTInputPlaceholderTextKey = @"wt.input.placeholder.text";
static NSString * const WTInputJellyMenuKey = @"wt.input.jelly.menu";
static NSString * const WTInputSMSKey = @"wt.input.sms.enabled";
static NSString * const WTInputSMSSizeKey = @"wt.input.sms.size";
static NSString * const WTInputSMSEmojiKey = @"wt.input.sms.hideEmoji";
static NSString * const WTInputSMSIconKey = @"wt.input.sms.icon";
static NSString * const WTInputStyleKey = @"wt.input.preview.style";

@interface WTInputSettingsController ()
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic,strong) UIVisualEffectView *preview;
@property(nonatomic,strong) UILabel *previewText;
@property(nonatomic,strong) UIView *previewPill;
@property(nonatomic,strong) UISegmentedControl *styleControl;
@end

@implementation WTInputSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"输入框设置/美化";
    self.view.backgroundColor = [UIColor colorWithRed:0.91 green:0.95 blue:0.93 alpha:1];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self buildPage];
}

- (BOOL)valueForKey:(NSString *)key fallback:(BOOL)fallback {
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    return [d objectForKey:key] ? [d boolForKey:key] : fallback;
}
- (void)setBool:(BOOL)value key:(NSString *)key {
    [NSUserDefaults.standardUserDefaults setBool:value forKey:key];
}
- (UIColor *)green {
    return [UIColor colorWithRed:0.04 green:0.43 blue:0.27 alpha:1];
}
- (UIVisualEffectView *)glassPanel {
    UIVisualEffectView *v = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
    v.layer.cornerRadius = 22;
    v.layer.cornerCurve = kCACornerCurveContinuous;
    v.layer.borderWidth = 1;
    v.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.68].CGColor;
    v.clipsToBounds = YES;
    return v;
}
- (void)buildPage {
    self.scroll = [UIScrollView new];
    self.scroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.scroll.alwaysBounceVertical = YES;
    [self.view addSubview:self.scroll];
    self.stack = [UIStackView new];
    self.stack.translatesAutoresizingMaskIntoConstraints = NO;
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.spacing = 16;
    [self.scroll addSubview:self.stack];
    [NSLayoutConstraint activateConstraints:@[
        [self.scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.stack.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor],
        [self.stack.leadingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.leadingAnchor],
        [self.stack.trailingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.trailingAnchor],
        [self.stack.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor constant:-24],
        [self.stack.widthAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.widthAnchor]
    ]];

    [self addSectionTitle:@"基础输入框"];
    UIVisualEffectView *base = [self glassPanel];
    UIStackView *baseRows = [self rowsStack];
    [base.contentView addSubview:baseRows];
    [NSLayoutConstraint activateConstraints:@[
        [baseRows.topAnchor constraintEqualToAnchor:base.contentView.topAnchor constant:4],
        [baseRows.leadingAnchor constraintEqualToAnchor:base.contentView.leadingAnchor constant:16],
        [baseRows.trailingAnchor constraintEqualToAnchor:base.contentView.trailingAnchor constant:-16],
        [baseRows.bottomAnchor constraintEqualToAnchor:base.contentView.bottomAnchor constant:-4]
    ]];
    [baseRows addArrangedSubview:[self switchRow:@"输入框美化总开关" detail:@"开启后应用自定义输入框外观" key:WTInputEnabledKey fallback:YES]];
    [baseRows addArrangedSubview:[self switchRow:@"输入框占位符" detail:@"显示自定义的发送提示文字" key:WTInputPlaceholderEnabledKey fallback:NO]];
    [baseRows addArrangedSubview:[self actionRow:@"占位符文字" detail:[NSUserDefaults.standardUserDefaults stringForKey:WTInputPlaceholderTextKey] ?: @"发送消息" action:@selector(editPlaceholder)]];
    [baseRows addArrangedSubview:[self switchRow:@"输入框加号液态菜单" detail:@"保留微信原生菜单行为，仅预留外观开关" key:WTInputJellyMenuKey fallback:NO]];
    [self.stack addArrangedSubview:base];

    [self addSectionTitle:@"样式预览"];
    UIVisualEffectView *previewCard = [self glassPanel];
    previewCard.translatesAutoresizingMaskIntoConstraints = NO;
    UIStackView *previewContent = [self rowsStack];
    [previewCard.contentView addSubview:previewContent];
    [NSLayoutConstraint activateConstraints:@[
        [previewContent.topAnchor constraintEqualToAnchor:previewCard.contentView.topAnchor constant:14],
        [previewContent.leadingAnchor constraintEqualToAnchor:previewCard.contentView.leadingAnchor constant:14],
        [previewContent.trailingAnchor constraintEqualToAnchor:previewCard.contentView.trailingAnchor constant:-14],
        [previewContent.bottomAnchor constraintEqualToAnchor:previewCard.contentView.bottomAnchor constant:-14]
    ]];
    self.styleControl = [[UISegmentedControl alloc] initWithItems:@[@"简约",@"大胶囊",@"小胶囊"]];
    NSInteger savedStyle = [NSUserDefaults.standardUserDefaults integerForKey:WTInputStyleKey];
    self.styleControl.selectedSegmentIndex = MIN(savedStyle, 2);
    [self.styleControl addTarget:self action:@selector(styleChanged:) forControlEvents:UIControlEventValueChanged];
    [previewContent addArrangedSubview:self.styleControl];
    UIView *sample = [self previewComposer];
    [previewContent addArrangedSubview:sample];
    UILabel *note = [UILabel new];
    note.text = @"样式将同步应用到微信聊天输入栏；此版本先实现磨砂背景与圆角";
    note.font = [UIFont systemFontOfSize:12];
    note.textColor = UIColor.secondaryLabelColor;
    note.textAlignment = NSTextAlignmentCenter;
    note.numberOfLines = 0;
    [previewContent addArrangedSubview:note];
    [self.stack addArrangedSubview:previewCard];

    [self addSectionTitle:@"短信输入框"];
    UIVisualEffectView *sms = [self glassPanel];
    UIStackView *smsRows = [self rowsStack];
    [sms.contentView addSubview:smsRows];
    [NSLayoutConstraint activateConstraints:@[
        [smsRows.topAnchor constraintEqualToAnchor:sms.contentView.topAnchor constant:4],
        [smsRows.leadingAnchor constraintEqualToAnchor:sms.contentView.leadingAnchor constant:16],
        [smsRows.trailingAnchor constraintEqualToAnchor:sms.contentView.trailingAnchor constant:-16],
        [smsRows.bottomAnchor constraintEqualToAnchor:sms.contentView.bottomAnchor constant:-4]
    ]];
    [smsRows addArrangedSubview:[self switchRow:@"短信输入框" detail:@"单独启用短信风格布局（后续接入微信）" key:WTInputSMSKey fallback:NO]];
    [smsRows addArrangedSubview:[self optionRow:@"短信输入框大小" items:@[@"大",@"小"] key:WTInputSMSSizeKey]];
    [smsRows addArrangedSubview:[self switchRow:@"隐藏短信风格表情图标" detail:@"不影响点击区域的预留" key:WTInputSMSEmojiKey fallback:NO]];
    [smsRows addArrangedSubview:[self optionRow:@"短信风格图标" items:@[@"关",@"粗",@"细"] key:WTInputSMSIconKey]];
    [self.stack addArrangedSubview:sms];

    [self addSectionTitle:@"说明"];
    UILabel *foot = [UILabel new];
    foot.text = @"当前版本已加入聊天页输入栏的保守识别与磨砂背景层。短信风格、占位符替换、加号菜单和工具栏细节仍为后续开发项。";
    foot.font = [UIFont systemFontOfSize:12];
    foot.textColor = UIColor.secondaryLabelColor;
    foot.numberOfLines = 0;
    foot.textAlignment = NSTextAlignmentCenter;
    [self.stack addArrangedSubview:foot];
}

- (UIStackView *)rowsStack {
    UIStackView *s = [UIStackView new];
    s.translatesAutoresizingMaskIntoConstraints = NO;
    s.axis = UILayoutConstraintAxisVertical;
    s.spacing = 0;
    return s;
}
- (void)addSectionTitle:(NSString *)title {
    UILabel *l = [UILabel new];
    l.text = title;
    l.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    l.textColor = [UIColor secondaryLabelColor];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    [self.stack addArrangedSubview:l];
    [l.heightAnchor constraintEqualToConstant:22].active = YES;
}
- (UIView *)switchRow:(NSString *)title detail:(NSString *)detail key:(NSString *)key fallback:(BOOL)fallback {
    UIView *row = [UIView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *t = [UILabel new]; t.translatesAutoresizingMaskIntoConstraints = NO;
    t.text = title; t.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    UILabel *sub = [UILabel new]; sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.text = detail; sub.font = [UIFont systemFontOfSize:12]; sub.textColor = UIColor.secondaryLabelColor;
    UISwitch *sw = [UISwitch new]; sw.translatesAutoresizingMaskIntoConstraints = NO;
    sw.onTintColor = self.green; sw.on = [self valueForKey:key fallback:fallback];
    sw.accessibilityIdentifier = key;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:t]; [row addSubview:sub]; [row addSubview:sw];
    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintEqualToConstant:66],
        [t.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [t.topAnchor constraintEqualToAnchor:row.topAnchor constant:12],
        [t.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-8],
        [sub.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],
        [sub.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:3],
        [sub.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-8],
        [sw.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [sw.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]
    ]];
    return row;
}
- (UIView *)actionRow:(NSString *)title detail:(NSString *)detail action:(SEL)action {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UILabel *t = [UILabel new]; t.text = title; t.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    UILabel *d = [UILabel new]; d.text = detail; d.font = [UIFont systemFontOfSize:12]; d.textColor = UIColor.secondaryLabelColor;
    UIStackView *v = [[UIStackView alloc] initWithArrangedSubviews:@[t,d]];
    v.translatesAutoresizingMaskIntoConstraints = NO; v.axis = UILayoutConstraintAxisVertical; v.spacing = 4;
    UIImageView *chev = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    chev.translatesAutoresizingMaskIntoConstraints = NO; chev.tintColor = UIColor.tertiaryLabelColor;
    [b addSubview:v]; [b addSubview:chev];
    [NSLayoutConstraint activateConstraints:@[
        [b.heightAnchor constraintEqualToConstant:62],
        [v.leadingAnchor constraintEqualToAnchor:b.leadingAnchor],
        [v.centerYAnchor constraintEqualToAnchor:b.centerYAnchor],
        [v.trailingAnchor constraintLessThanOrEqualToAnchor:chev.leadingAnchor constant:-8],
        [chev.trailingAnchor constraintEqualToAnchor:b.trailingAnchor],
        [chev.centerYAnchor constraintEqualToAnchor:b.centerYAnchor],
        [chev.widthAnchor constraintEqualToConstant:10]
    ]];
    return b;
}
- (UIView *)optionRow:(NSString *)title items:(NSArray<NSString *> *)items key:(NSString *)key {
    UIView *row = [UIView new]; row.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *l = [UILabel new]; l.translatesAutoresizingMaskIntoConstraints = NO;
    l.text = title; l.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];
    seg.translatesAutoresizingMaskIntoConstraints = NO;
    NSInteger saved = [NSUserDefaults.standardUserDefaults integerForKey:key];
    seg.selectedSegmentIndex = MIN(saved, items.count - 1);
    seg.accessibilityIdentifier = key;
    [seg addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:l]; [row addSubview:seg];
    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintEqualToConstant:58],
        [l.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [l.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [seg.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
        [seg.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [seg.widthAnchor constraintEqualToConstant:150],
        [l.trailingAnchor constraintLessThanOrEqualToAnchor:seg.leadingAnchor constant:-8]
    ]];
    return row;
}
- (UIView *)previewComposer {
    UIView *wrap = [UIView new]; wrap.translatesAutoresizingMaskIntoConstraints = NO;
    [wrap.heightAnchor constraintEqualToConstant:72].active = YES;
    UIView *pill = [UIView new]; pill.translatesAutoresizingMaskIntoConstraints = NO;
    pill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.30];
    pill.layer.cornerCurve = kCACornerCurveContinuous;
    pill.layer.borderWidth = 1;
    pill.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    pill.layer.shadowColor = UIColor.blackColor.CGColor;
    pill.layer.shadowOpacity = 0.06; pill.layer.shadowRadius = 8;
    [wrap addSubview:pill];
    UILabel *voice = [UILabel new]; voice.translatesAutoresizingMaskIntoConstraints = NO;
    voice.text = @"◖))"; voice.font = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
    UILabel *placeholder = [UILabel new]; placeholder.translatesAutoresizingMaskIntoConstraints = NO;
    placeholder.text = @"发送消息"; placeholder.textColor = UIColor.secondaryLabelColor;
    placeholder.font = [UIFont systemFontOfSize:15];
    UILabel *tools = [UILabel new]; tools.translatesAutoresizingMaskIntoConstraints = NO;
    tools.text = @"☻  ⊕"; tools.font = [UIFont systemFontOfSize:20];
    [pill addSubview:voice]; [pill addSubview:placeholder]; [pill addSubview:tools];
    [NSLayoutConstraint activateConstraints:@[
        [pill.leadingAnchor constraintEqualToAnchor:wrap.leadingAnchor constant:5],
        [pill.trailingAnchor constraintEqualToAnchor:wrap.trailingAnchor constant:-5],
        [pill.centerYAnchor constraintEqualToAnchor:wrap.centerYAnchor],
        [pill.heightAnchor constraintEqualToConstant:48],
        [voice.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:14],
        [voice.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
        [placeholder.leadingAnchor constraintEqualToAnchor:voice.trailingAnchor constant:13],
        [placeholder.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
        [tools.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-13],
        [tools.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor],
        [placeholder.trailingAnchor constraintLessThanOrEqualToAnchor:tools.leadingAnchor constant:-8]
    ]];
    self.previewPill = pill; self.previewText = placeholder;
    [self applyPreviewStyle:self.styleControl.selectedSegmentIndex];
    return wrap;
}
- (void)applyPreviewStyle:(NSInteger)style {
    self.previewPill.layer.cornerRadius = style == 2 ? 18 : 25;
    self.previewPill.transform = style == 1 ? CGAffineTransformMakeScale(1.0,1.12) : CGAffineTransformIdentity;
    self.previewText.text = [NSUserDefaults.standardUserDefaults stringForKey:WTInputPlaceholderTextKey] ?: @"发送消息";
}
- (void)switchChanged:(UISwitch *)sender {
    [self setBool:sender.isOn key:sender.accessibilityIdentifier];
}
- (void)optionChanged:(UISegmentedControl *)sender {
    [NSUserDefaults.standardUserDefaults setInteger:sender.selectedSegmentIndex forKey:sender.accessibilityIdentifier];
}
- (void)styleChanged:(UISegmentedControl *)sender {
    [NSUserDefaults.standardUserDefaults setInteger:sender.selectedSegmentIndex forKey:WTInputStyleKey];
    [self applyPreviewStyle:sender.selectedSegmentIndex];
}
- (void)editPlaceholder {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"占位符文字" message:@"设置聊天输入框的提示文字" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f) {
        f.text = [NSUserDefaults.standardUserDefaults stringForKey:WTInputPlaceholderTextKey] ?: @"发送消息";
        f.placeholder = @"输入提示文字";
    }];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *v = a.textFields.firstObject.text ?: @"发送消息";
        [NSUserDefaults.standardUserDefaults setObject:v forKey:WTInputPlaceholderTextKey];
        self.previewText.text = v;
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
@end
