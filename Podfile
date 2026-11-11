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

#only for test
#pod 'CYLTabBarController/CYLFlatDesignTabBar', :git => 'https://github.com/ChenYilong/CYLTabBarController.git', :branch => 'fix/flatdesign-tabbar-position-during-transition'
# Placeholders (empty data, no network) and pull to refresh, at the latest commit of CYLTableViewPlaceHolder on any
# branch (AGENTS.md, "Depending on CYLTableViewPlaceHolder"; find it with scripts/latest-cyl-commit.sh). Replaces MJRefresh.
pod 'CYLTableViewPlaceHolder', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '44e16c465e2c046bc425e3917bb86e4e912d088c'
# Every animation type of CYLTableViewPlaceHolder: each demo list uses another one (CYLDemoPlaceholderAnimation).
pod 'CYLTableViewPlaceHolder/LottieSwift', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '44e16c465e2c046bc425e3917bb86e4e912d088c'
pod 'CYLTableViewPlaceHolder/PAG', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '44e16c465e2c046bc425e3917bb86e4e912d088c'
pod 'CYLTableViewPlaceHolder/Rive', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '44e16c465e2c046bc425e3917bb86e4e912d088c'
pod 'CYLTableViewPlaceHolder/GIF', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '44e16c465e2c046bc425e3917bb86e4e912d088c'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
    end
  end
end
