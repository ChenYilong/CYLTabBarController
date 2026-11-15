import { promptAction, display } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import {
  CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton, CYLPlusButtonPageIndex, CYLBadge, CYLBadgeView,
  CYLBadgeAppearance, CYLBadgeAnimationType, CYLOffset, CYLEdgeInsets, cyl_simulateMemoryWarning, cyl_badgeTitleForRow,
  cyl_badgeStyleCount, cyl_applyBadgeSample, CYLTabButtonTapAnimationType, CYLImpactFeedbackStyle,
  CYLTabBarMinimizeBehavior, cyl_reportScroll, cyl_pushViewController
} from 'cyltabbar';
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
  private badges: CYLBadge[] = CYL_TABS.map(() => new CYLBadge());
  private plusButtonBadge: CYLBadge = new CYLBadge();
  /** [EN] The badge of each badge row, per page. [CN] 每个页面每个角标行的角标。 */
  private rowBadges: Map<string, CYLBadge[]> = new Map();

  aboutToAppear(): void {
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
        id: 'language', title: 'Language', subtitle: `Current: ${DEMO_LANGUAGE_NAMES[this.languageIndex]}`,
        action: () => this.choose('Language', DEMO_LANGUAGE_NAMES, this.languageIndex, (index: number) => {
          // [EN] setAppPreferredLanguage reloads the app's resources ($r) in the chosen language. [CN] 以所选语言重新加载应用资源。
          i18n.System.setAppPreferredLanguage(DEMO_LANGUAGES[index] === '' ? 'default' : DEMO_LANGUAGES[index]);
          this.languageIndex = index;
        }),
      },
      {
        id: 'memory-warning', title: 'Simulate a memory warning',
        subtitle: 'Unloads the pages of unselected tabs when unloadsUnselectedViewsOnMemoryWarning is on (#426), then lists each tab',
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
    const names = ['Home', 'Nearby', 'Messages', 'Me'];
    const lines = names.map((name: string, index: number) => {
      const state = loaded.indexOf(index) >= 0 ? 'loaded' : (unloaded.indexOf(index) >= 0 ? 'unloaded now' : 'not loaded');
      return `${index}. ${name}: ${state}${index === this.selectedIndex ? ' (selected)' : ''}`;
    });
    this.getUIContext().getPromptAction().showDialog({ title: 'Memory warning', message: lines.join('\n'), buttons: [{ text: 'OK', color: '#007AFF' }] });
  }

  /** [EN] Tab bar appearance and the FlatDesign rows (items 13, 14, 56, 17, 18, 19). [CN] TabBar 外观与扁平样式行。 */
  private appearanceRows(): DemoRow[] {
    return [
      {
        id: 'title-offset', title: 'Title offset (titlePositionAdjustment)',
        subtitle: `Tap to cycle the vertical offset of every tab title, current: (${this.titleOffset.horizontal}, ${this.titleOffset.vertical})`,
        action: () => {
          const next = DEMO_TITLE_OFFSETS[(DEMO_TITLE_OFFSETS.indexOf(this.titleOffset.vertical) + 1) % DEMO_TITLE_OFFSETS.length];
          this.titleOffset = { horizontal: 0, vertical: next };
        },
      },
      {
        id: 'appearance', title: 'standardAppearance theme (shared by Liquid Glass and FlatDesign)',
        subtitle: `Current: ${DEMO_APPEARANCES[this.appearanceIndex].name}; tap for the next one`,
        action: () => {
          this.appearanceIndex = (this.appearanceIndex + 1) % DEMO_APPEARANCES.length;
          this.applyItemBackgrounds();
        },
      },
      {
        id: 'tab-bar-hidden', title: 'Show / hide the tab bar (setTabBarHidden:animated:)',
        subtitle: `tabBarHidden = ${this.tabBarHidden}; hidden, it comes back after 2 s`,
        action: () => {
          this.tabBarHidden = !this.tabBarHidden;
          if (this.tabBarHidden) {
            setTimeout(() => this.tabBarHidden = false, 2000);
          }
        },
      },
      {
        id: 'minimize', title: 'Shrink / hide the tab bar on scroll (issue #13)',
        subtitle: `cyl_tabBarMinimizeBehavior = ${['Automatic', 'Never', 'OnScrollDown', 'OnScrollUp'][this.minimizeBehavior]}; tap to choose, then scroll this list`,
        action: () => this.choose('cyl_tabBarMinimizeBehavior', ['Automatic', 'Never', 'OnScrollDown', 'OnScrollUp'],
          this.minimizeBehavior, (index: number) => this.minimizeBehavior = index as CYLTabBarMinimizeBehavior),
      },
      {
        id: 'tab-bar-height', title: 'Change the tab bar height', subtitle: `tabBarHeight = ${this.tabBarHeight}`,
        action: () => this.tabBarHeight = this.tabBarHeight === 49 ? 69 : 49,
      },
      {
        id: 'items-not-centered', title: 'Tab items not centered (system layout)',
        action: () => this.itemEdgeInsets = { top: 0, left: 0, bottom: 0, right: 0 },
      },
      {
        id: 'items-centered', title: 'Tab items centered', subtitle: 'cyl_itemEdgeInsets: 15% of a tab width free at each end',
        action: () => {
          const inset = this.getUIContext().px2vp(display_width()) / 5 * 0.15;
          this.itemEdgeInsets = { top: 0, left: inset, bottom: 0, right: inset };
        },
      },
      {
        id: 'item-background', title: 'Set the tab item background color',
        subtitle: 'CYLTabBarItemBackgroundColor / CYLTabBarItemSelectedBackgroundColor',
        action: () => {
          this.itemBackgrounds = !this.itemBackgrounds;
          this.applyItemBackgrounds();
        },
      },
    ];
  }

  /** [EN] -updateTabBarItemAtIndex:attributes: for the background rows and the capsule theme. [CN] 更新各 Tab 的背景属性。 */
  private applyItemBackgrounds(): void {
    const capsule = DEMO_APPEARANCES[this.appearanceIndex].capsule;
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
        id: 'system-tab-bar', title: 'Compare with the system tab bar',
        subtitle: 'ArkUI Tabs, the HarmonyOS system tab bar, with the same tabs',
        action: () => this.push('pages/SystemTabs', {} as DemoPushParams),
      },
      {
        id: 'system-tab-bar-plus', title: 'Push to the system tab bar (another PlusButton)',
        subtitle: 'The system bar has no plus button: a floating button stands in',
        action: () => this.push('pages/SystemTabs', { withPlus: true } as DemoPushParams),
      },
      {
        id: 'another-tab-bar', title: 'Push to another CYLTabBarController (another PlusButton)',
        subtitle: 'A tab bar controller of another context, with a square plus button',
        action: () => this.push('pages/AnotherTabBar', {} as DemoPushParams),
      },
      {
        id: 'pop-push', title: 'cyl_pop / cyl_push methods',
        subtitle: 'cyl_pushViewController, cyl_popSelectTabBarChildViewControllerAtIndex, cyl_pushOrPopToViewController',
        action: () => cyl_pushViewController('pages/PopPushDemo'),
      },
    ];
  }

  /** [EN] Configuration file (item 43). [CN] 配置文件（第 43 项）。 */
  private configurationRows(): DemoRow[] {
    return ['json', 'json5', 'jsonc'].map((format: string) => {
      const row: DemoRow = {
        id: `configuration-${format}`, title: `由配置文件创建 TabBarController (.${format}) / Create from a configuration file`,
        action: () => this.push('pages/ConfigurationDemo', { file: `configurations/cyl_tabbar_configuration.${format}` } as DemoPushParams),
      };
      return row;
    });
  }

  /** [EN] The badge rows of a page (items 50, 53), each with its action as BadgeRows of the Android port. [CN] 页面的角标行。 */
  private badgeRows(page: string): DemoRow[] {
    const badges = this.rowBadges.get(page) ?? [];
    return badges.map((badge: CYLBadge, row: number) => {
      const item: DemoRow = {
        id: `badge-${row}`, title: cyl_badgeTitleForRow(row), badgeRow: row,
        subtitle: `${page} CYLTabBarController on HarmonyOS`,
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
        id: 'title', title: 'Change the tab title', subtitle: 'Changes the title of this page\'s tab in place; tap again to restore',
        action: () => {
          const on = this.flip(`title-${page}`);
          this.updateTab(index, (item: CYLTabBarItemAttributes) => item.title = on ? 'Courses' : CYL_TABS[index].title);
        },
      },
      {
        id: 'network-icon', title: 'Download a network icon', subtitle: 'Loads the icon of this page\'s tab from a URL (CYLTabBarItemImageURL); tap again to restore',
        action: () => {
          const on = this.flip(`network-${page}`);
          this.updateTab(index, (item: CYLTabBarItemAttributes) => {
            item.imageURL = on ? icons[0][0] : undefined;
            item.selectedImageURL = on ? icons[0][1] : undefined;
          });
        },
      },
      {
        id: 'all-network-icons', title: 'Download every network icon', subtitle: 'Updates the icons of every tab from URLs; tap again to restore',
        action: () => {
          const on = this.flip('all-network');
          this.tabs.forEach((tab: CYLTabBarItemAttributes, i: number) => this.updateTab(i, (item: CYLTabBarItemAttributes) => {
            item.imageURL = on ? icons[i % 2][0] : undefined;
            item.selectedImageURL = on ? icons[i % 2][1] : undefined;
          }));
        },
      },
      {
        id: 'all-local-icons', title: 'Use local icons for every tab', subtitle: 'Updates every tab icon from local images; tap again to restore',
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
        id: 'gif', title: 'GIF icon', subtitle: 'This page\'s tab shows a GIF (CYLTabBarGIFFilePath); tap again to restore',
        action: () => {
          const on = this.flip(`gif-${page}`);
          this.updateTab(index, (item: CYLTabBarItemAttributes) => item.gifFilePath = on ? 'gif/cyl_tab_sample_animated.gif' : undefined);
        },
      },
      {
        id: 'all-titles', title: 'Change every title', subtitle: 'Updates the titles of every tab at once (-updateTabBarItemsWithAttributes:); tap again to restore',
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
        id: 'replace', title: 'Replace the pages of the neighboring tabs',
        subtitle: 'Replaces the tabs on both sides of this tab with other pages (issue #481); tap again to restore',
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
        id: 'selected-index', title: 'selectedIndex and PlusButton (issue #515)',
        subtitle: `selectedIndex = ${this.selectedIndex} (the plus button's page is ${CYLPlusButtonPageIndex}, never a tab index); tap for the next tab`,
        action: () => this.selectedIndex = this.selectedIndex < 0 ? 0 : (this.selectedIndex + 1) % CYL_TABS.length,
      },
      {
        id: 'login', title: 'Login state', subtitle: `Logged in: ${this.loggedIn}. The "Me" tab needs a login (issue #19); tap to toggle`,
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
    const cases = ['Image loads after 2 s', 'Image replaced after 2 s', 'Image removed after 2 s', 'Background image loads after 2 s'];
    const modes = ['late-load', 'late-replace', 'late-remove', 'late-background'];
    return [
      {
        id: 'late-image', title: 'PlusButton image set later',
        subtitle: 'Pushes a tab bar controller whose plus button image changes 2 s later; the layout must not move',
        action: () => this.choose('PlusButton image set later', cases, -1,
          (index: number) => this.push('pages/AnotherTabBar', { mode: modes[index] } as DemoPushParams)),
      },
      {
        id: 'touchable-area', title: 'PlusButton touchable area (issue #91)',
        subtitle: `Shows the touchable area in translucent red: ${this.plus.showsTouchableArea === true}; scale ${scale}x; tap to cycle 1x, 1.5x, 2x, off`,
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
    const tapNames = ['None', 'Scale', 'Zoom in', 'Bounce', 'Rotation', 'Flip'];
    const feedbackNames = ['Off', 'Default tap sound', 'Custom sound file (cyl_tabButtonTapSoundURL)', 'Light haptic',
      'Medium haptic', 'Heavy haptic', 'Tap sound + haptic'];
    const longPress = [300, 500, 1000];
    const doubleTap = [200, 300, 500];
    return [
      {
        id: 'tap-animation', title: 'Tap animation (cyl_tabButtonTapAnimationType)',
        subtitle: `Current: ${tapNames[this.tapAnimation]}; tap for the next one, then tap a tab`,
        action: () => this.tapAnimation = (this.tapAnimation + 1) % tapNames.length,
      },
      {
        id: 'feedback', title: 'Tap sound and haptics (cyl_tabButtonHapticFeedbackEnabled / Style)',
        subtitle: `Current: ${feedbackNames[this.feedbackStep]}; tap for the next one`,
        action: () => this.feedbackStep = (this.feedbackStep + 1) % feedbackNames.length,
      },
      {
        id: 'long-press', title: 'Long press on tabs (issue #535)',
        subtitle: 'Long press any tab or the plus button: a toast names it (cyl_didLongPressControlBlock)',
        action: () => this.toast('Long press a tab or the plus button'),
      },
      {
        id: 'gesture-timings', title: 'Long press duration and double tap interval (issue #535 / #152)',
        subtitle: `cyl_tabBarItemLongPressDuration = ${longPress[this.longPressIndex]} ms, cyl_tabBarItemDoubleTapInterval = ${doubleTap[this.doubleTapIndex]} ms; tap to cycle; double tap a tab to see it`,
        action: () => {
          this.longPressIndex = (this.longPressIndex + 1) % longPress.length;
          this.doubleTapIndex = (this.doubleTapIndex + 1) % doubleTap.length;
        },
      },
      {
        id: 'swipe', title: 'Swipe to switch tabs (cyl_swipeToSwitchTabEnabled, issue #535)',
        subtitle: `On: ${this.swipeEnabled}; swipe the page left / right`,
        action: () => this.swipeEnabled = !this.swipeEnabled,
      },
      {
        id: 'slide-transition', title: 'Slide transition (CYLTabBarSlideTransitionAnimator)',
        subtitle: `On: ${this.slideTransition}; the new page slides in from the side of its tab`,
        action: () => this.slideTransition = !this.slideTransition,
      },
      {
        id: 'previous-tab', title: 'Previous tab (cyl_selectPreviousTab, issue #535)',
        action: () => this.selectedIndex = ((this.selectedIndex < 0 ? 0 : this.selectedIndex) + CYL_TABS.length - 1) % CYL_TABS.length,
      },
      {
        id: 'next-tab', title: 'Next tab (cyl_selectNextTab, issue #535)',
        action: () => this.selectedIndex = ((this.selectedIndex < 0 ? 0 : this.selectedIndex) + 1) % CYL_TABS.length,
      },
    ];
  }

  /** [EN] Messages: push tab bar controllers (item 52, issue #202). [CN] 消息页：push TabBarController（第 52 项，issue #202）。 */
  private messageRows(): DemoRow[] {
    return [
      {
        id: 'same-context', title: 'Push a TabBarController of the same context (the same PlusButton class)',
        action: () => this.push('pages/AnotherTabBar', { mode: 'same' } as DemoPushParams),
      },
      {
        id: 'new-context', title: 'Push a TabBarController of a new context (PlusButton with a tappable X, issue #202)',
        subtitle: 'Tap the X at the top right of the PlusButton: the X changes color at random and the PlusButton does not respond',
        action: () => this.push('pages/AnotherTabBar', { mode: 'close' } as DemoPushParams),
      },
    ];
  }

  private sections(page: string): DemoSection[] {
    return [
      { title: 'General', rows: this.generalRows() },
      { title: 'Tab bar appearance', rows: this.appearanceRows() },
      { title: 'Update tabs in place', rows: this.tabItemUpdateRows(page) },
      { title: 'Tab pages, selection and login', rows: this.pageRows(page) },
      { title: 'PlusButton', rows: this.plusButtonRows() },
      { title: 'Tab interactions', rows: this.interactionRows() },
      { title: 'Configuration file', rows: this.configurationRows() },
      { title: 'Jump and compare', rows: this.jumpRows() },
      { title: 'Badges', rows: page === DEMO_MESSAGE ? this.messageRows().concat(this.badgeRows(page)) : this.badgeRows(page) },
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
        .width(CYL_BADGE_ICON)
        .height(CYL_BADGE_ICON)
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
      }
      .height(44)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.cyl_bar_background'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .id(`cyl-nav-title-${identifier}`)

      if (this.replacedTabs.indexOf(index) >= 0) {
        Column() {
          Text(`Replacement page ${index + 1}`)
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

  build() {
    Column() {
      CYLTabBarController({
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
        didLongPress: (index: number, identifier: string) => this.toast(`Long press: ${identifier} (${index})`),
        didDoubleTap: (index: number, identifier: string) => this.toast(`Double tap: ${identifier} (${index})`),
        loginRequiredTabBarItemIdentifiers: [DEMO_ME],
        presentLogin: (index: number, identifier: string, completion: (loggedIn: boolean) => void) => {
          this.getUIContext().getPromptAction().showDialog({
            title: 'Log in', message: `"${identifier}" needs a login (issue #19)`,
            buttons: [{ text: 'Cancel', color: '#8A8A8E' }, { text: 'Log in', color: '#007AFF' }],
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
        tabBarBackgroundColor: this.appearanceIndex === 0 ? $r('app.color.cyl_bar_background') : DEMO_APPEARANCES[this.appearanceIndex].background,
        tabBarShadowColor: DEMO_APPEARANCES[this.appearanceIndex].shadow,
        unselectedColor: DEMO_APPEARANCES[this.appearanceIndex].normal,
        tintColor: this.appearanceIndex === 0 ? '#FF8000' : DEMO_APPEARANCES[this.appearanceIndex].selected,
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
