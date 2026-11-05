Pod::Spec.new do |s|
  s.name         = "CYLTabBarController"
  s.version      = "1.99.72"
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
    utils.source_files = 'CYLTabBarController/CYLUtils/**/*.{h,m}'
    utils.public_header_files = 'CYLTabBarController/CYLUtils/**/*.h'
    # FIX: issue #216 — theme switching (skins) lives in `CYLUtils/CYLComponents/CYLTheme/`; its private header stays private.
    # 换肤（主题切换）位于 `CYLUtils/CYLComponents/CYLTheme/`，其私有头文件不公开。
    utils.private_header_files = 'CYLTabBarController/CYLUtils/CYLComponents/CYLTheme/CYLThemePrivate.h'
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
    badge.source_files = 'CYLTabBarController/CYLBadgeView/**/*.{h,m}'
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
    'CYLTabBarController/**/LottieSwift/*.{h,m,Swift}',
    'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/**/*.{swift}',
    'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-ObjectiveC/**/*.{h,m}',
    'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-Swift/**/*.{h,m,swift}'
    ]
    core.public_header_files = 'CYLTabBarController/**/*.h'
    # The resource bundle is part of CYLUtils (see above), which Core depends on. 资源包属于 Core 依赖的 CYLUtils。
    # FIX: issue #535 — the tab tap sound. 点击 Tab 的音效。
    core.frameworks = 'UIKit', 'AudioToolbox'

    
  end
  
  s.subspec 'Lottie' do |lottie|
    #指定2.5.3，使用 oc 版本 lottie
    lottie.dependency "CYLTabBarController/LottieObjectiveC"
  end
  
  s.subspec 'LottieObjectiveC' do |lottieobjc|
    lottieobjc.dependency 'CYLTabBarController/Core'
    #指定2.5.3，使用 oc 版本 lottie
    lottieobjc.dependency "lottie-ios", '~> 2.5.3'
  end
  
  s.subspec "LottieSwift" do |lottieswift|
    lottieswift.source_files = 'CYLTabBarController/**/LottieSwift/*.{h,m,Swift}'
    #使用 swift 版本 lottie；4.5.1 起提供 `removeValueProvider(for:)`（#442 的 Dark Mode 颜色恢复会用到）
    lottieswift.dependency 'lottie-ios', '>= 4.5.1'
    # lottie-ios 4.5.1 起要求 iOS 13
    lottieswift.ios.deployment_target = '13.0'
    lottieswift.dependency 'CYLTabBarController/Core'
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
    '-Werror=incomplete-implementation'
    ]
  }
  
end

