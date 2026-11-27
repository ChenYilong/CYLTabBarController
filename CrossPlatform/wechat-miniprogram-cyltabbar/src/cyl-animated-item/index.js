/**
 * [EN] cyl-animated-item: an icon + title view to reuse in other repositories (CollectionViewClassifyMenu's tags,
 *      CYLSearchViewController's bar items): an icon that plays an animation file through the abstract nodes
 *      `cyl-lottie-view`, `cyl-pag-view`, `cyl-rive-view`, `cyl-svga-view` (the app names its engine components, e.g.
 *      `generic:cyl-lottie-view="cyl-lottie"`; GIF is drawn by `<image>`), its static image, a title beside or below it,
 *      an optional accessory with its own tap (`accessorytap`), and gestures on the whole item (`itemtap`,
 *      `itemlongpress`, `dragstart` / `dragmove` / `dragend` when `drag-enabled`). It depends on no animation package.
 *      A file whose engine is not installed shows the static image, or the placeholder, and logs once in the developer
 *      tools which package to add. Accessibility: one element, role button, `accessibility-label` (else the title),
 *      selected and disabled states.
 * [CN] cyl-animated-item：可在其他仓库复用的图标 + 标题视图（CollectionViewClassifyMenu 的标签、CYLSearchViewController 的栏目）：
 *      通过抽象节点 `cyl-lottie-view`、`cyl-pag-view`、`cyl-rive-view`、`cyl-svga-view` 播放动画文件的图标（App 指定引擎组件，例如
 *      `generic:cyl-lottie-view="cyl-lottie"`；GIF 由 `<image>` 绘制）、其静态图片、位于旁边或下方的标题、带独立点击的可选附加图标
 *      （`accessorytap`），以及整个条目的手势（`itemtap`、`itemlongpress`，`drag-enabled` 时的 `dragstart` / `dragmove` / `dragend`）。
 *      不依赖任何动画包。没有安装引擎的文件显示静态图片或占位图，并在开发者工具中输出一次需要安装的包。无障碍：一个元素，角色为按钮，
 *      `accessibility-label`（否则为标题），带选中与禁用状态。
 */
const {
  cylAnimatedItemAdaptedColor, cylAnimatedItemBackground, cylAnimatedItemDrawsLiquidGlass, cylAnimatedItemIsAnimationEngineAvailable, cylAnimatedItemIsDark, cylAnimatedItemTintColor, cylAnimatedItemMissingReason, cylAnimatedItemModel, cylAnimatedItemPackage, cylAnimatedItemRenderingMode, cylAnimatedItemResource, cylAnimatedItemRestingProgress,
} = require('./cyl_animated_item_model')
const { cylGIFImageInfo } = require('./cyl_gif_image')
const { cylGIFColorKind } = require('./cyl_one_color_detector')
// [EN] The one-color detection of a GIF animation, cached per URL. [CN] GIF 动画的单色检测结果，按 URL 缓存。
const cylGIFColorKindCache = {}
const { CYLAnimatedItemPlayer } = require('./cyl_animated_item_player')
const { CYLAnimatedItemCountdown, CYL_COUNTDOWN_TICK_INTERVAL } = require('./cyl_animated_item_countdown')
const { LifecycleController } = require('../cyl-dealloc-block-executor/index')
const {
  cylAnimationDidStart, cylAnimationDidStop, cylForgetAnimation, cylPauseAnimation, cylResumeAnimation,
} = require('./cyl_animation_events')

/**
 * [EN] What `detached` releases: the countdown timer, the app-show and theme listeners and the GIF timers. It runs as the keyed
 *      teardown block `cyl.animatedItem.teardown` of CYLDeallocBlockExecutor (see `lifetimes`).
 * [CN] `detached` 释放的内容：倒计时定时器、App 显示与主题监听、GIF 定时器。它作为 CYLDeallocBlockExecutor 中带 key 的销毁块
 *      `cyl.animatedItem.teardown` 运行（见 `lifetimes`）。
 */
function cylTeardown(item) {
  cylForgetAnimation(item)
  if (item.cylPlayer) item.cylPlayer.destroy()
  item.cylStopCountdownTimer()
  if (typeof wx !== 'undefined' && typeof wx.offAppShow === 'function' && item.cylAppShowListener) wx.offAppShow(item.cylAppShowListener)
  clearTimeout(item.cylGifTimer)
  clearTimeout(item.cylGIFImageTimer)
  if (typeof wx !== 'undefined' && typeof wx.offThemeChange === 'function' && item.cylThemeListener) wx.offThemeChange(item.cylThemeListener)
}

/**
 * [EN] The id of the engine node (only one is rendered), reached by `selectComponent` for the playback methods.
 * [CN] 引擎节点的 id（只渲染一个），播放方法通过 `selectComponent` 获取它。
 */
const CYL_ENGINE_ID = '#cyl-animated-item-engine'

const cylWarnedTypes = []

Component({
  properties: {
    // [EN] The background (flat, or Liquid Glass), corner radius and border, the same names as iOS, Android and HarmonyOS:
    //      see cylAnimatedItemBackground() in cyl_animated_item_model.js. -1 (cornerRadius) and '' mean not set. A glass color with alpha 0
//      ('transparent', '#00000000') draws the default frosted tint, as ''.
    // [CN] 背景（扁平或液态玻璃）、圆角与边框，与 iOS、Android、鸿蒙同名：见 cyl_animated_item_model.js 的 cylAnimatedItemBackground()。圆角 -1 与 '' 表示未设置。玻璃颜色透明度为 0（'transparent'、'#00000000'）时使用默认的磨砂着色，与 '' 相同。
    itemBackgroundStyle: { type: String, value: 'flat' },
    itemBackgroundColor: { type: String, value: '' },
    itemCornerRadius: { type: Number, value: -1 },
    // [EN] The space between the outer border and the content on the left and right, in px, on top of the padding. -1 (default) is not set: the drawn
    //      Liquid Glass gets cylAnimatedItemLiquidGlassContentInset (a capsule's round ends take room from the content), flat gets 0; 0 or more is explicit.
    //      The partner of itemCornerRadius. [CN] 外侧边框与内容之间左右的间距（px），叠加在内边距之上。-1（默认）表示未设置：绘制液态玻璃时取
    //      cylAnimatedItemLiquidGlassContentInset（胶囊圆端会占去内容空间），扁平为 0；0 及以上为显式值。与 itemCornerRadius 一一对应。
    itemContentHorizontalInset: { type: Number, value: -1 },
    itemBorderWidth: { type: Number, value: 0 },
    itemBorderColor: { type: String, value: '' },
    // The share of the color's alpha that tints a Liquid Glass: -1 (default) is 0.75, 1 the color as it is.
    itemGlassTintAlpha: { type: Number, value: -1 },
    title: { type: String, value: '' },
    image: { type: String, value: '' },
    selectedImage: { type: String, value: '' },
    placeholderImage: { type: String, value: null, optionalTypes: [Object] },
    animationUrl: { type: String, value: '' },
    selected: { type: Boolean, value: false },
    enabled: { type: Boolean, value: true },
    axis: { type: String, value: 'horizontal' },
    iconSize: { type: Number, value: 24 },
    loop: { type: Boolean, value: false },
    speed: { type: Number, value: 1 },
    /**
     * [EN] Lottie JSON as an object (a data module), instead of `animationUrl`; each item plays its own copy.
     * [CN] 以对象形式提供的 Lottie JSON（数据模块），代替 `animationUrl`；每个条目播放自己的副本。
     */
    animationData: { type: Object, value: null },
    /**
     * [EN] The type of `animationUrl` ('lottie', 'pag', 'rive', 'svga', 'gif') when its extension does not say it (a file
     *      renamed to `.bin` for a code package); '' or an unknown type reads it from the extension.
     * [CN] 当扩展名无法说明时（为代码包改名为 `.bin` 的文件）`animationUrl` 的类型（'lottie'、'pag'、'rive'、'svga'、'gif'）；
     *      '' 或未知类型时根据扩展名判断。
     */
    animationType: { type: String, value: '' },
    /**
     * [EN] Inside a control that is itself the accessibility element and handles taps (a tag, a bar item): no padding,
     *      no 44 px minimum, hidden from accessibility, no gestures. The control keeps its own label and touch target.
     * [CN] 位于本身就是无障碍元素并处理点击的控件内（标签、栏目）：无内边距、无 44 px 最小高度、对无障碍隐藏、无手势。控件保留自己的标签与触控区域。
     */
    embedded: { type: Boolean, value: false },
    /**
     * [EN] Plays once when the file is ready (default, as before). false: rests until `playAnimation()`.
     * [CN] 文件就绪后播放一次（默认，与之前相同）。false：静止，直到调用 `playAnimation()`。
     */
    autoplay: { type: Boolean, value: true },
    /**
     * [EN] Whether a play-once animation (`loop` off) is replaced by the still image when it ends (iOS / Android
     *      `showsImageWhenAnimationEnds`): the engine is hidden and `selectedImage` / `image` (else the placeholder)
     *      shows. Off by default, so the last frame stays. `playAnimation()`, `stopAnimation()`, a new selection, a new
     *      file or turning `loop` on shows the animation again. The end is the engine's `complete` (Lottie, PAG, Rive,
     *      SVGA) or the end of a timed GIF pass (with stills); `animationcomplete` and its alias `animationend` are sent either way.
     * [CN] 只播放一次的动画（`loop` 关闭）结束时是否换成静态图片（iOS / Android 的 `showsImageWhenAnimationEnds`）：隐藏引擎，显示
     *      `selectedImage` / `image`（没有时为占位图）。默认关闭，保留最后一帧。`playAnimation()`、`stopAnimation()`、重新选中、新文件或开启
     *      `loop` 时重新显示动画。结束来自引擎的 `complete`（Lottie、PAG、Rive、SVGA）或有静帧的 GIF 一遍计时结束；两种情况都发送 `animationcomplete` 与别名 `animationend`。
     */
    showsImageWhenAnimationEnds: { type: Boolean, value: false },
    /**
     * [EN] Whether the item applies the default playback rules (HarmonyOS `drivesAnimationPlayback`, default true): selected plays
     *      once from the start, unselected rests, `restartToken` plays again, `autoplay` plays on ready. false: the host drives
     *      playback itself (resting progress, Play all) through `cylAnimatedItemPlayer()`; the item only hands out the player and applies
     *      none of those rules (a selection change touches no engine, the engine never autoplays, `restartToken` is ignored).
     *      `playAnimation()`, `restartAnimation()` and `stopAnimation()` still do what they are called for. Set it when the
     *      item is created.
     * [CN] 条目是否应用默认播放规则（鸿蒙的 `drivesAnimationPlayback`，默认 true）：选中时从头播放一次，未选中时静止，`restartToken`
     *      再次播放，`autoplay` 在就绪时播放。false：宿主通过 `cylAnimatedItemPlayer()` 自行驱动播放（静止进度、全部播放）；条目只交出播放器，
     *      不应用上述任何规则（选中状态变化不触及引擎，引擎不自动播放，忽略 `restartToken`）。`playAnimation()`、`restartAnimation()`、
     *      `stopAnimation()` 仍按调用执行。请在创建条目时设置。
     */
    drivesAnimationPlayback: { type: Boolean, value: true },
    /**
     * [EN] A number that plays the animation again from the start each time it grows (HarmonyOS `animationRestartToken`), next
     *      to `restartAnimation()`. The value at creation is not a restart; a lower value is not one either. Ignored while
     *      `drivesAnimationPlayback` is false.
     * [CN] 每次增大时从头再次播放动画的数字（鸿蒙的 `animationRestartToken`），与 `restartAnimation()` 并列。创建时的值不算重播；
     *      变小也不算。`drivesAnimationPlayback` 为 false 时忽略。
     */
    restartToken: { type: Number, value: 0 },
    /**
     * [EN] Alias of `restartToken` under the HarmonyOS name: the same behavior; growth of either one restarts the animation.
     * [CN] `restartToken` 的别名（鸿蒙的名称）：行为相同；任何一个增大都会重播。
     */
    animationRestartToken: { type: Number, value: 0 },
    /**
     * [EN] The frame (0...1) shown at rest while not selected (iOS `animationRestingProgress`); selected shows the last.
     * [CN] 未选中时静止显示的帧（0...1，iOS 的 `animationRestingProgress`）；选中时显示最后一帧。
     */
    restingProgress: { type: Number, value: 0 },
    /**
     * [EN] GIF stills (PNG): the first and last frames shown at rest; with them a GIF plays one pass (`gifDuration` ms)
     *      on `playAnimation()`, or until `loop` is turned off. Without them a GIF always plays, as before.
     * [CN] GIF 静帧（PNG）：静止时显示的第一帧与最后一帧；有静帧时 `playAnimation()` 播放一遍（`gifDuration` 毫秒），或循环直到关闭
     *      `loop`。没有静帧时 GIF 一直播放（与之前相同）。
     */
    gifFirstFrame: { type: String, value: '' },
    gifLastFrame: { type: String, value: '' },
    gifDuration: { type: Number, value: 1000 },
    /**
     * [EN] Where cyl-rive and cyl-pag load their WebAssembly from (their `wasm-path`); '' keeps the engine's default.
     * [CN] cyl-rive 与 cyl-pag 加载 WebAssembly 的位置（其 `wasm-path`）；'' 使用引擎的默认路径。
     */
    riveWasmPath: { type: String, value: '' },
    pagWasmPath: { type: String, value: '' },
    accessoryImage: { type: String, value: '' },
    accessoryText: { type: String, value: '' },
    accessoryAccessibilityLabel: { type: String, value: '' },
    accessoryPlacement: { type: String, value: 'trailing' },
    dragEnabled: { type: Boolean, value: false },
    accessibilityLabel: { type: String, value: '' },
    // [EN] The item's badge, the iOS names: `badgeValue` null (the default) no badge, '' a dot, otherwise the text; `badgeAttributes`
    //      the style keys of iOS' `CYLBadgeAttributeKey`; `reservesBadgeSpace` reserves the badge's overhang when measuring;
    //      `badgeAccessibilityLabel` the localized description read after the label. See cyl-badge/cyl_badge_model.js.
    // [CN] item 的角标，使用 iOS 的名称：`badgeValue` 为 null（默认）无角标、'' 红点，其余为文字；`badgeAttributes` 为 iOS `CYLBadgeAttributeKey` 的样式键；
    //      `reservesBadgeSpace` 在测量时预留角标伸出的部分；`badgeAccessibilityLabel` 为在标签之后朗读的本地化描述。见 cyl-badge/cyl_badge_model.js。
    badgeValue: { type: null, value: null },
    badgeAttributes: { type: Object, value: null },
    reservesBadgeSpace: { type: Boolean, value: false },
    badgeAccessibilityLabel: { type: String, value: '' },
    // [EN] For a host that draws the icon with this component (the tab bar item): Lottie / Rive colors (keypath -> color),
    //      autoplay, a tint for the static image, a non-square icon, the embedded layout and hiding it from screen
    //      readers (the host is the accessibility element). [CN] 供用本组件绘制图标的宿主（TabBar Item）使用：Lottie / Rive
    //      颜色（keypath -> 颜色）、自动播放、静态图片着色、非正方形图标、嵌入式布局，以及对读屏隐藏（宿主是无障碍元素）。
    // [EN] `animationType` and `autoplay` are declared above ("*.svga.bin" is read as SVGA).
    // [CN] `animationType` 与 `autoplay` 已在上方声明（"*.svga.bin" 读作 SVGA）。
    colors: { type: Object, value: null },
    iconTint: { type: String, value: '' },
    /**
     * [EN] The tint of `selectedImage` while selected. Not set (the default): `iconTint` for both. With both images set, each
     *      is its own layer and a selection change only toggles their opacity (no node re-created, no `src` change).
     * [CN] 选中时 `selectedImage` 的着色。未设置（默认）：两者都用 `iconTint`。两张图片都设置时各自为一个图层，选中变化只切换
     *      它们的不透明度（不重建节点，不改变 `src`）。
     */
    selectedIconTint: { type: String, value: null, optionalTypes: [Object] },
    /**
     * [EN] One color for the animation, like a template image (the same names and values as Rive's `tint`): '' (default) keeps the
     *      file's colors; "title" draws it in the item's icon color (the selected state's icon color when selected); "#RRGGBB" /
     *      "#RRGGBBAA" is a fixed color (the selected item takes its selected icon color when it has one). A set value overrides the same
     *      option of the animation source. Rive (canvas fill) and GIF (CSS filter) are recolored; Lottie, PAG and SVGA keep their
     *      colors. See `cylAnimatedItemAnimationTint`.
     * [CN] 动画使用的一种颜色，如同模板图片（名称与取值同 Rive 的 `tint`）：'' （默认）保持文件的颜色；"title" 用条目的图标颜色绘制（选中时用选中
     *      状态的图标颜色）；"#RRGGBB" / "#RRGGBBAA" 是固定颜色（选中条目有选中图标颜色时用它）。已设置的值覆盖动画来源中的同名选项。
     *      Rive（canvas 填充）与 GIF（CSS filter）会改色；Lottie、PAG、SVGA 保持自身颜色。见 `cylAnimatedItemAnimationTint`。
     */
    animationTint: { type: String, value: '' },
    /**
     * [EN] The dark-mode color of a fixed `animationTint` (a color; not needed for "title"), used while the item is dark.
     * [CN] 固定 `animationTint` 的深色模式颜色（颜色；"title" 不需要），条目为深色时使用。
     */
    animationDarkTint: { type: String, value: '' },
    /**
     * [EN] The icon colors `animationTint` follows, when they differ from the static image's `iconTint` / `selectedIconTint` (a tab bar
     *      item passes its title colors): '' (default) means `iconTint` / `selectedIconTint`. They never tint the static image.
     * [CN] `animationTint` 所跟随的图标颜色，与静态图片的 `iconTint` / `selectedIconTint` 不同时使用（TabBar 项传入其标题颜色）：
     *      '' （默认）表示用 `iconTint` / `selectedIconTint`。它们不会给静态图片着色。
     */
    animationIconTint: { type: String, value: '' },
    // [EN] INTERNAL, not API: cyl-animated-item-stack switches its built-in divider on through these (the item then draws only the line). [CN] 内部使用，不是 API：cyl-animated-item-stack 通过它们开启其内置分割线（此时条目只画那条线）。
    cylInternalDivider: { type: Boolean, value: false },
    cylDividerColor: { type: String, value: '' },
    cylDividerLength: { type: Number, value: 20 },
    cylDividerVertical: { type: Boolean, value: true },
    animationSelectedIconTint: { type: String, value: '' },
    /**
     * [EN] The rendering mode of the animation when `animationTint` is NOT set (also the URL option `renderingMode=`): 'automatic' (default, also '')
     *      tints with the effective icon color only a file detected as ONE color (here only a GIF; Rive, Lottie, PAG and SVGA are undetectable, and
     *      Lottie, PAG and SVGA cannot be recolored in a mini program at all); 'alwaysTemplate' tints (Rive and GIF) with the effective icon
     *      color; 'alwaysOriginal' never tints. An explicit `animationTint` always wins.
     * [CN] 未设置 `animationTint` 时动画的渲染模式（也可用 URL 选项 `renderingMode=`）：'automatic'（默认，也可为 ''）仅当文件被检测为「单色」时用有效图标
     *      颜色着色（这里只有 GIF；Rive、Lottie、PAG、SVGA 无法检测，而 Lottie、PAG、SVGA 在小程序里根本无法改色）；'alwaysTemplate' 用有效图标颜色给
     *      Rive 与 GIF 着色；'alwaysOriginal' 从不着色。显式的 `animationTint` 始终优先。
     */
    animationRenderingMode: { type: String, value: '' },
    /**
     * [EN] The built-in SELECTED color (icon, title, rendering-mode tint) when no explicit selected color exists: the host's default selected color (the
     *      stack passes its own, the tab bar its default); '' (default) is systemBlue 0,136,255 (dark 0,145,255). The normal built-in is label.
     * [CN] 没有显式选中颜色时的内置「选中」颜色（图标、标题、渲染模式着色）：宿主的默认选中色（堆叠传入自己的，TabBar 传入其默认值）；'' （默认）为
     *      systemBlue 0,136,255（深色 0,145,255）。普通状态的内置色为 label。
     */
    builtInSelectedColor: { type: String, value: '' },
    /**
     * [EN] SUBCLASS-EXPLICIT colors per state (the iOS `setSubclassTitleColor(_:for:)` / `setSubclassIconColor(_:for:)` channel; '' = none): a host built on this item
     *      (a cyl-tag-list tag) hands its per-state colors here WITHOUT touching the integrator's own `titleColor` / `iconTint` or the stack-inherited ones. They count as
     *      EXPLICIT (adapted on drawn dark glass: title 4.5, icon and animation tint 3) and are never written into the public properties. A missing selected value falls
     *      back to the normal one. Precedence (one function for the title, one for the icon, see `cylAnimatedItemResolvedTitleColor` / `cylAnimatedItemResolvedIconColor`): own
     *      `titleColor` / `iconTint` > subclass-explicit of the state > stack-inherited > subclass built-in > component built-in. A static image is tinted by the explicit levels only (tint spec v2).
     * [CN] 按状态的「子类显式」颜色（iOS 的 `setSubclassTitleColor(_:for:)` / `setSubclassIconColor(_:for:)` 通道；'' 为无）：基于本条目的宿主（cyl-tag-list 的标签）把每个状态的颜色
     *      交到这里，「不触碰」集成方自己的 `titleColor` / `iconTint` 与堆叠继承的颜色。它们算「显式」颜色（在绘制的深色玻璃上适配：标题 4.5，图标与动画着色 3），且绝不写入公开属性。
     *      缺少选中值时回退到常态值。优先级（标题一个函数、图标一个函数，见 `cylAnimatedItemResolvedTitleColor` / `cylAnimatedItemResolvedIconColor`）：自己的 `titleColor` / `iconTint` >
     *      该状态的子类显式 > 堆叠继承 > 子类内置 > 组件内置。静态图片只由显式层着色（着色规范 v2）。
     */
    subclassTitleColor: { type: String, value: '' },
    subclassSelectedTitleColor: { type: String, value: '' },
    subclassDisabledTitleColor: { type: String, value: '' },
    subclassIconColor: { type: String, value: '' },
    subclassSelectedIconColor: { type: String, value: '' },
    subclassDisabledIconColor: { type: String, value: '' },
    /**
     * [EN] SUBCLASS BUILT-IN colors per state (the twin of iOS `applyTitleTintColor(_:)` / `applyIconTintColor(_:)`; '' = none): the host's effective color of each state when it
     *      has no explicit one. Adapted on drawn dark glass like the explicit levels (normal and selected; NOT the disabled look), as the iOS doc says (the message that said
     *      "not adapted" is superseded). They tint no static image (built-in), but are the icon color of `animationTint: 'title'` and the rendering modes.
     * [CN] 按状态的「子类内置」颜色（iOS `applyTitleTintColor(_:)` / `applyIconTintColor(_:)` 的对应；'' 为无）：宿主在没有显式颜色时各状态的有效颜色。与显式层一样在绘制的深色玻璃上适配
     *      （常态与选中；「不」含禁用外观），依据 iOS 文档（说「不适配」的消息已被取代）。它们不给静态图片着色（内置），但是 `animationTint: 'title'` 与渲染模式所用的图标颜色。
     */
    builtInTitleColor: { type: String, value: '' },
    builtInSelectedTitleColor: { type: String, value: '' },
    builtInDisabledTitleColor: { type: String, value: '' },
    builtInIconColor: { type: String, value: '' },
    builtInSelectedIconColor: { type: String, value: '' },
    builtInDisabledIconColor: { type: String, value: '' },
    // [EN] INTERNAL: the stack-inherited level for a host that passes the stack's colors apart from the item's own (cyl-animated-item-stack still merges them into `titleColor` / `iconTint`, i.e. the own level). [CN] 内部使用：供把堆叠的颜色与条目自己的分开传入的宿主使用的「堆叠继承」层（cyl-animated-item-stack 仍把它们合并进 `titleColor` / `iconTint`，即自己的层）。
    inheritedTitleColor: { type: String, value: '' },
    inheritedIconTint: { type: String, value: '' },
    inheritedSelectedIconTint: { type: String, value: '' },
    /**
     * [EN] The background color while the item is pressed and enabled (iOS `itemHighlightedBackgroundColor`); '' (default) = none. A finger down / up (or a cancelled touch) toggles it.
     * [CN] 条目被按下且可用时的背景色（iOS 的 `itemHighlightedBackgroundColor`）；'' （默认）为无。手指按下 / 抬起（或触摸取消）时切换。
     */
    itemHighlightedBackgroundColor: { type: String, value: '' },
    /**
     * [EN] The alpha (0...1) of the animation (engine, GIF) while the item is disabled (iOS `itemDisabledAnimationAlpha`); -1 (default) = not set = 1. The static image is not changed.
     * [CN] 条目禁用时动画（引擎、GIF）的透明度（0...1，iOS 的 `itemDisabledAnimationAlpha`）；-1（默认）为未设置，即 1。静态图片不变。
     */
    itemDisabledAnimationAlpha: { type: Number, value: -1 },
    /**
     * [EN] A selected HOST-DRIVEN item (`drivesAnimationPlayback` false) rests on the last frame (iOS `showsLastFrameWhenSelected`); default off. With the default rules a selected item
     *      always rests on its last frame already.
     * [CN] 被选中的「宿主驱动」条目（`drivesAnimationPlayback` 为 false）停在最后一帧（iOS 的 `showsLastFrameWhenSelected`）；默认关闭。默认规则下选中的条目本来就停在最后一帧。
     */
    showsLastFrameWhenSelected: { type: Boolean, value: false },
    /**
     * [EN] Disabled wins the image (iOS `disabledWinsImage`): `selectedImage` shows only when selected AND enabled; default off.
     * [CN] 禁用优先于图片（iOS 的 `disabledWinsImage`）：`selectedImage` 仅在选中且可用时显示；默认关闭。
     */
    disabledWinsImage: { type: Boolean, value: false },
    // [EN] iOS `showsOutlineWhenIncreaseContrast` / `respectsReduceMotion` (default false), kept for API parity so a host can turn them on. No effect in a mini
    //      program: the base library exposes no Increase Contrast or Reduce Motion setting. [CN] iOS 的 `showsOutlineWhenIncreaseContrast` / `respectsReduceMotion`
    //      （默认 false），为 API 一致性保留，宿主可以打开。在小程序中不起作用：基础库没有提供「增强对比度」或「减弱动态效果」设置。
    showsOutlineWhenIncreaseContrast: { type: Boolean, value: false },
    respectsReduceMotion: { type: Boolean, value: false },
    /**
     * [EN] The title's color (any CSS color); '' keeps the inherited color.
     * [CN] 标题颜色（任意 CSS 颜色）；'' 时沿用继承的颜色。
     */
    titleColor: { type: String, value: '' },
    /**
     * [EN] The title's font size in px; 0 keeps the default 14 px.
     * [CN] 标题字号（px）；0 时为默认的 14 px。
     */
    titleFontSize: { type: Number, value: 0 },
    /**
     * [EN] The title's font weight: 'normal', 'bold', 'bolder', 'lighter' or 100–900 (string or number); '' keeps the
     *      default.
     * [CN] 标题字重：'normal'、'bold'、'bolder'、'lighter' 或 100–900（字符串或数字）；'' 时保持默认。
     */
    titleFontWeight: { type: String, optionalTypes: [Number], value: '' },
    /**
     * [EN] The title's color in dark mode (any CSS color); '' keeps `titleColor`. Dark follows `userInterfaceStyle`.
     * [CN] 深色模式下的标题颜色（任意 CSS 颜色）；'' 时沿用 `titleColor`。是否深色由 `userInterfaceStyle` 决定。
     */
    titleDarkColor: { type: String, value: '' },
    /**
     * [EN] 'system' (default) follows the system theme (needs `"darkmode": true` in app.json); 'light' or 'dark' forces it.
     * [CN] 'system'（默认）跟随系统主题（需在 app.json 中设置 `"darkmode": true`）；'light' 或 'dark' 时强制。
     */
    userInterfaceStyle: { type: String, value: 'system' },
    /**
     * [EN] The title's line count: 1 one line with an ellipsis (default), 0 no limit, n > 1 up to n lines, then an ellipsis.
     * [CN] 标题行数：1 为单行省略（默认），0 为不限，n > 1 为最多 n 行后省略。
     */
    titleLines: { type: Number, value: 1 },
    /**
     * [EN] The title's line height in px; 0 keeps the default.
     * [CN] 标题行高（px）；0 时为默认值。
     */
    titleLineHeight: { type: Number, value: 0 },
    /**
     * [EN] The gap between the icon and the title in px (below the icon when vertical, beside it when horizontal); -1
     *      keeps the default 2 px (vertical) / 4 px (horizontal).
     * [CN] 图标与标题的间距（px；纵向在图标下方，横向在图标旁）；-1 为默认的 2 px（纵向）/ 4 px（横向）。
     */
    titleSpacing: { type: Number, value: -1 },
    /**
     * [EN] 'plain' (default) or 'countdown': a countdown button, e.g. "Get code" of an SMS login (`itemStyle`, the same name
     *      as on iOS, Android and HarmonyOS; `style` is the host's own attribute). Set the `countdown…` properties, then call
     *      `startCountdown()` (or set `startsCountdownOnTap`). The end is a time read from the local clock, so the seconds in the
     *      background count (FIX: issue #1 of SMSCodeButton); a clock past the longest duration, or set back to before the start,
     *      closes it; `countdownCacheKey` keeps it across a restart. While it runs the item is disabled. Events: `countdownstart`,
     *      `countdowntick` (`detail.seconds`, once per second), `countdownfinish`.
     * [CN] 'plain'（默认）或 'countdown'：倒计时按钮，例如短信登录的「获取验证码」（`itemStyle`，与 iOS、Android、HarmonyOS
     *      同名；`style` 是宿主自己的属性）。设置 `countdown…` 属性后调用 `startCountdown()`（或设置 `startsCountdownOnTap`）。结束是从本地时钟读取的时间点，
     *      因此后台的秒数计入（修复 SMSCodeButton 的 issue #1）；时钟超过最长时长或被调回到开始之前时关闭；`countdownCacheKey` 使其在重启后继续。
     *      倒计时中条目不可用。事件：`countdownstart`、`countdowntick`（`detail.seconds`，每秒一次）、`countdownfinish`。
     */
    itemStyle: { type: String, value: 'plain' },
    countdownDuration: { type: Number, value: 60 },
    countdownIdleTitle: { type: String, value: 'Get code' },
    countdownRunningTitleFormat: { type: String, value: '%ld s left' },
    countdownFinishedTitle: { type: String, value: 'Resend' },
    countdownImage: { type: String, value: '' },
    countdownRunningTitleColor: { type: String, value: '#999999' },
    startsCountdownOnTap: { type: Boolean, value: false },
    countdownCacheKey: { type: String, value: '' },
    iconWidth: { type: Number, value: 0 },
    iconHeight: { type: Number, value: 0 },
    bare: { type: Boolean, value: false },
    accessibilityHidden: { type: Boolean, value: false },
    // [EN] The role a screen reader announces: "button" (default) or "text" (a container's hint that takes no taps, e.g.
    //      cyl-animated-item-stack). [CN] 读屏朗读的角色："button"（默认）或 "text"（容器中不接收点击的提示，例如 cyl-animated-item-stack）。
    accessibilityRole: { type: String, value: 'button' },
  },

  data: {
    itemBackgroundCss: '',
    itemGlassDrawn: false,
    // [EN] The same rule as `itemGlassDrawn` under the iOS names (`drawsLiquidGlass` / `drawsFlatBackground`), for the template or a host to read. [CN] 与 `itemGlassDrawn` 同一规则，使用 iOS 的名称（`drawsLiquidGlass` / `drawsFlatBackground`），供模板或宿主读取。
    itemDrawsLiquidGlass: false,
    itemDrawsFlatBackground: true,
    itemPressed: false,
    animationLoaded: false,
    animationFailed: false,
    gifPlaying: false,
    gifImageReady: false,
    gifImagePlaying: false,
    animationEnded: false,
    animationColorKind: '',
    hostRestingProgress: 0,
    lottieData: null,
    m: {},
    systemTheme: 'light',
    countdownState: 'idle',
    countdownSeconds: 0,
  },

  observers: {
    'itemBackgroundStyle, itemBackgroundColor, itemCornerRadius, itemBorderWidth, itemBorderColor, itemGlassTintAlpha, itemContentHorizontalInset, userInterfaceStyle, itemHighlightedBackgroundColor, enabled': function () {
      this.cylRefreshBackground()
      // [EN] The colors are judged against the glass: a changed glass changes them. [CN] 颜色是对照玻璃判断的：玻璃变化，颜色也变化。
      this.cylUpdate()
    },
    'animationUrl, animationData, animationType': function (animationUrl, animationData, animationType) {
      // [EN] A host re-renders and sets the same file (or the same Lottie data object) again: keep the loaded / failed
      //      state, because the engine view (cyl-lottie reloads only when its inputs change) does not load again and sends
      //      no new `ready`; resetting here left the static image over a playing animation.
      // [CN] 宿主重新渲染时会再次设置同一个文件（或同一个 Lottie 数据对象）：保留已加载 / 失败状态，因为引擎视图（cyl-lottie
      //      只在输入变化时重新加载）不会再次加载、也不会再发 `ready`；在这里重置会让静态图片盖住正在播放的动画。
      const key = `${animationUrl || ''}|${animationType || ''}`
      // [EN] The same file after a failure is a retry (the network is back): reset so the engine view may load it again.
      // [CN] 失败后再次设置同一个文件即为重试（例如网络恢复）：重置，让引擎视图可以再次加载。
      if (key === this.cylAnimationKey && animationData === this.cylAnimationData && !this.data.animationFailed) {
        return
      }
      this.cylAnimationKey = key
      this.cylAnimationData = animationData
      clearTimeout(this.cylGifTimer)
      this.cylPendingPlay = false
      this.cylIsPlaying = false
      // cyl-lottie keeps the data it gets and changes it while playing: every item gets its own copy.
      const lottieData = animationData && typeof animationData === 'object' ? JSON.parse(JSON.stringify(animationData)) : null // NOSONAR: `structuredClone` is not in every mini program runtime
      this.setData({ animationLoaded: false, animationFailed: false, gifPlaying: false, animationEnded: false, lottieData })
      this.cylUpdate()
      // [EN] A file of no known type has no engine to report anything: it cannot be decoded. [CN] 不属于任何已知类型的文件没有引擎可以报告：无法解码。
      if (animationUrl && this.data.m && !this.data.m.animationType) this.cylReportResourceMissing('decode failed')
    },
    'badgeValue, badgeAttributes, reservesBadgeSpace, badgeAccessibilityLabel, title, image, selectedImage, placeholderImage, embedded, enabled, axis, iconSize, accessoryImage, accessoryText, accessoryAccessibilityLabel, accessoryPlacement, accessibilityLabel, gifFirstFrame, gifLastFrame, iconWidth, iconHeight, iconTint, selectedIconTint, animationTint, animationDarkTint, animationIconTint, animationSelectedIconTint, animationRenderingMode, builtInSelectedColor, animationColorKind, titleColor, titleFontSize, titleFontWeight, titleDarkColor, userInterfaceStyle, titleLines, titleLineHeight, titleSpacing, cylInternalDivider, cylDividerColor, cylDividerLength, cylDividerVertical': function () {
      this.cylUpdate()
    },
    // [EN] The subclass, inherited and built-in color levels and the options that change the model. [CN] 子类、继承与内置颜色层级，以及改变模型的选项。
    'subclassTitleColor, subclassSelectedTitleColor, subclassDisabledTitleColor, subclassIconColor, subclassSelectedIconColor, subclassDisabledIconColor, builtInTitleColor, builtInSelectedTitleColor, builtInDisabledTitleColor, builtInIconColor, builtInSelectedIconColor, builtInDisabledIconColor, inheritedTitleColor, inheritedIconTint, inheritedSelectedIconTint, itemDisabledAnimationAlpha, disabledWinsImage': function () {
      this.cylUpdate()
    },
    'itemStyle, countdownIdleTitle, countdownRunningTitleFormat, countdownFinishedTitle, countdownImage, countdownRunningTitleColor, countdownDuration': function (itemStyle) {
      if (itemStyle !== 'countdown' && this.cylCountdown && this.data.countdownState !== 'idle') this.resetCountdown()
      this.cylUpdate()
    },
    'countdownCacheKey, itemStyle': function (key, itemStyle) {
      if (itemStyle === 'countdown') this.cylAnimatedItemCountdown().setCacheKey(key)
    },
    'showsImageWhenAnimationEnds': function (shows) {
      if (!shows) this.cylShowAnimationAgain()
    },
    'restartToken, animationRestartToken': function (token, aliasToken) {
      // [EN] The value at creation is the baseline of each (set in `attached`); only a larger one restarts (either of the two), and a
      //      host that drives the player itself is not restarted (HarmonyOS: the restart is one of the default rules).
      // [CN] 创建时的值是各自的基准（在 `attached` 中设置）；只有更大的值才重播（两者任一），自行驱动播放器的宿主不会被重播
      //      （鸿蒙：重播属于默认规则）。
      const last = this.cylRestartToken
      const lastAlias = this.cylAnimationRestartToken
      this.cylRestartToken = token
      this.cylAnimationRestartToken = aliasToken
      if (last === undefined || !this.data.drivesAnimationPlayback) return
      if (Number(token) > Number(last) || Number(aliasToken) > Number(lastAlias)) this.restartAnimation()
    },
    'selected, restingProgress, showsLastFrameWhenSelected': function () {
      // [EN] Host-driven: the host rests and plays through the player; only the drawing follows `selected`. [CN] 宿主驱动：宿主通过播放器静止与播放；只有绘制随 `selected` 变化。
      if (!this.data.drivesAnimationPlayback) {
        this.cylUpdate()
        return
      }
      this.cylShowAnimationAgain()
      this.cylUpdate()
      if (!this.data.autoplay || this.data.gifFirstFrame || this.data.gifLastFrame) {
        // [EN] No longer selected: stop the engine (and any play still waiting for it) before showing the resting frame, so
        //      two tabs never look selected (the iOS contract: a switch stops and resets the other tabs).
        // [CN] 不再被选中：先停止引擎（以及仍在等待它的播放），再显示静止帧，避免两个 Tab 同时看起来是选中的（iOS 约定：切换时停止并重置其他 Tab）。
        if (!this.data.selected) this.cylHalt()
        this.cylRest()
      }
      // [EN] Another tab is selected: a playing GIF image rests. [CN] 选中了其他 Tab：正在播放的 GIF 图片回到静止。
      if (!this.data.selected && this.data.gifImagePlaying) this.cylRestGIFImage()
    },
    'loop': function () {
      if (this.data.loop && this.data.drivesAnimationPlayback) this.cylShowAnimationAgain()
      // [EN] A GIF image: off lets the pass in progress end, on keeps it playing. [CN] GIF 图片：关闭时让当前一遍播完，开启时一直播放。
      if (this.data.gifImagePlaying) {
        clearTimeout(this.cylGIFImageTimer)
        if (!this.data.loop) this.cylScheduleGIFImageEnd()
      }
      // Engines take `loop` live; a GIF with stills is timed here: off lets the pass in progress end, on keeps it playing.
      if (!this.data.gifPlaying) return
      clearTimeout(this.cylGifTimer)
      if (!this.data.loop) this.cylScheduleGifEnd()
    },
  },

  lifetimes: {
    attached() {
      this.cylLifecycle = new LifecycleController(this)
      this.cylLifecycle.registry.addDeallocCallback(cylTeardown, { key: 'cyl.animatedItem.teardown' })
      this.cylLifecycle.onLoad()
      // [EN] The item's own screen events (`didEnterScreen` / `didLeaveScreen`) from a `wx.createIntersectionObserver`; stopped when it detaches.
      // [CN] 条目自己的屏幕事件（`didEnterScreen` / `didLeaveScreen`）来自 `wx.createIntersectionObserver`；detached 时停止。
      const stopObservingScreen = this.cylLifecycle.observeScreen('.cyl-animated-item')
      this.cylLifecycle.registry.addDeallocCallback(() => stopObservingScreen(), { key: 'cyl.animatedItem.screenObserver' })
      // [EN] The system theme, kept current while attached. [CN] 系统主题，挂载期间保持最新。
      let theme = 'light'
      try {
        const info = typeof wx.getAppBaseInfo === 'function' ? wx.getAppBaseInfo() : wx.getSystemInfoSync()
        theme = info.theme === 'dark' ? 'dark' : 'light'
      } catch {
        theme = 'light'
      }
      this.data.systemTheme = theme
      this.cylRefreshBackground()
      this.cylThemeListener = (result) => {
        this.data.systemTheme = result?.theme === 'dark' ? 'dark' : 'light'
        this.cylRefreshBackground()
        this.cylUpdate()
      }
      if (typeof wx !== 'undefined' && typeof wx.onThemeChange === 'function') wx.onThemeChange(this.cylThemeListener)
      // [EN] A countdown kept before a restart continues. [CN] 重启之前保存的倒计时继续。
      if (this.data.itemStyle === 'countdown') this.cylAnimatedItemCountdown().setCacheKey(this.data.countdownCacheKey)
      this.cylRestartToken = this.data.restartToken
      this.cylAnimationRestartToken = this.data.animationRestartToken
      this.cylUpdate()
    },
    detached() {
      // [EN] Runs the teardown block; a component that never attached has no controller and is released directly. [CN] 运行销毁块；从未 attached 的组件没有控制器，直接释放。
      if (this.cylLifecycle) this.cylLifecycle.onUnload()
      else cylTeardown(this)
    },
  },

  methods: {
    /**
     * [EN] Builds the background (flat or drawn Liquid Glass) for the current inputs and mode: the default frosted tint of dark mode is white at 0.04, of
     *      light mode (225, 222, 220) at 0.10. Called by the observer and again when the system theme changes (`userInterfaceStyle` `system`).
     * [CN] 按当前输入与模式构建背景（扁平或绘制的液态玻璃）：深色模式的默认磨砂着色是透明度 0.04 的白色，浅色模式是透明度 0.10 的 (225, 222, 220)。由 observer 调用，
     *      系统主题变化时（`userInterfaceStyle` 为 `system`）再次调用。
     */
    cylRefreshBackground() {
      const d = this.data
      const dark = cylAnimatedItemIsDark({ userInterfaceStyle: d.userInterfaceStyle, systemTheme: d.systemTheme })
      const background = cylAnimatedItemBackground(d.itemBackgroundStyle, d.itemBackgroundColor, d.itemCornerRadius, d.itemBorderWidth, d.itemBorderColor, dark, d.itemGlassTintAlpha, d.itemContentHorizontalInset)
      const drawsLiquidGlass = cylAnimatedItemDrawsLiquidGlass(d)
      // [EN] The pressed background (`itemHighlightedBackgroundColor`, while pressed and enabled) replaces the tint. [CN] 按下背景（`itemHighlightedBackgroundColor`，按下且可用时）取代着色。
      const highlight = d.itemPressed && d.enabled !== false ? cylAnimatedItemTintColor(d.itemHighlightedBackgroundColor) : ''
      this.setData({
        itemBackgroundCss: background.css + (highlight ? `background-color:${highlight};` : ''),
        itemGlassDrawn: background.glass,
        itemDrawsLiquidGlass: drawsLiquidGlass,
        itemDrawsFlatBackground: !drawsLiquidGlass,
      })
    },

    /**
     * [EN] The item's own dark-glass rule as a public function (iOS `adaptedOnGlass(_:kind:)`): `color` as it must be drawn for this item's glass state, theme, background
     *      colour and tint alpha; `kind` 'icon' (minimum 3) or 'title' (minimum 4.5, 'text' too). Unchanged unless dark Liquid Glass is drawn.
     * [CN] 条目自己的深色玻璃规则，公开为函数（iOS 的 `adaptedOnGlass(_:kind:)`）：`color` 对本条目的玻璃状态、主题、背景色与着色透明度实际应绘制的颜色；
     *      `kind` 为 'icon'（最低 3）或 'title'（最低 4.5，'text' 亦可）。除非绘制深色液态玻璃，否则原样返回。
     */
    adaptedOnGlass(color, kind) {
      return cylAnimatedItemAdaptedColor(color, kind, this.data)
    },

    /** [EN] Whether the engine of `type` (default: this item's type) can draw (iOS `isAnimationEngineAvailable`). [CN] `type`（默认为本条目的类型）的引擎是否可绘制（iOS 的 `isAnimationEngineAvailable`）。 */
    cylIsAnimationEngineAvailable(type) {
      return cylAnimatedItemIsAnimationEngineAvailable(type || this.data.m?.animationType, cylWarnedTypes)
    },

    /** [EN] Pressed look on / off for `itemHighlightedBackgroundColor`. [CN] `itemHighlightedBackgroundColor` 的按下外观开 / 关。 */
    cylSetPressed(pressed) {
      if (!this.data.itemHighlightedBackgroundColor || !!this.data.itemPressed === pressed) return
      this.setData({ itemPressed: pressed })
      this.cylRefreshBackground()
      // [EN] The pressed color is the flat fill the colors are judged against. [CN] 按下颜色是颜色所对照的扁平填充。
      this.cylUpdate()
    },

    cylOnTouchCancel() {
      this.cylSetPressed(false)
    },

    /**
     * [EN] The countdown state machine of this item, made on first use with the local clock and the mini program storage.
     * [CN] 本条目的倒计时状态机，首次使用时以本地时钟与小程序存储创建。
     */
    cylAnimatedItemCountdown() {
      if (this.cylCountdown) return this.cylCountdown
      const storage = typeof wx !== 'undefined' && typeof wx.getStorageSync === 'function' ? {
        get: (name) => { try { return wx.getStorageSync(name) } catch { return null } },
        set: (name, value) => { try { wx.setStorageSync(name, value) } catch { /* [EN] a full storage only loses the restart case. [CN] 存储已满只会丢失重启恢复。 */ } },
        remove: (name) => { try { wx.removeStorageSync(name) } catch { /* [EN] nothing to drop. [CN] 没有可丢弃的内容。 */ } },
      } : null
      const countdown = new CYLAnimatedItemCountdown({
        storage,
        onChange: () => {
          const running = countdown.state === 'running'
          this.setData({ countdownState: countdown.state, countdownSeconds: countdown.shown })
          if (running) this.cylStartCountdownTimer()
          else this.cylStopCountdownTimer()
          this.cylUpdate()
        },
        onStart: () => this.triggerEvent('countdownstart', {}),
        onTick: (seconds) => this.triggerEvent('countdowntick', { seconds }),
        onFinish: () => this.triggerEvent('countdownfinish', {}),
      })
      this.cylCountdown = countdown
      // [EN] The time spent in the background counts: read the clock when the mini program is shown again.
      // [CN] 后台度过的时间计入：小程序再次显示时读取时钟。
      this.cylAppShowListener = () => countdown.refresh()
      if (typeof wx !== 'undefined' && typeof wx.onAppShow === 'function') wx.onAppShow(this.cylAppShowListener)
      return countdown
    },

    cylStartCountdownTimer() {
      if (this.cylCountdownTimer) return
      this.cylCountdownTimer = setInterval(() => this.cylAnimatedItemCountdown().refresh(), CYL_COUNTDOWN_TICK_INTERVAL)
    },

    cylStopCountdownTimer() {
      clearInterval(this.cylCountdownTimer)
      this.cylCountdownTimer = null
    },

    /**
     * [EN] Starts (or restarts) the countdown for `seconds` (default `countdownDuration`, e.g. the server's "retry after").
     *      Switches the item to the countdown style when it is not. [CN] 开始（或重新开始）`seconds` 秒的倒计时（默认 `countdownDuration`，
     *      例如服务器返回的「多少秒后重试」）。条目不是倒计时样式时切换为倒计时样式。
     */
    startCountdown(seconds) {
      if (this.data.itemStyle !== 'countdown') {
        this.setData({ itemStyle: 'countdown' })
        this.cylAnimatedItemCountdown().setCacheKey(this.data.countdownCacheKey)
      }
      this.cylAnimatedItemCountdown().startFor(Number(seconds) > 0 ? Number(seconds) : this.data.countdownDuration)
    },

    /** [EN] Stops and goes idle, with no finish event. [CN] 停止并回到待机，不触发结束事件。 */
    resetCountdown() {
      this.cylAnimatedItemCountdown().reset()
    },

    /** [EN] Reads the clock now (done by the item itself). [CN] 立即读取时钟（条目自己会做）。 */
    refreshCountdown() {
      this.cylAnimatedItemCountdown().refresh()
    },

    cylUpdate() {
      const m = cylAnimatedItemModel({ ...this.data })
      this.setData({ m })
      this.cylDetectColorKind(m)
      if ((m.gifImage || '') !== (this.cylGIFImageSource || '')) this.cylLoadGIFImage(m.gifImage || '')
      else if (m.gifImage && this.cylGIFImageInfo && (m.iconTint || '') !== (this.cylGIFImageTint || '')) this.cylDrawGIFImageStill()
    },

    /**
     * [EN] One-color detection of a GIF ANIMATION (the only type this mini program tints without an explicit color; cached per URL): needed only
     *      with no explicit tint and a rendering mode that is not alwaysOriginal. Sets `animationColorKind` ('one' | 'multi' | 'unknown').
     * [CN] GIF「动画」的单色检测（本小程序在没有显式颜色时唯一会着色的类型；按 URL 缓存）：仅在没有显式着色且渲染模式不是 alwaysOriginal 时需要。设置 `animationColorKind`。
     */
    cylDetectColorKind(m) {
      const url = m.animationType === 'gif' ? m.animationPath : ''
      const wanted = url && cylAnimatedItemRenderingMode(this.data.animationRenderingMode, url) === 'automatic' && !String(this.data.animationTint || '').trim()
      const kind = wanted ? cylGIFColorKindCache[url] : ''
      if (kind !== undefined) {
        if ((this.data.animationColorKind || '') !== (kind || '')) this.setData({ animationColorKind: kind || '' }, () => this.cylUpdate())
        return
      }
      if (this.cylColorKindURL === url || typeof wx === 'undefined') return
      this.cylColorKindURL = url
      this.cylReadBytes(url, (buffer) => {
        const info = buffer ? cylGIFImageInfo(new Uint8Array(buffer)) : null
        cylGIFColorKindCache[url] = info ? cylGIFColorKind(info.frame, false) : 'unknown'
        this.cylDetectColorKind(this.data.m || m)
      })
    },

    /** [EN] Reads a package or local file, or an http(s) URL, as an ArrayBuffer (null on failure). [CN] 以 ArrayBuffer 读取代码包或本地文件或 http(s) 地址（失败为 null）。 */
    cylReadBytes(path, done) {
      if (/^https?:\/\//.test(path)) {
        wx.request({ url: path, responseType: 'arraybuffer', success: (result) => done(result.statusCode >= 200 && result.statusCode < 300 ? result.data : null), fail: () => done(null) })
        return
      }
      const fs = wx.getFileSystemManager()
      fs.readFile({ filePath: path, success: (result) => done(result.data), fail: () => {
        if (path.startsWith('/')) fs.readFile({ filePath: path.slice(1), success: (result) => done(result.data), fail: () => done(null) })
        else done(null)
      } })
    },

    /**
     * [EN] Reads and decodes a GIF image (a package or local file, or an http(s) URL), then draws its first frame.
     * [CN] 读取并解码 GIF 图片（代码包或本地文件，或 http(s) 地址），然后绘制其第一帧。
     */
    cylLoadGIFImage(path) {
      this.cylGIFImageSource = path
      this.cylGIFImageInfo = null
      clearTimeout(this.cylGIFImageTimer)
      if (this.data.gifImageReady || this.data.gifImagePlaying) this.setData({ gifImageReady: false, gifImagePlaying: false })
      if (!path || typeof wx === 'undefined') return
      const decoded = (buffer) => {
        if (this.cylGIFImageSource !== path || !buffer) return
        const info = cylGIFImageInfo(new Uint8Array(buffer))
        if (!info) return
        this.cylGIFImageInfo = info
        this.cylDrawGIFImageStill()
      }
      if (/^https?:\/\//.test(path)) {
        wx.request({ url: path, responseType: 'arraybuffer', success: (result) => {
          if (result.statusCode >= 200 && result.statusCode < 300) decoded(result.data)
        } })
        return
      }
      const fs = wx.getFileSystemManager()
      fs.readFile({ filePath: path, success: (result) => decoded(result.data), fail: () => {
        // [EN] A package path may also be read without its leading slash. [CN] 代码包路径也可以去掉开头的斜杠读取。
        if (path.startsWith('/')) fs.readFile({ filePath: path.slice(1), success: (result) => decoded(result.data) })
      } })
    },

    /** [EN] Draws the first frame of the GIF image, centered in a square canvas. [CN] 在正方形 canvas 中居中绘制 GIF 图片的第一帧。 */
    cylDrawGIFImageStill() {
      const info = this.cylGIFImageInfo
      if (!info) return
      this.createSelectorQuery().select('#cyl-gif-image-still').fields({ node: true }).exec((result) => {
        const canvas = result?.[0]?.node
        if (!canvas || this.cylGIFImageInfo !== info) return
        const side = Math.max(info.width, info.height)
        canvas.width = side
        canvas.height = side
        const context = canvas.getContext('2d')
        const pixels = context.createImageData(info.width, info.height)
        pixels.data.set(info.frame)
        context.clearRect(0, 0, side, side)
        context.putImageData(pixels, Math.floor((side - info.width) / 2), Math.floor((side - info.height) / 2))
        // [EN] A template image (`iconTint`): the still takes the tint as the <image> does. [CN] 模板图片（`iconTint`）：静帧与 <image> 一样着色。
        const tint = this.data.m?.iconTint
        if (tint) {
          context.globalCompositeOperation = 'source-in'
          context.fillStyle = tint
          context.fillRect(0, 0, side, side)
          context.globalCompositeOperation = 'source-over'
        }
        this.cylGIFImageTint = tint || ''
        this.setData({ gifImageReady: true })
        this.cylUpdate()
      })
    },

    /**
     * [EN] Plays the GIF image from its first frame: one pass, or until `loop` is turned off; then the still again.
     * [CN] 从第一帧播放 GIF 图片：播放一遍，或一直播放到关闭 `loop`；之后回到静帧。
     */
    cylPlayGIFImage() {
      clearTimeout(this.cylGIFImageTimer)
      this.cylGIFImageStartedAt = Date.now()
      // [EN] Setting the source again restarts the GIF from its first frame. [CN] 重新设置图片来源会让 GIF 从第一帧开始。
      this.setData({ gifImagePlaying: true, 'm.fallbackImage': '' }, () => {
        this.cylUpdate()
        if (!this.data.loop) this.cylScheduleGIFImageEnd()
      })
    },

    /** [EN] The end of the pass in progress, then the still. [CN] 当前一遍结束后显示静帧。 */
    cylScheduleGIFImageEnd() {
      const duration = this.cylGIFImageInfo?.duration || 1000
      const elapsed = Date.now() - (this.cylGIFImageStartedAt || Date.now())
      this.cylGIFImageTimer = setTimeout(() => {
        this.cylRestGIFImage()
        // [EN] A timed pass of a GIF image ended: the same as an engine's `complete`. [CN] GIF 图片的一遍计时结束：与引擎的 `complete` 相同。
        this.cylAnimationDidEnd()
        this.cylPlayDidEnd()
        this.cylEmitComplete({ type: 'gif' })
      }, duration - (elapsed % duration))
    },

    /** [EN] Back to the first-frame still. [CN] 回到第一帧静帧。 */
    cylRestGIFImage() {
      clearTimeout(this.cylGIFImageTimer)
      if (!this.data.gifImagePlaying) return
      // [EN] The canvas comes back empty: draw the still again. [CN] canvas 重新创建后为空：再次绘制静帧。
      this.setData({ gifImagePlaying: false }, () => this.cylDrawGIFImageStill())
      this.cylUpdate()
    },

    /** [EN] The engine component drew the file. [CN] 引擎组件已绘制该文件。 */
    cylOnAnimationReady(event) {
      this.setData({ animationLoaded: true })
      // [EN] Forwarded as `animationready` with the engine's detail (e.g. `duration`). [CN] 以 `animationready` 转发，带引擎的 detail（如 `duration`）。
      this.triggerEvent('animationready', event?.detail || {})
      this.cylUpdate()
      if (this.cylPendingPlay) {
        this.playAnimation()
      } else if (!this.data.autoplay && this.data.drivesAnimationPlayback) {
        this.cylRest()
      } else if (this.data.autoplay && this.data.drivesAnimationPlayback && this.data.m.usesEngine) {
        // [EN] The engine plays by itself on ready (`autoplay`). [CN] 引擎在就绪时自行播放（`autoplay`）。
        this.cylIsPlaying = true
      }
    },

    /**
     * [EN] Plays the animation from progress 0, once (or until `loop` is turned off): the engine's `cylPlayFromStart()`, or
     *      the GIF again from its first frame. A file still loading plays when it is ready. Play all calls this on every item.
     * [CN] 从进度 0 播放一次动画（或循环直到关闭 `loop`）：引擎的 `cylPlayFromStart()`，或从第一帧重新播放 GIF。仍在加载的文件在就绪后播放。
     *      “全部播放”对每个条目调用此方法。
     */
    playAnimation() {
      this.cylShowAnimationAgain()
      const m = this.data.m
      if (m.gifImage || m.usesEngine || (m.animationType === 'gif' && m.gifPath)) this.cylIsPlaying = true
      if (m.gifImage && this.cylGIFImageInfo) {
        this.cylPlayGIFImage()
        cylAnimationDidStart(this, { type: 'gifImage', loop: !!this.data.loop })
        return
      }
      if (m.animationType === 'gif' && m.gifPath) {
        this.cylPlayGif()
        cylAnimationDidStart(this, { type: 'gif', loop: !!this.data.loop })
        return
      }
      if (!m.usesEngine) return
      if (!this.data.animationLoaded) {
        this.cylPendingPlay = true
        return
      }
      this.cylPendingPlay = false
      const engine = this.selectComponent(CYL_ENGINE_ID)
      if (engine && typeof engine.cylPlayFromStart === 'function') {
        engine.cylPlayFromStart()
        cylAnimationDidStart(this, { type: m.animationType, loop: !!this.data.loop })
      }
    },

    /**
     * [EN] Pauses the playing animation on its current frame (`cyl.animation.didPause`); the engine's `cylPause`. A GIF has no pause and keeps
     *      playing. [CN] 把正在播放的动画暂停在当前帧（`cyl.animation.didPause`）；使用引擎的 `cylPause`。GIF 没有暂停，会继续播放。
     */
    pauseAnimation() {
      return cylPauseAnimation(this)
    },

    /** [EN] Continues an animation paused by `pauseAnimation()` (`cyl.animation.didResume`). [CN] 继续被 `pauseAnimation()` 暂停的动画（`cyl.animation.didResume`）。 */
    resumeAnimation() {
      return cylResumeAnimation(this)
    },

    /** [EN] The same as `playAnimation()` (iOS `restartAnimation`). [CN] 与 `playAnimation()` 相同（iOS 的 `restartAnimation`）。 */
    restartAnimation() {
      this.playAnimation()
    },

    /** [EN] Stops and shows the resting frame (iOS `stopAnimation`). [CN] 停止并显示静止帧（iOS 的 `stopAnimation`）。 */
    stopAnimation() {
      this.cylShowAnimationAgain()
      this.cylHalt()
      this.cylRest()
      cylAnimationDidStop(this, false)
    },

    /**
     * [EN] Cancels a play that waits for the file and stops the engine where it is (a seek alone, `cylSetProgress`, does not stop
     *      SVGA or PAG, and Rive has no seek), so the resting frame that follows is the last thing drawn.
     * [CN] 取消仍在等待文件的播放，并让引擎停在当前位置（单独的跳转 `cylSetProgress` 不会停止 SVGA 或 PAG，Rive 也没有跳转），
     *      这样随后显示的静止帧就是最后绘制的内容。
     */
    cylHalt() {
      this.cylPendingPlay = false
      this.cylIsPlaying = false
      clearTimeout(this.cylGifTimer)
      if (this.data.gifImagePlaying) this.cylRestGIFImage()
      if (!this.data.m.usesEngine || !this.data.animationLoaded) return
      const engine = this.selectComponent(CYL_ENGINE_ID)
      if (engine && typeof engine.cylPause === 'function') engine.cylPause()
    },

    /**
     * [EN] The resting frame: the last one while selected, else `restingProgress`. Lottie through `cylGoToAndStop`, PAG
     *      and SVGA through `cylSetProgress`, Rive through its `resting-frame` (first / last), GIF through its stills.
     * [CN] 静止帧：选中时为最后一帧，否则为 `restingProgress`。Lottie 用 `cylGoToAndStop`，PAG 与 SVGA 用 `cylSetProgress`，
     *      Rive 用 `resting-frame`（first / last），GIF 用其静帧。
     */
    cylRest() {
      this.cylRestAt(cylAnimatedItemRestingProgress(this.data))
    },

    /**
     * [EN] The resting frame at `progress` (0...1): `cylRest()` for the item's own resting progress, `cylStopAtProgress()` for
     *      the host's. An engine with no seek rests through `cylStop()` (Rive: its `resting-frame`).
     * [CN] 停在 `progress`（0...1）的静止帧：`cylRest()` 使用条目自己的静止进度，`cylStopAtProgress()` 使用宿主给出的进度。
     *      没有跳转的引擎通过 `cylStop()` 静止（Rive：其 `resting-frame`）。
     */
    cylRestAt(progress) {
      clearTimeout(this.cylGifTimer)
      if (this.data.gifPlaying) {
        this.setData({ gifPlaying: false })
        this.cylUpdate()
      }
      if (!this.data.m.usesEngine || !this.data.animationLoaded) return
      const engine = this.selectComponent(CYL_ENGINE_ID)
      if (!engine) return
      if (typeof engine.cylSetProgress === 'function') {
        engine.cylSetProgress(progress)
      } else if (typeof engine.cylGoToAndStop === 'function' && typeof engine.cylLottieAnimation === 'function') {
        const player = engine.cylLottieAnimation()
        const last = Math.max(0, (player?.totalFrames || 1) - 1)
        engine.cylGoToAndStop(Math.round(last * progress), true)
      } else if (typeof engine.cylRest === 'function') {
        engine.cylRest()
      } else if (typeof engine.cylStop === 'function') {
        // [EN] Rive: stopping resets its input, which is its resting state. [CN] Rive：停止会重置其输入，即静止状态。
        engine.cylStop()
      }
    },

    cylPlayGif() {
      clearTimeout(this.cylGifTimer)
      if (!this.data.gifFirstFrame && !this.data.gifLastFrame) {
        // Without stills the GIF always plays; setting its source again restarts it from the first frame.
        const path = this.data.m.gifPath
        this.setData({ 'm.gifPath': '' }, () => this.setData({ 'm.gifPath': path }))
        return
      }
      this.cylGifStartedAt = Date.now()
      this.setData({ gifPlaying: false, 'm.gifPath': this.data.gifFirstFrame || this.data.m.gifPath }, () => {
        this.setData({ gifPlaying: true })
        this.cylUpdate()
        if (!this.data.loop) this.cylScheduleGifEnd()
      })
    },

    /** [EN] One pass, then the resting still. [CN] 播放一遍后显示静帧。 */
    cylScheduleGifEnd() {
      const duration = Number(this.data.gifDuration) > 0 ? Number(this.data.gifDuration) : 1000
      const elapsed = Date.now() - (this.cylGifStartedAt || Date.now())
      this.cylGifTimer = setTimeout(() => {
        this.setData({ gifPlaying: false })
        this.cylUpdate()
        // [EN] A timed pass of a GIF with stills ended: the same as an engine's `complete`. [CN] 有静帧的 GIF 一遍计时结束：与引擎的 `complete` 相同。
        this.cylAnimationDidEnd()
        this.cylPlayDidEnd()
        this.cylEmitComplete({ type: 'gif' })
      }, duration - (elapsed % duration))
    },

    /**
     * [EN] A play-once pass ended: the still image replaces the animation when `showsImageWhenAnimationEnds`.
     * [CN] 只播放一次的一遍结束：开启 `showsImageWhenAnimationEnds` 时用静态图片替换动画。
     */
    cylAnimationDidEnd() {
      cylAnimationDidStop(this, true)
      if (this.data.loop || !this.data.showsImageWhenAnimationEnds || this.data.animationEnded) return
      this.setData({ animationEnded: true })
      this.cylUpdate()
    },

    /** [EN] The animation shows again in place of the still image. [CN] 重新显示动画，替换静态图片。 */
    cylShowAnimationAgain() {
      if (!this.data.animationEnded) return
      this.setData({ animationEnded: false })
      this.cylUpdate()
    },

    /**
     * [EN] No engine, a corrupt file or a failed download: back to the static image (or the placeholder), and once per type
     *      a log naming the package to add. [CN] 没有引擎、文件损坏或下载失败：回到静态图片（或占位图），并按类型输出一次需要安装的包。
     */
    cylOnAnimationError(event) {
      this.cylIsPlaying = false
      this.setData({ animationFailed: true })
      this.cylUpdate()
      // [EN] Forwarded as `animationerror` with the engine's detail (`message`); the item still falls back to its image.
      // [CN] 以 `animationerror` 转发，带引擎的 detail（`message`）；条目仍回到静态图片。
      this.triggerEvent('animationerror', event?.detail || {})
      this.cylReportResourceMissing(cylAnimatedItemMissingReason(event?.detail?.message))
      const type = this.data.m.animationType
      if (type && !cylWarnedTypes.includes(type)) {
        cylWarnedTypes.push(type)
        console.warn(`[cyl-animated-item] ${type} animation (${this.data.animationUrl}) cannot play: ${event?.detail?.message || 'no engine'}. ` +
          `Showing the static image, or the placeholder without one. Install ${cylAnimatedItemPackage(type)} and set generic:cyl-${type}-view.`)
      }
    },

    /**
     * [EN] `resourcemissing` with `{ resource, reason }`: the file as configured (`animationUrl` without its `#` options) and
     *      "not found", "unreadable", "decode failed" or "engine library missing". Once per resource per item; the item still
     *      shows its image or the placeholder. A Lottie given as `animationData` has no file to name.
     * [CN] 以 `{ resource, reason }` 发出 `resourcemissing`：按配置给出的文件（`animationUrl` 去掉 `#` 选项）与原因。每个条目每个资源一次；
     *      条目仍显示图片或占位图。以 `animationData` 传入的 Lottie 没有文件可报告。
     */
    cylReportResourceMissing(reason) {
      const resource = cylAnimatedItemResource(this.data.animationUrl)
      if (!resource) return
      this.cylMissingResources = this.cylMissingResources || []
      if (this.cylMissingResources.includes(resource)) return
      this.cylMissingResources.push(resource)
      this.triggerEvent('resourcemissing', { resource, reason })
    },

    /**
     * [EN] The engine finished a play (a non-looping pass): forwarded as `animationcomplete`, e.g. to count repeats.
     * [CN] 引擎播放结束（非循环的一遍）：以 `animationcomplete` 转发，例如用于统计重复次数。
     */
    cylOnAnimationComplete(event) {
      this.cylAnimationDidEnd()
      this.cylPlayDidEnd()
      this.cylEmitComplete(event?.detail || {})
    },

    /**
     * [EN] A play-once pass ended: sends `animationcomplete` and its alias `animationend` (HarmonyOS name), both with the same detail.
     * [CN] 只播放一次的一遍播放结束：发送 `animationcomplete` 及其别名 `animationend`（鸿蒙的名称），detail 相同。
     */
    cylEmitComplete(detail) {
      this.triggerEvent('animationcomplete', detail)
      this.triggerEvent('animationend', detail)
    },

    /** [EN] A looping play finished one pass: forwarded as `animationloopcomplete`. [CN] 循环播放完成一遍：以 `animationloopcomplete` 转发。 */
    cylOnAnimationLoopComplete(event) {
      this.triggerEvent('animationloopcomplete', event?.detail || {})
    },

    /**
     * [EN] A play-once pass ended: not playing any more, and the player's `onEnded` callback runs.
     * [CN] 只播放一次的一遍播放结束：不再处于播放中，并调用播放器的 `onEnded` 回调。
     */
    cylPlayDidEnd() {
      this.cylIsPlaying = false
      if (this.cylPlayer) this.cylPlayer.didEnd()
    },

    /**
     * [EN] Whether `loop` takes effect on this file: an engine, a GIF with stills, or a GIF image; a GIF with neither plays
     *      by itself and cannot loop. [CN] `loop` 对该文件是否生效：引擎、有静帧的 GIF 或 GIF 图片；两者皆无的 GIF 自行播放，无法循环。
     */
    cylCanLoop() {
      const m = this.data.m
      return !!(m.usesEngine || m.gifImage || (m.animationType === 'gif' && (this.data.gifFirstFrame || this.data.gifLastFrame)))
    },

    /**
     * [EN] The player of this item (once per item, see cyl_animated_item_player.js): `play()`, `stopAtProgress(p)`, `speed`,
     *      `loops`, `supportsSpeed` / `supportsLoops` / `supportsProgress`, `isPlaying`, `onEnded(cb)`, `supportsColors` /
     *      `applyColors(colors)`. The way to play an item with `drivesAnimationPlayback` off; also fine with it on (the
     *      default rules play through the same item). `animationready` says the engine is live.
     * [CN] 本条目的播放器（每个条目一个，见 cyl_animated_item_player.js）：`play()`、`stopAtProgress(p)`、`speed`、`loops`、
     *      `supportsSpeed` / `supportsLoops` / `supportsProgress`、`isPlaying`、`onEnded(cb)`、`supportsColors` / `applyColors(colors)`。
     *      播放 `drivesAnimationPlayback` 关闭的条目的方式；开启时也可用（默认规则通过同一个条目播放）。`animationready` 表示引擎已就绪。
     */
    cylAnimatedItemPlayer() {
      if (this.cylPlayer) return this.cylPlayer
      this.cylPlayer = new CYLAnimatedItemPlayer({
        engine: () => this.cylAnimationView(),
        type: () => (this.data.m.gifImage ? 'gif' : this.data.m.animationType),
        usesLoop: () => this.cylCanLoop(),
        isPlaying: () => !!this.cylIsPlaying,
        get: (name) => this.data[name],
        set: (patch) => this.setData(patch),
        play: () => this.playAnimation(),
        stopAtProgress: (progress) => this.cylStopAtProgress(progress),
      })
      return this.cylPlayer
    },

    /**
     * [EN] Stops where it is, then shows the frame at `progress` (0...1): the player's `stopAtProgress`. Host-driven, the
     *      resting frame and the GIF stills follow this progress until the next call.
     * [CN] 停在当前位置，然后显示 `progress`（0...1）处的帧：播放器的 `stopAtProgress`。宿主驱动时，静止帧与 GIF 静帧在下次调用之前都以此进度为准。
     */
    cylStopAtProgress(progress) {
      this.cylShowAnimationAgain()
      this.cylHalt()
      if (!this.data.drivesAnimationPlayback) {
        this.setData({ hostRestingProgress: progress })
        this.cylUpdate()
      }
      this.cylRestAt(progress)
    },

    /** [EN] The engine component, or null (no engine type, GIF, or not drawn yet). [CN] 引擎组件，没有时为 null。 */
    cylAnimationView() {
      return this.selectComponent(CYL_ENGINE_ID)
    },

    /**
     * [EN] Plays the animation from its first frame, or `offset` seconds in, when its engine can.
     * [CN] 引擎支持时，从首帧（或第 `offset` 秒）播放动画。
     */
    cylPlayFromStart(offset) {
      // [EN] A GIF image plays from its first frame (a selected tab, a re-tap, Play all). [CN] GIF 图片从第一帧播放（选中、再次点击、全部播放）。
      if (this.data.m.gifImage && this.cylGIFImageInfo) {
        this.cylPlayGIFImage()
        return
      }
      const view = this.cylAnimationView()
      if (view && typeof view.cylPlayFromStart === 'function') {
        view.cylPlayFromStart(offset)
      }
    },

    /** [EN] Stops the animation on its resting frame. [CN] 停止动画并显示静止帧。 */
    cylStop() {
      const view = this.cylAnimationView()
      if (view && typeof view.cylStop === 'function') {
        view.cylStop()
      }
    },

    cylOnTap() {
      if (this.data.cylInternalDivider) return
      if (this.data.enabled && !this.data.embedded && this.data.countdownState !== 'running') {
        this.triggerEvent('itemtap', {})
        // [EN] After the page handled the tap (send the code there), the countdown starts. [CN] 页面处理点击（在那里发送验证码）之后开始倒计时。
        if (this.data.itemStyle === 'countdown' && this.data.startsCountdownOnTap) this.startCountdown()
      }
    },

    cylOnLongPress() {
      if (!this.data.cylInternalDivider && this.data.enabled && !this.data.embedded) {
        this.triggerEvent('itemlongpress', {})
      }
    },

    cylOnAccessoryTap() {
      if (this.data.enabled) {
        this.triggerEvent('accessorytap', {})
      }
    },

    cylOnTouchStart(event) {
      if (this.data.enabled) this.cylSetPressed(true)
      if (!this.data.dragEnabled || this.data.embedded) return
      const touch = event.touches[0]
      this.cylDragStart = { x: touch.clientX, y: touch.clientY }
      this.triggerEvent('dragstart', {})
    },

    cylOnTouchMove(event) {
      if (!this.data.dragEnabled || !this.cylDragStart) return
      const touch = event.touches[0]
      this.triggerEvent('dragmove', { dx: touch.clientX - this.cylDragStart.x, dy: touch.clientY - this.cylDragStart.y })
    },

    cylOnTouchEnd(event) {
      this.cylSetPressed(false)
      if (!this.data.dragEnabled || !this.cylDragStart) return
      const touch = event.changedTouches[0]
      this.triggerEvent('dragend', { dx: touch.clientX - this.cylDragStart.x, dy: touch.clientY - this.cylDragStart.y })
      this.cylDragStart = null
    },
  },
})
