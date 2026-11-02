# [CN]CYLTabBarController 常见问题
# [EN]CYLTabBarController FAQ

| 中文 | English |
|:---|:---|
| 本文整理自 GitHub Issues 中标记为 `Q-A` 的使用问答。原 issue 已关闭，每条问答都附有原 issue 链接，可前往查看完整讨论。 | This page collects the usage questions from GitHub Issues labeled `Q-A`. The original issues are closed; each entry links to them for the full discussion. |
| 遇到使用问题，请先查阅本页和 [README](../README.md)，仍未解决再提 issue；bug 与新需求请直接提 issue。 | For usage questions, check this page and the [README](../README.md) first, and open an issue only if they don't help. Report bugs and feature requests as issues directly. |

## [CN]目录
## [EN]Contents

| 中文 | English |
|:---|:---|
| [1. 安装、运行与调试](#cn1-安装运行与调试) | [1. Installation, running and debugging](#en1-installation-running-and-debugging) |
| [2. TabBarController 的使用](#cn2-tabbarcontroller-的使用) | [2. Using TabBarController](#en2-using-tabbarcontroller) |
| [3. PlusButton（中间凸起按钮）](#cn3-plusbutton中间凸起按钮) | [3. PlusButton (the raised center button)](#en3-plusbutton-the-raised-center-button) |
| [4. TabBarItem 的图标、文字与布局](#cn4-tabbaritem-的图标文字与布局) | [4. TabBarItem icons, titles and layout](#en4-tabbaritem-icons-titles-and-layout) |
| [5. 外观：背景、分割线、阴影与深色模式](#cn5-外观背景分割线阴影与深色模式) | [5. Appearance: background, separator, shadow and Dark Mode](#en5-appearance-background-separator-shadow-and-dark-mode) |
| [6. 角标 Badge](#cn6-角标-badge) | [6. Badges](#en6-badges) |
| [7. Lottie 动画](#cn7-lottie-动画) | [7. Lottie animations](#en7-lottie-animations) |
| [8. 导航、转场与手势](#cn8-导航转场与手势) | [8. Navigation, transitions and gestures](#en8-navigation-transitions-and-gestures) |
| [9. 与第三方库的兼容](#cn9-与第三方库的兼容) | [9. Compatibility with third-party libraries](#en9-compatibility-with-third-party-libraries) |
| [10. 其他](#cn10-其他) | [10. Other](#en10-other) |

## [CN]1. 安装、运行与调试
## [EN]1. Installation, running and debugging

### [CN]CocoaPods 安装失败：`RPC failed; curl 56 ... SSL_ERROR_SYSCALL` / `early EOF`
### [EN]CocoaPods installation fails: `RPC failed; curl 56 ... SSL_ERROR_SYSCALL` / `early EOF`

| 中文 | English |
|:---|:---|
| 来源：[#534](https://github.com/ChenYilong/CYLTabBarController/issues/534)、[#520](https://github.com/ChenYilong/CYLTabBarController/issues/520) | Source: [#534](https://github.com/ChenYilong/CYLTabBarController/issues/534), [#520](https://github.com/ChenYilong/CYLTabBarController/issues/520) |
| 报错发生在 `git clone` 阶段，是本机到 GitHub 的网络中断，与本库代码无关。可以： | The error happens during `git clone`: the network connection to GitHub dropped. It is unrelated to the library code. You can: |
| 1. 重试，或为 git 配置可用的网络代理； | 1. Retry, or configure a working proxy for git. |
| 2. 按 README 的 [清除 CocoaPods 本地缓存](../README.md#cn清除-cocoapods-本地缓存) 与 [升级本地 CocoaPods 源](../README.md#cn升级本地-cocoapods-源) 操作后重新 `pod install`； | 2. Follow [Clear the CocoaPods cache](../README.md#enclear-the-cocoapods-cache) and [Update the local CocoaPods repository](../README.md#enupdate-the-local-cocoapods-repository) in the README, then run `pod install` again. |
| 3. 仍失败时，可改用 Carthage 或 Swift Package Manager 导入（见 README）。 | 3. If it still fails, integrate with Carthage or Swift Package Manager instead (see the README). |

### [CN]Demo 无法运行
### [EN]The demo does not run

| 中文 | English |
|:---|:---|
| 来源：[#398](https://github.com/ChenYilong/CYLTabBarController/issues/398)、[#506](https://github.com/ChenYilong/CYLTabBarController/issues/506) | Source: [#398](https://github.com/ChenYilong/CYLTabBarController/issues/398), [#506](https://github.com/ChenYilong/CYLTabBarController/issues/506) |
| 1. 在仓库根目录执行 `pod install`，然后打开 `CYLTabBarController.xcworkspace`（不是 `.xcodeproj`）； | 1. Run `pod install` in the repository root, then open `CYLTabBarController.xcworkspace` (not the `.xcodeproj`). |
| 2. 如果 `pod install` 报错，请把完整日志贴到新 issue。 | 2. If `pod install` fails, post the full log in a new issue. |
| 早期版本的 Demo 存在资源路径问题（[#367](https://github.com/ChenYilong/CYLTabBarController/issues/367)），当前版本的示例源码已统一整理，请使用最新代码。 | Early versions of the demo had broken resource paths ([#367](https://github.com/ChenYilong/CYLTabBarController/issues/367)). The example sources have since been reorganized; use the latest code. |

### [CN]有 Swift 版本吗？
### [EN]Is there a Swift version?

| 中文 | English |
|:---|:---|
| 来源：[#400](https://github.com/ChenYilong/CYLTabBarController/issues/400) | Source: [#400](https://github.com/ChenYilong/CYLTabBarController/issues/400) |
| 本库使用 Objective-C 编写，可直接在 Swift 项目中使用。仓库中提供了多个 Swift Demo（`Example-Swift*` 目录），用法见 README 的 [在 Swift 项目中使用 CYLTabBarController](../README.md#cn在-swift-项目中使用-cyltabbarcontroller)。 | The library is written in Objective-C and works in Swift projects as is. The repository has several Swift demos (the `Example-Swift*` directories); see [Using CYLTabBarController in a Swift project](../README.md#enusing-cyltabbarcontroller-in-a-swift-project) in the README. |

### [CN]控制台打印 `Class CYLTabBar overrides the -traitCollection getter, which is not supported`
### [EN]The console prints `Class CYLTabBar overrides the -traitCollection getter, which is not supported`

| 中文 | English |
|:---|:---|
| 来源：[#458](https://github.com/ChenYilong/CYLTabBarController/issues/458)、[#443](https://github.com/ChenYilong/CYLTabBarController/issues/443) | Source: [#458](https://github.com/ChenYilong/CYLTabBarController/issues/458), [#443](https://github.com/ChenYilong/CYLTabBarController/issues/443) |
| 旧版本的 `CYLTabBar` 重写了 `-traitCollection`，iOS 13 起会打印该警告。新版本已移除这段代码。升级到最新版本后，如仍有警告： | Old versions of `CYLTabBar` overrode `-traitCollection`, which iOS 13 and later warn about. That code has been removed. If the warning remains after upgrading: |
| 1. Xcode 中执行 Clean Build Folder 后重新编译； | 1. Run Clean Build Folder in Xcode and build again. |
| 2. 确认 `Podfile.lock` 中的版本确实已更新（可先注释该依赖 `pod install`，再取消注释重新 `pod install`）。 | 2. Check that `Podfile.lock` really has the new version (comment out the dependency and run `pod install`, then uncomment it and run `pod install` again). |

### [CN]集成后项目无法打断点
### [EN]Breakpoints stop working after integration

| 中文 | English |
|:---|:---|
| 来源：[#402](https://github.com/ChenYilong/CYLTabBarController/issues/402) | Source: [#402](https://github.com/ChenYilong/CYLTabBarController/issues/402) |
| 本库不会影响断点。请检查当前 Scheme 的 Build Configuration 是否为 Debug，以及 Build Settings 中 `Debug Information Format`、`Optimization Level`（Debug 应为 `None [-O0]`）等设置。 | The library does not affect breakpoints. Check that the scheme's Build Configuration is Debug, and the `Debug Information Format` and `Optimization Level` build settings (Debug should be `None [-O0]`). |

## [CN]2. TabBarController 的使用
## [EN]2. Using TabBarController

### [CN]继承 CYLTabBarController 后，`tabBar:didSelectItem:` 不回调
### [EN]`tabBar:didSelectItem:` is not called in a CYLTabBarController subclass

| 中文 | English |
|:---|:---|
| 来源：[#490](https://github.com/ChenYilong/CYLTabBarController/issues/490) | Source: [#490](https://github.com/ChenYilong/CYLTabBarController/issues/490) |
| 请使用 README [捕获 TabBar 点击事件](../README.md#cn捕获-tabbar-点击事件) 中的方式监听选中事件，并参考 [#201](https://github.com/ChenYilong/CYLTabBarController/issues/201#issuecomment-498562038)、[#161](https://github.com/ChenYilong/CYLTabBarController/issues/161) 中的讨论。 | Observe selection as described in [Handling TabBar selection events](../README.md#enhandling-tabbar-selection-events) in the README; see also the discussions in [#201](https://github.com/ChenYilong/CYLTabBarController/issues/201#issuecomment-498562038) and [#161](https://github.com/ChenYilong/CYLTabBarController/issues/161). |

### [CN]能否动态更新某个 Tab 的 ViewController？重新 `setViewControllers` 后黑屏
### [EN]Can a tab's view controller be replaced at runtime? The screen is black after `setViewControllers` again

| 中文 | English |
|:---|:---|
| 来源：[#551](https://github.com/ChenYilong/CYLTabBarController/issues/551) | Source: [#551](https://github.com/ChenYilong/CYLTabBarController/issues/551) |
| 重新设置 `viewControllers` 后，再调用一次 `setSelectedIndex:` 选中目标 Tab 即可正常显示（提问者已验证）。 | After setting `viewControllers` again, call `setSelectedIndex:` once to select the target tab; the page then shows normally (confirmed by the reporter). |

### [CN]收到内存警告时，能否移除非当前 Tab 的页面，切换时再加载？
### [EN]On a memory warning, can the pages of other tabs be removed and loaded again when selected?

| 中文 | English |
|:---|:---|
| 来源：[#426](https://github.com/ChenYilong/CYLTabBarController/issues/426) | Source: [#426](https://github.com/ChenYilong/CYLTabBarController/issues/426) |
| 本库没有提供此 API。可以在各子控制器的 `-didReceiveMemoryWarning` 中自行释放不可见页面持有的大资源（图片、缓存等），并在 `-viewWillAppear:` 中按需重新加载，无需替换 ViewController 本身。 | The library has no API for this. In each child view controller, release large resources (images, caches) in `-didReceiveMemoryWarning` while it is not visible, and load them again in `-viewWillAppear:`; the view controller itself does not need replacing. |

### [CN]TabBar 超过 5 个 item 时，如何隐藏 More 按钮？
### [EN]How do I hide the More button with more than five items?

| 中文 | English |
|:---|:---|
| 来源：[#472](https://github.com/ChenYilong/CYLTabBarController/issues/472)、[#493](https://github.com/ChenYilong/CYLTabBarController/issues/493) | Source: [#472](https://github.com/ChenYilong/CYLTabBarController/issues/472), [#493](https://github.com/ChenYilong/CYLTabBarController/issues/493) |
| 系统 `UITabBar` 最多显示 5 个 item，超过时会出现 More，这是系统逻辑，也是审核要求。PlusButton 不计入这 5 个，因此最多为 5 个 TabBarItem + 1 个 PlusButton，详见 README [为什么放置 6 个 TabBarItem 会显示异常？](../README.md#cn为什么放置-6-个-tabbaritem-会显示异常)。 | The system `UITabBar` shows at most five items and adds More beyond that; this is system behavior and an App Review requirement. The PlusButton does not count, so the limit is five TabBarItems plus one PlusButton; see [Why does placing six TabBarItems behave unexpectedly?](../README.md#enwhy-does-placing-six-tabbaritems-behave-unexpectedly) in the README. |

## [CN]3. PlusButton（中间凸起按钮）
## [EN]3. PlusButton (the raised center button)

### [CN]照着 README 写了，中间按钮却不显示
### [EN]The center button does not show although I followed the README

| 中文 | English |
|:---|:---|
| 来源：[#463](https://github.com/ChenYilong/CYLTabBarController/issues/463) | Source: [#463](https://github.com/ChenYilong/CYLTabBarController/issues/463) |
| 1. 在 `-application:didFinishLaunchingWithOptions:` 中、**创建 CYLTabBarController 之前**调用 `[YourPlusButtonSubclass registerPlusButton]`（不要放在 `+load` 中，见 README [为什么 iOS 10 会崩溃而 iOS 9 不会？](../README.md#cn为什么-ios-10-会崩溃而-ios-9-不会)）； | 1. Call `[YourPlusButtonSubclass registerPlusButton]` in `-application:didFinishLaunchingWithOptions:`, **before creating the CYLTabBarController** (not in `+load`; see [Why does it crash on iOS 10 but not iOS 9?](../README.md#enwhy-does-it-crash-on-ios-10-but-not-ios-9) in the README). |
| 2. 子类需遵守 `CYLPlusButtonSubclassing` 协议并实现 `+plusButton`； | 2. The subclass must conform to `CYLPlusButtonSubclassing` and implement `+plusButton`. |
| 3. 使用 Lottie 时，请通过 `pod 'CYLTabBarController/Lottie'` 导入，不要单独再导入一份 Lottie 后只使用 `Core`，否则库内部检测不到 Lottie。 | 3. With Lottie, integrate `pod 'CYLTabBarController/Lottie'`. Adding Lottie separately next to the `Core` subspec leaves the library unable to detect it. |

### [CN]启动时如何默认选中 PlusButton？选中后旁边的 item 也显示为选中
### [EN]How do I select the PlusButton at launch? The item next to it also appears selected

| 中文 | English |
|:---|:---|
| 来源：[#594](https://github.com/ChenYilong/CYLTabBarController/issues/594)、[#459](https://github.com/ChenYilong/CYLTabBarController/issues/459) | Source: [#594](https://github.com/ChenYilong/CYLTabBarController/issues/594), [#459](https://github.com/ChenYilong/CYLTabBarController/issues/459) |
| 当 PlusButton 子类实现了 `+plusChildViewController` 时，直接把 `selectedIndex` 设为 PlusButton 的下标即可： | When the PlusButton subclass implements `+plusChildViewController`, set `selectedIndex` to the PlusButton's index: |

```Objective-C
tabBarController.selectedIndex = [YourPlusButtonSubclass indexOfPlusButtonInTabBar];
```

| 中文 | English |
|:---|:---|
| 旧版本中，用代码选中 PlusButton 对应的页面时，会把 PlusButton 下方的系统 Tab 按钮（看上去是相邻的 item）设为选中。该问题已在新版本修复，请升级到最新版本。 | In old versions, selecting the PlusButton's page in code selected the system tab button under the PlusButton, which looks like the neighboring item. This is fixed; upgrade to the latest version. |

### [CN]默认选中 PlusButton 后，点击其他 Tab，PlusButton 无法恢复 normal 状态
### [EN]After selecting the PlusButton at launch, it stays selected when another tab is tapped

| 中文 | English |
|:---|:---|
| 来源：[#403](https://github.com/ChenYilong/CYLTabBarController/issues/403) | Source: [#403](https://github.com/ChenYilong/CYLTabBarController/issues/403) |
| 不要手动设置 `CYLExternPlusButton.selected`，按上一条用 `selectedIndex` 选中即可，选中状态由库维护。如果自定义了 `UITabBarControllerDelegate`，请按 README [PlusButton 选中后无法恢复为 normal](../README.md#cnplusbutton-选中后无法恢复为-normal) 在 `-tabBarController:shouldSelectViewController:` 中同步状态。 | Don't set `CYLExternPlusButton.selected` yourself; select it with `selectedIndex` as above and the library keeps the state. With a custom `UITabBarControllerDelegate`, sync the state in `-tabBarController:shouldSelectViewController:` as described in [PlusButton remains selected after selecting another tab](../README.md#enplusbutton-remains-selected-after-selecting-another-tab). |

### [CN]3 个按钮（含 PlusButton）时如何让 PlusButton 居中？PlusButton 与其他 item 间距不均匀
### [EN]How do I center the PlusButton among three buttons? The PlusButton is not evenly spaced

| 中文 | English |
|:---|:---|
| 来源：[#419](https://github.com/ChenYilong/CYLTabBarController/issues/419)、[#446](https://github.com/ChenYilong/CYLTabBarController/issues/446) | Source: [#419](https://github.com/ChenYilong/CYLTabBarController/issues/419), [#446](https://github.com/ChenYilong/CYLTabBarController/issues/446) |
| 用 `+indexOfPlusButtonInTabBar` 指定 PlusButton 的位置（3 个按钮时返回 `1`）。 | Set the PlusButton's position with `+indexOfPlusButtonInTabBar` (return `1` for three buttons). |
| 间距不均匀时，按 README [PlusButton 与其他 TabBarItem 的间距不均匀](../README.md#cnplusbutton-与其他-tabbaritem-的间距不均匀) 给 PlusButton 设置与其他 item 相同的宽度，或参考 [调整 PlusButton 与 TabBarItem 的宽度](../README.md#cn调整-plusbutton-与-tabbaritem-的宽度)。 | For uneven spacing, give the PlusButton the same width as the other items as described in [The PlusButton is not evenly spaced](../README.md#enthe-plusbutton-is-not-evenly-spaced), or see [Customize the PlusButton and TabBarItem widths](../README.md#encustomize-the-plusbutton-and-tabbaritem-widths). |

### [CN]TabBar 上只有一个 PlusButton，能否实现？
### [EN]Can a TabBar have only a PlusButton?

| 中文 | English |
|:---|:---|
| 来源：[#407](https://github.com/ChenYilong/CYLTabBarController/issues/407) | Source: [#407](https://github.com/ChenYilong/CYLTabBarController/issues/407) |
| 本库基于系统 `UITabBar`，面向「若干 TabBarItem + 可选的 PlusButton」的结构，不支持只有 PlusButton 的 TabBar。这种场景建议直接在页面底部放一个自定义按钮。 | The library builds on the system `UITabBar` for "several TabBarItems plus an optional PlusButton", and does not support a TabBar with only a PlusButton. Put a custom button at the bottom of the page instead. |

### [CN]中间凸起按钮上的白边、阴影怎么设置？
### [EN]How do I add a white border or shadow to the raised button?

| 中文 | English |
|:---|:---|
| 来源：[#514](https://github.com/ChenYilong/CYLTabBarController/issues/514) | Source: [#514](https://github.com/ChenYilong/CYLTabBarController/issues/514) |
| Demo 中 PlusButton 的白边是图标图片本身自带的。可以让设计提供带白边的图片，或者在 `+plusButton` 中给按钮的 `layer` 设置 `borderColor`、`shadowColor` 等属性。 | The white border in the demo is part of the icon image. Use an image with the border, or set `borderColor`, `shadowColor` and so on on the button's `layer` in `+plusButton`. |

### [CN]只能有一个 PlusButton？全局静态变量导致一个 App 只能用一个实例
### [EN]Only one PlusButton? Global variables limit an app to one instance

| 中文 | English |
|:---|:---|
| 来源：[#476](https://github.com/ChenYilong/CYLTabBarController/issues/476) | Source: [#476](https://github.com/ChenYilong/CYLTabBarController/issues/476) |
| 新版本已支持多个 TabBarController 各自使用不同的 PlusButton：PlusButton 按 `context` 绑定到对应的 TabBarController，item 个数、宽度等布局数据也由每个 TabBar 各自保存。用法见 README [多 TabBar 嵌套并指定 PlusButton 位置](../README.md#cn多-tabbar-嵌套并指定-plusbutton-位置)。 | Several TabBarControllers can now each have their own PlusButton: a PlusButton is bound to its TabBarController by `context`, and each TabBar keeps its own layout data such as item count and width. See [Nesting multiple TabBars and specifying the PlusButton position](../README.md#ennesting-multiple-tabbars-and-specifying-the-plusbutton-position) in the README. |

## [CN]4. TabBarItem 的图标、文字与布局
## [EN]4. TabBarItem icons, titles and layout

### [CN]图标大小如何设置？
### [EN]How do I set the icon size?

| 中文 | English |
|:---|:---|
| 来源：[#410](https://github.com/ChenYilong/CYLTabBarController/issues/410) | Source: [#410](https://github.com/ChenYilong/CYLTabBarController/issues/410) |
| 图标按图片本身的尺寸显示，请提供符合设计尺寸的 @2x/@3x 图片。需要微调位置时，可在 `tabBarItemsAttributes` 中使用 `CYLTabBarItemImageInsets`。 | Icons are shown at the image's own size; provide @2x/@3x images at the designed size. To fine-tune the position, use `CYLTabBarItemImageInsets` in `tabBarItemsAttributes`. |

### [CN]点击图标后图标越来越大（真机）
### [EN]The icon grows on every tap (on device)

| 中文 | English |
|:---|:---|
| 来源：[#469](https://github.com/ChenYilong/CYLTabBarController/issues/469) | Source: [#469](https://github.com/ChenYilong/CYLTabBarController/issues/469) |
| `imageInsets` 的 top 与 bottom 必须大小相等、符号相反，例如 `UIEdgeInsetsMake(offset, 0, -offset, 0)`。否则系统每次布局都会改变图片尺寸。 | The top and bottom of `imageInsets` must be equal and opposite, for example `UIEdgeInsetsMake(offset, 0, -offset, 0)`. Otherwise the system resizes the image on every layout pass. |

### [CN]只显示图标时，图标没有垂直居中；只显示文字（类似抖音）怎么做？
### [EN]Icons are not vertically centered without titles; how do I show titles only (like TikTok)?

| 中文 | English |
|:---|:---|
| 来源：[#485](https://github.com/ChenYilong/CYLTabBarController/issues/485)、[#512](https://github.com/ChenYilong/CYLTabBarController/issues/512) | Source: [#485](https://github.com/ChenYilong/CYLTabBarController/issues/485), [#512](https://github.com/ChenYilong/CYLTabBarController/issues/512) |
| 只显示图标：在 `tabBarItemsAttributes` 中省略 `CYLTabBarItemTitle`，库会自动让图标垂直居中，见 README [让 TabBarItem 仅显示图标并使图标垂直居中](../README.md#cn让-tabbaritem-仅显示图标并使图标垂直居中)。 | Icons only: omit `CYLTabBarItemTitle` from `tabBarItemsAttributes` and the library centers the icon vertically; see [Display only icons in TabBarItems and center them vertically](../README.md#endisplay-only-icons-in-tabbaritems-and-center-them-vertically) in the README. |
| 只显示文字：不传图片时，库会使用占位图（`+[UIImage cyl_tabItemPlaceholderImage]`）以保证布局，可用 `CYLTabBarItemTitlePositionAdjustment` 把文字移到垂直居中的位置；也可以把文字做成图片，按「只显示图标」的方式处理。 | Titles only: without an image, the library uses a placeholder image (`+[UIImage cyl_tabItemPlaceholderImage]`) to keep the layout. Move the title to the vertical center with `CYLTabBarItemTitlePositionAdjustment`, or render the text as an image and treat it as an icon. |

### [CN]能否让图标和标题水平排列（图标在左、标题在右）？
### [EN]Can the icon and title sit side by side (icon left, title right)?

| 中文 | English |
|:---|:---|
| 来源：[#482](https://github.com/ChenYilong/CYLTabBarController/issues/482) | Source: [#482](https://github.com/ChenYilong/CYLTabBarController/issues/482) |
| 系统只在 iPad 等宽屏的 inline 布局中横向排列，本库没有提供在 iPhone 上强制横向排列的选项。可以用 `-[UIControl cyl_replaceTabButtonWithNewView:show:]` 把 Tab 按钮替换为自定义视图来实现。 | The system uses the side-by-side (inline) layout only on wide screens such as iPad, and the library has no option to force it on iPhone. Replace the tab button with a custom view using `-[UIControl cyl_replaceTabButtonWithNewView:show:]`. |

### [CN]iPad 上 item 都挤在中间，如何让它们平分宽度？
### [EN]On iPad the items are packed in the middle; how do I spread them across the width?

| 中文 | English |
|:---|:---|
| 来源：[#592](https://github.com/ChenYilong/CYLTabBarController/issues/592) | Source: [#592](https://github.com/ChenYilong/CYLTabBarController/issues/592) |
| 这是系统 `UITabBar` 在 iPad 上的默认布局。可设置： | This is the default layout of the system `UITabBar` on iPad. Set: |

```Objective-C
tabBarController.tabBar.itemPositioning = UITabBarItemPositioningFill;
```

### [CN]selectionIndicatorImage 的位置如何跟随 `CYLTabBarItemTitlePositionAdjustment` 调整？
### [EN]How do I move selectionIndicatorImage along with `CYLTabBarItemTitlePositionAdjustment`?

| 中文 | English |
|:---|:---|
| 来源：[#545](https://github.com/ChenYilong/CYLTabBarController/issues/545) | Source: [#545](https://github.com/ChenYilong/CYLTabBarController/issues/545) |
| `selectionIndicatorImage` 由系统按 item 的区域绘制，不会随标题偏移移动。需要在图片本身预留偏移；自定义选中背景的做法见 README [如何添加选中背景色？](../README.md#cn如何添加选中背景色)。 | The system draws `selectionIndicatorImage` over the item's area; it does not follow the title offset. Build the offset into the image itself; for a custom selected background, see [How can I add a selected background color?](../README.md#enhow-can-i-add-a-selected-background-color) in the README. |

### [CN]未选中的图标被染成灰色，与设计图不一致；`unselectedItemTintColor` 无效
### [EN]Unselected icons are tinted gray instead of the designed colors; `unselectedItemTintColor` has no effect

| 中文 | English |
|:---|:---|
| 来源：[#465](https://github.com/ChenYilong/CYLTabBarController/issues/465)、[#588](https://github.com/ChenYilong/CYLTabBarController/issues/588) | Source: [#465](https://github.com/ChenYilong/CYLTabBarController/issues/465), [#588](https://github.com/ChenYilong/CYLTabBarController/issues/588) |
| 系统会把渲染模式为 `Automatic` 的图片当作模板图，按 tint color 着色，图标就变成单色剪影（#465 的截图）。希望显示图片原色时： | The system treats images with the `Automatic` rendering mode as templates and tints them, so icons turn into one-color silhouettes (the screenshots in #465). To show the image's own colors: |
| 1. 在 `tabBarItemsAttributes` 中传图片名（NSString）而不是 UIImage（推荐）：库会按原图渲染，并自动加载深色图片，#465 正是这样解决的；或 | 1. Pass the image name (NSString) instead of a UIImage in `tabBarItemsAttributes` (recommended): the library renders it as original and loads its dark image, which is how #465 was solved; or |
| 2. 在 Asset Catalog 中把图片的 Render As 设为 Original Image；或 | 2. Set Render As to Original Image for the image in the asset catalog; or |
| 3. 代码中使用 `[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]`。 | 3. Use `[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]` in code. |
| 两种形式的区别见 README [图片传名称还是 UIImage](../README.md#cn图片传名称nsstring还是-uiimage)。 | See [Image names or UIImage objects](../README.md#enimage-names-nsstring-or-uiimage-objects) in the README for the differences. |
| 只希望改变颜色时，使用模板图片并设置 `unselectedItemTintColor`。 | To change only the color, use template images and set `unselectedItemTintColor`. |

### [CN]iOS 13 起，`[[UITabBarItem appearance] setTitleTextAttributes:...]` 设置的文字颜色、字体不生效
### [EN]Since iOS 13, title colors and fonts set with `[[UITabBarItem appearance] setTitleTextAttributes:...]` have no effect

| 中文 | English |
|:---|:---|
| 来源：[#435](https://github.com/ChenYilong/CYLTabBarController/issues/435) | Source: [#435](https://github.com/ChenYilong/CYLTabBarController/issues/435) |
| iOS 13 起请使用 `UITabBarAppearance`，同时把 `titlePositionAdjustment` 设到 appearance 中，否则 `CYLTabBarItemTitlePositionAdjustment` 会失效。Demo `MainTabBarController.m` 中的写法： | Since iOS 13, use `UITabBarAppearance`, and set `titlePositionAdjustment` on the appearance too, or `CYLTabBarItemTitlePositionAdjustment` stops working. As in the demo's `MainTabBarController.m`: |

```Objective-C
if (@available(iOS 13.0, *)) {
    UITabBarItemAppearance *itemAppearance = [[UITabBarItemAppearance alloc] init];
    itemAppearance.normal.titlePositionAdjustment = titlePositionAdjustment;
    [itemAppearance.normal setTitleTextAttributes:normalAttrs];     // may include NSFontAttributeName
    [itemAppearance.selected setTitleTextAttributes:selectedAttrs];

    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    appearance.stackedLayoutAppearance = itemAppearance;
    appearance.inlineLayoutAppearance = itemAppearance;
    appearance.compactInlineLayoutAppearance = itemAppearance;
    self.tabBar.standardAppearance = appearance;
    self.tabBar.scrollEdgeAppearance = appearance;
    self.tabBar.unselectedItemTintColor = normalAttrs[NSForegroundColorAttributeName];
}
```

### [CN]页面里设置 `self.title` 后，Tab 的文字也变了
### [EN]Setting `self.title` in a page also changes the tab title

| 中文 | English |
|:---|:---|
| 来源：[#518](https://github.com/ChenYilong/CYLTabBarController/issues/518) | Source: [#518](https://github.com/ChenYilong/CYLTabBarController/issues/518) |
| `self.title` 会同时修改导航栏标题和 TabBarItem 标题。请改用 `self.navigationItem.title`，见 README [ViewController 标题与 TabBar 标题不一致](../README.md#cnviewcontroller-标题与-tabbar-标题不一致)。 | `self.title` sets both the navigation bar title and the TabBarItem title. Use `self.navigationItem.title` instead; see [The ViewController title does not match the TabBar title](../README.md#enthe-viewcontroller-title-does-not-match-the-tabbar-title) in the README. |

## [CN]5. 外观：背景、分割线、阴影与深色模式
## [EN]5. Appearance: background, separator, shadow and Dark Mode

### [CN]如何隐藏 TabBar 顶部分割线、自定义分割线颜色，或给 TabBar 加阴影？
### [EN]How do I hide the top separator, change its color, or add a shadow to the TabBar?

| 中文 | English |
|:---|:---|
| 来源：[#532](https://github.com/ChenYilong/CYLTabBarController/issues/532)、[#494](https://github.com/ChenYilong/CYLTabBarController/issues/494) | Source: [#532](https://github.com/ChenYilong/CYLTabBarController/issues/532), [#494](https://github.com/ChenYilong/CYLTabBarController/issues/494) |
| 隐藏分割线：`[tabBarController hideTabBarShadowImageView];` | Hide the separator: `[tabBarController hideTabBarShadowImageView];` |
| 自定义分割线：iOS 13 起设置 `UITabBarAppearance` 的 `shadowColor`（高度固定为 1）或 `shadowImage`（可自定义高度），写法见 [#494](https://github.com/ChenYilong/CYLTabBarController/issues/494) 与 Demo `MainTabBarController.m`。 | Custom separator: since iOS 13, set `shadowColor` (fixed 1pt height) or `shadowImage` (custom height) on `UITabBarAppearance`; see [#494](https://github.com/ChenYilong/CYLTabBarController/issues/494) and the demo's `MainTabBarController.m`. |
| 阴影：隐藏分割线后，设置 `tabBar.layer` 的 `shadowColor`、`shadowOffset`、`shadowOpacity`、`shadowRadius`。 | Shadow: after hiding the separator, set `shadowColor`, `shadowOffset`, `shadowOpacity` and `shadowRadius` on `tabBar.layer`. |
| 设置 `shadowImage` 后 `CYLTabBarItemTitlePositionAdjustment` 失效的问题，见 [#456](https://github.com/ChenYilong/CYLTabBarController/issues/456) 以及第 4 节 iOS 13 文字属性的写法。 | If `CYLTabBarItemTitlePositionAdjustment` stops working after setting `shadowImage`, see [#456](https://github.com/ChenYilong/CYLTabBarController/issues/456) and the iOS 13 title attributes entry in section 4. |

### [CN]能否设置不规则（中间凸起）的 TabBar 背景图片？
### [EN]Can the TabBar have an irregular background image (raised in the middle)?

| 中文 | English |
|:---|:---|
| 来源：[#447](https://github.com/ChenYilong/CYLTabBarController/issues/447)、[#524](https://github.com/ChenYilong/CYLTabBarController/issues/524) | Source: [#447](https://github.com/ChenYilong/CYLTabBarController/issues/447), [#524](https://github.com/ChenYilong/CYLTabBarController/issues/524) |
| iOS 13 起不要通过 KVC 修改 TabBar 内部视图，可以： | Since iOS 13, don't modify the TabBar's internal views through KVC. Instead: |
| 1. 使用 `UITabBarAppearance` 的 `backgroundImage`（配合 `backgroundImageContentMode`）设置背景； | 1. Set the background with `backgroundImage` (and `backgroundImageContentMode`) on `UITabBarAppearance`. |
| 2. 凸起部分超出 TabBar 时，在 `tabBar` 上插入一个 `y` 为负值的 `UIImageView` 显示凸起部分。 | 2. For a part that rises above the TabBar, insert a `UIImageView` with a negative `y` into `tabBar`. |
| 全面屏机型的 TabBar 更高（含底部安全区），图片需按实际高度适配，或使用可拉伸图片。超出 TabBar 的区域默认不响应点击，见 README [凸起的图标超出 49pt 后无法响应](../README.md#cn凸起的图标超出-49pt-后无法响应)。 | On devices without a Home button the TabBar is taller (it includes the bottom safe area), so fit the image to the real height or use a resizable image. Areas outside the TabBar don't receive taps; see [A raised icon does not respond above 49pt](../README.md#ena-raised-icon-does-not-respond-above-49pt) in the README. |

### [CN]iOS 13 起用 KVC 设置 TabBar 会崩溃吗？
### [EN]Does setting TabBar properties through KVC crash since iOS 13?

| 中文 | English |
|:---|:---|
| 来源：[#430](https://github.com/ChenYilong/CYLTabBarController/issues/430) | Source: [#430](https://github.com/ChenYilong/CYLTabBarController/issues/430) |
| iOS 13 起，通过 KVC 访问部分私有属性（如 `_xxx` 成员变量）会直接崩溃。请改用 `UITabBarAppearance` 等公开 API，不要用 KVC 修改 TabBar。 | Since iOS 13, accessing some private properties through KVC (such as `_xxx` instance variables) crashes. Use public APIs such as `UITabBarAppearance` instead of KVC. |

### [CN]深色模式（Dark Mode）如何适配？动态颜色、图片不跟随切换
### [EN]How do I support Dark Mode? Dynamic colors and images don't switch

| 中文 | English |
|:---|:---|
| 来源：[#540](https://github.com/ChenYilong/CYLTabBarController/issues/540)、[#517](https://github.com/ChenYilong/CYLTabBarController/issues/517)、[#552](https://github.com/ChenYilong/CYLTabBarController/issues/552)、[#486](https://github.com/ChenYilong/CYLTabBarController/issues/486) | Source: [#540](https://github.com/ChenYilong/CYLTabBarController/issues/540), [#517](https://github.com/ChenYilong/CYLTabBarController/issues/517), [#552](https://github.com/ChenYilong/CYLTabBarController/issues/552), [#486](https://github.com/ChenYilong/CYLTabBarController/issues/486) |
| 颜色：使用动态颜色，例如系统的 `systemBackgroundColor`，或库提供的 `cyl_systemBackgroundColor`、`cyl_labelColor` 等（见 `UIColor+CYLTabBarControllerExtention.h`）；指定浅色和深色两种颜色时，新版本可用 `+[UIColor cyl_colorWithLightColor:darkColor:]`。不要在设置颜色时自行判断当前模式后传入固定颜色，此时得到的 trait 可能是 `unspecified`（#552 的原因）。 | Colors: use dynamic colors, such as the system `systemBackgroundColor` or the library's `cyl_systemBackgroundColor`, `cyl_labelColor` and others (see `UIColor+CYLTabBarControllerExtention.h`); for a light and a dark color, newer versions add `+[UIColor cyl_colorWithLightColor:darkColor:]`. Don't check the current mode yourself and pass a fixed color: at that point the trait may still be `unspecified` (the cause of #552). |
| 图片：在 Asset Catalog 中为图片添加 Dark 外观，再在 `tabBarItemsAttributes` 中传入图片名；新版本中也可以按命名规范提供 `<图片名>_dark`（传图片名时自动加载），或用 `+[UIImage cyl_imageWithLightImage:darkImage:]` 把两张图合成一张会自动切换的图片，不必在 `-traitCollectionDidChange:` 中手动替换（[#486](https://github.com/ChenYilong/CYLTabBarController/issues/486#issuecomment-698183206) 中的旧做法）。 | Images: add a Dark appearance to the image in the asset catalog, and pass the image name in `tabBarItemsAttributes`; in newer versions, also provide `<name>_dark` by naming convention (loaded automatically with the name), or combine two images into one that switches by itself with `+[UIImage cyl_imageWithLightImage:darkImage:]`, instead of replacing them in `-traitCollectionDidChange:` (the older workaround in [#486](https://github.com/ChenYilong/CYLTabBarController/issues/486#issuecomment-698183206)). |
| 详见 README [适配深色模式](../README.md#cn适配深色模式)。 | See [Supporting Dark Mode](../README.md#ensupporting-dark-mode) in the README. |

### [CN]App 不需要深色模式；手动设置 window 的 overrideUserInterfaceStyle 后图片仍跟随系统
### [EN]The app doesn't support Dark Mode; images still follow the system after setting the window's overrideUserInterfaceStyle

| 中文 | English |
|:---|:---|
| 来源：[#440](https://github.com/ChenYilong/CYLTabBarController/issues/440)、[#620](https://github.com/ChenYilong/CYLTabBarController/issues/620) | Source: [#440](https://github.com/ChenYilong/CYLTabBarController/issues/440), [#620](https://github.com/ChenYilong/CYLTabBarController/issues/620) |
| 不需要深色模式时，在 Info.plist 中添加 `UIUserInterfaceStyle`，值为 `Light`，整个 App 固定为浅色。 | If the app does not support Dark Mode, add `UIUserInterfaceStyle` with the value `Light` to Info.plist; the whole app then stays light. |
| 也可以设置 `window.overrideUserInterfaceStyle`（或 window 的 rootViewController）。设置后仍只跟随系统，通常是因为代码按 window scene 或屏幕的风格选图或选色：它们不认 window 上的 override。旧版 Demo 的 `-traitCollectionDidChange:` 以及库内部（未公开）的深浅色图片方法就是这样，新版本已改为跟随每个视图自身的风格。请比较 `self.traitCollection`，并使用会自动切换的图片和颜色（见上一条）。 | You can also set `window.overrideUserInterfaceStyle` (or on the window's root view controller). If things still follow only the system after that, the code usually picks images or colors by the window scene's or the screen's style, which ignore the window's override. The old demo's `-traitCollectionDidChange:` and the library's internal (unpublished) light/dark image helper did so; newer versions follow each view's own style. Compare `self.traitCollection`, and use images and colors that switch by themselves (see the entry above). |

### [CN]深色模式下，想让 TabBar 保持浅色的毛玻璃效果
### [EN]Keep the TabBar's light blur in Dark Mode

| 中文 | English |
|:---|:---|
| 来源：[#394](https://github.com/ChenYilong/CYLTabBarController/issues/394) | Source: [#394](https://github.com/ChenYilong/CYLTabBarController/issues/394) |

```Objective-C
if (@available(iOS 13.0, *)) {
    tabBarController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
}
```

### [CN]手动把 window 设为深色模式后，TabBarItem 的红点不显示
### [EN]The TabBarItem red dot disappears after forcing the window into Dark Mode

| 中文 | English |
|:---|:---|
| 来源：[#531](https://github.com/ChenYilong/CYLTabBarController/issues/531) | Source: [#531](https://github.com/ChenYilong/CYLTabBarController/issues/531) |
| 原 issue 未能定位原因。之后角标已多次重构：角标会在深色模式切换等 trait 变化时重新解析边框颜色并恢复循环动画，颜色默认值也可通过 `CYLBadgeAppearance` 全局设置。请升级到最新版本重试；如仍复现，请提交 bug 并附上可复现的 Demo。 | The cause was not found in the original issue. Badges have been reworked since: they re-resolve their border color and restore their repeating animation when traits such as Dark Mode change, and their default colors can be set globally with `CYLBadgeAppearance`. Upgrade to the latest version and try again; if it still happens, report a bug with a demo that reproduces it. |

## [CN]6. 角标 Badge
## [EN]6. Badges

### [CN]设置角标字体后，角标大小也变了
### [EN]Changing the badge font also changes the badge size

| 中文 | English |
|:---|:---|
| 来源：[#597](https://github.com/ChenYilong/CYLTabBarController/issues/597) | Source: [#597](https://github.com/ChenYilong/CYLTabBarController/issues/597) |
| 角标大小按文字内容和字体计算，这是预期行为。需要固定大小时，可以设置 `cyl_badgeFrame`、`cyl_badgeRadius` 等属性（见 `CYLBadgeProtocol.h`），或像提问者一样，把自定义 label 添加到 `cyl_tabButton.cyl_tabImageView` 上。 | The badge size follows its text and font; this is expected. For a fixed size, set `cyl_badgeFrame`, `cyl_badgeRadius` and similar properties (see `CYLBadgeProtocol.h`), or, as the reporter did, add your own label to `cyl_tabButton.cyl_tabImageView`. |

### [CN]如何全局设置角标的背景色等属性？
### [EN]How do I set the badge background color and other properties globally?

| 中文 | English |
|:---|:---|
| 来源：[#425](https://github.com/ChenYilong/CYLTabBarController/issues/425) | Source: [#425](https://github.com/ChenYilong/CYLTabBarController/issues/425) |
| 新版本提供了 `CYLBadgeAppearance`，在显示角标之前统一设置一次即可，对象上单独设置的值仍然优先。详见 README [全局设置角标样式](../README.md#cn全局设置角标样式)。 | Newer versions add `CYLBadgeAppearance`: set it once before showing badges; a value set on an object still wins. See [Setting the badge style globally](../README.md#ensetting-the-badge-style-globally) in the README. |

```Objective-C
[CYLBadgeAppearance globalAppearance].backgroundColor = [UIColor systemPinkColor];
[CYLBadgeAppearance globalAppearance].font = [UIFont boldSystemFontOfSize:10];
[CYLBadgeAppearance globalAppearance].centerOffset = CGPointMake(-5, 3);
```

### [CN]如何获取已设置的 badgeValue？
### [EN]How do I read the badgeValue I set?

| 中文 | English |
|:---|:---|
| 来源：[#499](https://github.com/ChenYilong/CYLTabBarController/issues/499) | Source: [#499](https://github.com/ChenYilong/CYLTabBarController/issues/499) |
| badgeValue 是业务自己传入的，请从业务数据中读取，不需要从组件中取值。判断角标是否正在显示可以用 `-cyl_isShowBadge`。 | The badgeValue comes from your own data, so read it there rather than from the component. To check whether a badge is shown, use `-cyl_isShowBadge`. |

### [CN]`setViewDidLayoutSubViewsBlockInvokeOnce:` 中的 block 不执行
### [EN]The block passed to `setViewDidLayoutSubViewsBlockInvokeOnce:` does not run

| 中文 | English |
|:---|:---|
| 来源：[#404](https://github.com/ChenYilong/CYLTabBarController/issues/404) | Source: [#404](https://github.com/ChenYilong/CYLTabBarController/issues/404) |
| 常见原因是子类在 `-init` 中创建了另一个 CYLTabBarController 并返回它（旧版 README 的写法）：App 显示的是那个普通实例，子类的 `-viewDidLoad` 中设置的 block 落在被丢弃的对象上，永远不会执行。请按 README [第二步](../README.md#cn第二步设置-cyltabbarcontroller-的两个数组) 通过 `[super initWithViewControllers:…]` 初始化。 | The usual cause is a subclass whose `-init` creates and returns another CYLTabBarController (as the old README did): the app shows that plain instance, and the block set in the subclass's `-viewDidLoad` lands on a discarded object and never runs. Initialize through `[super initWithViewControllers:…]` as in [Step 2](../README.md#enstep-2-configure-the-view-controller-and-tab-bar-item-attribute-arrays) of the README. |
| 显示或更新 Tab 角标请改用 `-reloadBadgesWithBlock:`：可随时、多次调用，Tab 按钮就绪后执行，无需 `dispatch_after`。once-block 只保存一个 block，且在 TabBar 已完成布局后设置的可能不再执行。详见 README [更新 Tab 角标](../README.md#cn更新-tab-角标)。 | To show or update tab badges, use `-reloadBadgesWithBlock:` instead: call it any time, as often as needed; it runs once the tab buttons exist, with no `dispatch_after`. The once-block holds a single block, and one set after the tab bar was laid out may never run. See [Updating tab badges](../README.md#enupdating-tab-badges) in the README. |

## [CN]7. Lottie 动画
## [EN]7. Lottie animations

### [CN]加载本地 Lottie JSON 文件无效
### [EN]A local Lottie JSON file does not play

| 中文 | English |
|:---|:---|
| 来源：[#467](https://github.com/ChenYilong/CYLTabBarController/issues/467)、[#454](https://github.com/ChenYilong/CYLTabBarController/issues/454) | Source: [#467](https://github.com/ChenYilong/CYLTabBarController/issues/467), [#454](https://github.com/ChenYilong/CYLTabBarController/issues/454) |
| 1. 通过 `pod 'CYLTabBarController/Lottie'` 导入（见第 3 节）； | 1. Integrate with `pod 'CYLTabBarController/Lottie'` (see section 3). |
| 2. 本地文件使用文件 URL： | 2. Use a file URL for a local file: |

```Objective-C
NSString *path = [[NSBundle mainBundle] pathForResource:@"tab_home_animate" ofType:@"json"];
NSDictionary *attributes = @{
    CYLTabBarItemTitle : @"首页",
    CYLTabBarLottieURL : [NSURL fileURLWithPath:path],
};
```

| 中文 | English |
|:---|:---|
| 3. 确认 JSON 文件已加入 App Target（Copy Bundle Resources）。 | 3. Make sure the JSON file is in the app target (Copy Bundle Resources). |
| 完整用法见 [#341](https://github.com/ChenYilong/CYLTabBarController/issues/341)。 | See [#341](https://github.com/ChenYilong/CYLTabBarController/issues/341) for full usage. |

### [CN]Lottie 的 JSON 文件从哪里获取？
### [EN]Where do I get Lottie JSON files?

| 中文 | English |
|:---|:---|
| 来源：[#478](https://github.com/ChenYilong/CYLTabBarController/issues/478) | Source: [#478](https://github.com/ChenYilong/CYLTabBarController/issues/478) |
| 可以在 [LottieFiles](https://lottiefiles.com/) 查找或在线编辑，也可由设计师用 After Effects + Bodymovin 导出。商用前请确认素材的授权。 | Find or edit animations online at [LottieFiles](https://lottiefiles.com/), or have a designer export them from After Effects with Bodymovin. Check the license before commercial use. |

### [CN]能否运行时替换某个 Tab 的 Lottie 动画？
### [EN]Can a tab's Lottie animation be replaced at runtime?

| 中文 | English |
|:---|:---|
| 来源：[#549](https://github.com/ChenYilong/CYLTabBarController/issues/549) | Source: [#549](https://github.com/ChenYilong/CYLTabBarController/issues/549) |
| 可以修改对应 `tabBarItem` 的 `cyl_lottieURL`，下次选中该 Tab 时会播放新的动画： | Change the `cyl_lottieURL` of its `tabBarItem`; the new animation plays the next time the tab is selected: |

```Objective-C
[viewController.tabBarItem cyl_setLottieURL:newLottieURL];
```

### [CN]如何修改 Lottie 动画的播放速度？有没有动画视图添加完成的回调？
### [EN]How do I change the Lottie playback speed? Is there a callback when the animation views are added?

| 中文 | English |
|:---|:---|
| 来源：[#428](https://github.com/ChenYilong/CYLTabBarController/issues/428) | Source: [#428](https://github.com/ChenYilong/CYLTabBarController/issues/428) |
| 库没有提供添加完成的回调。动画视图添加后，可以通过 `tabButton.cyl_lottieAnimationView` 取到并设置 `animationSpeed`；`tabBarController.isLottieViewAdded` 表示是否已经添加。 | There is no such callback. Once the animation views are added, get one with `tabButton.cyl_lottieAnimationView` and set its `animationSpeed`; `tabBarController.isLottieViewAdded` tells whether they have been added. |

### [CN]能否只给中间的 PlusButton 添加 Lottie 动画？是否支持 SVGA 动画？
### [EN]Can only the center PlusButton have a Lottie animation? Is SVGA supported?

| 中文 | English |
|:---|:---|
| 来源：[#614](https://github.com/ChenYilong/CYLTabBarController/issues/614)、[#415](https://github.com/ChenYilong/CYLTabBarController/issues/415) | Source: [#614](https://github.com/ChenYilong/CYLTabBarController/issues/614), [#415](https://github.com/ChenYilong/CYLTabBarController/issues/415) |
| `tabBarItemsAttributes` 中的 Lottie 配置只作用于普通 TabBarItem。 | The Lottie settings in `tabBarItemsAttributes` apply to regular TabBarItems only. |
| PlusButton 是自定义的 `UIButton`，可以在 `+plusButton` 中自行添加 Lottie 动画视图，并在点击时播放。 | The PlusButton is your own `UIButton`: add a Lottie animation view to it in `+plusButton` and play it on tap. |
| 库不内置 SVGA。可以用 `-[UIControl cyl_replaceTabImageViewWithNewView:show:]` 把 Tab 的图片视图替换为 SVGA 播放视图。 | SVGA is not built in. Replace a tab's image view with an SVGA player view using `-[UIControl cyl_replaceTabImageViewWithNewView:show:]`. |

## [CN]8. 导航、转场与手势
## [EN]8. Navigation, transitions and gestures

### [CN]iOS 26 侧滑返回时，TabBar 浮在侧滑页面上方
### [EN]On iOS 26 the TabBar floats above the page during the swipe-back gesture

| 中文 | English |
|:---|:---|
| 来源：[#645](https://github.com/ChenYilong/CYLTabBarController/issues/645) | Source: [#645](https://github.com/ChenYilong/CYLTabBarController/issues/645) |
| 这是 iOS 26 系统 TabBar（液态玻璃）的默认表现，本库使用系统 TabBar，因此保持同样的行为。可选方案： | This is the default behavior of the iOS 26 system TabBar (Liquid Glass). The library uses the system TabBar, so it behaves the same. Options: |
| 1. pop 时隐藏 TabBar，避免它悬浮出来； | 1. Hide the TabBar while popping, so it does not float in. |
| 2. 把层级改为 `RootNavigationController → TabBarController → 各 Tab 页面`，所有 push 都通过最外层导航控制器完成。有开发者反馈这种方式效果正常，但老项目需要调整跳转逻辑； | 2. Restructure to `RootNavigationController → TabBarController → tab pages` and push everything through the outer navigation controller. Developers report this works, but existing projects need their navigation code changed. |
| 3. 完全自定义 TabBar 需要使用私有 API，有审核风险，本库不采用。 | 3. A fully custom TabBar needs private APIs and risks App Review rejection, so the library does not do this. |

### [CN]首页 push 后无法右滑返回；侧滑返回时崩溃
### [EN]Swipe back stops working after a push from the home page; swipe back crashes

| 中文 | English |
|:---|:---|
| 来源：[#571](https://github.com/ChenYilong/CYLTabBarController/issues/571)、[#504](https://github.com/ChenYilong/CYLTabBarController/issues/504) | Source: [#571](https://github.com/ChenYilong/CYLTabBarController/issues/571), [#504](https://github.com/ChenYilong/CYLTabBarController/issues/504) |
| 隐藏导航栏时，系统的侧滑手势可能出现错乱。可使用 `UIViewController+CYLNavigationControllerExtention.h` 中的方法规避： | With the navigation bar hidden, the system swipe-back gesture can misbehave. Work around it with the methods in `UIViewController+CYLNavigationControllerExtention.h`: |

```Objective-C
// viewWillDisappear: / dealloc: disable swipe back during the transition
// viewWillDisappear: / dealloc 中调用：转场过程中禁用侧滑手势
- (void)cyl_disableInteractivePopGestureRecognizer;
// viewDidDisappear: enable it again after the transition
// viewDidDisappear: 中调用：转场结束后重新启用
- (void)cyl_enableInteractivePopGestureRecognizer;
```

| 中文 | English |
|:---|:---|
| 如果仍然崩溃，请提交 bug 并附上崩溃日志。 | If it still crashes, report a bug with the crash log. |

### [CN]每个 Tab 页面都要单独隐藏导航栏吗？
### [EN]Do I have to hide the navigation bar in every tab page?

| 中文 | English |
|:---|:---|
| 来源：[#603](https://github.com/ChenYilong/CYLTabBarController/issues/603) | Source: [#603](https://github.com/ChenYilong/CYLTabBarController/issues/603) |
| 导航栏由各自的 `UINavigationController` 控制，本库不会统一隐藏。可以在公共基类的 `-viewWillAppear:` 中调用 `[self.navigationController setNavigationBarHidden:YES animated:animated]`，或在 `UINavigationControllerDelegate` 的 `-navigationController:willShowViewController:animated:` 中统一处理。 | Each `UINavigationController` controls its own bar; the library does not hide them. Call `[self.navigationController setNavigationBarHidden:YES animated:animated]` in a shared base class's `-viewWillAppear:`, or handle it in `-navigationController:willShowViewController:animated:` of a `UINavigationControllerDelegate`. |

### [CN]页面内容（如 TableView）被 TabBar 遮挡
### [EN]The TabBar covers page content such as a table view

| 中文 | English |
|:---|:---|
| 来源：[#525](https://github.com/ChenYilong/CYLTabBarController/issues/525) | Source: [#525](https://github.com/ChenYilong/CYLTabBarController/issues/525) |
| 关闭 TabBar 半透明即可： | Turn off TabBar translucency: |

```Objective-C
[UITabBar appearance].translucent = NO;
```

| 中文 | English |
|:---|:---|
| 注意：iOS 26 液态玻璃下，页面会延伸到 TabBar 之外的区域，这是系统的特殊效果。 | Note: with iOS 26 Liquid Glass, pages extend beyond the TabBar area; this is a system effect. |

### [CN]多个 TabBarController 嵌套时，push 后侧滑返回，内部 TabBarItem 偏移
### [EN]With nested TabBarControllers, inner TabBarItems shift after a push and swipe back

| 中文 | English |
|:---|:---|
| 来源：[#429](https://github.com/ChenYilong/CYLTabBarController/issues/429) | Source: [#429](https://github.com/ChenYilong/CYLTabBarController/issues/429) |
| 旧版本中多个 TabBarController 共用全局的布局数据，会互相影响。新版本中每个 TabBar 各自保存布局数据（见 [#489](https://github.com/ChenYilong/CYLTabBarController/issues/489)），请升级到最新版本。 | In old versions, all TabBarControllers shared global layout data and affected each other. Each TabBar now keeps its own (see [#489](https://github.com/ChenYilong/CYLTabBarController/issues/489)); upgrade to the latest version. |

## [CN]9. 与第三方库的兼容
## [EN]9. Compatibility with third-party libraries

### [CN]与 QMUIKit 冲突：选中状态的文字属性不生效；PlusButton 子控制器继承 QMUI 后 TabBar 消失
### [EN]Conflicts with QMUIKit: selected title attributes are ignored; the TabBar disappears when the plus child view controller inherits from QMUI

| 中文 | English |
|:---|:---|
| 来源：[#455](https://github.com/ChenYilong/CYLTabBarController/issues/455)、[#510](https://github.com/ChenYilong/CYLTabBarController/issues/510) | Source: [#455](https://github.com/ChenYilong/CYLTabBarController/issues/455), [#510](https://github.com/ChenYilong/CYLTabBarController/issues/510) |
| 两个库都会修改 TabBar 的外观和行为。请先将 CYLTabBarController 和 QMUIKit 都升级到最新版本，有开发者反馈升级后不再冲突。如果仍有问题，请提交 bug 并附上可复现的 Demo。 | Both libraries change the TabBar's appearance and behavior. Upgrade both CYLTabBarController and QMUIKit to their latest versions; developers report the conflict is gone after that. If not, report a bug with a demo that reproduces it. |

## [CN]10. 其他
## [EN]10. Other

### [CN]iPhone 12 mini 的高度是 780，`CYL_IS_IPHONE_X` 的判断需要修改吗？
### [EN]The iPhone 12 mini is 780pt tall; does `CYL_IS_IPHONE_X` need changing?

| 中文 | English |
|:---|:---|
| 来源：[#548](https://github.com/ChenYilong/CYLTabBarController/issues/548) | Source: [#548](https://github.com/ChenYilong/CYLTabBarController/issues/548) |
| 不需要。iPhone 12 mini 的 `UIScreen` 逻辑尺寸是 375 × 812（780 是物理像素换算后的值），满足判断条件。而且新版本中 `CYL_IS_IPHONE_X` 已改为根据 TabBar 的实际可见尺寸判断。 | No. The iPhone 12 mini's logical `UIScreen` size is 375 × 812 (780 comes from its physical pixels), which meets the condition. Also, `CYL_IS_IPHONE_X` now uses the TabBar's actual visible size. |

### [CN]内容为空的问题
### [EN]Questions without content

| 中文 | English |
|:---|:---|
| 来源：[#595](https://github.com/ChenYilong/CYLTabBarController/issues/595) | Source: [#595](https://github.com/ChenYilong/CYLTabBarController/issues/595) |
| 该 issue 只有模板内容，没有描述问题。如有疑问，请重新提交并补充具体描述。 | The issue contains only the template, with no question. Please open a new issue with a description. |
