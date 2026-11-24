Pod::Spec.new do |s|
  s.name         = "CYLTabBarController"
  s.version      = "1.100.0"
  s.summary      = "Highly customizable tabBar and tabBarController for iOS"
  s.description  = "[EN]It is an iOS UI module library for adding animation to iOS tabbar items and icons with Lottie and Liquid Glass Animation.  [CN]【中国特色 TabBar】一行代码实现 Lottie +玻璃效果动画TabBar，支持中间带+号的TabBar样式，自带红点角标，支持动态刷新。【iOS26 & iPhone 17 supported】"
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.social_media_url = 'http://weibo.com/luohanchenyilong/'
  s.platform     = :ios, '15.0'
  s.swift_versions = ['5.0']
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.default_subspec = 'Core'
  s.static_framework = true
  # FIX: issue #535 — what Core and CYLBadgeView share: macros, helpers (`-cyl_setHidden:`, `-cyl_valueForKey:`,
  # `-cyl_tabButton`...), `+[CYLUtils isLiquidGlassActive]`, the string table (`CYLLocalizedString()`) and the resource
  # bundle. Both depend on it. Core 与 CYLBadgeView 共用的宏、工具方法、字符串表与资源包，二者都依赖它。
  s.subspec 'CYLUtils' do |utils|
    # [EN] Swift migration (docs/Swift-Migration.md): translated files live in `Swift/` folders next to the Objective-C ones.
    # [CN] Swift 迁移（docs/Swift-Migration.md）：已翻译的文件放在 Objective-C 文件旁的 `Swift/` 目录中。
    utils.source_files = 'CYLTabBarController/CYLUtils/**/*.{h,m,swift}'
    # [EN] The animation keys and URL options belong to the CYLAnimatedItem pod (CYLAnimatedItem.podspec), which CYLUtils
    #      depends on; CYLUtils re-exports it (Swift `@_exported import`, Objective-C headers).
    # [CN] 动画 key 与 URL 选项属于 CYLAnimatedItem pod（CYLAnimatedItem.podspec），CYLUtils 依赖它并重新导出（Swift `@_exported import`、
    #      Objective-C 头文件）。
    utils.exclude_files = 'CYLTabBarController/CYLUtils/CYLAnimationKeys.{h,m}', 'CYLTabBarController/CYLUtils/Swift/CYLAnimationURLOptions.swift', 'CYLTabBarController/CYLUtils/Swift/CYLAnimationKeyLookup.swift'
    utils.dependency 'CYLAnimatedItem/Core', s.version.to_s
    # [EN] The Liquid Glass rule (`+isLiquidGlassActive` forwards to it). [CN] 液态玻璃的判断规则（`+isLiquidGlassActive` 转发到它）。
    utils.dependency 'CYLLiquidGlass', s.version.to_s
    utils.public_header_files = 'CYLTabBarController/CYLUtils/**/*.h'
    # FIX: issue #216 — theme switching (skins): public headers in `CYLUtils/CYLComponents/CYLTheme/`, implementation in
    # Swift (`CYLUtils/Swift/`); its private helpers are internal Swift. [CN] 换肤（主题切换）：公开头文件位于
    # `CYLUtils/CYLComponents/CYLTheme/`，实现为 Swift（`CYLUtils/Swift/`）；私有辅助方法为 Swift 内部代码。
    # The library's resource bundle (localized strings now, images can go in it too), shipped as is, so its layout is
    # the same in every integration (see `CYLResourceBundle()`).
    utils.resources = ['CYLTabBarController/Resources/CYLTabBarController.bundle']
    utils.frameworks = 'UIKit'
  end

  # FIX: issue #535 — the badge component on its own: `pod 'CYLTabBarController/CYLBadgeView'`.
  # Badges with animations for any UIView, UIControl, UIBarButtonItem and UITabBarItem; no tab bar code.
  # Core depends on it, so every other subspec includes it and existing Podfiles need no change.
  # 单独使用角标组件：`pod 'CYLTabBarController/CYLBadgeView'`。为任意 UIView、UIControl、UIBarButtonItem、UITabBarItem 添加带动画的角标，
  # 不包含 TabBar 代码。Core 依赖它，因此其他所有 subspec 都已包含，现有 Podfile 无需修改。
  s.subspec 'CYLBadgeView' do |badge|
    badge.dependency 'CYLTabBarController/CYLUtils'
    # [EN] The badge posts its moments (shown, cleared, ready, animation start and stop) through CYLDeallocBlockExecutor (docs/Lifecycle-Library.md).
    # [CN] 角标通过 CYLDeallocBlockExecutor 发出时机事件（显示、清除、就绪、动画开始与结束）。
    badge.dependency 'CYLDeallocBlockExecutor', '~> 1.4'
    badge.source_files = 'CYLTabBarController/CYLBadgeView/**/*.{h,m,swift}'
    badge.public_header_files = 'CYLTabBarController/CYLBadgeView/**/*.h'
    # Shared by the badge sources only; tells a standalone build from one with Core (tab bar). 仅供角标源文件使用，用于区分是否包含 Core。
    badge.private_header_files = 'CYLTabBarController/CYLBadgeView/CYLBadgeViewDefines.h'
    badge.frameworks = 'UIKit', 'QuartzCore'
  end

  # [EN] CYLAnimationEngine: the animation engine alone (animator protocols, registry, factory, players, view animator),
  #      no tab bar and no Core. Every animation library subspec (LottieSwift, LottieObjectiveC, PAG, Rive, SVGA, GIF)
  #      depends on it; an app adds it directly only to register an animator of its own.
  # [CN] CYLAnimationEngine：仅动画引擎（animator 协议、注册表、工厂、播放器、view animator），不含 TabBar，也不依赖 Core。每个动画库
  #      子库（LottieSwift、LottieObjectiveC、PAG、Rive、SVGA、GIF）都依赖它；App 只有在注册自己的 animator 时才需要直接引入。
  s.subspec 'CYLAnimationEngine' do |engine|
    # [EN] The engine lives in the CYLAnimatedItem pod; kept as a name for compatibility. [CN] 引擎位于 CYLAnimatedItem pod；保留此名称以兼容。
    engine.dependency 'CYLTabBarController/CYLUtils'
    engine.dependency 'CYLAnimatedItem/Engine', s.version.to_s
  end

  # [EN] CYLAnimatedItem: CYLAnimatedItemView, an icon + title control to subclass (an accessory icon with its own tap,
  #      tap / long press / drag), as an independent component: `pod 'CYLTabBarController/CYLAnimatedItem'` brings
  #      CYLUtils and nothing else, no tab bar, no Core, no engine. Like the FlatDesign tab bar item, it is guarded at
  #      compile time (`CYL_ANIMATION_ENGINE_AVAILABLE`): static images by default; add the animation subspec of each
  #      file type to play (e.g. `pod 'CYLTabBarController/LottieSwift'`), which brings the engine, and the same view plays
  #      it with no code change. An app that never animates ships no engine and no animation library, however many engines
  #      are added later. Integration guide: docs/Animated-Item.md.
  # [CN] CYLAnimatedItem：可继承的 icon + title 控件 CYLAnimatedItemView（带自身点击的附加图标，点击 / 长按 / 拖拽），作为独立组件：
  #      `pod 'CYLTabBarController/CYLAnimatedItem'` 只带入 CYLUtils，不含 TabBar、Core 和引擎。与扁平样式 Tab 按钮一样在编译期用 guard
  #      （`CYL_ANIMATION_ENGINE_AVAILABLE`）隔离：默认只支持静态图片；要播放某种文件，加入对应的动画子库（例如
  #      `pod 'CYLTabBarController/LottieSwift'`），它会带入引擎，同一个控件无需修改代码即可播放。不使用动效的 App 不会带入引擎和任何
  #      动画库，以后引擎再多也不会增大其包体积。接入文档：docs/Animated-Item.md。
  s.subspec 'CYLAnimatedItem' do |item|
    # [EN] The component is the CYLAnimatedItem pod (module `CYLAnimatedItem`, no dependency on this pod); kept as a name
    #      for compatibility. [CN] 组件即 CYLAnimatedItem pod（模块 `CYLAnimatedItem`，不依赖本 pod）；保留此名称以兼容。
    item.dependency 'CYLAnimatedItem/Core', s.version.to_s
  end

  # [EN] The component's animation engines, one per type and the same for every type: CYLAnimatedItem (the component's
  #      core) + CYLAnimationEngine + that library's animator, never Core. `pod 'CYLTabBarController/CYLAnimatedItem'` plus
  #      `pod 'CYLTabBarController/CYLAnimatedItemLottieSwift'` plays Lottie without the tab bar. The tab bar's
  #      `CYLTabBarController/LottieSwift` (and PAG, Rive, SVGA, GIF…) is Core plus the matching engine below. A new
  #      animation type is one `CYLAnimatedItem<Type>` here and one tab bar subspec `<Type>` that depends on it. Flat
  #      names: CocoaPods allows `default_subspecs` only on the root spec, so children of CYLAnimatedItem would all come
  #      with it (and libpag / libpag-enterprise, iOS 13 / 14 requirements would collide in it).
  # [CN] 组件的动效引擎，每种类型一个，所有类型做法相同：CYLAnimatedItem（组件核心）+ CYLAnimationEngine + 该库的 animator，从不依赖
  #      Core。`pod 'CYLTabBarController/CYLAnimatedItem'` 加 `pod 'CYLTabBarController/CYLAnimatedItemLottieSwift'` 即可在没有 TabBar 的情况下
  #      播放 Lottie。TabBar 的 `CYLTabBarController/LottieSwift`（以及 PAG、Rive、SVGA、GIF……）等于 Core 加下面对应的引擎。新增动效类型只需
  #      在这里加一个 `CYLAnimatedItem<类型>`，再加一个依赖它的 TabBar 子库 `<类型>`。使用平铺名称：CocoaPods 只允许根 spec 设置
  #      `default_subspecs`，CYLAnimatedItem 的子库会被全部带入（libpag 与 libpag-enterprise、iOS 13 / 14 的要求也会在其中冲突）。
  s.subspec 'CYLAnimatedItemLottieObjectiveC' do |lottieobjc|
    lottieobjc.dependency 'CYLAnimatedItem/LottieObjectiveC', s.version.to_s
  end

  s.subspec 'CYLAnimatedItemLottie' do |lottie|
    lottie.dependency 'CYLTabBarController/CYLAnimatedItemLottieObjectiveC'
  end

  s.subspec 'CYLAnimatedItemLottieSwift' do |lottieswift|
    lottieswift.dependency 'CYLAnimatedItem/LottieSwift', s.version.to_s
    lottieswift.ios.deployment_target = '15.0'
  end

  s.subspec 'CYLAnimatedItemPAG' do |pag|
    pag.dependency 'CYLAnimatedItem/PAG', s.version.to_s
  end

  s.subspec 'CYLAnimatedItemPAGEnterprise' do |pagenterprise|
    pagenterprise.dependency 'CYLAnimatedItem/PAGEnterprise', s.version.to_s
  end

  s.subspec 'CYLAnimatedItemRive' do |rive|
    rive.dependency 'CYLAnimatedItem/Rive', s.version.to_s
    rive.ios.deployment_target = '15.0'
  end

  s.subspec 'CYLAnimatedItemSVGA' do |svga|
    svga.dependency 'CYLAnimatedItem/SVGA', s.version.to_s
  end

  s.subspec 'CYLAnimatedItemGIF' do |gif|
    gif.dependency 'CYLAnimatedItem/GIF', s.version.to_s
  end

  s.subspec 'Core' do |core|
    core.dependency 'CYLTabBarController/CYLUtils'
    core.dependency 'CYLTabBarController/CYLBadgeView'
    # [EN] The component's core (CYLAnimatedItemView, static images), never an animation engine: a tab bar animates only
    #      with an animation subspec (`CYL_ANIMATION_ENGINE_AVAILABLE`).
    # [CN] 组件核心（CYLAnimatedItemView，静态图片），从不依赖动效引擎：只有引入动画子库时 TabBar 才会播放动画（`CYL_ANIMATION_ENGINE_AVAILABLE`）。
    core.dependency 'CYLTabBarController/CYLAnimatedItem'
    # [EN] Lifecycle and dealloc blocks (the one-time layout block, docs/Lifecycle-Library.md). 1.4.0 is not on trunk yet:
    #      the Podfiles pin its branch until it is.
    # [CN] 生命周期与 dealloc block（只执行一次的布局 block，docs/Lifecycle-Library.md）。1.4.0 尚未发布到 trunk：发布前各 Podfile 指定其分支。
    core.dependency 'CYLDeallocBlockExecutor', '~> 1.4'
    core.source_files = 'CYLTabBarController', 'CYLTabBarController/**/*.{h,m}', 'CYLTabBarController/Swift/*.swift', 'CYLTabBarController/Swift/Deprecated/*.swift'
    core.exclude_files = [
    'CYLTabBarController/Package/**/*', # SPM-only: the umbrella headers, module maps and header links of the C targets
    'CYLTabBarController/CYLUtils/**/*', # the CYLUtils subspec above
    'CYLTabBarController/CYLBadgeView/**/*', # the CYLBadgeView subspec above
    # [EN] The engine (CYLAnimationEngine) and the animators (one subspec each). Core keeps the tab buttons' side of the engine
    #      (CYLTabBarItemAnimationEngine; Swift/UIControl+CYLTabBarItemAnimationPlayer.swift and the PAG helper
    #      Swift/CYLPAGTabBarItemAttributes.swift), compiled only with an animation subspec (`CYL_ANIMATION_ENGINE_AVAILABLE`,
    #      `CYL_PAG_AVAILABLE`).
    # [CN] 引擎（CYLAnimationEngine）与各 animator（各自一个子库）。Core 保留 Tab 按钮使用引擎的部分（CYLTabBarItemAnimationEngine、
    #      Swift/UIControl+CYLTabBarItemAnimationPlayer.swift 与 PAG 工具函数 Swift/CYLPAGTabBarItemAttributes.swift），只有引入动画子库时才编译
    #      （`CYL_ANIMATION_ENGINE_AVAILABLE`、`CYL_PAG_AVAILABLE`）。
    'CYLTabBarController/CYLTabBarItemAnimation/{GIF,Lottie,PAG,Rive,SVGA,Swift}/**/*',
    'CYLTabBarController/CYLTabBarItemAnimation/{CYLTabBarItemAnimator,CYLTabBarItemAnimationPlayer,CYLTabBarItemAnimatorRegistry,CYLTabBarItemAnimationFactory,CYLTabBarItemAnimationPlayableView,CYLTabBarItemViewAnimator}.{h,m}',
    'CYLTabBarController/CYLAnimatedItem/**/*', # the CYLAnimatedItem subspec above (the engine files are in CYLTabBarItemAnimation/)
    'CYLTabBarController/**/LottieSwift/*.{h,m,Swift}',
    'CYLTabBarController/RiveSwift/**/*', # the Rive subspec below (Swift bridge)
    'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/**/*.{swift}',
    'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/**/*.{h,m}',
    'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-Swift/**/*.{h,m,swift}'
    ]
    core.public_header_files = 'CYLTabBarController/**/*.h'
    # FIX: issue #604 — the interface to the CYLTabBarItemAnimation subspec, internal, not public API. Core does not depend
    # on that subspec: it checks at runtime that it is there.
    # 与 CYLTabBarItemAnimation 子库之间的接口，仅供内部使用，不属于公开 API。Core 不依赖该子库，而是在运行时检查它是否存在。
    core.private_header_files = 'CYLTabBarController/UIControl+CYLTabBarItemAnimation.h', 'CYLTabBarController/CYLTabBarItemAnimationService.h', 'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationEngine.h'
    # The resource bundle is part of CYLUtils (see above), which Core depends on. 资源包属于 Core 依赖的 CYLUtils。
    # FIX: issue #535 — the tab tap sound. 点击 Tab 的音效。
    core.frameworks = 'UIKit', 'AudioToolbox'

    
  end
  
  # FIX: issue #604 — the tab icon animation shared by every animation library, its own pod (subspec) pulled in only by
  # an animation library's subspec (Lottie, PAG…): Core does not depend on it. Dependency inversion on two levels:
  # - Core owns `CYLTabBarItemAnimationService` and calls only that; `CYLTabBarItemAnimationEngine` here implements it and
  #   hands itself to Core when it loads.
  # - The engine owns the public protocols, split by role: `CYLTabBarItemAnimationFileMatching` and
  #   `CYLTabBarItemAnimationViewFactory` (combined in `CYLTabBarItemAnimator`) and `CYLTabBarItemAnimationPlayer`; it
  #   creates views only through `CYLTabBarItemAnimationFactory` and finds libraries only through
  #   `CYLTabBarItemAnimatorRegistry`. Each library's animator and players live in that library's subspec
  #   (`CYLTabBarItemAnimation/<Library>/`), and the animator registers itself.
  # A new library is one more folder, one more animator class and one more subspec; nothing else changes.
  # 所有动画库共用的 Tab 图标动画，是独立的 pod（子库），只由某个动画库的子库（Lottie、PAG…）引入，Core 不依赖它。两层依赖反转：
  # - Core 定义 `CYLTabBarItemAnimationService` 并只调用它；这里的 `CYLTabBarItemAnimationEngine` 实现它，并在加载时交给 Core。
  # - 引擎按职责定义公开协议：`CYLTabBarItemAnimationFileMatching` 与 `CYLTabBarItemAnimationViewFactory`（组合为 `CYLTabBarItemAnimator`），以及
  #   `CYLTabBarItemAnimationPlayer`；只通过 `CYLTabBarItemAnimationFactory` 创建视图，只通过 `CYLTabBarItemAnimatorRegistry` 查找动画库。每个动画库的
  #   animator 与播放器放在该库的子库中（`CYLTabBarItemAnimation/<库名>/`），animator 自行注册。
  # 新增动画库只需新增一个目录、一个 animator 类和一个子库，其他代码都无需修改。
  s.subspec 'CYLTabBarItemAnimation' do |animation|
    # [EN] Kept for Podfiles that name it: Core (which holds the tab buttons' side of the engine) plus the engine.
    # [CN] 为写了它的 Podfile 保留：Core（包含 Tab 按钮使用引擎的部分）加引擎。
    animation.dependency 'CYLTabBarController/Core'
    animation.dependency 'CYLTabBarController/CYLAnimationEngine'
  end

  s.subspec 'Lottie' do |lottie|
    lottie.dependency 'CYLTabBarController/LottieObjectiveC'
  end
  
  s.subspec 'LottieObjectiveC' do |lottieobjc|
    # [EN] Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`, the Swift side of the C macro) is compiled.
    # [CN] 编译 Core 中只在有引擎时才编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`，对应同名 C 宏）。
    lottieobjc.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE' }
    # [EN] The tab bar (Core) plus the component's engine `CYLAnimatedItemLottieObjectiveC` (no Core).
    # [CN] TabBar（Core）加组件的动效引擎 `CYLAnimatedItemLottieObjectiveC`（不依赖 Core）。
    lottieobjc.dependency 'CYLTabBarController/Core'
    lottieobjc.dependency 'CYLTabBarController/CYLAnimatedItemLottieObjectiveC'
  end
  
  s.subspec "LottieSwift" do |lottieswift|
    # [EN] Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`, the Swift side of the C macro) is compiled.
    # [CN] 编译 Core 中只在有引擎时才编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`，对应同名 C 宏）。
    lottieswift.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE' }
    # [EN] The tab bar (Core) plus the component's engine `CYLAnimatedItemLottieSwift` (no Core).
    # [CN] TabBar（Core）加组件的动效引擎 `CYLAnimatedItemLottieSwift`（不依赖 Core）。
    lottieswift.dependency 'CYLTabBarController/Core'
    lottieswift.dependency 'CYLTabBarController/CYLAnimatedItemLottieSwift'
    lottieswift.ios.deployment_target = '15.0'
  end

  # FIX: issue #604 — PAG animations (Tencent libpag), the same way as Lottie: `pod 'CYLTabBarController/PAG'`.
  # Tabs then take `CYLTabBarPAGURL` / `CYLTabBarPAGFilePath` (".pag" files) like the Lottie keys. libpag is a binary
  # pod (libpag.xcframework), so no source is copied here; `CYLPAGTabBarItemAnimator` (CYLTabBarItemAnimation) finds it
  # with `__has_include(<libpag/PAGView.h>)`, with or without Lottie.
  # PAG 动画（腾讯 libpag），用法与 Lottie 相同：`pod 'CYLTabBarController/PAG'`。Tab 使用 `CYLTabBarPAGURL` /
  # `CYLTabBarPAGFilePath`（".pag" 文件），与 Lottie key 一致。libpag 为二进制 pod（libpag.xcframework），无需复制源码；
  # `CYLPAGTabBarItemAnimator`（CYLTabBarItemAnimation）通过 `__has_include(<libpag/PAGView.h>)` 识别，无论是否引入 Lottie。
  s.subspec 'PAG' do |pag|
    # [EN] Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`, the Swift side of the C macro) is compiled.
    # [CN] 编译 Core 中只在有引擎时才编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`，对应同名 C 宏）。
    # [EN] Also `CYL_PAG_AVAILABLE`: Core's PAG helper (Swift/CYLPAGTabBarItemAttributes.swift). [CN] 另加 `CYL_PAG_AVAILABLE`：Core 的 PAG 工具函数。
    pag.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE CYL_PAG_AVAILABLE' }
    # [EN] The tab bar (Core) plus the component's engine `CYLAnimatedItemPAG` (no Core).
    # [CN] TabBar（Core）加组件的动效引擎 `CYLAnimatedItemPAG`（不依赖 Core）。
    pag.dependency 'CYLTabBarController/Core'
    pag.dependency 'CYLTabBarController/CYLAnimatedItemPAG'
  end

  # FIX: issue #604 — the same with PAG Enterprise (`libpag-enterprise`: audio, 3D, movie layers…), like the two Lottie
  # flavors. It ships the same `libpag.xcframework`, so use either `PAG` or `PAGEnterprise`, not both.
  # 使用 PAG 企业版（`libpag-enterprise`：音频、3D、视频图层等），与 Lottie 的两个版本类似。它包含同样的 `libpag.xcframework`，
  # 因此 `PAG` 与 `PAGEnterprise` 二选一，不要同时引入。
  s.subspec 'PAGEnterprise' do |pagenterprise|
    # [EN] Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`, the Swift side of the C macro) is compiled.
    # [CN] 编译 Core 中只在有引擎时才编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`，对应同名 C 宏）。
    # [EN] Also `CYL_PAG_AVAILABLE`: Core's PAG helper (Swift/CYLPAGTabBarItemAttributes.swift). [CN] 另加 `CYL_PAG_AVAILABLE`：Core 的 PAG 工具函数。
    pagenterprise.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE CYL_PAG_AVAILABLE' }
    # [EN] The tab bar (Core) plus the component's engine `CYLAnimatedItemPAGEnterprise` (no Core).
    # [CN] TabBar（Core）加组件的动效引擎 `CYLAnimatedItemPAGEnterprise`（不依赖 Core）。
    pagenterprise.dependency 'CYLTabBarController/Core'
    pagenterprise.dependency 'CYLTabBarController/CYLAnimatedItemPAGEnterprise'
  end
  
  # Rive animations (`RiveRuntime`), the same way as Lottie and PAG: `pod 'CYLTabBarController/Rive'`.
  # Rive takes the short path of CYLTabBarItemAnimation: its Swift view (RiveSwift/) adopts
  # `CYLTabBarItemAnimationPlayableView` / `CYLTabBarItemAnimationViewProviding`, and `CYLRiveTabBarItemAnimator` only
  # registers a ready-made `CYLTabBarItemViewAnimator` for ".riv" files and declares Rive's keys and options; there is no
  # Rive animator or player logic, and nothing in Core. RiveRuntime is a binary pod with a Swift API; 6.29 is the first
  # version whose current API (`Worker`, `File`, `Rive`, `RiveUIView`) replaces the deprecated `RiveViewModel`.
  # Rive 动画（`RiveRuntime`），用法与 Lottie、PAG 相同：`pod 'CYLTabBarController/Rive'`。Rive 使用 CYLTabBarItemAnimation 的简便方式：
  # 其 Swift 视图（RiveSwift/）遵守 `CYLTabBarItemAnimationPlayableView` / `CYLTabBarItemAnimationViewProviding`，`CYLRiveTabBarItemAnimator`
  # 只为 ".riv" 文件注册一个现成的 `CYLTabBarItemViewAnimator`，并声明 Rive 的 key 与选项；没有 Rive 专用的 animator 或播放器逻辑，Core 中也
  # 没有任何 Rive 代码。RiveRuntime 为二进制 pod，提供 Swift API；6.29 起，其当前 API（`Worker`、`File`、`Rive`、`RiveUIView`）取代了已废弃的
  # `RiveViewModel`。
  s.subspec 'Rive' do |rive|
    # [EN] Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`, the Swift side of the C macro) is compiled.
    # [CN] 编译 Core 中只在有引擎时才编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`，对应同名 C 宏）。
    rive.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE' }
    # [EN] The tab bar (Core) plus the component's engine `CYLAnimatedItemRive` (no Core).
    # [CN] TabBar（Core）加组件的动效引擎 `CYLAnimatedItemRive`（不依赖 Core）。
    rive.dependency 'CYLTabBarController/Core'
    rive.dependency 'CYLTabBarController/CYLAnimatedItemRive'
    rive.ios.deployment_target = '15.0'
  end

  # FIX: issue #415 — SVGA tab icons (SVGAPlayer), integrated like Rive: the keys, the animator and its playable view.
  # SVGA Tab 图标（SVGAPlayer），接入方式与 Rive 相同：key、animator 及其可播放视图。
  s.subspec 'SVGA' do |svga|
    # [EN] Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`, the Swift side of the C macro) is compiled.
    # [CN] 编译 Core 中只在有引擎时才编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`，对应同名 C 宏）。
    svga.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE' }
    # [EN] The tab bar (Core) plus the component's engine `CYLAnimatedItemSVGA` (no Core).
    # [CN] TabBar（Core）加组件的动效引擎 `CYLAnimatedItemSVGA`（不依赖 Core）。
    svga.dependency 'CYLTabBarController/Core'
    svga.dependency 'CYLTabBarController/CYLAnimatedItemSVGA'
  end

  # FIX: issue #605 — GIF tab icons that play once when selected, like Lottie, PAG and Rive. A GIF given as an image
  # (`CYLTabBarItemImage`, `CYLTabBarItemImageURL`) loops and needs no subspec. No third-party library: ImageIO decodes it.
  # 选中时播放一次的 GIF Tab 图标，用法与 Lottie、PAG、Rive 相同。作为图片传入（`CYLTabBarItemImage`、`CYLTabBarItemImageURL`）的 GIF 循环播放，
  # 不需要子库。不依赖第三方库：由 ImageIO 解码。
  s.subspec 'GIF' do |gif|
    # [EN] Core's engine-only Swift code (`#if CYL_ANIMATION_ENGINE_AVAILABLE`, the Swift side of the C macro) is compiled.
    # [CN] 编译 Core 中只在有引擎时才编译的 Swift 代码（`#if CYL_ANIMATION_ENGINE_AVAILABLE`，对应同名 C 宏）。
    gif.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE' }
    # [EN] The tab bar (Core) plus the component's engine `CYLAnimatedItemGIF` (no Core).
    # [CN] TabBar（Core）加组件的动效引擎 `CYLAnimatedItemGIF`（不依赖 Core）。
    gif.dependency 'CYLTabBarController/Core'
    gif.dependency 'CYLTabBarController/CYLAnimatedItemGIF'
  end

  s.subspec 'CYLFlatDesignTabBar' do |flatdesign|
    flatdesign.dependency "CYLTabBarController/CYLFlatDesignTabBar-ObjectiveC"
    flatdesign.ios.deployment_target = '15.0' # depends on LottieSwift
  end
  

  s.subspec 'CYLFlatDesignTabBar-ObjectiveC' do |flatdesign|
    flatdesign.dependency "CYLTabBarController/LottieSwift"
    flatdesign.ios.deployment_target = '15.0' # depends on LottieSwift
    flatdesign.source_files = 'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/**/*.{h,m,swift}'
#    flatdesign.resource = 'CYLTabBarController/**/CYLFlatDesignUITabBarController.bundle'

  end
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Category-only files (e.g. `CAAnimation+CYLBadgeExtention.m`) export no global symbol, which makes libtool
    # warn "has no symbols" when CocoaPods builds a static framework.
    'OTHER_LIBTOOLFLAGS' => '-no_warning_for_no_symbols',
    'WARNING_CFLAGS' => [
    '-Werror=undeclared-selector',
    '-Werror=incomplete-implementation',
    # libpag's umbrella header `libpag.h` leaves out its C++ headers (pag/*.h), so every file of this pod that sees the
    # libpag module warns "umbrella header for module 'libpag' does not include header". Third-party module map: not ours to fix.
    # libpag 的 umbrella 头文件 `libpag.h` 未包含其 C++ 头文件（pag/*.h），本 pod 中看到 libpag 模块的文件都会报该警告。属于第三方模块映射，不由本库修复。
    '-Wno-incomplete-umbrella'
    ]
  }
  
end

