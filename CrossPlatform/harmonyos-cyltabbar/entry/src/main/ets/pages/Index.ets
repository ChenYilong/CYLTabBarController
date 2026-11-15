import { promptAction, display } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import {
  CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton, CYLPlusButtonPageIndex, CYLBadge, CYLBadgeView,
  CYLBadgeAppearance, CYLBadgeAnimationType, CYLOffset, CYLEdgeInsets, cyl_simulateMemoryWarning, cyl_badgeTitleForRow,
  cyl_badgeStyleCount, cyl_applyBadgeSample
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
  { title: $r('app.string.tab_home'), selectedTitle: $r('app.string.tab_refresh'), image: $r('app.media.home_normal'), selectedImage: $r('app.media.home_highlight'), identifier: DEMO_HOME, lottieFilePath: 'lottie/green_lottie_tab_home.json' },
  { title: $r('app.string.tab_nearby'), image: $r('app.media.fishpond_normal'), selectedImage: $r('app.media.fishpond_highlight'), identifier: DEMO_CITY, lottieFilePath: 'lottie/green_lottie_tab_discover.json' },
  { title: $r('app.string.tab_messages'), image: $r('app.media.message_normal'), darkImage: $r('app.media.message_normal_night'), selectedImage: $r('app.media.message_highlight'), identifier: DEMO_MESSAGE, lottieFilePath: 'lottie/green_lottie_tab_news.json' },
  { title: $r('app.string.tab_me'), image: $r('app.media.account_normal'), selectedImage: $r('app.media.account_highlight'), identifier: DEMO_ME, lottieFilePath: 'lottie/green_lottie_tab_mine.json' },
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
        identifier: item.identifier, darkImage: item.darkImage, lottieFilePath: item.lottieFilePath,
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

  private sections(page: string): DemoSection[] {
    return [
      { title: 'General', rows: this.generalRows() },
      { title: 'Tab bar appearance', rows: this.appearanceRows() },
      { title: 'Configuration file', rows: this.configurationRows() },
      { title: 'Jump and compare', rows: this.jumpRows() },
      { title: 'Badges', rows: this.badgeRows(page) },
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
          .fontColor('#000000')
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
    .backgroundColor(Color.White)
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
      .backgroundColor('#F2F2F7')
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
      .backgroundColor('#F8F8F8')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .id(`cyl-nav-title-${identifier}`)

      if (index !== CYLPlusButtonPageIndex) {
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
        .backgroundColor('#F2F2F7')
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
        plusButton: CYL_PLUS,
        selectedIndex: $selectedIndex,
        badges: this.badges,
        tabCoverImages: this.covers,
        plusButtonBadge: this.plusButtonBadge,
        tabBarHidden: this.tabBarHidden,
        tabBarHeight: this.tabBarHeight,
        titlePositionAdjustment: this.titleOffset,
        itemEdgeInsets: this.itemEdgeInsets,
        tabBarBackgroundColor: DEMO_APPEARANCES[this.appearanceIndex].background,
        tabBarShadowColor: DEMO_APPEARANCES[this.appearanceIndex].shadow,
        unselectedColor: DEMO_APPEARANCES[this.appearanceIndex].normal,
        tintColor: this.appearanceIndex === 0 ? '#FF8000' : DEMO_APPEARANCES[this.appearanceIndex].selected,
        unloadsUnselectedViewsOnMemoryWarning: this.unloads,
        onMemoryWarning: (unloaded: number[], loaded: number[]) => this.memoryWarningReport(unloaded, loaded),
        didSelect: (index: number) => {
          // [EN] Tapping a tab with a badge clears it (MainTabBarController.m). [CN] 点击带角标的 Tab 清除角标。
          if (index >= 0 && this.badges[index].cyl_isShowBadge()) {
            this.badges[index].cyl_clearBadge();
          }
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
