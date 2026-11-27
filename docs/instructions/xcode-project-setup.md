# Xcode Project Setup [`xcode-project-setup`]

Whenever you work on a project that runs in Xcode (a demo, an example, any app with a Podfile), check these things first and fix what is missing.

## 1. Top of the Podfile

It must start with these lines. `<projectname>` is the name of the `.xcodeproj` in the same folder as the Podfile:

```ruby
platform :ios, '15.0'

ENV['SWIFT_VERSION'] = '5'

project '<projectname>.xcodeproj'
```

## 2. Bottom of the Podfile

It must end with this hook. If it is missing, append it at the bottom:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
    end
  end
end
```

CocoaPods allows only one `post_install` hook per Podfile. If the Podfile already has one (React Native's `react_native_post_install`, Flutter's `flutter_additional_ios_build_settings`), put the `targets.each` loop inside that hook instead of adding a second one. React Native pods need React Native's own minimum (15.1, `min_ios_version_supported`): those Podfiles use it in both places instead of 15.0, so no pod goes below what React Native supports. Flutter Podfiles keep Flutter's build configurations on the project line: `project 'Runner.xcodeproj', { 'Debug' => :debug, 'Profile' => :release, 'Release' => :release }`.

## 3. App icon and launch screen

If the project has no app icon or no launch screen, copy them from the Objective-C example (the root `CYLTabBarController.xcodeproj`). Look at every asset catalog the target compiles, not only its own folder: several demos share another demo's catalog (`Example-Rive` and RN `example-rive` use `Example-SwiftUI-Rive`'s, RN `example-pag` uses `Example-PAG`'s), and a second `AppIcon` set makes `actool` warn "used by multiple app icon sets". A launch screen can also be a build setting (`INFOPLIST_KEY_UILaunchStoryboardName`); `UILaunchScreen_Generation` alone is a blank screen and counts as none.

- **App icon**: `Example/Images.xcassets/AppIcon.appiconset`, copied into the project's asset catalog; set `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.
- **Launch screen**: `Example/Base.lproj/LaunchScreen.storyboard` and the image it shows, `Example/Images.xcassets/CYLTabBar.imageset`; set `UILaunchStoryboardName` to `LaunchScreen` in the Info.plist.
- Add the copied files to the target, keeping the project format of the `cyl-xcode-compat` skill (explicit file lists, no folder sync).

The root `Podfile` is the reference: it already has the top lines and the hook.

## 4. No copied sources

SonarCloud counts every copied file as duplicated code. Before copying a file from another demo, reference it instead:

- The HealthyHome demos (`Example-SwiftUI`, `Example-Swift-Carthage`, `Example-PAG`, `Example-Swift-SwiftManager`) compile the sources of `Example-Swift-03/HealthyHome` (file references with `sourceTree = SOURCE_ROOT` and a `../Example-Swift-03/HealthyHome/…` path). A demo-specific difference goes into that file behind a Swift compile condition set only in that demo's app target (`SWIFT_ACTIVE_COMPILATION_CONDITIONS = "$(inherited) …"`): `CYL_DEMO_PAG`, `CYL_DEMO_SWIFTUI`, `CYL_DEMO_FLATDESIGN_DELEGATE` (the FlatDesign delegate of Carthage and PAG).
- Sources shared by unrelated demos go into `Example-Shared/` (for example, `CYLPlusButtonSubclass+Layout.swift`, used by Example-Swift and Example-Swift-02; each keeps its own `plusButton()`). React Native examples reference `example/ios/…` (for example, `SceneDelegate.swift`).
- The sample configuration files are in `Example-Shared/Configurations/`, bundled as a folder reference.
- Test helpers shared by several test files go into one file (Android: `CYLTestSupport.kt`; scripts: `scripts/configuration-tests/confined_paths.py`).
