# [EN] CYLLiquidGlass: Liquid Glass as a base library: the gate every CYLTabBarController component asks
#      (`CYLLiquidGlass.isActive()`) and a glass background view (`CYLLiquidGlassView`). It depends on no other pod of
#      this repository, like CYLAnimatedItem: CYLTabBarController (its `CYLUtils.isLiquidGlassActive()` forwards here)
#      and CollectionViewClassifyMenu depend on it, never the other way round. Guide: docs/Liquid-Glass-Component.md.
#      Same repository, tag and version as CYLTabBarController.
# [CN] CYLLiquidGlass：作为基础库的液态玻璃：CYLTabBarController 各组件共用的判断（`CYLLiquidGlass.isActive()`）与玻璃背景视图
#      （`CYLLiquidGlassView`）。与 CYLAnimatedItem 一样不依赖本仓库的其他 pod：CYLTabBarController（其
#      `CYLUtils.isLiquidGlassActive()` 转发到这里）与 CollectionViewClassifyMenu 依赖它，反之从不依赖。文档：
#      docs/Liquid-Glass-Component.md。与 CYLTabBarController 同一仓库、同一 tag、同一版本。
Pod::Spec.new do |s|
  s.name         = "CYLLiquidGlass"
  s.version      = "1.100.0"
  s.summary      = "Liquid Glass for iOS as a base library: the availability rule and a glass background view"
  s.description  = "[EN]CYLLiquidGlass.isActive() is the one rule for Liquid Glass (iOS 27 and later; iOS 26 unless UIDesignRequiresCompatibility) and CYLLiquidGlassView a UIGlassEffect background tinted and clipped to a corner radius, drawing nothing where there is no glass. [CN]CYLLiquidGlass.isActive() 是液态玻璃的唯一判断规则（iOS 27 及以上；iOS 26 上未设置 UIDesignRequiresCompatibility 时），CYLLiquidGlassView 是可着色、可按圆角裁剪的 UIGlassEffect 背景，没有玻璃时不绘制。"
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.platform     = :ios, '15.0'
  s.swift_versions = ['5.0']
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.static_framework = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.source_files = 'CYLTabBarController/CYLLiquidGlass/Swift/*.swift'
  s.resources    = ['CYLTabBarController/CYLLiquidGlass/Resources/CYLLiquidGlass.bundle']
  s.frameworks   = 'UIKit'
end
