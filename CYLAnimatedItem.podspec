# [EN] CYLAnimatedItem: the animated icon + title component (CYLAnimatedItemView), its animation engine and one subspec per
#      animation type, as a pod and module of its own. It depends on no other pod of this repository: not on
#      CYLTabBarController. Apps write `import CYLAnimatedItem` (Objective-C: `@import CYLAnimatedItem;`).
#      CYLTabBarController depends on it (its Core on `CYLAnimatedItem/Core`, its animation subspecs on the matching
#      `CYLAnimatedItem/<Type>`), never the other way round. Guide: docs/Animated-Item.md.
#      Same repository, same tag and same version as CYLTabBarController: until both are on the CocoaPods trunk, a Podfile
#      that takes CYLTabBarController by path or commit names this pod the same way.
# [CN] CYLAnimatedItem：动效图标 + 标题组件（CYLAnimatedItemView）、其动画引擎以及每种动画类型一个子库，作为独立的 pod 与模块。
#      它不依赖本仓库的任何其他 pod：不依赖 CYLTabBarController。App 写 `import CYLAnimatedItem`（Objective-C：`@import CYLAnimatedItem;`）。
#      CYLTabBarController 依赖它（Core 依赖 `CYLAnimatedItem/Core`，动画子库依赖对应的 `CYLAnimatedItem/<Type>`），反之从不依赖。
#      文档：docs/Animated-Item.md。与 CYLTabBarController 同一仓库、同一 tag、同一版本：两者发布到 CocoaPods trunk 之前，按路径或 commit
#      引入 CYLTabBarController 的 Podfile 以同样方式写上本 pod。
Pod::Spec.new do |s|
  s.name         = "CYLAnimatedItem"
  s.version      = "1.100.0"
  s.summary      = "An animated icon + title view for iOS: Lottie, PAG, Rive, SVGA and GIF, static images without them"
  s.description  = "[EN]CYLAnimatedItemView shows an icon and a title, plays any animation file of its engine (Lottie, PAG, Rive, SVGA, GIF), falls back to the static image, then to a placeholder, and takes an accessory and drag gestures. Shared by CYLTabBarController's tab buttons, CollectionViewClassifyMenu's tags and CYLTableViewPlaceHolder's placeholders. [CN]动效图标 + 标题组件：播放 Lottie、PAG、Rive、SVGA、GIF，没有引擎时显示静态图片与占位图，支持附加图标与拖拽手势。"
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.platform     = :ios, '15.0'
  s.swift_versions = ['5.0']
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.static_framework = true
  # [EN] A module even when the app builds static libraries (no use_frameworks!): Swift code imports it
  #      (`import CYLAnimatedItem`, e.g. CYLTabBarController's CYLUtils and CollectionViewClassifyMenu's core), and without
  #      DEFINES_MODULE that import failed unless every Podfile added `:modular_headers => true` for this pod.
  # [CN] 即使 App 构建静态库（没有 use_frameworks!）也提供 module：Swift 代码会导入它（`import CYLAnimatedItem`，例如 CYLTabBarController 的
  #      CYLUtils 与 CollectionViewClassifyMenu 的核心），没有 DEFINES_MODULE 时，除非每个 Podfile 都为本 pod 加上 `:modular_headers => true`，
  #      否则导入会失败。
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.default_subspec = 'Core'

  # [EN] The component: the view, its macros, the generic animation keys and URL options, and the resource bundle (the
  #      tab-icon-sized placeholder, LICENSE, POLICY.md). Static images only: no engine, no animation library.
  # [CN] 组件本身：视图、宏、通用动画 key 与 URL 选项，以及资源包（适合 Tab 图标尺寸的占位图、LICENSE、POLICY.md）。只显示静态图片：
  #      不含引擎与动画库。
  s.subspec 'Core' do |core|
    core.source_files = 'CYLTabBarController/CYLAnimatedItem/*.{h,m}',
                        'CYLTabBarController/CYLUtils/CYLAnimationKeys.{h,m}',
                        'CYLTabBarController/CYLUtils/Swift/CYLAnimationURLOptions.swift',
                        'CYLTabBarController/CYLUtils/Swift/CYLAnimationKeyLookup.swift',
                        # [EN] Swift views built on CYLAnimatedItemView (CYLAnimatedItemStackView). [CN] 基于 CYLAnimatedItemView 的 Swift 视图（CYLAnimatedItemStackView）。
                        'CYLTabBarController/CYLAnimatedItem/Swift/*.swift'
    core.public_header_files = 'CYLTabBarController/CYLAnimatedItem/*.h', 'CYLTabBarController/CYLUtils/CYLAnimationKeys.h'
    core.resources = ['CYLTabBarController/CYLAnimatedItem/Resources/CYLAnimatedItem.bundle']
    core.frameworks = 'UIKit'
  end

  # [EN] The animation engine: animators, players, the registry and the factory. With it `CYL_ANIMATION_ENGINE_AVAILABLE` is 1.
  # [CN] 动画引擎：animator、播放器、注册表与工厂。引入后 `CYL_ANIMATION_ENGINE_AVAILABLE` 为 1。
  s.subspec 'Engine' do |engine|
    engine.dependency 'CYLAnimatedItem/Core'
    files = %w[CYLTabBarItemAnimator CYLTabBarItemAnimationPlayer CYLTabBarItemAnimatorRegistry CYLTabBarItemAnimationFactory
               CYLTabBarItemAnimationPlayableView CYLTabBarItemViewAnimator]
    engine.source_files = files.map { |name| "CYLTabBarController/CYLTabBarItemAnimation/#{name}.{h,m}" } +
                          ['CYLTabBarController/CYLTabBarItemAnimation/Swift/*.swift']
    engine.public_header_files = files.map { |name| "CYLTabBarController/CYLTabBarItemAnimation/#{name}.h" }
    engine.frameworks = 'UIKit'
    # [EN] The Swift CYLAnimatedItemView (Core) plays animations only with the engine: Swift cannot read the C macro, so the
    #      engine sets the same name as a Swift condition. [CN] Swift 编写的 CYLAnimatedItemView（Core）只有引擎参与时才播放动画：Swift
    #      读不到 C 宏，因此由引擎设置同名的 Swift 条件。
    engine.pod_target_xcconfig = { 'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) CYL_ANIMATION_ENGINE_AVAILABLE' }
  end

  # [EN] One subspec per animation type, the same shape for each: Core + Engine + the library.
  # [CN] 每种动画类型一个子库，结构相同：Core + Engine + 动画库。
  s.subspec 'LottieObjectiveC' do |lottieobjc|
    lottieobjc.dependency 'CYLAnimatedItem/Engine'
    # [EN] The lottie-ios 2.x player is Swift (Lottie/ObjectiveC/); the animator stays Objective-C (+load). [CN] lottie-ios 2.x 播放器为 Swift（Lottie/ObjectiveC/）；animator 保留为 Objective-C（+load）。
    lottieobjc.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.{h,m}', 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/ObjectiveC/*.swift'
    lottieobjc.private_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.h'
    lottieobjc.dependency 'lottie-ios', '~> 2.5.3'
  end

  s.subspec 'Lottie' do |lottie|
    lottie.dependency 'CYLAnimatedItem/LottieObjectiveC'
  end

  s.subspec 'LottieSwift' do |lottieswift|
    lottieswift.dependency 'CYLAnimatedItem/Engine'
    lottieswift.source_files = 'CYLTabBarController/LottieSwift/*.swift', 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.{h,m}'
    lottieswift.private_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/Lottie/*.h'
    lottieswift.dependency 'lottie-ios', '>= 4.5.1'
    lottieswift.ios.deployment_target = '15.0'
  end

  s.subspec 'PAG' do |pag|
    pag.dependency 'CYLAnimatedItem/Engine'
    pag.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.{h,m,swift}'
    pag.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.h'
    pag.dependency 'libpag', '>= 4.0'
    pag.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GLES_SILENCE_DEPRECATION=1' }
  end

  s.subspec 'PAGEnterprise' do |pagenterprise|
    pagenterprise.dependency 'CYLAnimatedItem/Engine'
    pagenterprise.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.{h,m,swift}'
    pagenterprise.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/PAG/*.h'
    pagenterprise.dependency 'libpag-enterprise', '>= 4.0'
    pagenterprise.compiler_flags = '-fno-modules'
  end

  s.subspec 'Rive' do |rive|
    rive.dependency 'CYLAnimatedItem/Engine'
    rive.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/Rive/*.{h,m}', 'CYLTabBarController/RiveSwift/*.swift'
    rive.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/Rive/*.h'
    rive.dependency 'RiveRuntime', '~> 6.29'
    rive.ios.deployment_target = '15.0'
  end

  s.subspec 'SVGA' do |svga|
    svga.dependency 'CYLAnimatedItem/Engine'
    svga.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/SVGA/*.{h,m}'
    svga.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/SVGA/*.h'
    svga.dependency 'SVGAPlayerLite', '~> 1.0', '>= 1.0.8'
  end

  s.subspec 'GIF' do |gif|
    gif.dependency 'CYLAnimatedItem/Engine'
    gif.source_files = 'CYLTabBarController/CYLTabBarItemAnimation/GIF/*.{h,m,swift}'
    gif.public_header_files = 'CYLTabBarController/CYLTabBarItemAnimation/GIF/*.h'
    gif.frameworks = 'ImageIO', 'QuartzCore'
  end

  # [EN] Tests that need an animation library (remote Lottie files: download, play or fall back). `pod lib lint` builds and runs
  #      them on a simulator; they depend on the component only.
  # [CN] 需要动画库的测试（远程 Lottie 文件：下载后播放或回退）。`pod lib lint` 会在模拟器上构建并运行；只依赖组件本身。
  s.test_spec 'Tests' do |test|
    # [EN] lottie-ios 2.x (iOS 12, like the root spec); LottieSwift needs iOS 13, which a test spec of a 12.0 root cannot resolve.
    # [CN] lottie-ios 2.x（iOS 12，与根 spec 相同）；LottieSwift 需要 iOS 13，12.0 的根 spec 下的 test spec 无法解析。
    test.dependency 'CYLAnimatedItem/LottieObjectiveC'
    # [EN] One Swift file, so the test bundle links the Swift runtime that the component's Swift code needs
    #      (otherwise Xcode 26 fails with "Undefined symbol: __swift_FORCE_LOAD_$_swiftCompatibility56").
    # [CN] 一个 Swift 文件，使测试 bundle 链接组件 Swift 代码所需的 Swift 运行时（否则 Xcode 26 报
    #      "Undefined symbol: __swift_FORCE_LOAD_$_swiftCompatibility56"）。
    test.source_files = 'CYLAnimatedItemTests/*.{h,m,swift}'
    test.frameworks = 'XCTest', 'UIKit'
  end
end
