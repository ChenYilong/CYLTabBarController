import { CYLLocalizedString, cyl_localizationKey, CYLTabBarPageRegistry, CYLTabBarPageRequest, CYLTabBarPage } from 'cyltabbar';
import { demoRegisterPages } from '../demo/DemoPages';
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
  /**
   * [EN] The Loop switch of the Rive pages (tabBarItemAnimationLoops): the selected tab's icon plays again after each pass.
   * [CN] Rive 页面的循环开关（tabBarItemAnimationLoops）：选中 Tab 的图标每次播放后再次播放。
   */
  @State loops: boolean = false;
  private file: string = 'configurations/cyl_tabbar_configuration.json';

  aboutToAppear(): void {
    demoRegisterPages();
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

  /**
   * [EN] The registered page of a tab (CYLTabBarItemPageIdentifier, docs/Tab-Page-Registry.md), or undefined.
   * [CN] Tab 已注册的页面（页面 ID），没有时为 undefined。
   */
  private cylRegisteredPage(index: number): CYLTabBarPage | undefined {
    const pageIdentifier = this.result?.items[index]?.pageIdentifier;
    return pageIdentifier === undefined ? undefined : CYLTabBarPageRegistry.sharedRegistry.pageProviderForPageIdentifier(pageIdentifier);
  }

  private cylRequest(index: number): CYLTabBarPageRequest {
    const item = this.result?.items[index];
    const attributes: Record<string, Object> = {
      'CYLTabBarItemIdentifier': item?.identifier ?? `${index}`,
      'CYLTabBarItemTitle': typeof item?.title === 'string' ? item.title : '',
      'CYLTabBarItemPageParameters': item?.pageParameters ?? ({} as Record<string, Object>),
    };
    return new CYLTabBarPageRequest(item?.pageIdentifier ?? '', attributes);
  }

  @Builder
  cylPage(index: number, identifier: string) {
    if (this.cylRegisteredPage(index) !== undefined) {
      // [EN] The page the app registered for this page ID. [CN] App 为此页面 ID 注册的页面。
      this.cylRegisteredPage(index)!.builder(this.cylRequest(index))
    } else {
    Column() {
      Text(this.result?.items[index]?.title ?? identifier)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)

        // One line, ending with an ellipsis (UINavigationBar): long titles wrapped to two lines.

        .maxLines(1)

        .textOverflow({ overflow: TextOverflow.Ellipsis })
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
  }

  build() {
    Column() {
      if (this.result !== undefined && (this.file.indexOf('_rive') >= 0 || this.file.indexOf('_svga') >= 0)) {
        // [EN] The animated icon examples' loop switch (AGENTS.md), applied live. [CN] 动画图标示例的循环开关，立即生效。
        Row() {
          Text(CYLLocalizedString('循环播放')).fontSize(15).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.loops })
            .onChange((isOn: boolean) => { this.loops = isOn; })
            .id('cyl-config-loop')
            .accessibilityText(CYLLocalizedString('循环播放'))
        }
        .padding({ left: 16, right: 16 })
        .height(48)
        .width('100%')
      }
      if (this.result !== undefined) {
        CYLTabBarController({
          tabBarItemsAttributes: this.result.items,
          selectedIndex: $selectedIndex,
          // [EN] Without a tint in the file: the demo's orange (its Home screen, the SVGA icons), not system blue.
          // [CN] 文件未设置强调色时：使用演示的橙色（与首页、SVGA 图标一致），而不是系统蓝。
          tintColor: this.result.tintColor ?? '#FF8000',
          unselectedColor: this.result.unselectedColor ?? '#808080',
          iconColor: this.result.iconColor,
          selectedIconColor: this.result.selectedIconColor,
          iconRenderingMode: this.result.iconRenderingMode,
          tabBarBackgroundColor: this.result.backgroundColor ?? '',
          titlePositionAdjustment: this.result.titlePositionAdjustment,
          tabBarItemAnimationLoops: this.loops,
          pageBuilder: (index: number, identifier: string) => {
            this.cylPage(index, identifier)
          },
        })
        .layoutWeight(1)
      } else {
        Text(this.errorText).fontColor(Color.Red).margin(16).id('cyl-config-error')
        Button(CYLLocalizedString('Back')).onClick(() => router.back())
      }
    }
    .width('100%')
    .height('100%')
  }
}
