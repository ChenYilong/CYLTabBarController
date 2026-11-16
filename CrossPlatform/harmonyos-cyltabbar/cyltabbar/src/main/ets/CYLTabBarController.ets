import { CYLTabBarStyleType, cyl_tabBarStyleModifier } from './CYLFlatDesignTabBar';
import { curves } from '@kit.ArkUI';
import { CYLTabBarItemAttributes, CYLTitleOffset } from './CYLTabBarItem';
import { CYLPlusButton } from './CYLPlusButton';
import { CYLBadge, CYLBadgeView } from './CYLBadge';
import { CYLLottieIcon } from './CYLLottieIcon';
import { CYLLocalizedString, cyl_textOf } from './CYLLocalization';

import { vibrator } from '@kit.SensorServiceKit';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { router } from '@kit.ArkUI';

/**
 * [EN] What a screen reader says for a badge (read as part of its host, e.g. "Messages, 99+ new messages"); '' none.
 * [CN] 屏幕阅读器读出的角标内容（作为宿主的一部分读出）；无角标时为 ''。
 */
export function cyl_badgeAccessibilityText(badge: CYLBadge | undefined): string {
  if (badge === undefined || !badge.cyl_isShowBadge()) {
    return '';
  }
  const text = badge.cyl_displayText();
  if (text === null) {
    return CYLLocalizedString('有新内容');
  }
  if (/^\d+\+?$/.test(text)) {
    return CYLLocalizedString('%@ 条新消息', text);
  }
  return CYLLocalizedString('Badge: %@', text);
}

/**
 * [EN] CYLTabBarMinimizeBehavior (issue #13): how the tab bar reacts when the current page scrolls.
 * [CN] 页面滚动时 TabBar 的反应（issue #13）。
 */
export enum CYLTabBarMinimizeBehavior {
  Automatic = 0,
  Never,
  OnScrollDown,
  OnScrollUp,
}

/** [EN] AppStorage key of the latest scroll delta (cyl_reportScroll). [CN] 最近一次滚动距离的 AppStorage 键。 */
export const CYLScrollStorageKey: string = 'cyl_scrollDelta';

/**
 * [EN] Reports a scroll of the current page (List / Scroll onDidScroll offset, vp; > 0 down) to the tab bar
 *      controller, which hides or shows the bar by tabBarMinimizeBehavior (cyl_hidesTabBarOnScroll).
 * [CN] 向 TabBarController 报告当前页面的滚动（List / Scroll 的 onDidScroll 偏移，vp；> 0 向下），控制器按 tabBarMinimizeBehavior 隐藏或显示 TabBar。
 */
export function cyl_reportScroll(delta: number): void {
  // [EN] A counter in the fraction keeps equal deltas distinct. [CN] 用小数部分的计数区分相同的偏移。
  cylScrollCounter = (cylScrollCounter + 1) % 1000;
  AppStorage.setOrCreate<number>(CYLScrollStorageKey, Math.round(delta) + (delta >= 0 ? 1 : -1) * cylScrollCounter / 10000);
}

let cylScrollCounter: number = 0;

/** [EN] AppStorage key of the tab a pushed page asks to select (cyl_popSelectTabBarChildViewController...). [CN] 被 push 的页面请求选中的 Tab。 */
export const CYLSelectRequestStorageKey: string = 'cyl_selectRequest';

/**
 * [EN] -cyl_popSelectTabBarChildViewControllerAtIndex:completion:: pops the pushed pages (router.clear + back to the
 *      page of the tab bar controller) and selects the tab at `index`.
 * [CN] 退出被 push 的页面（返回 TabBarController 所在页面）并选中第 index 个 Tab。
 */
export function cyl_popSelectTabBarChildViewControllerAtIndex(index: number, completion?: () => void): void {
  AppStorage.setOrCreate<string>(CYLSelectRequestStorageKey, `${index}#${Date.now()}`);
  router.back({ url: AppStorage.get<string>('cyl_tabBarPageUrl') ?? 'pages/Index' });
  if (completion !== undefined) {
    setTimeout(completion, 0);
  }
}

/**
 * [EN] -cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier:: the same, by tab identifier.
 * [CN] 同上，按 Tab identifier。
 */
export function cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier(identifier: string, completion?: () => void): void {
  AppStorage.setOrCreate<string>(CYLSelectRequestStorageKey, `id:${identifier}#${Date.now()}`);
  router.back({ url: AppStorage.get<string>('cyl_tabBarPageUrl') ?? 'pages/Index' });
  if (completion !== undefined) {
    setTimeout(completion, 0);
  }
}

/**
 * [EN] -cyl_selectTabBarItemWithIdentifier:: selects the tab with this identifier in the tab bar controller on screen.
 * [CN] 在当前 TabBarController 中选中该 identifier 的 Tab。
 */
export function cyl_selectTabBarItemWithIdentifier(identifier: string): void {
  AppStorage.setOrCreate<string>(CYLSelectRequestStorageKey, `id:${identifier}#${Date.now()}`);
}

/**
 * [EN] -cyl_tabBarItemIdentifiers: the identifiers of the tabs, in order (the index when a tab has none).
 * [CN] 各 Tab 的 identifier，按顺序（没有时为索引）。
 */
export function cyl_tabBarItemIdentifiers(items: CYLTabBarItemAttributes[]): string[] {
  return items.map((item: CYLTabBarItemAttributes, index: number) => item.identifier ?? `${index}`);
}

/**
 * [EN] -cyl_indexOfTabBarItemWithIdentifier: (cyl_controlWithTabBarItemIdentifier, cyl_viewControllerWithTabBarItemIdentifier
 *      find the button and page at this index); -1 when none.
 * [CN] 该 identifier 的 Tab 索引（按钮与页面都在此索引）；没有时为 -1。
 */
export function cyl_indexOfTabBarItemWithIdentifier(items: CYLTabBarItemAttributes[], identifier: string): number {
  return cyl_tabBarItemIdentifiers(items).indexOf(identifier);
}

/**
 * [EN] -cyl_pushViewController:animated:: pushes a page (router url) above the tab bar, which it covers (the tab bar
 *      stays with its page, as hidesBottomBarWhenPushed).
 * [CN] 在 TabBar 之上 push 页面（router url），页面覆盖 TabBar（相当于 hidesBottomBarWhenPushed）。
 */
export function cyl_pushViewController(url: string, params?: Object): void {
  router.pushUrl({ url: url, params: params });
}

/**
 * [EN] -cyl_pushOrPopToViewController:animated:callback:: goes back to `url` when it is already in the stack, otherwise
 *      pushes it; callback(true) when it popped.
 * [CN] 若 url 已在栈中则返回到它，否则 push；返回时 callback(true)。
 */
export function cyl_pushOrPopToViewController(url: string, params?: Object, callback?: (popped: boolean) => void): void {
  const index = router.getStateByUrl(url);
  if (index.length > 0) {
    router.back({ url: url, params: params });
    callback?.(true);
  } else {
    router.pushUrl({ url: url, params: params });
    callback?.(false);
  }
}

let cylTapPlayer: media.SoundPool | undefined = undefined;
let cylTapSound: number = -1;

/**
 * [EN] Plays the tap sound (cyl_tabButtonTapSoundEnabled; cyl_tabButtonTapSoundURL: a rawfile path, the library's
 *      click by default). The file must be in the app's rawfile.
 * [CN] 播放点击音效（rawfile 路径，默认使用库的点击音）。文件需在应用的 rawfile 中。
 */
async function cylPlayTapSound(context: Context, path: string): Promise<void> {
  if (cylTapPlayer === undefined) {
    cylTapPlayer = await media.createSoundPool(2, { usage: audio.StreamUsage.STREAM_USAGE_GAME, rendererFlags: 1 });
    const fd = context.resourceManager.getRawFdSync(path);
    cylTapSound = await cylTapPlayer.load(fd.fd, fd.offset, fd.length);
    await new Promise<void>((resolve: () => void) => setTimeout(resolve, 150));
  }
  await cylTapPlayer.play(cylTapSound, { loop: 0, rate: audio.AudioRendererRate.RENDER_RATE_NORMAL, leftVolume: 0.6, rightVolume: 0.6, priority: 0 });
}

/**
 * [EN] CYLTabButtonTapAnimationType: the built-in tap animations of a tab button (cyl_tabButtonTapAnimationType).
 * [CN] Tab 按钮的内置点击动画。
 */
export enum CYLTabButtonTapAnimationType {
  None = 0,
  Scale,
  ZoomIn,
  Bounce,
  Rotation,
  Flip,
}

/**
 * [EN] The AppStorage key of the system color mode ('dark' / 'light'); set it from UIAbility.onCreate and
 *      onConfigurationUpdate with cyl_updateColorMode (Dark Mode images, CYLTabBarItemDarkImage).
 * [CN] 系统颜色模式的 AppStorage 键（'dark' / 'light'）；在 UIAbility.onCreate 与 onConfigurationUpdate 中用 cyl_updateColorMode 设置。
 */
export const CYLColorModeStorageKey: string = 'cyl_colorMode';

/** [EN] Records the color mode (ConfigurationConstant.ColorMode: 0 dark, 1 light). [CN] 记录颜色模式（0 深色，1 浅色）。 */
export function cyl_updateColorMode(colorMode: number | undefined): void {
  AppStorage.setOrCreate<string>(CYLColorModeStorageKey, colorMode === 0 ? 'dark' : 'light');
}

/** [EN] CYLImpactFeedbackStyle (cyl_tabButtonHapticFeedbackStyle). [CN] 触感强度。 */
export enum CYLImpactFeedbackStyle {
  Light = 0,
  Medium,
  Heavy,
}

/**
 * [EN] UIEdgeInsets (vp). [CN] 边距（vp）。
 */
export interface CYLEdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/** [EN] The AppStorage key bumped by cyl_simulateMemoryWarning. [CN] cyl_simulateMemoryWarning 递增的 AppStorage 键。 */
export const CYLMemoryWarningStorageKey: string = 'cyl_memoryWarning';

/**
 * [EN] +[CYLTabBarController cyl_simulateMemoryWarning]: sends a memory warning to every CYLTabBarController (also for
 *      real warnings: call it from UIAbility.onMemoryLevel). Each controller with unloadsUnselectedViewsOnMemoryWarning
 *      unloads the pages of its unselected tabs (#426) and reports them to onMemoryWarning.
 * [CN] 向所有 CYLTabBarController 发送内存警告（系统内存警告时可在 UIAbility.onMemoryLevel 中调用）。开启 unloadsUnselectedViewsOnMemoryWarning
 *      的控制器卸载未选中 Tab 的页面（#426），并通过 onMemoryWarning 报告。
 */
export function cyl_simulateMemoryWarning(): void {
  AppStorage.setOrCreate<number>(CYLMemoryWarningStorageKey, (AppStorage.get<number>(CYLMemoryWarningStorageKey) ?? 0) + 1);
}

/**
 * [EN] One place of the bar: a tab (tabIndex >= 0) or the plus button (tabIndex -1).
 * [CN] TabBar 中的一个位置：Tab（tabIndex >= 0）或加号按钮（tabIndex 为 -1）。
 */
class CYLSlot {
  tabIndex: number = -1;
  key: string = '';

  constructor(tabIndex: number, key: string) {
    this.tabIndex = tabIndex;
    this.key = key;
  }
}

/**
 * [EN] The plus button's place among the selectable pages (its page comes after the tabs). [CN] 加号页面的索引（排在所有 Tab 之后）。
 */
export const CYLPlusButtonPageIndex: number = -1;

/**
 * [EN] CYLTabBarController for HarmonyOS: the tab bar and the pages of the tabs. Pages are built by `pageBuilder`
 *      (index, identifier) the first time their tab is selected, then kept (as iOS keeps its view controllers).
 *      Properties map the iOS library: tabBarItemsAttributes (CYLTabBarControllerTabBarItemsAttributes), plusButton
 *      (CYLTabBarControllerPlusButton), selectedIndex, badgeValues (-cyl_setBadgeValue: of each tab), tintColor
 *      (CYLTabBarItemSelectedTitleColor), unselectedColor, tabBarHeight, tabBarHidden (-setTabBarHidden:animated:),
 *      shouldSelect (-tabBarController:shouldSelectViewController:), didSelect (-tabBarController:didSelectViewController:),
 *      plusButtonAction (CYLTabBarControllerPlusButtonAction).
 * [CN] 鸿蒙版 CYLTabBarController：TabBar 与各 Tab 的页面。页面在其 Tab 第一次被选中时由 `pageBuilder`（index, identifier）
 *      创建，之后保留（与 iOS 保留视图控制器相同）。属性与 iOS 库对应，见上。
 */
@Component
export struct CYLTabBarController {
  /** [EN] CYLTabBarControllerTabBarItemsAttributes; a new array updates the tabs (-updateTabBarItemAtIndex:attributes:). [CN] 新数组即更新 Tab。 */
  @Prop tabBarItemsAttributes: CYLTabBarItemAttributes[] = [];
  plusButton?: CYLPlusButton;
  @Link selectedIndex: number;
  /** [EN] The badge of each tab (-[UIView cyl_showBadgeValue:] on its tab button); created when unset. [CN] 每个 Tab 的角标；未设置时自动创建。 */
  @State badges: CYLBadge[] = [];
  /** [EN] The plus button's badge. [CN] 加号按钮的角标。 */
  @State plusButtonBadge: CYLBadge = new CYLBadge();
  @Prop tabBarHidden: boolean = false;
  /** [EN] -setTabBarHidden:animated:: whether hiding and showing slide (true) or jump. [CN] 隐藏与显示是否带滑动动画。 */
  @Prop tabBarHiddenAnimated: boolean = true;
  /** [EN] cyl_tabBarItemSelectedTitleColor / CYLTabBarItemSelectedTitleColor. [CN] 选中标题颜色。 */
  @Prop tintColor: ResourceColor = '#FF8000';
  /** [EN] cyl_tabBarItemTitleColor / CYLTabBarItemTitleColor. [CN] 未选中标题颜色。 */
  @Prop unselectedColor: ResourceColor = '#808080';
  plusButtonTitleSelectedColor?: ResourceColor;
  /** [EN] cyl_tabBarBackgroundColor / CYLTabBarBackgroundColor. [CN] TabBar 背景色。 */
  @Prop tabBarBackgroundColor: ResourceColor = '#F8F8F8';
  /** [EN] cyl_tabBarShadowColor / CYLTabBarShadowColor: the line on top of the bar; transparent hides it. [CN] TabBar 顶部分割线颜色；透明即隐藏。 */
  @Prop tabBarShadowColor: ResourceColor = '#1F000000';
  /** [EN] tabBarHeight / CYLTabBarHeight (vp). [CN] TabBar 高度（vp）。 */
  @Prop tabBarHeight: number = 49;
  /**
   * [EN] `tabBarStyleType` (iOS CYLConstants.h): Default, System, FlatDesign or LiquidGlass (demo 7: FlatDesign).
   * [CN] TabBar 样式（iOS CYLConstants.h）：默认、系统、扁平或液态玻璃（第 7 项：扁平样式）。
   */
  @Prop tabBarStyleType: CYLTabBarStyleType = CYLTabBarStyleType.Default;
  /**
   * [EN] `-[CYLFlatDesignTabBar barTintColor]`: the FlatDesign bar's tint over its blur; undefined (default) for none.
   * [CN] 扁平样式 TabBar 模糊之上的着色；undefined（默认）表示不着色。
   */
  @Prop barTintColor: ResourceColor | undefined = undefined;
  /**
   * [EN] -[CYLTabBar cyl_itemEdgeInsets]: space kept free at the two ends of the bar; the tabs and the plus button share
   *      the rest (centered items).
   * [CN] TabBar 两端留空；Tab 与加号按钮平分其余宽度（居中排列）。
   */
  @Prop itemEdgeInsets: CYLEdgeInsets = { top: 0, left: 0, bottom: 0, right: 0 };
  /** [EN] CYLTabBarControllerTitlePositionAdjustment (vp); an item's own adjustment wins. [CN] 全部标题的位置偏移；Tab 自己的偏移优先。 */
  @Prop titlePositionAdjustment: CYLTitleOffset = { horizontal: 0, vertical: 0 };
  /** [EN] unloadsUnselectedViewsOnMemoryWarning (#426). [CN] 内存警告时卸载未选中 Tab 的页面（#426）。 */
  @Prop unloadsUnselectedViewsOnMemoryWarning: boolean = false;
  /**
   * [EN] -didReceiveMemoryWarning: called after each memory warning with the tabs whose pages were unloaded and the
   *      ones still loaded (CYLSimulateMemoryWarningReport).
   * [CN] 每次内存警告后调用，参数为被卸载页面的 Tab 与仍保留的 Tab。
   */
  onMemoryWarning?: (unloaded: number[], loaded: number[]) => void;
  @StorageProp('cyl_memoryWarning') @Watch('cylOnMemoryWarning') private memoryWarning: number = 0;
  /** [EN] CYLTabBarControllerTabBarItemAnimationSpeed (Lottie). [CN] Lottie 动画速度。 */
  tabBarItemAnimationSpeed: number = 1;
  /**
   * [EN] -cyl_coverVisiableTabImageViewOrTabButton:...: an image covering a whole tab button (index -> image), as the
   *      Example's Taobao-style Home cover; undefined: none.
   * [CN] 覆盖整个 Tab 按钮的图片（索引 -> 图片），如示例中仿淘宝的首页封面；undefined 表示无。
   */
  @Prop tabCoverImages: (ResourceStr | undefined)[] = [];
  @State private replayTokens: number[] = [];
  imageSize: number = 26;
  /**
   * [EN] -[CYLTabBarController cyl_loginRequiredTabBarItemIdentifiers] (issue #19): tabs that need a login. While
   *      loggedIn is false, selecting one calls presentLogin instead; it is selected when the completion gets true.
   * [CN] 需要登录的 Tab（issue #19）。未登录时选中它们会调用 presentLogin；completion 传 true 后才选中。
   */
  @Prop loginRequiredTabBarItemIdentifiers: string[] = [];
  /** [EN] cyl_loggedIn. [CN] 是否已登录。 */
  @Prop loggedIn: boolean = true;
  /** [EN] cyl_presentLoginBlock: shows the login UI, then calls completion(true) when logged in. [CN] 显示登录界面，登录后调用 completion(true)。 */
  presentLogin?: (index: number, identifier: string, completion: (loggedIn: boolean) => void) => void;
  /** [EN] cyl_loggedIn setter / CYLTabBarLoginStateDidChangeNotification: the login completed. [CN] 登录状态变化。 */
  loginStateDidChange?: (loggedIn: boolean) => void;
  /** [EN] cyl_tabButtonTapAnimationType: played on the tapped tab's icon. [CN] 点击 Tab 时图标播放的动画。 */
  @Prop tapAnimationType: CYLTabButtonTapAnimationType = CYLTabButtonTapAnimationType.None;
  /** [EN] cyl_tabButtonHapticFeedbackEnabled (needs ohos.permission.VIBRATE). [CN] 点击时触感反馈（需 ohos.permission.VIBRATE）。 */
  @Prop hapticFeedbackEnabled: boolean = false;
  /** [EN] cyl_tabButtonHapticFeedbackStyle. [CN] 触感强度。 */
  @Prop hapticFeedbackStyle: CYLImpactFeedbackStyle = CYLImpactFeedbackStyle.Medium;
  /**
   * [EN] cyl_didLongPressControlBlock / -tabBarController:didLongPressControl: (issue #535): a long press on a tab (its
   *      index) or on the plus button (CYLPlusButtonPageIndex).
   * [CN] 长按 Tab（其索引）或加号按钮（CYLPlusButtonPageIndex）。
   */
  didLongPress?: (index: number, identifier: string) => void;
  /** [EN] cyl_tabBarItemLongPressDuration (ms), 500 by default. [CN] 长按时长（毫秒），默认 500。 */
  @Prop longPressDuration: number = 500;
  /** [EN] cyl_doubleTapBlock (issue #152): a second tap on a tab within doubleTapInterval. [CN] 在间隔内再次点击同一 Tab。 */
  didDoubleTap?: (index: number, identifier: string) => void;
  /** [EN] cyl_tabBarItemDoubleTapInterval (ms), 300 by default. [CN] 双击间隔（毫秒），默认 300。 */
  @Prop doubleTapInterval: number = 300;
  /** [EN] cyl_swipeToSwitchTabEnabled: swipe the page left / right for the next / previous tab. [CN] 左右滑动页面切换到下一个 / 上一个 Tab。 */
  @Prop swipeToSwitchTabEnabled: boolean = false;
  @State private tapScale: number[] = [];
  @State private tapAngle: number[] = [];
  @State private tapFlip: number[] = [];
  @State private tapOffset: number[] = [];
  private lastTapIndex: number = -2;
  private lastTapTime: number = 0;
  /**
   * [EN] CYLTabBarSlideTransitionAnimator: the new page slides in from the side of its tab (duration ms; 0 off).
   * [CN] 新页面从其 Tab 所在一侧滑入（时长毫秒；0 关闭）。
   */
  @Prop slideTransitionDuration: number = 0;
  @State private slideOffset: number = 0;
  @StorageProp('cyl_colorMode') private colorMode: string = 'light';
  /**
   * [EN] -tabBarController:didSelectControl:: every reported tap, with the index selected before it (a re-tap has
   *      previous === index).
   * [CN] 每次点击后调用，附点击前的选中索引（再次点击时 previous === index）。
   */
  didSelectControl?: (index: number, previous: number) => void;
  /** [EN] cyl_tabBarMinimizeBehavior (issue #13). [CN] 滚动时 TabBar 的反应。 */
  @Prop tabBarMinimizeBehavior: CYLTabBarMinimizeBehavior = CYLTabBarMinimizeBehavior.Never;
  /** [EN] cyl_hidesTabBarOnScroll: OnScrollDown when on (Automatic means OnScrollDown here). [CN] 开启时等同 OnScrollDown。 */
  @Prop hidesTabBarOnScroll: boolean = false;
  @State private scrollHidden: boolean = false;
  @StorageProp('cyl_scrollDelta') @Watch('cylOnScroll') private scrollDelta: number = 0;
  @StorageProp('cyl_selectRequest') @Watch('cylOnSelectRequest') private selectRequest: string = '';
  /** [EN] cyl_tabButtonTapSoundEnabled. [CN] 点击时播放音效。 */
  @Prop tapSoundEnabled: boolean = false;
  /** [EN] cyl_tabButtonTapSoundURL: a rawfile path. [CN] 音效的 rawfile 路径。 */
  @Prop tapSoundPath: string = 'cyl_tap_click.wav';
  shouldSelect?: (index: number, identifier: string) => boolean;
  didSelect?: (index: number, identifier: string) => void;
  plusButtonAction?: () => void;
  @BuilderParam pageBuilder: (index: number, identifier: string) => void = this.cylEmptyPage;
  @State private loaded: number[] = [];
  @State private plusPressed: boolean = false;

  @Builder
  cylEmptyPage(index: number, identifier: string) {
  }

  aboutToAppear(): void {
    this.loaded = [this.selectedIndex];
    while (this.badges.length < this.tabBarItemsAttributes.length) {
      this.badges.push(new CYLBadge());
    }
  }

  /**
   * [EN] -setSelectedIndex: through the delegate: shouldSelect may refuse; didSelect follows.
   * [CN] 经过代理设置选中索引：shouldSelect 可拒绝；随后调用 didSelect。
   */
  cylOnScroll(): void {
    let behavior = this.tabBarMinimizeBehavior;
    if (this.hidesTabBarOnScroll && (behavior === CYLTabBarMinimizeBehavior.Never || behavior === CYLTabBarMinimizeBehavior.Automatic)) {
      behavior = CYLTabBarMinimizeBehavior.OnScrollDown;
    }
    if (behavior === CYLTabBarMinimizeBehavior.Never || behavior === CYLTabBarMinimizeBehavior.Automatic) {
      this.scrollHidden = false;
      return;
    }
    const delta = this.scrollDelta;
    if (Math.abs(delta) < 2) {
      return;
    }
    const down = delta > 0;
    this.scrollHidden = behavior === CYLTabBarMinimizeBehavior.OnScrollDown ? down : !down;
  }

  cylOnSelectRequest(): void {
    const request = this.selectRequest.split('#')[0];
    if (request.length === 0) {
      return;
    }
    if (request.startsWith('id:')) {
      const identifier = request.substring(3);
      const index = this.tabBarItemsAttributes.findIndex((item: CYLTabBarItemAttributes) => item.identifier === identifier);
      if (index >= 0) {
        this.cylSelect(index);
      }
    } else {
      const index = Number.parseInt(request, 10);
      if (index >= 0 && index < this.tabBarItemsAttributes.length) {
        this.cylSelect(index);
      }
    }
  }

  cylOnMemoryWarning(): void {
    let unloaded: number[] = [];
    if (this.unloadsUnselectedViewsOnMemoryWarning) {
      unloaded = this.loaded.filter((index: number) => index !== this.selectedIndex);
      this.loaded = [this.selectedIndex];
    }
    if (this.onMemoryWarning !== undefined) {
      this.onMemoryWarning(unloaded, this.loaded.slice());
    }
  }

  /** [EN] The tap animation and the haptic of a tab button. [CN] Tab 按钮的点击动画与触感。 */
  cylTapFeedback(index: number): void {
    if (this.tapSoundEnabled) {
      cylPlayTapSound(this.getUIContext().getHostContext() as Context, this.tapSoundPath).catch(() => {});
    }
    if (this.hapticFeedbackEnabled) {
      const effects = ['haptic.clock.timer', 'haptic.effect.soft', 'haptic.effect.hard'];
      try {
        vibrator.startVibration({ type: 'preset', effectId: effects[this.hapticFeedbackStyle], count: 1 },
          { id: 0, usage: 'touch' }).catch(() => {});
      } catch (e) {
        // [EN] No vibrator or no permission. [CN] 没有振动器或没有权限。
      }
    }
    if (index < 0 || this.tapAnimationType === CYLTabButtonTapAnimationType.None) {
      return;
    }
    const set = (values: number[], value: number): number[] => {
      const copy = values.slice();
      copy[index] = value;
      return copy;
    };
    switch (this.tapAnimationType) {
      case CYLTabButtonTapAnimationType.Scale:
        this.tapScale = set(this.tapScale, 0.6);
        animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.tapScale = set(this.tapScale, 1); });
        break;
      case CYLTabButtonTapAnimationType.ZoomIn:
        this.tapScale = set(this.tapScale, 1.4);
        animateTo({ duration: 300, curve: Curve.EaseOut }, () => { this.tapScale = set(this.tapScale, 1); });
        break;
      case CYLTabButtonTapAnimationType.Bounce:
        this.tapOffset = set(this.tapOffset, -10);
        animateTo({ duration: 400, curve: curves.springMotion(0.4, 0.4) }, () => { this.tapOffset = set(this.tapOffset, 0); });
        break;
      case CYLTabButtonTapAnimationType.Rotation:
        this.tapAngle = set(this.tapAngle, 0);
        animateTo({ duration: 400 }, () => { this.tapAngle = set(this.tapAngle, 360); });
        break;
      case CYLTabButtonTapAnimationType.Flip:
        this.tapFlip = set(this.tapFlip, 0);
        animateTo({ duration: 400 }, () => { this.tapFlip = set(this.tapFlip, 180); });
        break;
      default:
        break;
    }
  }

  /** [EN] A tap on a tab button: double tap, feedback, then selection. [CN] 点击 Tab：双击检测、反馈，然后选中。 */
  cylTap(index: number): void {
    const now = Date.now();
    if (index === this.lastTapIndex && now - this.lastTapTime <= this.doubleTapInterval && this.didDoubleTap !== undefined) {
      this.lastTapIndex = -2;
      this.didDoubleTap(index, this.cylIdentifier(index));
    } else {
      this.lastTapIndex = index;
      this.lastTapTime = now;
    }
    this.cylTapFeedback(index);
    const previous = this.selectedIndex;
    this.cylSelect(index);
    if (this.didSelectControl !== undefined) {
      this.didSelectControl(index, previous);
    }
  }

  /** [EN] -cyl_selectNextTab / -cyl_selectPreviousTab (step 1 / -1), wrapping around. [CN] 选中下一个 / 上一个 Tab（循环）。 */
  cylSelectNeighbor(step: number): void {
    const count = this.tabBarItemsAttributes.length;
    if (count === 0) {
      return;
    }
    const from = this.selectedIndex < 0 ? 0 : this.selectedIndex;
    this.cylSelect((from + step + count) % count);
  }

  cylSelect(index: number): void {
    const identifier = this.cylIdentifier(index);
    if (this.shouldSelect !== undefined && !this.shouldSelect(index, identifier)) {
      return;
    }
    if (!this.loggedIn && this.loginRequiredTabBarItemIdentifiers.indexOf(identifier) >= 0) {
      if (this.presentLogin !== undefined) {
        this.presentLogin(index, identifier, (loggedIn: boolean) => {
          if (loggedIn) {
            if (this.loginStateDidChange !== undefined) {
              this.loginStateDidChange(true);
            }
            this.cylDoSelect(index, identifier);
          }
        });
      }
      return;
    }
    this.cylDoSelect(index, identifier);
  }

  private cylDoSelect(index: number, identifier: string): void {
    if (this.slideTransitionDuration > 0 && index !== this.selectedIndex && index >= 0 && this.selectedIndex >= 0) {
      this.slideOffset = index > this.selectedIndex ? 100 : -100;
      animateTo({ duration: this.slideTransitionDuration, curve: Curve.EaseOut }, () => { this.slideOffset = 0; });
    }
    if (index === this.selectedIndex && index >= 0) {
      // [EN] A re-tap replays the Lottie icon (#433). [CN] 再次点击重播 Lottie 图标（#433）。
      const tokens = this.replayTokens.slice();
      tokens[index] = (tokens[index] ?? 0) + 1;
      this.replayTokens = tokens;
    }
    if (this.loaded.indexOf(index) < 0) {
      this.loaded = this.loaded.concat([index]);
    }
    this.selectedIndex = index;
    if (this.didSelect !== undefined) {
      this.didSelect(index, identifier);
    }
  }

  /** [EN] The icon of a tab: GIF, then URL, then the images. [CN] Tab 图标：GIF 优先，其次网络图片，最后本地图片。 */
  cylIcon(index: number): ResourceStr | undefined {
    const item = this.tabBarItemsAttributes[index];
    if (item.gifFilePath !== undefined) {
      return item.gifFilePath.startsWith('http') ? item.gifFilePath : $rawfile(item.gifFilePath);
    }
    const selected = this.selectedIndex === index;
    if (item.imageURL !== undefined) {
      return selected ? (item.selectedImageURL ?? item.imageURL) : item.imageURL;
    }
    if (this.colorMode === 'dark') {
      if (selected && item.darkSelectedImage !== undefined) {
        return item.darkSelectedImage;
      }
      if (!selected && item.darkImage !== undefined) {
        return item.darkImage;
      }
    }
    return selected ? (item.selectedImage ?? item.image) : item.image;
  }

  /**
   * [EN] The accessibility label of a tab: its title (the shown one) and its badge, e.g. "Messages, 99+ new messages".
   * [CN] Tab 的无障碍标签：标题与角标。
   */
  cylAccessibilityLabel(index: number): string {
    const item = this.tabBarItemsAttributes[index];
    const title = cyl_textOf(this.selectedIndex === index ? (item.selectedTitle ?? item.title) : item.title);
    const label = title.length > 0 ? title : (item.identifier ?? `${index + 1}`);
    const badge = cyl_badgeAccessibilityText(this.badges[index]);
    return badge.length > 0 ? CYLLocalizedString('%@, %@', label, badge) : label;
  }

  /** [EN] The accessibility description: role, position and the selected state. [CN] 无障碍描述：角色、位置与选中状态。 */
  cylAccessibilityDescription(index: number): string {
    const position = CYLLocalizedString('Tab, %1$@ of %2$@', index + 1, this.tabBarItemsAttributes.length);
    return this.selectedIndex === index ? CYLLocalizedString('%@, %@', position, CYLLocalizedString('选中')) : position;
  }

  /** [EN] The plus button's label: its title or "Plus button", and its badge. [CN] 加号按钮的标签。 */
  cylPlusAccessibilityLabel(): string {
    const title = cyl_textOf(this.plusButton?.title);
    const label = title.length > 0 ? title : CYLLocalizedString('加号按钮');
    const badge = cyl_badgeAccessibilityText(this.plusButtonBadge);
    return badge.length > 0 ? CYLLocalizedString('%@, %@', label, badge) : label;
  }

  cylIdentifier(index: number): string {
    if (index === CYLPlusButtonPageIndex) {
      return this.plusButton?.identifier ?? 'plus';
    }
    const item = this.tabBarItemsAttributes[index];
    return item?.identifier ?? `${index}`;
  }

  cylSlots(): CYLSlot[] {
    const slots: CYLSlot[] = this.tabBarItemsAttributes.map((item: CYLTabBarItemAttributes, i: number) => new CYLSlot(i, `tab-${i}`));
    if (this.plusButton !== undefined) {
      const at = this.plusButton.index ?? Math.floor(slots.length / 2);
      slots.splice(Math.max(0, Math.min(at, slots.length)), 0, new CYLSlot(-1, 'plus'));
    }
    return slots;
  }

  cylPages(): number[] {
    const pages: number[] = this.tabBarItemsAttributes.map((item: CYLTabBarItemAttributes, i: number) => i);
    if (this.plusButton?.selectable) {
      pages.push(CYLPlusButtonPageIndex);
    }
    return pages;
  }

  @Builder
  cylTab(index: number) {
    Column() {
      if (this.tabCoverImages[index] !== undefined) {
        Image(this.tabCoverImages[index])
          .height(this.tabBarHeight - 4)
          .objectFit(ImageFit.Contain)
          .id(`cyl-cover-${this.cylIdentifier(index)}`)
      } else {
      Stack() {
        if (this.tabBarItemsAttributes[index].lottieFilePath !== undefined
          && this.tabBarItemsAttributes[index].gifFilePath === undefined
          && this.tabBarItemsAttributes[index].imageURL === undefined) {
          CYLLottieIcon({
            path: this.colorMode === 'dark' && this.tabBarItemsAttributes[index].lottieDarkFilePath !== undefined
              ? this.tabBarItemsAttributes[index].lottieDarkFilePath : this.tabBarItemsAttributes[index].lottieFilePath,
            iconSize: this.tabBarItemsAttributes[index].lottieSize ?? this.imageSize,
            speed: this.tabBarItemAnimationSpeed,
            selected: this.selectedIndex === index,
            replayToken: this.replayTokens[index] ?? 0,
          })
        } else {
        Image(this.cylIcon(index))
          .width(this.imageSize)
          .height(this.imageSize)
          .objectFit(ImageFit.Contain)
          .scale({ x: this.tapScale[index] ?? 1, y: this.tapScale[index] ?? 1 })
          .rotate({ z: 1, angle: this.tapAngle[index] ?? 0 })
          .rotate({ y: 1, angle: this.tapFlip[index] ?? 0 })
          .translate({ y: this.tapOffset[index] ?? 0 })
        }
        CYLBadgeView({ badge: this.badges[index], anchorWidth: this.imageSize })
      }
      .width(this.imageSize)
      .height(this.imageSize)
      // [EN] FIX (HarmonyOS screenshot issue 3): the icon is centered in its frame (a smaller Lottie or SVGA icon too),
      //      so icon and title share one vertical center line; the badge is positioned absolutely and does not move.
      // [CN] 修复（鸿蒙截图问题 3）：图标在其框内居中（较小的 Lottie 或 SVGA 图标也一样），使图标与标题位于同一条竖直中心线；
      //      角标为绝对定位，不受影响。
      .alignContent(Alignment.Center)

      if (this.tabBarItemsAttributes[index].title !== undefined) {
        Text(this.selectedIndex === index
          ? (this.tabBarItemsAttributes[index].selectedTitle ?? this.tabBarItemsAttributes[index].title)
          : this.tabBarItemsAttributes[index].title)
          .fontSize(10)
          .height(13)
          .maxLines(1)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 3 })
          .fontColor(this.selectedIndex === index
            ? (this.tabBarItemsAttributes[index].selectedTitleColor ?? this.tintColor)
            : (this.tabBarItemsAttributes[index].titleColor ?? this.unselectedColor))
          .offset({
            x: (this.tabBarItemsAttributes[index].titlePositionAdjustment ?? this.titlePositionAdjustment).horizontal,
            y: (this.tabBarItemsAttributes[index].titlePositionAdjustment ?? this.titlePositionAdjustment).vertical,
          })
      }
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.selectedIndex === index
      ? (this.tabBarItemsAttributes[index].selectedBackgroundColor ?? Color.Transparent)
      : (this.tabBarItemsAttributes[index].backgroundColor ?? Color.Transparent))
    // [EN] FIX (HarmonyOS screenshot issue 6): on the Liquid Glass capsule an item's background is a capsule too, so the
    //      first and last items' backgrounds no longer stick out of the bar's rounded ends.
    // [CN] 修复（鸿蒙截图问题 6）：在液态玻璃胶囊上，item 背景也是胶囊形，首尾 item 的背景不再超出 TabBar 的圆角两端。
    .borderRadius(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? this.tabBarHeight / 2 : 0)
    // [EN] One accessibility element per tab: icon, cover, Lottie and badge are read through it. [CN] 每个 Tab 一个无障碍元素。
    .accessibilityGroup(true)
    .accessibilityText(this.cylAccessibilityLabel(index))
    .accessibilityDescription(this.cylAccessibilityDescription(index))
    .id(`cyl-tab-${this.cylIdentifier(index)}`)
    .gesture(GestureGroup(GestureMode.Exclusive,
      LongPressGesture({ duration: this.longPressDuration }).onAction(() => {
        if (this.didLongPress !== undefined) {
          this.didLongPress(index, this.cylIdentifier(index));
        }
      }),
      TapGesture().onAction(() => this.cylTap(index))))
  }

  /**
   * [EN] Issue #91: the touchable area, scaled around the center by touchableAreaScale, then grown by touchableAreaOutsets.
   * [CN] Issue #91：可点击区域，先按 touchableAreaScale 绕中心缩放，再按 touchableAreaOutsets 扩大。
   */
  cylPlusResponseRegion(): Rectangle {
    const scale = Math.max(0.1, this.plusButton?.touchableAreaScale ?? 1);
    const extra = (scale - 1) / 2;
    return {
      x: `${-extra * 100}%`, y: `${-extra * 100}%`, width: `${scale * 100}%`, height: `${scale * 100}%`,
    };
  }

  @Builder
  cylTouchableArea() {
    Column()
      .width(`${Math.max(0.1, this.plusButton?.touchableAreaScale ?? 1) * 100}%`)
      .height(`${Math.max(0.1, this.plusButton?.touchableAreaScale ?? 1) * 100}%`)
      .backgroundColor(this.plusButton?.touchableAreaColor ?? '#4DFF0000')
      .hitTestBehavior(HitTestMode.Transparent)
      .accessibilityLevel('no')
      .id('cyl-plus-touchable-area')
  }

  /**
   * [EN] FIX (HarmonyOS screenshot issue 3): the top of a tab's title, the same for the tabs and the plus button. A tab
   *      centers its icon, a 3 vp gap and its title (about 13 vp for 10 fp text) in the bar; the plus button's aligned
   *      title used `tabBarHeight - 17` instead and sat lower than the other titles.
   * [CN] 修复（鸿蒙截图问题 3）：Tab 标题的顶部，Tab 与 PlusButton 相同。Tab 在 TabBar 中居中排列图标、3 vp 间距与标题（10 fp 文字约
   *      13 vp）；PlusButton 对齐的标题此前使用 `tabBarHeight - 17`，比其他标题低。
   */
  cylTitleTop(): number {
    return (this.tabBarHeight - (this.imageSize + 3 + 13)) / 2 + this.imageSize + 3;
  }

  cylPlusAlignsTitle(): boolean {
    return this.plusButton?.title !== undefined && this.plusButton?.alignsTitle !== false;
  }

  @Builder
  cylPlus() {
    Column() {
      Stack() {
        if (this.plusButton?.backgroundImage !== undefined) {
          Image(this.plusButton.backgroundImage)
            .width(this.plusButton?.imageSize ?? 54)
            .height(this.plusButton?.imageSize ?? 54)
            .objectFit(ImageFit.Contain)
        }
        // [EN] Item 31: no image yet keeps the layout (the slot stays). [CN] 第 31 项：尚无图片时布局不变。
        Image(this.plusPressed || this.selectedIndex === CYLPlusButtonPageIndex
          ? (this.plusButton?.selectedImage ?? this.plusButton?.image) : this.plusButton?.image)
          .width(this.plusButton?.imageSize ?? 54)
          .height(this.plusButton?.imageSize ?? 54)
          .objectFit(ImageFit.Contain)
        CYLBadgeView({ badge: this.plusButtonBadge, anchorWidth: this.plusButton?.imageSize ?? 54 })
      }
      // [EN] As CYLPlusButton.kt: with an aligned title the image sits right above the title (item 4); otherwise it is
      //      centred and moved by centerYOffset. [CN] 与 CYLPlusButton.kt 相同：标题对齐时图片紧贴标题上方（第 4 项）；否则居中并按 centerYOffset 移动。
      .position(this.cylPlusAlignsTitle()
        ? { x: 0, y: this.cylTitleTop() - (this.plusButton?.imageSize ?? 54) } : undefined)
      .width(this.cylPlusAlignsTitle() ? '100%' : undefined)
      .offset({ y: this.cylPlusAlignsTitle() ? 0 : (this.plusButton?.centerYOffset ?? 0) })

      if (this.plusButton?.title !== undefined) {
        Text(this.plusButton.title)
          .fontSize(10)
          .height(13)
          .maxLines(1)
          .fontColor(this.selectedIndex === CYLPlusButtonPageIndex
            ? (this.plusButtonTitleSelectedColor ?? this.tintColor) : this.unselectedColor)
          .position(this.plusButton?.alignsTitle === false ? undefined : { x: 0, y: this.cylTitleTop() })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .accessibilityGroup(true)
    .accessibilityText(this.cylPlusAccessibilityLabel())
    .accessibilityDescription(this.selectedIndex === CYLPlusButtonPageIndex ? CYLLocalizedString('选中') : CYLLocalizedString('Double tap to open'))
    .responseRegion(this.cylPlusResponseRegion())
    .overlay(this.plusButton?.showsTouchableArea ? this.cylTouchableArea : undefined)
    .id('cyl-plus-button')
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.plusPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.plusPressed = false;
      }
    })
    .gesture(LongPressGesture({ duration: this.longPressDuration }).onAction(() => {
      if (this.didLongPress !== undefined) {
        this.didLongPress(CYLPlusButtonPageIndex, this.cylIdentifier(CYLPlusButtonPageIndex));
      }
    }))
    .onClick(() => {
      this.cylTapFeedback(CYLPlusButtonPageIndex);
      if (this.plusButton?.selectable) {
        this.cylSelect(CYLPlusButtonPageIndex);
      }
      if (this.plusButtonAction !== undefined) {
        this.plusButtonAction();
      }
    })
  }

  build() {
    Column() {
      Stack() {
        ForEach(this.cylPages(), (index: number) => {
          if (this.loaded.indexOf(index) >= 0) {
            Column() {
              this.pageBuilder(index, this.cylIdentifier(index))
            }
            .width('100%')
            .height('100%')
            .translate({ x: this.selectedIndex === index ? `${this.slideOffset}%` : 0 })
            .visibility(this.selectedIndex === index ? Visibility.Visible : Visibility.Hidden)
          }
        }, (index: number) => `page-${index}`)
      }
      .layoutWeight(1)
      .width('100%')
      .gesture(PanGesture({ direction: PanDirection.Horizontal, distance: 40 })
        .onActionEnd((event: GestureEvent) => {
          if (this.swipeToSwitchTabEnabled && Math.abs(event.offsetX) > 60) {
            this.cylSelectNeighbor(event.offsetX < 0 ? 1 : -1);
          }
        }), GestureMask.Normal)

      if (!this.tabBarHidden && !this.scrollHidden) {
        // [EN] A container that insets the floating Liquid Glass capsule (16 vp at the sides, 8 vp above the gesture bar);
        //      the classic and FlatDesign bars fill it and reach under the gesture bar.
        // [CN] 容器：为悬浮的液态玻璃胶囊留出边距（两侧 16 vp，距手势条 8 vp）；经典与扁平样式铺满并延伸到手势条下方。
        Column() {
        Row() {
          ForEach(this.cylSlots(), (slot: CYLSlot) => {
            if (slot.tabIndex >= 0) {
              this.cylTab(slot.tabIndex)
            } else {
              this.cylPlus()
            }
          }, (slot: CYLSlot) => slot.key)
        }
        .width('100%')
        .height(this.tabBarHeight)
        .backgroundColor(this.tabBarBackgroundColor)
        .border({ width: { top: 0.5 }, color: { top: this.tabBarShadowColor } })
        .attributeModifier(cyl_tabBarStyleModifier(this.tabBarStyleType, this.barTintColor, this.tabBarHeight))
        .padding({ left: this.itemEdgeInsets.left, right: this.itemEdgeInsets.right })
        .expandSafeArea(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? [] : [SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .id('cyl-tab-bar')
        }
        .width('100%')
        .padding(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? { left: 16, right: 16, bottom: 8 } : 0)
        // [EN] The bar color continues under the gesture bar (classic and FlatDesign); clear around the Liquid Glass capsule.
        // [CN] 经典与扁平样式的 TabBar 颜色延伸到手势条下方；液态玻璃胶囊四周透明。
        .backgroundColor(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? Color.Transparent
          : (this.tabBarStyleType === CYLTabBarStyleType.FlatDesign ? (this.barTintColor ?? '#F9F9F9') : this.tabBarBackgroundColor))
        .expandSafeArea(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? [] : [SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM)
          .animation({ duration: this.tabBarHiddenAnimated ? 250 : 0 }))
        .id('cyl-tab-bar-container')
      }
    }
    .width('100%')
    .height('100%')
  }
}
