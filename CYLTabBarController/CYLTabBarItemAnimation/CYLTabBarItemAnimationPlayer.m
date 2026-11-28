//
//  CYLTabBarItemAnimationPlayer.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-shell — [EN] `CYLTabBarItemAnimationBasePlayer` is a public superclass that apps and animators subclass in Objective-C; Objective-C cannot subclass a Swift class (the maintainer's rule of 2026-11-13, docs/Swift-Migration.md). [CN] `CYLTabBarItemAnimationBasePlayer` 是供 App 与 animator 用 Objective-C 继承的公开父类；Objective-C 不能继承 Swift 类（维护者 2026-11-13 的规则）。

#import "CYLTabBarItemAnimationPlayer.h"

@implementation CYLTabBarItemAnimationBasePlayer

- (instancetype)initWithAnimationView:(UIView *)animationView {
    if (self = [super init]) {
        _animationView = animationView;
    }
    return self;
}

#pragma mark - The cross-platform player contract (optional members of CYLTabBarItemAnimationPlayer)

/*
 * [EN] The defaults answer from the optional members the subclass already implements (`-respondsToSelector:`, which a
 *      subclass such as the playable view player may narrow); `loops`, `progress` and `animationSpeed` themselves are never
 *      defined here, because the item view and the tab engine branch on whether a player responds to them.
 * [CN] 默认值根据子类已实现的可选成员回答（`-respondsToSelector:`，可选播放器等子类可以收窄）；这里从不定义 `loops`、`progress` 与
 *      `animationSpeed` 本身，因为条目视图与 Tab 引擎会根据播放器是否响应它们走不同的分支。
 */

- (BOOL)supportsSpeed {
    return [self respondsToSelector:@selector(setAnimationSpeed:)];
}

- (BOOL)supportsLoops {
    return [self respondsToSelector:@selector(setLoops:)];
}

- (BOOL)supportsProgress {
    return [self respondsToSelector:@selector(setProgress:)] && [self respondsToSelector:@selector(progress)];
}

- (BOOL)supportsColors {
    return [self respondsToSelector:@selector(applyColors:traitCollection:)];
}

- (BOOL)isPlaying {
    return NO;
}

- (CGFloat)speed {
    if (![self supportsSpeed]) {
        return 1;
    }
    CGFloat value = [[self valueForKey:@"animationSpeed"] doubleValue];
    return value > 0 ? value : 1;
}

- (void)setSpeed:(CGFloat)speed {
    if ([self supportsSpeed]) {
        [self setValue:@(speed > 0 ? speed : 1) forKey:@"animationSpeed"];
    }
}

- (void)applyColors:(NSDictionary<NSString *, UIColor *> *)colors {
    if (![self supportsColors]) {
        return;
    }
    UITraitCollection *traitCollection = self.animationView.traitCollection ?: [UITraitCollection currentTraitCollection];
    [(id<CYLTabBarItemAnimationPlayer>)self applyColors:colors traitCollection:traitCollection];
}

- (void)notifyPlaybackEnded {
    if ([self respondsToSelector:@selector(loops)] && [[self valueForKey:@"loops"] boolValue]) {
        return;
    }
    void (^onEnded)(void) = self.onEnded;
    if (!onEnded) {
        return;
    }
    if ([NSThread isMainThread]) {
        onEnded();
    } else {
        dispatch_async(dispatch_get_main_queue(), onEnded);
    }
}

@end
