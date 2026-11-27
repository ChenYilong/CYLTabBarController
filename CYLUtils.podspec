# [EN] CYLUtils: the bottom pod of this repository (docs/Animated-Item-Badge.md, D7 and D8). Macros, view helpers, themes
#      (skins), localization (`CYLLocalizedString`) and the resource bundle `CYLTabBarController.bundle` of the whole library.
#      It depends only on the lifecycle library and is its only direct user (D8: every other pod gets it through here).
#      Layering: CYLUtils <- CYLBadge <- CYLAnimatedItem <- CYLTabBarController. Same repository, tag and version as the others.
#      Module name `CYLUtilsKit`: a module with the same name as its class `CYLUtils` breaks Swift name lookup and
#      `.swiftinterface` files. Written statically, not linted yet; the sources still import CYLAnimatedItem in places
#      (step 3 of the guide), so this pod is not wired into the other podspecs yet.
# [CN] CYLUtils：本仓库最底层的 pod（docs/Animated-Item-Badge.md，D7 与 D8）。宏、视图辅助方法、主题（换肤）、本地化（`CYLLocalizedString`）
#      以及整个库的资源包 `CYLTabBarController.bundle`。它只依赖生命周期库，并且是其唯一的直接使用者（D8：其他 pod 都经由它获得）。
#      分层：CYLUtils <- CYLBadge <- CYLAnimatedItem <- CYLTabBarController。与其他 pod 同一仓库、同一 tag、同一版本。
#      模块名 `CYLUtilsKit`：与其类 `CYLUtils` 同名的模块会破坏 Swift 名称查找与 `.swiftinterface` 文件。静态编写，尚未 lint；
#      源码中仍有处导入 CYLAnimatedItem（指南第 3 步），因此本 pod 尚未接入其他 podspec。
Pod::Spec.new do |s|
  s.name         = "CYLUtils"
  s.module_name  = "CYLUtilsKit"
  s.version      = "1.100.0"
  s.summary      = "Shared helpers of CYLTabBarController's libraries: macros, view helpers, themes, localization"
  s.description  = "[EN]The bottom layer of CYLTabBarController's libraries: feature-check macros, UIView / UIViewController / UIImage helpers, theme switching (skins), CYLLocalizedString and the localized resource bundle. Re-exports the lifecycle library CYLDeallocBlockExecutor. [CN]CYLTabBarController 各库的最底层：功能检测宏、视图辅助方法、换肤、CYLLocalizedString 与本地化资源包，并重新导出生命周期库 CYLDeallocBlockExecutor。"
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.platform     = :ios, '15.0'
  s.swift_versions = ['5.0']
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.static_framework = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.source_files = 'CYLTabBarController/CYLUtils/**/*.{h,m,swift}'
  # [EN] The animation keys and URL options belong to the CYLAnimatedItem pod. [CN] 动画 key 与 URL 选项属于 CYLAnimatedItem pod。
  s.exclude_files = 'CYLTabBarController/CYLUtils/CYLAnimationKeys.{h,m}',
                    'CYLTabBarController/CYLUtils/Swift/CYLAnimationURLOptions.swift',
                    'CYLTabBarController/CYLUtils/Swift/CYLAnimationKeyLookup.swift'
  s.public_header_files = 'CYLTabBarController/CYLUtils/**/*.h'
  # [EN] The one owner of the library's string table and `LICENSE`: no other pod lists this bundle. [CN] 本库字符串表与 `LICENSE` 的唯一所有者：其他 pod 不再列出该资源包。
  s.resources    = ['CYLTabBarController/Resources/CYLTabBarController.bundle']
  # [EN] D8: the only direct user of the lifecycle library. [CN] D8：生命周期库的唯一直接使用者。
  s.dependency 'CYLDeallocBlockExecutor', '~> 1.4'
  s.frameworks   = 'UIKit'
end
