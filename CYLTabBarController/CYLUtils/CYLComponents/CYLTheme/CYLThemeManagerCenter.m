//
//  CYLThemeManagerCenter.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLThemeManagerCenter.h"
#import "CYLThemePrivate.h"

NSString *const CYLThemeManagerNameDefault = @"Default";

/// [EN] Every manager, created on the main thread. [CN] 所有管理器，在主线程创建。
static NSMutableArray<CYLThemeManager *> *CYLThemeAllManagers(void) {
    static NSMutableArray<CYLThemeManager *> *managers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        managers = [NSMutableArray array];
    });
    return managers;
}

@implementation CYLThemeManagerCenter

+ (CYLThemeManager *)themeManagerWithName:(__kindof NSObject<NSCopying> *)name {
    NSMutableArray<CYLThemeManager *> *managers = CYLThemeAllManagers();
    @synchronized (managers) {
        for (CYLThemeManager *manager in managers) {
            if ([manager.name isEqual:name]) {
                return manager;
            }
        }
        CYLThemeManager *manager = [[CYLThemeManager alloc] initWithName:name];
        [managers addObject:manager];
        return manager;
    }
}

+ (CYLThemeManager *)defaultThemeManager {
    return [self themeManagerWithName:CYLThemeManagerNameDefault];
}

+ (NSArray<CYLThemeManager *> *)themeManagers {
    NSMutableArray<CYLThemeManager *> *managers = CYLThemeAllManagers();
    @synchronized (managers) {
        return [managers copy];
    }
}

+ (void)updateThemesForTraitCollection:(UITraitCollection *)traitCollection {
    for (CYLThemeManager *manager in [self themeManagers]) {
        [manager updateThemeForTraitCollection:traitCollection];
    }
}

@end
