//
//  CYLPAGTabBarItemAttributes.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] The tab bar's PAG helper (declared in CYLPAGTabBarItemAnimator.h). It builds on Core's
//      `CYLTabBarItemsAttributesAddingAnimationFiles()`, so it is part of Core, and compiled only when the PAG subspec
//      (`PAG` or `PAGEnterprise`, which do not depend on Core) is in the build. The PAG header is looked up through the
//      header search paths only, never by a relative path, so a file on disk that the build does not compile is not used.
// [CN] TabBar 的 PAG 工具函数（声明于 CYLPAGTabBarItemAnimator.h）。它基于 Core 的 `CYLTabBarItemsAttributesAddingAnimationFiles()`，因此属于
//      Core，只有 PAG 子库（`PAG` 或 `PAGEnterprise`，二者不依赖 Core）参与构建时才编译。PAG 头文件只通过头文件搜索路径查找，不使用相对路径，
//      因此不会用到磁盘上存在但未参与编译的文件。
#if __has_include(<CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>) || __has_include(<CYLTabBarController/CYLPAGTabBarItemAnimator.h>)
#if __has_include(<CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>)
#import <CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>
#else
#import <CYLTabBarController/CYLPAGTabBarItemAnimator.h>
#endif
#define CYL_PAG_TAB_BAR_HELPER 1
#elif __has_include("CYLPAGTabBarItemAnimator.h")
#if __has_include(<CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>)
#import <CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>
#else
#import "CYLPAGTabBarItemAnimator.h"
#endif
#define CYL_PAG_TAB_BAR_HELPER 1
#else
#define CYL_PAG_TAB_BAR_HELPER 0
#endif

#if CYL_PAG_TAB_BAR_HELPER
#if __has_include("../../CYLTabBarController.h")
#import "../../CYLTabBarController.h"
#else
#import "CYLTabBarController.h"
#endif
#endif

#if CYL_PAG_TAB_BAR_HELPER && CYL_PAG_AVAILABLE

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
