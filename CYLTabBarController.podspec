Pod::Spec.new do |s|
  s.name         = "CYLTabBarController"
  s.version      = "1.24.1"
  s.summary      = "Highly customizable tabBar and tabBarController for iOS"
  s.description  = "CYLTabBarController is iPad and iPhone compatible. Supports landscape and portrait orientations and can be used inside UINavigationController."
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.social_media_url = 'http://weibo.com/luohanchenyilong/'
  s.platform     = :ios, '8.0'
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
 
  s.requires_arc = true


  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
  core.source_files  = 'CYLTabBarController', 'CYLTabBarController/**/*.{h,m}'
  core.public_header_files = 'CYLTabBarController/**/*.h'
  end

  s.subspec 'Lottie' do |lottie|
    lottie.dependency 'CYLTabBarController/Core'
    lottie.dependency "lottie-ios" , '~> 2.5.3'
  end
end
