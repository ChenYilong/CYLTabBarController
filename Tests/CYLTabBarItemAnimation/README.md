# [CN]Tab 图标动画测试
# [EN]Tab bar item animation tests

| 中文 | English |
|:---|:---|
| 测试同时注册多个动画库（Lottie、PAG、Rive）、每个 Tab 只使用其中一个时的行为：由有值的 key 选择动画库、不混用不同动画库的 key、只使用通用 key 时由扩展名决定、未引入的动画库的 key 被忽略，以及 Rive 方式中 URL 选项的传递。测试使用 `CYLTabBarItemAnimation` 子库中真实的注册表、视图 animator 与播放器源码，以及从源码中提取的真实 Core 函数。说明见 [docs/Tab-Bar-Item-Animation.md](../../docs/Tab-Bar-Item-Animation.md)。 | Tests what happens with several animation libraries registered at once (Lottie, PAG, Rive) and each tab using one of them: the keys with a value choose the library, keys of different libraries are not mixed, generic keys fall back to the file's extension, keys of a library that is not installed are ignored, and the URL options reach the view on Rive's path. They use the real registry, view animator and player sources of the `CYLTabBarItemAnimation` subspec, and the real Core functions, extracted from their files. See [docs/Tab-Bar-Item-Animation.md](../../docs/Tab-Bar-Item-Animation.md). |
| 运行：在 Mac 上执行 `Tests/CYLTabBarItemAnimation/run.sh`（需要 Xcode 命令行工具）；GitHub Actions 的「Animation tests」工作流在相关文件变化时自动运行。 | To run: `Tests/CYLTabBarItemAnimation/run.sh` on a Mac (Xcode command line tools); the "Animation tests" GitHub Actions workflow runs it when the related files change. |
