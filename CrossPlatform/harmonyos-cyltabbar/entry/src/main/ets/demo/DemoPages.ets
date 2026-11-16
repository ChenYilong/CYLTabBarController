import { CYLLocalizedString, CYLTabBarPageRegistry, CYLTabBarPageRequest } from 'cyltabbar';

/**
 * [EN] The pages the example registers for the page IDs of its configuration files (docs/Tab-Page-Registry.md): a
 *      colored page for each SVGA / Rive tab, a page with its URL for "web" (CYLTabBarItemPageParameters), and "web" also
 *      registered asynchronously to show the placeholder of a page loaded later.
 * [CN] 示例为其配置文件中的页面 ID 注册的页面：每个 SVGA / Rive Tab 一个彩色页面，"web" 显示其 URL（页面参数）。
 */
@Builder
function demoColorPage(request: CYLTabBarPageRequest) {
  Column() {
    Text(request.title ?? request.pageIdentifier)
      .fontSize(22)
      .fontColor(Color.White)
    Text(CYLLocalizedString('Page: %@', request.pageIdentifier))
      .fontSize(13)
      .fontColor('#E6FFFFFF')
      .margin({ top: 8 })
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .backgroundColor(request.pageIdentifier.endsWith('home') ? '#FF9500' : request.pageIdentifier.endsWith('discover') ? '#34C759'
    : request.pageIdentifier.endsWith('message') ? '#007AFF' : '#AF52DE')
  .accessibilityGroup(true)
  .accessibilityText(request.title ?? request.pageIdentifier)
  .id(`cyl-registry-page-${request.pageIdentifier}`)
}

@Builder
function demoWebPage(request: CYLTabBarPageRequest) {
  Column() {
    Text('web')
      .fontSize(22)
    Text(typeof request.parameters['url'] === 'string' ? request.parameters['url'] as string : '-')
      .fontSize(13)
      .fontColor('#007AFF')
      .margin({ top: 8 })
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .id('cyl-registry-page-web')
}

/** [EN] Registers the example's pages with the shared registry once. [CN] 向共享注册表注册一次示例页面。 */
export function demoRegisterPages(): void {
  const registry = CYLTabBarPageRegistry.sharedRegistry;
  if (registry.registeredPageIdentifiers.length > 0) {
    return;
  }
  registry.registerPageProviderForPageIdentifiers(wrapBuilder(demoColorPage),
    ['svga-home', 'svga-discover', 'svga-message', 'svga-me', 'rive-home', 'rive-discover', 'rive-message', 'rive-me']);
  registry.registerPageProvider(wrapBuilder(demoWebPage), 'web');
}
