# Changelog

## Unreleased

### Breaking: the minimum iOS version is 15.0 / 最低 iOS 版本提高到 15.0

- **[EN]** `CYLTabBarController.podspec`, `CYLAnimatedItem.podspec` and `Package.swift` now require iOS 15.0 (they were iOS 12.0, with the LottieSwift and FlatDesign subspecs at 13.0 and Rive at 14.0). Apps that support iOS 12 to 14 stay on the previous release. The Example projects and their Podfiles are at 15.0 too. Reason: the Swift migration (docs/Swift-Migration.md) uses iOS 13+ UIKit types (`UITabBarItemAppearance`, `UITabBarItemStateAppearance`) without availability guards, which broke builds at deployment target 12.0 (CYLTableViewPlaceHolder's "iOS 12 runtime" job); current Xcode cannot build below iOS 15 anyway.
- **[CN]** `CYLTabBarController.podspec`、`CYLAnimatedItem.podspec` 与 `Package.swift` 现在要求 iOS 15.0（此前为 iOS 12.0，LottieSwift 与 FlatDesign 子库为 13.0，Rive 为 14.0）。仍支持 iOS 12 到 14 的 App 请继续使用上一个版本。Example 工程及其 Podfile 同样为 15.0。原因：Swift 迁移（docs/Swift-Migration.md）使用了 iOS 13+ 的 UIKit 类型（`UITabBarItemAppearance`、`UITabBarItemStateAppearance`）且没有可用性判断，导致以部署目标 12.0 构建失败（CYLTableViewPlaceHolder 的「iOS 12 runtime」任务）；当前 Xcode 本来也无法构建 iOS 15 以下。
- **TODO:** the podspec `version` is not bumped here; the maintainer picks the release number. Dead `#available(iOS 13...)` branches are removed in a separate cleanup step. / podspec 的 `version` 在这里没有修改，由维护者决定发布版本号；失效的 `#available(iOS 13...)` 分支在单独的清理步骤中移除。
