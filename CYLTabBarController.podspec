Pod::Spec.new do |s|
  s.name         = "CYLTabBarController"
  s.version      = "1.99.28"
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
  s.subspec 'Core' do |core|
    core.source_files = 'CYLTabBarController', 'CYLTabBarController/**/*.{h,m}'
    core.exclude_files = [
    'CYLTabBarController/**/LottieSwift/*.{h,m,Swift}'
#    ,'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-Swift/*.{h,m,swift}'
    ]
    core.resource = 'CYLTabBarController/**/CYLFlatDesignTabBarController.bundle'
    core.public_header_files = 'CYLTabBarController/**/*.h'

    
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
    #使用 swift 版本 lottie
    lottieswift.dependency 'lottie-ios', '>= 4.0.0'
    lottieswift.dependency 'CYLTabBarController/Core'
  end
  
#  s.subspec 'CYLFlatDesignTabBar' do |flatdesign|
#    flatdesign.dependency "CYLTabBarController/CYLFlatDesignTabBar-Swift"
#  end
#  
#  s.subspec 'CYLFlatDesignTabBar-Swift' do |flatdesign|
#    flatdesign.dependency "CYLTabBarController/Core"
#    flatdesign.source_files = 'CYLTabBarController/**/CYLFlatDesignTabBar/CYLFlatDesignTabBar-Swift/*.{h,m,swift}'
#  end
  
  
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'WARNING_CFLAGS' => [
    '-Werror=undeclared-selector',
    '-Werror=incomplete-implementation'
    ]
  }
  
end

