#import <UIKit/UIKit.h>
#import "WTSettingsController.h"
#import <objc/runtime.h>


static const NSInteger WTInputGlassTag = 0x57544947;
static BOOL WTInputBool(NSString *key, BOOL fallback) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    return value ? [value boolValue] : fallback;
}
static UIView *WTFindComposerContainer(UIView *root) {
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:root];
    UITextView *textView = nil;
    NSUInteger visited = 0;
    while (stack.count && visited++ < 700) {
        UIView *v = stack.lastObject; [stack removeLastObject];
        if ([v isKindOfClass:UITextView.class] && !v.hidden && v.alpha > 0.05) { textView = (UITextView *)v; break; }
        for (UIView *child in v.subviews) [stack addObject:child];
    }
    if (!textView) return nil;
    UIView *candidate = textView.superview;
    while (candidate && candidate != root) {
        CGRect f = [candidate convertRect:candidate.bounds toView:root];
        if (CGRectGetWidth(f) >= CGRectGetWidth(root.bounds) * 0.62 &&
            CGRectGetHeight(f) >= 38 && CGRectGetHeight(f) <= 180 &&
            CGRectGetMaxY(f) >= CGRectGetHeight(root.bounds) - 190) return candidate;
        candidate = candidate.superview;
    }
    return nil;
}
static void WTUpdateGlowBorder(UIVisualEffectView *glass, CGFloat radius) {
    NSString *layerName = @"wtchet.glow.border";
    CAGradientLayer *gradient = nil;
    for (CALayer *layer in glass.layer.sublayers) {
        if ([layer.name isEqualToString:layerName]) { gradient = (CAGradientLayer *)layer; break; }
    }
    BOOL enabled = WTInputBool(@"wt.input.glow.enabled", NO);
    if (!enabled) {
        [gradient removeFromSuperlayer];
        return;
    }
    NSString *colorName = [NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.glow.color"] ?: @"green";
    UIColor *base = [colorName isEqualToString:@"blue"] ? [UIColor colorWithRed:0.20 green:0.62 blue:1 alpha:1] :
                    ([colorName isEqualToString:@"purple"] ? [UIColor colorWithRed:0.62 green:0.35 blue:1 alpha:1] :
                    ([colorName isEqualToString:@"white"] ? UIColor.whiteColor : [UIColor colorWithRed:0.08 green:0.72 blue:0.43 alpha:1]));
    if (!gradient) {
        gradient = [CAGradientLayer layer];
        gradient.name = layerName;
        gradient.startPoint = CGPointMake(0, 0.5);
        gradient.endPoint = CGPointMake(1, 0.5);
        gradient.locations = @[@0, @0.35, @0.7, @1];
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.fillColor = UIColor.clearColor.CGColor;
        mask.strokeColor = UIColor.whiteColor.CGColor;
        mask.lineWidth = 2.0;
        gradient.mask = mask;
        [glass.layer addSublayer:gradient];
    }
    gradient.frame = glass.bounds;
    CAShapeLayer *mask = (CAShapeLayer *)gradient.mask;
    mask.frame = gradient.bounds;
    mask.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(gradient.bounds, 1, 1) cornerRadius:MAX(2, radius - 1)].CGPath;
    UIColor *dim = [base colorWithAlphaComponent:0.12];
    UIColor *bright = [base colorWithAlphaComponent:0.98];
    gradient.colors = @[(id)dim.CGColor, (id)bright.CGColor, (id)dim.CGColor, (id)bright.CGColor];
    if (![gradient animationForKey:@"wtchet.glow.rotation"]) {
        CGFloat speed = [NSUserDefaults.standardUserDefaults objectForKey:@"wt.input.glow.speed"] ? [NSUserDefaults.standardUserDefaults floatForKey:@"wt.input.glow.speed"] : 1.0;
        speed = MIN(2.5, MAX(0.5, speed));
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        spin.fromValue = @0;
        spin.toValue = @(M_PI * 2);
        spin.duration = 3.6 / speed;
        spin.repeatCount = HUGE_VALF;
        [gradient addAnimation:spin forKey:@"wtchet.glow.rotation"];
    }
}

static void WTApplyChatInputGlass(UIView *root) {
    if (!NSThread.isMainThread || !root) return;
    UIView *host = WTFindComposerContainer(root);
    if (!host) return;
    BOOL enabled = WTInputBool(@"wt.global.enabled", YES) && WTInputBool(@"wt.input.enabled", YES);
    if (!enabled) { [[host viewWithTag:WTInputGlassTag] removeFromSuperview]; return; }
    NSInteger style = [NSUserDefaults.standardUserDefaults integerForKey:@"wt.input.preview.style"];
    BOOL smsMode = WTInputBool(@"wt.input.sms.enabled", NO);
    CGFloat radius = smsMode ? 18.0 : (style == 2 ? 17.0 : (style == 1 ? 29.0 : 23.0));
    UIVisualEffectView *glass = (UIVisualEffectView *)[host viewWithTag:WTInputGlassTag];
    if (!glass) {
        glass = [[UIVisualEffectView alloc] initWithEffect:WTInputBool(@"wt.glass.enabled", YES) ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial] : nil];
        glass.tag = WTInputGlassTag;
        glass.userInteractionEnabled = NO;
        glass.translatesAutoresizingMaskIntoConstraints = NO;
        [host insertSubview:glass atIndex:0];
        [NSLayoutConstraint activateConstraints:@[
            [glass.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
            [glass.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
            [glass.topAnchor constraintEqualToAnchor:host.topAnchor],
            [glass.bottomAnchor constraintEqualToAnchor:host.bottomAnchor]
        ]];
    }
    glass.effect = WTInputBool(@"wt.glass.enabled", YES) ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial] : nil;
    // Keep WeChat's original container clipping and hit-testing intact.
    glass.layer.cornerRadius = radius;
    glass.layer.cornerCurve = kCACornerCurveContinuous;
    glass.clipsToBounds = YES;
    glass.layer.borderWidth = 0.8;
    glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.62].CGColor;
    WTUpdateGlowBorder(glass, radius);

    UITextView *editor = nil;
    NSMutableArray<UIView *> *nodes = [NSMutableArray arrayWithObject:host];
    NSUInteger scanned = 0;
    while (nodes.count && scanned++ < 240) {
        UIView *v = nodes.lastObject; [nodes removeLastObject];
        if ([v isKindOfClass:UITextView.class]) {
            editor = (UITextView *)v;
            editor.backgroundColor = UIColor.clearColor;
            editor.layer.cornerRadius = style == 2 ? 16 : (style == 1 ? 24 : 20);
        }
        if ([v isKindOfClass:UILabel.class] && WTInputBool(@"wt.input.placeholder.enabled", NO)) {
            UILabel *label = (UILabel *)v;
            if ([label.text containsString:@"发送消息"] || [label.text containsString:@"输入"]) {
                label.text = [NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.placeholder.text"] ?: @"发送消息";
            }
        }
        if ([v isKindOfClass:UIButton.class]) {
            UIButton *button = (UIButton *)v;
            NSString *accessibility = [[(button.accessibilityLabel ?: @"") lowercaseString] stringByAppendingString:(button.currentTitle ?: @"")];
            if (WTInputBool(@"wt.input.sms.hideEmoji", NO) && ([accessibility containsString:@"表情"] || [accessibility containsString:@"emoji"])) button.hidden = YES;
            button.tintColor = [UIColor colorWithWhite:0.12 alpha:1];
            button.layer.cornerCurve = kCACornerCurveContinuous;
            button.layer.cornerRadius = smsMode ? 16 : (style == 2 ? 18 : 22);
            button.layer.borderWidth = 0.65;
            button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.55].CGColor;
            BOOL isPlus = [accessibility containsString:@"plus"] || [accessibility containsString:@"添加"] || [accessibility containsString:@"更多"];
            button.backgroundColor = [UIColor colorWithWhite:1 alpha:(isPlus && WTInputBool(@"wt.input.jelly.menu", NO)) ? 0.42 : 0.20];
            if (smsMode && button.currentImage) {
                NSInteger iconWeight = [NSUserDefaults.standardUserDefaults integerForKey:@"wt.input.sms.icon"];
                UIImageSymbolWeight weight = iconWeight == 1 ? UIImageSymbolWeightBold : (iconWeight == 2 ? UIImageSymbolWeightLight : UIImageSymbolWeightRegular);
                UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:weight];
                [button setPreferredSymbolConfiguration:configuration forImageInState:UIControlStateNormal];
            }
            button.clipsToBounds = YES;
        }
        for (UIView *child in v.subviews) [nodes addObject:child];
    }

}

static UIViewController *WTTopController(UIViewController *controller) {
    if (controller.presentedViewController) return WTTopController(controller.presentedViewController);
    if ([controller isKindOfClass:UINavigationController.class]) return WTTopController(((UINavigationController *)controller).visibleViewController);
    if ([controller isKindOfClass:UITabBarController.class]) return WTTopController(((UITabBarController *)controller).selectedViewController);
    return controller;
}

static UIWindow *WTKeyWindow(void) {
    for (UIWindow *window in UIApplication.sharedApplication.windows) if (window.isKeyWindow) return window;
    return UIApplication.sharedApplication.keyWindow;
}

static void WTShowSettings(void) {
    UIWindow *window = WTKeyWindow();
    UIViewController *top = WTTopController(window.rootViewController);
    if (!top || top.presentedViewController) return;
    WTSettingsController *settings = [WTSettingsController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settings];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [top presentViewController:nav animated:YES completion:nil];
}

@interface WTLauncherTarget : NSObject
+ (instancetype)shared;
- (void)openSettings;
@end

@implementation WTLauncherTarget
+ (instancetype)shared {
    static WTLauncherTarget *target;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ target = [WTLauncherTarget new]; });
    return target;
}
- (void)openSettings { WTShowSettings(); }
@end

static void WTInstallLauncher(void) {
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.tencent.xin"]) return;
    UIWindow *window = WTKeyWindow();
    if (!window || [window viewWithTag:0x57544348]) return;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tag = 0x57544348;
    button.frame = CGRectMake(window.bounds.size.width - 64, window.bounds.size.height * 0.62, 48, 48);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    button.backgroundColor = [UIColor colorWithWhite:1 alpha:0.86];
    button.layer.cornerRadius = 24;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.95].CGColor;
    button.layer.shadowColor = UIColor.blackColor.CGColor;
    button.layer.shadowOpacity = 0.12;
    button.layer.shadowRadius = 8;
    [button setTitle:@"wt" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [button setTitleColor:[UIColor colorWithRed:0.02 green:0.37 blue:0.21 alpha:1] forState:UIControlStateNormal];
    [button addTarget:[WTLauncherTarget shared] action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:button];
}

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{ WTInstallLauncher(); });
}
- (void)viewDidLayoutSubviews {
    %orig;
    if (![NSStringFromClass(self.class) isEqualToString:@"BaseMsgContentViewController"]) return;
    WTApplyChatInputGlass(self.view);
}
%end

%ctor {
    @autoreleasepool {
        if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.tencent.xin"]) {
            NSLog(@"[wtchet] v0.1.0 settings prototype loaded");
        }
    }
}
