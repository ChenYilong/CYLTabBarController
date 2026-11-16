import { promptAction } from '@kit.ArkUI';
import {
  CYLLocalizedString, CYLTabBarController, CYLTabBarItemAttributes, CYLPlusButton, CYLBadge, CYLBadgeAnimationType,
  CYLTabBarStyleType, CYLTabButtonTapAnimationType, CYLEdgeInsets
} from 'cyltabbar';
import { DEMO_GALLERY, DemoGalleryScene } from '../demo/DemoGalleryScenes';

/**
 * [EN] Item 49: one gallery scene, built from its DemoGalleryScene data with the public CYLTabBarController API.
 * [CN] 第 49 项：一个场景，用公开的 CYLTabBarController API 按其数据构建。
 */
interface GalleryParams {
  id: string;
}

const TITLES: string[] = ['Home', 'Video', 'Photo', 'Message', 'Me', 'Favor', 'Shop', 'Read'];
const ICONS: Resource[] = [$r('app.media.home_normal'), $r('app.media.fishpond_normal'), $r('app.media.img_tab_home_0'),
  $r('app.media.message_normal'), $r('app.media.account_normal'), $r('app.media.img_tab_message_0'),
  $r('app.media.home_normal'), $r('app.media.message_normal')];
const SELECTED: Resource[] = [$r('app.media.home_highlight'), $r('app.media.fishpond_highlight'), $r('app.media.img_tab_home_1'),
  $r('app.media.message_highlight'), $r('app.media.account_highlight'), $r('app.media.img_tab_message_1'),
  $r('app.media.home_highlight'), $r('app.media.message_highlight')];
const LOTTIE: string[] = ['lottie/green_lottie_tab_home.json', 'lottie/green_lottie_tab_discover.json',
  'lottie/green_lottie_tab_news.json', 'lottie/green_lottie_tab_mine.json'];

function cylFindScene(id: string): DemoGalleryScene | undefined {
  for (const section of DEMO_GALLERY) {
    const found = section.scenes.find((scene: DemoGalleryScene) => scene.id === id);
    if (found !== undefined) {
      return found;
    }
  }
  return undefined;
}

@Entry
@Component
struct GalleryScene {
  @State scene: DemoGalleryScene = DEMO_GALLERY[0].scenes[1];
  @State selectedIndex: number = 0;
  @State tabs: CYLTabBarItemAttributes[] = [];
  @State tapAnimation: CYLTabButtonTapAnimationType = CYLTabButtonTapAnimationType.None;
  @State label: string = '';
  private badges: CYLBadge[] = [];
  private suggestTimer: number = -1;
  private plus?: CYLPlusButton;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as GalleryParams;
    this.scene = cylFindScene(params?.id ?? '') ?? this.scene;
    const scene = this.scene;
    const count = scene.tabs ?? 4;
    const indexes: number[] = [];
    for (let i = 0; i < count; i++) {
      indexes.push(i);
    }
    this.tabs = indexes.map((i: number) => {
      const item: CYLTabBarItemAttributes = {
        title: CYLLocalizedString(TITLES[i % TITLES.length]), image: ICONS[i % ICONS.length], selectedImage: SELECTED[i % SELECTED.length],
        identifier: TITLES[i % TITLES.length].toLowerCase(),
        selectedTitleColor: scene.colors !== undefined ? scene.colors[i % scene.colors.length] : undefined,
        backgroundColor: scene.backgrounds ? '#FFF6E0' : undefined,
        selectedBackgroundColor: scene.backgrounds ? '#FFD966' : undefined,
        lottieFilePath: scene.lottie ? LOTTIE[i % LOTTIE.length] : undefined,
      };
      return item;
    });
    this.badges = this.tabs.map(() => new CYLBadge());
    (scene.badges ?? []).forEach((value: string | undefined, i: number) => {
      if (value !== undefined && i < this.badges.length) {
        if (scene.badgeColor !== undefined) {
          this.badges[i].backgroundColor = scene.badgeColor;
        }
        this.badges[i].cyl_showBadgeValue(value, scene.tapAnimation === CYLTabButtonTapAnimationType.Bounce ? CYLBadgeAnimationType.Bounce : CYLBadgeAnimationType.None);
      }
    });
    if (scene.plus) {
      this.plus = { image: $r('app.media.post_normal'), selectedImage: $r('app.media.post_highlight'), title: CYLLocalizedString('发布'),
        centerYOffset: -14, imageSize: 52, alignsTitle: true, identifier: 'plus' };
    }
    this.selectedIndex = Math.min(scene.selected ?? 0, count - 1);
    this.tapAnimation = scene.tapAnimation ?? CYLTabButtonTapAnimationType.None;
    this.label = this.tabTitle(this.selectedIndex);
    if (scene.suggest) {
      // [EN] "Suggest a click": the middle tab bounces every 3 s until it is selected. [CN] 中间 Tab 每 3 秒跳动，直到被选中。
      const middle = Math.floor(count / 2);
      this.suggestTimer = setInterval(() => {
        if (this.selectedIndex === middle) {
          clearInterval(this.suggestTimer);
          return;
        }
        this.badges[middle].cyl_showBadgeValue('', CYLBadgeAnimationType.ScaleOnce);
      }, 3000);
    }
  }

  aboutToDisappear(): void {
    if (this.suggestTimer >= 0) {
      clearInterval(this.suggestTimer);
    }
  }

  private tabTitle(index: number): string {
    return index < 0 ? CYLLocalizedString('发布') : CYLLocalizedString(TITLES[index % TITLES.length]);
  }

  private dialog(message: string): void {
    this.getUIContext().getPromptAction().showDialog({ message: message, buttons: [{ text: CYLLocalizedString('OK'), color: '#007AFF' }] }).catch(() => {});
  }

  @Builder
  page(index: number, identifier: string) {
    Column() {
      Text(this.label)
        .fontSize(20)
        .id(`cyl-gallery-page-${identifier}`)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(this.scene.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .minFontSize(12)
          .maxFontSize(17)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('app.color.cyl_bar_background'))

      CYLTabBarController({
        tabBarItemsAttributes: this.tabs,
        plusButton: this.plus,
        selectedIndex: $selectedIndex,
        badges: this.badges,
        tabBarStyleType: this.scene.style ?? CYLTabBarStyleType.Default,
        tapAnimationType: this.tapAnimation,
        itemEdgeInsets: { top: 0, left: this.scene.insets ?? 0, bottom: 0, right: this.scene.insets ?? 0 } as CYLEdgeInsets,
        tintColor: this.scene.style === CYLTabBarStyleType.LiquidGlass || this.scene.style === CYLTabBarStyleType.FlatDesign ? '#007AFF' : '#FF8000',
        shouldSelect: (index: number, identifier: string): boolean => {
          // [EN] cyl_customActionTabBarItemIdentifiers: this tab opens a dialog, not its page. [CN] 此 Tab 打开弹窗而不是页面。
          if (this.scene.customAction === identifier) {
            this.dialog(this.tabTitle(index));
            return false;
          }
          // [EN] Issue #472: the fifth tab opens a menu of the other pages. [CN] 第五个 Tab 打开其余页面的菜单。
          if (this.scene.more === true && index === 4) {
            const rest = TITLES.slice(4).map((title: string) => {
              const button: promptAction.Button = { text: CYLLocalizedString(title), color: '#007AFF' };
              return button;
            });
            this.getUIContext().getPromptAction().showActionMenu({ title: 'More', buttons: rest as [promptAction.Button, promptAction.Button?, promptAction.Button?, promptAction.Button?, promptAction.Button?, promptAction.Button?] })
              .then((result: promptAction.ActionMenuSuccessResponse) => {
                this.label = CYLLocalizedString(TITLES[4 + result.index]);
                this.selectedIndex = 4;
              }).catch(() => {});
            return false;
          }
          return true;
        },
        didSelect: (index: number) => {
          this.label = this.tabTitle(index);
          if (index >= 0 && this.badges[index] !== undefined && this.badges[index].cyl_isShowBadge() && this.scene.style === CYLTabBarStyleType.LiquidGlass) {
            this.badges[index].cyl_clearBadge();
          }
        },
        plusButtonAction: () => {
          if (this.scene.plusMenu) {
            this.getUIContext().getPromptAction().showActionMenu({ title: CYLLocalizedString('发布'),
              buttons: [{ text: CYLLocalizedString('拍照'), color: '#007AFF' }, { text: CYLLocalizedString('从相册选择'), color: '#007AFF' }] }).catch(() => {});
          } else {
            this.label = CYLLocalizedString('发布');
          }
        },
        pageBuilder: (index: number, identifier: string) => {
          this.page(index, identifier)
        },
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
