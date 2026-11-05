#import "WTInputSettingsController.h"

static NSString * const kEnabled = @"wt.input.enabled";
static NSString * const kStyle = @"wt.input.preview.style";
static NSString * const kPlaceholderOn = @"wt.input.placeholder.enabled";
static NSString * const kPlaceholder = @"wt.input.placeholder.text";
static NSString * const kJelly = @"wt.input.jelly.menu";
static NSString * const kSMS = @"wt.input.sms.enabled";
static NSString * const kSMSSize = @"wt.input.sms.size";
static NSString * const kHideEmoji = @"wt.input.sms.hideEmoji";
static NSString * const kSMSIcon = @"wt.input.sms.icon";
static NSString * const kGlow = @"wt.input.glow.enabled";
static NSString * const kGlowSpeed = @"wt.input.glow.speed";
static NSString * const kGlowColor = @"wt.input.glow.color";
static NSString * const kBlur = @"wt.input.blur.enabled";
static NSString * const kOffset = @"wt.input.offsetY";
static NSString * const kIconColor = @"wt.input.icon.color";
static NSString * const kMenuTheme = @"wt.input.jelly.theme";
static NSString * const kFade = @"wt.input.fade.enabled";
static NSString * const kNativeBG = @"wt.input.nativeBackground.hide";
static NSString * const kOuterBlur = @"wt.input.outerBlur.enabled";
static NSString * const kOuterRound = @"wt.input.outerBlur.rounded";
static NSString * const kMethod = @"wt.input.method.enabled";
static NSString * const kMethodBG = @"wt.input.method.hideBackground";
static NSString * const kMethodBlur = @"wt.input.method.blur";
static NSString * const kMethodRound = @"wt.input.method.rounded";
static void WTPostInputSettingsChanged(void) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wt.input.settings.changed" object:nil];
}

@interface WTInputSettingsController ()
@property(nonatomic,strong) UIScrollView *scroll;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic,strong) UISegmentedControl *style;
@property(nonatomic,strong) UIView *previewPill;
@property(nonatomic,strong) UILabel *previewPlaceholder;
@property(nonatomic,strong) UIVisualEffectView *previewGlass;
@property(nonatomic,strong) UISlider *glowSlider;
@property(nonatomic,strong) UIButton *showButton;
@end

@implementation WTInputSettingsController

- (UIColor *)green { return [UIColor colorWithRed:0.02 green:0.53 blue:0.30 alpha:1]; }
- (BOOL)flag:(NSString *)key fallback:(BOOL)value {
    return [NSUserDefaults.standardUserDefaults objectForKey:key] ? [NSUserDefaults.standardUserDefaults boolForKey:key] : value;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"输入框设置/美化";
    self.view.backgroundColor = [UIColor colorWithRed:0.88 green:0.94 blue:0.91 alpha:1];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"chevron.left"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self buildPage];
}
- (void)goBack { [self.navigationController popViewControllerAnimated:YES]; }

- (UIVisualEffectView *)panel {
    UIVisualEffectView *v = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialLight]];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.layer.cornerRadius = 24; v.layer.cornerCurve = kCACornerCurveContinuous;
    v.layer.borderWidth = 1; v.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.72].CGColor;
    v.clipsToBounds = YES;
    return v;
}
- (UIStackView *)verticalStack {
    UIStackView *s = [UIStackView new]; s.translatesAutoresizingMaskIntoConstraints = NO;
    s.axis = UILayoutConstraintAxisVertical; s.spacing = 0;
    return s;
}
- (void)addHeading:(NSString *)text {
    UILabel *l = [UILabel new]; l.translatesAutoresizingMaskIntoConstraints = NO;
    l.text = text; l.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    l.textColor = [UIColor secondaryLabelColor];
    [self.stack addArrangedSubview:l]; [l.heightAnchor constraintEqualToConstant:30].active = YES;
}
- (void)addPanel:(UIVisualEffectView *)panel content:(UIView *)content inset:(CGFloat)inset {
    [panel.contentView addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [content.topAnchor constraintEqualToAnchor:panel.contentView.topAnchor constant:inset],
        [content.leadingAnchor constraintEqualToAnchor:panel.contentView.leadingAnchor constant:16],
        [content.trailingAnchor constraintEqualToAnchor:panel.contentView.trailingAnchor constant:-16],
        [content.bottomAnchor constraintEqualToAnchor:panel.contentView.bottomAnchor constant:-inset]
    ]];
    [self.stack addArrangedSubview:panel];
}
- (UIView *)switchRow:(NSString *)title detail:(NSString *)detail key:(NSString *)key fallback:(BOOL)fallback {
    UIView *row=[UIView new]; row.translatesAutoresizingMaskIntoConstraints=NO;
    UILabel *t=[UILabel new]; t.translatesAutoresizingMaskIntoConstraints=NO; t.text=title; t.font=[UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    UILabel *d=[UILabel new]; d.translatesAutoresizingMaskIntoConstraints=NO; d.text=detail; d.font=[UIFont systemFontOfSize:12]; d.textColor=UIColor.secondaryLabelColor;
    UISwitch *sw=[UISwitch new]; sw.translatesAutoresizingMaskIntoConstraints=NO; sw.onTintColor=self.green; sw.on=[self flag:key fallback:fallback]; sw.accessibilityIdentifier=key;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:t]; [row addSubview:d]; [row addSubview:sw];
    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintEqualToConstant:66],
        [t.leadingAnchor constraintEqualToAnchor:row.leadingAnchor], [t.topAnchor constraintEqualToAnchor:row.topAnchor constant:10],
        [t.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-10],
        [d.leadingAnchor constraintEqualToAnchor:t.leadingAnchor], [d.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:3],
        [d.trailingAnchor constraintLessThanOrEqualToAnchor:sw.leadingAnchor constant:-10],
        [sw.trailingAnchor constraintEqualToAnchor:row.trailingAnchor], [sw.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]
    ]];
    return row;
}
- (UIView *)disclosureRow:(NSString *)title detail:(NSString *)detail action:(SEL)action {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; b.translatesAutoresizingMaskIntoConstraints=NO;
    [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UILabel *t=[UILabel new]; t.text=title; t.font=[UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    UILabel *d=[UILabel new]; d.text=detail; d.font=[UIFont systemFontOfSize:12]; d.textColor=UIColor.secondaryLabelColor;
    UIStackView *v=[[UIStackView alloc] initWithArrangedSubviews:@[t,d]]; v.translatesAutoresizingMaskIntoConstraints=NO; v.axis=UILayoutConstraintAxisVertical; v.spacing=3;
    UIImageView *chev=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]]; chev.translatesAutoresizingMaskIntoConstraints=NO; chev.tintColor=UIColor.tertiaryLabelColor;
    [b addSubview:v]; [b addSubview:chev];
    [NSLayoutConstraint activateConstraints:@[
        [b.heightAnchor constraintEqualToConstant:64], [v.leadingAnchor constraintEqualToAnchor:b.leadingAnchor],
        [v.centerYAnchor constraintEqualToAnchor:b.centerYAnchor], [v.trailingAnchor constraintLessThanOrEqualToAnchor:chev.leadingAnchor constant:-8],
        [chev.trailingAnchor constraintEqualToAnchor:b.trailingAnchor], [chev.centerYAnchor constraintEqualToAnchor:b.centerYAnchor],
        [chev.widthAnchor constraintEqualToConstant:14], [chev.heightAnchor constraintEqualToConstant:14]
    ]];
    return b;
}

- (void)captureInputHierarchy {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wt.input.hierarchy.capture" object:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.8*NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        NSString *dump=[NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.hierarchy.lastCapture"];
        if(dump.length) {
            UIPasteboard.generalPasteboard.string=dump;
            UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"结构采集完成" message:@"已复制当前界面视图结构。请回到微信聊天页面，粘贴发送给我。不会采集聊天文字或消息内容。" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"采集失败" message:@"没有取得视图结构，请在聊天页面打开设置后重试。" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}
- (void)buildPage {
    self.scroll=[UIScrollView new]; self.scroll.translatesAutoresizingMaskIntoConstraints=NO; self.scroll.alwaysBounceVertical=YES;
    [self.view addSubview:self.scroll];
    self.stack=[self verticalStack]; [self.scroll addSubview:self.stack];
    [NSLayoutConstraint activateConstraints:@[
        [self.scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:4],
        [self.scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [self.scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [self.scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-88],
        [self.stack.topAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.topAnchor],
        [self.stack.leadingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.leadingAnchor],
        [self.stack.trailingAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.trailingAnchor],
        [self.stack.bottomAnchor constraintEqualToAnchor:self.scroll.contentLayoutGuide.bottomAnchor constant:-22],
        [self.stack.widthAnchor constraintEqualToAnchor:self.scroll.frameLayoutGuide.widthAnchor]
    ]];

    [self addHeading:@"问题诊断"];
    UIVisualEffectView *diagnostic=[self panel]; UIStackView *diagnosticRows=[self verticalStack];
    [diagnosticRows addArrangedSubview:[self disclosureRow:@"采集输入栏结构" detail:@"复制当前微信界面视图层级，不读取聊天内容" action:@selector(captureInputHierarchy)]];
    [self addPanel:diagnostic content:diagnosticRows inset:0];

    [self addHeading:@"输入框"];
    UIVisualEffectView *base=[self panel]; UIStackView *baseRows=[self verticalStack];
    [baseRows addArrangedSubview:[self switchRow:@"输入框胶囊" detail:@"输入框样式总开关" key:kEnabled fallback:YES]];
    UIView *line=[UIView new]; line.backgroundColor=[UIColor colorWithWhite:1 alpha:0.75]; [line.heightAnchor constraintEqualToConstant:1].active=YES; [baseRows addArrangedSubview:line];
    [baseRows addArrangedSubview:[self disclosureRow:@"展开" detail:@"输入框样式、布局选项" action:@selector(scrollToStyle)]];
    [baseRows addArrangedSubview:[self switchRow:@"输入栏磨砂背景" detail:@"使用系统薄磨砂材质" key:kBlur fallback:YES]];
    [baseRows addArrangedSubview:[self switchRow:@"输入框渐隐背景" detail:@"在输入栏叠加柔和渐变层" key:kFade fallback:NO]];
    [baseRows addArrangedSubview:[self optionRow:@"按钮图标颜色" items:@[@"深色",@"绿色",@"白色"] key:kIconColor]];
    [baseRows addArrangedSubview:[self disclosureRow:@"发送键颜色" detail:@"自定义发送按钮颜色" action:@selector(chooseSendColor)]];
    [baseRows addArrangedSubview:[self disclosureRow:@"输入光标颜色" detail:@"自定义输入光标颜色" action:@selector(chooseCursorColor)]];
    [baseRows addArrangedSubview:[self disclosureRow:@"输入文字颜色" detail:@"自定义输入文字颜色" action:@selector(chooseTextColor)]];
    [baseRows addArrangedSubview:[self sliderRow:@"输入栏上下位置" detail:@"微调输入栏垂直位置" key:kOffset min:-20 max:20 fallback:0]];
    [self addPanel:base content:baseRows inset:0];

    [self addHeading:@"输入法功能区"];
    UIVisualEffectView *method=[self panel]; UIStackView *methodRows=[self verticalStack];
    [methodRows addArrangedSubview:[self switchRow:@"输入法功能区美化" detail:@"单独控制键盘上方的输入法工具区域" key:kMethod fallback:YES]];
    [methodRows addArrangedSubview:[self switchRow:@"隐藏原生底板" detail:@"去除微信输入栏外层原生纯色背景" key:kNativeBG fallback:YES]];
    [methodRows addArrangedSubview:[self switchRow:@"外层毛玻璃背景" detail:@"为输入栏底部区域添加系统磨砂" key:kOuterBlur fallback:YES]];
    [methodRows addArrangedSubview:[self switchRow:@"外层背景圆角" detail:@"输入区域采用连续圆角边缘" key:kOuterRound fallback:YES]];
    [methodRows addArrangedSubview:[self switchRow:@"隐藏输入法原生背景" detail:@"仅作用于识别到的键盘工具栏" key:kMethodBG fallback:YES]];
    [methodRows addArrangedSubview:[self switchRow:@"输入法区域毛玻璃" detail:@"为输入法工具栏添加薄磨砂材质" key:kMethodBlur fallback:YES]];
    [methodRows addArrangedSubview:[self switchRow:@"输入法区域圆角" detail:@"输入法工具栏使用连续圆角" key:kMethodRound fallback:YES]];
    [self addPanel:method content:methodRows inset:0];

    [self addHeading:@"样式预览"];
    UIVisualEffectView *sampleCard=[self panel]; UIStackView *sampleRows=[self verticalStack];
    self.style=[[UISegmentedControl alloc] initWithItems:@[@"简约",@"大胶囊",@"小胶囊"]];
    NSInteger saved=[NSUserDefaults.standardUserDefaults integerForKey:kStyle]; self.style.selectedSegmentIndex=MIN(saved,2);
    [self.style addTarget:self action:@selector(styleChanged:) forControlEvents:UIControlEventValueChanged];
    [sampleRows addArrangedSubview:self.style]; [self.style.heightAnchor constraintEqualToConstant:34].active=YES;
    [sampleRows addArrangedSubview:[self composerPreview]];
    UILabel *hint=[UILabel new]; hint.text=@"预览与微信聊天输入栏同步使用当前样式"; hint.textColor=UIColor.secondaryLabelColor; hint.font=[UIFont systemFontOfSize:11]; hint.textAlignment=NSTextAlignmentCenter;
    [sampleRows addArrangedSubview:hint]; [hint.heightAnchor constraintEqualToConstant:22].active=YES;
    [self addPanel:sampleCard content:sampleRows inset:14];

    [self addHeading:@"TG 菜单"];
    UIVisualEffectView *tg=[self panel]; UIStackView *tgRows=[self verticalStack];
    [tgRows addArrangedSubview:[self switchRow:@"TG 菜单" detail:@"启用胶囊式附加菜单外观" key:kJelly fallback:NO]];
    [tgRows addArrangedSubview:[self optionRow:@"TG 菜单材质" items:@[@"系统",@"浅色",@"深色"] key:kMenuTheme]];
    [self addPanel:tg content:tgRows inset:0];

    [self addHeading:@"输入框炫光"];
    UIVisualEffectView *glow=[self panel]; UIStackView *glowRows=[self verticalStack];
    [glowRows addArrangedSubview:[self switchRow:@"输入框炫光" detail:@"沿输入框边缘显示柔和流光" key:kGlow fallback:NO]];
    [glowRows addArrangedSubview:[self sliderRow:@"炫光速度" detail:@"慢速 1.0 倍 · 快速 2.5 倍" key:kGlowSpeed min:0.5 max:2.5 fallback:1.0]];
    [glowRows addArrangedSubview:[self disclosureRow:@"炫光颜色" detail:@"选择绿色、蓝色、紫色或系统色" action:@selector(chooseGlowColor)]];
    [self addPanel:glow content:glowRows inset:0];

    [self addHeading:@"短信输入框"];
    UIVisualEffectView *sms=[self panel]; UIStackView *smsRows=[self verticalStack];
    [smsRows addArrangedSubview:[self switchRow:@"短信输入框" detail:@"使用更紧凑的短信式输入布局" key:kSMS fallback:NO]];
    [smsRows addArrangedSubview:[self optionRow:@"输入框大小" items:@[@"大",@"小"] key:kSMSSize]];
    [smsRows addArrangedSubview:[self switchRow:@"隐藏表情图标" detail:@"隐藏输入栏表情按钮外观" key:kHideEmoji fallback:NO]];
    [smsRows addArrangedSubview:[self optionRow:@"短信风格图标" items:@[@"默认",@"粗线",@"细线"] key:kSMSIcon]];
    [self addPanel:sms content:smsRows inset:0];

    [self addHeading:@"占位文字"];
    UIVisualEffectView *placeholder=[self panel]; UIStackView *phRows=[self verticalStack];
    [phRows addArrangedSubview:[self switchRow:@"自定义占位符" detail:@"替换输入框内的提示文字" key:kPlaceholderOn fallback:NO]];
    [phRows addArrangedSubview:[self disclosureRow:@"占位符内容" detail:[NSUserDefaults.standardUserDefaults stringForKey:kPlaceholder] ?: @"发送消息" action:@selector(editPlaceholder)]];
    [self addPanel:placeholder content:phRows inset:0];

    self.showButton=[UIButton buttonWithType:UIButtonTypeSystem]; self.showButton.translatesAutoresizingMaskIntoConstraints=NO;
    [self.showButton setTitle:@"◉  展示效果" forState:UIControlStateNormal]; self.showButton.titleLabel.font=[UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.showButton setTitleColor:[UIColor colorWithRed:0 green:0.48 blue:0.98 alpha:1] forState:UIControlStateNormal];
    self.showButton.backgroundColor=[UIColor colorWithWhite:1 alpha:0.72]; self.showButton.layer.cornerRadius=28; self.showButton.layer.borderWidth=1; self.showButton.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.85].CGColor;
    [self.showButton addTarget:self action:@selector(showEffect) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.showButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.showButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:28],
        [self.showButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-28],
        [self.showButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],
        [self.showButton.heightAnchor constraintEqualToConstant:54]
    ]];
}
- (UIView *)composerPreview {
    UIView *wrap=[UIView new]; wrap.translatesAutoresizingMaskIntoConstraints=NO; [wrap.heightAnchor constraintEqualToConstant:88].active=YES;
    UIVisualEffectView *glass=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialLight]];
    glass.translatesAutoresizingMaskIntoConstraints=NO; glass.layer.cornerRadius=26; glass.clipsToBounds=YES; glass.layer.borderWidth=1; glass.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.8].CGColor;
    [wrap addSubview:glass];
    [NSLayoutConstraint activateConstraints:@[[glass.leadingAnchor constraintEqualToAnchor:wrap.leadingAnchor constant:4],[glass.trailingAnchor constraintEqualToAnchor:wrap.trailingAnchor constant:-4],[glass.centerYAnchor constraintEqualToAnchor:wrap.centerYAnchor],[glass.heightAnchor constraintEqualToConstant:58]]];
    UIStackView *items=[UIStackView new]; items.translatesAutoresizingMaskIntoConstraints=NO; items.axis=UILayoutConstraintAxisHorizontal; items.alignment=UIStackViewAlignmentCenter; items.spacing=12;
    UIImageView *voice=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"waveform"]]; voice.tintColor=UIColor.labelColor; voice.contentMode=UIViewContentModeScaleAspectFit;
    self.previewPlaceholder=[UILabel new]; self.previewPlaceholder.text=[NSUserDefaults.standardUserDefaults stringForKey:kPlaceholder] ?: @"发送消息"; self.previewPlaceholder.textColor=UIColor.secondaryLabelColor; self.previewPlaceholder.font=[UIFont systemFontOfSize:16];
    UIView *space=[UIView new]; [space setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisHorizontal];
    UIImageView *emoji=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"face.smiling"]]; emoji.tintColor=UIColor.labelColor;
    UIImageView *plus=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle"]]; plus.tintColor=UIColor.labelColor;
    for (UIView *v in @[voice,self.previewPlaceholder,space,emoji,plus]) [items addArrangedSubview:v];
    for (UIView *v in @[voice,emoji,plus]) { [v.widthAnchor constraintEqualToConstant:24].active=YES; [v.heightAnchor constraintEqualToConstant:24].active=YES; }
    [glass.contentView addSubview:items];
    [NSLayoutConstraint activateConstraints:@[[items.leadingAnchor constraintEqualToAnchor:glass.contentView.leadingAnchor constant:16],[items.trailingAnchor constraintEqualToAnchor:glass.contentView.trailingAnchor constant:-16],[items.centerYAnchor constraintEqualToAnchor:glass.contentView.centerYAnchor]]];
    self.previewPill=glass;
    [self applyPreview];
    return wrap;
}
- (UIView *)sliderRow:(NSString *)title detail:(NSString *)detail key:(NSString *)key min:(float)min max:(float)max fallback:(float)value {
    UIView *row=[UIView new]; row.translatesAutoresizingMaskIntoConstraints=NO; [row.heightAnchor constraintEqualToConstant:76].active=YES;
    UILabel *t=[UILabel new]; t.translatesAutoresizingMaskIntoConstraints=NO; t.text=title; t.font=[UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    UILabel *d=[UILabel new]; d.translatesAutoresizingMaskIntoConstraints=NO; d.text=detail; d.font=[UIFont systemFontOfSize:11]; d.textColor=UIColor.secondaryLabelColor;
    UISlider *slider=[UISlider new]; slider.translatesAutoresizingMaskIntoConstraints=NO; slider.minimumValue=min; slider.maximumValue=max; slider.value=[NSUserDefaults.standardUserDefaults objectForKey:key] ? [NSUserDefaults.standardUserDefaults floatForKey:key] : value; slider.accessibilityIdentifier=key; slider.minimumTrackTintColor=self.green;
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:t]; [row addSubview:d]; [row addSubview:slider];
    [NSLayoutConstraint activateConstraints:@[[t.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],[t.topAnchor constraintEqualToAnchor:row.topAnchor constant:8],[d.leadingAnchor constraintEqualToAnchor:t.leadingAnchor],[d.topAnchor constraintEqualToAnchor:t.bottomAnchor constant:2],[slider.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:120],[slider.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],[slider.centerYAnchor constraintEqualToAnchor:row.centerYAnchor]]];
    return row;
}
- (UIView *)optionRow:(NSString *)title items:(NSArray *)items key:(NSString *)key {
    UIView *row=[UIView new]; row.translatesAutoresizingMaskIntoConstraints=NO; [row.heightAnchor constraintEqualToConstant:60].active=YES;
    UILabel *l=[UILabel new]; l.translatesAutoresizingMaskIntoConstraints=NO; l.text=title; l.font=[UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    UISegmentedControl *seg=[[UISegmentedControl alloc] initWithItems:items]; seg.translatesAutoresizingMaskIntoConstraints=NO; seg.selectedSegmentIndex=MIN([NSUserDefaults.standardUserDefaults integerForKey:key],items.count-1); seg.accessibilityIdentifier=key; [seg addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:l]; [row addSubview:seg];
    [NSLayoutConstraint activateConstraints:@[[l.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],[l.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],[seg.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],[seg.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],[seg.widthAnchor constraintEqualToConstant:150],[l.trailingAnchor constraintLessThanOrEqualToAnchor:seg.leadingAnchor constant:-8]]];
    return row;
}
- (void)switchChanged:(UISwitch *)s { [NSUserDefaults.standardUserDefaults setBool:s.isOn forKey:s.accessibilityIdentifier]; WTPostInputSettingsChanged(); }
- (void)segmentChanged:(UISegmentedControl *)s { [NSUserDefaults.standardUserDefaults setInteger:s.selectedSegmentIndex forKey:s.accessibilityIdentifier]; WTPostInputSettingsChanged(); }
- (void)sliderChanged:(UISlider *)s { [NSUserDefaults.standardUserDefaults setFloat:s.value forKey:s.accessibilityIdentifier]; WTPostInputSettingsChanged(); }
- (void)styleChanged:(UISegmentedControl *)s { [NSUserDefaults.standardUserDefaults setInteger:s.selectedSegmentIndex forKey:kStyle]; [self applyPreview]; WTPostInputSettingsChanged(); }
- (void)applyPreview {
    NSInteger style=[NSUserDefaults.standardUserDefaults integerForKey:kStyle];
    CGFloat radius=style==1?29:(style==2?18:24);
    self.previewPill.layer.cornerRadius=radius;
    self.previewPlaceholder.text=[NSUserDefaults.standardUserDefaults stringForKey:kPlaceholder] ?: @"发送消息";
}
- (void)scrollToStyle { [self.scroll setContentOffset:CGPointMake(0,MIN(self.scroll.contentSize.height,220)) animated:YES]; }
- (void)showTGInfo {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"TG 菜单" message:@"当前保留原生微信加号菜单的点击与展开逻辑。菜单外观增强将在后续版本接入。" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]]; [self presentViewController:a animated:YES completion:nil];
}
- (void)chooseSendColor { [self chooseColorForKey:@"wt.input.send.color" title:@"发送键颜色"]; }
- (void)chooseCursorColor { [self chooseColorForKey:@"wt.input.cursor.color" title:@"输入光标颜色"]; }
- (void)chooseTextColor { [self chooseColorForKey:@"wt.input.text.color" title:@"输入文字颜色"]; }
- (void)chooseColorForKey:(NSString *)key title:(NSString *)title {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *names=@[@"系统绿",@"冰蓝",@"紫色",@"黑色",@"白色",@"灰色"];
    NSArray *values=@[@"green",@"blue",@"purple",@"black",@"white",@"gray"];
    for (NSUInteger i=0;i<names.count;i++) {
        NSString *name=names[i], *value=values[i];
        [a addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
            WTPostInputSettingsChanged();
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (a.popoverPresentationController) {
        a.popoverPresentationController.sourceView=self.view;
        a.popoverPresentationController.sourceRect=CGRectMake(CGRectGetMidX(self.view.bounds),CGRectGetMidY(self.view.bounds),1,1);
    }
    [self presentViewController:a animated:YES completion:nil];
}
- (void)chooseGlowColor {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"炫光颜色" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *names=@[@"系统绿",@"冰蓝",@"紫色",@"白色"];
    NSArray *values=@[@"green",@"blue",@"purple",@"white"];
    for (NSUInteger i=0;i<names.count;i++) { NSString *n=names[i], *v=values[i]; [a addAction:[UIAlertAction actionWithTitle:n style:UIAlertActionStyleDefault handler:^(UIAlertAction *x){ [NSUserDefaults.standardUserDefaults setObject:v forKey:kGlowColor]; WTPostInputSettingsChanged(); }]]; }
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    if (a.popoverPresentationController) {
        a.popoverPresentationController.sourceView = self.view;
        a.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
    [self presentViewController:a animated:YES completion:nil];
}
- (void)editPlaceholder {
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"占位符内容" message:@"设置聊天输入框中的提示文字" preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){ f.text=[NSUserDefaults.standardUserDefaults stringForKey:kPlaceholder] ?: @"发送消息"; }];
    [a addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x){ NSString *v=a.textFields.firstObject.text ?: @"发送消息"; [NSUserDefaults.standardUserDefaults setObject:v forKey:kPlaceholder]; self.previewPlaceholder.text=v; WTPostInputSettingsChanged(); }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)showEffect {
    // Bring the interactive style preview into view instead of showing a confirmation-only alert.
    [self.scroll setContentOffset:CGPointMake(0, 210) animated:YES];
    self.previewPill.layer.borderWidth = 1.8;
    [UIView animateWithDuration:0.35 animations:^{ self.previewPill.layer.borderWidth = 0.8; }];
}
@end
