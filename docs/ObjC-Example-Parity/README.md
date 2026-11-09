# [CN]ObjC Example 复刻进度（React Native 与 Flutter）
# [EN]ObjC Example parity (React Native and Flutter)

| 中文 | English |
|:---|:---|
| 本页跟踪 `CrossPlatform/react-native-cyltabbar/example` 与 `CrossPlatform/flutter_cyltabbar/example` 对 Objective-C 示例（`Example/`，根目录的 `CYLTabBarController.xcworkspace`）的复刻。第一列是 ObjC 示例已有的演示，ObjC 示例本身记为 100 分；其他四列每复刻一项勾选一项（✅），未完成为 ⬜。每列分数 = 已勾选项数 / 总项数 × 100（四舍五入；56 项时每勾选一项约加 1.79 分），每勾选一项就重新打分并在「评分记录」中加一行，直到四列都是 100 分。 | This page tracks how `CrossPlatform/react-native-cyltabbar/example` and `CrossPlatform/flutter_cyltabbar/example` replicate the Objective-C example (`Example/`, the root `CYLTabBarController.xcworkspace`). The first column lists the demos the ObjC example has, and the ObjC example itself scores 100; the other four columns get a check (✅) for each demo replicated, ⬜ until then. A column's score = checked items / all items × 100 (rounded; with 56 items each check adds about 1.79), scored again with every check and logged in "Score history", until all four columns score 100. |
| 判定标准：功能与界面和 ObjC 示例一致（同样的分组、行、文字与当前值，点击后同样的效果），在 iPhone 17 Pro 模拟器（iOS 26.5）与 Android 模拟器（API 35）上实际操作验证。只靠原生 UIKit 才能演示的行，用组件提供的同等能力复刻，并在说明中写明。 | A check means the function and the UI match the ObjC example (the same sections, rows, texts and current values, the same effect when tapped), checked by hand on an iPhone 17 Pro simulator (iOS 26.5) and an Android emulator (API 35). A row that only native UIKit can show is replicated with the equivalent the components offer, said in its note. |

## [CN]分数
## [EN]Scores

| 列 / Column | objcExample | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android |
|:---|:---|:---|:---|:---|:---|
| 分数 / Score | 100 | 34 | 34 | 34 | 34 |
| 已勾选 / Checked | 56 / 56 | 19 / 56 | 19 / 56 | 19 / 56 | 19 / 56 |

## [CN]对照表
## [EN]Checklist

### [CN]TabBar 与导航栏
### [EN]Tab bar and navigation bar

| # | objcExample 已有的演示 / Demos in objcExample (100) | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 说明 / Note |
|:---|:---|:---|:---|:---|:---|:---|
| 1 | 四个 Tab：首页、同城、消息、我的（图片、identifier） / Four tabs: Home, Nearby, Messages, Me (images, identifiers) | ✅ | ✅ | ✅ | ✅ | Lottie 图标需要 iOS 上的静态 framework（`use_frameworks! :linkage => :static`），与 ObjC 的 `use_frameworks!` 相同。 / The Lottie icons need static frameworks on iOS (`use_frameworks! :linkage => :static`), as ObjC's `use_frameworks!`. |
| 2 | 首页 Tab 的 Lottie 图标 / The Home tab's Lottie icon | ✅ | ✅ | ✅ | ✅ | Lottie 图标 + 1.5 秒后的「淘」封面（新增 `tabCoverImages`；Android 新增 `CYLTabBarItemButton.cyl_coverView`，覆盖整个 Tab 按钮）。 / The Lottie icon plus the cover after 1.5 s (new `tabCoverImages`; Android gets `CYLTabBarItemButton.cyl_coverView`, covering the whole tab button). |
| 3 | PlusButton「发布」：图片、标题与 Tab 标题对齐、位于第 2 位、identifier `plus`、选中标题为绿色 / The "Post" plus button: images, title aligned with the tab titles, index 2, identifier `plus`, green selected title | ✅ | ✅ | ✅ | ✅ | 图片、位置、角标、页面一致；选中 PlusButton 页面时其下方显示选中效果、标题为选中色（新键 `CYLPlusButtonShowsSelection`，即 ObjC 示例 `-tabBarController:shouldShowPlatterLiquidLensViewForControl:` 返回 YES）；页面没有标题时使用 PlusButton 的标题；Android 液态玻璃选中时保留普通图片。之前看到的红色来自 ObjC 模拟器保存的「Grapefruit」皮肤，默认皮肤为绿色。 / Images, position, badge and page match; with the plus page selected the selection shows under it and the title takes the selected color (new key `CYLPlusButtonShowsSelection`: the ObjC example returns YES from `-tabBarController:shouldShowPlatterLiquidLensViewForControl:`); an untitled page takes the plus button's title; Android Liquid Glass keeps the normal image while selected. The red seen before came from the "Grapefruit" skin saved in the ObjC simulator; the default skin is green. |
| 4 | PlusButton 的 y 轴位置与 ObjC 示例一致（`+constantOfPlusButtonCenterYOffsetForTabBarHeight:` 为 -14） / The plus button's y position matches the ObjC example (`+constantOfPlusButtonCenterYOffsetForTabBarHeight:` returns -14) | ✅ | ✅ | ✅ | ✅ | iOS：TabBar 坐标中 frame 均为 (x, -31.5, 55×80)，与 ObjC 相同；Android：图片紧贴标题上方，圆心在标题中心上方 34.3 dp（iOS 33.3 pt）。 / iOS: frame (x, -31.5, 55×80) in tab bar coordinates in all, as in ObjC; Android: the image right above the title, its center 34.3 dp above the title center (iOS 33.3 pt). |
| 5 | PlusButton 的角标（启动为 1，每次点击加 1）与点击操作 / The plus button's badge (1 at launch, +1 per tap) and its tap action | ✅ | ✅ | ✅ | ✅ | 启动 1.5 秒后为 1（bounce）；ObjC 液态玻璃下点击不会增加，与之一致。 / 1 (bounce) 1.5 s after launch; on Liquid Glass ObjC does not count taps, and neither do these. |
| 6 | 启动时的 Tab 角标：首页红点、同城 8、消息 99+、我的 NEW / Tab badges at launch: Home dot, Nearby 8, Messages 99+, Me NEW | ✅ | ✅ | ✅ | ✅ | 新增 `badgeAttributes`（颜色、动画、半径、偏移）。首页红点随即被封面清除，与 ObjC 相同。Android 角标位置与尺寸改为 iOS 规则（锚点右上角 +2、22 pt 图片视图、粗体 9 + 边距 8）。 / New `badgeAttributes` (color, animation, radius, offset). The Home dot is cleared at once by the cover, as in ObjC. Android badges now follow the iOS rules (anchor's top-right +2, the 22 pt image view, bold 9 + margin 8). |
| 7 | 导航栏「FlatDesign」：切换为扁平样式 TabBar / Navigation bar "FlatDesign": switch to the FlatDesign tab bar | ✅ | ✅ | ✅ | ✅ | 首页导航栏左侧「Flat Design」（呼吸红点，随机颜色）用新的扁平样式 TabBar 替换当前 TabBar（新的 key，重新出现启动角标）；修复：iOS 扁平样式下宿主页面的角标原先画在隐藏的系统 Tab 按钮上。 / The home page's "Flat Design" button (a breathing dot in a random color) replaces the tab bar with a new FlatDesign one (a new key, the launch badges again); fixed: in iOS FlatDesign the host pages' badges went on the hidden system tab buttons. |
| 8 | 导航栏「LiquidGlass」：重新创建液态玻璃 TabBar / Navigation bar "LiquidGlass": build a Liquid Glass tab bar again | ✅ | ✅ | ✅ | ✅ | 右侧「Liquid Glass」（抖动红点）重新创建液态玻璃 TabBar，皮肤保持不变。 / "Liquid Glass" (a shaking dot) builds a new Liquid Glass tab bar; the skin stays. |
| 9 | 导航栏「换肤」：皮肤选择 / Navigation bar "Skin": the skin picker | ✅ | ✅ | ✅ | ✅ | 「Skin」菜单：17 个皮肤与「Follow the system Dark Mode」，与 ObjC 相同；节日图标全彩 / 45% 透明，PlusButton 换成节日图标（`CYLPlusButtonImageSize` 55pt）；网络皮肤下载 Tab 与 PlusButton 图标。「淘」封面与 ObjC 一样在图标替换之后由示例延迟添加，并在任何选中状态下保持（宿主封面改为与 `-selectedCover` 相同的按钮）。Flutter Android release 补上 `INTERNET` 权限。 / "Skin" menu: the 17 skins and "Follow the system Dark Mode", as ObjC; holiday icons in full color / 45%, the plus button takes the holiday icon (`CYLPlusButtonImageSize` 55 pt); the network skin downloads the tab and plus button icons. The 淘 cover is added by the example after the icons change, as ObjC, and stays in every selection state (the host's cover is a button, as `-selectedCover`). Flutter Android release gets the `INTERNET` permission. |
| 10 | PlusButton 的子页面（`plusChildViewController`） / The plus button's own page (`plusChildViewController`) | ✅ | ✅ | ✅ | ✅ | `pageIdentifier`；修复：选中 PlusButton 页面后 Tab 角标消失（宿主现在把未处理的 delegate 方法交给 controller）。 / `pageIdentifier`; fixed: the tab badges vanished once the plus button's page was selected (the host now forwards the delegate methods it does not handle to the controller). |

### [CN]演示列表：通用与 TabBar 外观
### [EN]Demo list: general and tab bar appearance

| # | objcExample 已有的演示 / Demos in objcExample (100) | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 说明 / Note |
|:---|:---|:---|:---|:---|:---|:---|
| 11 | 语言切换 / Language | ✅ | ✅ | ✅ | ✅ | 五种语言与「跟随系统」；译文由库的字符串表生成（`strings.json`）；阿拉伯语从右到左，TabBar 镜像；组件 `language` / five languages and "Follow system"; translations generated from the library's string tables (`strings.json`); Arabic right to left, the tab bar mirrored; component `language` |
| 12 | 模拟内存警告 / Simulate memory warning | ✅ | ✅ | ✅ | ✅ | 配置键 `CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`、`CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers`（保留首页）；`CYLSimulateMemoryWarningReport()`；组件 `memoryWarningRequest` / `onMemoryWarning` / config keys (the home tab kept); `CYLSimulateMemoryWarningReport()`; component `memoryWarningRequest` / `onMemoryWarning` |
| 13 | 标题偏移（titlePositionAdjustment） / Title offset (titlePositionAdjustment) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 14 | standardAppearance 主题 / standardAppearance theme | ⬜ | ⬜ | ⬜ | ⬜ | |
| 15 | 换肤行（issue #216） / Skin row (issue #216) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 16 | 滚动时缩小 / 隐藏 TabBar（issue #13） / Minimize / hide the tab bar on scroll (issue #13) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 17 | 修改 CYLFlatDesignTabBar 高度 / Change the CYLFlatDesignTabBar height | ⬜ | ⬜ | ⬜ | ⬜ | |
| 18 | CYLFlatDesignTabBarItem 居中 / 不居中 / CYLFlatDesignTabBarItem centered / not centered | ⬜ | ⬜ | ⬜ | ⬜ | |
| 19 | CYLFlatDesignTabBarItem 背景色 / CYLFlatDesignTabBarItem background color | ⬜ | ⬜ | ⬜ | ⬜ | |
| 20 | 滚动隐藏：模拟意外情况（39 项） / Scroll hiding: simulated interruptions (39) | ⬜ | ⬜ | ⬜ | ⬜ | |

### [CN]演示列表：原地更新 Tab
### [EN]Demo list: update tabs in place

| # | objcExample 已有的演示 / Demos in objcExample (100) | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 说明 / Note |
|:---|:---|:---|:---|:---|:---|:---|
| 21 | 修改 Tab 标题 / Change tab title | ⬜ | ⬜ | ⬜ | ⬜ | |
| 22 | 下载网络图标 / Download network icon | ⬜ | ⬜ | ⬜ | ⬜ | |
| 23 | 更换所有网络图标 / Change all network icons | ⬜ | ⬜ | ⬜ | ⬜ | |
| 24 | 更换所有本地图标 / Change all local icons | ⬜ | ⬜ | ⬜ | ⬜ | |
| 25 | GIF 图标 / GIF icon | ⬜ | ⬜ | ⬜ | ⬜ | |
| 26 | 修改所有标题 / Change all titles | ⬜ | ⬜ | ⬜ | ⬜ | |

### [CN]演示列表：Tab 页面、选中与登录、PlusButton、皮肤
### [EN]Demo list: tab pages, selection and login, plus button, skins

| # | objcExample 已有的演示 / Demos in objcExample (100) | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 说明 / Note |
|:---|:---|:---|:---|:---|:---|:---|
| 27 | 替换相邻 Tab（issue #481） / Replace neighboring tabs (issue #481) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 28 | selectedIndex 与 PlusButton（issue #515） / selectedIndex and the plus button (issue #515) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 29 | 登录状态（issue #19） / Login state (issue #19) | ✅ | ✅ | ✅ | ✅ | 配置键 `CYLTabBarControllerLoginRequiredTabBarItemIdentifiers`；宿主 `loggedIn`、`didRequestLogin`、`loginStateDidChange`；登录状态缓存在本地，重启后保留 / config key; host `loggedIn`, `didRequestLogin`, `loginStateDidChange`; the state is cached locally, across launches |
| 30 | PlusButton 可点击区域（issue #91） / Plus button touchable area (issue #91) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 31 | 之后才加载的 PlusButton 图片 / Plus button image loaded later | ⬜ | ⬜ | ⬜ | ⬜ | |
| 32 | 皮肤列表：节日与配色（19 个） / Skins: holidays and colors (19) | ⬜ | ⬜ | ⬜ | ⬜ | |

### [CN]演示列表：Tab 交互与工具方法
### [EN]Demo list: tab interactions and helpers

| # | objcExample 已有的演示 / Demos in objcExample (100) | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 说明 / Note |
|:---|:---|:---|:---|:---|:---|:---|
| 33 | 点击动画、声音与触感 / Tap animation, sound and haptics | ⬜ | ⬜ | ⬜ | ⬜ | |
| 34 | 长按 Tab（issue #535） / Long press on tabs (issue #535) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 35 | 长按时长与双击间隔（issue #535 / #152） / Long press duration and double tap interval (issue #535 / #152) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 36 | 滑动切换 Tab（issue #535） / Swipe to switch tabs (issue #535) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 37 | 上一个 / 下一个 Tab（issue #535） / Previous / next tab (issue #535) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 38 | 滑动转场（CYLTabBarSlideTransitionAnimator） / Slide transition (CYLTabBarSlideTransitionAnimator) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 39 | 无需基类隐藏导航栏（issue #535） / Hide the navigation bar without a base class (issue #535) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 40 | 超出父视图仍可响应（issue #535） / Respond outside the superview (issue #535) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 41 | 从 bundle 加载图片（issue #535） / Load images from a bundle (issue #535) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 42 | CYLUtils 弱引用关联对象与查找按钮（issue #535） / CYLUtils weak associated objects and finding a button (issue #535) | ⬜ | ⬜ | ⬜ | ⬜ | |

### [CN]演示列表：配置文件、跳转与对比、场景展示、角标
### [EN]Demo list: configuration file, navigation and comparisons, gallery, badges

| # | objcExample 已有的演示 / Demos in objcExample (100) | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 说明 / Note |
|:---|:---|:---|:---|:---|:---|:---|
| 43 | 由配置文件创建 TabBarController / Create a tab bar controller from a configuration file | ⬜ | ⬜ | ⬜ | ⬜ | |
| 44 | 配置文件：模拟意外情况（A2–E1） / Configuration file: simulated failures (A2–E1) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 45 | 与系统 UITabBar 对比 / Compare with the system UITabBar | ⬜ | ⬜ | ⬜ | ⬜ | |
| 46 | Push 系统 UITabBarController（另一个 PlusButton） / Push a system UITabBarController (another plus button) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 47 | Push 另一个 CYLFlatDesignTabBarController / Push another CYLFlatDesignTabBarController | ⬜ | ⬜ | ⬜ | ⬜ | |
| 48 | cyl_pop / cyl_push 演示 / cyl_pop / cyl_push demo | ⬜ | ⬜ | ⬜ | ⬜ | |
| 49 | TabBar 场景展示（Gallery） / Tab bar gallery | ⬜ | ⬜ | ⬜ | ⬜ | |
| 50 | 角标样例（35 种） / Badge samples (35) | ✅ | ✅ | ✅ | ✅ | 35 种角标样例（`UITableViewCell+CYLBadgeExtention.m`）由 JS / Dart 绘制，样式、位置与动画相同；数据来自 `Example-Shared/DemoList/demo-list.json`。 / The 35 badge samples (`UITableViewCell+CYLBadgeExtention.m`), drawn in JS / Dart with the same styles, positions and animations; data from `Example-Shared/DemoList/demo-list.json`. |

### [CN]其他页面
### [EN]Other pages

| # | objcExample 已有的演示 / Demos in objcExample (100) | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 说明 / Note |
|:---|:---|:---|:---|:---|:---|:---|
| 51 | 每个 Tab 显示同一套演示列表与角标样例（不留空） / Every tab shows the same demo list and badge samples (never empty) | ✅ | ✅ | ✅ | ✅ | 每个 Tab 显示同一套演示列表（87 行 + 35 个角标样例，13 个分区），副标题为「页面标题 CYLTabBarController on 系统 版本」。 / Every tab shows the same demo list (87 rows + 35 badge samples, 13 sections); the subtitle is "page title CYLTabBarController on system version". |
| 52 | 消息页：Push 同一 context / 新 context 的 TabBarController（issue #202） / Messages: push a tab bar controller of the same / a new context (issue #202) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 53 | 点击角标行：标题变为「首页(n)」并 Push 橙色页面 / Tapping a badge row: the title becomes "Home (n)" and an orange page is pushed | ✅ | ✅ | ✅ | ✅ | 点击角标行推入全屏橙色页面（覆盖 TabBar，点击返回）；ObjC 的导航标题「Home (n)」在首页导航栏中不显示，因此不复刻。 / Tapping a badge row pushes a full screen orange page (over the tab bar; tap to go back); ObjC's "Home (n)" navigation title is not shown in the home page's bar, so it is not replicated. |
| 54 | 跟随系统深色 / 浅色模式：页面颜色、TabBar、深色图片（`CYLTabBarItemDarkImage`、Lottie 深色文件）随系统设置切换 / Follows the system's dark / light mode: page colors, the tab bar and the dark images (`CYLTabBarItemDarkImage`, Lottie dark files) switch with the system setting | ✅ | ✅ | ✅ | ✅ | 页面用系统颜色；TabBar、`CYLTabBarItemDarkImage` 与 Lottie 深色文件随系统切换（iOS `simctl ui appearance`、Android `cmd uimode night`）。 / The pages use system colors; the tab bar, `CYLTabBarItemDarkImage` and the Lottie dark files switch with the system (iOS `simctl ui appearance`, Android `cmd uimode night`). |
| 55 | 点击 Tab 后更新角标（`-tabBarController:didSelectControl:`）：液态玻璃下选中 Tab 的点击把其角标变为同色红点；再次点击已选中的 Tab 不变 / A tap updates the tab's badge (`-tabBarController:didSelectControl:`): on Liquid Glass a tap that selects a tab turns its badge into a dot of the same color; tapping the selected tab again changes nothing | ✅ | ✅ | ✅ | ✅ | 宿主每次点击上报 `didSelectTab`（iOS 改由 `didSelectControl:`）。 / The host reports every tap with `didSelectTab` (iOS now from `didSelectControl:`). |
| 56 | 显示 / 隐藏 TabBar（`-setTabBarHidden:animated:`，所有样式） / Show / hide the tab bar (`-setTabBarHidden:animated:`, every style) | ✅ | ✅ | ✅ | ✅ | 组件 `tabBarHidden`；隐藏时触摸交给页面；此前漏列于本表 / component `tabBarHidden`; touches go to the page while hidden; missing from this table before |

## [CN]评分记录
## [EN]Score history

| 时间 / When | react-native-iOS | react-native-Android | flutter-iOS | flutter-Android | 变化 / Change |
|:---|:---|:---|:---|:---|:---|
| 2026-11-08 基线 / baseline | 0 | 0 | 0 | 0 | 现有示例只有一个演示页，未复刻 ObjC 示例。发现：PlusButton 比 iOS 高约 15 pt（见下）；RN 基础示例 iOS 发布版启动崩溃（`pod install` 早于 `CYLAnimationView`，已重新安装）。 / The current examples have one page and replicate nothing. Found: the plus button sits about 15 pt higher than on iOS (below); the React Native basic example's iOS release crashed at launch (`pod install` predated `CYLAnimationView`; installed again). |
| 2026-11-08 第 1 批 / batch 1 | 2 | 2 | 2 | 2 | 第 4 项：iOS 配置生成的 PlusButton 改用与 ObjC 示例子类相同的 `UIButtonConfiguration` 布局；Android 标题对齐改为与 iOS 相同（图片紧贴标题上方）；新增 `CYLPlusButtonSize` 与 PlusButton 选中图片（两个库）；示例使用 ObjC 的参数与标题偏移 (0, -3.5)。 / Item 4: the iOS configured plus button uses the ObjC example subclass's `UIButtonConfiguration` layout; Android aligns the title as iOS does (the image right above the title); new `CYLPlusButtonSize` and a selected plus image (both libraries); the examples use the ObjC parameters and the (0, -3.5) title offset. |
| 2026-11-08 第 2 批 / batch 2 | 15 | 15 | 15 | 15 | 第 1、2、5、6、10、54、55 项。宿主新增 `badgeAttributes`、`plusButtonBadgeAttributes`、`tabCoverImages`（两个库与 RN / Flutter）；Android 角标位置与尺寸改为 iOS 规则；宿主把未处理的 delegate 方法交给 controller（修复选中 PlusButton 页面后角标消失）；RN iOS 使用静态 framework（Lottie）。 / Items 1, 2, 5, 6, 10, 54, 55. The host gets `badgeAttributes`, `plusButtonBadgeAttributes`, `tabCoverImages` (both libraries, RN / Flutter); Android badges follow the iOS placement and size; the host forwards unhandled delegate methods to the controller (fixes the badges vanishing with the plus page selected); RN iOS uses static frameworks (Lottie). |
| 2026-11-08 第 3 批 / batch 3 | 16 | 16 | 16 | 16 | 第 3 项。TabBar 外观与 ObjC 示例相同（标题 10pt，未选中红、选中绿，写在皮肤命名值 `CYLTabBarControllerThemes` 中）；新键 `CYLPlusButtonShowsSelection`（两个库、RN / Flutter）；plus 页面默认取 PlusButton 标题；Android 液态玻璃未选中标题改用系统颜色、有页面的 PlusButton 选中时保留普通图片（与 iOS 26 相同）。 / Item 3. The tab bar appearance of the ObjC example (10 pt titles, red unselected, green selected, as a skin's named values in `CYLTabBarControllerThemes`); new key `CYLPlusButtonShowsSelection` (both libraries, RN / Flutter); the plus page takes the plus button's title by default; Android Liquid Glass draws unselected titles in the system color and keeps a plus button's normal image when it has a page (as iOS 26). |
| 2026-11-08 第 4 批 / batch 4 | 20 | 20 | 20 | 20 | 第 7、8 项；第 9 项除网络皮肤的 PlusButton 外均已完成。库修复：iOS 扁平样式宿主页面的角标宿主；宿主由值加载的图片按原图绘制；配置皮肤的背景为不透明；之前配置的皮肤不再阻止新配置的皮肤生效（两个库）；Android 主题切换清除旧外观颜色，液态玻璃不使用背景色。 / Items 7, 8; item 9 done except the network skin's plus button. Library fixes: the badge host of iOS FlatDesign host pages; images the host loads from values are drawn as is; a configuration skin's background is opaque; a skin of an earlier configuration no longer blocks the new configuration's skin (both libraries); Android clears the old theme's appearance colors, and its Liquid Glass ignores the background color. |
| 2026-11-09 第 5 批 / batch 5 | 27 | 27 | 27 | 27 | 第 9、50、51、53 项。演示列表与角标样例（共享数据 `Example-Shared/DemoList`，`scripts/sync-example-shared.py`）；新键 `CYLPlusButtonImageSize`（两个库、RN / Flutter）；RN iOS TabBar 底部位置与 ObjC 一致（SafeAreaView 不再包含 TabBar）；RN Android 滚动时列表宽度不再变化；宿主封面改为按钮；示例与列表补全无障碍；命名、无障碍与封面规则写入 AGENTS.md。 / Items 9, 50, 51, 53. The demo list and badge samples (shared data `Example-Shared/DemoList`, `scripts/sync-example-shared.py`); new key `CYLPlusButtonImageSize` (both libraries, RN / Flutter); the RN iOS tab bar sits where ObjC's does (SafeAreaView no longer holds it); the RN Android list keeps its width while scrolling; the host's cover is a button; accessibility for the examples and the list; naming, accessibility and cover rules in AGENTS.md. |
| 2026-11-09 第 6 批 / batch 6 | 29 | 29 | 29 | 29 | 第 29 项（登录）。配置键 `CYLTabBarControllerLoginRequiredTabBarItemIdentifiers`（两个库）；宿主 `loggedIn`、`didRequestLogin`、`loginStateDidChange`、`resetLoggedIn`，登录后应用之前设置的选中；Android 库把 `cyl_loggedIn` 存入 SharedPreferences（与 iOS 相同，重启后保留）；RN `loginState` 属性与 `onLoginStateChange` 事件，Flutter `bool? loggedIn` 与 `onLoginStateChange`；RN 示例改用 `react-native-safe-area-context`（RN 弃用 SafeAreaView 的警告消失）；四个平台验证：未登录弹窗、登录后选中、重启后保持登录；退出登录回到首页在 iOS 上手动验证，Android 由单元测试覆盖。 / Item 29 (login). Config key (both libraries); host `loggedIn`, `didRequestLogin`, `loginStateDidChange`, `resetLoggedIn`, the earlier selection applied after login; the Android library keeps `cyl_loggedIn` in SharedPreferences (as iOS, across launches); RN `loginState` prop and `onLoginStateChange` event, Flutter `bool? loggedIn` and `onLoginStateChange`; the RN example uses `react-native-safe-area-context` (no more SafeAreaView deprecation warning); checked on all four platforms: the alert while logged out, the selection after login, the login kept after a relaunch; back to Home on logout checked by hand on iOS, by unit tests on Android. |
| 2026-11-09 第 7 批 / batch 7 | 31 | 31 | 31 | 31 | 第 11 项（语言切换）。示例的文字（`demo-list.json` 与新的 `ui-texts.json`）由 `scripts/sync-example-shared.py` 根据库的 33 张字符串表翻译为 `strings.json`；语言行弹出五种语言与「跟随系统」（iOS 操作表，Android 对话框），用新的 key 重建全部内容，阿拉伯语从右到左。宿主新增 `language`（iOS `CYLSetLocalizationLanguage()`，Android 新的 `CYLLocalization`）；Android 库的角标与 PlusButton 无障碍文字、`new` / `NEW` 角标改为由 iOS 字符串表生成的资源（`scripts/android-library-strings.py`），与 iOS 说法一致；Android TabBar 与液态玻璃气泡在从右到左时镜像（不依赖 `android:supportsRtl`）。四个平台验证：选择器、阿拉伯语文字与布局、镜像的 TabBar 与气泡、库文字（「رسائل جديدة: 1」）。CI 检查生成的文件。 / Item 11 (language). The examples' texts (`demo-list.json` and the new `ui-texts.json`) are translated into `strings.json` from the library's 33 string tables by `scripts/sync-example-shared.py`; the language row offers five languages and "Follow system" (an action sheet on iOS, a dialog on Android), rebuilds everything with a new key, Arabic right to left. Hosts get `language` (iOS `CYLSetLocalizationLanguage()`, Android the new `CYLLocalization`); the Android library's badge and plus button accessibility texts and `new` / `NEW` badges are resources generated from the iOS tables (`scripts/android-library-strings.py`), saying what iOS says; the Android tab bar and Liquid Glass bubble mirror right to left (without needing `android:supportsRtl`). Checked on all four platforms: the picker, Arabic texts and layout, the mirrored bar and bubble, the library's texts ("رسائل جديدة: 1"). CI checks the generated files. |
| 2026-11-09 第 8 批 / batch 8 | 32 | 32 | 32 | 32 | 新增并完成第 56 项（显示 / 隐藏 TabBar），此前漏列于本表，因此总项数变为 56。用户发现 Flutter Android 等示例点击「Show / hide CYLFlatDesignTabBar」没有反应：该行未接入，且 `demo-list.json` 误写了「不支持」副标题（Objective-C 示例在所有样式下都支持）。宿主新增 `tabBarHidden`（iOS `setTabBarHidden:animated:`，Android `setTabBarHidden`），隐藏时不接收触摸；RN / Flutter 组件新增同名属性。四个平台验证：隐藏、再次显示。 / Added and completed item 56 (show / hide the tab bar), missing from this table before, so there are 56 items now. The user found that "Show / hide CYLFlatDesignTabBar" did nothing in the Flutter Android example (and the other non-iOS ones): the row was not wired and `demo-list.json` had a wrong "Not supported" subtitle (the Objective-C example supports it in every style). Hosts get `tabBarHidden` (iOS `setTabBarHidden:animated:`, Android `setTabBarHidden`), taking no touches while hidden; the RN / Flutter components get the same prop. Checked on all four platforms: hide, then show again. |
| 2026-11-09 第 9 批 / batch 9 | 34 | 34 | 34 | 34 | 第 12 项（模拟内存警告）。两个库新增配置键 `CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning` 与 `CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers`（`cyl_keepsLoadedTabBarItemIdentifiers`，无需子类即可保留 Tab），以及 `CYLSimulateMemoryWarningReport()`（Objective-C 弹窗也使用它）；Android 的内存警告文字改为由 iOS 字符串表生成（33 种语言）。宿主 `simulateMemoryWarning`，RN / Flutter `memoryWarningRequest` / `onMemoryWarning`；示例弹窗与 Objective-C 相同（保留首页：「kept: shouldUnload returned NO」）。修复：Android 宿主的空白页面原来没有视图，所有 Tab 都显示「未加载」；RN Android 中内存警告会去掉 Tab 角标与封面：React Native 自行布局宿主，不经过布局流程，启动时等待布局的角标 block 一直保留着当时（空的）值，内存警告分离页面触发布局后才执行，把角标与封面清除；现在两个宿主都在 block 执行时读取当前值，且 Android 库的 `performWhenTabBarItemsReady` 也等待 TabBar 自身的布局，手动布局（React Native）时 block 不再一直等待（两个回归测试，旧代码下均失败）。四个平台验证。 / Item 12 (simulate memory warning). Both libraries get the config keys `CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning` and `CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers` (`cyl_keepsLoadedTabBarItemIdentifiers`, keeping tabs without a subclass) and `CYLSimulateMemoryWarningReport()` (the Objective-C alert uses it too); Android's memory warning texts are generated from the iOS tables (33 languages). Host `simulateMemoryWarning`, RN / Flutter `memoryWarningRequest` / `onMemoryWarning`; the examples' alert matches Objective-C's (home kept: "kept: shouldUnload returned NO"). Fixed: the Android host's empty pages had no view, so every tab read "not loaded"; on RN Android a memory warning took the tab badges and covers off: React Native lays the host out itself, outside a layout pass, so a badge block queued at launch kept waiting with its (empty) values, and ran when the warning's page detaching caused a layout, clearing them; both hosts now read the current values when the block runs, and the Android library's `performWhenTabBarItemsReady` also waits for the tab bar's own layout, so a block no longer waits forever when the view is laid out by hand (React Native) (two regression tests, both failing on the old code). Checked on all four platforms. |

## [CN]PlusButton y 轴位置的核对
## [EN]Checking the plus button's y position

| 中文 | English |
|:---|:---|
| 已修复（第 1 批）。iOS 液态玻璃下 PlusButton 标题与 Tab 标题对齐时，`-[CYLPlusButton cyl_alignedCenterForCenter:]` 按「图片底边到自身标题中心的距离」（标题移入 TabBarItem 之前测得）放置图片，高度代理方法的结果被覆盖。ObjC 示例的子类用 `UIButtonConfiguration`（图片在上、标题紧贴其下），这个距离约 6 pt；配置生成的 PlusButton 用 `+cyl_plusButtonWithImage:…`，其布局（`-cyl_getImageFrame:titleFrame:`）把标题再下移 10 pt，距离约 22 pt，所以图片高了约 15 pt。Android 的 `CYLTabBar.layoutPlusButton` 标题对齐时保持按钮顶部不动、向下拉长按钮，与 iOS 的算法也不同。 | Fixed (batch 1). On iOS with Liquid Glass and the plus title aligned with the tab titles, `-[CYLPlusButton cyl_alignedCenterForCenter:]` places the image by the distance from its bottom edge to its own title's center (measured before the title moved into the tab item), overriding the height methods. The ObjC example's subclass uses `UIButtonConfiguration` (the image on top, the title right under it): about 6 pt. The configured plus button uses `+cyl_plusButtonWithImage:…`, whose layout (`-cyl_getImageFrame:titleFrame:`) puts the title 10 pt lower: about 22 pt, so the image sits about 15 pt higher. On Android, `CYLTabBar.layoutPlusButton` keeps the button's top and grows it down when the title is aligned, another algorithm than iOS. |
