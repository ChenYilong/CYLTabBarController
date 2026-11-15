import { promptAction } from '@kit.ArkUI';
import {
  CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton, CYLPlusButtonPageIndex, CYLBadge, CYLBadgeAppearance,
  CYLBadgeAnimationType
} from 'cyltabbar';

/**
 * [EN] The tabs of the Objective-C Example (MainTabBarController): Home, Nearby, Messages, Me, with identifiers.
 * [CN] Objective-C Example（MainTabBarController）的 Tab：首页、同城、消息、我的，带 identifier。
 */
const CYL_TABS: CYLTabBarItemAttributes[] = [
  { title: $r('app.string.tab_home'), image: $r('app.media.home_normal'), selectedImage: $r('app.media.home_highlight'), identifier: 'home' },
  { title: $r('app.string.tab_nearby'), image: $r('app.media.fishpond_normal'), selectedImage: $r('app.media.fishpond_highlight'), identifier: 'nearby' },
  { title: $r('app.string.tab_messages'), image: $r('app.media.message_normal'), selectedImage: $r('app.media.message_highlight'), identifier: 'message' },
  { title: $r('app.string.tab_me'), image: $r('app.media.account_normal'), selectedImage: $r('app.media.account_highlight'), identifier: 'me' },
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
    }, 1500);
  }

  @Builder
  cylPage(index: number, identifier: string) {
    Column() {
      Text(index === CYLPlusButtonPageIndex ? $r('app.string.tab_post') : CYL_TABS[index].title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 12 })
      Text(identifier)
        .fontSize(13)
        .fontColor('#888888')
        .margin({ top: 8 })
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
