// SPM-only shim: CocoaPods exposes this header as <CYLTabBarController/CYLTabBarItemAnimationFactory.h>.
// It keeps the `__has_include(<CYLTabBarController/...>)` check of CYL_ANIMATION_ENGINE_AVAILABLE true under SPM, which
// always builds the engine.
#import "../../CYLTabBarItemAnimation/CYLTabBarItemAnimationFactory.h"
