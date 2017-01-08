Pod::Spec.new do |s|
  s.name         = "CYLTabBarController"
  s.version      = "1.10.0"
  s.summary      = "Highly customizable tabBar and tabBarController for iOS"
  s.description  = "CYLTabBarController is iPad and iPhone compatible. Supports landscape and portrait orientations and can be used inside UINavigationController."
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.social_media_url = 'http://weibo.com/luohanchenyilong/'
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
  s.source_files  = 'CYLTabBarController', 'CYLTabBarController/**/*.{h,m}'
  s.public_header_files = 'CYLTabBarController/**/*.h'
  s.requires_arc = true
end
