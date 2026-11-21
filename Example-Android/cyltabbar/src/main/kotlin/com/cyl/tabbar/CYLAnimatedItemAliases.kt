@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

/*
 * [EN] The animated item component (`:cylanimateditem`, Maven `cyltabbarcontroller-animateditem`) is its own library in
 *      package `com.cyl.animateditem` and depends on nothing of the tab bar. These aliases keep the names the tab bar has
 *      always used in `com.cyl.tabbar` working for Kotlin callers; new code imports `com.cyl.animateditem` directly.
 *      Java callers use `com.cyl.animateditem` (Kotlin type aliases are not visible to Java).
 * [CN] 动效组件（`:cylanimateditem`，Maven `cyltabbarcontroller-animateditem`）是独立的库，位于包 `com.cyl.animateditem`，不依赖 TabBar 的任何代码。
 *      这些别名使 TabBar 一直在 `com.cyl.tabbar` 中使用的名称对 Kotlin 调用方仍然可用；新代码直接导入 `com.cyl.animateditem`。
 *      Java 调用方使用 `com.cyl.animateditem`（Kotlin 类型别名对 Java 不可见）。
 */

/**
 * [EN] `com.cyl.animateditem.CYLTabBarAnimationOption`. [CN] 即 `com.cyl.animateditem.CYLTabBarAnimationOption`。
 */
typealias CYLTabBarAnimationOption = com.cyl.animateditem.CYLTabBarAnimationOption

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimatorPriority`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimatorPriority`。
 */
typealias CYLTabBarItemAnimatorPriority = com.cyl.animateditem.CYLTabBarItemAnimatorPriority

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationPlayer`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationPlayer`。
 */
typealias CYLTabBarItemAnimationPlayer = com.cyl.animateditem.CYLTabBarItemAnimationPlayer

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationBasePlayer`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationBasePlayer`。
 */
typealias CYLTabBarItemAnimationBasePlayer = com.cyl.animateditem.CYLTabBarItemAnimationBasePlayer

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationFileMatching`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationFileMatching`。
 */
typealias CYLTabBarItemAnimationFileMatching = com.cyl.animateditem.CYLTabBarItemAnimationFileMatching

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationViewFactory`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationViewFactory`。
 */
typealias CYLTabBarItemAnimationViewFactory = com.cyl.animateditem.CYLTabBarItemAnimationViewFactory

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimator`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimator`。
 */
typealias CYLTabBarItemAnimator = com.cyl.animateditem.CYLTabBarItemAnimator

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimatorRegistering`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimatorRegistering`。
 */
typealias CYLTabBarItemAnimatorRegistering = com.cyl.animateditem.CYLTabBarItemAnimatorRegistering

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimatorRegistry`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimatorRegistry`。
 */
typealias CYLTabBarItemAnimatorRegistry = com.cyl.animateditem.CYLTabBarItemAnimatorRegistry

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationViewMaking`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationViewMaking`。
 */
typealias CYLTabBarItemAnimationViewMaking = com.cyl.animateditem.CYLTabBarItemAnimationViewMaking

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationFactory`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationFactory`。
 */
typealias CYLTabBarItemAnimationFactory = com.cyl.animateditem.CYLTabBarItemAnimationFactory

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationPlayableView`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationPlayableView`。
 */
typealias CYLTabBarItemAnimationPlayableView = com.cyl.animateditem.CYLTabBarItemAnimationPlayableView

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationViewProviding`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationViewProviding`。
 */
typealias CYLTabBarItemAnimationViewProviding = com.cyl.animateditem.CYLTabBarItemAnimationViewProviding

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemViewAnimator`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemViewAnimator`。
 */
typealias CYLTabBarItemViewAnimator = com.cyl.animateditem.CYLTabBarItemViewAnimator

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationFiles`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationFiles`。
 */
typealias CYLTabBarItemAnimationFiles = com.cyl.animateditem.CYLTabBarItemAnimationFiles

/**
 * [EN] `com.cyl.animateditem.CYLReflection`. [CN] 即 `com.cyl.animateditem.CYLReflection`。
 */
typealias CYLReflection = com.cyl.animateditem.CYLReflection

/**
 * [EN] `com.cyl.animateditem.CYLLottieTabBarItemAnimator`. [CN] 即 `com.cyl.animateditem.CYLLottieTabBarItemAnimator`。
 */
typealias CYLLottieTabBarItemAnimator = com.cyl.animateditem.CYLLottieTabBarItemAnimator

/**
 * [EN] `com.cyl.animateditem.CYLPAGTabBarItemAnimator`. [CN] 即 `com.cyl.animateditem.CYLPAGTabBarItemAnimator`。
 */
typealias CYLPAGTabBarItemAnimator = com.cyl.animateditem.CYLPAGTabBarItemAnimator

/**
 * [EN] `com.cyl.animateditem.CYLRiveTabBarItemAnimator`. [CN] 即 `com.cyl.animateditem.CYLRiveTabBarItemAnimator`。
 */
typealias CYLRiveTabBarItemAnimator = com.cyl.animateditem.CYLRiveTabBarItemAnimator

/**
 * [EN] `com.cyl.animateditem.CYLRiveTabBarItemAnimationView`. [CN] 即 `com.cyl.animateditem.CYLRiveTabBarItemAnimationView`。
 */
typealias CYLRiveTabBarItemAnimationView = com.cyl.animateditem.CYLRiveTabBarItemAnimationView

/**
 * [EN] `com.cyl.animateditem.CYLAnimatedItemResources`. [CN] 即 `com.cyl.animateditem.CYLAnimatedItemResources`。
 */
typealias CYLAnimatedItemResources = com.cyl.animateditem.CYLAnimatedItemResources

/**
 * [EN] `com.cyl.animateditem.CYLSize`. [CN] 即 `com.cyl.animateditem.CYLSize`。
 */
typealias CYLSize = com.cyl.animateditem.CYLSize

/**
 * [EN] `com.cyl.animateditem.CYLOffset`. [CN] 即 `com.cyl.animateditem.CYLOffset`。
 */
typealias CYLOffset = com.cyl.animateditem.CYLOffset

/**
 * [EN] `com.cyl.animateditem.CYLGIFTabBarItemAnimator`. [CN] 即 `com.cyl.animateditem.CYLGIFTabBarItemAnimator`。
 */
typealias CYLGIFTabBarItemAnimator = com.cyl.animateditem.CYLGIFTabBarItemAnimator

/**
 * [EN] `com.cyl.animateditem.CYLGIFTabBarItemAnimationView`. [CN] 即 `com.cyl.animateditem.CYLGIFTabBarItemAnimationView`。
 */
typealias CYLGIFTabBarItemAnimationView = com.cyl.animateditem.CYLGIFTabBarItemAnimationView

/**
 * [EN] `com.cyl.animateditem.CYLGIFDrawable`. [CN] 即 `com.cyl.animateditem.CYLGIFDrawable`。
 */
typealias CYLGIFDrawable = com.cyl.animateditem.CYLGIFDrawable

/**
 * [EN] `com.cyl.animateditem.CYLSVGATabBarItemAnimator`. [CN] 即 `com.cyl.animateditem.CYLSVGATabBarItemAnimator`。
 */
typealias CYLSVGATabBarItemAnimator = com.cyl.animateditem.CYLSVGATabBarItemAnimator

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationFailureHandling`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationFailureHandling`。
 */
typealias CYLTabBarItemAnimationFailureHandling = com.cyl.animateditem.CYLTabBarItemAnimationFailureHandling

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationFailure`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationFailure`。
 */
typealias CYLTabBarItemAnimationFailure = com.cyl.animateditem.CYLTabBarItemAnimationFailure

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimationKeys`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimationKeys`。
 */
typealias CYLTabBarItemAnimationKeys = com.cyl.animateditem.CYLTabBarItemAnimationKeys

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimatorPriorityDefault`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimatorPriorityDefault`。
 */
const val CYLTabBarItemAnimatorPriorityDefault: CYLTabBarItemAnimatorPriority = com.cyl.animateditem.CYLTabBarItemAnimatorPriorityDefault

/**
 * [EN] `com.cyl.animateditem.CYLTabBarItemAnimatorPriorityFallback`. [CN] 即 `com.cyl.animateditem.CYLTabBarItemAnimatorPriorityFallback`。
 */
const val CYLTabBarItemAnimatorPriorityFallback: CYLTabBarItemAnimatorPriority = com.cyl.animateditem.CYLTabBarItemAnimatorPriorityFallback

/**
 * [EN] `com.cyl.animateditem.CYLTabBarAnimationURLWithOptions`. [CN] 即 `com.cyl.animateditem.CYLTabBarAnimationURLWithOptions`。
 */
fun CYLTabBarAnimationURLWithOptions(fileURL: String?, options: Map<CYLTabBarAnimationOption, String>?): String? =
    com.cyl.animateditem.CYLTabBarAnimationURLWithOptions(fileURL, options)

/**
 * [EN] `com.cyl.animateditem.CYLTabBarAnimationFileAndOptions`. [CN] 即 `com.cyl.animateditem.CYLTabBarAnimationFileAndOptions`。
 */
@androidx.annotation.RestrictTo(androidx.annotation.RestrictTo.Scope.LIBRARY_GROUP)
fun CYLTabBarAnimationFileAndOptions(url: String): Pair<String, Map<String, String>> = com.cyl.animateditem.CYLTabBarAnimationFileAndOptions(url)

/**
 * [EN] `com.cyl.animateditem.CYLTabBarAnimationFileExtension`. [CN] 即 `com.cyl.animateditem.CYLTabBarAnimationFileExtension`。
 */
@androidx.annotation.RestrictTo(androidx.annotation.RestrictTo.Scope.LIBRARY_GROUP)
fun CYLTabBarAnimationFileExtension(url: String): String = com.cyl.animateditem.CYLTabBarAnimationFileExtension(url)
