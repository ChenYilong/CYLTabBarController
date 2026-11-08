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

  install_modules_dependencies(s)
end
