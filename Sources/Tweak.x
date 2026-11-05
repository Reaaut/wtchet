#import <UIKit/UIKit.h>
#import "WTSettingsController.h"
#import <objc/runtime.h>


static const NSInteger WTInputGlassTag = 0x57544947;
static char WTOriginalHostBackgroundKey;
static char WTOriginalHostTransformKey;
static char WTOriginalButtonHiddenKey;
static char WTOriginalBackdropBackgroundKey;
static char WTOriginalIMEBackgroundKey;
static BOOL WTInputBool(NSString *key, BOOL fallback) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    return value ? [value boolValue] : fallback;
}
static BOOL WTClassLooksLikeComposer(UIView *view) {
    NSString *name = NSStringFromClass(view.class).lowercaseString;
    return [name containsString:@"inputtool"] || [name containsString:@"inputbar"] ||
           [name containsString:@"chatinput"] || [name containsString:@"composer"] ||
           [name containsString:@"inputeditor"] || [name containsString:@"mmtextview"];
}
static BOOL WTIsTextEditor(UIView *view) {
    if ([view isKindOfClass:UITextView.class] || [view isKindOfClass:UITextField.class]) return YES;
    NSString *name = NSStringFromClass(view.class).lowercaseString;
    return ([name containsString:@"textview"] || [name containsString:@"inputtext"]) &&
           ![name containsString:@"label"];
}
static UIView *WTFindComposerContainer(UIView *root) {
    if (!root) return nil;
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:root];
    NSMutableArray<UIView *> *editors = [NSMutableArray array];
    NSMutableArray<UIView *> *namedHosts = [NSMutableArray array];
    NSUInteger visited = 0;
    while (stack.count && visited++ < 1400) {
        UIView *v = stack.lastObject;
        [stack removeLastObject];
        if (WTIsTextEditor(v) && !v.hidden && v.alpha > 0.05) [editors addObject:v];
        if (WTClassLooksLikeComposer(v)) [namedHosts addObject:v];
        for (UIView *child in v.subviews) [stack addObject:child];
    }
    CGFloat rootHeight = CGRectGetHeight(root.bounds);
    CGFloat rootWidth = CGRectGetWidth(root.bounds);
    UIView *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    for (UIView *editor in editors) {
        UIView *candidate = editor;
        while (candidate && candidate != root) {
            CGRect frame = [candidate convertRect:candidate.bounds toView:root];
            CGFloat width = CGRectGetWidth(frame), height = CGRectGetHeight(frame);
            if (width >= rootWidth * 0.58 && height >= 34 && height <= 210 &&
                CGRectGetMaxY(frame) >= rootHeight - 280) {
                CGFloat score = 100.0 - fabs(rootHeight - CGRectGetMaxY(frame));
                if (WTClassLooksLikeComposer(candidate)) score += 180.0;
                if (width >= rootWidth * 0.78) score += 25.0;
                if (score > bestScore) { bestScore = score; best = candidate; }
            }
            candidate = candidate.superview;
        }
    }
    if (best) return best;
    for (UIView *candidate in namedHosts) {
        CGRect frame = [candidate convertRect:candidate.bounds toView:root];
        CGFloat width = CGRectGetWidth(frame), height = CGRectGetHeight(frame);
        if (width < rootWidth * 0.58 || height < 34 || height > 210 ||
            CGRectGetMaxY(frame) < rootHeight - 280) continue;
        CGFloat score = 150.0 - fabs(rootHeight - CGRectGetMaxY(frame));
        if (score > bestScore) { bestScore = score; best = candidate; }
    }
    return best;
}
static const NSInteger WTComposerBackdropTag = 0x57544247;
static const NSInteger WTInputMethodGlassTag = 0x5754494D;
static UIView *WTFindComposerBackdrop(UIView *root, UIView *host) {
    CGFloat rw=CGRectGetWidth(root.bounds), rh=CGRectGetHeight(root.bounds);
    UIView *best=nil;
    for (UIView *v=host.superview; v && v!=root; v=v.superview) {
        CGRect f=[v convertRect:v.bounds toView:root];
        CGFloat w=CGRectGetWidth(f), h=CGRectGetHeight(f);
        if (w>=rw*0.90 && h>=65 && h<=360 && CGRectGetMaxY(f)>=rh-90 &&
            CGRectGetMinY(f)>=rh-390) best=v;
    }
    return best;
}
static void WTApplyComposerBackdrop(UIView *root, UIView *host) {
    UIView *backdrop=WTFindComposerBackdrop(root,host);
    if (!backdrop) return;
    BOOL hide=WTInputBool(@"wt.input.nativeBackground.hide",YES);
    BOOL blur=WTInputBool(@"wt.input.outerBlur.enabled",YES);
    if (!objc_getAssociatedObject(backdrop,&WTOriginalBackdropBackgroundKey)) {
        id original=backdrop.backgroundColor ?: (id)NSNull.null;
        objc_setAssociatedObject(backdrop,&WTOriginalBackdropBackgroundKey,original,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIVisualEffectView *effect=(UIVisualEffectView *)[backdrop viewWithTag:WTComposerBackdropTag];
    if (!hide && !blur) {
        [effect removeFromSuperview];
        id original=objc_getAssociatedObject(backdrop,&WTOriginalBackdropBackgroundKey);
        backdrop.backgroundColor=(original==NSNull.null)?nil:original;
        return;
    }
    if (hide) backdrop.backgroundColor=UIColor.clearColor;
    if (!effect) {
        effect=[[UIVisualEffectView alloc] initWithEffect:nil];
        effect.tag=WTComposerBackdropTag; effect.userInteractionEnabled=NO; effect.translatesAutoresizingMaskIntoConstraints=NO;
        [backdrop insertSubview:effect atIndex:0];
        [NSLayoutConstraint activateConstraints:@[
            [effect.leadingAnchor constraintEqualToAnchor:backdrop.leadingAnchor],
            [effect.trailingAnchor constraintEqualToAnchor:backdrop.trailingAnchor],
            [effect.topAnchor constraintEqualToAnchor:backdrop.topAnchor],
            [effect.bottomAnchor constraintEqualToAnchor:backdrop.bottomAnchor]
        ]];
    }
    effect.effect=blur?[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]:nil;
    effect.layer.cornerRadius=WTInputBool(@"wt.input.outerBlur.rounded",YES)?20:0;
    effect.layer.cornerCurve=kCACornerCurveContinuous; effect.clipsToBounds=YES;
}
static void WTApplyInputMethodArea(UIView *root) {
    NSMutableArray<UIView *> *stack=[NSMutableArray arrayWithObject:root];
    NSUInteger count=0;
    while(stack.count && count++<900) {
        UIView *v=stack.lastObject; [stack removeLastObject];
        NSString *name=NSStringFromClass(v.class).lowercaseString;
        BOOL target=([name containsString:@"keyboardtoolbar"] || [name containsString:@"inputmethod"] ||
                     [name containsString:@"inputmode"] || [name containsString:@"imeaccessory"] ||
                     [name containsString:@"keyboardaccessory"]);
        if(target && v!=root) {
            BOOL enabled=WTInputBool(@"wt.input.method.enabled",YES);
            UIVisualEffectView *glass=(UIVisualEffectView *)[v viewWithTag:WTInputMethodGlassTag];
            if(!objc_getAssociatedObject(v,&WTOriginalIMEBackgroundKey)) {
                id original=v.backgroundColor ?: (id)NSNull.null;
                objc_setAssociatedObject(v,&WTOriginalIMEBackgroundKey,original,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            if(enabled && WTInputBool(@"wt.input.method.hideBackground",YES)) v.backgroundColor=UIColor.clearColor;
            if(enabled && WTInputBool(@"wt.input.method.blur",YES) && !glass) {
                glass=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
                glass.tag=WTInputMethodGlassTag; glass.userInteractionEnabled=NO; glass.translatesAutoresizingMaskIntoConstraints=NO;
                [v insertSubview:glass atIndex:0];
                [NSLayoutConstraint activateConstraints:@[
                    [glass.leadingAnchor constraintEqualToAnchor:v.leadingAnchor],
                    [glass.trailingAnchor constraintEqualToAnchor:v.trailingAnchor],
                    [glass.topAnchor constraintEqualToAnchor:v.topAnchor],
                    [glass.bottomAnchor constraintEqualToAnchor:v.bottomAnchor]
                ]];
            }
            if(!enabled) {
                [glass removeFromSuperview];
                id original=objc_getAssociatedObject(v,&WTOriginalIMEBackgroundKey);
                v.backgroundColor=(original==NSNull.null)?nil:original;
            }
            glass.layer.cornerRadius=WTInputBool(@"wt.input.method.rounded",YES)?16:0;
            glass.clipsToBounds=YES;
        }
        for(UIView *child in v.subviews) [stack addObject:child];
    }
}
static UIColor *WTInputNamedColor(NSString *name, UIColor *fallback) {
    if ([name isEqualToString:@"green"]) return [UIColor colorWithRed:0.02 green:0.60 blue:0.34 alpha:1];
    if ([name isEqualToString:@"blue"]) return [UIColor colorWithRed:0.12 green:0.48 blue:0.95 alpha:1];
    if ([name isEqualToString:@"purple"]) return [UIColor colorWithRed:0.58 green:0.34 blue:0.92 alpha:1];
    if ([name isEqualToString:@"white"]) return UIColor.whiteColor;
    if ([name isEqualToString:@"black"]) return [UIColor colorWithWhite:0.08 alpha:1];
    if ([name isEqualToString:@"gray"]) return [UIColor colorWithWhite:0.42 alpha:1];
    return fallback;
}
static void WTUpdateFadeBackground(UIVisualEffectView *glass) {
    NSString *name = @"wtchet.input.fade";
    CAGradientLayer *fade = nil;
    for (CALayer *layer in glass.contentView.layer.sublayers) if ([layer.name isEqualToString:name]) { fade=(CAGradientLayer *)layer; break; }
    if (!WTInputBool(@"wt.input.fade.enabled", NO)) { [fade removeFromSuperlayer]; return; }
    if (!fade) { fade=[CAGradientLayer layer]; fade.name=name; [glass.contentView.layer insertSublayer:fade atIndex:0]; }
    fade.frame=glass.contentView.bounds;
    fade.startPoint=CGPointMake(0.5,0); fade.endPoint=CGPointMake(0.5,1);
    UIColor *tint=WTInputNamedColor([NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.fade.color"] ?: @"green",[UIColor colorWithWhite:1 alpha:1]);
    fade.colors=@[(id)[tint colorWithAlphaComponent:0.22].CGColor,(id)[tint colorWithAlphaComponent:0.03].CGColor,(id)UIColor.clearColor.CGColor];
    fade.locations=@[@0,@0.55,@1];
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
    CGFloat speed = [NSUserDefaults.standardUserDefaults objectForKey:@"wt.input.glow.speed"] ? [NSUserDefaults.standardUserDefaults floatForKey:@"wt.input.glow.speed"] : 1.0;
    gradient.speed = MIN(2.5, MAX(0.5, speed));
    CAShapeLayer *mask = (CAShapeLayer *)gradient.mask;
    mask.frame = gradient.bounds;
    mask.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(gradient.bounds, 1, 1) cornerRadius:MAX(2, radius - 1)].CGPath;
    UIColor *dim = [base colorWithAlphaComponent:0.12];
    UIColor *bright = [base colorWithAlphaComponent:0.98];
    gradient.colors = @[(id)dim.CGColor, (id)bright.CGColor, (id)dim.CGColor, (id)bright.CGColor];
    if (![gradient animationForKey:@"wtchet.glow.rotation"]) {
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        spin.fromValue = @0;
        spin.toValue = @(M_PI * 2);
        spin.duration = 3.6;
        spin.repeatCount = HUGE_VALF;
        [gradient addAnimation:spin forKey:@"wtchet.glow.rotation"];
    }
}

static void WTApplyChatInputGlass(UIView *root) {
    if (!NSThread.isMainThread || !root) return;
    UIView *host = WTFindComposerContainer(root);
    if (!host) return;
    BOOL enabled = WTInputBool(@"wt.global.enabled", YES) && WTInputBool(@"wt.input.enabled", YES);
    if (!objc_getAssociatedObject(host, &WTOriginalHostBackgroundKey)) {
        id original = host.backgroundColor ?: (id)NSNull.null;
        objc_setAssociatedObject(host, &WTOriginalHostBackgroundKey, original, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(host, &WTOriginalHostTransformKey, [NSValue valueWithCGAffineTransform:host.transform], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSInteger style = [NSUserDefaults.standardUserDefaults integerForKey:@"wt.input.preview.style"];
    BOOL smsMode = WTInputBool(@"wt.input.sms.enabled", NO);
    NSInteger smsSize = [NSUserDefaults.standardUserDefaults integerForKey:@"wt.input.sms.size"];
    CGFloat radius = smsMode ? (smsSize == 1 ? 13.0 : 20.0) : (style == 2 ? 17.0 : (style == 1 ? 29.0 : 23.0));
    if (!enabled) {
        [[host viewWithTag:WTInputGlassTag] removeFromSuperview];
        id originalBackground = objc_getAssociatedObject(host, &WTOriginalHostBackgroundKey);
        host.backgroundColor = (originalBackground == NSNull.null) ? nil : originalBackground;
        NSValue *originalTransform = objc_getAssociatedObject(host, &WTOriginalHostTransformKey);
        if (originalTransform) host.transform = originalTransform.CGAffineTransformValue;
        return;
    }
    WTApplyComposerBackdrop(root,host);
    WTApplyInputMethodArea(root);
    host.backgroundColor = UIColor.clearColor;
    host.layer.cornerRadius = radius;
    host.layer.cornerCurve = kCACornerCurveContinuous;
    host.clipsToBounds = YES;
    CGFloat verticalOffset = [NSUserDefaults.standardUserDefaults floatForKey:@"wt.input.offsetY"];
    NSValue *originalTransform = objc_getAssociatedObject(host, &WTOriginalHostTransformKey);
    host.transform = CGAffineTransformTranslate(originalTransform ? originalTransform.CGAffineTransformValue : CGAffineTransformIdentity, 0, verticalOffset);
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
    glass.effect = (WTInputBool(@"wt.glass.enabled", YES) && WTInputBool(@"wt.input.blur.enabled", YES)) ? [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial] : nil;
    // Keep WeChat's original container clipping and hit-testing intact.
    glass.layer.cornerRadius = radius;
    glass.layer.cornerCurve = kCACornerCurveContinuous;
    glass.clipsToBounds = YES;
    glass.layer.borderWidth = 0.8;
    glass.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.62].CGColor;
    WTUpdateGlowBorder(glass, radius);
    WTUpdateFadeBackground(glass);

    UITextView *editor = nil;
    NSMutableArray<UIView *> *nodes = [NSMutableArray arrayWithObject:host];
    NSUInteger scanned = 0;
    while (nodes.count && scanned++ < 240) {
        UIView *v = nodes.lastObject; [nodes removeLastObject];
        if ([v isKindOfClass:UITextView.class]) {
            editor = (UITextView *)v;
            editor.backgroundColor = UIColor.clearColor;
            editor.layer.cornerRadius = style == 2 ? 16 : (style == 1 ? 24 : 20);
            editor.textColor = WTInputNamedColor([NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.text.color"] ?: @"black", UIColor.labelColor);
            editor.tintColor = WTInputNamedColor([NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.cursor.color"] ?: @"green", UIColor.systemGreenColor);
        } else if ([v isKindOfClass:UITextField.class]) {
            UITextField *field=(UITextField *)v;
            field.backgroundColor=UIColor.clearColor;
            field.textColor=WTInputNamedColor([NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.text.color"] ?: @"black",UIColor.labelColor);
            field.tintColor=WTInputNamedColor([NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.cursor.color"] ?: @"green",UIColor.systemGreenColor);
        }
        if ([v isKindOfClass:UIButton.class]) {
            UIButton *button = (UIButton *)v;
            NSString *accessibility = [[(button.accessibilityLabel ?: @"") lowercaseString] stringByAppendingString:(button.currentTitle ?: @"")];
            BOOL isEmoji = [accessibility containsString:@"表情"] || [accessibility containsString:@"emoji"] ||
                           (CGRectGetMidX(button.frame) > CGRectGetWidth(host.bounds) * 0.66 && CGRectGetMidX(button.frame) < CGRectGetWidth(host.bounds) * 0.90);
            if (isEmoji) {
                if (!objc_getAssociatedObject(button, &WTOriginalButtonHiddenKey))
                    objc_setAssociatedObject(button, &WTOriginalButtonHiddenKey, @(button.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                BOOL wasHidden = [objc_getAssociatedObject(button, &WTOriginalButtonHiddenKey) boolValue];
                button.hidden = wasHidden || WTInputBool(@"wt.input.sms.hideEmoji", NO);
            }
            NSInteger iconColor = [NSUserDefaults.standardUserDefaults integerForKey:@"wt.input.icon.color"];
            button.tintColor = iconColor == 1 ? [UIColor colorWithRed:0.02 green:0.53 blue:0.30 alpha:1] :
                               (iconColor == 2 ? UIColor.whiteColor : [UIColor colorWithWhite:0.12 alpha:1]);
            if ([accessibility containsString:@"发送"] || [accessibility containsString:@"send"]) {
                button.tintColor = WTInputNamedColor([NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.send.color"] ?: @"green", button.tintColor);
            }
            button.layer.cornerCurve = kCACornerCurveContinuous;
            button.layer.cornerRadius = smsMode ? (smsSize == 1 ? 13 : 18) : (style == 2 ? 18 : 22);
            button.layer.borderWidth = 0.65;
            button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.55].CGColor;
            BOOL isPlus = [accessibility containsString:@"plus"] || [accessibility containsString:@"添加"] || [accessibility containsString:@"更多"] ||
                          CGRectGetMidX(button.frame) >= CGRectGetWidth(host.bounds) * 0.88;
            BOOL jelly = WTInputBool(@"wt.input.jelly.menu", NO);
            NSInteger menuTheme = [NSUserDefaults.standardUserDefaults integerForKey:@"wt.input.jelly.theme"];
            UIColor *buttonFill = menuTheme == 2 ? [UIColor colorWithWhite:0.12 alpha:0.72] :
                                  (menuTheme == 1 ? [UIColor colorWithWhite:1 alpha:0.82] : [UIColor colorWithWhite:1 alpha:0.20]);
            button.backgroundColor = (isPlus && jelly) ? buttonFill : [UIColor colorWithWhite:1 alpha:0.20];
            if (smsMode && button.currentImage) {
                NSInteger iconWeight = [NSUserDefaults.standardUserDefaults integerForKey:@"wt.input.sms.icon"];
                UIImageSymbolWeight weight = iconWeight == 1 ? UIImageSymbolWeightBold : (iconWeight == 2 ? UIImageSymbolWeightLight : UIImageSymbolWeightRegular);
                UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:weight];
                [button setPreferredSymbolConfiguration:configuration forImageInState:UIControlStateNormal];
            }
            button.clipsToBounds = YES;
        }
        if ([v isKindOfClass:UILabel.class] && WTInputBool(@"wt.input.placeholder.enabled", NO)) {
            UILabel *label = (UILabel *)v;
            if ([label.text containsString:@"发送消息"] || [label.text containsString:@"输入"]) {
                label.text = [NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.placeholder.text"] ?: @"发送消息";
                label.textColor = WTInputNamedColor([NSUserDefaults.standardUserDefaults stringForKey:@"wt.input.text.color"] ?: @"gray", UIColor.secondaryLabelColor);
            }
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
    dispatch_async(dispatch_get_main_queue(), ^{
        WTInstallLauncher();
        WTApplyChatInputGlass(self.view);
    });
}
- (void)viewDidLayoutSubviews {
    %orig;
    WTApplyChatInputGlass(self.view);
    NSString *controllerName = NSStringFromClass(self.class).lowercaseString;
    if (WTInputBool(@"wt.input.jelly.menu", NO) &&
        ([controllerName containsString:@"menu"] || [controllerName containsString:@"actionsheet"] ||
         [controllerName containsString:@"popover"] || [controllerName containsString:@"more"])) {
        self.view.backgroundColor = UIColor.clearColor;
        self.view.layer.cornerRadius = 22;
        self.view.clipsToBounds = YES;
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:UIVisualEffectView.class]) return;
        }
        UIVisualEffectView *menuGlass = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterial]];
        menuGlass.frame = self.view.bounds;
        menuGlass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        menuGlass.userInteractionEnabled = NO;
        menuGlass.layer.cornerRadius = 22;
        menuGlass.clipsToBounds = YES;
        [self.view insertSubview:menuGlass atIndex:0];
    }
}
%end

%hook UIView
- (void)layoutSubviews {
    %orig;
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.tencent.xin"]) return;
    NSString *name = NSStringFromClass(self.class).lowercaseString;
    if ([name containsString:@"inputtool"] || [name containsString:@"inputbar"] ||
        [name containsString:@"chatinput"] || [name containsString:@"composer"]) {
        UIWindow *window = self.window;
        UIViewController *root = window.rootViewController;
        if (root) WTApplyChatInputGlass(root.view);
    }
}
%end

%hook UITextView
- (void)layoutSubviews {
    %orig;
    UIWindow *window = self.window;
    if (!window || ![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.tencent.xin"]) return;
    UIViewController *rootController = window.rootViewController;
    if (rootController) WTApplyChatInputGlass(rootController.view);
}
%end

%ctor {
    @autoreleasepool {
        if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.tencent.xin"]) {
            NSLog(@"[wtchet] composer styling runtime loaded");
            [[NSNotificationCenter defaultCenter] addObserverForName:@"wt.input.settings.changed" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                UIWindow *window = WTKeyWindow();
                UIViewController *root = window.rootViewController;
                if (root) WTApplyChatInputGlass(root.view);
            }];
        }
    }
}
