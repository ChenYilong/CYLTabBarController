//
//  UIViewController+CYLTheme.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLTheme.h"
#import "CYLThemeManager.h"
#import "CYLThemePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (CYLTheme)

- (void)cyl_themeDidChangeByManager:(CYLThemeManager *)manager identifier:(nullable __kindof NSObject<NSCopying> *)identifier theme:(nullable __kindof NSObject *)theme {
    // [EN] Every child, not only the visible one: a child shown later still learns that the theme changed while it was
    //      hidden (e.g. a tab not selected yet).
    // [CN] 所有子控制器，而不只是可见的那个：之后才显示的子控制器（例如尚未选中的 Tab）也能得知隐藏期间主题发生了变化。
    for (UIViewController *childViewController in [self.childViewControllers copy]) {
        [childViewController cyl_themeDidChangeByManager:manager identifier:identifier theme:theme];
    }
    // [EN] Only the view controller presented by this one, not one presented by an ancestor and inherited here.
    // [CN] 只传递给由自身 present 出的控制器，不包括由祖先控制器 present、在这里也能取到的控制器。
    UIViewController *presentedViewController = self.presentedViewController;
    if (presentedViewController && presentedViewController.presentingViewController == self) {
        [presentedViewController cyl_themeDidChangeByManager:manager identifier:identifier theme:theme];
    }
    if (self.isViewLoaded) {
        [self setNeedsStatusBarAppearanceUpdate];
        // [EN] A loaded view out of every window (a tab not selected, a page under the top of a navigation stack) is not
        //      reached through the windows: update it here, so it is right when shown. Only the top of such a detached
        //      tree; its subviews follow.
        // [CN] 已加载但不在任何 window 中的视图（未选中的 Tab、导航栈中栈顶以下的页面）无法通过 window 到达：在这里更新，显示时即为正确样式。
        //      只处理这类脱离视图树的顶层视图，其子视图随之更新。
        UIView *view = self.view;
        if (!view.window && !view.superview) {
            [view cyl_themeDidChangeByManager:manager identifier:identifier theme:theme enumeratesSubviews:YES];
        }
    }
}

@end

NS_ASSUME_NONNULL_END
