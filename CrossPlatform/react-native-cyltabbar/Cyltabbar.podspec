require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "Cyltabbar"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/ChenYilong/CYLTabBarController.git", :tag => "v#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  s.private_header_files = "ios/**/*.h"

  # The iOS library itself. In this repository the example app takes it from the local sources
  # (`pod 'CYLTabBarController', :path => ...` in example/ios/Podfile), so a change in the library shows at once.
  s.dependency "CYLTabBarController"
  # [EN] With static libraries, the library's generated Swift header (CYLTabBarHostView and the other classes translated to
  #      Swift) is in its "Swift Compatibility Header" folder; with frameworks it is in the framework.
  # [CN] 使用静态库时，库生成的 Swift 头文件（CYLTabBarHostView 等已翻译为 Swift 的类）位于其 "Swift Compatibility Header" 目录；使用 framework 时位于 framework 中。
  s.pod_target_xcconfig = {
    "HEADER_SEARCH_PATHS" => "\"$(PODS_CONFIGURATION_BUILD_DIR)/CYLTabBarController/Swift Compatibility Header\""
  }

  install_modules_dependencies(s)
end
