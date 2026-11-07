# [CN]PAG 动效资源（安装时下载）
# [EN]PAG animation files (downloaded on install)

| 中文 | English |
|:---|:---|
| 为 [#604](https://github.com/ChenYilong/CYLTabBarController/issues/604)（PAG 动画 Tab 图标）准备的 `.pag` 动效文件，来自腾讯 libpag 的 6 个官方仓库。**文件本身不保存在本仓库中**：与 libpag pod 一样，在安装时下载。本目录只保存清单 [pag-resources.json](pag-resources.json)：每个文件的来源仓库、固定的 commit、路径、大小与 SHA-256。说明见 [docs/PAG-Animation.md](../../docs/PAG-Animation.md)。 | `.pag` animation files for [#604](https://github.com/ChenYilong/CYLTabBarController/issues/604) (PAG animated tab icons), from Tencent's 6 official libpag repositories. **The files are not kept in this repository**: like the libpag pod, they are downloaded on install. This folder only keeps the manifest [pag-resources.json](pag-resources.json): each file's source repository, pinned commit, path, size and SHA-256. See [docs/PAG-Animation.md](../../docs/PAG-Animation.md). |
| **下载**：在 `Example-PAG` 中执行 `pod install`（Podfile 的 `pre_install` 会自动下载），或直接执行 `python3 scripts/fetch-animation-resources.py PAGResources`。已存在且 SHA-256 正确的文件会跳过；`--check` 只做校验。下载的文件已加入 `.gitignore`。 | **Download**: run `pod install` in `Example-PAG` (its Podfile's `pre_install` downloads them), or `python3 scripts/fetch-animation-resources.py PAGResources`. Files already present with the right SHA-256 are skipped; `--check` only verifies. The downloaded files are in `.gitignore`. |
| 共 44 个不重复的 `.pag` 文件（约 20 MB）以及各仓库的 LICENSE，下载到 `<仓库名>/` 子目录。多个仓库中内容相同的文件只下载一次，按 pag-ios → pag-enterprise-ios → pag-android → pag-flutter → pag-enterprise-android → pag-web 的顺序取第一份。 | 44 unique `.pag` files (about 20 MB) plus each repository's LICENSE, downloaded into `<repository>/` folders. A file with the same content in several repositories is downloaded once, from the first of pag-ios → pag-enterprise-ios → pag-android → pag-flutter → pag-enterprise-android → pag-web. |

| 子目录 / Folder | 来源 / Source | 许可 / License |
|:---|:---|:---|
| `tab-icons/` | `Example-PAG` 的 4 个 Tab 图标，名称表示用途 / The 4 tab icons of `Example-PAG`, named by use: [Tencent/libpag](https://github.com/Tencent/libpag) `assets`（`refreshing`、`wstask_circle`、`like`，Git LFS）、[libpag/pag-ios](https://github.com/libpag/pag-ios)（`2`） | Apache License 2.0 |
| `pag-ios/` | [libpag/pag-ios](https://github.com/libpag/pag-ios) `sample/pag-ios/assets` | Apache License 2.0 |
| `pag-enterprise-ios/` | [libpag/pag-enterprise-ios](https://github.com/libpag/pag-enterprise-ios) `sample/asset` | Apache License 2.0 |
| `pag-android/` | [libpag/pag-android](https://github.com/libpag/pag-android) `sample/app/src/main/assets` | MIT |
| `pag-flutter/` | [libpag/pag-flutter](https://github.com/libpag/pag-flutter) `example/data` | Apache License 2.0 |
| `pag-enterprise-android/` | [libpag/pag-enterprise-android](https://github.com/libpag/pag-enterprise-android) `sample/app/src/main/assets` | 商业许可 / Commercial（3 个文件与 pag-enterprise-ios 的相同，只下载其 LICENSE / its 3 files are identical to pag-enterprise-ios's; only its LICENSE is downloaded） |
| `pag-web/` | [libpag/pag-web](https://github.com/libpag/pag-web) | 无许可文件 / No license file |

| 中文 | English |
|:---|:---|
| **许可提示**：pag-enterprise-android 需要商业 PAG 授权，pag-web 没有许可文件。这些文件只是从原仓库下载到你的电脑上，本仓库不分发它们；在 App 中发布任何文件之前，请自行确认其使用条款。`pag-enterprise-ios/` 中的文件（音频、3D 等）需要 `pod 'CYLTabBarController/PAGEnterprise'` 才能完整显示。 | **License note**: pag-enterprise-android requires a commercial PAG license and pag-web has no license file. These files are only downloaded to your machine from their original repositories; this repository does not distribute them. Check the terms before you ship any of them in an app. The files in `pag-enterprise-ios/` (audio, 3D…) need `pod 'CYLTabBarController/PAGEnterprise'` to render fully. |
