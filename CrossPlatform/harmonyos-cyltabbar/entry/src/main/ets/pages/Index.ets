import { promptAction, display } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import {
  CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton, CYLPlusButtonPageIndex, CYLBadge, CYLBadgeView,
  CYLBadgeAppearance, CYLBadgeAnimationType, CYLOffset, CYLEdgeInsets, cyl_simulateMemoryWarning, cyl_badgeTitleForRow,
  cyl_badgeStyleCount, cyl_applyBadgeSample, CYLTabButtonTapAnimationType, CYLImpactFeedbackStyle,
  CYLTabBarMinimizeBehavior, cyl_reportScroll, cyl_pushViewController, CYLThemeManager, CYLThemeManagerCenter,
  cyl_tabBarItemIdentifiers, cyl_indexOfTabBarItemWithIdentifier, cyl_selectTabBarItemWithIdentifier
} from 'cyltabbar';
import { CYLLocalizedString, cyl_localizationKey, cyl_badgeAccessibilityText } from 'cyltabbar';
import { DemoTheme, DEMO_THEMES, demoRegisterThemes } from '../demo/DemoThemes';
import { DemoFlatDesignButton } from '../demo/DemoFlatDesign';
import { DemoLiquidGlassButton } from '../demo/DemoLiquidGlass';
import { CYLTabBarStyleType, CYLFlatDesignTintColor, CYLFlatDesignUnselectedColor, CYLLiquidGlassTintColor, CYLLiquidGlassSelectionColor } from 'cyltabbar';
import {
  DemoRow, DemoSection, DEMO_APPEARANCES, DEMO_TITLE_OFFSETS, DEMO_HOME, DEMO_CITY, DEMO_MESSAGE, DEMO_ME,
  DEMO_LANGUAGES, DEMO_LANGUAGE_NAMES
} from '../demo/DemoRows';

/**
 * [EN] The tabs of the Objective-C Example (MainTabBarController): Home, Nearby, Messages, Me, with identifiers.
 * [CN] Objective-C Example（MainTabBarController）的 Tab：首页、同城、消息、我的，带 identifier。
 */
const CYL_TABS: CYLTabBarItemAttributes[] = [
  { title: $r('app.string.tab_home'), selectedTitle: $r('app.string.tab_refresh'), image: $r('app.media.home_normal'), selectedImage: $r('app.media.home_highlight'), identifier: DEMO_HOME, lottieFilePath: 'lottie/green_lottie_tab_home.json', lottieDarkFilePath: 'lottie/green_lottie_tab_home_dark.json' },
  { title: $r('app.string.tab_nearby'), image: $r('app.media.fishpond_normal'), selectedImage: $r('app.media.fishpond_highlight'), identifier: DEMO_CITY, lottieFilePath: 'lottie/green_lottie_tab_discover.json', lottieDarkFilePath: 'lottie/green_lottie_tab_discover_dark.json' },
  { title: $r('app.string.tab_messages'), image: $r('app.media.message_normal'), darkImage: $r('app.media.message_normal_night'), selectedImage: $r('app.media.message_highlight'), identifier: DEMO_MESSAGE, lottieFilePath: 'lottie/green_lottie_tab_news.json', lottieDarkFilePath: 'lottie/green_lottie_tab_news_dark.json' },
  { title: $r('app.string.tab_me'), image: $r('app.media.account_normal'), selectedImage: $r('app.media.account_highlight'), identifier: DEMO_ME, lottieFilePath: 'lottie/green_lottie_tab_mine.json', lottieDarkFilePath: 'lottie/green_lottie_tab_mine_dark.json' },
];

const CYL_RANDOM_COLORS: string[] = ['#FF3B30', '#FF9500', '#34C759', '#007AFF', '#AF52DE', '#FF2D55'];

/**
 * [EN] The space under the last row of a demo list (vp): the tab bar (49), the raised plus button above it and the
 *      gesture bar, so no row stays hidden behind them (HarmonyOS screenshot issue 5).
 * [CN] 演示列表最后一行下方的空间（vp）：TabBar（49）、其上方凸起的 PlusButton 与手势条，使任何一行都不会被挡住（鸿蒙截图问题 5）。
 */
const CYL_LIST_END_INSET: number = 120;

/**
 * [EN] The size of a skin's plus image (vp), smaller than the default 52 vp button (HarmonyOS screenshot issue 10).
 * [CN] 皮肤加号图片的尺寸（vp），小于默认 52 vp 的按钮（鸿蒙截图问题 10）。
 */
const CYL_SKIN_PLUS_IMAGE_SIZE: number = 40;

/**
 * [EN] CYLPlusButtonSubclass of the Objective-C Example: "Post" at index 2, raised by 14 vp
 *      (+constantOfPlusButtonCenterYOffsetForTabBarHeight: -14), title aligned with the tab titles, green when selected,
 *      and a page of its own (+plusChildViewController).
 * [CN] Objective-C Example 的 CYLPlusButtonSubclass：位于第 2 位的「发布」，上移 14 vp，标题与 Tab 标题对齐，选中时为绿色，带自己的页面。
 */
const CYL_PLUS: CYLPlusButton = {
  image: $r('app.media.post_normal'),
  selectedImage: $r('app.media.post_highlight'),
  title: $r('app.string.tab_post'),
  index: 2,
  centerYOffset: -14,
  imageSize: 52,
  alignsTitle: true,
  identifier: 'plus',
  selectable: true,
};

/** [EN] The icon size of a badge row (CYLBadgeRowHeight leaves room for the badge). [CN] 角标行的图标尺寸。 */
interface DemoPushParams {
  mode?: string;
  title?: string;
  color?: string;
  hidesNavigationBar?: boolean;
  withPlus?: boolean;
  file?: string;
}

const CYL_BADGE_ICON: number = 30;

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @State plusBadge: number = 1;
  // [EN] Item 2: the Taobao-style cover on Home after 1.5 s (setSelectedCoverShow:). [CN] 第 2 项：1.5 秒后首页的仿淘宝封面。
  @State covers: (ResourceStr | undefined)[] = [];
  @State tabs: CYLTabBarItemAttributes[] = CYL_TABS.slice();
  @State titleOffset: CYLOffset = { horizontal: 0, vertical: 0 };
  @State appearanceIndex: number = 0;
  @State tabBarHidden: boolean = false;
  @State tabBarHeight: number = 49;
  @State itemEdgeInsets: CYLEdgeInsets = { top: 0, left: 0, bottom: 0, right: 0 };
  @State itemBackgrounds: boolean = false;
  @State unloads: boolean = false;
  @State languageIndex: number = 0;
  /** [EN] Item 53: "Home (n)" after a Home badge row is tapped; -1 none. [CN] 第 53 项：点击首页角标行后的「首页(n)」；-1 表示无。 */
  @State homeTitleRow: number = -1;
  @State plus: CYLPlusButton = CYL_PLUS;
  /** [EN] Item 27: tabs whose page was replaced (issue #481). [CN] 第 27 项：页面被替换的 Tab（issue #481）。 */
  @State replacedTabs: number[] = [];
  /** [EN] Item 29: login state (issue #19); "Me" needs a login. [CN] 第 29 项：登录状态；「我的」需要登录。 */
  @State loggedIn: boolean = true;
  /** [EN] Toggled update rows, by id. [CN] 已切换的更新行。 */
  @State toggled: string[] = [];
  /** [EN] Items 33-37: tab interactions (#535). [CN] 第 33-37 项：Tab 交互（#535）。 */
  @State tapAnimation: CYLTabButtonTapAnimationType = CYLTabButtonTapAnimationType.None;
  @State feedbackStep: number = 0;
  @State longPressIndex: number = 1;
  @State doubleTapIndex: number = 1;
  @State swipeEnabled: boolean = false;
  @State slideTransition: boolean = false;
  @State minimizeBehavior: CYLTabBarMinimizeBehavior = CYLTabBarMinimizeBehavior.Never;
  /** [EN] Items 9, 15, 32: the current skin (CYLThemeManager). [CN] 第 9、15、32 项：当前皮肤。 */
  @State theme: DemoTheme = DEMO_THEMES[0];
  /** [EN] Item 7: the tab bar style and the key of the tab bar on screen (a new key builds a new one). [CN] 第 7 项：TabBar 样式与当前 TabBar 的 key（新 key 会新建 TabBar）。 */
  @State styleType: CYLTabBarStyleType = CYLTabBarStyleType.Default;
  @State tabBarKey: number = 0;
  private badges: CYLBadge[] = CYL_TABS.map(() => new CYLBadge());
  private plusButtonBadge: CYLBadge = new CYLBadge();
  /** [EN] The badge of each badge row, per page. [CN] 每个页面每个角标行的角标。 */
  private rowBadges: Map<string, CYLBadge[]> = new Map();

  /** [EN] CYLThemeDidChangeNotification: applies the skin to the tabs, the colors and the plus button. [CN] 应用皮肤。 */
  private themeListener = (manager: CYLThemeManager, identifier: string | undefined, theme: Object | undefined): void => {
    const skin = (theme as DemoTheme) ?? DEMO_THEMES[0];
    this.theme = skin;
    this.tabs.forEach((tab: CYLTabBarItemAttributes, i: number) => this.updateTab(i, (item: CYLTabBarItemAttributes) => {
      const icon = skin.icons.length > 0 ? $rawfile(skin.iconPath(skin.icons[i % skin.icons.length])) : undefined;
      item.image = icon ?? CYL_TABS[i].image;
      item.selectedImage = icon ?? CYL_TABS[i].selectedImage;
      item.lottieFilePath = icon !== undefined || skin.iconURLs.length > 0 ? undefined : CYL_TABS[i].lottieFilePath;
      item.imageURL = skin.iconURLs.length > 0 ? skin.iconURLs[i % skin.iconURLs.length][0] : undefined;
      item.selectedImageURL = skin.iconURLs.length > 0 ? skin.iconURLs[i % skin.iconURLs.length][1] : undefined;
      item.title = skin.titlePrefix !== undefined ? `${skin.titlePrefix} ${['Home', 'Nearby', 'Messages', 'Me'][i]}` : CYL_TABS[i].title;
    }));
    const plusIcon: ResourceStr | undefined = skin.icons.length > 0 ? $rawfile(skin.iconPath(skin.icons[skin.icons.length - 1])) : skin.plusURL;
    const copy: CYLPlusButton = {
      image: plusIcon ?? CYL_PLUS.image, selectedImage: plusIcon ?? CYL_PLUS.selectedImage, title: CYL_PLUS.title,
      // [EN] FIX (HarmonyOS screenshot issue 10): a skin's plus image is a tab-style icon without the button's round
      //      background, so it is drawn smaller than the 52 vp button and no longer spreads over the list above the bar.
      // [CN] 修复（鸿蒙截图问题 10）：皮肤的加号图片是 Tab 风格的图标，没有按钮的圆形背景，因此画得比 52 vp 的按钮小，不再铺到 TabBar 上方的列表上。
      index: CYL_PLUS.index, centerYOffset: CYL_PLUS.centerYOffset,
      imageSize: plusIcon !== undefined ? CYL_SKIN_PLUS_IMAGE_SIZE : CYL_PLUS.imageSize,
      alignsTitle: CYL_PLUS.alignsTitle, identifier: CYL_PLUS.identifier, selectable: CYL_PLUS.selectable,
    };
    this.plus = copy;
  };

  /** [EN] Item 9: the navigation bar "Skin" picker. [CN] 第 9 项：导航栏「换肤」选择器。 */
  private showSkinPicker(): void {
    const names = DEMO_THEMES.map((theme: DemoTheme) => theme.name);
    this.getUIContext().showTextPickerDialog({
      range: names,
      selected: Math.max(0, names.indexOf(this.theme.name)),
      onAccept: (value: TextPickerResult) => {
        CYLThemeManagerCenter.defaultThemeManager.currentThemeIdentifier = names[value.index as number];
      },
    });
  }

  aboutToDisappear(): void {
    CYLThemeManagerCenter.defaultThemeManager.removeListener(this.themeListener);
  }

  aboutToAppear(): void {
    demoRegisterThemes();
    CYLThemeManagerCenter.defaultThemeManager.addListener(this.themeListener);
    // [EN] SceneDelegate.m -setUpBadgeAppearance (#425). [CN] 全局角标偏移。
    CYLBadgeAppearance.globalAppearance.centerOffset = { horizontal: -5, vertical: 3 };
    // [EN] cyl_demo_showPlusButtonBadge: 1 at launch. [CN] 启动时加号角标为 1。
    this.plusButtonBadge.cyl_showBadgeValue('1');
    const current = i18n.System.getAppPreferredLanguage();
    this.languageIndex = Math.max(0, DEMO_LANGUAGES.indexOf(current));
    for (const page of [DEMO_HOME, DEMO_CITY, DEMO_MESSAGE, DEMO_ME]) {
      const count = Math.max(page === DEMO_HOME || page === DEMO_ME ? 30 : 15, cyl_badgeStyleCount());
      const badges: CYLBadge[] = [];
      for (let row = 0; row < count; row++) {
        const badge = new CYLBadge();
        cyl_applyBadgeSample(badge, row, CYL_BADGE_ICON);
        badges.push(badge);
      }
      this.rowBadges.set(page, badges);
    }
    // [EN] Item 6 (MainTabBarController.m, after 1.5 s so the animations are easy to see): Home a dot (random color,
    //      radius 5.5, breathe), Nearby 8 (purple, scale), Messages 100 -> 99+ (bounce), Me NEW (offset (-1, 3), breathe).
    // [CN] 第 6 项（1.5 秒后，便于看清动画）：首页红点、同城 8、消息 99+、我的 NEW。
    this.showLaunchBadges();
  }

  /**
   * [EN] Item 6 after 1.5 s; again for each new tab bar (item 7). [CN] 1.5 秒后显示第 6 项的角标；每个新 TabBar 再次显示（第 7 项）。
   */
  showLaunchBadges(): void {
    setTimeout(() => {
      const home = this.badges[0];
      home.backgroundColor = CYL_RANDOM_COLORS[Math.floor(Math.random() * CYL_RANDOM_COLORS.length)];
      home.radius = 11 / 2;
      home.cyl_showBadgeValue('', CYLBadgeAnimationType.Breathe);
      this.badges[1].backgroundColor = '#AF52DE';
      this.badges[1].cyl_showBadgeValue('8', CYLBadgeAnimationType.Scale);
      this.badges[2].cyl_showBadgeValue('100', CYLBadgeAnimationType.Bounce);
      this.badges[3].centerOffset = { horizontal: -1, vertical: 3 };
      this.badges[3].cyl_showBadgeValue('NEW', CYLBadgeAnimationType.Breathe);
      // [EN] The cover replaces the Home button, so its badge is cleared (MainTabBarController.m). [CN] 封面替换首页按钮，因此清除其角标。
      this.covers = [$r('app.media.home_select_cover')];
      this.badges[0].cyl_clearBadge();
    }, 1500);
  }

  // MARK: - Rows 行

  private push(url: string, params: Object): void {
    this.getUIContext().getRouter().pushUrl({ url: url, params: params });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private choose(title: string, names: string[], current: number, picked: (index: number) => void): void {
    this.getUIContext().getPromptAction().showActionMenu({
      title: title,
      buttons: names.slice(0, 6).map((name: string, index: number) => {
        const button: promptAction.Button = { text: (index === current ? '✓ ' : '') + name, color: '#007AFF' };
        return button;
      }) as [promptAction.Button, promptAction.Button?, promptAction.Button?, promptAction.Button?, promptAction.Button?, promptAction.Button?],
    }).then((result: promptAction.ActionMenuSuccessResponse) => picked(result.index)).catch(() => {});
  }

  /** [EN] General: Language (item 11), Simulate memory warning (item 12). [CN] 通用：语言（第 11 项）、模拟内存警告（第 12 项）。 */
  private generalRows(): DemoRow[] {
    return [
      {
        id: 'language', title: CYLLocalizedString('语言'), subtitle: CYLLocalizedString('点击切换语言'),
        action: () => this.choose(CYLLocalizedString('语言'), DEMO_LANGUAGE_NAMES, this.languageIndex, (index: number) => {
          // [EN] setAppPreferredLanguage reloads the app's resources ($r) in the chosen language. [CN] 以所选语言重新加载应用资源。
          i18n.System.setAppPreferredLanguage(DEMO_LANGUAGES[index] === '' ? 'default' : DEMO_LANGUAGES[index]);
          this.languageIndex = index;
        }),
      },
      {
        id: 'memory-warning', title: CYLLocalizedString('模拟内存警告'),
        subtitle: CYLLocalizedString('卸载未选中的 Tab，切换时重新加载'),
        action: () => {
          this.unloads = true;
          // [EN] Let the @Prop reach the controller first. [CN] 先让 @Prop 传到控制器。
          setTimeout(() => cyl_simulateMemoryWarning(), 0);
        },
      },
    ];
  }

  /** [EN] CYLSimulateMemoryWarningReport: one line per tab. [CN] 每个 Tab 一行。 */
  private memoryWarningReport(unloaded: number[], loaded: number[]): void {
    const names = [CYLLocalizedString('首页'), CYLLocalizedString('同城'), CYLLocalizedString('消息'), CYLLocalizedString('我的')];
    const lines = names.map((name: string, index: number) => {
      const state = loaded.indexOf(index) >= 0 ? CYLLocalizedString('保留') : (unloaded.indexOf(index) >= 0 ? CYLLocalizedString('已卸载') : CYLLocalizedString('未加载'));
      return `${index}. ${name}: ${state}${index === this.selectedIndex ? ' · ' + CYLLocalizedString('选中') : ''}`;
    });
    this.getUIContext().getPromptAction().showDialog({ title: CYLLocalizedString('内存警告'), message: lines.join('\n'), buttons: [{ text: CYLLocalizedString('OK'), color: '#007AFF' }] });
  }

  /** [EN] Tab bar appearance and the FlatDesign rows (items 13, 14, 56, 17, 18, 19). [CN] TabBar 外观与扁平样式行。 */
  private appearanceRows(): DemoRow[] {
    return [
      {
        id: 'title-offset', title: CYLLocalizedString('标题偏移（titlePositionAdjustment）'),
        subtitle: CYLLocalizedString('点击切换所有 Tab 标题的垂直偏移，当前：%@', `(${this.titleOffset.horizontal}, ${this.titleOffset.vertical})`),
        action: () => {
          const next = DEMO_TITLE_OFFSETS[(DEMO_TITLE_OFFSETS.indexOf(this.titleOffset.vertical) + 1) % DEMO_TITLE_OFFSETS.length];
          this.titleOffset = { horizontal: 0, vertical: next };
        },
      },
      {
        id: 'appearance', title: CYLLocalizedString('standardAppearance 主题（液态玻璃与扁平样式共用）'),
        subtitle: CYLLocalizedString('点击切换 tabBar.standardAppearance，当前：%@', CYLLocalizedString(DEMO_APPEARANCES[this.appearanceIndex].name)),
        action: () => {
          this.appearanceIndex = (this.appearanceIndex + 1) % DEMO_APPEARANCES.length;
          this.applyItemBackgrounds();
        },
      },
      {
        id: 'tab-bar-hidden', title: CYLLocalizedString('Show / hide CYLFlatDesignTabBar'),
        subtitle: CYLLocalizedString('tabBarHidden = %@; hidden, it comes back after 2 s', `${this.tabBarHidden}`),
        action: () => {
          this.tabBarHidden = !this.tabBarHidden;
          if (this.tabBarHidden) {
            setTimeout(() => this.tabBarHidden = false, 2000);
          }
        },
      },
      {
        id: 'skin', title: CYLLocalizedString('换肤（主题，issue #216）'), subtitle: CYLLocalizedString('点击选择主题：TabBar 的背景、图标与文字颜色原地切换，所有 TabBar 样式均适用。当前：%@', CYLLocalizedString(this.theme.titleKey)),
        action: () => this.showSkinPicker(),
      },
      {
        id: 'minimize', title: CYLLocalizedString('滚动时缩小 / 隐藏 TabBar（issue #13）'),
        subtitle: CYLLocalizedString('cyl_tabBarMinimizeBehavior = %@; tap to choose, then scroll this list', ['Automatic', 'Never', 'OnScrollDown', 'OnScrollUp'][this.minimizeBehavior]),
        action: () => this.choose('cyl_tabBarMinimizeBehavior', ['Automatic', 'Never', 'OnScrollDown', 'OnScrollUp'],
          this.minimizeBehavior, (index: number) => this.minimizeBehavior = index as CYLTabBarMinimizeBehavior),
      },
      {
        id: 'tab-bar-height', title: CYLLocalizedString('改变 CYLFlatDesignTabBar 高度'), subtitle: `tabBarHeight = ${this.tabBarHeight}`,
        action: () => this.tabBarHeight = this.tabBarHeight === 49 ? 69 : 49,
      },
      {
        id: 'items-not-centered', title: CYLLocalizedString('Change CYLFlatDesignTabBarItem 不居中显示（系统效果）'),
        // [EN] FIX (HarmonyOS screenshot issue 15): a subtitle like its neighbors. [CN] 修复（鸿蒙截图问题 15）：与相邻行一样带副标题。
        subtitle: CYLLocalizedString('cyl_itemEdgeInsets: zero, the tabs fill the bar'),
        action: () => this.itemEdgeInsets = { top: 0, left: 0, bottom: 0, right: 0 },
      },
      {
        id: 'items-centered', title: CYLLocalizedString('Change CYLFlatDesignTabBarItem 居中显示'), subtitle: CYLLocalizedString('cyl_itemEdgeInsets: 15% of a tab width free at each end'),
        action: () => {
          const inset = this.getUIContext().px2vp(display_width()) / 5 * 0.15;
          this.itemEdgeInsets = { top: 0, left: inset, bottom: 0, right: inset };
        },
      },
      {
        id: 'item-background', title: CYLLocalizedString('设置 CYLFlatDesignTabBarItem 背景色'),
        subtitle: CYLLocalizedString('CYLTabBarItemBackgroundColor / CYLTabBarItemSelectedBackgroundColor'),
        action: () => {
          this.itemBackgrounds = !this.itemBackgrounds;
          this.applyItemBackgrounds();
        },
      },
    ];
  }

  /** [EN] -updateTabBarItemAtIndex:attributes: for the background rows and the capsule theme. [CN] 更新各 Tab 的背景属性。 */
  private applyItemBackgrounds(): void {
    const capsule = DEMO_APPEARANCES[this.appearanceIndex].capsule
      ?? (this.styleType === CYLTabBarStyleType.LiquidGlass ? CYLLiquidGlassSelectionColor : undefined);
    this.tabs = this.tabs.map((item: CYLTabBarItemAttributes) => {
      const copy: CYLTabBarItemAttributes = {
        title: item.title, selectedTitle: item.selectedTitle, image: item.image, selectedImage: item.selectedImage,
        identifier: item.identifier, darkImage: item.darkImage, lottieFilePath: item.lottieFilePath, lottieDarkFilePath: item.lottieDarkFilePath,
        lottieSize: item.lottieSize, titlePositionAdjustment: item.titlePositionAdjustment,
        backgroundColor: this.itemBackgrounds ? '#FFF0C8' : undefined,
        selectedBackgroundColor: this.itemBackgrounds ? '#FFCC00' : capsule,
      };
      return copy;
    });
  }

  /** [EN] Jump and compare (items 45, 46, 47). [CN] 跳转与对比（第 45、46、47 项）。 */
  private jumpRows(): DemoRow[] {
    return [
      {
        id: 'system-tab-bar', title: CYLLocalizedString('和系统 UITabBar 比较'),
        subtitle: CYLLocalizedString('ArkUI Tabs, the HarmonyOS system tab bar, with the same tabs'),
        action: () => this.push('pages/SystemTabs', {} as DemoPushParams),
      },
      {
        id: 'system-tab-bar-plus', title: CYLLocalizedString('Push To 系统 UITabBarController（另一个 PlusButton）'),
        subtitle: CYLLocalizedString('The system bar has no plus button: a floating button stands in'),
        action: () => this.push('pages/SystemTabs', { withPlus: true } as DemoPushParams),
      },
      {
        id: 'another-tab-bar', title: CYLLocalizedString('Push to another CYLTabBarController (another PlusButton)'),
        subtitle: CYLLocalizedString('A tab bar controller of another context, with a square plus button'),
        action: () => this.push('pages/AnotherTabBar', {} as DemoPushParams),
      },
      {
        id: 'pop-push', title: CYLLocalizedString('cyl_pop / cyl_push 系列方法演示'),
        subtitle: CYLLocalizedString('cyl_pushViewController, cyl_popSelectTabBarChildViewControllerAtIndex, cyl_pushOrPopToViewController'),
        action: () => cyl_pushViewController('pages/PopPushDemo'),
      },
    ];
  }

  /** [EN] Configuration file (item 43). [CN] 配置文件（第 43 项）。 */
  private configurationRows(): DemoRow[] {
    return ['json', 'json5', 'jsonc'].map((format: string) => {
      const row: DemoRow = {
        id: `configuration-${format}`, title: `${CYLLocalizedString('从配置文件创建 TabBarController')} (.${format})`,
        action: () => this.push('pages/ConfigurationDemo', { file: `configurations/cyl_tabbar_configuration.${format}` } as DemoPushParams),
      };
      return row;
    }).concat([{
      // [EN] FIX: issue #415: SVGA tab icons from a configuration file (CYLTabBarSVGAFilePath, CYLTabBarSVGASize), as the
      //      iOS, Android, React Native, Flutter and mini program demos. [CN] FIX: issue #415：来自配置文件的 SVGA Tab 图标。
      id: 'configuration-svga', title: CYLLocalizedString('SVGA Tab 图标（配置文件）'),
      subtitle: CYLLocalizedString('CYLTabBarSVGAFilePath：选中时播放一次，未选中时显示第一帧'),
      action: () => this.push('pages/ConfigurationDemo', { file: 'configurations/cyl_tabbar_configuration_svga.json' } as DemoPushParams),
    } as DemoRow, {
      // [EN] Item 44: broken and unusual files (A2–E1); each shows a typed error or the tab bar created safely.
      // [CN] 第 44 项：损坏与异常的文件（A2–E1）；每个显示错误或安全创建的 TabBar。
      id: 'configuration-failures', title: CYLLocalizedString('配置文件：模拟意外情况'),
      action: () => this.push('pages/ConfigurationFailures', {} as DemoPushParams),
    } as DemoRow]);
  }

  /** [EN] The badge rows of a page (items 50, 53), each with its action as BadgeRows of the Android port. [CN] 页面的角标行。 */
  private badgeRows(page: string): DemoRow[] {
    const badges = this.rowBadges.get(page) ?? [];
    return badges.map((badge: CYLBadge, row: number) => {
      const item: DemoRow = {
        id: `badge-${row}`, title: cyl_badgeTitleForRow(row), badgeRow: row,
        subtitle: CYLLocalizedString('%@ CYLTabBarController on HarmonyOS', page),
        action: () => this.badgeRowTapped(page, row),
      };
      return item;
    });
  }

  private badgeRowTapped(page: string, row: number): void {
    if (page === DEMO_HOME) {
      this.homeTitleRow = row;
      this.push('pages/TextPage', { title: 'CYLBaseViewController', color: '#FFA500' } as DemoPushParams);
    } else if (page === DEMO_MESSAGE) {
      this.push('pages/AnotherTabBar', {} as DemoPushParams);
    } else if (page === DEMO_CITY) {
      this.push('pages/TextPage', { title: 'CYLDetailsViewController (navigation bar hidden)', color: '#5AC8FA', hidesNavigationBar: true } as DemoPushParams);
    } else {
      this.badges[3].cyl_showBadgeValue(`${row}`, CYLBadgeAnimationType.None);
      this.push('pages/TextPage', { title: 'testPush', color: '#FF0000' } as DemoPushParams);
    }
  }

  private isOn(id: string): boolean {
    return this.toggled.indexOf(id) >= 0;
  }

  /** [EN] Flips a toggle row; returns its new state. [CN] 切换一行；返回新状态。 */
  private flip(id: string): boolean {
    const on = !this.isOn(id);
    this.toggled = on ? this.toggled.concat([id]) : this.toggled.filter((t: string) => t !== id);
    return on;
  }

  /** [EN] -updateTabBarItemAtIndex:attributes: with a change applied to a copy. [CN] 对副本应用修改后更新 Tab。 */
  private updateTab(index: number, change: (item: CYLTabBarItemAttributes) => void): void {
    const tabs = this.tabs.slice();
    const copy: CYLTabBarItemAttributes = {
      title: tabs[index].title, selectedTitle: tabs[index].selectedTitle, image: tabs[index].image,
      selectedImage: tabs[index].selectedImage, identifier: tabs[index].identifier, darkImage: tabs[index].darkImage,
      lottieFilePath: tabs[index].lottieFilePath, lottieDarkFilePath: tabs[index].lottieDarkFilePath, lottieSize: tabs[index].lottieSize,
      titlePositionAdjustment: tabs[index].titlePositionAdjustment, backgroundColor: tabs[index].backgroundColor,
      selectedBackgroundColor: tabs[index].selectedBackgroundColor, imageURL: tabs[index].imageURL,
      selectedImageURL: tabs[index].selectedImageURL, gifFilePath: tabs[index].gifFilePath,
    };
    change(copy);
    tabs[index] = copy;
    this.tabs = tabs;
  }

  private pageIndex(page: string): number {
    return Math.max(0, CYL_TABS.findIndex((item: CYLTabBarItemAttributes) => item.identifier === page));
  }

  /** [EN] Update tabs in place (items 21-26). [CN] 原地更新 Tab（第 21-26 项）。 */
  private tabItemUpdateRows(page: string): DemoRow[] {
    const index = this.pageIndex(page);
    const icons: string[][] = [
      ['https://cdn-icons-png.flaticon.com/512/3132/3132732.png', 'https://cdn-icons-png.flaticon.com/512/3132/3132779.png'],
      ['https://cdn-icons-png.flaticon.com/512/1077/1077035.png', 'https://cdn-icons-png.flaticon.com/512/1077/1077063.png'],
    ];
    const local: Resource[] = [$r('app.media.img_tab_home_0'), $r('app.media.img_tab_message_0'), $r('app.media.app_icon')];
    const localSelected: Resource[] = [$r('app.media.img_tab_home_1'), $r('app.media.img_tab_message_1'), $r('app.media.app_icon')];
    return [
      {
        id: 'title', title: CYLLocalizedString('更换 Tab 标题'), subtitle: CYLLocalizedString('原地更换当前页 Tab 的标题，再点恢复'),
        action: () => {
          const on = this.flip(`title-${page}`);
          this.updateTab(index, (item: CYLTabBarItemAttributes) => item.title = on ? 'Courses' : CYL_TABS[index].title);
        },
      },
      {
        id: 'network-icon', title: CYLLocalizedString('下载网络图标'), subtitle: CYLLocalizedString('从网络下载当前页 Tab 的图标（带缓存），再点恢复'),
        action: () => {
          const on = this.flip(`network-${page}`);
          this.updateTab(index, (item: CYLTabBarItemAttributes) => {
            item.imageURL = on ? icons[0][0] : undefined;
            item.selectedImageURL = on ? icons[0][1] : undefined;
          });
        },
      },
      {
        id: 'all-network-icons', title: CYLLocalizedString('批量下载网络图标'), subtitle: CYLLocalizedString('下载并更新所有 Tab 的图标，再点恢复'),
        action: () => {
          const on = this.flip('all-network');
          this.tabs.forEach((tab: CYLTabBarItemAttributes, i: number) => this.updateTab(i, (item: CYLTabBarItemAttributes) => {
            item.imageURL = on ? icons[i % 2][0] : undefined;
            item.selectedImageURL = on ? icons[i % 2][1] : undefined;
          }));
        },
      },
      {
        id: 'all-local-icons', title: CYLLocalizedString('批量使用本地图标'), subtitle: CYLLocalizedString('用本地图片（图片名、文件路径、UIImage、文件 URL）更新所有 Tab 的图标，再点恢复'),
        action: () => {
          const on = this.flip('all-local');
          this.tabs.forEach((tab: CYLTabBarItemAttributes, i: number) => this.updateTab(i, (item: CYLTabBarItemAttributes) => {
            item.image = on ? local[i % 3] : CYL_TABS[i].image;
            item.selectedImage = on ? localSelected[i % 3] : CYL_TABS[i].selectedImage;
            item.lottieFilePath = on ? undefined : CYL_TABS[i].lottieFilePath;
          }));
        },
      },
      {
        id: 'gif', title: CYLLocalizedString('GIF 动图图标'), subtitle: CYLLocalizedString('当前页 Tab 显示 GIF 动图，再点恢复'),
        action: () => {
          const on = this.flip(`gif-${page}`);
          this.updateTab(index, (item: CYLTabBarItemAttributes) => item.gifFilePath = on ? 'gif/cyl_tab_sample_animated.gif' : undefined);
        },
      },
      {
        id: 'all-titles', title: CYLLocalizedString('批量更换标题'), subtitle: CYLLocalizedString('一次更新所有 Tab 的标题，再点恢复'),
        action: () => {
          const on = this.flip('all-titles');
          this.tabs.forEach((tab: CYLTabBarItemAttributes, i: number) => this.updateTab(i, (item: CYLTabBarItemAttributes) => {
            item.title = on ? `Tab ${i + 1}` : CYL_TABS[i].title;
          }));
        },
      },
    ];
  }

  /** [EN] Tab pages, selection and login (items 27-29). [CN] Tab 页面、选中与登录（第 27-29 项）。 */
  private pageRows(page: string): DemoRow[] {
    const index = this.pageIndex(page);
    return [
      {
        id: 'replace', title: CYLLocalizedString('替换相邻 Tab 的页面'),
        subtitle: CYLLocalizedString('把当前 Tab 两侧的 Tab 换成其他页面（issue #481），再点恢复'),
        action: () => {
          const sides = [index - 1, index + 1].filter((side: number) => side >= 0 && side < CYL_TABS.length);
          const on = this.flip(`replace-${page}`);
          this.replacedTabs = on ? sides : [];
          sides.forEach((side: number) => this.updateTab(side, (item: CYLTabBarItemAttributes) => {
            item.title = on ? `Replaced ${side + 1}` : CYL_TABS[side].title;
          }));
        },
      },
      {
        id: 'selected-index', title: CYLLocalizedString('selectedIndex 与 PlusButton（issue #515）'),
        subtitle: CYLLocalizedString('selectedIndex = %@ (the plus button\'s page is %@, never a tab index); tap for the next tab', this.selectedIndex, CYLPlusButtonPageIndex),
        action: () => this.selectedIndex = this.selectedIndex < 0 ? 0 : (this.selectedIndex + 1) % CYL_TABS.length,
      },
      {
        id: 'login', title: CYLLocalizedString(this.loggedIn ? '登录状态：已登录' : '登录状态：未登录'), subtitle: CYLLocalizedString('The “Me” tab needs a login (issue #19); tap to toggle'),
        action: () => {
          this.loggedIn = !this.loggedIn;
          if (!this.loggedIn && this.selectedIndex === 3) {
            this.selectedIndex = 0;
          }
        },
      },
    ];
  }

  /** [EN] PlusButton (items 30, 31). [CN] PlusButton（第 30、31 项）。 */
  private plusButtonRows(): DemoRow[] {
    const scale = this.plus.touchableAreaScale ?? 1;
    const cases = [CYLLocalizedString('加载图片'), CYLLocalizedString('替换为更大的图片'), CYLLocalizedString('移除图片'), CYLLocalizedString('加载背景图片')];
    const modes = ['late-load', 'late-replace', 'late-remove', 'late-background'];
    return [
      {
        id: 'late-image', title: CYLLocalizedString('PlusButton 图片之后才加载'),
        subtitle: CYLLocalizedString('Pushes a tab bar controller whose plus button image changes 2 s later; the layout must not move'),
        action: () => this.choose(CYLLocalizedString('PlusButton 图片之后才加载'), cases, -1,
          (index: number) => this.push('pages/AnotherTabBar', { mode: modes[index] } as DemoPushParams)),
      },
      {
        id: 'touchable-area', title: CYLLocalizedString('PlusButton 点击范围（issue #91）'),
        subtitle: CYLLocalizedString('Shows the touchable area in translucent red: %@; scale %@x; tap to cycle 1x, 1.5x, 2x, off', `${this.plus.showsTouchableArea === true}`, scale),
        action: () => {
          const shows = this.plus.showsTouchableArea === true;
          const next = !shows ? 1 : (scale >= 2 ? 0 : scale + 0.5);
          const copy: CYLPlusButton = {
            image: CYL_PLUS.image, selectedImage: CYL_PLUS.selectedImage, title: CYL_PLUS.title, index: CYL_PLUS.index,
            centerYOffset: CYL_PLUS.centerYOffset, imageSize: CYL_PLUS.imageSize, alignsTitle: CYL_PLUS.alignsTitle,
            identifier: CYL_PLUS.identifier, selectable: CYL_PLUS.selectable,
            showsTouchableArea: next > 0, touchableAreaScale: next > 0 ? next : 1,
          };
          this.plus = copy;
        },
      },
    ];
  }

  /** [EN] Tab interactions (items 33-37). [CN] Tab 交互（第 33-37 项）。 */
  private interactionRows(): DemoRow[] {
    const tapNames = [CYLLocalizedString('无'), CYLLocalizedString('放大再缩小'), CYLLocalizedString('从小放大'), CYLLocalizedString('弹性'), CYLLocalizedString('旋转'), CYLLocalizedString('翻转')];
    const feedbackNames = [CYLLocalizedString('关闭'), CYLLocalizedString('默认点击声'), CYLLocalizedString('自定义音频文件（cyl_tabButtonTapSoundURL）'), CYLLocalizedString('轻触感反馈'),
      CYLLocalizedString('中等触感反馈'), CYLLocalizedString('重触感反馈'), CYLLocalizedString('点击声 + 触感反馈')];
    const longPress = [300, 500, 1000];
    const doubleTap = [200, 300, 500];
    return [
      {
        id: 'tap-animation', title: CYLLocalizedString('Tab 点击动画（issue #535）'),
        subtitle: CYLLocalizedString('点击切换 Tab 与 PlusButton 的点击动画，当前：%@', tapNames[this.tapAnimation]),
        action: () => this.tapAnimation = (this.tapAnimation + 1) % tapNames.length,
      },
      {
        id: 'feedback', title: CYLLocalizedString('Tab 点击声音与触感反馈（issue #535）'),
        subtitle: CYLLocalizedString('点击切换，然后点击任意 Tab 或 PlusButton 试听。触感反馈只在真机上振动。当前：%@', feedbackNames[this.feedbackStep]),
        action: () => this.feedbackStep = (this.feedbackStep + 1) % feedbackNames.length,
      },
      {
        id: 'long-press', title: CYLLocalizedString('长按 Tab（issue #535）'),
        subtitle: CYLLocalizedString('打开开关后长按任意 Tab 或 PlusButton，会弹出该按钮的标识。'),
        action: () => this.toast(CYLLocalizedString('Long press a tab or the plus button')),
      },
      {
        id: 'gesture-timings', title: CYLLocalizedString('长按时长与双击间隔（issue #535 / #152）'),
        subtitle: CYLLocalizedString('cyl_tabBarItemLongPressDuration = %@ ms, cyl_tabBarItemDoubleTapInterval = %@ ms; tap to cycle; double tap a tab to see it', longPress[this.longPressIndex], doubleTap[this.doubleTapIndex]),
        action: () => {
          this.longPressIndex = (this.longPressIndex + 1) % longPress.length;
          this.doubleTapIndex = (this.doubleTapIndex + 1) % doubleTap.length;
        },
      },
      {
        id: 'swipe', title: CYLLocalizedString('左右滑动切换 Tab（issue #535）'),
        subtitle: CYLLocalizedString('On: %@; swipe the page left / right', `${this.swipeEnabled}`),
        action: () => this.swipeEnabled = !this.swipeEnabled,
      },
      {
        id: 'slide-transition', title: CYLLocalizedString('滑动转场（CYLTabBarSlideTransitionAnimator）'),
        subtitle: CYLLocalizedString('On: %@; the new page slides in from the side of its tab', `${this.slideTransition}`),
        action: () => this.slideTransition = !this.slideTransition,
      },
      {
        id: 'previous-tab', title: CYLLocalizedString('Previous tab (cyl_selectPreviousTab, issue #535)'),
        action: () => this.selectedIndex = ((this.selectedIndex < 0 ? 0 : this.selectedIndex) + CYL_TABS.length - 1) % CYL_TABS.length,
      },
      {
        id: 'next-tab', title: CYLLocalizedString('Next tab (cyl_selectNextTab, issue #535)'),
        action: () => this.selectedIndex = ((this.selectedIndex < 0 ? 0 : this.selectedIndex) + 1) % CYL_TABS.length,
      },
    ];
  }

  /** [EN] Messages: push tab bar controllers (item 52, issue #202). [CN] 消息页：push TabBarController（第 52 项，issue #202）。 */
  private messageRows(): DemoRow[] {
    return [
      {
        id: 'same-context', title: CYLLocalizedString('Push 同一个 context 的 TabBarController（同一个 PlusButton 类）'),
        action: () => this.push('pages/AnotherTabBar', { mode: 'same' } as DemoPushParams),
      },
      {
        id: 'new-context', title: CYLLocalizedString('Push 新 context 的 TabBarController（PlusButton 带可点击的 X 子按钮，issue #202）'),
        subtitle: CYLLocalizedString('点击 PlusButton 右上角的 X：X 随机改变颜色，PlusButton 不响应'),
        action: () => this.push('pages/AnotherTabBar', { mode: 'close' } as DemoPushParams),
      },
    ];
  }

  /** [EN] No base class, and helpers (items 39-42, issue #535). [CN] 无需基类与辅助方法（第 39-42 项）。 */
  private helperRows(page: string): DemoRow[] {
    const index = this.pageIndex(page);
    return [
      {
        id: 'hide-navigation-bar', title: CYLLocalizedString('不继承基类隐藏导航栏（issue #535）'),
        subtitle: CYLLocalizedString('Pushes a page that hides the navigation bar while shown, with no base class'),
        action: () => this.push('pages/TextPage', { title: 'The navigation bar is hidden while this page is shown', color: '#FFCC00', hidesNavigationBar: true } as DemoPushParams),
      },
      {
        id: 'outside-superview', title: CYLLocalizedString('超出父视图响应点击（issue #535）'),
        subtitle: CYLLocalizedString('The plus button sticks out of the bar; its part above the bar responds (shown in red)'),
        action: () => {
          const copy: CYLPlusButton = {
            image: this.plus.image, selectedImage: this.plus.selectedImage, title: this.plus.title, index: this.plus.index,
            centerYOffset: this.plus.centerYOffset, imageSize: this.plus.imageSize, alignsTitle: this.plus.alignsTitle,
            identifier: this.plus.identifier, selectable: this.plus.selectable,
            showsTouchableArea: this.plus.showsTouchableArea !== true, touchableAreaScale: this.plus.touchableAreaScale,
          };
          this.plus = copy;
        },
      },
      {
        id: 'bundle-image', title: CYLLocalizedString('从 bundle 加载图片（issue #535）'),
        subtitle: 'The image of this page\'s tab from the app\'s rawfile (the resource bundle of iOS); tap again to restore',
        action: () => {
          const on = this.flip(`bundle-${page}`);
          this.updateTab(index, (item: CYLTabBarItemAttributes) => {
            item.image = on ? $rawfile('Skins/1.0.0/space/rocket@3x.png') : CYL_TABS[index].image;
            item.selectedImage = on ? $rawfile('Skins/1.0.0/space/rocket@3x.png') : CYL_TABS[index].selectedImage;
            item.lottieFilePath = on ? undefined : CYL_TABS[index].lottieFilePath;
          });
        },
      },
      {
        id: 'helpers', title: CYLLocalizedString('CYLUtils 弱引用关联对象与查找按钮（issue #535）'),
        subtitle: 'cyl_tabBarItemIdentifiers, cyl_indexOfTabBarItemWithIdentifier, cyl_selectTabBarItemWithIdentifier, WeakRef',
        action: () => {
          const identifiers = cyl_tabBarItemIdentifiers(this.tabs);
          const lines = identifiers.map((identifier: string) =>
            `${identifier}: tab and page at index ${cyl_indexOfTabBarItemWithIdentifier(this.tabs, identifier)}`);
          const weak = new WeakRef<Object>(this.tabs);
          this.getUIContext().getPromptAction().showDialog({
            title: 'CYLUtils',
            message: `${lines.join('\n')}\n\nWeak reference: ${weak.deref() !== undefined}\nselected: ${identifiers[this.selectedIndex] ?? 'plus'}\n\nOK selects "message".`,
            buttons: [{ text: CYLLocalizedString('OK'), color: '#007AFF' }],
          }).then(() => cyl_selectTabBarItemWithIdentifier(DEMO_MESSAGE)).catch(() => {});
        },
      },
    ];
  }

  private sections(page: string): DemoSection[] {
    return [
      { title: CYLLocalizedString('通用'), rows: this.generalRows() },
      { title: CYLLocalizedString('TabBar 外观'), rows: this.appearanceRows() },
      { title: CYLLocalizedString('原地更新 Tab'), rows: this.tabItemUpdateRows(page) },
      { title: CYLLocalizedString('Tab 页面、选中与登录'), rows: this.pageRows(page) },
      { title: 'PlusButton', rows: this.plusButtonRows() },
      { title: CYLLocalizedString('换肤：节日与配色主题（%@ 种）', DEMO_THEMES.length), rows: DEMO_THEMES.map((theme: DemoTheme) => {
        const row: DemoRow = {
          id: `theme-${theme.name}`, title: (theme.name === this.theme.name ? '✓ ' : '') + CYLLocalizedString(theme.titleKey),
          action: () => CYLThemeManagerCenter.defaultThemeManager.currentThemeIdentifier = theme.name,
        };
        return row;
      }) },
      { title: CYLLocalizedString('Tab 交互'), rows: this.interactionRows() },
      { title: CYLLocalizedString('无需继承基类与工具方法'), rows: this.helperRows(page) },
      { title: CYLLocalizedString('配置文件'), rows: this.configurationRows() },
      { title: CYLLocalizedString('跳转与对比'), rows: this.jumpRows() },
      { title: CYLLocalizedString('角标'), rows: page === DEMO_MESSAGE ? this.messageRows().concat(this.badgeRows(page)) : this.badgeRows(page) },
    ];
  }

  // MARK: - Pages 页面

  @Builder
  cylRow(row: DemoRow, page: string) {
    Row() {
      if (row.badgeRow !== undefined) {
        Stack() {
          Image($r('app.media.app_icon'))
            .width(CYL_BADGE_ICON)
            .height(CYL_BADGE_ICON)
            .borderRadius(6)
          CYLBadgeView({ badge: (this.rowBadges.get(page) ?? [])[row.badgeRow], anchorWidth: CYL_BADGE_ICON })
        }
        // [EN] No fixed size: text badges are measured with the free width (issue list #1). [CN] 不固定尺寸（问题 #1）。
        .alignContent(Alignment.TopStart)
        .margin({ right: 16 })
      }
      Column() {
        Text(row.title)
          .fontSize(15)
          .fontColor($r('app.color.cyl_label'))
        if (row.subtitle !== undefined) {
          Text(row.subtitle)
            .fontSize(12)
            .fontColor('#8A8A8E')
            .margin({ top: 3 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .constraintSize({ minHeight: row.badgeRow !== undefined ? 60 : 48 })
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.cyl_row_background'))
    // [EN] A row is one accessibility element: title as the label, subtitle and badge as the description.
    // [CN] 每行一个无障碍元素：标题为标签，副标题与角标为描述。
    .accessibilityGroup(true)
    .accessibilityText(row.title)
    .accessibilityDescription([row.subtitle ?? '', row.badgeRow !== undefined
      ? cyl_badgeAccessibilityText((this.rowBadges.get(page) ?? [])[row.badgeRow]) : ''].filter((t: string) => t.length > 0).join(', '))
    .id(`cyl-row-${page}-${row.id}`)
    .onClick(() => row.action())
  }

  @Builder
  cylSectionHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#6D6D72')
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 6 })
      .backgroundColor($r('app.color.cyl_grouped_background'))
  }

  /**
   * [EN] A tab's page: a navigation bar with the tab's title (the view controllers of the Objective-C Example are in
   *      navigation controllers) and the demo list (item 51: the same on every tab, never empty). Item 10: the plus
   *      button's page (+plusChildViewController) is blank, titled "发布".
   * [CN] Tab 页面：带 Tab 标题的导航栏与演示列表（第 51 项：每个 Tab 相同，不留空）。第 10 项：加号按钮的页面为空白，标题为「发布」。
   */
  @Builder
  cylPage(index: number, identifier: string) {
    Column() {
      Row() {
        Text(index === CYLPlusButtonPageIndex ? $r('app.string.tab_post') : CYL_TABS[index].title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
        if (index === 0 && this.homeTitleRow >= 0) {
          Text(`(${this.homeTitleRow})`)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
        }
        if (index === 0) {
          // [EN] The left bar buttons, side by side (never over the centred title). [CN] 左侧导航按钮并排，不压住居中的标题。
          Row({ space: 8 }) {
            DemoFlatDesignButton({ onTap: () => this.showFlatDesignTabBar() })
            DemoLiquidGlassButton({ onTap: () => this.showLiquidGlassTabBar() })
          }
          // [EN] As tall as the bar, content centred: on the title's centre line (issue list #3). [CN] 与导航栏等高并垂直居中（问题 #3）。
          .height(44)
          .alignItems(VerticalAlign.Center)
          .position({ left: 12, top: 0 })
        }
        if (index !== CYLPlusButtonPageIndex) {
          Text(CYLLocalizedString('换肤'))
            .fontSize(15)
            .fontColor('#007AFF')
            .height(44)
            .textAlign(TextAlign.Center)
            .position({ right: 16, top: 0 })
            .id(`cyl-nav-skin-${identifier}`)
            .onClick(() => this.showSkinPicker())
        }
      }
      .height(44)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.cyl_bar_background'))
      .id(`cyl-nav-title-${identifier}`)

      if (this.replacedTabs.indexOf(index) >= 0) {
        Column() {
          Text(CYLLocalizedString('替换页 %@', index + 1))
            .fontSize(20)
            .id(`cyl-replacement-page-${index}`)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#E6E6FA')
      } else if (index !== CYLPlusButtonPageIndex) {
        List() {
          ForEach(this.sections(identifier), (section: DemoSection) => {
            ListItemGroup({ header: this.cylSectionHeader(section.title) }) {
              ForEach(section.rows, (row: DemoRow) => {
                ListItem() {
                  this.cylRow(row, identifier)
                }
              }, (row: DemoRow) => `${row.id}-${row.title}-${row.subtitle ?? ''}`)
            }
            .divider({ strokeWidth: 0.5, color: '#E5E5E5', startMargin: 16 })
          }, (section: DemoSection) => section.title)
        }
        .layoutWeight(1)
        .width('100%')
        // [EN] FIX (HarmonyOS screenshot issue 5): the last rows scroll above the tab bar, the raised plus button and the
        //      gesture bar instead of staying under them. [CN] 修复（鸿蒙截图问题 5）：最后几行可以滚动到 TabBar、凸起的 PlusButton
        //      与手势条之上，而不是被它们挡住。
        .contentEndOffset(CYL_LIST_END_INSET)
        .backgroundColor($r('app.color.cyl_grouped_background'))
        .onDidScroll((offset: number) => cyl_reportScroll(offset))
        .id(`cyl-page-${identifier}`)
      } else {
        Column()
          .layoutWeight(1)
          .width('100%')
          .id(`cyl-page-${identifier}`)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  /**
   * [EN] Item 7: replaces the tab bar with a new FlatDesign one (a new key), Home selected, the launch badges again.
   * [CN] 第 7 项：用新的扁平样式 TabBar（新 key）替换当前 TabBar，选中首页，再次显示启动角标。
   */
  showLiquidGlassTabBar(): void {
    // [EN] Item 8: a new Liquid Glass tab bar, built like the FlatDesign one (item 7). [CN] 第 8 项：重新创建液态玻璃 TabBar。
    this.showFlatDesignTabBar();
    this.styleType = CYLTabBarStyleType.LiquidGlass;
    this.applyItemBackgrounds();
  }

  showFlatDesignTabBar(): void {
    this.styleType = CYLTabBarStyleType.FlatDesign;
    this.selectedIndex = 0;
    this.covers = [];
    this.badges.forEach((badge: CYLBadge) => badge.cyl_clearBadge());
    this.tabBarKey += 1;
    this.showLaunchBadges();
  }

  build() {
    Column() {
      ForEach([this.tabBarKey], (key: number) => {
      CYLTabBarController({
        tabBarStyleType: this.styleType,
        // [EN] A skin's bar color tints the FlatDesign and Liquid Glass bars too. [CN] 皮肤的 TabBar 颜色也用于扁平样式与液态玻璃。
        barTintColor: this.theme.bar,
        tabBarItemsAttributes: this.tabs,
        plusButton: this.plus,
        selectedIndex: $selectedIndex,
        badges: this.badges,
        loggedIn: this.loggedIn,
        tapAnimationType: this.tapAnimation,
        hapticFeedbackEnabled: this.feedbackStep >= 3,
        hapticFeedbackStyle: (this.feedbackStep >= 3 && this.feedbackStep <= 5 ? this.feedbackStep - 3 : 1) as CYLImpactFeedbackStyle,
        tapSoundEnabled: this.feedbackStep === 1 || this.feedbackStep === 2 || this.feedbackStep === 6,
        tapSoundPath: this.feedbackStep === 2 ? 'cyl_tap_tock.wav' : 'cyl_tap_click.wav',
        tabBarMinimizeBehavior: this.minimizeBehavior,
        longPressDuration: [300, 500, 1000][this.longPressIndex],
        doubleTapInterval: [200, 300, 500][this.doubleTapIndex],
        swipeToSwitchTabEnabled: this.swipeEnabled,
        slideTransitionDuration: this.slideTransition ? 350 : 0,
        didSelectControl: (index: number, previous: number) => {
          // [EN] Item 55: a tap on a newly selected tab turns its badge into a dot of the same color; a re-tap of the
          //      selected tab changes nothing. [CN] 第 55 项：点击新选中的 Tab 时把角标变为同色红点；再次点击已选中的 Tab 不变。
          if (index >= 0 && index !== previous && this.badges[index].cyl_isShowBadge() && this.badges[index].value !== '') {
            this.badges[index].cyl_showBadgeValue('', CYLBadgeAnimationType.None);
          }
        },
        didLongPress: (index: number, identifier: string) => this.toast(CYLLocalizedString('长按了「%@」', identifier)),
        didDoubleTap: (index: number, identifier: string) => this.toast(`Double tap: ${identifier} (${index})`),
        loginRequiredTabBarItemIdentifiers: [DEMO_ME],
        presentLogin: (index: number, identifier: string, completion: (loggedIn: boolean) => void) => {
          this.getUIContext().getPromptAction().showDialog({
            title: CYLLocalizedString('登录'), message: `"${identifier}" needs a login (issue #19)`,
            buttons: [{ text: CYLLocalizedString('取消'), color: '#8A8A8E' }, { text: CYLLocalizedString('登录'), color: '#007AFF' }],
          }).then((result: promptAction.ShowDialogSuccessResponse) => {
            const ok = result.index === 1;
            if (ok) {
              this.loggedIn = true;
            }
            completion(ok);
          }).catch(() => completion(false));
        },
        tabCoverImages: this.covers,
        plusButtonBadge: this.plusButtonBadge,
        tabBarHidden: this.tabBarHidden,
        tabBarHeight: this.tabBarHeight,
        titlePositionAdjustment: this.titleOffset,
        itemEdgeInsets: this.itemEdgeInsets,
        tabBarBackgroundColor: this.theme.bar ?? (this.appearanceIndex === 0 ? $r('app.color.cyl_bar_background') : DEMO_APPEARANCES[this.appearanceIndex].background),
        tabBarShadowColor: DEMO_APPEARANCES[this.appearanceIndex].shadow,
        unselectedColor: this.theme.normal ?? (this.styleType === CYLTabBarStyleType.FlatDesign ? CYLFlatDesignUnselectedColor : DEMO_APPEARANCES[this.appearanceIndex].normal),
        tintColor: this.theme.tint ?? (this.styleType === CYLTabBarStyleType.FlatDesign ? CYLFlatDesignTintColor : this.styleType === CYLTabBarStyleType.LiquidGlass ? CYLLiquidGlassTintColor : (this.appearanceIndex === 0 ? '#FF8000' : DEMO_APPEARANCES[this.appearanceIndex].selected)),
        unloadsUnselectedViewsOnMemoryWarning: this.unloads,
        onMemoryWarning: (unloaded: number[], loaded: number[]) => this.memoryWarningReport(unloaded, loaded),
        didSelect: (index: number) => {
          // [EN] Tapping a tab with a badge clears it (MainTabBarController.m). [CN] 点击带角标的 Tab 清除角标。
          // [EN] Badges now change in didSelectControl (item 55). [CN] 角标改为在 didSelectControl 中更新（第 55 项）。
        },
        plusButtonTitleSelectedColor: '#32CD32',
        plusButtonAction: () => {
          // [EN] Item 5: the badge goes up by one per tap. [CN] 第 5 项：每次点击角标加 1。
          this.plusBadge += 1;
          this.plusButtonBadge.cyl_showBadgeValue(`${this.plusBadge}`);
          this.toast(`Post tapped (${this.plusBadge - 1})`);
        },
        pageBuilder: (index: number, identifier: string) => {
          this.cylPage(index, identifier)
        },
      })
      }, (key: number) => `cyl-tab-bar-${key}`)
    }
    .width('100%')
    .height('100%')
  }
}

/** [EN] The default display's width in px. [CN] 默认屏幕宽度（px）。 */
function display_width(): number {
  try {
    return display.getDefaultDisplaySync().width;
  } catch (e) {
    return 1080;
  }
}
