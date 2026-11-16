import { CYLLocalizedString } from 'cyltabbar';
import { router } from '@kit.ArkUI';
import {
  CYLTabBarController, CYLTabBarConfiguration, CYLTabBarConfigurationResult, CYLTabBarConfigurationError
} from 'cyltabbar';

/**
 * [EN] The example's images for the configuration's SF Symbol names ("system:house"): HarmonyOS has no SF Symbols.
 * [CN] 配置中 SF Symbol 名（"system:house"）对应的示例图片：鸿蒙没有 SF Symbols。
 */
const CYL_SYSTEM_IMAGES: Record<string, Resource> = {
  'system:house': $r('app.media.home_normal'),
  'system:house.fill': $r('app.media.home_highlight'),
  'system:message': $r('app.media.message_normal'),
  'system:message.fill': $r('app.media.message_highlight'),
  'system:safari': $r('app.media.fishpond_normal'),
  'system:safari.fill': $r('app.media.fishpond_highlight'),
  'system:person': $r('app.media.account_normal'),
  'system:person.fill': $r('app.media.account_highlight'),
};

interface CYLConfigurationRoute {
  file: string;
}

/**
 * [EN] Item 43 (CYLConfigurationDemoViewController): a tab bar controller made from a configuration file of
 *      Example-Shared/Configurations (cyl_tabbar_configuration.json, .json5 or .jsonc, rawfile/configurations). The
 *      "Message" tab is for "ios,android" only, so it is left out on HarmonyOS. A failure shows the error.
 * [CN] 第 43 项：由 Example-Shared/Configurations 中的配置文件创建 TabBarController。「Message」Tab 只用于 "ios,android"，
 *      因此在鸿蒙上不显示。失败时显示错误。
 */
@Entry
@Component
struct ConfigurationDemo {
  @State selectedIndex: number = 0;
  @State result?: CYLTabBarConfigurationResult = undefined;
  @State errorText: string = '';
  private file: string = 'configurations/cyl_tabbar_configuration.json';

  aboutToAppear(): void {
    const params = router.getParams() as CYLConfigurationRoute | undefined;
    if (params?.file) {
      this.file = params.file;
    }
    CYLTabBarConfiguration.imageResolver = (name: string) => CYL_SYSTEM_IMAGES[name] ?? $r('app.media.home_normal');
    try {
      const configuration = CYLTabBarConfiguration.configurationWithRawFile(getContext(this), this.file);
      this.result = CYLTabBarConfiguration.resultWithConfiguration(configuration, '1.0.0', false);
    } catch (error) {
      const failure = error as CYLTabBarConfigurationError;
      this.errorText = `${failure.domain ?? ''} ${failure.code ?? ''}: ${failure.message}`;
    }
  }

  @Builder
  cylPage(index: number, identifier: string) {
    Column() {
      Text(this.result?.items[index]?.title ?? identifier)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .height(44)
        .width('100%')
        .textAlign(TextAlign.Center)
        .backgroundColor('#F8F8F8')
      // [EN] Issue list #22: the labels are localized (iOS-style keys); the file path and the identifiers stay as written.
      // [CN] 问题清单 #22：标签已本地化；文件路径与标识保持原样。
      Text(`${this.file}\n${CYLLocalizedString('Identifier: %@', identifier)}\n${CYLLocalizedString('Page identifier: %@', this.result?.items[index]?.pageIdentifier ?? '-')}`)
        .fontSize(13)
        .fontColor('#666666')
        .margin(16)
        .id(`cyl-config-page-${identifier}`)
      Button(CYLLocalizedString('Back')).onClick(() => router.back())
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      if (this.result !== undefined) {
        CYLTabBarController({
          tabBarItemsAttributes: this.result.items,
          selectedIndex: $selectedIndex,
          tintColor: this.result.tintColor ?? '#007AFF',
          tabBarBackgroundColor: this.result.backgroundColor ?? '#F8F8F8',
          titlePositionAdjustment: this.result.titlePositionAdjustment,
          pageBuilder: (index: number, identifier: string) => {
            this.cylPage(index, identifier)
          },
        })
      } else {
        Text(this.errorText).fontColor(Color.Red).margin(16).id('cyl-config-error')
        Button(CYLLocalizedString('Back')).onClick(() => router.back())
      }
    }
    .width('100%')
    .height('100%')
  }
}
