import { CYLTabBarStyleType, cyl_tabBarStyleModifier } from './CYLFlatDesignTabBar';
import { CYLLiquidGlassTokens, CYLLiquidGlassCapsuleModifier, CYLLiquidGlassContainerModifier } from './CYLLiquidGlass';
import { curves, window, KeyboardAvoidMode } from '@kit.ArkUI';
import { CYLTabBarItemAttributes, CYLTitleOffset } from './CYLTabBarItem';
import { CYLPlusButton, cyl_liquidGlassContentDy } from './CYLPlusButton';
import { CYLBadge, CYLBadgeView } from './CYLBadge';
import { CYLLottieIcon } from './CYLLottieIcon';
import { CYLSVGAView } from './svga/CYLSVGAView';
import { CYLRiveIcon, cylRiveIsSupported } from './CYLRiveTabBarItemAnimator';
import { CYLAnimatedItemView, CYLAnimatedItemAnimationContext, CYLAnimatedItemEngines } from 'cylanimateditem';
import { CYLLocalizedString, cyl_textOf } from './CYLLocalization';
import { CYLTabButtonAnimation, CYLTabButtonProperty, CYLTabButtonView, CYLTabButtonViewImpl } from './CYLTabButtonAnimation';

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

/** [EN] AppStorage key bumped by cyl_restoreTabBar. [CN] cyl_restoreTabBar 递增的 AppStorage 键。 */
export const CYLRestoreTabBarStorageKey: string = 'cyl_restoreTabBar';

/**
 * [EN] Shows a tab bar that scrolling hid, after an interruption (a dialog, a push and pop, the page shown again, the app
 *      back in the foreground; iOS -cyl_restoreTabBarAfterInterruption, issue #13). Scrolling right after it (a fling's
 *      inertia) does not hide the bar again; only a new scroll after 600 ms does.
 * [CN] 意外情况（弹窗、push 后 pop、页面重新显示、App 回到前台）后恢复被滚动隐藏的 TabBar（issue #13）。紧随其后的滚动（惯性）
 *      不会再次隐藏，600 毫秒后的新滚动才会。
 */
export function cyl_restoreTabBar(): void {
  AppStorage.setOrCreate<number>(CYLRestoreTabBarStorageKey, (AppStorage.get<number>(CYLRestoreTabBarStorageKey) ?? 0) + 1);
}

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
  /** [EN] CYLTabBarControllerPlusButton; a new object updates the plus button in place (issue list #7). [CN] 新对象即原地更新加号按钮。 */
  @Prop plusButton: CYLPlusButton | undefined = undefined;
  @Link @Watch('cylOnSelectedIndexChange') selectedIndex: number;
  /** [EN] The badge of each tab (-[UIView cyl_showBadgeValue:] on its tab button); created when unset. [CN] 每个 Tab 的角标；未设置时自动创建。 */
  @State @Watch('cylOnBadgesChange') badges: CYLBadge[] = [];
  /** [EN] The plus button's badge. [CN] 加号按钮的角标。 */
  @State plusButtonBadge: CYLBadge = new CYLBadge();
  @Prop @Watch('cylOnTabBarHiddenChange') tabBarHidden: boolean = false;
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
   * [EN] `-[CYLFlatDesignTabBar backgroundImage]`: a FlatDesign bar's image, tiled, in place of its blur; undefined for none.
   * [CN] 扁平样式 TabBar 的背景图（平铺），代替模糊；undefined 表示无。
   */
  @Prop barBackgroundImage: ResourceStr | undefined = undefined;
  /**
   * [EN] `-[CYLFlatDesignTabBar shadowImage]`: an image drawn as the bar's top line instead of the 0.5 vp shadow color.
   * [CN] 作为 TabBar 顶部线条绘制的图片，代替 0.5 vp 的阴影色。
   */
  @Prop shadowImage: ResourceStr | undefined = undefined;
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
   * [EN] tabBarItemAnimationLoops: the selected tab's Rive icon plays again after each pass until this is turned off,
   *      also while playing (docs/Animated-Item.md, the Rive loop); off by default.
   * [CN] tabBarItemAnimationLoops：选中 Tab 的 Rive 图标每次播放后再次播放，直到关闭，播放中也立即生效；默认关闭。
   */
  @Prop tabBarItemAnimationLoops: boolean = false;
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
  /**
   * [EN] cyl_tabButtonAnimation (issue #535): a CYLTabButtonAnimation played on the tab buttons (select, deselect,
   *      reselect, press, badge change); it replaces tapAnimationType. [CN] Tab 按钮的点击动画对象；设置后替代 tapAnimationType。
   */
  tabButtonAnimation?: CYLTabButtonAnimation;
  @State private tapFlipX: number[] = [];
  @State private tapTitleOpacity: number[] = [];
  @State private tapTitleScale: number[] = [];
  @State private tapBadgeScale: number[] = [];
  @State private tapFrameImages: (ResourceStr | undefined)[] = [];
  @State private tapFireworks: number[] = [];
  @State private tapFireworkImages: (ResourceStr | undefined)[] = [];
  private lastTapIndex: number = -2;
  /** [EN] The tab whose long press just fired: its click is not a tap. [CN] 刚触发长按的 Tab：其 click 不算点击。 */
  private cylLongPressedIndex: number = -2;
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
  @Prop @Watch('cylRestoreFromScroll') tabBarMinimizeBehavior: CYLTabBarMinimizeBehavior = CYLTabBarMinimizeBehavior.Never;
  /** [EN] cyl_hidesTabBarOnScroll: OnScrollDown when on (Automatic means OnScrollDown here). [CN] 开启时等同 OnScrollDown。 */
  @Prop @Watch('cylRestoreFromScroll') hidesTabBarOnScroll: boolean = false;
  @State private scrollHidden: boolean = false;
  /**
   * [EN] Liquid Glass minimized by scrolling (CYLLiquidGlass.ets): the capsule is a ball with the selected tab; scrolling the
   *      other way or tapping the ball expands it. The other styles hide the bar instead (`scrollHidden`).
   * [CN] 液态玻璃被滚动缩小（CYLLiquidGlass.ets）：胶囊变成只含选中 Tab 的球；反向滚动或点按球即展开。其他样式则隐藏 TabBar（`scrollHidden`）。
   */
  @State private glassCollapsed: boolean = false;
  /** [EN] The controller's width, for the Liquid Glass slots (vp). [CN] 控制器宽度，用于液态玻璃的槽位（vp）。 */
  @State private glassWidth: number = 0;
  /** [EN] The gesture bar's height (vp), so the capsule floats 24 vp above the screen's bottom. [CN] 手势条高度（vp），使胶囊距屏幕底部 24 vp。 */
  @State private glassGestureBarHeight: number = 0;
  /**
   * [EN] The Liquid Glass lens (iOS 26): its position in slots (fractional while it slides or follows a finger), its stretch
   *      along the motion (jelly), and how much it is lifted (pressed or dragged). Separate layers: no tab node is rebuilt.
   * [CN] 液态玻璃的镜片（iOS 26）：以槽位计的位置（滑动或跟随手指时为小数）、沿运动方向的拉伸（果冻效果）与抬起程度（按压或拖动）。
   *      独立图层：不重建任何 Tab 节点。
   */
  @State private glassLensPosition: number = -1;
  @State private glassLensStretch: number = 1;
  @State private glassLensLift: number = 0;
  private glassDragging: boolean = false;
  /** [EN] A finger is down on the capsule; pan updates after it lifts are ignored. [CN] 手指按在胶囊上；抬起后的拖动更新被忽略。 */
  private glassTouchActive: boolean = false;
  @StorageProp('cyl_scrollDelta') @Watch('cylOnScroll') private scrollDelta: number = 0;
  @StorageProp('cyl_restoreTabBar') @Watch('cylRestoreFromScroll') private restoreToken: number = 0;
  /** [EN] Scrolls until this time do not hide the bar (after a restore). [CN] 在此时间前的滚动不会隐藏 TabBar（恢复之后）。 */
  private cylIgnoreScrollUntil: number = 0;
  /**
   * [EN] Called when scrolling hides or shows the bar (true: shown), for apps and tests (iOS
   *      CYLTabBarMinimizeStateDidChangeNotification). [CN] 滚动隐藏或显示 TabBar 时调用（true 为显示）。
   */
  tabBarVisibilityDidChange?: (visible: boolean) => void;
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
  /**
   * [EN] Issue list #31: the keyboard is up and the page is resized for it (KeyboardAvoidMode other than OFFSET). The tab bar then
   *      leaves the layout instead of riding up on top of the keyboard: like iOS, it stays where it is, behind the keyboard.
   * [CN] 问题清单 #31：键盘弹出且页面为键盘缩小（避让模式不是 OFFSET）。此时 TabBar 退出布局，不随键盘上移：与 iOS 相同，留在原处被键盘遮住。
   */
  @State private keyboardCoversTabBar: boolean = false;
  private cylKeyboardWindow: window.Window | undefined = undefined;
  private cylKeyboardListener: (height: number) => void = (height: number) => {
    let mode = KeyboardAvoidMode.OFFSET;
    try {
      mode = this.getUIContext().getKeyboardAvoidMode();
    } catch (error) {
      mode = KeyboardAvoidMode.OFFSET;
    }
    // [EN] As iOS (restoreTabBar(for:) on UIKeyboardWillShowNotification): the keyboard coming up is an interruption that
    //      shows a scroll-hidden bar again; its going away is not.
    // [CN] 与 iOS 相同（UIKeyboardWillShowNotification）：键盘弹出是一次打断，会重新显示被滚动隐藏的 TabBar；键盘收起不算打断。
    if (height > 0 && !this.cylKeyboardShown && this.scrollHidden) {
      this.cylRestoreFromScroll();
    }
    this.cylKeyboardShown = height > 0;
    this.keyboardCoversTabBar = height > 0 && mode !== KeyboardAvoidMode.OFFSET;
  };
  private cylKeyboardShown: boolean = false;

  @Builder
  cylEmptyPage(index: number, identifier: string) {
  }

  aboutToAppear(): void {
    // [EN] cyltabbar plays Lottie (@ohos/lottie), Rive (@ohos/rive) and SVGA (its own player): CYLAnimatedItemView draws them.
    // [CN] cyltabbar 播放 Lottie、Rive 与 SVGA（自带播放器）：由 CYLAnimatedItemView 绘制。
    ['Lottie', 'Rive', 'SVGA'].forEach((type: string) => CYLAnimatedItemEngines.register(type));
    this.loaded = [this.selectedIndex];
    while (this.badges.length < this.tabBarItemsAttributes.length) {
      this.badges.push(new CYLBadge());
    }
    this.cylObserveKeyboard();
    // [EN] The Liquid Glass lens starts on the selected slot. [CN] 液态玻璃镜片从选中槽位开始。
    this.glassLensPosition = this.cylGlassSelectedSlot();
  }

  aboutToDisappear(): void {
    try {
      this.cylKeyboardWindow?.off('keyboardHeightChange', this.cylKeyboardListener);
    } catch (error) {
      // [EN] The window is already gone. [CN] 窗口已销毁。
    }
    this.cylKeyboardWindow = undefined;
  }

  /**
   * [EN] Follows the keyboard height of the window (issue list #31). [CN] 监听窗口的键盘高度（问题清单 #31）。
   */
  private cylObserveKeyboard(): void {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return;
    }
    window.getLastWindow(context).then((found: window.Window) => {
      this.cylKeyboardWindow = found;
      found.on('keyboardHeightChange', this.cylKeyboardListener);
      try {
        const area = found.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        this.glassGestureBarHeight = this.getUIContext().px2vp(area.bottomRect.height);
      } catch (error) {
        this.glassGestureBarHeight = 0;
      }
    }).catch(() => {
      // [EN] No window (e.g. the previewer): the bar keeps its normal layout. [CN] 没有窗口（如预览器）：TabBar 保持普通布局。
    });
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
    const hidden = behavior === CYLTabBarMinimizeBehavior.OnScrollDown ? down : !down;
    if (hidden && Date.now() < this.cylIgnoreScrollUntil) {
      return;
    }
    this.cylSetScrollHidden(hidden);
  }

  private cylSetScrollHidden(hidden: boolean): void {
    if (this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass) {
      // [EN] Liquid Glass minimizes into a ball instead of leaving the screen (iOS 26). [CN] 液态玻璃缩小成球，而不是离开屏幕（iOS 26）。
      this.cylSetGlassCollapsed(hidden);
      return;
    }
    if (this.scrollHidden === hidden) {
      return;
    }
    this.scrollHidden = hidden;
    if (this.tabBarVisibilityDidChange !== undefined) {
      this.tabBarVisibilityDidChange(!hidden);
    }
  }

  /**
   * [EN] The one entry of the Liquid Glass minimize morph, as the reference's setBarCollapsed: one animateTo flips
   *      glassCollapsed and every size, offset and opacity of the bar follows it. Only attributes change (no node is rebuilt),
   *      so Lottie, SVGA and Rive icons keep their views.
   * [CN] 液态玻璃缩小形变的唯一入口，与参考工程的 setBarCollapsed 相同：一个 animateTo 切换 glassCollapsed，TabBar 的尺寸、偏移与透明度
   *      都随之变化。只改变属性（不重建节点），Lottie、SVGA 与 Rive 图标保留各自的视图。
   */
  private cylSetGlassCollapsed(collapsed: boolean): void {
    if (this.glassCollapsed === collapsed) {
      return;
    }
    this.getUIContext().animateTo({ duration: CYLLiquidGlassTokens.MORPH_DURATION, curve: Curve.EaseInOut }, () => {
      this.glassCollapsed = collapsed;
    });
  }

  /** [EN] The slot position of the selected tab or plus button. [CN] 选中 Tab 或加号按钮的槽位序号。 */
  private cylGlassSelectedSlot(): number {
    return Math.max(0, this.cylSlots().findIndex((slot: CYLSlot) => slot.tabIndex === this.selectedIndex));
  }

  /**
   * [EN] Slides the lens to the selected slot like liquid: it stretches along the motion at once, travels on a spring and
   *      settles back to round (iOS 26 tab bar lens).
   * [CN] 像液体一样把镜片滑到选中槽位：先沿运动方向拉伸，再以弹簧曲线移动，最后回弹成圆（iOS 26 TabBar 镜片）。
   */
  private cylGlassMoveLens(): void {
    if (this.tabBarStyleType !== CYLTabBarStyleType.LiquidGlass || this.glassDragging) {
      return;
    }
    const target = this.cylGlassSelectedSlot();
    if (this.glassLensPosition < 0) {
      this.glassLensPosition = target;
      return;
    }
    const distance = Math.abs(target - this.glassLensPosition);
    if (distance < 0.01) {
      return;
    }
    const ui = this.getUIContext();
    ui.animateTo({ duration: 120, curve: Curve.EaseOut }, () => {
      this.glassLensStretch = 1 + Math.min(0.45, 0.18 * distance);
    });
    ui.animateTo({ curve: curves.interpolatingSpring(0, 1, 260, 22) }, () => {
      this.glassLensPosition = target;
    });
    setTimeout(() => {
      ui.animateTo({ curve: curves.interpolatingSpring(0, 1, 380, 14) }, () => {
        this.glassLensStretch = 1;
      });
    }, 140);
  }

  /** [EN] Lifts the lens and swells the capsule while touched (iOS 26 press). [CN] 触摸时抬起镜片并让胶囊微微膨胀（iOS 26 按压）。 */
  private cylGlassLift(lifted: boolean): void {
    this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 320, 16) }, () => {
      this.glassLensLift = lifted ? 1 : 0;
    });
  }

  /** [EN] The slot under a finger at x (vp, inside the capsule). [CN] 胶囊内 x 处（vp）手指下的槽位。 */
  private cylGlassSlotAt(x: number): number {
    const position = (x - this.itemEdgeInsets.left) / this.cylGlassSlotWidth() - 0.5;
    return Math.max(0, Math.min(this.cylSlots().length - 1, position));
  }

  /** [EN] The lens follows the finger, lifted, then snaps to the slot it ends on and selects it (iOS 26 drag). [CN] 镜片抬起并跟随手指，松手后吸附到所在槽位并选中（iOS 26 拖动）。 */
  private cylGlassDragUpdate(x: number): void {
    if (this.tabBarStyleType !== CYLTabBarStyleType.LiquidGlass || this.glassCollapsed || !this.glassTouchActive) {
      return;
    }
    this.glassDragging = true;
    this.glassLensPosition = this.cylGlassSlotAt(x);
  }

  private cylGlassDragEnd(): void {
    if (!this.glassDragging) {
      return;
    }
    this.glassDragging = false;
    this.glassTouchActive = false;
    const slot = this.cylSlots()[Math.round(this.glassLensPosition)];
    this.cylGlassLift(false);
    if (slot !== undefined && slot.tabIndex >= 0 && slot.tabIndex !== this.selectedIndex) {
      this.cylTap(slot.tabIndex);
    }
    // [EN] Always settle on the real selection (a refused tab, or the plus button, sends the lens back). [CN] 总是回到实际选中项（被拒绝的 Tab 或加号按钮会让镜片返回）。
    setTimeout(() => this.cylGlassMoveLens(), 0);
  }

  /**
   * [EN] The lens behind the selected tab: a brighter, more saturated glass pill with a bright rim, stretched along its motion
   *      and swollen while lifted; hidden when minimized (the ball is the lens then).
   * [CN] 选中 Tab 后的镜片：更亮、更饱和的玻璃胶囊，带亮色描边，沿运动方向拉伸，抬起时膨胀；缩小后隐藏（此时球即镜片）。
   */
  @Builder
  cylGlassLens() {
    Stack() {
      Row()
        // [EN] As iOS 26: a neutral, borderless lens 8 vp wider than its slot and 4 vp inside the capsule; darker glass in a
        //      light app, lighter glass in a dark one. [CN] 与 iOS 26 相同：中性无描边的镜片，比槽位宽 8 vp，距胶囊上下 4 vp；浅色 App 中偏暗，深色 App 中偏亮。
        .width(this.cylGlassSlotWidth() + 8)
        .height(this.cylGlassRowHeight() - 8)
        .borderRadius((this.cylGlassRowHeight() - 8) / 2)
        .backgroundColor(this.colorMode === 'dark'
          ? (this.glassLensLift > 0.5 ? '#47FFFFFF' : '#33FFFFFF')
          : (this.glassLensLift > 0.5 ? '#1A000000' : '#0D000000'))
        .shadow({ radius: 8 + 10 * this.glassLensLift, color: '#1A000000', offsetY: 2 })
        .scale({
          x: this.glassLensStretch * (1 + 0.12 * this.glassLensLift),
          y: (2 - this.glassLensStretch) * (1 + 0.18 * this.glassLensLift),
        })
        .position({
          x: this.itemEdgeInsets.left + Math.max(0, this.glassLensPosition) * this.cylGlassSlotWidth() - 4,
          y: 4,
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .opacity(this.glassCollapsed || this.glassLensPosition < 0 ? 0 : 1)
    .hitTestBehavior(HitTestMode.None)
  }

  /**
   * [EN] The capsule's light: a specular band along the top edge fading down, and a faint glow along the bottom edge, so the
   *      glass reads as a curved, refracting surface.
   * [CN] 胶囊的光：沿上边缘向下渐隐的高光带，以及下边缘的微弱反光，使玻璃呈现弯曲、折射的表面。
   */
  @Builder
  cylGlassSheen() {
    Stack()
      .width('100%')
      .height('100%')
      .borderRadius(this.cylGlassRowHeight() / 2)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#40FFFFFF', 0], ['#0AFFFFFF', 0.35], ['#00FFFFFF', 0.6], ['#14FFFFFF', 1]],
      })
      // [EN] The glass rim, under the tabs. [CN] 玻璃亮边，位于 Tab 之下。
      .border({ width: 0.5, color: this.colorMode === 'dark' ? '#40FFFFFF' : '#99FFFFFF' })
      .position({ x: 0, y: 0 })
      .hitTestBehavior(HitTestMode.None)
  }

  /**
   * [EN] Liquid Glass: how far the tab content moves down so it is centered in the capsule, as on iOS. The content is laid out
   *      for tabBarHeight from the top; the capsule is taller (61 vp), so tabs and the plus button move by the same amount and
   *      stay aligned with each other. 0 for the other styles.
   * [CN] 液态玻璃：Tab 内容下移的距离，使其在胶囊中垂直居中（与 iOS 相同）。内容按 tabBarHeight 从顶部排列，而胶囊更高（61 vp），
   *      因此 Tab 与加号按钮移动相同距离，彼此保持对齐。其他样式为 0。
   */
  private cylGlassContentDy(): number {
    if (this.tabBarStyleType !== CYLTabBarStyleType.LiquidGlass || this.glassCollapsed) {
      return 0;
    }
    return cyl_liquidGlassContentDy(this.tabBarHeight);
  }

  /** [EN] Liquid Glass, minimized into a ball. [CN] 液态玻璃，已缩小成球。 */
  private cylGlassMinimized(): boolean {
    return this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass && this.glassCollapsed;
  }

  /** [EN] The Liquid Glass capsule's height: 56 vp (or tabBarHeight if taller), 42 vp minimized. [CN] 液态玻璃胶囊高度。 */
  private cylGlassRowHeight(): number {
    return this.glassCollapsed ? CYLLiquidGlassTokens.ROW_HEIGHT_COLLAPSED
      : Math.max(this.tabBarHeight, CYLLiquidGlassTokens.ROW_HEIGHT_EXPANDED);
  }

  /** [EN] The width of one slot of the expanded capsule; slots keep it while the capsule narrows. [CN] 展开态胶囊中一个槽位的宽度；胶囊收窄时槽位保持此宽度。 */
  private cylGlassSlotWidth(): number {
    const capsule = this.glassWidth - 2 * CYLLiquidGlassTokens.BAR_SIDE_MARGIN - this.itemEdgeInsets.left - this.itemEdgeInsets.right;
    return Math.max(1, capsule / Math.max(1, this.cylSlots().length));
  }

  /**
   * [EN] Minimized: the selected slot moves from its place to the capsule's center (the row stays centered on the capsule),
   *      and down by half a title line once the title has faded. [CN] 缩小后：选中槽位从原位平移到胶囊中心，标题淡出后再下移半个标题行高。
   */
  private cylGlassSlotTranslate(slotTabIndex: number): TranslateOptions {
    if (!this.cylGlassMinimized() || slotTabIndex !== this.selectedIndex) {
      return { x: 0, y: 0 };
    }
    const slots = this.cylSlots();
    const position = slots.findIndex((slot: CYLSlot) => slot.tabIndex === slotTabIndex);
    return {
      x: (slots.length / 2 - position - 0.5) * this.cylGlassSlotWidth(),
      y: CYLLiquidGlassTokens.COLLAPSED_ICON_DY,
    };
  }

  /** [EN] Minimized, only the selected slot shows; the others vanish at once, outside the morph. [CN] 缩小后只显示选中槽位，其他槽位立即消失。 */
  private cylGlassSlotVisible(slotTabIndex: number): boolean {
    return !this.cylGlassMinimized() || slotTabIndex === this.selectedIndex;
  }

  /** [EN] A tab change from code is an interruption too (issue #13). [CN] 代码切换 Tab 也视为意外情况。 */
  cylOnSelectedIndexChange(): void {
    this.cylGlassMoveLens();
    this.cylRestoreFromScroll();
  }

  /** [EN] setTabBarHidden(false) shows the bar, also when scrolling had hidden it. [CN] setTabBarHidden(false) 也会恢复被滚动隐藏的 TabBar。 */
  cylOnTabBarHiddenChange(): void {
    if (!this.tabBarHidden) {
      this.cylRestoreFromScroll();
    }
  }

  /** [EN] cyl_restoreTabBar and other interruptions: show the bar, ignore the next 600 ms of scrolling. [CN] 恢复 TabBar。 */
  cylRestoreFromScroll(): void {
    this.cylIgnoreScrollUntil = Date.now() + 600;
    this.cylSetScrollHidden(false);
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
    this.cylRestoreFromScroll();
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
    if (index < 0 || this.tapAnimationType === CYLTabButtonTapAnimationType.None || this.tabButtonAnimation !== undefined) {
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

  private cylTapValues(property: CYLTabButtonProperty): number[] {
    switch (property) {
      case CYLTabButtonProperty.IconScale: return this.tapScale;
      case CYLTabButtonProperty.IconAngle: return this.tapAngle;
      case CYLTabButtonProperty.IconFlipY: return this.tapFlip;
      case CYLTabButtonProperty.IconFlipX: return this.tapFlipX;
      case CYLTabButtonProperty.IconOffsetY: return this.tapOffset;
      case CYLTabButtonProperty.TitleOpacity: return this.tapTitleOpacity;
      case CYLTabButtonProperty.TitleScale: return this.tapTitleScale;
      default: return this.tapBadgeScale;
    }
  }

  private cylSetTapValue(index: number, property: CYLTabButtonProperty, value: number): void {
    const copy = this.cylTapValues(property).slice();
    copy[index] = value;
    switch (property) {
      case CYLTabButtonProperty.IconScale: this.tapScale = copy; break;
      case CYLTabButtonProperty.IconAngle: this.tapAngle = copy; break;
      case CYLTabButtonProperty.IconFlipY: this.tapFlip = copy; break;
      case CYLTabButtonProperty.IconFlipX: this.tapFlipX = copy; break;
      case CYLTabButtonProperty.IconOffsetY: this.tapOffset = copy; break;
      case CYLTabButtonProperty.TitleOpacity: this.tapTitleOpacity = copy; break;
      case CYLTabButtonProperty.TitleScale: this.tapTitleScale = copy; break;
      default: this.tapBadgeScale = copy; break;
    }
  }

  /** [EN] The CYLTabButtonView of a tab, for tabButtonAnimation. [CN] Tab 的 CYLTabButtonView。 */
  cylButtonView(index: number): CYLTabButtonView {
    const neutral = (property: CYLTabButtonProperty): number =>
      property === CYLTabButtonProperty.IconScale || property === CYLTabButtonProperty.TitleOpacity ||
        property === CYLTabButtonProperty.TitleScale || property === CYLTabButtonProperty.BadgeScale ? 1 : 0;
    const ui = this.getUIContext();
    return new CYLTabButtonViewImpl(index, this.tabBarItemsAttributes[index]?.title !== undefined,
      (property: CYLTabButtonProperty): number => this.cylTapValues(property)[index] ?? neutral(property),
      (property: CYLTabButtonProperty, value: number, duration?: number, curve?: Curve): void => {
        if (duration === undefined || duration <= 0) {
          this.cylSetTapValue(index, property, value);
          return;
        }
        ui.animateTo({ duration: duration, curve: curve ?? Curve.EaseInOut }, () => this.cylSetTapValue(index, property, value));
      },
      (property: CYLTabButtonProperty, values: number[], duration: number, keyTimes?: number[]): void => {
        if (values.length === 0) {
          return;
        }
        this.cylSetTapValue(index, property, values[0]);
        const steps: KeyframeState[] = [];
        for (let i = 1; i < values.length; i++) {
          const from = keyTimes?.[i - 1] ?? (i - 1) / (values.length - 1);
          const to = keyTimes?.[i] ?? i / (values.length - 1);
          const value = values[i];
          steps.push({
            duration: Math.max(1, Math.round((to - from) * duration)),
            curve: Curve.EaseInOut,
            event: () => this.cylSetTapValue(index, property, value),
          });
        }
        if (steps.length > 0) {
          ui.keyframeAnimateTo({ iterations: 1 }, steps);
        }
      },
      (image: ResourceStr | undefined): void => {
        const copy = this.tapFrameImages.slice();
        copy[index] = image;
        this.tapFrameImages = copy;
      },
      (image?: ResourceStr): void => {
        const images = this.tapFireworkImages.slice();
        images[index] = image;
        this.tapFireworkImages = images;
        const start = this.tapFireworks.slice();
        start[index] = 0.01;
        this.tapFireworks = start;
        ui.animateTo({
          duration: 600, curve: Curve.EaseOut, onFinish: () => {
            const done = this.tapFireworks.slice();
            done[index] = 0;
            this.tapFireworks = done;
          }
        }, () => {
          const end = this.tapFireworks.slice();
          end[index] = 1;
          this.tapFireworks = end;
        });
      });
  }

  /** [EN] tabButtonAnimation on a tap: reselect, or deselect the previous tab then select this one. [CN] 点击时播放动画对象。 */
  private cylPlayTabButtonAnimation(index: number, previous: number): void {
    const animation = this.tabButtonAnimation;
    if (animation === undefined || index < 0) {
      return;
    }
    if (index === previous) {
      animation.cyl_playReselectAnimationWithTabButton(this.cylButtonView(index));
      return;
    }
    if (previous >= 0) {
      animation.cyl_toRight = index > previous;
      animation.cyl_playDeselectAnimationWithTabButton(this.cylButtonView(previous));
    }
    animation.cyl_fromLeft = previous >= 0 && previous < index;
    animation.cyl_playSelectAnimationWithTabButton(this.cylButtonView(index));
  }

  private cylLastBadgeValues: string[] = [];

  /**
   * [EN] A badge set or replaced in `badges`: tabButtonAnimation's badge-changed animation.
   * [CN] `badges` 中的角标被设置或替换时，播放动画对象的角标动画。
   */
  cylOnBadgesChange(): void {
    const values = this.badges.map((badge: CYLBadge) => `${badge?.value ?? 'none'}|${badge?.generation ?? 0}`);
    const animation = this.tabButtonAnimation;
    if (animation !== undefined) {
      values.forEach((value: string, index: number) => {
        if (this.cylLastBadgeValues[index] !== undefined && this.cylLastBadgeValues[index] !== value) {
          animation.cyl_playBadgeChangedAnimationWithTabButton(this.cylButtonView(index));
        }
      });
    }
    this.cylLastBadgeValues = values;
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
    this.cylPlayTabButtonAnimation(index, previous);
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
    // [EN] A tab change is an interruption: the bar comes back (issue #13). [CN] 切换 Tab 视为意外情况：TabBar 恢复。
    if (index !== this.selectedIndex) {
      this.cylRestoreFromScroll();
    }
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
    const state = this.selectedIndex === index ? CYLLocalizedString('%@, %@', position, CYLLocalizedString('选中')) : position;
    // [EN] A disabled tab says so (`CYLFlatDesignTabBarItem.enabled`). [CN] 不可用的 Tab 会读出「不可用」。
    return this.tabBarItemsAttributes[index].enabled === false ? CYLLocalizedString('%@, %@', state, CYLLocalizedString('Dimmed')) : state;
  }

  /**
   * [EN] `layoutCentered` with a title and no image: the icon square is left out, so the title sits in the middle.
   * [CN] `layoutCentered` 且有标题无图片时省略图标方框，使标题居中。
   */
  cylHidesIcon(index: number): boolean {
    const item = this.tabBarItemsAttributes[index];
    return item.layoutCentered === true && item.title !== undefined && item.image === undefined
      && item.lottieFilePath === undefined && item.imageURL === undefined && item.gifFilePath === undefined
      && this.cylSVGAPath(index) === undefined;
  }

  /** [EN] The plus button's label: its title or "Plus button", and its badge. [CN] 加号按钮的标签。 */
  cylPlusAccessibilityLabel(): string {
    const title = cyl_textOf(this.plusButton?.title);
    const label = title.length > 0 ? title : CYLLocalizedString('加号按钮');
    const badge = cyl_badgeAccessibilityText(this.plusButtonBadge);
    return badge.length > 0 ? CYLLocalizedString('%@, %@', label, badge) : label;
  }

  /** [EN] The height of a tab's icon (a Lottie size or the image size). [CN] Tab 图标高度。 */
  cylIconHeight(index: number): number {
    const item = this.tabBarItemsAttributes[index];
    const lottie = item.lottieFilePath !== undefined && item.gifFilePath === undefined && item.imageURL === undefined;
    if (lottie) {
      return item.lottieSize ?? this.imageSize;
    }
    if (this.cylRivePath(index) !== undefined) {
      return item.riveSize ?? this.imageSize;
    }
    // [EN] SVGA icons have their own size (issue list #11). [CN] SVGA 图标有自己的尺寸（问题 #11）。
    return this.cylSVGAPath(index) !== undefined ? (item.svgaSize ?? this.imageSize) : this.imageSize;
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

  /**
   * [EN] FIX: issue #415. The tabs whose SVGA file failed to load: they show their image. [CN] SVGA 文件加载失败的 Tab：它们显示图片。
   */
  @State cylSVGAFailures: number[] = [];

  /**
   * [EN] FIX: issue #415. The SVGA file of a tab (URL first, the dark variant in dark mode), or undefined when it has none,
   *      when GIF or image URL attributes win (as for Lottie), or when it failed to load.
   * [CN] FIX: issue #415。Tab 的 SVGA 文件（先取 URL，深色模式取深色版本）；没有、被 GIF 或图片 URL 属性覆盖（与 Lottie 相同）或加载失败时为 undefined。
   */
  private cylSVGAPath(index: number): string | undefined {
    const item = this.tabBarItemsAttributes[index];
    if (item.gifFilePath !== undefined || item.imageURL !== undefined || this.cylSVGAFailures.includes(index)) {
      return undefined;
    }
    const dark = this.colorMode === 'dark';
    const darkPath = dark ? (item.svgaDarkURL ?? item.svgaDarkFilePath) : undefined;
    return darkPath ?? item.svgaURL ?? item.svgaFilePath;
  }

  /**
   * [EN] The tabs whose Rive file failed to load: they show their image. [CN] Rive 文件加载失败的 Tab：它们显示图片。
   */
  @State cylRiveFailures: number[] = [];

  /**
   * [EN] The Rive file of a tab (the dark variant in dark mode), or undefined when it has none, when Lottie, GIF or image
   *      URL attributes win, or when it failed to load.
   * [CN] Tab 的 Rive 文件（深色模式取深色版本）；没有、被 Lottie、GIF 或图片 URL 属性覆盖或加载失败时为 undefined。
   */
  private cylRivePath(index: number): string | undefined {
    const item = this.tabBarItemsAttributes[index];
    // [EN] No Rive view where @ohos/rive cannot run: the image shows. [CN] @ohos/rive 无法运行时不创建 Rive 视图：显示图片。
    if (item.lottieFilePath !== undefined || item.gifFilePath !== undefined || item.imageURL !== undefined
      || this.cylRiveFailures.includes(index) || !cylRiveIsSupported()) {
      return undefined;
    }
    const dark = this.colorMode === 'dark';
    return (dark ? item.riveDarkFilePath : undefined) ?? item.riveFilePath;
  }

  /** [EN] Fireworks of tabButtonAnimation: 8 particles that burst out and fade. [CN] 烟花：8 个粒子向外散开并淡出。 */
  @Builder
  cylFireworks(index: number) {
    Stack() {
      ForEach([0, 1, 2, 3, 4, 5, 6, 7], (particle: number) => {
        if (this.tapFireworkImages[index] !== undefined) {
          Image(this.tapFireworkImages[index])
            .width(6)
            .height(6)
            .translate({
              x: Math.cos(particle * Math.PI / 4) * 22 * (this.tapFireworks[index] ?? 0),
              y: Math.sin(particle * Math.PI / 4) * 22 * (this.tapFireworks[index] ?? 0),
            })
            .opacity(1 - (this.tapFireworks[index] ?? 0))
        } else {
          Circle()
            .width(4)
            .height(4)
            .fill(this.tintColor)
            .translate({
              x: Math.cos(particle * Math.PI / 4) * 22 * (this.tapFireworks[index] ?? 0),
              y: Math.sin(particle * Math.PI / 4) * 22 * (this.tapFireworks[index] ?? 0),
            })
            .opacity(1 - (this.tapFireworks[index] ?? 0))
        }
      }, (particle: number) => `${particle}`)
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel('no-hide-descendants')
  }

  /** [EN] The animation file of a tab (Lottie, Rive or SVGA), or undefined. [CN] Tab 的动画文件（Lottie、Rive 或 SVGA），没有时为 undefined。 */
  cylTabAnimationPath(index: number): string | undefined {
    const item = this.tabBarItemsAttributes[index];
    if (item.lottieFilePath !== undefined && item.gifFilePath === undefined && item.imageURL === undefined) {
      return this.colorMode === 'dark' && item.lottieDarkFilePath !== undefined ? item.lottieDarkFilePath : item.lottieFilePath;
    }
    return this.cylRivePath(index) ?? this.cylSVGAPath(index);
  }

  cylTabAnimationSize(index: number): number {
    const item = this.tabBarItemsAttributes[index];
    if (item.lottieFilePath !== undefined && item.gifFilePath === undefined && item.imageURL === undefined) {
      return item.lottieSize ?? this.imageSize;
    }
    if (this.cylRivePath(index) !== undefined) {
      return item.riveSize ?? this.imageSize;
    }
    return item.svgaSize ?? this.imageSize;
  }

  /** [EN] The engine view CYLAnimatedItemView shows for a tab. [CN] CYLAnimatedItemView 为 Tab 显示的引擎视图。 */
  @Builder
  cylTabEngine(index: number, context: CYLAnimatedItemAnimationContext) {
    if (this.tabBarItemsAttributes[index].lottieFilePath !== undefined
      && this.tabBarItemsAttributes[index].gifFilePath === undefined
      && this.tabBarItemsAttributes[index].imageURL === undefined) {
      CYLLottieIcon({
        path: this.cylTabAnimationPath(index),
        iconSize: this.cylTabAnimationSize(index),
        speed: this.tabBarItemAnimationSpeed,
        selected: this.selectedIndex === index,
        replayToken: this.replayTokens[index] ?? 0,
        onLoaded: () => context.onLoaded(),
        onLoadError: (_message: string) => context.onFailed(),
      })
    } else if (this.cylRivePath(index) !== undefined) {
      CYLRiveIcon({
        path: this.cylRivePath(index),
        iconSize: this.cylTabAnimationSize(index),
        selected: this.selectedIndex === index,
        replayToken: this.replayTokens[index] ?? 0,
        loops: this.tabBarItemAnimationLoops,
        onLoaded: () => context.onLoaded(),
        onLoadError: (_message: string) => {
          context.onFailed();
          this.cylRiveFailures = this.cylRiveFailures.concat([index]);
        },
      })
    } else if (this.cylSVGAPath(index) !== undefined) {
      CYLSVGAView({
        path: this.cylSVGAPath(index),
        iconSize: this.cylTabAnimationSize(index),
        selected: this.selectedIndex === index,
        replayToken: this.replayTokens[index] ?? 0,
        onLoaded: () => context.onLoaded(),
        onLoadError: (_message: string) => {
          context.onFailed();
          this.cylSVGAFailures = this.cylSVGAFailures.concat([index]);
        },
      })
    }
  }

  @Builder
  cylTab(index: number) {
    Column() {
      if (this.tabCoverImages[index] !== undefined) {
        Image(this.tabCoverImages[index])
          .height(this.tabBarHeight - 4)
          .margin({ top: 2 })
          .objectFit(ImageFit.Contain)
          .id(`cyl-cover-${this.cylIdentifier(index)}`)
      } else {
      Stack() {
        if (this.cylTabAnimationPath(index) !== undefined) {
          // [EN] The animated icon is CYLAnimatedItemView (docs/Animated-Item.md, TODO 5): the static image (else the
          //      placeholder) until the engine view reports it is drawn, and again when it fails.
          // [CN] 动效图标由 CYLAnimatedItemView 绘制（docs/Animated-Item.md，TODO 5）：引擎视图报告绘制完成之前，以及失败之后，显示静态图片（没有时为占位图）。
          CYLAnimatedItemView({
            isBare: true,
            image: this.cylIcon(index) ?? '',
            animationUrl: this.cylTabAnimationPath(index),
            iconSize: this.cylTabAnimationSize(index),
            isItemSelected: this.selectedIndex === index,
            animationBuilder: (context: CYLAnimatedItemAnimationContext) => {
              this.cylTabEngine(index, context)
            },
          })
        } else {
        Image(this.tapFrameImages[index] ?? this.cylIcon(index))
          .width(this.imageSize)
          .height(this.imageSize)
          .objectFit(ImageFit.Contain)
          .scale({ x: this.tapScale[index] ?? 1, y: this.tapScale[index] ?? 1 })
          .rotate({ z: 1, angle: this.tapAngle[index] ?? 0 })
          .rotate({ y: 1, angle: this.tapFlip[index] ?? 0 })
          .rotate({ x: 1, angle: this.tapFlipX[index] ?? 0 })
          .translate({ y: this.tapOffset[index] ?? 0 })
          .padding(this.tabBarItemsAttributes[index].imageInsets ?? 0)
          .overlay((this.tapFireworks[index] ?? 0) > 0 ? this.cylFireworks(index) : undefined)
        }
        CYLBadgeView({ badge: this.badges[index], anchorWidth: this.cylIconHeight(index) })
          .scale({ x: this.tapBadgeScale[index] ?? 1, y: this.tapBadgeScale[index] ?? 1 })
      }
      // [EN] No fixed width: the badge is measured with the free width, so text badges grow with their text (issue list
      //      #1). The icon sits right above the title, whose top is at tabBarHeight - 17 like the plus title (#2).
      // [CN] 不固定宽度：角标按剩余宽度测量，文字角标随文字变宽（问题 #1）。图标紧贴标题上方，标题顶部与加号标题同在 tabBarHeight - 17（#2）。
      .alignContent(Alignment.TopStart)
      .margin({ top: Math.max(0, this.tabBarHeight - 17 - 3 - this.cylIconHeight(index)) })
      .offset({
        x: this.tabBarItemsAttributes[index].imagePositionAdjustment?.horizontal ?? 0,
        y: this.tabBarItemsAttributes[index].imagePositionAdjustment?.vertical ?? 0,
      })
      .visibility(this.cylHidesIcon(index) ? Visibility.None : Visibility.Visible)

      if (this.tabBarItemsAttributes[index].title !== undefined) {
        Text(this.selectedIndex === index
          ? (this.tabBarItemsAttributes[index].selectedTitle ?? this.tabBarItemsAttributes[index].title)
          : this.tabBarItemsAttributes[index].title)
          .fontSize(10)
          .margin({ top: 3 })
          // [EN] Liquid Glass minimized: the title fades out with the morph. [CN] 液态玻璃缩小时标题随形变淡出。
          .opacity(this.cylGlassMinimized() ? 0 : (this.tapTitleOpacity[index] ?? 1))
          .scale({ x: this.tapTitleScale[index] ?? 1, y: this.tapTitleScale[index] ?? 1 })
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
    .padding({ top: this.cylGlassContentDy() })
    // [EN] Liquid Glass: each slot keeps the expanded width while the capsule narrows into a ball (CYLLiquidGlass.ets).
    // [CN] 液态玻璃：胶囊收窄成球时，每个槽位保持展开时的宽度（CYLLiquidGlass.ets）。
    .constraintSize(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass && this.glassWidth > 0
      ? { minWidth: this.cylGlassSlotWidth(), maxWidth: this.cylGlassSlotWidth() } : {})
    .translate(this.cylGlassSlotTranslate(index))
    .visibility(this.cylGlassSlotVisible(index) ? Visibility.Visible : Visibility.Hidden)
    .height('100%')
    .justifyContent(FlexAlign.Start)
    // [EN] Liquid Glass: the selection is a capsule inside the rounded bar (issue list #6). [CN] 液态玻璃：选中背景为圆角胶囊（问题 #6）。
    .borderRadius(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? this.tabBarHeight / 2 : 0)
    .opacity(this.tabBarItemsAttributes[index].enabled === false ? 0.4 : 1)
    .enabled(this.tabBarItemsAttributes[index].enabled !== false)
    .backgroundColor(this.selectedIndex === index
      ? (this.tabBarItemsAttributes[index].selectedBackgroundColor ?? Color.Transparent)
      : (this.tabBarItemsAttributes[index].backgroundColor ?? Color.Transparent))
    // [EN] One accessibility element per tab: icon, cover, Lottie and badge are read through it. [CN] 每个 Tab 一个无障碍元素。
    .accessibilityGroup(true)
    .accessibilityText(this.cylAccessibilityLabel(index))
    .accessibilityDescription(this.cylAccessibilityDescription(index))
    .id(`cyl-tab-${this.cylIdentifier(index)}`)
    // [EN] Taps through onClick, the long press in parallel: an exclusive long-press + tap group could drop the first tap
    //      right after a page push (issue list #14). [CN] 点击走 onClick，长按为并行手势：长按 + 点击的互斥组合可能丢失 push 后的第一次点击（问题 #14）。
    .onClick(() => {
      if (this.cylLongPressedIndex === index) {
        this.cylLongPressedIndex = -2;
        return;
      }
      // [EN] Liquid Glass minimized: the first tap on the ball only expands it, as the reference. [CN] 液态玻璃缩小时，点按球只展开，与参考工程相同。
      if (this.cylGlassMinimized()) {
        this.cylSetGlassCollapsed(false);
        return;
      }
      this.cylTap(index);
    })
    .onTouch((event: TouchEvent) => {
      const animation = this.tabButtonAnimation;
      if (animation === undefined) {
        return;
      }
      if (event.type === TouchType.Down) {
        animation.cyl_playHighlightAnimationWithTabButton(this.cylButtonView(index));
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animation.cyl_playDehighlightAnimationWithTabButton(this.cylButtonView(index));
      }
    })
    .parallelGesture(LongPressGesture({ duration: this.longPressDuration }).onAction(() => {
      this.cylLongPressedIndex = index;
      if (this.didLongPress !== undefined) {
        this.didLongPress(index, this.cylIdentifier(index));
      }
    }))
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

  cylPlusAlignsTitle(): boolean {
    return this.plusButton?.title !== undefined && this.plusButton?.alignsTitle !== false;
  }

  @Builder
  cylPlus() {
    Column() {
      Stack() {
        // [EN] The image and its badge in a box of the image's size: the badge is placed from the image's top-left, as iOS
        //      places it on the plus button (center at its top-right corner plus cyl_badgeCenterOffset), not from the slot,
        //      which is wider than the image (the badge was 8 to 15 vp inside the image).
        // [CN] 图片与角标放在与图片等大的盒子中：角标以图片左上角为原点定位，与 iOS 在加号按钮上的位置相同（中心位于右上角再加
        //      cyl_badgeCenterOffset），而不是以比图片更宽的槽位为原点（此前角标落在图片内侧 8 到 15 vp）。
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
        .width(this.plusButton?.imageSize ?? 54)
        .height(this.plusButton?.imageSize ?? 54)
      }
      // [EN] As CYLPlusButton.kt: with an aligned title the image sits right above the title (item 4); otherwise it is
      //      centred and moved by centerYOffset. [CN] 与 CYLPlusButton.kt 相同：标题对齐时图片紧贴标题上方（第 4 项）；否则居中并按 centerYOffset 移动。
      .position(this.cylPlusAlignsTitle()
        ? { x: 0, y: this.cylGlassContentDy() + this.tabBarHeight - 17 - (this.plusButton?.imageSize ?? 54) } : undefined)
      .width(this.cylPlusAlignsTitle() ? '100%' : undefined)
      .offset({ y: this.cylPlusAlignsTitle() ? 0 : (this.plusButton?.centerYOffset ?? 0) })

      if (this.plusButton?.title !== undefined) {
        Text(this.plusButton.title)
          .fontSize(10)
          .fontColor(this.selectedIndex === CYLPlusButtonPageIndex
            ? (this.plusButtonTitleSelectedColor ?? this.tintColor) : this.unselectedColor)
          .position(this.plusButton?.alignsTitle === false ? undefined : { x: 0, y: this.cylGlassContentDy() + this.tabBarHeight - 17 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .layoutWeight(1)
    .constraintSize(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass && this.glassWidth > 0
      ? { minWidth: this.cylGlassSlotWidth(), maxWidth: this.cylGlassSlotWidth() } : {})
    .translate(this.cylGlassSlotTranslate(CYLPlusButtonPageIndex))
    .visibility(this.cylGlassSlotVisible(CYLPlusButtonPageIndex) ? Visibility.Visible : Visibility.Hidden)
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

  /**
   * [EN] `shadowImage` as the bar's top line, stretched to the width. [CN] 作为 TabBar 顶部线条的 `shadowImage`，横向拉伸。
   */
  @Builder
  cylShadowImage() {
    Image(this.shadowImage)
      .width('100%')
      .height(1)
      .objectFit(ImageFit.Fill)
      .accessibilityLevel('no')
      .hitTestBehavior(HitTestMode.Transparent)
  }

  /**
   * [EN] The classic / FlatDesign top line (0.5 vp of the shadow color, or `shadowImage`), as the row's first child placed
   *      at its top: the tabs and the raised plus button are drawn after it, so it never crosses them (HarmonyOS issue
   *      list #52). As the row's border or overlay, ArkUI painted it over the children.
   * [CN] 经典 / 扁平样式的顶部线条（0.5 vp 的阴影色，或 `shadowImage`），作为 Row 的第一个子节点放在顶部：Tab 与凸起的加号按钮在其后绘制，
   *      线条不会横穿它们（鸿蒙问题列表 #52）。作为 Row 的描边或 overlay 时，ArkUI 会把它画在子节点之上。
   */
  @Builder
  cylTopLine() {
    if (this.shadowImage !== undefined) {
      this.cylShadowImage()
    } else {
      Row()
        .width('100%')
        .height(0.5)
        .backgroundColor(this.tabBarShadowColor)
        .accessibilityLevel('no')
        .hitTestBehavior(HitTestMode.Transparent)
    }
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
          // [EN] Liquid Glass: the lens under the tabs and the sheen over them are real children placed absolutely, so they
          //      follow state like any node and leave the tabs' layout and keys alone.
          // [CN] 液态玻璃：Tab 下方的镜片与上方的光泽是绝对定位的真实子节点，随状态更新，且不影响 Tab 的布局与 key。
          // [EN] Glass light first, then the lens, then the tabs: the raised plus button and the badges are drawn over the
          //      glass, as on iOS, with no band of light across them.
          // [CN] 先画玻璃的光，再画镜片，最后画 Tab：凸起的加号按钮与角标画在玻璃之上，与 iOS 相同，不会被光带横穿。
          if (this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass) {
            this.cylGlassSheen()
            this.cylGlassLens()
          } else {
            // [EN] The top line first, under the tabs and the plus button (issue list #52).
            // [CN] 先画顶部线条，位于 Tab 与加号按钮之下（问题列表 #52）。
            Stack() {
              this.cylTopLine()
            }
            .width('100%')
            .position({ x: 0, y: 0 })
            .hitTestBehavior(HitTestMode.Transparent)
          }
          ForEach(this.cylSlots(), (slot: CYLSlot) => {
            if (slot.tabIndex >= 0) {
              this.cylTab(slot.tabIndex)
            } else {
              this.cylPlus()
            }
          }, (slot: CYLSlot) => slot.key)
        }
        // [EN] Liquid Glass: the capsule narrows into a ball when minimized; its slots keep their width and stay centered on it.
        // [CN] 液态玻璃：缩小时胶囊收窄成球；槽位保持宽度并以胶囊为中心。
        .width(this.cylGlassMinimized() ? CYLLiquidGlassTokens.ROW_HEIGHT_COLLAPSED : '100%')
        .height(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? this.cylGlassRowHeight() : this.tabBarHeight)
        .justifyContent(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? FlexAlign.Center : FlexAlign.Start)
        // [EN] Classic / FlatDesign: the container paints the bar color once, so a translucent theme color (e.g. #17203ACC)
        //      is the same above and under the gesture bar (painted twice, the row looked darker than the strip).
        // [CN] 经典 / 扁平样式：由容器统一绘制 TabBar 颜色，半透明主题色在手势条上下一致（绘制两次时 TabBar 比下方条带更深）。
        .backgroundColor(Color.Transparent)
        // [EN] Liquid Glass: no border on the row (ArkUI paints a border over the children, a line across the raised plus
        //      button); the glass rim is drawn by cylGlassSheen, under the tabs. The classic top line would also leave the
        //      other edges black after a re-render.
        // [CN] 液态玻璃：Row 不设描边（ArkUI 把描边画在子节点之上，会在凸起的加号按钮上留下一条线）；玻璃亮边由 cylGlassSheen 画在 Tab 之下。
        // [EN] No border and no overlay in any style: both are painted over the children. The classic / FlatDesign top line
        //      is cylTopLine, the row's first child (issue list #52).
        // [CN] 任何样式都不用描边与 overlay：两者都画在子节点之上。经典 / 扁平样式的顶部线条是 Row 的第一个子节点 cylTopLine（问题列表 #52）。
        .border({ width: 0 })
        // [EN] Liquid Glass: the lens slides behind the tabs; touching lifts it, dragging moves it (iOS 26).
        // [CN] 液态玻璃：镜片在 Tab 后滑动；触摸时抬起，拖动时跟随（iOS 26）。
        .scale({ x: 1 + 0.02 * this.glassLensLift, y: 1 + 0.02 * this.glassLensLift })
        .onTouch((event: TouchEvent) => {
          if (this.tabBarStyleType !== CYLTabBarStyleType.LiquidGlass || this.glassCollapsed) {
            return;
          }
          if (event.type === TouchType.Down) {
            this.glassTouchActive = true;
            this.cylGlassLift(true);
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            if (this.glassDragging) {
              this.cylGlassDragEnd();
            } else {
              this.glassTouchActive = false;
              this.cylGlassLift(false);
            }
          }
        })
        .parallelGesture(PanGesture({ direction: PanDirection.Horizontal, distance: 6 })
          .onActionUpdate((event: GestureEvent) => {
            const finger = event.fingerList.length > 0 ? event.fingerList[0] : undefined;
            if (finger !== undefined) {
              this.cylGlassDragUpdate(finger.localX);
            }
          })
          .onActionEnd(() => this.cylGlassDragEnd())
          .onActionCancel(() => this.cylGlassDragEnd()))
        // [EN] Liquid Glass: the glass capsule of CYLLiquidGlass.ets (blur, tint barTintColor or a light glass, shadow, rim).
        // [CN] 液态玻璃：CYLLiquidGlass.ets 的玻璃胶囊（模糊、barTintColor 或浅色玻璃着色、阴影、描边）。
        .attributeModifier(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass
          ? new CYLLiquidGlassCapsuleModifier(this.barTintColor, this.cylGlassRowHeight(), 3, this.colorMode === 'dark')
          : cyl_tabBarStyleModifier(this.tabBarStyleType, this.barTintColor, this.tabBarHeight, this.barBackgroundImage))
        .padding({ left: this.itemEdgeInsets.left, right: this.itemEdgeInsets.right })
        .expandSafeArea(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? [] : [SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .id('cyl-tab-bar')
        }
        .width('100%')
        // [EN] Liquid Glass (reference geometry): 11 vp at the sides, 24 vp above the screen's bottom (gesture bar included);
        //      minimized, the ball sits 22 vp from the leading edge.
        // [CN] 液态玻璃（参考工程的几何）：两侧 11 vp，距屏幕底部 24 vp（含手势条）；缩小后球距起始边 22 vp。
        .padding(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? {
          left: this.glassCollapsed ? CYLLiquidGlassTokens.COLLAPSED_EDGE_MARGIN : CYLLiquidGlassTokens.BAR_SIDE_MARGIN,
          right: CYLLiquidGlassTokens.BAR_SIDE_MARGIN,
          bottom: Math.max(4, CYLLiquidGlassTokens.BAR_BOTTOM_MARGIN - this.glassGestureBarHeight),
        } : 0)
        .alignItems(this.cylGlassMinimized() ? HorizontalAlign.Start : HorizontalAlign.Center)
        .attributeModifier(new CYLLiquidGlassContainerModifier(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass))
        // [EN] The bar color continues under the gesture bar (classic and FlatDesign); clear around the Liquid Glass capsule.
        // [CN] 经典与扁平样式的 TabBar 颜色延伸到手势条下方；液态玻璃胶囊四周透明。
        .backgroundColor(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? Color.Transparent
          : (this.tabBarStyleType === CYLTabBarStyleType.FlatDesign ? (this.barTintColor ?? '#F9F9F9') : this.tabBarBackgroundColor))
        .expandSafeArea(this.tabBarStyleType === CYLTabBarStyleType.LiquidGlass ? [] : [SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        // [EN] Issue list #31: out of the layout while a resizing keyboard is up, so it never moves above the keyboard.
        // [CN] 问题清单 #31：缩小页面的键盘弹出时退出布局，因此不会移到键盘上方。
        .visibility(this.keyboardCoversTabBar ? Visibility.None : Visibility.Visible)
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM)
          .animation({ duration: this.tabBarHiddenAnimated ? 250 : 0 }))
        .id('cyl-tab-bar-container')
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_old: Area, area: Area) => {
      this.glassWidth = Number(area.width);
    })
  }
}
