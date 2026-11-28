# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'
ENV['SWIFT_VERSION'] = '5'
project 'CYLTabBarController.xcodeproj'
target 'CYLTabBarController' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

#pod 'CYLTabBarController', '~> 1.99.39'        # 默认不依赖Lottie
#pod 'CYLTabBarController/LottieObjectiveC', '~> 1.99.39'  # 依赖Lottie Objective-C库
#pod 'CYLTabBarController/LottieSwift', '~> 1.99.39'  # 依赖Lottie Swift库

#pod 'CYLTabBarController', :path => './'
#pod 'CYLTabBarController/LottieObjectiveC', :path => './'
#pod 'CYLTabBarController/LottieSwift', :path => './'
pod 'CYLTabBarController/CYLFlatDesignTabBar', :path => './'
pod 'CYLDeallocBlockExecutor', :git => 'https://github.com/ChenYilong/CYLDeallocBlockExecutor.git', :commit => '4276a6dab5a428ccc3a5f3f347eab991881fb97c' # TODO: remove after CYLDeallocBlockExecutor 1.4.0 is published (docs/Lifecycle-Library.md)
# [EN] The animated item component's own pod (CYLAnimatedItem.podspec), by the same path until it is on the trunk.
# [CN] 动效组件独立的 pod（CYLAnimatedItem.podspec），发布到 trunk 之前按相同路径引入。
pod 'CYLUtils', :path => './'
pod 'CYLBadge', :path => './'
pod 'CYLAnimatedItem', :path => './'
# [EN] The demo sections are a ClassifyMenu tag list (docs/instructions/examples.md, "Demo lists that need sections use a ClassifyMenu tag list"). Pinned by commit; no copy of its sources.
# [CN] 演示 section 使用 ClassifyMenu 的 TagList（docs/instructions/examples.md）。按 commit 固定；不复制其源码。
# [EN] iOS pins 6bb6e2b8 (feat/harmony, 2026-11-29: the tag list style API the badge demos use). HarmonyOS, Android and the mini program read
#      CrossPlatform/harmonyos-cyltabbar/classifymenu.pin (9a4c1908). TODO: neither commit contains the other; return to one pin when ClassifyMenu has a commit with both.
# [CN] iOS 固定 6bb6e2b8（feat/harmony，2026-11-29：角标 Demo 使用的标签列表样式 API）。鸿蒙、Android、小程序读取
#      CrossPlatform/harmonyos-cyltabbar/classifymenu.pin（9a4c1908）。TODO：两个提交互不包含；待 ClassifyMenu 提供同时包含两者的提交后恢复为同一个 pin。
pod 'CollectionViewClassifyMenu', :git => 'https://github.com/ChenYilong/CollectionViewClassifyMenu.git', :commit => '6bb6e2b895f0698133d90af1362d5b5344b54ddf'

#only for test
#pod 'CYLTabBarController/CYLFlatDesignTabBar', :git => 'https://github.com/ChenYilong/CYLTabBarController.git', :branch => 'fix/flatdesign-tabbar-position-during-transition'
# Placeholders (empty data, no network) and pull to refresh, at the latest commit of CYLTableViewPlaceHolder on any
# branch (AGENTS.md, "Depending on CYLTableViewPlaceHolder"; find it with scripts/latest-cyl-commit.sh). Replaces MJRefresh.
pod 'CYLTableViewPlaceHolder', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => 'b9e6af5c17ccda2c6c279083826c439b2765de1c'
# Every animation type of CYLTableViewPlaceHolder: each demo list uses another one (CYLDemoPlaceholderAnimation).
pod 'CYLTableViewPlaceHolder/LottieSwift', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => 'b9e6af5c17ccda2c6c279083826c439b2765de1c'
pod 'CYLTableViewPlaceHolder/PAG', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => 'b9e6af5c17ccda2c6c279083826c439b2765de1c'
pod 'CYLTableViewPlaceHolder/Rive', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => 'b9e6af5c17ccda2c6c279083826c439b2765de1c'
pod 'CYLTableViewPlaceHolder/GIF', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => 'b9e6af5c17ccda2c6c279083826c439b2765de1c'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
    end
  end
end
