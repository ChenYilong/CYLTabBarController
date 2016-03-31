Pod::Spec.new do |s|
  s.name         = "CYLTabBarController"
  s.version      = "1.2.2"
  s.summary      = "Highly customizable tabBar and tabBarController for iOS"
  s.description  = "CYLTabBarController is iPad and iPhone compatible. Supports landscape and portrait orientations and can be used inside UINavigationController."
  s.homepage     = "https://github.com/ChenYilong/CYLTabBarController"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "ChenYilong" => "luohanchenyilong@163.com" }
  s.platform     = :ios, '6.0'
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => s.version.to_s }
  s.source_files  = 'CYLTabBarController', 'CYLTabBarController/**/*.{h,m}'
  s.requires_arc = true
end
