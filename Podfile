# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
ENV['SWIFT_VERSION'] = '5'

target 'CYLTabBarController' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

#pod 'CYLTabBarController', '~> 1.99.18'        # 默认不依赖Lottie
#pod 'CYLTabBarController/Lottie', '~> 1.99.18'  # 依赖Lottie库

#pod 'CYLTabBarController', :path => './'
#pod 'CYLTabBarController/Lottie', :path => './'
pod 'CYLTabBarController/LottieSwift', :path => './'


pod 'MJRefresh'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
    end
  end
end
