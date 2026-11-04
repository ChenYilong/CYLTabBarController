# [CN]CYLTabBarController PAG 动画示例
# [EN]CYLTabBarController PAG animation demo

| 中文 | English |
|:---|:---|
| 本示例由 `Example-Swift-03` 复制而来，Tab 图标改用 PAG 动画（腾讯 libpag，[#604](https://github.com/ChenYilong/CYLTabBarController/issues/604)）：`pod 'CYLTabBarController/PAG'`，Tab 属性使用 `CYLTabBarItemsAttributesAddingPAGFiles` 与 `CYLTabBarPAGSize`。说明见 [docs/PAG-Animation.md](../docs/PAG-Animation.md)。 | Copied from `Example-Swift-03`, with PAG tab icons (Tencent libpag, [#604](https://github.com/ChenYilong/CYLTabBarController/issues/604)): `pod 'CYLTabBarController/PAG'`, and the tab attributes use `CYLTabBarItemsAttributesAddingPAGFiles` and `CYLTabBarPAGSize`. See [docs/PAG-Animation.md](../docs/PAG-Animation.md). |
| 运行：在本目录执行 `pod install`，打开 `HealthyHome.xcworkspace`。 | To run: `pod install` in this folder, then open `HealthyHome.xcworkspace`. |
| 4 个 Tab 使用的 `.pag` 文件（`Example-Shared/PAGResources/pag-ios` 中的 `1`、`2`、`22`、`test2`，取自 [libpag/pag-ios](https://github.com/libpag/pag-ios)，Apache License 2.0）不保存在仓库中，`pod install` 时由 Podfile 的 `pre_install` 自动下载（`scripts/fetch-pag-resources.py`，固定版本并校验 SHA-256）。 | The `.pag` files of the 4 tabs (`1`, `2`, `22` and `test2` in `Example-Shared/PAGResources/pag-ios`, from [libpag/pag-ios](https://github.com/libpag/pag-ios), Apache License 2.0) are not in the repository: `pod install` downloads them from the Podfile's `pre_install` (`scripts/fetch-pag-resources.py`, pinned and SHA-256 checked). |
