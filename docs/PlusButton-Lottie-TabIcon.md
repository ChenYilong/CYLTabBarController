# [CN]有 PlusButton 时，Tab 的 Lottie 图标与 Lottie 文件对应
# [EN]Lottie tab icons and their files when there is a PlusButton

| 中文 | English |
|:---|:---|
| 本文回顾 [#423](https://github.com/ChenYilong/CYLTabBarController/issues/423)：有 PlusButton（中间凸起按钮）时，选中 PlusButton 之后的 Tab，标题切换了，图标（Lottie）没有切换。并说明本次的加固与一处启动动画修复。涉及经典系统 TabBar、液态玻璃（Liquid Glass）和扁平样式（FlatDesign）。 | This page reviews [#423](https://github.com/ChenYilong/CYLTabBarController/issues/423): with a plus button (the raised center button), selecting a tab after it switched the title but not the (Lottie) icon. It also covers this change's hardening and one launch animation fix, across the classic system tab bar, Liquid Glass and FlatDesign. |

## [CN]#423 的原因与现状
## [EN]#423: cause and current state

| 中文 | English |
|:---|:---|
| **复现条件**：PlusButton 不实现 `+plusChildViewController`，只用 `addTarget`；Tab 使用 Lottie 图标。选中最后一个 Tab，push 后返回，再选中旁边的 Tab：标题切换了，图标没有切换。 | **Setup**: a plus button without `+plusChildViewController`, using `addTarget` only, and Lottie tabs. Select the last tab, push and pop, then select the tab next to it: the title switches, the icon does not. |
| **当年的原因**：`-cyl_isSelected` 用按钮下标与 `selectedIndex` 比较，PlusButton 之后的按钮下标错了一位，把错误的 Tab 当成已选中，于是没有播放动画。 | **The original cause**: `-cyl_isSelected` compared a button index with `selectedIndex`. After the plus button the index was off by one, so the wrong tab counted as selected and no animation played. |
| **现状**：`-cyl_isSelected` 已不再被调用；经典样式的按钮下标在布局时只对系统 Tab 按钮计数（不含 PlusButton）；选中 Tab 时，Lottie 文件取自该 Tab 自己的 `tabBarItem`。按现有代码，该现象应已不再出现，但本次没有在设备上验证。 | **Now**: `-cyl_isSelected` is no longer called. In the classic style, button indexes are counted over system tab buttons only (no plus button) at layout. When a tab is selected, its Lottie file comes from its own `tabBarItem`. With the current code this should no longer happen, but it was not verified on a device this time. |

## [CN]Lottie 文件从哪里来
## [EN]Where the Lottie file comes from

| 中文 | English |
|:---|:---|
| 每个 Tab 的 Lottie 文件只读一次：优先 `CYLTabBarLottieURL`；没有时把 `CYLTabBarLottieFilePath` 转成文件 URL。结果同时保存在两处，值相同： | Each tab's Lottie file is read once: `CYLTabBarLottieURL` first; without it, `CYLTabBarLottieFilePath` turned into a file URL. The result is kept in two places, with the same value: |
| • `tabBarItem.cyl_lottieURL` / `cyl_lottieSizeValue`：每个 Tab 自己的，不会错位； | • `tabBarItem.cyl_lottieURL` / `cyl_lottieSizeValue`: the tab's own, cannot shift; |
| • `lottieURLs` / `lottieSizes`：按顺序排列，只包含设置了 Lottie 的 Tab，不含 PlusButton。 | • `lottieURLs` / `lottieSizes`: in order, only for tabs that set a Lottie file, never the plus button. |
| 深色动画（`CYLTabBarLottieDarkURL` / `CYLTabBarLottieDarkFilePath` / `CYLTabBarLottieDarkColors`）按浅色 URL 注册和查找，因此从哪一处取都一样。 | Dark animations (`CYLTabBarLottieDarkURL` / `CYLTabBarLottieDarkFilePath` / `CYLTabBarLottieDarkColors`) are registered and looked up by the light URL, so either source gives the same result. |

## [CN]本次修改
## [EN]What this change does

| 中文 | English |
|:---|:---|
| **1. 加固：按 item 而不是按位置取 Lottie 文件。** 新增 `-cyl_tabBarItemForTabButton:`，通过子控制器找到按钮所属的 `tabBarItem`。原来按位置取（`lottieURLs[index]`）的代码只在启动时执行，且事先校验了数量，所以是对齐的；现在改为优先按 item 取，不再依赖 PlusButton 与未设置 Lottie 的 Tab，按位置取只作兜底。行为不变。 | **1. Hardening: the Lottie file by item, not by position.** The new `-cyl_tabBarItemForTabButton:` finds a button's `tabBarItem` through the view controllers. The position-based code (`lottieURLs[index]`) only ran at launch, after a count check, so it was aligned. It now uses the item first and no longer depends on the plus button or on tabs without Lottie; the position is only a fallback. No change in behavior. |
| **2. 修复：启动时的选中动画播在错的 Tab 上。** 经典样式初始化 Lottie 时用 `idx == selectedIndex` 判断哪个 Tab 是选中的，但 `idx` 不含 PlusButton，`selectedIndex` 却包含 PlusButton 的子控制器。子控制器在初始选中的 Tab 之前时，启动动画会播在相邻的 Tab 上。现在比较按钮所属的 `tabBarItem`。只影响启动时那一次，之后的点击本来就正确。 | **2. Fix: the launch animation on the wrong tab.** The classic style chose the selected tab at Lottie setup with `idx == selectedIndex`, but `idx` leaves out the plus button while `selectedIndex` counts the plus child view controller. With that child before the initially selected tab, the launch animation played on the neighboring tab. It now compares the button's own `tabBarItem`. Only that one launch animation was affected; later taps were already right. |

| 样式 / Style | 中文 | English |
|:---|:---|:---|
| 经典系统 TabBar（iOS 25 及以前，或 UI 兼容模式） | 加固 + 启动动画修复 | Hardening + launch animation fix |
| 液态玻璃（iOS 26+） | 本来就按 item 取；加固了一处未被调用的按位置分支 | Already by item; hardens one unused position-based branch |
| 扁平样式 FlatDesign | 不受影响：按 item 选中，item 自己保存 `lottieFilePath` | Not affected: it selects by item, and the item keeps its own `lottieFilePath` |

| 中文 | English |
|:---|:---|
| 使用方无需修改代码。`CYLTabBarLottieURL` 与 `CYLTabBarLottieFilePath` 均可使用： | No code change is needed. Both `CYLTabBarLottieURL` and `CYLTabBarLottieFilePath` work: |

```objc
// By file path (or CYLTabBarLottieURL with an NSURL). 文件路径（或用 CYLTabBarLottieURL 传 NSURL）。
NSDictionary *home = @{
    CYLTabBarItemTitle      : @"首页",
    CYLTabBarItemImage      : @"home_normal",
    CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"tab_home" ofType:@"json"],
    CYLTabBarLottieSize     : [NSValue valueWithCGSize:CGSizeMake(33, 33)],
};

// Or by name, for every tab (adds CYLTabBarLottieFilePath, and the _dark file when present).
// 或按名称为每个 Tab 添加（设置 CYLTabBarLottieFilePath，存在 _dark 文件时一并设置）。
NSArray *attributes = CYLTabBarItemsAttributesAddingLottieFiles(baseAttributes,
    @[@"tab_home", @"tab_discover", @"tab_news", @"tab_mine"], nil);
```

```swift
// A plus button without a child view controller, as in #423. 与 #423 相同：没有子控制器的 PlusButton。
final class MyPlusButton: CYLPlusButton, CYLPlusButtonSubclassing {
    static func plusButton() -> Any {
        let button = MyPlusButton(type: .custom)
        button.setImage(UIImage(named: "tabbar_plus"), for: .normal)
        button.sizeToFit()
        button.addTarget(button, action: #selector(plusAction), for: .touchUpInside)
        return button
    }
    static func indexOfPlusButtonInTabBar() -> UInt { 2 }
    @objc private func plusAction() { /* present a sheet, push a page... */ }
}
```

## [CN]测试与截图
## [EN]Testing and screenshots

| 中文 | English |
|:---|:---|
| 本次修改在 Linux 环境中完成，无法运行 Xcode 和 iOS 模拟器，因此**没有截图**，也没有在设备上验证。建议验证：① 三种样式下按 #423 的步骤复现，确认图标切换并播放动画；② 经典样式下，PlusButton 有子控制器、初始选中 PlusButton 之后的 Tab，确认启动动画播在该 Tab 上；③ 分别用 `CYLTabBarLottieURL` 和 `CYLTabBarLottieFilePath` 配置。验证后的截图请放在 `docs/assets/` 中，并用 `![](assets/文件名.png)` 引用。 | This change was made on Linux, where Xcode and the iOS simulator cannot run, so there are **no screenshots** and it was not verified on a device. Suggested checks: ① reproduce #423's steps in all three styles and check that the icon switches and animates; ② in the classic style, with a plus child view controller and a tab after it selected at launch, check that the launch animation plays on that tab; ③ configure with `CYLTabBarLottieURL` and with `CYLTabBarLottieFilePath`. Put screenshots from these checks in `docs/assets/` and reference them as `![](assets/file-name.png)`. |
