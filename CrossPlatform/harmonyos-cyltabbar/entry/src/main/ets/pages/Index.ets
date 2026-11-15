import { promptAction, router } from '@kit.ArkUI';
import {
  CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton, CYLPlusButtonPageIndex, CYLBadge, CYLBadgeAppearance,
  CYLBadgeAnimationType
} from 'cyltabbar';

/**
 * [EN] The tabs of the Objective-C Example (MainTabBarController): Home, Nearby, Messages, Me, with identifiers.
 * [CN] Objective-C Example（MainTabBarController）的 Tab：首页、同城、消息、我的，带 identifier。
 */
const CYL_TABS: CYLTabBarItemAttributes[] = [
  { title: $r('app.string.tab_home'), selectedTitle: $r('app.string.tab_refresh'), image: $r('app.media.home_normal'), selectedImage: $r('app.media.home_highlight'), identifier: 'home', lottieFilePath: 'lottie/green_lottie_tab_home.json' },
  { title: $r('app.string.tab_nearby'), image: $r('app.media.fishpond_normal'), selectedImage: $r('app.media.fishpond_highlight'), identifier: 'city', lottieFilePath: 'lottie/green_lottie_tab_discover.json' },
  { title: $r('app.string.tab_messages'), image: $r('app.media.message_normal'), darkImage: $r('app.media.message_normal_night'), selectedImage: $r('app.media.message_highlight'), identifier: 'message', lottieFilePath: 'lottie/green_lottie_tab_news.json' },
  { title: $r('app.string.tab_me'), image: $r('app.media.account_normal'), selectedImage: $r('app.media.account_highlight'), identifier: 'CYLMineViewController', lottieFilePath: 'lottie/green_lottie_tab_mine.json' },
];

/**
 * [EN] CYLPlusButtonSubclass of the Objective-C Example: "Post" at index 2, raised by 14 vp
 *      (+constantOfPlusButtonCenterYOffsetForTabBarHeight: -14), title aligned with the tab titles, green when selected,
 *      and a page of its own (+plusChildViewController).
 * [CN] Objective-C Example 的 CYLPlusButtonSubclass：位于第 2 位的「发布」，上移 14 vp，标题与 Tab 标题对齐，选中时为绿色，带自己的页面。
 */
const CYL_RANDOM_COLORS: string[] = ['#FF3B30', '#FF9500', '#34C759', '#007AFF', '#AF52DE', '#FF2D55'];

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

@Entry
@Component
struct Index {
  @State selectedIndex: number = 0;
  @State plusBadge: number = 1;
  // [EN] Item 2: the Taobao-style cover on Home after 1.5 s (setSelectedCoverShow:). [CN] 第 2 项：1.5 秒后首页的仿淘宝封面。
  @State covers: (ResourceStr | undefined)[] = [];
  private badges: CYLBadge[] = CYL_TABS.map(() => new CYLBadge());
  private plusButtonBadge: CYLBadge = new CYLBadge();

  aboutToAppear(): void {
    // [EN] SceneDelegate.m -setUpBadgeAppearance (#425). [CN] 全局角标偏移。
    CYLBadgeAppearance.globalAppearance.centerOffset = { horizontal: -5, vertical: 3 };
    // [EN] cyl_demo_showPlusButtonBadge: 1 at launch. [CN] 启动时加号角标为 1。
    this.plusButtonBadge.cyl_showBadgeValue('1');
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

  /**
   * [EN] A tab's page: a navigation bar with the tab's title (the view controllers of the Objective-C Example are in
   *      navigation controllers). Item 10: the plus button's page (+plusChildViewController) is blank, titled "发布".
   * [CN] Tab 页面：带 Tab 标题的导航栏（Objective-C Example 的视图控制器都在导航控制器中）。第 10 项：加号按钮的页面为空白，标题为「发布」。
   */
  /**
   * [EN] A tab's page: a navigation bar with the tab's title (the view controllers of the Objective-C Example are in
   *      navigation controllers). Item 10: the plus button's page (+plusChildViewController) is blank, titled "发布".
   * [CN] Tab 页面：带 Tab 标题的导航栏（Objective-C Example 的视图控制器都在导航控制器中）。第 10 项：加号按钮的页面为空白，标题为「发布」。
   */
  @Builder
  cylPage(index: number, identifier: string) {
    Column() {
      Text(index === CYLPlusButtonPageIndex ? $r('app.string.tab_post') : CYL_TABS[index].title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .height(44)
        .width('100%')
        .textAlign(TextAlign.Center)
        .backgroundColor('#F8F8F8')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        .id(`cyl-nav-title-${identifier}`)
      Column() {
        if (identifier === 'home') {
          // [EN] Home rows (more follow, docs/HarmonyOS-Parity.md). Item 43: create from a configuration file.
          // [CN] 首页行（后续补齐）。第 43 项：由配置文件创建。
          ForEach(['json', 'json5', 'jsonc'], (format: string) => {
            Text(`由配置文件创建 TabBarController (.${format}) / Create from a configuration file`)
              .fontSize(15)
              .width('100%')
              .padding(14)
              .border({ width: { bottom: 0.5 }, color: { bottom: '#E5E5E5' } })
              .id(`cyl-row-configuration-${format}`)
              .onClick(() => {
                router.pushUrl({ url: 'pages/ConfigurationDemo', params: { file: `configurations/cyl_tabbar_configuration.${format}` } });
              })
          }, (format: string) => format)
        }
      }
        .layoutWeight(1)
        .width('100%')
        .id(`cyl-page-${identifier}`)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  build() {
    Column() {
      CYLTabBarController({
        tabBarItemsAttributes: CYL_TABS,
        plusButton: CYL_PLUS,
        selectedIndex: $selectedIndex,
        badges: this.badges,
        tabCoverImages: this.covers,
        plusButtonBadge: this.plusButtonBadge,
        didSelect: (index: number) => {
          // [EN] Tapping a tab with a badge clears it (MainTabBarController.m). [CN] 点击带角标的 Tab 清除角标。
          if (index >= 0 && this.badges[index].cyl_isShowBadge()) {
            this.badges[index].cyl_clearBadge();
          }
        },
        tintColor: '#FF8000',
        plusButtonTitleSelectedColor: '#32CD32',
        plusButtonAction: () => {
          // [EN] Item 5: the badge goes up by one per tap. [CN] 第 5 项：每次点击角标加 1。
          this.plusBadge += 1;
          this.plusButtonBadge.cyl_showBadgeValue(`${this.plusBadge}`);
          promptAction.showToast({ message: `Post tapped (${this.plusBadge - 1})` });
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
