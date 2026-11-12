//
//  CYLConstants+Keys.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

// [EN] The configuration keys, attribute keys and notification names of CYLTabBarController, translated from Objective-C
//      (docs/Swift-Migration.md, branch swift-core). Objective-C keeps the same names as macros in the headers (hidden from
//      Swift); the strings never change. Each comment is the one the header had.
// [CN] CYLTabBarController 的配置键、属性键与通知名，已从 Objective-C 翻译（docs/Swift-Migration.md，swift-core 分支）。Objective-C
//      在头文件中以宏保留相同的名称（对 Swift 隐藏）；字符串永不改变。每条注释沿用头文件中的注释。

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemTitle = "CYLTabBarItemTitle"

/**
 * FIX: issue #433
 * [EN] Optional title (NSString) shown while the tab is selected, like JD's "Home" tab that reads "Refresh" when it is
 *      selected; the tab shows `CYLTabBarItemTitle` again when another tab is selected. Works in every style (classic,
 *      Liquid Glass, FlatDesign). Pair it with `CYLTabBarItemSelectedImage` (or a Lottie animation, which replays on a
 *      re-tap) and with the reselect gesture (`cyl_tabBarItemGestureHandler`) to refresh on a second tap. It can be
 *      changed in place, like `CYLTabBarItemTitle`, with `-updateTabBarItemAtIndex:attributes:`.
 *      See docs/TabBarItem-Selected-Title.md.
 * [CN] 可选的选中标题（NSString）：Tab 选中时显示，例如京东「首页」选中后显示「刷新」；选中其他 Tab 后恢复 `CYLTabBarItemTitle`。
 *      支持所有样式（经典、液态玻璃、FlatDesign）。可搭配 `CYLTabBarItemSelectedImage`（或 Lottie 动画，再次点击会重新播放），
 *      以及再次点击手势（`cyl_tabBarItemGestureHandler`），实现再次点击刷新。与 `CYLTabBarItemTitle` 一样，可以通过
 *      `-updateTabBarItemAtIndex:attributes:` 原地修改。见 docs/TabBarItem-Selected-Title.md。
 */
public let CYLTabBarItemSelectedTitle = "CYLTabBarItemSelectedTitle"

/**
 * FIX: issue #465
 * [EN] `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage` (and the dark keys below) take an image name or a UIImage.
 *      A name is the prepared form, recommended for most cases: it is rendered as original (the icon keeps its colors)
 *      and its dark image is loaded for you. A UIImage is used as it is: an image from `imageNamed:` has the
 *      `Automatic` rendering mode, which a tab bar tints as a template, so icons turn into one-color silhouettes unless
 *      you call `imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal` first.
 * [CN] `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`（以及下方的深色图片键）可传图片名或 UIImage。图片名是库预先处理好的形式，
 *      适用于大多数场景，推荐使用：按原图渲染（图标保持原有颜色），并自动加载深色图片。UIImage 原样使用：`imageNamed:` 得到的图片
 *      渲染模式为 `Automatic`，TabBar 会把它当作模板图着色，图标变成单色剪影，除非先调用
 *      `imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal`。
 */
public let CYLTabBarItemImage = "CYLTabBarItemImage"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemSelectedImage = "CYLTabBarItemSelectedImage"

/**
 * FIX: issue #620
 * [EN] Optional dark images for `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`, as a name or a UIImage. The tab then
 *      shows them where the interface style is dark (system setting or `overrideUserInterfaceStyle`) and switches by
 *      itself. Not needed when the image has a Dark appearance in the asset catalog or a "<name>_dark" image exists
 *      (`UIImage.cyl_darkImageNameSuffix`); when given, they replace those.
 * [CN] 可选的深色图片，对应 `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`，可为图片名或 UIImage。界面风格为深色时
 *      （系统设置或 `overrideUserInterfaceStyle`）Tab 显示这些图片，并自动切换。图片在 Asset Catalog 中自带 Dark 外观或存在
 *      「<图片名>_dark」（`UIImage.cyl_darkImageNameSuffix`）时无需设置；设置后优先于它们。
 */
public let CYLTabBarItemDarkImage = "CYLTabBarItemDarkImage"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemSelectedDarkImage = "CYLTabBarItemSelectedDarkImage"

/**
 * FIX: issue #601, #337, #215
 * [EN] Optional icons from the network, an NSURL or a URL string: unselected (`CYLTabBarItemImageURL`) and selected
 *      (`CYLTabBarItemSelectedImageURL`; without it the unselected one is used). `CYLTabBarItemImage` /
 *      `CYLTabBarItemSelectedImage` stay the default icons and the placeholders: the tab shows them until the download
 *      ends, and keeps them when it fails. The downloaded images then replace them, in every style, also over a Lottie
 *      icon, through `-setTabBarItemIcon:selectedIcon:size:atIndex:`, drawn with their own colors, a GIF animating. Any
 *      source that method takes works too (a file path, a UIImage...).
 *      `CYLTabBarItemImageURLSize` (an NSValue of CGSize) sets their size, the placeholder's by default. They are cached
 *      in memory and in the sandbox, see `CYLImageCache` to set how long and how much.
 *
 *          @{ CYLTabBarItemTitle : @"Home",
 *             CYLTabBarItemImage : @"home_normal",                     // default and placeholder
 *             CYLTabBarItemSelectedImage : @"home_selected",
 *             CYLTabBarItemImageURL : @"https://example.com/home.png", // replaces them once downloaded
 *             CYLTabBarItemSelectedImageURL : @"https://example.com/home_selected.png" }
 *
 * [CN] 可选的网络图标，NSURL 或 URL 字符串：未选中（`CYLTabBarItemImageURL`）与选中（`CYLTabBarItemSelectedImageURL`；未设置时使用
 *      未选中的）。`CYLTabBarItemImage` / `CYLTabBarItemSelectedImage` 仍是默认图标及占位图：下载完成前 Tab 显示它们，下载失败时保留
 *      它们。下载完成后由下载的图片覆盖，适用于所有样式，也能覆盖 Lottie 图标，基于 `-setTabBarItemIcon:selectedIcon:size:atIndex:`（也支持该方法的其他图片来源，如文件路径、UIImage），
 *      按原图颜色绘制，GIF 会播放动画。`CYLTabBarItemImageURLSize`（CGSize 的 NSValue）设置其尺寸，默认与占位图相同。图片缓存在内存及
 *      沙盒中，缓存时长与大小见 `CYLImageCache`。示例见上。
 */
public let CYLTabBarItemImageURL = "CYLTabBarItemImageURL"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemSelectedImageURL = "CYLTabBarItemSelectedImageURL"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemImageURLSize = "CYLTabBarItemImageURLSize"

/**
 * FIX: issue #604 — generic animation keys, for every animation library.
 * [EN] Keys for a tab's animation that do not name a library: the file decides which library plays it (".json" Lottie,
 *      ".pag" PAG, or the file type of any library added later, see `CYLTabBarItemAnimatorRegistry`). They work like the
 *      Lottie keys, and each library's own keys (`CYLTabBarLottie…`, `CYLTabBarPAG…`) keep working too.
 *      - `CYLTabBarAnimationURL` (NSURL) / `CYLTabBarAnimationFilePath` (NSString): the file; the URL wins.
 *      - `CYLTabBarAnimationSize`: the view size, an NSValue of CGSize (default: the icon placeholder size).
 *      - `CYLTabBarAnimationDarkURL` / `CYLTabBarAnimationDarkFilePath`: the Dark Mode version (#442).
 *      - `CYLTabBarAnimationDarkColors`: keypath -> UIColor for Dark Mode, for libraries that support it (Lottie 4.x).
 * [CN] 不指定动画库的 Tab 动画 key：由文件决定使用哪个动画库播放（".json" 为 Lottie，".pag" 为 PAG，或以后新增的动画库对应的文件类型，
 *      见 `CYLTabBarItemAnimatorRegistry`）。用法与 Lottie key 相同，各动画库自己的 key（`CYLTabBarLottie…`、`CYLTabBarPAG…`）也仍然有效。
 *      - `CYLTabBarAnimationURL`（NSURL）/ `CYLTabBarAnimationFilePath`（NSString）：动画文件，URL 优先。
 *      - `CYLTabBarAnimationSize`：视图尺寸，CGSize 的 NSValue（默认使用图标占位尺寸）。
 *      - `CYLTabBarAnimationDarkURL` / `CYLTabBarAnimationDarkFilePath`：深色模式版本（#442）。
 *      - `CYLTabBarAnimationDarkColors`：深色模式下 keypath -> UIColor，用于支持该功能的动画库（Lottie 4.x）。
 */
public let CYLTabBarAnimationURL = "CYLTabBarAnimationURL"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarAnimationFilePath = "CYLTabBarAnimationFilePath"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarAnimationSize = "CYLTabBarAnimationSize"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarAnimationDarkURL = "CYLTabBarAnimationDarkURL"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarAnimationDarkFilePath = "CYLTabBarAnimationDarkFilePath"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarAnimationDarkColors = "CYLTabBarAnimationDarkColors"

/**
 * FIX: issue #216
 * [EN] `CYLTabBarAnimationColors`: keypath -> UIColor applied in every appearance, for libraries that support color
 *      overrides (Lottie 4.x, Rive). A theme color (`+[UIColor cyl_colorWithThemeProvider:]`) is resolved again on every
 *      theme change, so the animation follows the skin; `CYLTabBarAnimationDarkColors` is added on top of it in Dark Mode.
 * [CN] `CYLTabBarAnimationColors`：在所有外观下应用的 keypath -> UIColor，用于支持颜色覆盖的动画库（Lottie 4.x、Rive）。
 *      主题颜色（`+[UIColor cyl_colorWithThemeProvider:]`）会在每次主题切换时重新解析，使动画跟随皮肤；深色模式下再叠加
 *      `CYLTabBarAnimationDarkColors`。
 */
public let CYLTabBarAnimationColors = "CYLTabBarAnimationColors"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemImageInsets = "CYLTabBarItemImageInsets"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemTitlePositionAdjustment = "CYLTabBarItemTitlePositionAdjustment"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemImagePositionAdjustment = "CYLTabBarItemImagePositionAdjustment"

/**
 * FIX: issue #408
 * [EN] Optional identifier of a tab (an NSString), like a tag. When tabs come and go (e.g. the server hides the second
 *      or third one), `selectedIndex` no longer tells which tab it is; the identifier does. Read it as
 *      `viewController.cyl_tabBarItemIdentifier` or `control.cyl_tabBarItemIdentifier` in the delegate methods, and see
 *      `CYLTabBarController (CYLTabBarItemIdentifier)` for lookups by identifier.
 *      Optional: a tab without one gets a default, its content view controller's class name (a navigation controller's
 *      root), e.g. @"CYLHomeViewController", with "_2", "_3"... for the next tabs of the same class; a plus button gets
 *      its class name, e.g. @"CYLPlusButtonSubclass" (see `+cyl_defaultTabBarItemIdentifierForClass:`). Class names stay
 *      the same when tabs are added or removed and in every language, unlike an index or a title.
 * [CN] 可选的 Tab 标识（NSString），类似 tag。Tab 会增减时（例如由后台控制隐藏第二个或第三个），`selectedIndex` 无法确定是哪个 Tab，
 *      标识可以。在代理方法中通过 `viewController.cyl_tabBarItemIdentifier` 或 `control.cyl_tabBarItemIdentifier` 读取；按标识查找见
 *      `CYLTabBarController (CYLTabBarItemIdentifier)`。
 *      可选：未设置时自动生成默认值，即内容控制器的类名（导航控制器取其根控制器），例如 @"CYLHomeViewController"；同一 TabBar 中
 *      后续同类的 Tab 依次加 "_2"、"_3"……；PlusButton 的默认值为其类名，例如 @"CYLPlusButtonSubclass"（见
 *      `+cyl_defaultTabBarItemIdentifierForClass:`）。与下标或标题不同，类名不会因增减 Tab 或切换语言而改变。
 */
public let CYLTabBarItemIdentifier = "CYLTabBarItemIdentifier"

/**
 * [EN] Keys of a tab bar configuration: one dictionary that holds everything an initializer takes, for
 *      `-initWithConfiguration:`, and the same keys in a configuration file (JSON, YAML, plist...) or a downloaded one,
 *      see `CYLTabBarController (CYLConfiguration)`. In code the values have their usual types; in a file, strings work
 *      for every key (see each key). Missing keys take the defaults of the other initializers.
 *      - `CYLTabBarControllerViewControllers`: NSArray<UIViewController *> (code only), matched to the items by index.
 *        Without it, each tab's page comes from its page ID, see `CYLTabBarItemPageIdentifier`.
 *      - `CYLTabBarControllerTabBarItemsAttributes`: NSArray<NSDictionary *>, the item attributes (`CYLTabBarItemTitle`...).
 *      - `CYLTabBarControllerImageInsets`: NSValue of UIEdgeInsets, or "{top, left, bottom, right}", [t, l, b, r] or
 *        {top: , left: , bottom: , right: }. Default UIEdgeInsetsZero.
 *      - `CYLTabBarControllerTitlePositionAdjustment`: NSValue of UIOffset, or "{horizontal, vertical}", [h, v] or
 *        {horizontal: , vertical: }. Default UIOffsetZero.
 *      - `CYLTabBarControllerStyleType`: NSNumber of CYLTabBarStyleType, or "default", "system", "flatDesign",
 *        "liquidGlass". Default CYLTabBarStyleTypeDefault.
 *      - `CYLTabBarControllerContext`: NSString, see `context`. Default nil.
 *      - `CYLTabBarControllerPageRegistry`: CYLTabBarPageRegistry or any `CYLTabBarPageProviding` (code only), the page
 *        providers of this tab bar controller only, looked up before the shared registry. Lets several tab bars map one page ID to different pages.
 *      - `CYLTabBarControllerPageResolver`: CYLTabBarPageProvider block (code only), called for each tab whose page ID
 *        is not in `CYLTabBarControllerPageRegistry`, before the shared registry; return nil to go on looking.
 *      - `CYLTabBarControllerPageLookupOrder`: NSArray<CYLTabBarPageSource> (or a comma-separated string) of "instance",
 *        "resolver", "shared", "automatic": where pages are looked up, in order. Default all four, in that order.
 *      - `CYLTabBarControllerAutomaticPageRegistration`: NSNumber (BOOL), or "true" / "false"; NO leaves the classes that
 *        adopt `CYLTabBarPage` out of the lookup. Default YES.
 * [CN] TabBar 配置的键：一个字典包含初始化方法的全部参数，用于 `-initWithConfiguration:`；配置文件（JSON、YAML、plist 等）或网络下载的
 *      配置使用同样的键，见 `CYLTabBarController (CYLConfiguration)`。代码中的值使用原本的类型；文件中每个键都可以用字符串（见各键说明）。
 *      缺少的键使用其他初始化方法的默认值。
 *      - `CYLTabBarControllerViewControllers`：NSArray<UIViewController *>（仅代码），按下标与 item 对应。没有时每个 Tab 的页面
 *        根据其页面 ID 获得，见 `CYLTabBarItemPageIdentifier`。
 *      - `CYLTabBarControllerTabBarItemsAttributes`：NSArray<NSDictionary *>，即各 item 的属性（`CYLTabBarItemTitle` 等）。
 *      - `CYLTabBarControllerImageInsets`：UIEdgeInsets 的 NSValue，或 "{top, left, bottom, right}"、[t, l, b, r]、
 *        {top: , left: , bottom: , right: }。默认 UIEdgeInsetsZero。
 *      - `CYLTabBarControllerTitlePositionAdjustment`：UIOffset 的 NSValue，或 "{horizontal, vertical}"、[h, v]、
 *        {horizontal: , vertical: }。默认 UIOffsetZero。
 *      - `CYLTabBarControllerStyleType`：CYLTabBarStyleType 的 NSNumber，或 "default"、"system"、"flatDesign"、"liquidGlass"。
 *        默认 CYLTabBarStyleTypeDefault。
 *      - `CYLTabBarControllerContext`：NSString，见 `context`。默认 nil。
 *      - `CYLTabBarControllerPageRegistry`：CYLTabBarPageRegistry 或任何 `CYLTabBarPageProviding`（仅代码），只属于该 TabBarController
 *        的页面提供者，先于全局注册表查找。多个 TabBar 可以把同一个页面 ID 对应到不同页面。
 *      - `CYLTabBarControllerPageResolver`：CYLTabBarPageProvider block（仅代码），页面 ID 不在 `CYLTabBarControllerPageRegistry`
 *        中时对每个 Tab 调用，先于全局注册表；返回 nil 则继续查找。
 *      - `CYLTabBarControllerPageLookupOrder`：由 "instance"、"resolver"、"shared"、"automatic" 组成的 NSArray<CYLTabBarPageSource>
 *        （或逗号分隔的字符串）：按顺序查找页面的来源。默认为这四个，顺序同上。
 *      - `CYLTabBarControllerAutomaticPageRegistration`：NSNumber（BOOL），或 "true" / "false"；为 NO 时不在遵守 `CYLTabBarPage` 的类中
 *        查找。默认 YES。
 */
public let CYLTabBarControllerViewControllers = "CYLTabBarControllerViewControllers"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerTabBarItemsAttributes = "CYLTabBarControllerTabBarItemsAttributes"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerImageInsets = "CYLTabBarControllerImageInsets"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerTitlePositionAdjustment = "CYLTabBarControllerTitlePositionAdjustment"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerStyleType = "CYLTabBarControllerStyleType"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerContext = "CYLTabBarControllerContext"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerPageRegistry = "CYLTabBarControllerPageRegistry"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerPageResolver = "CYLTabBarControllerPageResolver"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerPageLookupOrder = "CYLTabBarControllerPageLookupOrder"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerAutomaticPageRegistration = "CYLTabBarControllerAutomaticPageRegistration"

/**
 * [EN] `CYLTabBarControllerTabBarItemAnimationSpeed`: NSNumber (or a number in a file), the playback speed of every tab
 *      animation (`tabBarItemAnimationSpeed`); 1 is the file's own speed. Not set: the default. Invalid (0, negative,
 *      NaN, not a number): ignored with a warning.
 * [CN] `CYLTabBarControllerTabBarItemAnimationSpeed`：NSNumber（文件中为数字），所有 Tab 动画的播放速度（`tabBarItemAnimationSpeed`）；
 *      1 为文件本身的速度。未设置时使用默认值。无效（0、负数、NaN、不是数字）时忽略并输出警告。
 */
public let CYLTabBarControllerTabBarItemAnimationSpeed = "CYLTabBarControllerTabBarItemAnimationSpeed"

/**
 * [EN] The plus button of a configuration, so a configuration alone (a file, a URL, React Native or Flutter) can show one:
 *      - `CYLTabBarControllerPlusButton`: a dictionary with `CYLTabBarItemTitle`, `CYLTabBarItemImage` (an image name,
 *        "system:<SF Symbol>" or a UIImage), and optionally `CYLTabBarItemSelectedTitle` and
 *        `CYLTabBarItemSelectedTitleColor` ("#RRGGBB" or a UIColor). It is registered for this configuration's
 *        `CYLTabBarControllerContext`, before the tab bar is made: give the configuration its own context so other tab bar
 *        controllers keep theirs. The plus button sits in the middle, so give an even number of tabs. With a title, the title
 *        lines up with the tab titles (`+alignsTitleWithTabBarItemTitles`). Not a dictionary: ignored with a warning.
 *      - `CYLTabBarControllerPlusButtonAction`: a block `void (^)(CYLPlusButton *plusButton)` (code only), run when the plus
 *        button is tapped.
 * [CN] 配置中的 PlusButton，只用配置（文件、URL、React Native 或 Flutter）也能显示：
 *      - `CYLTabBarControllerPlusButton`：字典，包含 `CYLTabBarItemTitle`、`CYLTabBarItemImage`（图片名、"system:<SF Symbol>" 或
 *        UIImage），可选 `CYLTabBarItemSelectedTitle` 与 `CYLTabBarItemSelectedTitleColor`（"#RRGGBB" 或 UIColor）。在创建 TabBar 之前
 *        为该配置的 `CYLTabBarControllerContext` 注册：请为配置设置独立的 context，以免影响其他 TabBarController。PlusButton
 *        位于中间，因此 Tab 数量应为偶数。有标题时标题与 Tab 标题对齐（`+alignsTitleWithTabBarItemTitles`）。不是字典时忽略并输出警告。
 *      - `CYLTabBarControllerPlusButtonAction`：block `void (^)(CYLPlusButton *plusButton)`（仅代码），点击 PlusButton 时执行。
 */
public let CYLTabBarControllerPlusButton = "CYLTabBarControllerPlusButton"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerPlusButtonAction = "CYLTabBarControllerPlusButtonAction"

/**
 * [EN] More keys of the `CYLTabBarControllerPlusButton` dictionary, for the layouts the `CYLPlusButtonSubclassing` methods
 *      give in code (Example-PAG, Example-Rive):
 *      - `CYLPlusButtonBackgroundImage`: an image drawn as the button's background, the title on it (an image name, a path or
 *        a UIImage); the button takes the image's size. Use it instead of `CYLTabBarItemImage` for a title on a picture.
 *      - `CYLTabBarItemTitleColor` ("#RRGGBB" or a UIColor) and `CYLTabBarItemTitleFont` (as for tabs): the title's look.
 *      - `CYLPlusButtonIndexInTabBar`: NSNumber, its place among the tabs (`+indexOfPlusButtonInTabBar`). Default: the middle.
 *      - `CYLPlusButtonCenterYMultiplier` / `CYLPlusButtonCenterYOffset`: NSNumbers, its vertical center
 *        (`+multiplierOfTabBarHeight:` / `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`).
 *      - `CYLPlusButtonAlignsTitle`: BOOL, whether the title lines up with the tab titles (`+alignsTitleWithTabBarItemTitles`).
 *        Default: YES with a title and no background image.
 *      - `CYLPlusButtonKeepsTitleVisible`: BOOL, the title stays visible on Liquid Glass (`cyl_keepShowingPlusButtonLabel`).
 *      - `CYLPlusButtonShowsSelection`: BOOL, Liquid Glass shows the selection (the lens and the selected title) under the
 *        plus button while its own page is selected, as an app returning YES from
 *        `-tabBarController:shouldShowPlatterLiquidLensViewForControl:` (the Objective-C example). Default: NO. Android
 *        always shows it.
 *      - `CYLPlusButtonSize`: the button's size ("{55, 80}", [55, 80] or an NSValue of CGSize), as a subclass sets its
 *        bounds. Default: the size of its image and title.
 *      - `CYLPlusButtonImageSize`: the size its images are drawn at, aspect fit (same formats), e.g. for an image downloaded
 *        at 512 px, as the example draws a skin's image in the old image's frame. Default: the images' own size.
 *      - `CYLTabBarItemIdentifier`: its identifier (`+tabBarItemIdentifier`).
 *      - `CYLTabBarItemPageIdentifier`: the plus button selects a page of its own, found like a tab's page (the configuration's
 *        resolver, registry or the shared registry; `+plusChildViewController`).
 * [CN] `CYLTabBarControllerPlusButton` 字典的更多键，对应代码中 `CYLPlusButtonSubclassing` 方法给出的布局（Example-PAG、Example-Rive）：
 *      - `CYLPlusButtonBackgroundImage`：作为按钮背景绘制的图片，标题画在上面（图片名、路径或 UIImage）；按钮采用图片的尺寸。需要把标题画在图上时，
 *        用它代替 `CYLTabBarItemImage`。
 *      - `CYLTabBarItemTitleColor`（"#RRGGBB" 或 UIColor）与 `CYLTabBarItemTitleFont`（与 Tab 相同）：标题的外观。
 *      - `CYLPlusButtonIndexInTabBar`：NSNumber，在各 Tab 中的位置（`+indexOfPlusButtonInTabBar`）。默认居中。
 *      - `CYLPlusButtonCenterYMultiplier` / `CYLPlusButtonCenterYOffset`：NSNumber，垂直中心位置
 *        （`+multiplierOfTabBarHeight:` / `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`）。
 *      - `CYLPlusButtonAlignsTitle`：BOOL，标题是否与 Tab 标题对齐（`+alignsTitleWithTabBarItemTitles`）。默认：有标题且没有背景图时为 YES。
 *      - `CYLPlusButtonKeepsTitleVisible`：BOOL，液态玻璃下保持显示标题（`cyl_keepShowingPlusButtonLabel`）。
 *      - `CYLPlusButtonShowsSelection`：BOOL，选中 PlusButton 自己的页面时，液态玻璃在 PlusButton 下方显示选中效果（放大镜与选中标题），
 *        与 App 在 `-tabBarController:shouldShowPlatterLiquidLensViewForControl:` 中返回 YES 相同（Objective-C 示例）。默认：NO。
 *        Android 总是显示。
 *      - `CYLPlusButtonSize`：按钮尺寸（"{55, 80}"、[55, 80] 或 CGSize 的 NSValue），与子类设置 bounds 相同。默认：图片与标题的尺寸。
 *      - `CYLPlusButtonImageSize`：图片的绘制尺寸，等比缩放（格式同上），例如 512px 的网络图片，与示例在原图片区域内绘制皮肤图片相同。默认：图片自身尺寸。
 *      - `CYLTabBarItemIdentifier`：其标识（`+tabBarItemIdentifier`）。
 *      - `CYLTabBarItemPageIdentifier`：PlusButton 选中自己的页面，按 Tab 页面的方式查找（配置的解析回调、注册表或全局注册表；
 *        `+plusChildViewController`）。
 */
public let CYLPlusButtonBackgroundImage = "CYLPlusButtonBackgroundImage"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonIndexInTabBar = "CYLPlusButtonIndexInTabBar"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonCenterYMultiplier = "CYLPlusButtonCenterYMultiplier"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonCenterYOffset = "CYLPlusButtonCenterYOffset"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonAlignsTitle = "CYLPlusButtonAlignsTitle"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonKeepsTitleVisible = "CYLPlusButtonKeepsTitleVisible"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonShowsSelection = "CYLPlusButtonShowsSelection"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonSize = "CYLPlusButtonSize"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLPlusButtonImageSize = "CYLPlusButtonImageSize"

/**
 * [EN] Interaction and appearance keys of a configuration:
 *      - `CYLTabBarControllerUserInterfaceStyle`: "light", "dark" or "system" (default): the tab bar controller's
 *        `overrideUserInterfaceStyle` (iOS 13+), e.g. dark glass for white icons.
 *      - `CYLTabBarControllerTabButtonTapAnimation`: "none", "scale", "zoomIn", "bounce", "bounceWithFireworks", "rotation",
 *        "flip" or "fume" (`cyl_tabButtonTapAnimationType`).
 *      - `CYLTabBarControllerSwipeToSwitchTab`: BOOL, swiping on the tab bar switches tabs (`cyl_swipeToSwitchTabEnabled`).
 *      - `CYLTabBarControllerLoginRequiredTabBarItemIdentifiers`: the identifiers (`CYLTabBarItemIdentifier`) of the tabs
 *        that need login (`cyl_loginRequiredTabBarItemIdentifiers`, issue #19), e.g. ["message", "mine"]; an array of
 *        strings or a comma-separated string.
 *      - `CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`: BOOL, a memory warning unloads the views of the tabs
 *        that are not selected (`unloadsUnselectedViewsOnMemoryWarning`, issue #426).
 *      - `CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers`: the identifiers of the tabs a memory warning never unloads
 *        (`cyl_keepsLoadedTabBarItemIdentifiers`), what overriding `-shouldUnloadViewOfViewController:` does in code; an
 *        array of strings or a comma-separated string.
 * [CN] 配置中的交互与外观键：
 *      - `CYLTabBarControllerUserInterfaceStyle`："light"、"dark" 或 "system"（默认）：TabBarController 的 `overrideUserInterfaceStyle`
 *        （iOS 13+），例如为白色图标使用深色玻璃。
 *      - `CYLTabBarControllerTabButtonTapAnimation`："none"、"scale"、"zoomIn"、"bounce"、"bounceWithFireworks"、"rotation"、"flip" 或
 *        "fume"（`cyl_tabButtonTapAnimationType`）。
 *      - `CYLTabBarControllerSwipeToSwitchTab`：BOOL，在 TabBar 上滑动切换 Tab（`cyl_swipeToSwitchTabEnabled`）。
 *      - `CYLTabBarControllerLoginRequiredTabBarItemIdentifiers`：需要登录的 Tab 的标识（`CYLTabBarItemIdentifier`）
 *        （`cyl_loginRequiredTabBarItemIdentifiers`，issue #19），例如 ["message", "mine"]；字符串数组或逗号分隔的字符串。
 *      - `CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`：BOOL，收到内存警告时卸载未选中 Tab 的视图
 *        （`unloadsUnselectedViewsOnMemoryWarning`，issue #426）。
 *      - `CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers`：内存警告时不卸载的 Tab 的标识（`cyl_keepsLoadedTabBarItemIdentifiers`），
 *        相当于在代码中重写 `-shouldUnloadViewOfViewController:`；字符串数组或逗号分隔的字符串。
 */
public let CYLTabBarControllerUserInterfaceStyle = "CYLTabBarControllerUserInterfaceStyle"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerTabButtonTapAnimation = "CYLTabBarControllerTabButtonTapAnimation"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerSwipeToSwitchTab = "CYLTabBarControllerSwipeToSwitchTab"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerLoginRequiredTabBarItemIdentifiers = "CYLTabBarControllerLoginRequiredTabBarItemIdentifiers"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning = "CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers = "CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers"

/**
 * [EN] Skins in a configuration (see docs/Configuration-File.md, "Skins"; the named values follow QMUI's skins):
 *      - `CYLTabBarControllerThemes`: the skins, by identifier: a dictionary {"light": {values}, "dark": {values}}, or a
 *        list of {`CYLTabBarThemeIdentifier`: "light", `CYLTabBarThemeValues`: {values}} (the Protobuf form). The values
 *        are named: a tab value "@name" (e.g. `CYLTabBarItemTitleColor`: "@accent", `CYLTabBarItemImage`: "@homeIcon")
 *        takes the value `name` of the current skin, and changes when the skin changes; "@@" starts a literal "@". The
 *        names `CYLTabBarBackgroundColor`, `CYLTabBarShadowColor`, `CYLTabBarItemTitleColor`,
 *        `CYLTabBarItemSelectedTitleColor`, `CYLTabBarItemIconColor`, `CYLTabBarItemSelectedIconColor`,
 *        `CYLTabBarItemTitleFont` and `CYLTabBarItemSelectedTitleFont` style the whole tab bar. A name a skin does not
 *        give comes from the skin of `CYLTabBarControllerThemeIdentifier`.
 *      - `CYLTabBarControllerThemeIdentifier`: the skin used first, and the one others fall back to. Default: the first
 *        identifier in alphabetical order.
 *      - `CYLTabBarControllerDarkThemeIdentifier`: the skin used in Dark Mode (iOS 13+): the tab bar then follows the
 *        system appearance, unless the manager already has its own `identifierForTrait`.
 *      - `CYLTabBarControllerThemeManagerName`: the `CYLThemeManager` the skins are registered with (default: the tab bar
 *        controller's `cyl_themeManager`, so the app's other views and skin menus see them too).
 *      Each skin becomes a `CYLTabBarConfigurationTheme` (a `CYLTabBarTheme`) of that manager; switch with
 *      `manager.currentThemeIdentifier = @"dark"`. A skin chosen before (persisted, or set by the app) is kept.
 * [CN] 配置中的皮肤（见 docs/Configuration-File.md 的“皮肤”；按名称取值参照 QMUI 的换肤）：
 *      - `CYLTabBarControllerThemes`：按标识组织的皮肤：字典 {"light": {值}, "dark": {值}}，或由 {`CYLTabBarThemeIdentifier`: "light",
 *        `CYLTabBarThemeValues`: {值}} 组成的列表（Protobuf 的形式）。值按名称引用：Tab 的值写成 "@name"（例如 `CYLTabBarItemTitleColor`:
 *        "@accent"、`CYLTabBarItemImage`: "@homeIcon"）时取当前皮肤中名为 `name` 的值，并随皮肤切换而变化；"@@" 表示以 "@" 开头的普通文本。
 *        名称 `CYLTabBarBackgroundColor`、`CYLTabBarShadowColor`、`CYLTabBarItemTitleColor`、`CYLTabBarItemSelectedTitleColor`、
 *        `CYLTabBarItemIconColor`、`CYLTabBarItemSelectedIconColor`、`CYLTabBarItemTitleFont`、`CYLTabBarItemSelectedTitleFont`
 *        用于整个 TabBar。某个皮肤没有的名称取自 `CYLTabBarControllerThemeIdentifier` 对应的皮肤。
 *      - `CYLTabBarControllerThemeIdentifier`：首先使用、也是其他皮肤回退的皮肤。默认：按字母顺序的第一个标识。
 *      - `CYLTabBarControllerDarkThemeIdentifier`：深色模式（iOS 13+）使用的皮肤：TabBar 随系统外观切换，除非管理器已有自己的
 *        `identifierForTrait`。
 *      - `CYLTabBarControllerThemeManagerName`：注册皮肤的 `CYLThemeManager`（默认：TabBarController 的 `cyl_themeManager`，因此 App 的其他
 *        视图与换肤菜单也能看到这些皮肤）。
 *      每个皮肤成为该管理器的一个 `CYLTabBarConfigurationTheme`（`CYLTabBarTheme`）；用 `manager.currentThemeIdentifier = @"dark"` 切换。
 *      之前已选择的皮肤（持久化的，或 App 设置的）保持不变。
 */
public let CYLTabBarControllerThemes = "CYLTabBarControllerThemes"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerThemeIdentifier = "CYLTabBarControllerThemeIdentifier"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerDarkThemeIdentifier = "CYLTabBarControllerDarkThemeIdentifier"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerThemeManagerName = "CYLTabBarControllerThemeManagerName"

/**
 * [EN] Configuration key: localized texts (docs/Configuration-File.md, "Localization"). YES (or "true"), the name of a
 *      strings table, or a dictionary with `CYLTabBarLocalizationTableName`, `CYLTabBarLocalizationPath` and
 *      `CYLTabBarLocalizationBundleName`. With it, every `CYLTabBarItemTitle`, `CYLTabBarItemSelectedTitle`,
 *      `CYLTabBarItemAccessibilityLabel` and `CYLTabBarItemAccessibilityHint` in the configuration (tabs, the plus button,
 *      skins) is a key looked up in `{language}.lproj/{table}.strings` for the library's language
 *      (`CYLLocalizationLanguage()`); a key with no translation stays as it is, as with `NSLocalizedString`. Android reads
 *      the same files, so one configuration and its tables serve every platform.
 * [CN] 配置键：本地化文本（docs/Configuration-File.md「本地化」）。值为 YES（或 "true"）、字符串表名，或包含
 *      `CYLTabBarLocalizationTableName`、`CYLTabBarLocalizationPath`、`CYLTabBarLocalizationBundleName` 的字典。设置后，配置中（Tab、
 *      PlusButton、皮肤）所有 `CYLTabBarItemTitle`、`CYLTabBarItemSelectedTitle`、`CYLTabBarItemAccessibilityLabel`、
 *      `CYLTabBarItemAccessibilityHint` 都作为键，在本库当前语言（`CYLLocalizationLanguage()`）的 `{语言}.lproj/{表名}.strings` 中查找；
 *      没有译文的键保持原样，与 `NSLocalizedString` 相同。Android 读取同样的文件，一份配置及其字符串表适用于所有平台。
 */
public let CYLTabBarControllerLocalization = "CYLTabBarControllerLocalization"

/**
 * [EN] Configuration key: a resource route (`CYLResourceRoute`, docs/Resource-Routes.md) to a configuration file, built
 *      into the app or in its sandbox, e.g. "bundle:Configurations?name=tabbar" or "sandbox:Caches/tabbar?name=tabbar&theme=dark".
 *      The file's keys are read first, then the other keys of this configuration win over them, so code (or React Native
 *      and Flutter, which send a dictionary) can change a few values of a file. A route that matches no file is logged and
 *      ignored. Android reads the same key.
 * [CN] 配置键：指向配置文件的资源路由（`CYLResourceRoute`，docs/Resource-Routes.md），文件可以内置在 App 中或位于沙盒，例如
 *      "bundle:Configurations?name=tabbar" 或 "sandbox:Caches/tabbar?name=tabbar&theme=dark"。先读取文件中的键，再由本配置中的其他键
 *      覆盖，因此代码（以及发送字典的 React Native 与 Flutter）可以修改文件中的少数值。没有匹配文件的路由会打印日志并被忽略。Android 读取同一个键。
 */
public let CYLTabBarControllerConfigurationRoute = "CYLTabBarControllerConfigurationRoute"

/**
 * [EN] Configuration key: a resource route to a tab bar manifest (`CYLTabBarManifest`, docs/Configuration-Manifest.md).
 *      The manifest's configuration (`-[CYLTabBarManifest configuration]`) is read first, then the other keys win over it;
 *      React Native's `manifestRoute` prop and Flutter's `manifestRoute` parameter write it. A route that is not a
 *      manifest this app may use (platform, app version, time) is logged and ignored. Android reads the same key.
 * [CN] 配置键：指向 TabBar 配置清单的资源路由（`CYLTabBarManifest`，docs/Configuration-Manifest.md）。先读取清单的配置
 *      （`-[CYLTabBarManifest configuration]`），再由其他键覆盖；React Native 的 `manifestRoute` 属性与 Flutter 的 `manifestRoute` 参数写入该键。
 *      不是本 App 可以使用的清单（平台、App 版本、时间）时打印日志并忽略。Android 读取同一个键。
 */
public let CYLTabBarControllerManifestRoute = "CYLTabBarControllerManifestRoute"

/**
 * [EN] The strings table, without ".strings" (default "Localizable"). [CN] 字符串表名，不含 ".strings"（默认 "Localizable"）。
 */
public let CYLTabBarLocalizationTableName = "CYLTabBarLocalizationTableName"

/**
 * [EN] The folder that holds the `{language}.lproj` folders, always in the app (never in this library), as a location
 *      route (docs/Configuration-Localization.md): "bundle:<path>" (the app's resources), "sandbox:Documents/…",
 *      "sandbox:Caches/…" or "sandbox:tmp/…" (tables downloaded at run time; the same names on Android), a "file:" URL, an
 *      absolute path, "~/…" (the app's home folder), or a path relative to the configuration file's folder (to the app's
 *      resources when the configuration did not come from a file). Takes precedence over `CYLTabBarLocalizationBundleName`.
 * [CN] 存放 `{语言}.lproj` 文件夹的目录，始终位于 App 中（不在本库中），写作位置路由（docs/Configuration-Localization.md）：
 *      "bundle:<路径>"（App 资源）、"sandbox:Documents/…"、"sandbox:Caches/…" 或 "sandbox:tmp/…"（运行时下载的字符串表；Android 使用相同的名称）、
 *      "file:" URL、绝对路径、"~/…"（App 主目录），或相对于配置文件所在目录的路径（配置不是来自文件时，相对于 App 资源目录）。
 *      优先于 `CYLTabBarLocalizationBundleName`。
 */
public let CYLTabBarLocalizationPath = "CYLTabBarLocalizationPath"

/**
 * [EN] A resource bundle in the app ("Texts" or "Texts.bundle"; Android: a folder in the assets); default the main bundle (Android: the assets root). [CN] App 中的资源包（"Texts" 或 "Texts.bundle"；Android：assets 中的文件夹）；默认 main bundle（Android：assets 根目录）。
 */
public let CYLTabBarLocalizationBundleName = "CYLTabBarLocalizationBundleName"

/**
 * [EN] The identifier of a skin in the list form of `CYLTabBarControllerThemes`. [CN] `CYLTabBarControllerThemes` 列表形式中皮肤的标识。
 */
public let CYLTabBarThemeIdentifier = "CYLTabBarThemeIdentifier"

/**
 * [EN] The named values of a skin in the list form of `CYLTabBarControllerThemes`. [CN] `CYLTabBarControllerThemes` 列表形式中皮肤的命名值。
 */
public let CYLTabBarThemeValues = "CYLTabBarThemeValues"

/**
 * [EN] Skin value name: the background color of the whole tab bar. [CN] 皮肤值名称：整个 TabBar 的背景色。
 */
public let CYLTabBarBackgroundColor = "CYLTabBarBackgroundColor"

/**
 * [EN] Skin value name: the separator line on top of the tab bar. [CN] 皮肤值名称：TabBar 顶部分割线的颜色。
 */
public let CYLTabBarShadowColor = "CYLTabBarShadowColor"

/**
 * [EN] Skin value name: an image behind the whole tab bar (`UITabBarAppearance.backgroundImage`): a name, "system:<name>" or a path. [CN] 皮肤值名称：整个 TabBar 的背景图片（`UITabBarAppearance.backgroundImage`）：名称、"system:<名称>" 或路径。
 */
public let CYLTabBarBackgroundImage = "CYLTabBarBackgroundImage"

/**
 * [EN] Skin value name: the image of the line on top of the tab bar (`UITabBarAppearance.shadowImage`). [CN] 皮肤值名称：TabBar 顶部线条的图片（`UITabBarAppearance.shadowImage`）。
 */
public let CYLTabBarShadowImage = "CYLTabBarShadowImage"

/**
 * [EN] Skin value name: how the items share the width (`stackedItemPositioning`): "centered", "fill" or "automatic". [CN] 皮肤值名称：各 Item 如何分配宽度（`stackedItemPositioning`）："centered"、"fill" 或 "automatic"。
 */
public let CYLTabBarStackedItemPositioning = "CYLTabBarStackedItemPositioning"

/**
 * [EN] Skin value name: the width of each item when centered, in points (`stackedItemWidth`; 0: an equal share). [CN] 皮肤值名称：居中时每个 Item 的宽度（pt，`stackedItemWidth`；0 表示平分）。
 */
public let CYLTabBarStackedItemWidth = "CYLTabBarStackedItemWidth"

/**
 * [EN] Skin value name: the space between centered items, in points (`stackedItemSpacing`). [CN] 皮肤值名称：居中的 Item 之间的间距（pt，`stackedItemSpacing`）。
 */
public let CYLTabBarStackedItemSpacing = "CYLTabBarStackedItemSpacing"

/**
 * [EN] Item keys of the pages and of remote configurations (see docs/Tab-Page-Registry.md):
 *      - `CYLTabBarItemPageIdentifier`: NSString, the cross-platform ID of the tab's page, e.g. "home"; iOS and Android
 *        register what it creates (see `CYLTabBarPageRegistry`). Missing or "": `CYLTabBarItemIdentifier` is used. A
 *        tab whose page is not found is skipped. Used only when `CYLTabBarControllerViewControllers` is not given.
 *      - `CYLTabBarItemPageParameters`: NSDictionary, passed to the page provider in the tab's attributes, e.g.
 *        {url: "https://..."} for two tabs that show the same web page class.
 *      - `CYLTabBarItemPlatforms`: NSArray<NSString *> or a comma-separated NSString, e.g. ["ios", "android"]; the tab
 *        is left out on iOS unless the list contains "ios". Missing: every platform.
 *      - `CYLTabBarItemMinimumAppVersion`: NSString, e.g. "2.3.0"; the tab is left out when the app's
 *        CFBundleShortVersionString is lower. With view controllers from code, a left-out tab takes its view
 *        controller out with it.
 *      In a file, image keys (`CYLTabBarItemImage`, `CYLTabBarItemSelectedImage` and the dark ones) also take
 *      "system:<SF Symbol name>" (iOS 13+), e.g. "system:house.fill"; Lottie URL keys take an http(s) URL, a path or a
 *      file name in the main bundle; `CYLTabBarItemImageURLSize` / `CYLTabBarLottieSize` take "{width, height}";
 *      `CYLTabBarLottieDarkColors` takes "#RRGGBB" or "#RRGGBBAA" colors.
 * [CN] 页面与远程配置相关的 item 键（见 docs/Tab-Page-Registry.md）：
 *      - `CYLTabBarItemPageIdentifier`：NSString，Tab 页面的跨端 ID，例如 "home"；iOS 与 Android 各自注册它创建什么页面（见
 *        `CYLTabBarPageRegistry`）。未设置或为 ""：使用 `CYLTabBarItemIdentifier`。找不到页面的 Tab 会被跳过。只在没有传入
 *        `CYLTabBarControllerViewControllers` 时使用。
 *      - `CYLTabBarItemPageParameters`：NSDictionary，随 Tab 的属性传给页面提供者，例如两个 Tab 使用同一个网页类时的
 *        {url: "https://..."}。
 *      - `CYLTabBarItemPlatforms`：NSArray<NSString *> 或逗号分隔的 NSString，例如 ["ios", "android"]；列表中没有 "ios" 时，
 *        iOS 上不显示该 Tab。未设置：所有平台。
 *      - `CYLTabBarItemMinimumAppVersion`：NSString，例如 "2.3.0"；App 的 CFBundleShortVersionString 更低时不显示该 Tab。
 *        子控制器由代码传入时，不显示的 Tab 连同其子控制器一起移除。
 *      文件中，图片键（`CYLTabBarItemImage`、`CYLTabBarItemSelectedImage` 及深色键）也支持 "system:<SF Symbol 名称>"（iOS 13+），
 *      例如 "system:house.fill"；Lottie URL 键支持 http(s) URL、路径或 main bundle 中的文件名；`CYLTabBarItemImageURLSize` /
 *      `CYLTabBarLottieSize` 支持 "{width, height}"；`CYLTabBarLottieDarkColors` 支持 "#RRGGBB" 或 "#RRGGBBAA" 颜色。
 */
public let CYLTabBarItemPageIdentifier = "CYLTabBarItemPageIdentifier"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemPageParameters = "CYLTabBarItemPageParameters"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemPlatforms = "CYLTabBarItemPlatforms"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemMinimumAppVersion = "CYLTabBarItemMinimumAppVersion"

/**
 * [EN] `CYLTabBarAnimationOptions`: the options of the tab's animation as a dictionary, option name -> string, for
 *      configurations (files, URLs or dictionaries). `-initWithConfiguration:` writes them into the fragment of the tab's
 *      animation URLs (`CYLTabBarAnimationURL`, a library's URL key, and their Dark Mode versions) with
 *      `CYLTabBarAnimationURLWithOptions()`; a tab that only has a file path gets a file URL with the options, so the
 *      same options can be written in a file as in code. The names are the option strings, e.g. "artboard",
 *      "stateMachine", "input" for Rive (`CYLTabBarAnimationOptionRive…`). Not a dictionary: ignored with a warning.
 *
 *          {"CYLTabBarAnimationURL": "icons.riv", "CYLTabBarAnimationOptions": {"artboard": "HOME", "input": "active"}}
 *
 * [CN] `CYLTabBarAnimationOptions`：Tab 动画的选项，字典（选项名 -> 字符串），用于配置（文件、URL 或字典）。`-initWithConfiguration:`
 *      用 `CYLTabBarAnimationURLWithOptions()` 把它们写入该 Tab 动画 URL（`CYLTabBarAnimationURL`、动画库的 URL 键及其深色模式版本）的
 *      fragment；只有文件路径的 Tab 会得到带选项的 file URL，因此文件中可以写与代码相同的选项。名称为选项字符串，例如 Rive 的
 *      "artboard"、"stateMachine"、"input"（`CYLTabBarAnimationOptionRive…`）。不是字典时忽略并输出警告。示例见上。
 */
public let CYLTabBarAnimationOptions = "CYLTabBarAnimationOptions"

/**
 * [EN] Optional per-tab colors (UIColor), in `tabBarItemsAttributes` (or `-updateTabBarItemAtIndex:attributes:`). See
 *      docs/Tab-Item-Colors.md.
 *      - `CYLTabBarItemTitleColor` / `CYLTabBarItemSelectedTitleColor`: the title color, unselected / selected.
 *      - `CYLTabBarItemIconColor` / `CYLTabBarItemSelectedIconColor`: the icon tint, unselected / selected. Only template
 *        images are tinted (`UIImageRenderingModeAlwaysTemplate`, SF Symbols); image names are drawn as original.
 *      - `CYLTabBarItemSelectedBackgroundColor`: fills the selected tab (classic tab bar and FlatDesign; Liquid Glass
 *        draws its own selection).
 *      Title and icon colors need iOS 13+ (`UITabBarAppearance`) and are ignored on iOS 12.
 *      Classic and Liquid Glass: the colors are written into the tab's own `UITabBarItem.standardAppearance` (and
 *      `scrollEdgeAppearance` on iOS 15+), a copy of the tab bar's appearance that is rebuilt when that one changes, as
 *      for `CYLTabBarItemTitlePositionAdjustment`; an appearance you installed on the item is kept as the base. FlatDesign:
 *      the flat item's title attributes and `selectedBackgroundColor`.
 * [CN] 可选的单个 Tab 颜色（UIColor），写在 `tabBarItemsAttributes`（或 `-updateTabBarItemAtIndex:attributes:`）中。见
 *      docs/Tab-Item-Colors.md。
 *      - `CYLTabBarItemTitleColor` / `CYLTabBarItemSelectedTitleColor`：标题颜色，未选中 / 选中。
 *      - `CYLTabBarItemIconColor` / `CYLTabBarItemSelectedIconColor`：图标着色，未选中 / 选中。只对模板图片生效
 *        （`UIImageRenderingModeAlwaysTemplate`、SF Symbols）；图片名按原图绘制。
 *      - `CYLTabBarItemSelectedBackgroundColor`：选中 Tab 的背景色（经典 TabBar 与扁平样式；液态玻璃自带选中效果）。
 *      标题与图标颜色需要 iOS 13+（`UITabBarAppearance`），iOS 12 上忽略。
 *      经典与液态玻璃：颜色写入该 Tab 自己的 `UITabBarItem.standardAppearance`（iOS 15+ 还有 `scrollEdgeAppearance`），即 TabBar
 *      appearance 的副本，TabBar 的 appearance 改变时会重建，与 `CYLTabBarItemTitlePositionAdjustment` 相同；你在 item 上设置的
 *      appearance 会作为基础保留。扁平样式：写入扁平 item 的标题属性与 `selectedBackgroundColor`。
 */
public let CYLTabBarItemTitleColor = "CYLTabBarItemTitleColor"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemSelectedTitleColor = "CYLTabBarItemSelectedTitleColor"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemIconColor = "CYLTabBarItemIconColor"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemSelectedIconColor = "CYLTabBarItemSelectedIconColor"

/**
 * [EN] FIX: issue #787 (and #159, #465, #588). How a tab's icon takes its colors, after Kongzue Tabbar's `noDyeing` and
 *      `focusColor` / `normalColor`:
 *      - `CYLTabBarItemIconRenderingMode` (a tab) / `CYLTabBarControllerIconRenderingMode` (every tab without its own):
 *        "template": the icon is tinted, so one image serves both states (no selected image needed): unselected with
 *        `CYLTabBarItemIconColor`, selected with `CYLTabBarItemSelectedIconColor`, else the tab bar's tint colors.
 *        "original": the icon keeps its own colors, even when an icon color is set (the fix for gray icons, #465 / #588).
 *        "automatic" (default): as before: on iOS image names keep their colors and template images (SF Symbols) are
 *        tinted; on Android an icon is tinted when it has an icon color.
 *      - `CYLTabBarControllerIconColor` / `CYLTabBarControllerSelectedIconColor`: the icon colors of every tab without its
 *        own ("#RRGGBB" in a file, or a UIColor), like Kongzue Tabbar's `normalColor` / `focusColor` for icons.
 *      iOS and Android (`CYLConstants`, same keys); React Native and Flutter are a TODO in docs/Tab-Item-Colors.md.
 * [CN] FIX: issue #787（以及 #159、#465、#588）。Tab 图标如何取色，参照 Kongzue Tabbar 的 `noDyeing` 与 `focusColor` / `normalColor`：
 *      - `CYLTabBarItemIconRenderingMode`（单个 Tab）/ `CYLTabBarControllerIconRenderingMode`（没有单独设置的所有 Tab）：
 *        "template"：图标被着色，因此一张图即可用于两种状态（无需选中图片）：未选中使用 `CYLTabBarItemIconColor`，选中使用
 *        `CYLTabBarItemSelectedIconColor`，否则使用 TabBar 的着色。"original"：图标保持原色，即使设置了图标颜色（解决图标变灰，#465 / #588）。
 *        "automatic"（默认）：与之前相同：iOS 上图片名保持原色、模板图片（SF Symbols）被着色；Android 上有图标颜色时着色。
 *      - `CYLTabBarControllerIconColor` / `CYLTabBarControllerSelectedIconColor`：没有单独设置的所有 Tab 的图标颜色（文件中为 "#RRGGBB"，
 *        或 UIColor），相当于 Kongzue Tabbar 中用于图标的 `normalColor` / `focusColor`。
 *      iOS 与 Android（`CYLConstants`，键相同）已支持；React Native 与 Flutter 见 docs/Tab-Item-Colors.md 的 TODO。
 */
public let CYLTabBarItemIconRenderingMode = "CYLTabBarItemIconRenderingMode"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerIconRenderingMode = "CYLTabBarControllerIconRenderingMode"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerIconColor = "CYLTabBarControllerIconColor"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarControllerSelectedIconColor = "CYLTabBarControllerSelectedIconColor"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemSelectedBackgroundColor = "CYLTabBarItemSelectedBackgroundColor"

/**
 * [EN] Optional background of the tab while NOT selected (UIColor), the counterpart of
 *      `CYLTabBarItemSelectedBackgroundColor`, which falls back to it when not set. Classic tab bar and FlatDesign, as the
 *      selected one. With `itemSpacing` (and no item width), the tab bar shows through the gaps as separators. See
 *      docs/Tab-Item-Colors.md.
 * [CN] 可选的 Tab 未选中时的背景色（UIColor），与 `CYLTabBarItemSelectedBackgroundColor` 对应；后者未设置时使用本值。与选中背景色
 *      一样适用于经典 TabBar 与扁平样式。配合 `itemSpacing`（且未设置 item 宽度）时，TabBar 的背景透过间隙显示为分隔线。见
 *      docs/Tab-Item-Colors.md。
 */
public let CYLTabBarItemBackgroundColor = "CYLTabBarItemBackgroundColor"

/**
 * [EN] Optional per-tab title fonts (UIFont), unselected / selected; the selected state uses the unselected font unless
 *      it has its own. Applied like the colors above (iOS 13+), also in FlatDesign. A larger font for one tab, or a bold
 *      title only while selected. See docs/Tab-Item-Colors.md.
 * [CN] 可选的单个 Tab 标题字体（UIFont），未选中 / 选中；选中状态没有单独设置时使用未选中的字体。与上面的颜色一样生效（iOS 13+），
 *      扁平样式同样支持。例如为某个 Tab 使用更大的字体，或只在选中时加粗。见 docs/Tab-Item-Colors.md。
 */
public let CYLTabBarItemTitleFont = "CYLTabBarItemTitleFont"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemSelectedTitleFont = "CYLTabBarItemSelectedTitleFont"

/**
 * [EN] Accessibility of a tab, for VoiceOver and UI tests (`app.tabBars.buttons["home"]`). See docs/Tab-Accessibility.md.
 *      - By default every tab gets an `accessibilityIdentifier`: its `CYLTabBarItemIdentifier` (or the default one, its
 *        content view controller's class name); the plus button gets its own identifier the same way. An identifier the
 *        app set itself is never replaced.
 *      - `CYLTabBarItemAccessibilityIdentifier`, `CYLTabBarItemAccessibilityLabel`, `CYLTabBarItemAccessibilityHint`
 *        (NSString) in `tabBarItemsAttributes` set them explicitly; without a label VoiceOver reads the title as before.
 *      Classic and Liquid Glass: written on the tab's UITabBarItem, which UIKit's tab button reads. FlatDesign: written on
 *      the flat tab button. Applied on layout, so a reload or an in-place update is picked up.
 * [CN] Tab 的无障碍信息，用于 VoiceOver 与 UI 测试（`app.tabBars.buttons["home"]`）。见 docs/Tab-Accessibility.md。
 *      - 默认每个 Tab 都会得到 `accessibilityIdentifier`：其 `CYLTabBarItemIdentifier`（未设置时为默认值，即内容控制器的类名）；
 *        PlusButton 同样得到自己的标识。App 自己设置的 identifier 不会被替换。
 *      - `tabBarItemsAttributes` 中的 `CYLTabBarItemAccessibilityIdentifier`、`CYLTabBarItemAccessibilityLabel`、
 *        `CYLTabBarItemAccessibilityHint`（NSString）显式指定；未设置 label 时 VoiceOver 与以前一样朗读标题。
 *      经典与液态玻璃：写入该 Tab 的 UITabBarItem，UIKit 的 Tab 按钮会读取它。扁平样式：写入扁平 Tab 按钮。布局时生效，因此
 *      重新加载或原地更新后都会更新。
 */
public let CYLTabBarItemAccessibilityIdentifier = "CYLTabBarItemAccessibilityIdentifier"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemAccessibilityLabel = "CYLTabBarItemAccessibilityLabel"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemAccessibilityHint = "CYLTabBarItemAccessibilityHint"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemWidthDidChangeNotification = "CYLTabBarItemWidthDidChangeNotification"

/**
 * [EN] userInfo of the tab notifications below (`CYLTabBarItemTitleDidChangeNotification`, `CYLTabBarItemIconDidChangeNotification`,
 *      `CYLTabBarItemDidChangeNotification`). The object of each is the tab's page (the root view controller of its
 *      navigation controller); userInfo names exactly what changed:
 *      - `CYLTabBarControllerKey`: the tab bar controller.
 *      - `CYLTabBarItemIdentifier`: the tab's identifier (from its attributes), the exact way to find it; absent when it has none.
 *      - `CYLTabBarItemIndexKey`: the tab's index in `viewControllers` (NSNumber).
 *      - `CYLTabBarItemViewControllerKey`: the tab's entry in `viewControllers` (e.g. its navigation controller).
 *      - `CYLTabBarItemKey`: the tab's item (`UITabBarItem`; `CYLFlatDesignTabBarItem` on FlatDesign).
 *      - `CYLTabBarItemChangedAttributesKey`: the changed attributes, keys and new values (when the change came from attributes).
 * [CN] 下列 Tab 通知（`CYLTabBarItemTitleDidChangeNotification`、`CYLTabBarItemIconDidChangeNotification`、`CYLTabBarItemDidChangeNotification`）的
 *      userInfo。object 均为该 Tab 的页面（导航控制器的根控制器）；userInfo 精确指出变化的对象：
 *      - `CYLTabBarControllerKey`：TabBar 控制器。
 *      - `CYLTabBarItemIdentifier`：Tab 的 ID（来自其 attributes），精确定位 Tab 的方式；没有 ID 时不存在。
 *      - `CYLTabBarItemIndexKey`：Tab 在 `viewControllers` 中的下标（NSNumber）。
 *      - `CYLTabBarItemViewControllerKey`：Tab 在 `viewControllers` 中的控制器（例如其导航控制器）。
 *      - `CYLTabBarItemKey`：Tab 的 item（`UITabBarItem`；扁平样式为 `CYLFlatDesignTabBarItem`）。
 *      - `CYLTabBarItemChangedAttributesKey`：变化的 attributes，key 与新值（变化来自 attributes 时）。
 */
public let CYLTabBarControllerKey = "CYLTabBarControllerKey"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemViewControllerKey = "CYLTabBarItemViewControllerKey"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarItemKey = "CYLTabBarItemKey"

/**
 * [EN] userInfo key when the plus button changed (`-updatePlusButtonWithAttributes:`, skins): the plus button. The same three
 *      notifications are posted; their object is the plus button's page (the plus child view controller), or the plus button
 *      when it has no page. Its page follows the new title like any tab (`CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM`).
 * [CN] PlusButton 变化时（`-updatePlusButtonWithAttributes:`、换肤）的 userInfo key：PlusButton。发送同样的三个通知；object 为 PlusButton 的
 *      页面（PlusButton 子控制器），没有页面时为 PlusButton。其页面与其他 Tab 一样跟随新标题（`CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM`）。
 */
public let CYLPlusButtonKey = "CYLPlusButtonKey"

/**
 * [EN] userInfo key of the title notification: the title before the change. [CN] 标题通知的 userInfo key：变化前的标题。
 */
public let CYLTabBarItemOldTitleKey = "CYLTabBarItemOldTitleKey"

/**
 * [EN] userInfo key: the changed attributes (NSDictionary). [CN] userInfo key：变化的 attributes（NSDictionary）。
 */
public let CYLTabBarItemChangedAttributesKey = "CYLTabBarItemChangedAttributesKey"

/**
 * [EN] userInfo key: the tab's index in `viewControllers` (NSNumber). [CN] userInfo key：Tab 在 `viewControllers` 中的下标（NSNumber）。
 */
public let CYLTabBarItemIndexKey = "CYLTabBarItemIndexKey"

/**
 * [EN] userInfo key of the icon notification: the `CYLTabBarItemIconViewProvider` now shown in place of the icon. [CN] 图标通知的 userInfo key：当前替换图标显示的 `CYLTabBarItemIconViewProvider`。
 */
public let CYLTabBarItemIconViewProviderKey = "CYLTabBarItemIconViewProviderKey"

/**
 * [EN] userInfo key: the applied theme. [CN] userInfo key：应用的主题。
 */
public let CYLTabBarThemeKey = "CYLTabBarThemeKey"

/**
 * [EN] userInfo key of `CYLTabBarControllerThemeDidApplyNotification`: the indexes (in `viewControllers`) of the tabs a skin
 *      changed (NSIndexSet); by default every tab, the plus button's tab excepted.
 * [CN] `CYLTabBarControllerThemeDidApplyNotification` 的 userInfo key：皮肤修改的 Tab 下标（`viewControllers` 中，NSIndexSet）；默认为全部 Tab，
 *      PlusButton 的 Tab 除外。
 */
public let CYLTabBarItemIndexesKey = "CYLTabBarItemIndexesKey"

/**
 * [EN] userInfo key of `CYLTabBarControllerThemeDidApplyNotification`: the identifiers (`CYLTabBarItemIdentifier`) of the
 *      tabs it changed, in tab order (NSArray<NSString *>); tabs without an identifier are left out.
 * [CN] `CYLTabBarControllerThemeDidApplyNotification` 的 userInfo key：修改的 Tab 的 ID（`CYLTabBarItemIdentifier`），按 Tab 顺序
 *      （NSArray<NSString *>）；没有 ID 的 Tab 不在其中。
 */
public let CYLTabBarItemIdentifiersKey = "CYLTabBarItemIdentifiersKey"

/**
 * [EN] A view that shows only the tab bar of a CYLTabBarController made from a configuration
 *      (`+[CYLTabBarController tabBarControllerWithConfiguration:]`, see docs/Configuration-File.md). The pages belong to
 *      someone else: React Native, Flutter, or an app that draws its own content. Every tab gets a transparent, empty page.
 *      The React Native and Flutter components of `CrossPlatform/` are thin wrappers around it.
 *
 *      - The tab bar controller is built once the view is in a window with a real width (a bar laid out at width 0 keeps
 *        its titles cut), and added as a child of the nearest view controller.
 *      - Image values given as URL strings (a file, or a dev server) are loaded on a background queue first, then the tab
 *        bar is built on the main queue; `imageResolver` handles other values (e.g. a Flutter asset).
 *      - Each view uses its own `CYLTabBarControllerContext` unless the configuration gives one, so several can be on screen.
 *      - Indexes (`selectedIndex`, `badgeValues`, `didSelectTab`) count the tabs of the configuration; the plus button is
 *        left out.
 *
 *          CYLTabBarHostView *bar = [[CYLTabBarHostView alloc] init];
 *          bar.didSelectTab = ^(NSInteger index, NSString *identifier) { [self showPageAtIndex:index]; };
 *          bar.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : items };
 *
 * [CN] 只显示 TabBar 的视图：TabBar 来自根据配置创建的 CYLTabBarController（`+[CYLTabBarController tabBarControllerWithConfiguration:]`，
 *      见 docs/Configuration-File.md）。页面由别人绘制：React Native、Flutter，或自己绘制内容的 App。每个 Tab 得到一个透明的空页面。
 *      `CrossPlatform/` 中的 React Native 与 Flutter 组件都是它的薄封装。
 *
 *      - 视图进入 window 并有真实宽度后才创建 TabBarController（宽度为 0 时布局的 TabBar 会一直截断标题），并加入最近的视图控制器。
 *      - 以 URL 字符串给出的图片（文件或开发服务器）先在后台队列加载，再在主队列创建 TabBar；其他值（例如 Flutter asset）由
 *        `imageResolver` 处理。
 *      - 配置没有给出 `CYLTabBarControllerContext` 时，每个视图使用自己的 context，因此屏幕上可以同时有多个。
 *      - 下标（`selectedIndex`、`badgeValues`、`didSelectTab`）按配置中的 Tab 计算，不含 PlusButton。
 * [EN] Keys of `badgeAttributes` / `plusButtonBadgeAttributes`. [CN] `badgeAttributes` / `plusButtonBadgeAttributes` 的键。
 */
public let CYLTabBarHostBadgeValue = "value"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarHostBadgeColor = "color"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarHostBadgeAnimation = "animation"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarHostBadgeRadius = "radius"

/**
 * [EN] See the Objective-C header.
 * [CN] 见 Objective-C 头文件。
 */
public let CYLTabBarHostBadgeCenterOffset = "centerOffset"

/**
 * [EN] The URL of a sample configuration on GitHub, used by the demo's "load from a URL" action.
 * [CN] GitHub 上示例配置文件的 URL，用于演示中的“从网络 URL 加载”。
 */
public let CYLSampleConfigurationURLString = "https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/Example-Shared/Configurations/cyl_tabbar_configuration.yaml"

extension NSNotification.Name {
    /**
     * [EN] Posted when `-[CYLTabBarController cyl_loggedIn]` is set; `object` is the tab bar controller it was set on.
     * [CN] 设置 `-[CYLTabBarController cyl_loggedIn]` 时发送；`object` 为被设置的 TabBarController。
     */
    public static let CYLTabBarLoginStateDidChange = NSNotification.Name("CYLTabBarLoginStateDidChangeNotification")

    /**
     * FIX: issue #604
     * [EN] Library-neutral names of the two notifications above, for any animation library (Lottie, PAG, Rive…). They have the
     *      same values, so an observer of either name gets the notification; the Lottie names stay for compatibility.
     * [CN] 上面两个通知的通用名称，适用于任意动画库（Lottie、PAG、Rive…）。取值相同，因此观察任一名称都能收到通知；Lottie 名称为兼容而保留。
     */
    public static let CYLTabBarItemAnimationPlaying = NSNotification.Name("CYLTabBarItemLottieAnimationPlayingNotification")

    /**
     * [EN] See the Objective-C header.
     * [CN] 见 Objective-C 头文件。
     */
    public static let CYLTabBarItemAnimationViewDidAdd = NSNotification.Name("CYLTabBarItemLottieAnimationViewDidAddNotification")

    /**
     * [EN] Posted when a tab's title or selected title changes in place (`-updateTabBarItemsWithAttributes:`,
     *      `-updateTabBarItemAtIndex:…`, skins and the APIs built on them). userInfo: the keys above, plus
     *      `CYLTabBarItemTitle` (the new title), `CYLTabBarItemSelectedTitle` (when the tab has one) and
     *      `CYLTabBarItemOldTitleKey` (the title before, when there was one).
     * [CN] Tab 标题或选中标题原地变化时发送（`-updateTabBarItemsWithAttributes:`、`-updateTabBarItemAtIndex:…`、换肤以及基于它们的接口）。
     *      userInfo：上述 key，以及 `CYLTabBarItemTitle`（新标题）、`CYLTabBarItemSelectedTitle`（有选中标题时）、
     *      `CYLTabBarItemOldTitleKey`（之前的标题，有时）。
     */
    public static let CYLTabBarItemTitleDidChange = NSNotification.Name("CYLTabBarItemTitleDidChangeNotification")

    /**
     * [EN] Posted after any in-place change of a tab (`-updateTabBarItemAtIndex:attributes:`, `-updateTabBarItemsWithAttributes:`,
     *      skins): title, selected title, images, colors, fonts, animations, image URLs. The object is the tab's page (the root
     *      view controller of its navigation controller). `userInfo[CYLTabBarItemChangedAttributesKey]` holds the changed
     *      attributes (their keys and new values), `userInfo[CYLTabBarItemIndexKey]` the tab's index in `viewControllers`.
     *      A title change posts `CYLTabBarItemTitleDidChangeNotification` too.
     * [CN] Tab 任意原地变化后发送（`-updateTabBarItemAtIndex:attributes:`、`-updateTabBarItemsWithAttributes:`、换肤）：标题、选中标题、图片、
     *      颜色、字体、动画、图片 URL。object 为该 Tab 的页面（导航控制器的根控制器）。`userInfo[CYLTabBarItemChangedAttributesKey]` 为变化的
     *      attributes（key 与新值），`userInfo[CYLTabBarItemIndexKey]` 为该 Tab 在 `viewControllers` 中的下标。标题变化时也会发送
     *      `CYLTabBarItemTitleDidChangeNotification`。
     */
    public static let CYLTabBarItemDidChange = NSNotification.Name("CYLTabBarItemDidChangeNotification")

    /**
     * [EN] Posted when a tab's icon changes in place: image keys (`CYLTabBarItemImage`, `CYLTabBarItemSelectedImage`, their dark
     *      variants, `CYLTabBarItemImageURL`…) through `-updateTabBarItemAtIndex:attributes:`, and a view shown in place of the
     *      icon (`-setTabBarItemIcon:selectedIcon:size:atIndex:`, `-setTabBarItemIconWithURL:…` once loaded, skins, restoring).
     *      userInfo: the keys above (`CYLTabBarItemChangedAttributesKey`: the changed image keys), plus
     *      `CYLTabBarItemIconViewProviderKey` for a view in place of the icon (absent when the tab's own icon comes back).
     *      Images loaded from `CYLTabBarItemImageURL` arrive later.
     * [CN] Tab 图标原地变化时发送：通过 `-updateTabBarItemAtIndex:attributes:` 修改图片 key（`CYLTabBarItemImage`、`CYLTabBarItemSelectedImage`、
     *      对应的深色图片、`CYLTabBarItemImageURL`…），以及替换图标显示的视图（`-setTabBarItemIcon:selectedIcon:size:atIndex:`、加载完成的
     *      `-setTabBarItemIconWithURL:…`、换肤、恢复）。userInfo：上述 key（`CYLTabBarItemChangedAttributesKey` 为变化的图片 key），以及替换图标的
     *      视图的 `CYLTabBarItemIconViewProviderKey`（恢复 Tab 自己的图标时不存在）。从 `CYLTabBarItemImageURL` 加载的图片稍后才到。
     */
    public static let CYLTabBarItemIconDidChange = NSNotification.Name("CYLTabBarItemIconDidChangeNotification")

    /**
     * [EN] Posted by a tab bar controller after it applied a skin (`CYLThemeManager`, a `CYLTabBarTheme` or none to restore):
     *      the tabs, the plus button and the appearance are already updated; network or animated icons may still be loading.
     *      The object is the tab bar controller; `userInfo[CYLTabBarThemeKey]` is the theme (absent when restoring), and
     *      `userInfo[CYLTabBarItemIndexesKey]` / `userInfo[CYLTabBarItemIdentifiersKey]` the tabs it changed (all of them by default).
     *      `CYLThemeDidChangeNotification` comes from the manager, before the tab bar applies the skin.
     * [CN] TabBar 控制器应用皮肤后发送（`CYLThemeManager`、`CYLTabBarTheme`，或无主题以恢复）：Tab、PlusButton 与外观都已更新；网络图标或
     *      动画图标可能仍在加载。object 为 TabBar 控制器；`userInfo[CYLTabBarThemeKey]` 为主题（恢复时不存在），
     *      `userInfo[CYLTabBarItemIndexesKey]` / `userInfo[CYLTabBarItemIdentifiersKey]` 为修改的 Tab（默认全部）。`CYLThemeDidChangeNotification`
     *      由管理器发送，早于 TabBar 应用皮肤。
     */
    public static let CYLTabBarControllerThemeDidApply = NSNotification.Name("CYLTabBarControllerThemeDidApplyNotification")
}
