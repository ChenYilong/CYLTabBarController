import BuildProfile from '../../../BuildProfile';

/** [EN] `maxLines` for a title without a line limit (`titleLines` 0). [CN] 标题不限行数（`titleLines` 为 0）时的 `maxLines`。 */
const CYL_UNLIMITED_LINES: number = 1000;

/**
 * [EN] Icon beside the title (default) or above it. [CN] 图标在标题旁（默认）或上方。
 */
export enum CYLAnimatedItemAxis {
  Horizontal = 0,
  Vertical = 1
}

/**
 * [EN] Where the accessory sits: before the content, after it (default) or on the icon's top-trailing corner.
 * [CN] 附加图标的位置：内容之前、之后（默认）或图标右上角。
 */
export enum CYLAnimatedItemAccessoryPlacement {
  Leading = 0,
  Trailing = 1,
  TopTrailing = 2
}

/**
 * [EN] What the animation builder gets: the file, its size, the selection, and two callbacks the engine calls once the file
 *      is ready (`onLoaded`) or cannot play (`onFailed`, a corrupt file, a failed download). Until `onLoaded` the item keeps
 *      its static image (or the placeholder) under the animation; after `onFailed` it shows them again.
 * [CN] 动画 builder 得到的内容：文件、尺寸、选中状态，以及两个回调，引擎在文件就绪时调用 `onLoaded`，无法播放时（文件损坏、下载失败）调用
 *      `onFailed`。调用 `onLoaded` 之前，条目在动画下方保留静态图片（或占位图）；调用 `onFailed` 之后重新显示它们。
 */
export class CYLAnimatedItemAnimationContext {
  url: string = '';
  size: number = 24;
  selected: boolean = false;
  /**
   * [EN] The playback the engine applies (the item's `animationSpeed`, `animationLoops`, and `restartToken`, which grows
   *      on every restart: the engine plays from progress 0 when it changes). The item hands a new context to the builder
   *      whenever one of them changes, so the engine view gets them as props and needs no state of the host.
   * [CN] 引擎应用的播放设置（条目的 `animationSpeed`、`animationLoops`，以及每次重播都会增长的 `restartToken`：变化时引擎从进度 0 播放）。
   *      其中任一项变化时条目都会把新的 context 交给 builder，因此引擎视图通过 prop 获得它们，不需要宿主的状态。
   */
  speed: number = 1;
  loops: boolean = false;
  restartToken: number = 0;
  onLoaded: () => void = () => {
  };
  onFailed: () => void = () => {
  };
  /**
   * [EN] The engine view registers how it replays (from progress 0); the item calls it each time `restartToken` grows.
   *      ArkUI copies a builder's values once when an arrow function wraps the builder (a host's `this`), so a prop
   *      alone may never see the new token (B23).
   * [CN] 引擎视图注册其重播方式（从进度 0 播放）；`restartToken` 每次增长时条目调用它。宿主用箭头函数包装 builder（绑定 `this`）时，
   *      ArkUI 只复制一次 builder 的值，因此仅靠 prop 可能永远看不到新标记（B23）。
   */
  setRestartHandler: (handler: () => void) => void = (_handler: () => void) => {
  };
}

/**
 * [EN] Imperative playback for a `CYLAnimatedItemView` (iOS / Android `restartAnimation`): pass one as `controller`, then
 *      call `restartAnimation()`, for example from `onItemTap`. The props `animationSpeed`, `animationLoops` and
 *      `animationRestartToken` do the same declaratively.
 * [CN] `CYLAnimatedItemView` 的命令式播放控制（iOS / Android 的 `restartAnimation`）：作为 `controller` 传入，然后调用 `restartAnimation()`，
 *      例如在 `onItemTap` 中。prop `animationSpeed`、`animationLoops` 与 `animationRestartToken` 以声明式实现相同功能。
 */
export class CYLAnimatedItemController {
  /** [EN] Set by the item it is attached to. [CN] 由所关联的条目设置。 */
  cylRestart: () => void = () => {
  };

  /** [EN] Plays the animation again from progress 0. [CN] 从进度 0 重新播放动画。 */
  restartAnimation(): void {
    this.cylRestart();
  }
}

/**
 * [EN] One known animation type: its name, the pod / package an app adds, and its file extensions.
 * [CN] 一种已知的动画类型：名称、App 需要加入的包，以及文件扩展名。
 */
class CYLAnimatedItemType {
  name: string = '';
  packageName: string = '';
  extensions: string[] = [];

  constructor(name: string, packageName: string, extensions: string[]) {
    this.name = name;
    this.packageName = packageName;
    this.extensions = extensions;
  }
}

const CYL_ANIMATED_ITEM_TYPES: CYLAnimatedItemType[] = [
  new CYLAnimatedItemType('Lottie', '@ohos/lottie', ['json', 'lottie']),
  new CYLAnimatedItemType('PAG', 'libpag', ['pag']),
  new CYLAnimatedItemType('Rive', '@ohos/rive', ['riv']),
  new CYLAnimatedItemType('SVGA', 'an SVGA player', ['svga']),
  new CYLAnimatedItemType('GIF', 'the system Image component', ['gif'])
];

/**
 * [EN] The animation type of a file from its extension ("Lottie", "PAG", "Rive", "SVGA", "GIF"), or '' when unknown.
 * [CN] 根据扩展名得到文件的动画类型（"Lottie"、"PAG"、"Rive"、"SVGA"、"GIF"），未知时为 ''。
 */
export function cylAnimatedItemTypeOf(url: string): string {
  // [EN] A trailing ".bin" is skipped ("icons.riv.bin" is Rive), as in the mini program. [CN] 忽略末尾的 ".bin"，与小程序相同。
  let file: string = url.split('#')[0].split('?')[0].replace(/\.bin$/i, '');
  let dot: number = file.lastIndexOf('.');
  if (dot < 0) {
    return '';
  }
  let extension: string = file.substring(dot + 1).toLowerCase();
  for (let type of CYL_ANIMATED_ITEM_TYPES) {
    if (type.extensions.indexOf(extension) >= 0) {
      return type.name;
    }
  }
  return '';
}

/**
 * [EN] The animation engines an app registered, by type. The component depends on no animation library: an app (or a
 *      library such as cyltabbar) registers the types it can play and passes `animationBuilder`; a file of a type nobody
 *      registered shows the static image, or the placeholder, and debug builds log once which package to add. The
 *      counterpart of iOS `CYLTabBarItemAnimatorRegistry` / `CYLAnimationWarnMissingEngine()` and Android
 *      `CYLAnimationEngines`.
 * [CN] App 按类型注册的动画引擎。组件不依赖任何动画库：App（或 cyltabbar 这样的库）注册它能播放的类型并传入 `animationBuilder`；
 *      没有注册的类型显示静态图片或占位图，debug 构建会输出一次需要加入的包。对应 iOS 的 `CYLTabBarItemAnimatorRegistry` /
 *      `CYLAnimationWarnMissingEngine()` 与 Android 的 `CYLAnimationEngines`。
 */
export class CYLAnimatedItemEngines {
  private static registered: string[] = [];
  private static warned: string[] = [];

  /**
   * [EN] Registers the engine of `type` ("Lottie", "PAG", "Rive", "SVGA", "GIF"). [CN] 注册 `type` 的引擎。
   */
  static register(type: string): void {
    if (CYLAnimatedItemEngines.registered.indexOf(type) < 0) {
      CYLAnimatedItemEngines.registered.push(type);
    }
  }

  /**
   * [EN] Whether the engine of `type` is registered. [CN] `type` 的引擎是否已注册。
   */
  static isRegistered(type: string): boolean {
    return CYLAnimatedItemEngines.registered.indexOf(type) >= 0;
  }

  /**
   * [EN] The registered types. [CN] 已注册的类型。
   */
  static registeredTypes(): string[] {
    return CYLAnimatedItemEngines.registered.slice();
  }

  /**
   * [EN] The known types nobody registered. [CN] 没有注册的已知类型。
   */
  static missingTypes(): string[] {
    let missing: string[] = [];
    for (let type of CYL_ANIMATED_ITEM_TYPES) {
      if (!CYLAnimatedItemEngines.isRegistered(type.name)) {
        missing.push(type.name);
      }
    }
    return missing;
  }

  /**
   * [EN] Whether a registered engine plays `url` (by its extension). [CN] 是否有已注册的引擎能播放 `url`（按扩展名）。
   */
  static canPlay(url: string): boolean {
    let type: string = cylAnimatedItemTypeOf(url);
    return type.length > 0 && CYLAnimatedItemEngines.isRegistered(type);
  }

  /**
   * [EN] In debug builds, logs once per type that `url` cannot play because its engine is not registered, with the package
   *      to add. Nothing in release builds, for an unknown type or when the engine is registered.
   * [CN] 在 debug 构建中，每种类型输出一次日志：`url` 因引擎未注册而无法播放，并给出需要加入的包。release 构建、未知类型或引擎已注册时不做任何事。
   */
  static warnMissingEngine(url: string): void {
    let name: string = cylAnimatedItemTypeOf(url);
    if (!BuildProfile.DEBUG || name.length === 0 || CYLAnimatedItemEngines.isRegistered(name) ||
      CYLAnimatedItemEngines.warned.indexOf(name) >= 0) {
      return;
    }
    CYLAnimatedItemEngines.warned.push(name);
    let packageName: string = '';
    for (let type of CYL_ANIMATED_ITEM_TYPES) {
      if (type.name === name) {
        packageName = type.packageName;
      }
    }
    console.warn(`[CYLAnimatedItem] ${name} animation (${url}) cannot play: no ${name} engine is registered. ` +
      `Showing the static image, or the placeholder without one. Add ${packageName} and call ` +
      `CYLAnimatedItemEngines.register('${name}') with an animationBuilder. Shown in debug builds only.`);
  }
}

/**
 * [EN] The color filter that paints a bitmap in `color` keeping each pixel's alpha (each channel = the color's component x
 *      the pixel's alpha; no offsets, so it does not depend on the channel range); the identity when `color` is '' or not
 *      a '#RRGGBB' / '#AARRGGBB' string. [CN] 以 `color` 绘制位图且保留每个像素透明度的颜色滤镜；color 为空或不是十六进制字符串时为恒等滤镜。
 */
export function cylIconColorFilter(color: ResourceColor): number[] {
  const identity: number[] = [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  if (typeof color !== 'string' || !new RegExp('^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').test(color)) {
    return identity;
  }
  const hex = (color as string).replace('#', '');
  const argb = hex.length === 6 ? 'FF' + hex : hex;
  const c = (index: number): number => parseInt(argb.substring(index, index + 2), 16) / 255;
  return [0, 0, 0, c(2), 0, 0, 0, 0, c(4), 0, 0, 0, 0, c(6), 0, 0, 0, 0, c(0), 0];
}

/**
 * [EN] An icon + title view to reuse or wrap (CollectionViewClassifyMenu's tags, CYLSearchViewController's bar items,
 *      CYLTableViewPlaceHolder's placeholders): an icon that plays an animation file through `animationBuilder`, its static
 *      image, a title beside or below it, an optional accessory with its own tap, and gestures on the whole item (tap, long
 *      press, drag). What shows, as on iOS and Android: the animation when a registered engine can play it; otherwise, while
 *      it loads and after it fails, the static image (`image` / `selectedImage`); the placeholder only when there is no
 *      static image. It is one accessibility element: its text is `itemTitle` (or `itemAccessibilityText`), its description
 *      `itemDescription` plus, while selected, `selectedDescription` (localized by the caller, like every text it shows).
 * [CN] 可复用或包装的图标 + 标题视图（CollectionViewClassifyMenu 的标签、CYLSearchViewController 的栏目、CYLTableViewPlaceHolder 的占位图）：
 *      通过 `animationBuilder` 播放动画文件的图标、其静态图片、位于旁边或下方的标题、带独立点击的可选附加图标，以及整个条目的手势（点击、长按、拖拽）。
 *      显示规则与 iOS、Android 相同：已注册的引擎能播放时显示动画；否则在加载期间与失败之后显示静态图片（`image` / `selectedImage`）；只有没有静态图片时
 *      才显示占位图。它是一个无障碍元素：文本为 `itemTitle`（或 `itemAccessibilityText`），描述为 `itemDescription` 加上选中状态。
 */
@Component
export struct CYLAnimatedItemView {
  @Prop itemTitle: string = '';
  @Prop image: ResourceStr = '';
  @Prop selectedImage: ResourceStr = '';
  @Prop placeholderImage: ResourceStr = $r('app.media.cyl_animated_item_placeholder');
  @Prop @Watch('cylAnimationDidChange') animationUrl: string = '';
  @Prop @Watch('cylPlaybackDidChange') isItemSelected: boolean = false;
  /**
   * [EN] Playback speed of the animation, 1 by default (iOS / Android `animationSpeed`). [CN] 动画播放速度，默认 1（iOS / Android `animationSpeed`）。
   */
  @Prop @Watch('cylPlaybackDidChange') animationSpeed: number = 1;
  /**
   * [EN] Whether the animation repeats (iOS / Android `animationLoops`). [CN] 动画是否循环（iOS / Android `animationLoops`）。
   */
  @Prop @Watch('cylPlaybackDidChange') animationLoops: boolean = false;
  /**
   * [EN] Any change plays the animation again from progress 0 (declarative `restartAnimation`); see also `controller`.
   * [CN] 任何变化都会让动画从进度 0 重新播放（声明式的 `restartAnimation`）；另见 `controller`。
   */
  @Prop @Watch('cylPlaybackDidChange') animationRestartToken: number = 0;
  /** [EN] Optional imperative control (`restartAnimation()`). [CN] 可选的命令式控制（`restartAnimation()`）。 */
  controller?: CYLAnimatedItemController;
  @State private cylControllerRestarts: number = 0;
  /** [EN] The engine view's replay (B23) and the token it last saw. [CN] 引擎视图的重播（B23）及其上次看到的标记。 */
  private cylRestartHandler?: () => void;
  private cylLastRestartToken: number = 0;
  private cylSetRestartHandler: (handler: () => void) => void = (handler: () => void) => {
    this.cylRestartHandler = handler;
  };
  @Prop isItemEnabled: boolean = true;
  @Prop axis: CYLAnimatedItemAxis = CYLAnimatedItemAxis.Horizontal;
  @Prop iconSize: number = 24;
  /**
   * [EN] The color of the static icon (`image` / `selectedImage` / the placeholder), as iOS tints template images: SVG
   *      and symbol images take it as their fill, bitmaps through an alpha-preserving color filter. '' (the default)
   *      keeps the image's own colors. A '#RRGGBB' / '#AARRGGBB' string tints bitmaps too; a resource color tints SVG
   *      only. [CN] 静态图标的颜色（如 iOS 的模板图着色）：SVG 与符号图作为填充色，位图通过保留透明度的颜色滤镜着色；''（默认）保留原色。
   */
  @Prop iconColor: ResourceColor = '';
  /**
   * [EN] The color the animation is drawn in, as one color, like a tinted template image (iOS / Android
   *      `CYLTabBarAnimationOptionTint`); '' keeps the file's own colors. Any engine: a layer of this color is
   *      composited "source in" over the engine view, in its own offscreen group, so the shape takes the color and its
   *      alpha (a 60 % white tint draws a 60 % white icon, as Android's SRC_IN; "source atop" kept a white icon white).
   * [CN] 动画以单一颜色绘制时使用的颜色，与着色的模板图片一致（iOS / Android 的 `CYLTabBarAnimationOptionTint`）；'' 保留文件自身的颜色。
   *      适用于任何引擎：在引擎视图上方以 "source in" 合成一层该颜色，位于独立的离屏组中，因此图形取该颜色及其透明度（60% 白色的着色绘制出
   *      60% 白色的图标，与 Android 的 SRC_IN 一致；"source atop" 会让白色图标保持白色）。
   */
  @Prop animationTintColor: ResourceColor = '';
  /**
   * [EN] The gap in vp between the icon and the title, and between an inline accessory and the rest (iOS `spacing`,
   *      Android `spacingDp`, the mini program's `titleSpacing`). Bug B21: it was declared but never read.
   * [CN] 图标与标题之间、行内附件与其余内容之间的间距（vp）（iOS `spacing`、Android `spacingDp`、小程序 `titleSpacing`）。问题 B21：此前声明了却从未使用。
   */
  @Prop spacing: number = 4;
  /**
   * [EN] The most lines of the title: 1 (the default) is one line with an ellipsis, 0 has no limit (as the mini
   *      program's `titleLines`). [CN] 标题的最大行数：1（默认）为单行加省略号，0 不限（与小程序的 `titleLines` 相同）。
   */
  @Prop titleLines: number = 1;
  @Prop titleFontSize: number = 14;
  @Prop titleColor: ResourceColor = '#333333';
  @Prop accessoryImage: ResourceStr = '';
  @Prop accessoryText: string = '';
  @Prop accessoryAccessibilityText: string = '';
  @Prop accessoryPlacement: CYLAnimatedItemAccessoryPlacement = CYLAnimatedItemAccessoryPlacement.Trailing;
  @Prop isDragEnabled: boolean = false;
  @Prop itemAccessibilityText: string = '';
  @Prop itemDescription: string = '';
  @Prop selectedDescription: string = '';
  @Prop itemId: string = '';
  /**
   * [EN] Embedded in a host that is the touch target and the accessibility element (the tab bar's icon): no padding, no
   *      minimum height, no gestures and hidden from screen readers. [CN] 嵌入在作为触摸目标与无障碍元素的宿主中（TabBar 的图标）：
   *      无内边距、无最小高度、无手势，并对读屏隐藏。
   */
  @Prop isBare: boolean = false;
  /**
   * [EN] Sized by its content in both directions (B29), as in a stack (`CYLAnimatedItemStackView`); otherwise (default)
   *      the item fills its parent, as a `Flex` without a size does, which suits a tag in a fixed-size cell.
   * [CN] 两个方向都按内容决定尺寸（B29），用于堆叠（`CYLAnimatedItemStackView`）；否则（默认）条目与未设置尺寸的 `Flex` 一样填满父组件，适合固定尺寸单元格中的标签。
   */
  @Prop sizesToContent: boolean = false;
  @State animationLoaded: boolean = false;
  @State animationFailed: boolean = false;
  @BuilderParam animationBuilder: (context: CYLAnimatedItemAnimationContext) => void = this.cylNoAnimation;
  onItemTap?: () => void;
  onItemLongPress?: () => void;
  onAccessoryTap?: () => void;
  onItemDragStart?: () => void;
  onItemDragMove?: (dx: number, dy: number) => void;
  onItemDragEnd?: (dx: number, dy: number) => void;
  @State private animationContext: CYLAnimatedItemAnimationContext = new CYLAnimatedItemAnimationContext();

  aboutToAppear(): void {
    this.cylLastRestartToken = this.animationRestartToken + this.cylControllerRestarts;
    if (this.controller) {
      this.controller.cylRestart = () => {
        this.cylControllerRestarts += 1;
        this.cylPlaybackDidChange();
      };
    }
    this.cylAnimationDidChange();
  }

  @Builder
  cylNoAnimation(context: CYLAnimatedItemAnimationContext) {
  }

  /**
   * [EN] A new file starts over: not loaded, not failed; a type nobody registered says so in debug builds.
   * [CN] 新文件重新开始：未加载、未失败；没有注册的类型在 debug 构建中给出提示。
   */
  cylAnimationDidChange(): void {
    this.animationLoaded = false;
    this.animationFailed = false;
    this.cylUpdateContext();
    if (this.animationUrl.length > 0 && !CYLAnimatedItemEngines.canPlay(this.animationUrl)) {
      CYLAnimatedItemEngines.warnMissingEngine(this.animationUrl);
    }
  }

  /**
   * [EN] The selection, speed, loops or a restart changed: the engine gets them in a new context, without reloading the
   *      file. [CN] 选中、速度、循环或重播发生变化：引擎通过新的 context 获得它们，不重新加载文件。
   */
  cylPlaybackDidChange(): void {
    this.cylUpdateContext();
    const token = this.animationRestartToken + this.cylControllerRestarts;
    if (token !== this.cylLastRestartToken) {
      this.cylLastRestartToken = token;
      this.cylRestartHandler?.();
    }
  }

  private cylUpdateContext(): void {
    let context: CYLAnimatedItemAnimationContext = new CYLAnimatedItemAnimationContext();
    context.url = this.animationUrl;
    context.size = this.iconSize;
    context.selected = this.isItemSelected;
    context.speed = this.animationSpeed;
    context.loops = this.animationLoops;
    context.restartToken = this.animationRestartToken + this.cylControllerRestarts;
    context.setRestartHandler = this.cylSetRestartHandler;
    let url: string = this.animationUrl;
    context.onLoaded = () => {
      if (url === this.animationUrl) {
        this.animationLoaded = true;
      }
    };
    context.onFailed = () => {
      if (url === this.animationUrl) {
        this.animationFailed = true;
      }
    };
    this.animationContext = context;
  }

  /**
   * [EN] Whether an engine plays the file now (made and not failed). [CN] 是否有引擎正在播放该文件（已创建且未失败）。
   */
  cylMakesAnimation(): boolean {
    return this.animationUrl.length > 0 && !this.animationFailed && CYLAnimatedItemEngines.canPlay(this.animationUrl);
  }

  /**
   * [EN] The static image of the state, or '' when there is none. [CN] 当前状态的静态图片，没有时为 ''。
   */
  cylStaticImage(): ResourceStr {
    if (this.isItemSelected && !this.cylIsEmpty(this.selectedImage)) {
      return this.selectedImage;
    }
    return this.image;
  }

  cylIsEmpty(image: ResourceStr): boolean {
    return typeof image === 'string' && (image as string).length === 0;
  }

  /**
   * [EN] What the icon shows under the animation: the static image, else the placeholder when there is an animation file
   *      that does not show (yet), else nothing.
   * [CN] 图标在动画下方显示的内容：静态图片；没有时，若有尚未显示的动画文件则显示占位图；否则不显示。
   */
  cylFallbackImage(): ResourceStr {
    let image: ResourceStr = this.cylStaticImage();
    if (!this.cylIsEmpty(image)) {
      return image;
    }
    let animationShows: boolean = this.cylMakesAnimation() && this.animationLoaded;
    return (this.animationUrl.length > 0 && !animationShows) ? this.placeholderImage : '';
  }

  cylShowsIcon(): boolean {
    return !this.cylIsEmpty(this.cylFallbackImage()) || this.cylMakesAnimation();
  }

  cylAccessibilityText(): string {
    return this.itemAccessibilityText.length > 0 ? this.itemAccessibilityText : this.itemTitle;
  }

  @Builder
  cylIcon() {
    Stack() {
      if (!this.cylIsEmpty(this.cylFallbackImage())) {
        Image(this.cylFallbackImage())
          .width(this.iconSize)
          .height(this.iconSize)
          .fillColor(this.iconColor === '' ? undefined : this.iconColor)
          .colorFilter(new ColorFilter(cylIconColorFilter(this.iconColor)))
          .objectFit(ImageFit.Contain)
          .opacity(this.cylMakesAnimation() && this.animationLoaded ? 0 : 1)
          .accessibilityLevel('no')
      }
      if (this.cylMakesAnimation()) {
        Stack() {
        Column() {
          // [EN] One object literal whose fields read state: ArkUI passes it by reference, so the engine view gets new
          //      values (selection, speed, loops, restarts) as they change; a context object alone is rendered once.
          // [CN] 字段读取状态的单个对象字面量：ArkUI 按引用传递，引擎视图随变化获得新值（选中、速度、循环、重播）；单独的 context 对象只渲染一次。
          this.animationBuilder({
            url: this.animationUrl,
            size: this.iconSize,
            selected: this.isItemSelected,
            speed: this.animationSpeed,
            loops: this.animationLoops,
            restartToken: this.animationRestartToken + this.cylControllerRestarts,
            onLoaded: this.animationContext.onLoaded,
            onFailed: this.animationContext.onFailed,
            setRestartHandler: this.cylSetRestartHandler
          })
        }
        .width(this.iconSize)
        .height(this.iconSize)
          if (this.animationTintColor !== '') {
            // [EN] The tint: kept only where the animation draws, with the animation's alpha (source in).
            // [CN] 着色：只保留动画绘制的区域，并乘以动画的透明度（source in）。
            Column()
              .width(this.iconSize)
              .height(this.iconSize)
              .backgroundColor(this.animationTintColor)
              .blendMode(BlendMode.SRC_IN)
              .hitTestBehavior(HitTestMode.Transparent)
              .id('cyl-animated-item-tint')
          }
        }
        .width(this.iconSize)
        .height(this.iconSize)
        // [EN] An offscreen group, so the tint only meets the animation, never what is behind the item.
        // [CN] 离屏组，使着色只与动画合成，不影响条目背后的内容。
        .blendMode(this.animationTintColor !== '' ? BlendMode.SRC_OVER : BlendMode.NONE, BlendApplyType.OFFSCREEN)
        .opacity(this.animationLoaded ? 1 : 0)
        .accessibilityLevel('no')
      }
      if (this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.TopTrailing) {
        this.cylAccessory()
      }
    }
    .alignContent(Alignment.TopEnd)
  }

  @Builder
  cylAccessory() {
    if (!this.cylIsEmpty(this.accessoryImage) || this.accessoryText.length > 0) {
      Row() {
        if (!this.cylIsEmpty(this.accessoryImage)) {
          Image(this.accessoryImage).width(18).height(18).objectFit(ImageFit.Contain)
        } else {
          Text(this.accessoryText).fontSize(this.titleFontSize).fontColor(this.titleColor)
        }
      }
      .constraintSize({ minWidth: 44, minHeight: 44 })
      .justifyContent(FlexAlign.Center)
      // [EN] An inline accessory keeps `spacing` from the icon and title, as on Android (B21). [CN] 行内附件与图标、标题保持 `spacing`，与 Android 相同（B21）。
      .margin(!this.cylShowsIconOrTitle() ? 0 :
        this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Leading ?
          (this.axis === CYLAnimatedItemAxis.Vertical ? { bottom: this.spacing } : { right: this.spacing }) :
          this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Trailing ? this.cylLeadingGap(this.spacing) : 0)
      .accessibilityGroup(true)
      .accessibilityText(this.accessoryAccessibilityText.length > 0 ? this.accessoryAccessibilityText : this.accessoryText)
      .id(this.itemId.length > 0 ? `${this.itemId}-accessory` : '')
      .onClick(() => {
        if (this.isItemEnabled && this.onAccessoryTap) {
          this.onAccessoryTap();
        }
      })
    }
  }

  @Builder
  cylTitle() {
    if (this.itemTitle.length > 0) {
      Text(this.itemTitle)
        .fontSize(this.titleFontSize)
        .fontColor(this.titleColor)
        .maxLines(this.titleLines > 0 ? Math.floor(this.titleLines) : CYL_UNLIMITED_LINES)
        .textOverflow({ overflow: this.titleLines > 0 ? TextOverflow.Ellipsis : TextOverflow.None })
        .textAlign(this.axis === CYLAnimatedItemAxis.Vertical ? TextAlign.Center : TextAlign.Start)
        .margin(this.cylShowsIcon() ? this.cylLeadingGap(this.spacing) : 0)
        .accessibilityLevel('no')
    }
  }

  /** [EN] A gap before a part: above it on the vertical axis, before it on the horizontal one. [CN] 某部分之前的间距：纵向在其上方，横向在其前方。 */
  private cylLeadingGap(gap: number): Margin {
    return this.axis === CYLAnimatedItemAxis.Vertical ? { top: gap } : { left: gap };
  }

  /** [EN] Whether the icon or the title shows (an inline accessory keeps `spacing` from them). [CN] 是否显示图标或标题（行内附件与它们保持 `spacing`）。 */
  private cylShowsIconOrTitle(): boolean {
    return this.cylShowsIcon() || this.itemTitle.length > 0;
  }

  @Builder
  cylContent() {
    if (this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Leading) {
      this.cylAccessory()
    }
    if (this.cylShowsIcon()) {
      this.cylIcon()
    }
    this.cylTitle()
    if (this.accessoryPlacement === CYLAnimatedItemAccessoryPlacement.Trailing) {
      this.cylAccessory()
    }
  }

  /** [EN] Bare and only an icon: no title, no accessory. [CN] 纯图标模式且只有图标：没有标题和附件。 */
  private cylIsBareIcon(): boolean {
    return this.isBare && this.itemTitle.length === 0 && this.cylIsEmpty(this.accessoryImage) && this.accessoryText.length === 0;
  }

  build() {
    Flex({
      direction: this.axis === CYLAnimatedItemAxis.Vertical ? FlexDirection.Column : FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      this.cylContent()
    }
    .padding(this.isBare ? 0 : 4)
    // [EN] A Flex without a size fills its parent. A bare icon (a host's tab icon, no title, no accessory) is exactly the
    //      icon, so a host can place things against its edges: the tab bar puts the badge at the icon's top-right, and an
    //      item as wide as the tab slot moved it to the icon's top-left (HarmonyOS issue list #51). `undefined` keeps the
    //      default size everywhere else.
    // [CN] 未设置尺寸的 Flex 会填满父组件。纯图标（宿主的 Tab 图标，无标题、无附件）的尺寸就是图标尺寸，宿主才能依据其边缘布局：TabBar 把角标放在
    //      图标右上角，而与 Tab 槽位同宽的条目把角标挪到了图标左上角（鸿蒙问题列表 #51）。其他情况为 `undefined`，保持默认尺寸。
    .width(this.cylIsBareIcon() ? this.iconSize : (this.sizesToContent ? 'auto' : undefined))
    .height(this.cylIsBareIcon() ? this.iconSize : (this.sizesToContent ? 'auto' : undefined))
    .opacity(this.isItemEnabled ? 1 : 0.5)
    .constraintSize({ minHeight: this.isBare ? 0 : 44 })
    .hitTestBehavior(this.isBare ? HitTestMode.None : HitTestMode.Default)
    .accessibilityLevel(this.isBare ? 'no-hide-descendants' : 'auto')
    .accessibilityGroup(true)
    .accessibilityText(this.cylAccessibilityText())
    .accessibilityDescription(this.isItemSelected && this.selectedDescription.length > 0 ?
      [this.itemDescription, this.selectedDescription].filter((part: string) => part.length > 0).join(', ') : this.itemDescription)
    .id(this.itemId)
    .onClick(() => {
      if (this.isItemEnabled && this.onItemTap) {
        this.onItemTap();
      }
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          if (this.isItemEnabled && this.onItemLongPress) {
            this.onItemLongPress();
          }
        })
    )
    .parallelGesture(
      PanGesture()
        .onActionStart(() => {
          if (this.isDragEnabled && this.onItemDragStart) {
            this.onItemDragStart();
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.isDragEnabled && this.onItemDragMove) {
            this.onItemDragMove(event.offsetX, event.offsetY);
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.isDragEnabled && this.onItemDragEnd) {
            this.onItemDragEnd(event.offsetX, event.offsetY);
          }
        })
    )
  }
}
