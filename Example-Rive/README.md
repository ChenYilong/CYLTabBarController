# [CN]CYLTabBarController Rive 动画示例
# [EN]CYLTabBarController Rive animation demo

| 中文 | English |
|:---|:---|
| 本示例由 `Example-PAG` 复制而来，Tab 图标改用 Rive 动画：`pod 'CYLTabBarController/Rive'`，Tab 属性使用 `CYLTabBarRiveURL`、`CYLTabBarRiveAnimationURL()`（指定画板与状态机）、`CYLTabBarRiveSize` 与 `CYLTabBarRiveDarkColors`。说明见 [docs/Rive-Animation.md](../docs/Rive-Animation.md)。 | Copied from `Example-PAG`, with Rive tab icons: `pod 'CYLTabBarController/Rive'`, and the tab attributes use `CYLTabBarRiveURL`, `CYLTabBarRiveAnimationURL()` (artboard and state machine), `CYLTabBarRiveSize` and `CYLTabBarRiveDarkColors`. See [docs/Rive-Animation.md](../docs/Rive-Animation.md). |
| 运行：在本目录执行 `pod install`，打开 `HealthyHome.xcworkspace`。 | To run: `pod install` in this folder, then open `HealthyHome.xcworkspace`. |
| 3 个有动画的 Tab 使用同一个文件 `icon-set.riv` 中的画板 `HOME`、`BELL`、`USER`，第 2 个 Tab 保持图片（[#477](https://github.com/ChenYilong/CYLTabBarController/issues/477)）。该文件取自 [rive_animated_icon](https://pub.dev/packages/rive_animated_icon) 2.1.1（MIT），不保存在仓库中，`pod install` 时由 Podfile 的 `pre_install` 自动下载（`scripts/fetch-rive-resources.py`，固定版本并校验 SHA-256）。 | The 3 animated tabs use the artboards `HOME`, `BELL` and `USER` of one file, `icon-set.riv`; the 2nd tab keeps its images ([#477](https://github.com/ChenYilong/CYLTabBarController/issues/477)). The file comes from [rive_animated_icon](https://pub.dev/packages/rive_animated_icon) 2.1.1 (MIT) and is not in the repository: `pod install` downloads it from the Podfile's `pre_install` (`scripts/fetch-rive-resources.py`, pinned and SHA-256 checked). |
