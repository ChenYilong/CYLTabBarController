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

// [EN] Only the animation URL of a tab's attributes stays here: it registers dark styles through functions declared in
//      private headers (`CYLConstants.m`). Everything else of this file is Swift (`Swift/UIControl+CYLTabBarItemAnimation.swift`,
//      docs/Swift-Migration.md); this moves with `CYLConstants`.
// [CN] 这里只保留 Tab 属性中动画 URL 的读取：它通过只在私有头文件中声明的函数（`CYLConstants.m`）注册深色样式。本文件的其他部分均为
//      Swift（`Swift/UIControl+CYLTabBarItemAnimation.swift`，docs/Swift-Migration.md）；这部分随 `CYLConstants` 一起迁移。
#import "UIControl+CYLTabBarItemAnimation.h"
#import "CYLTabBarController.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"

static void CYLRegisterDarkAnimationFromAttributes(NSURL *animationURL, NSDictionary *attributes) {
    if (!animationURL) {
        return;
    }
    // First: the #442 keys and whether their values are usable. Without any, and with nothing registered before for this
    // animation, nothing else runs. 首先判断 #442 新增的 key 是否存在、值是否有效；都没有且此前也未注册时，直接返回。
    // FIX: issue #604 — generic keys, or the keys of the library the tab's keys choose (`CYLTabBarItemAttributesAnimationValue`).
    // 通用 key，或 Tab 的 key 选择的动画库的 key。
    id darkURLValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationDarkURL);
    id darkFilePathValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationDarkFilePath);
    id darkColorsValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationDarkColors);
    NSURL *darkURL = [darkURLValue isKindOfClass:[NSURL class]] ? darkURLValue : nil;
    if (!darkURL && [darkFilePathValue isKindOfClass:[NSString class]] && [(NSString *)darkFilePathValue length] > 0) {
        darkURL = [CYLConstants cyl_getURLFromString:darkFilePathValue];
    }
    NSDictionary *darkColors = ([darkColorsValue isKindOfClass:[NSDictionary class]] && [(NSDictionary *)darkColorsValue count] > 0) ? darkColorsValue : nil;
    // FIX: issue #216 — the colors of every appearance, theme colors allowed. 所有外观下的颜色，可以是主题颜色。
    id colorsValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationColors);
    NSDictionary *colors = ([colorsValue isKindOfClass:[NSDictionary class]] && [(NSDictionary *)colorsValue count] > 0) ? colorsValue : nil;
    if (!darkURL && !darkColors && !colors && ![CYLTabBarItemAnimationDefaultStyleSource() hasStyleVariantForURL:animationURL]) {
        return;
    }
    CYLTabBarItemAnimationRegisterColors(animationURL, colors);
    // [EN] The dark version is played by the same library as the light one. [CN] 深色版本与浅色版本由同一个动画库播放。
    if (darkURL) {
        [CYLTabBarItemAnimationGetService() bindAnimationURL:darkURL toAttributes:attributes];
    }
    CYLTabBarItemAnimationRegisterDarkStyle(animationURL, darkURL, darkColors);
}

/*!
 * [EN] The animation file of a tab item (`…URL`, else `…FilePath`, with `filePath` set to the latter), bound to the
 *      library its keys choose (e.g. `CYLTabBarRiveURL`) rather than to its extension, with its Dark Mode version (#442).
 * [CN] Tab item 的动画文件（`…URL`，否则为 `…FilePath`，并把后者写入 `filePath`），绑定到其 key 选择的动画库（例如 `CYLTabBarRiveURL`），
 *      而不是由扩展名决定，并注册其深色模式版本（#442）。
 */
NSURL *CYLTabBarItemAnimationURLFromAttributes(NSDictionary *attributes, NSString * __autoreleasing *filePath) {
    id URLValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationURL);
    id filePathValue = CYLTabBarItemAttributesAnimationValue(attributes, CYLTabBarAnimationFilePath);
    NSString *animationFilePath = [filePathValue isKindOfClass:[NSString class]] ? filePathValue : nil;
    if (filePath) {
        *filePath = animationFilePath;
    }
    NSURL *animationURL = [URLValue isKindOfClass:[NSURL class]] ? URLValue : [CYLConstants cyl_getURLFromString:animationFilePath];
    [CYLTabBarItemAnimationGetService() bindAnimationURL:animationURL toAttributes:attributes];
    CYLRegisterDarkAnimationFromAttributes(animationURL, attributes);
    return animationURL;
}

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
