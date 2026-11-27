# [EN] CYLBadge: animated badges for any UIView, UIControl, UIBarButtonItem and UITabBarItem, as a pod and module of its own
#      (docs/Animated-Item-Badge.md, D1). Sources stay in `CYLTabBarController/CYLBadgeView/` (no file moves). It sees only
#      CYLUtils below it (the lifecycle library comes through CYLUtils, D8), never CYLAnimatedItem or CYLTabBarController.
#      Its resource bundle holds only `LICENSE` (every published package needs one); its strings are CYLUtils'.
#      Written statically, not linted yet; not wired into the other podspecs yet (step 8 of the guide).
# [CN] CYLBadge：为任意 UIView、UIControl、UIBarButtonItem、UITabBarItem 添加带动画的角标，作为独立的 pod 与模块（docs/Animated-Item-Badge.md，D1）。
#      源码仍在 `CYLTabBarController/CYLBadgeView/`（不移动文件）。它只看得到下面的 CYLUtils（生命周期库经由 CYLUtils，D8），
#      看不到 CYLAnimatedItem 与 CYLTabBarController。资源包只含 `LICENSE`（每个发布的包都需要一份）；字符串用 CYLUtils 的。
#      静态编写，尚未 lint；尚未接入其他 podspec（指南第 8 步）。
Pod::Spec.new do |s|
  s.name         = "CYLBadge"
  s.version      = "1.100.0"
  s.summary      = "Animated badges for any UIView, UIControl, UIBarButtonItem and UITabBarItem"
  s.description  = "[EN]Shows a dot, a number or text badge on any view with ten animations, styles and accessibility descriptions; the animated item of CYLTabBarController hosts it through CYLBadgeHosting. [CN]在任意视图上显示红点、数字或文字角标，带十种动画、样式与无障碍描述；CYLTabBarController 的动效 item 通过 CYLBadgeHosting 承载它。"
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.platform     = :ios, '15.0'
  s.swift_versions = ['5.0']
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.static_framework = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.source_files = 'CYLTabBarController/CYLBadgeView/**/*.{h,m,swift}'
  s.public_header_files = 'CYLTabBarController/CYLBadgeView/**/*.h'
  s.private_header_files = 'CYLTabBarController/CYLBadgeView/CYLBadgeViewDefines.h'
  s.resources    = ['CYLTabBarController/CYLBadgeView/Resources/CYLBadge.bundle']
  s.dependency 'CYLUtils', s.version.to_s
  s.frameworks   = 'UIKit', 'QuartzCore'
end
