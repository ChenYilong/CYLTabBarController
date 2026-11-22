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

@end
