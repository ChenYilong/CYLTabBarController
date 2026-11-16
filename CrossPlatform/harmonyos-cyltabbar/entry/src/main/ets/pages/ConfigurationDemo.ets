import { CYLLocalizedString, cyl_localizationKey } from 'cyltabbar';
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

/**
 * [EN] The English titles of the shared configuration files (Example-Shared/Configurations), as localization keys: the
 *      tabs show them in the device language like every other text of the demo.
 * [CN] 共享配置文件中的英文标题，作为本地化 key：Tab 与演示中的其他文字一样按设备语言显示。
 */
const CYL_CONFIGURATION_TITLES: string[] = [
  cyl_localizationKey('Home'), cyl_localizationKey('Discover'), cyl_localizationKey('Message'), cyl_localizationKey('Me'),
];

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
      const result = CYLTabBarConfiguration.resultWithConfiguration(configuration, '1.0.0', false);
      result.items.forEach((item) => {
        if (typeof item.title === 'string' && CYL_CONFIGURATION_TITLES.indexOf(item.title) >= 0) {
          item.title = CYLLocalizedString(item.title);
        }
      });
      this.result = result;
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
      // [EN] What this page is, in the device language; the page identifier only when the item has one.
      // [CN] 说明本页内容（设备语言）；只有设置了页面标识时才显示。
      Text(CYLLocalizedString('Configuration file: %@', this.file) + '\n' + CYLLocalizedString('Tab: %@', identifier)
        + (this.result?.items[index]?.pageIdentifier !== undefined
          ? '\n' + CYLLocalizedString('Page: %@', this.result?.items[index]?.pageIdentifier ?? '') : ''))
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
          // [EN] Without a tint in the file: the demo's orange (its Home screen, the SVGA icons), not system blue.
          // [CN] 文件未设置强调色时：使用演示的橙色（与首页、SVGA 图标一致），而不是系统蓝。
          tintColor: this.result.tintColor ?? '#FF8000',
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
