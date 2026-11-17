//
//  CYLPAGTabBarItemAttributes.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The tab bar's PAG helper (declared in CYLPAGTabBarItemAnimator.h). It builds on Core's
//      `CYLTabBarItemsAttributesAddingAnimationFiles()`, so it is compiled by the `PAG` / `PAGEnterprise` subspecs, which
//      depend on Core, and not by the Core-free `CYLAnimatedItemPAG`.
// [CN] TabBar 的 PAG 工具函数（声明于 CYLPAGTabBarItemAnimator.h）。它基于 Core 的 `CYLTabBarItemsAttributesAddingAnimationFiles()`，因此由依赖
//      Core 的 `PAG` / `PAGEnterprise` 子库编译，不在不依赖 Core 的 `CYLAnimatedItemPAG` 中。
#if __has_include("../CYLPAGTabBarItemAnimator.h")
#import "../CYLPAGTabBarItemAnimator.h"
#else
#import "CYLPAGTabBarItemAnimator.h"
#endif
#if __has_include("../../../CYLTabBarController.h")
#import "../../../CYLTabBarController.h"
#else
#import "CYLTabBarController.h"
#endif

#if CYL_PAG_AVAILABLE

NSArray<NSDictionary *> *CYLTabBarItemsAttributesAddingPAGFiles(NSArray<NSDictionary *> *attributes,
                                                                 NSArray<NSString *> *pagFileNames,
                                                                 NSBundle *bundle) {
    // [EN] The generic helper with "<name>.pag": the same files, under the generic keys the PAG keys stand for.
    // [CN] 使用「名称.pag」调用通用工具函数：文件相同，使用 PAG key 所对应的通用 key。
    NSMutableArray *fileNames = [NSMutableArray arrayWithCapacity:pagFileNames.count];
    for (id name in pagFileNames) {
        BOOL hasName = [name isKindOfClass:[NSString class]] && [(NSString *)name length] > 0;
        [fileNames addObject:hasName ? [(NSString *)name stringByAppendingPathExtension:@"pag"] : @""];
    }
    return CYLTabBarItemsAttributesAddingAnimationFiles(attributes, fileNames, bundle);
}

#endif
