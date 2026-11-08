#
# The Flutter plugin of CYLTabBarController. In this repository the example uses the local library
# (example/ios/Podfile: pod 'CYLTabBarController', :path => '../../../..').
#
Pod::Spec.new do |s|
  s.name             = 'flutter_cyltabbar'
  s.version          = '0.1.0'
  s.summary          = 'CYLTabBarController (iOS) and its Android port as a Flutter widget'
  s.description      = 'The native tab bar of CYLTabBarController, made from a configuration, as a Flutter widget.'
  s.homepage         = 'https://github.com/ChenYilong/CYLTabBarController'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ChenYilong' => 'luohanchenyilong@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_cyltabbar/Sources/flutter_cyltabbar/**/*.{h,m}'
  s.public_header_files = 'flutter_cyltabbar/Sources/flutter_cyltabbar/include/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'CYLTabBarController'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
