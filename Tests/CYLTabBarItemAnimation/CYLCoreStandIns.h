//
//  CYLCoreStandIns.h
//  CYLTabBarItemAnimation tests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLTabBarItemAnimationService.h"

NS_ASSUME_NONNULL_BEGIN

// [EN] The C entry points the engine calls. Core is Swift (`@_cdecl`, Swift/UIControl+CYLTabBarItemAnimation.swift and
//      Swift/CYLTabBarItemAnimationStyleRegistry.swift), and since step 118 only the generated Swift interface declares them, which this
//      macOS harness does not build. run.sh force-includes this header (`-include`); main.m defines the functions.
// [CN] 引擎调用的 C 入口。Core 是 Swift（`@_cdecl`），自第 118 步起只有生成的 Swift 接口声明它们，而本 macOS 测试不构建它。run.sh 用 `-include`
//      强制包含本头文件；函数由 main.m 定义。
FOUNDATION_EXTERN void CYLTabBarItemAnimationSetService(id<CYLTabBarItemAnimationService> _Nullable service);
FOUNDATION_EXTERN id<CYLTabBarItemAnimationStyleSource> CYLTabBarItemAnimationDefaultStyleSource(void);
FOUNDATION_EXTERN id<CYLTabBarItemAnimationHost> CYLTabBarItemAnimationDefaultHost(void);

NS_ASSUME_NONNULL_END
