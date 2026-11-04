//
//  CYLTabBarItemAnimationFactory.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemAnimationFactory.h"
#import <objc/runtime.h>
#import "CYLTabBarItemAnimatorRegistry.h"

/// [EN] The view keeps its player; the player holds the view weakly, so there is no retain cycle.
/// [CN] 视图持有其播放器；播放器弱引用视图，因此没有循环引用。
static const void *CYLTabBarItemAnimationPlayerKey = &CYLTabBarItemAnimationPlayerKey;

@implementation CYLTabBarItemAnimationFactory

+ (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    id<CYLTabBarItemAnimator> animator = [CYLTabBarItemAnimatorRegistry animatorForURL:URL];
    UIView *animationView = [animator animationViewWithURL:URL size:size contentMode:contentMode];
    id<CYLTabBarItemAnimationPlayer> player = animationView ? [animator playerForAnimationView:animationView] : nil;
    if (!player) {
        return nil;
    }
    objc_setAssociatedObject(animationView, CYLTabBarItemAnimationPlayerKey, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // The same set-up for every library, for a view inside a tab button. 所有动画库相同：作为 Tab 按钮子视图的设置。
    animationView.frame = CGRectMake(0, 0, size.width, size.height);
    animationView.userInteractionEnabled = NO;
    animationView.contentMode = contentMode;
    animationView.translatesAutoresizingMaskIntoConstraints = YES; // FIX: issue #653, see `_CYLTabButtonLayoutTracker`
    animationView.clipsToBounds = NO;
    return animationView;
}

+ (id<CYLTabBarItemAnimationPlayer>)playerForView:(UIView *)view {
    if (!view || [view isMemberOfClass:[UIView class]]) {
        return nil;
    }
    id<CYLTabBarItemAnimationPlayer> player = objc_getAssociatedObject(view, CYLTabBarItemAnimationPlayerKey);
    if (player) {
        return player;
    }
    // [EN] A library view made elsewhere (e.g. added by the app): its library recognizes it and gives it a player.
    // [CN] 在别处创建的动画库视图（例如由 App 添加）：由其动画库识别并为它创建播放器。
    for (id<CYLTabBarItemAnimator> animator in [CYLTabBarItemAnimatorRegistry animators]) {
        player = [animator playerForAnimationView:view];
        if (player) {
            objc_setAssociatedObject(view, CYLTabBarItemAnimationPlayerKey, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return player;
        }
    }
    return nil;
}

+ (BOOL)isAnimationView:(UIView *)view {
    return [self playerForView:view] != nil;
}

@end
