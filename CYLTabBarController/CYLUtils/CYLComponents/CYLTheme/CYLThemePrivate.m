//
//  CYLThemePrivate.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLThemePrivate.h"

NS_ASSUME_NONNULL_BEGIN

void CYLThemeRefreshBarAppearances(UIView *view) {
    if (@available(iOS 13.0, *)) {
        // [EN] A copy is a new object: the bar applies it again and resolves the theme colors in it.
        // [CN] 副本是新对象：Bar 会重新应用它，并重新解析其中的主题颜色。
        if ([view isKindOfClass:[UITabBar class]]) {
            UITabBar *tabBar = (UITabBar *)view;
            tabBar.standardAppearance = [tabBar.standardAppearance copy];
            if (@available(iOS 15.0, *)) {
                if (tabBar.scrollEdgeAppearance) {
                    tabBar.scrollEdgeAppearance = [tabBar.scrollEdgeAppearance copy];
                }
            }
        } else if ([view isKindOfClass:[UINavigationBar class]]) {
            UINavigationBar *navigationBar = (UINavigationBar *)view;
            navigationBar.standardAppearance = [navigationBar.standardAppearance copy];
            if (navigationBar.scrollEdgeAppearance) {
                navigationBar.scrollEdgeAppearance = [navigationBar.scrollEdgeAppearance copy];
            }
            if (navigationBar.compactAppearance) {
                navigationBar.compactAppearance = [navigationBar.compactAppearance copy];
            }
        } else if ([view isKindOfClass:[UIToolbar class]]) {
            UIToolbar *toolbar = (UIToolbar *)view;
            toolbar.standardAppearance = [toolbar.standardAppearance copy];
            if (toolbar.compactAppearance) {
                toolbar.compactAppearance = [toolbar.compactAppearance copy];
            }
        }
    }
}

NS_ASSUME_NONNULL_END
