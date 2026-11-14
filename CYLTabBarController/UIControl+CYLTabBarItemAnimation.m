//
//  UIControl+CYLTabBarItemAnimation.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #604 — Core's side of the tab icon animation: it only forwards to the injected
//      `CYLTabBarItemAnimationService`, so Core knows no animation library (dependency inversion), and a new library needs
//      no change here.
// [CN] Core 一侧的 Tab 图标动画：只转发给注入的 `CYLTabBarItemAnimationService`，因此 Core 不认识任何动画库（依赖反转），
//      新增动画库时这里无需修改。

// [EN] Only the `CYLTabBar` category stays here. The animation URL of a tab's attributes is Swift since step 45
//      (`Swift/CYLTabBarItemAnimationStyleRegistry.swift`); the rest of this file is `Swift/UIControl+CYLTabBarItemAnimation.swift`.
// [CN] 这里只保留 `CYLTabBar` 的类别。Tab 属性中动画 URL 的读取自第 45 步起为 Swift（`Swift/CYLTabBarItemAnimationStyleRegistry.swift`）；
//      本文件的其他部分为 `Swift/UIControl+CYLTabBarItemAnimation.swift`。
#import "UIControl+CYLTabBarItemAnimation.h"
#import "CYLTabBarController.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"

// [EN] Stays Objective-C until CYLTabBar is Swift: the generated header cannot extend a class it reads later.
// [CN] 在 CYLTabBar 迁移到 Swift 之前保留为 Objective-C：生成的头文件无法扩展一个之后才读取的类。
@implementation CYLTabBar (CYLTabBarItemAnimation)

- (void)cyl_playTabBarItemAnimationWithSelectedControl:(UIControl *)selectedControl
                                                   URL:(NSURL *)URL
                                                  size:(CGSize)size
                                       defaultSelected:(BOOL)defaultSelected
                                           contentMode:(UIViewContentMode)contentMode {
    if (!URL) {
        return;
    }
    // [CN] 统一使用CYLTabBarItemAnimationPlayingNotification进行动画重置， 故删除手动重置。
    // [EN] Animation reset is handled uniformly via CYLTabBarItemAnimationPlayingNotification, so the manual reset
    //      was removed.
    [selectedControl cyl_playTabBarItemAnimationWithURL:URL size:size defaultSelected:defaultSelected contentMode:contentMode];
}

- (void)cyl_stopAllTabBarItemAnimations {
    [self cyl_enumerateAnimatedControlsUsingBlock:^(UIControl *control) {
        [control cyl_stopTabBarItemAnimation];
    }];
}

- (void)cyl_restartAllTabBarItemAnimations {
    [self cyl_enumerateAnimatedControlsUsingBlock:^(UIControl *control) {
        [control cyl_restartTabBarItemAnimation];
    }];
}

- (void)cyl_setAllTabBarItemAnimationsSpeed:(CGFloat)speed loops:(BOOL)loops {
    [self cyl_enumerateAnimatedControlsUsingBlock:^(UIControl *control) {
        [control cyl_setTabBarItemAnimationSpeed:speed];
        [control cyl_setTabBarItemAnimationLoops:loops];
    }];
}

/// [EN] The tab buttons, then the selected-state layers (Liquid Glass). [CN] Tab 按钮，然后是选中态图层（液态玻璃）。
- (void)cyl_enumerateAnimatedControlsUsingBlock:(void (^)(UIControl *control))block {
    for (UIControl *control in self.cyl_visibleControls) {
        block(control);
    }
    for (UIControl *control in self.cyl_platterSelectedContentViews) {
        block(control);
    }
}

@end
