import { CYLLocalizedString } from 'cyltabbar';
import { DEMO_GALLERY, DemoGalleryScene, DemoGallerySection } from '../demo/DemoGalleryScenes';

/**
 * [EN] Item 49: the tab bar gallery list; a tap opens the scene (pages/GalleryScene) or the ArkUI system tab bar, or shows
 *      why a scene is not available on HarmonyOS.
 * [CN] 第 49 项：场景列表；点击打开场景、ArkUI 系统 TabBar，或说明鸿蒙上无法展示的原因。
 */
interface GalleryRoute {
  id?: string;
  withPlus?: boolean;
}

@Entry
@Component
struct Gallery {
  private open(scene: DemoGalleryScene): void {
    const router = this.getUIContext().getRouter();
    if (scene.unavailable !== undefined) {
      this.getUIContext().getPromptAction().showToast({ message: scene.unavailable });
    } else if (scene.system === true) {
      router.pushUrl({ url: 'pages/SystemTabs', params: {} as GalleryRoute });
    } else {
      router.pushUrl({ url: 'pages/GalleryScene', params: { id: scene.id } as GalleryRoute });
    }
  }

  @Builder
  header(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#6D6D72')
      .width('100%')
      .padding({ left: 16, top: 16, bottom: 6 })
      .backgroundColor($r('app.color.cyl_grouped_background'))
  }

  build() {
    Column() {
      Row() {
        Text('‹ ' + CYLLocalizedString('Back'))
          .fontSize(16)
          .fontColor('#007AFF')
          .id('cyl-back')
          .onClick(() => this.getUIContext().getRouter().back())
        Text(CYLLocalizedString('TabBar 场景展示'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 52 })
      }
      .height(44)
      .width('100%')
      .padding({ left: 12 })
      .backgroundColor($r('app.color.cyl_bar_background'))

      List() {
        ForEach(DEMO_GALLERY, (section: DemoGallerySection) => {
          ListItemGroup({ header: this.header(section.title) }) {
            ForEach(section.scenes, (scene: DemoGalleryScene) => {
              ListItem() {
                Column() {
                  Text(scene.title)
                    .fontSize(15)
                    .fontColor(scene.unavailable !== undefined ? '#8A8A8E' : $r('app.color.cyl_label'))
                  Text(scene.unavailable ?? scene.subtitle)
                    .fontSize(12)
                    .fontColor('#8A8A8E')
                    .margin({ top: 3 })
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor($r('app.color.cyl_row_background'))
                .accessibilityGroup(true)
                .accessibilityText(scene.title)
                .accessibilityDescription(scene.unavailable ?? scene.subtitle)
                .id(`cyl-row-gallery-${scene.id}`)
                .onClick(() => this.open(scene))
              }
            }, (scene: DemoGalleryScene) => scene.id)
          }
          .divider({ strokeWidth: 0.5, color: '#E5E5E5', startMargin: 16 })
        }, (section: DemoGallerySection) => section.title)
      }
      .layoutWeight(1)
      .contentEndOffset(40)
      .backgroundColor($r('app.color.cyl_grouped_background'))
    }
    .width('100%')
    .height('100%')
  }
}
