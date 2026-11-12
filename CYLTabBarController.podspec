Pod::Spec.new do |s|
  s.name         = "CYLTabBarController"
  s.version      = "1.100.0"
  s.summary      = "Highly customizable tabBar and tabBarController for iOS"
  s.description  = "[EN]It is an iOS UI module library for adding animation to iOS tabbar items and icons with Lottie and Liquid Glass Animation.  [CN]【中国特色 TabBar】一行代码实现 Lottie +玻璃效果动画TabBar，支持中间带+号的TabBar样式，自带红点角标，支持动态刷新。【iOS26 & iPhone 17 supported】"
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.social_media_url = 'http://weibo.com/luohanchenyilong/'
  s.platform     = :ios, '12.0'
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
    badge.source_files = 'CYLTabBarController/CYLBadgeView/**/*.{h,m,swift}'
    badge.public_header_files = 'CYLTabBarController/CYLBadgeView/**/*.h'
    # Shared by the badge sources only; tells a standalone build from one with Core (tab bar). 仅供角标源文件使用，用于区分是否包含 Core。
    badge.private_header_files = 'CYLTabBarController/CYLBadgeView/CYLBadgeViewDefines.h'
    badge.frameworks = 'UIKit', 'QuartzCore'
  end

  s.subspec 'Core' do |core|
    core.dependency 'CYLTabBarController/CYLUtils'
    core.dependency 'CYLTabBarController/CYLBadgeView'
    core.source_files = 'CYLTabBarController', 'CYLTabBarController/**/*.{h,m}'
    core.exclude_files = [
    'CYLTabBarController/include/**/*', # SPM-only module map and header shims
    'CYLTabBarController/CYLUtils/**/*', # the CYLUtils subspec above
    'CYLTabBarController/CYLBadgeView/**/*', # the CYLBadgeView subspec above
    'CYLTabBarController/CYLTabBarItemAnimation/**/*', # the CYLTabBarItemAnimation subspec below
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
    core.private_header_files = 'CYLTabBarController/UIControl+CYLTabBarItemAnimation.h', 'CYLTabBarController/CYLTabBarItemAnimationService.h', 'CYLTabBarController/CYLTabBarController+CYLPrivate.h'
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
    animation.dependency 'CYLTabBarController/Core'
    animation.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/*.{h,m}'
    # Public: the protocols (matching, view factory, player), the registry, the factory and the player of a tab button.
    # 公开：协议（匹配、视图工厂、播放器）、注册表、工厂，以及 Tab 按钮的播放器。
    animation.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimator.h',
                                    'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayer.h',
                                    'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimatorRegistry.h',
                                    'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationFactory.h',
                                    'CYLTabBarController/CYLTabBarItemAnimation/UIControl+CYLTabBarItemAnimationPlayer.h',
                                    # The short path for libraries whose view plays itself (Rive): the protocols and the
                                    # ready-made animator. 视图自己会播放的动画库（Rive）的简便方式：协议与现成的 animator。
                                    'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayableView.h',
                                    'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemViewAnimator.h'
    animation.private_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationEngine.h'
    animation.frameworks = 'UIKit'
  end

  s.subspec 'Lottie' do |lottie|
    #指定2.5.3，使用 oc 版本 lottie
    lottie.dependency "CYLTabBarController/LottieObjectiveC"
  end
  
  s.subspec 'LottieObjectiveC' do |lottieobjc|
    lottieobjc.dependency 'CYLTabBarController/Core'
    lottieobjc.dependency 'CYLTabBarController/CYLTabBarItemAnimation'
    # The Lottie animator (#604), registered with CYLTabBarItemAnimatorRegistry. Lottie 的 animator（#604），向注册表注册。
    lottieobjc.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.{h,m}'
    lottieobjc.private_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.h'
    #指定2.5.3，使用 oc 版本 lottie
    lottieobjc.dependency "lottie-ios", '~> 2.5.3'
  end
  
  s.subspec "LottieSwift" do |lottieswift|
    # The Swift bridge, and the Lottie animator (#604). Swift 桥接，以及 Lottie 的 animator（#604）。
    lottieswift.source_files = 'CYLTabBarController/**/LottieSwift/*.{h,m,Swift}', 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.{h,m}'
    lottieswift.private_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.h'
    #使用 swift 版本 lottie；4.5.1 起提供 `removeValueProvider(for:)`（#442 的 Dark Mode 颜色恢复会用到）
    lottieswift.dependency 'lottie-ios', '>= 4.5.1'
    # lottie-ios 4.5.1 起要求 iOS 13
    lottieswift.ios.deployment_target = '13.0'
    lottieswift.dependency 'CYLTabBarController/Core'
    lottieswift.dependency 'CYLTabBarController/CYLTabBarItemAnimation'
  end

  # FIX: issue #604 — PAG animations (Tencent libpag), the same way as Lottie: `pod 'CYLTabBarController/PAG'`.
  # Tabs then take `CYLTabBarPAGURL` / `CYLTabBarPAGFilePath` (".pag" files) like the Lottie keys. libpag is a binary
  # pod (libpag.xcframework), so no source is copied here; `CYLPAGTabBarItemAnimator` (CYLTabBarItemAnimation) finds it
  # with `__has_include(<libpag/PAGView.h>)`, with or without Lottie.
  # PAG 动画（腾讯 libpag），用法与 Lottie 相同：`pod 'CYLTabBarController/PAG'`。Tab 使用 `CYLTabBarPAGURL` /
  # `CYLTabBarPAGFilePath`（".pag" 文件），与 Lottie key 一致。libpag 为二进制 pod（libpag.xcframework），无需复制源码；
  # `CYLPAGTabBarItemAnimator`（CYLTabBarItemAnimation）通过 `__has_include(<libpag/PAGView.h>)` 识别，无论是否引入 Lottie。
  s.subspec 'PAG' do |pag|
    pag.dependency 'CYLTabBarController/Core'
    pag.dependency 'CYLTabBarController/CYLTabBarItemAnimation'
    # The PAG animator (#604), registered with CYLTabBarItemAnimatorRegistry. PAG 的 animator（#604），向注册表注册。
    pag.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.{h,m}'
    # Public: the PAG keys and `CYLTabBarItemsAttributesAddingPAGFiles()` live here, not in Core.
    # 公开：PAG 的 key 与 `CYLTabBarItemsAttributesAddingPAGFiles()` 位于这里，而不是 Core 中。
    pag.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.h'
    pag.dependency 'libpag', '>= 4.0'
    # [EN] libpag's PAGSurface.h names the deprecated OpenGL ES classes; building its module would warn here.
    # [CN] libpag 的 PAGSurface.h 引用了已弃用的 OpenGL ES 类，编译其模块时会在此产生警告。
    pag.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GLES_SILENCE_DEPRECATION=1' }
  end

  # FIX: issue #604 — the same with PAG Enterprise (`libpag-enterprise`: audio, 3D, movie layers…), like the two Lottie
  # flavors. It ships the same `libpag.xcframework`, so use either `PAG` or `PAGEnterprise`, not both.
  # 使用 PAG 企业版（`libpag-enterprise`：音频、3D、视频图层等），与 Lottie 的两个版本类似。它包含同样的 `libpag.xcframework`，
  # 因此 `PAG` 与 `PAGEnterprise` 二选一，不要同时引入。
  s.subspec 'PAGEnterprise' do |pagenterprise|
    pagenterprise.dependency 'CYLTabBarController/Core'
    pagenterprise.dependency 'CYLTabBarController/CYLTabBarItemAnimation'
    # The PAG animator (#604), registered with CYLTabBarItemAnimatorRegistry. PAG 的 animator（#604），向注册表注册。
    pagenterprise.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.{h,m}'
    pagenterprise.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.h'
    pagenterprise.dependency 'libpag-enterprise', '>= 4.0'
    # libpag-enterprise 4.4.x–4.5.98: the module's umbrella `libpag.h` imports `PAGView+Audio.h`, which the framework does
    # not ship, so a modular import of libpag fails ("Could not build module 'libpag'"). The PAG animator imports only
    # `PAGView.h` (complete), so its file is compiled without modules.
    # libpag-enterprise 4.4.x–4.5.98：模块的 umbrella 头文件 `libpag.h` 引入了框架中不存在的 `PAGView+Audio.h`，以模块方式引入 libpag
    # 会失败（"Could not build module 'libpag'"）。PAG animator 只引入完整的 `PAGView.h`，因此它的文件不使用模块编译。
    pagenterprise.compiler_flags = '-fno-modules'
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
    rive.dependency 'CYLTabBarController/Core'
    rive.dependency 'CYLTabBarController/CYLTabBarItemAnimation'
    # The registration and keys, and the Swift view. 注册与 key，以及 Swift 视图。
    rive.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/Rive/*.{h,m}', 'CYLTabBarController/RiveSwift/*.swift'
    rive.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/Rive/*.h'
    rive.dependency 'RiveRuntime', '~> 6.29'
    # RiveRuntime requires iOS 14. RiveRuntime 要求 iOS 14。
    rive.ios.deployment_target = '14.0'
  end

  # FIX: issue #605 — GIF tab icons that play once when selected, like Lottie, PAG and Rive. A GIF given as an image
  # (`CYLTabBarItemImage`, `CYLTabBarItemImageURL`) loops and needs no subspec. No third-party library: ImageIO decodes it.
  # 选中时播放一次的 GIF Tab 图标，用法与 Lottie、PAG、Rive 相同。作为图片传入（`CYLTabBarItemImage`、`CYLTabBarItemImageURL`）的 GIF 循环播放，
  # 不需要子库。不依赖第三方库：由 ImageIO 解码。
  s.subspec 'GIF' do |gif|
    gif.dependency 'CYLTabBarController/Core'
    gif.dependency 'CYLTabBarController/CYLTabBarItemAnimation'
    gif.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/GIF/*.{h,m}'
    gif.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/GIF/*.h'
    gif.frameworks = 'ImageIO', 'QuartzCore'
  end

  s.subspec 'CYLFlatDesignTabBar' do |flatdesign|
    flatdesign.dependency "CYLTabBarController/CYLFlatDesignTabBar-ObjectiveC"
    flatdesign.ios.deployment_target = '13.0' # depends on LottieSwift
  end
  

  s.subspec 'CYLFlatDesignTabBar-ObjectiveC' do |flatdesign|
    flatdesign.dependency "CYLTabBarController/LottieSwift"
    flatdesign.ios.deployment_target = '13.0' # depends on LottieSwift
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

