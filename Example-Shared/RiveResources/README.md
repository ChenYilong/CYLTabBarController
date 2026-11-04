# [CN]Rive 动效资源（安装时下载）
# [EN]Rive animation files (downloaded on install)

| 中文 | English |
|:---|:---|
| Rive 动画 Tab 图标使用的 `.riv` 文件。**文件本身不保存在本仓库中**：与 RiveRuntime pod 一样，在安装时下载。本目录只保存清单 [rive-resources.json](rive-resources.json)：每个来源包的名称、固定版本、归档的 SHA-256，以及从中取出的文件与各自的 SHA-256。说明见 [docs/Rive-Animation.md](../../docs/Rive-Animation.md)。 | `.riv` files for the Rive animated tab icons. **The files are not kept in this repository**: like the RiveRuntime pod, they are downloaded on install. This folder only keeps the manifest [rive-resources.json](rive-resources.json): each source package's name, pinned version and archive SHA-256, and the files taken from it with their own SHA-256. See [docs/Rive-Animation.md](../../docs/Rive-Animation.md). |
| **下载**：在 `Example-Rive` 中执行 `pod install`（Podfile 的 `pre_install` 会自动下载），或直接执行 `python3 scripts/fetch-animation-resources.py RiveResources`。已存在且 SHA-256 正确的文件会跳过；`--check` 只做校验。下载的文件已加入 `.gitignore`。 | **Download**: run `pod install` in `Example-Rive` (its Podfile's `pre_install` downloads them), or `python3 scripts/fetch-animation-resources.py RiveResources`. Files already present with the right SHA-256 are skipped; `--check` only verifies. The downloaded files are in `.gitignore`. |

| 子目录 / Folder | 来源 / Source | 许可 / License |
|:---|:---|:---|
| `rive_animated_icon/` | [rive_animated_icon](https://pub.dev/packages/rive_animated_icon) 2.1.1（[nikkieke/rive_animated_icons](https://github.com/nikkieke/rive_animated_icons)）`assets/icon-set.riv`：60 个图标，每个图标一个画板 / 60 icons, one artboard each | MIT |
