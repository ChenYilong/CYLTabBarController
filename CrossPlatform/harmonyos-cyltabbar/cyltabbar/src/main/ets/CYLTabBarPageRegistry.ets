/**
 * [EN] The page registry (iOS CYLTabBarPageRegistry.h, Android CYLTabBarPageRegistry.kt, docs/Tab-Page-Registry.md): a
 *      configuration names each tab's page by a cross-platform page ID (CYLTabBarItemPageIdentifier); the app registers
 *      what each ID builds. On HarmonyOS a page is a builder (`WrappedBuilder<[CYLTabBarPageRequest]>`, made with
 *      `wrapBuilder(myPageBuilder)`). Lookup order: instance (the registry given to the tab bar), resolver, shared.
 * [CN] 页面注册表：配置用跨平台页面 ID（CYLTabBarItemPageIdentifier）指定每个 Tab 的页面，App 注册每个 ID 对应的页面。鸿蒙上页面是一个 builder
 *      （`WrappedBuilder<[CYLTabBarPageRequest]>`，用 `wrapBuilder(myPageBuilder)` 创建）。查找顺序：instance、resolver、shared。
 */

/**
 * [EN] CYLTabBarPageRequest: what a page is built from (typed, read-only). [CN] 创建页面所需的信息（只读）。
 */
export class CYLTabBarPageRequest {
  /** [EN] CYLTabBarItemPageIdentifier. [CN] 页面 ID。 */
  readonly pageIdentifier: string;
  /** [EN] CYLTabBarItemIdentifier, or undefined. [CN] Tab 的 identifier。 */
  readonly tabIdentifier?: string;
  /** [EN] CYLTabBarItemTitle, or undefined. [CN] Tab 标题。 */
  readonly title?: string;
  /** [EN] CYLTabBarItemPageParameters; empty when none. [CN] 页面参数；没有时为空。 */
  readonly parameters: Record<string, Object>;
  /** [EN] Every public attribute of the tab (no key that starts with "_"). [CN] Tab 的所有公开属性。 */
  readonly attributes: Record<string, Object>;

  constructor(pageIdentifier: string, attributes: Record<string, Object>) {
    this.pageIdentifier = pageIdentifier;
    const visible: Record<string, Object> = {};
    Object.keys(attributes).filter((key: string) => !key.startsWith('_')).forEach((key: string) => visible[key] = attributes[key]);
    this.attributes = visible;
    this.tabIdentifier = typeof attributes['CYLTabBarItemIdentifier'] === 'string' ? attributes['CYLTabBarItemIdentifier'] as string : undefined;
    this.title = typeof attributes['CYLTabBarItemTitle'] === 'string' ? attributes['CYLTabBarItemTitle'] as string : undefined;
    const parameters = attributes['CYLTabBarItemPageParameters'];
    this.parameters = parameters !== undefined && typeof parameters === 'object' && !Array.isArray(parameters)
      ? parameters as Record<string, Object> : {};
  }

  /** [EN] +requestWithPageIdentifier:attributes:. [CN] 创建请求。 */
  static requestWithPageIdentifier(pageIdentifier: string, attributes: Record<string, Object>): CYLTabBarPageRequest {
    return new CYLTabBarPageRequest(pageIdentifier, attributes);
  }
}

/** [EN] CYLTabBarPageProvider / CYLTabBarPageFactory: the page of a request. [CN] 根据请求创建页面。 */
export type CYLTabBarPage = WrappedBuilder<[CYLTabBarPageRequest]>;

/** [EN] CYLTabBarAsyncPageFactory: the page delivered later (a module loaded later); undefined removes the tab. [CN] 异步创建页面；undefined 移除该 Tab。 */
export type CYLTabBarAsyncPageFactory = (request: CYLTabBarPageRequest) => Promise<CYLTabBarPage | undefined>;

/** [EN] CYLTabBarPageResolver: the app's own lookup (a router), undefined when it has none. [CN] App 自己的查找（路由）。 */
export type CYLTabBarPageResolver = (request: CYLTabBarPageRequest) => CYLTabBarPage | undefined;

/** [EN] CYLTabBarPageSource: where a page is looked up (CYLTabBarControllerPageLookupOrder). [CN] 页面查找来源。 */
export enum CYLTabBarPageSource {
  InstanceRegistry = 'instance',
  Resolver = 'resolver',
  SharedRegistry = 'shared',
  AutomaticRegistration = 'automatic',
}

/** [EN] CYLTabBarPageSkipReason: why a tab got no page. [CN] Tab 没有页面的原因。 */
export enum CYLTabBarPageSkipReason {
  NoPageIdentifier = 'noPageIdentifier',
  Unregistered = 'unregistered',
  ProviderFailed = 'providerFailed',
}

/** [EN] CYLTabBarSkippedTab: a tab that got no page, and why. [CN] 没有页面的 Tab 及原因。 */
export class CYLTabBarSkippedTab {
  readonly reason: CYLTabBarPageSkipReason;
  readonly pageIdentifier?: string;
  readonly title?: string;
  readonly attributes: Record<string, Object>;
  /** [EN] Details in English (the source that failed, the error), or undefined. [CN] 英文详情。 */
  readonly detail?: string;

  constructor(reason: CYLTabBarPageSkipReason, pageIdentifier: string | undefined, attributes: Record<string, Object>, detail?: string) {
    this.reason = reason;
    this.pageIdentifier = pageIdentifier;
    this.attributes = attributes;
    this.title = typeof attributes['CYLTabBarItemTitle'] === 'string' ? attributes['CYLTabBarItemTitle'] as string : undefined;
    this.detail = detail;
  }

  /** [EN] +skippedTabWithReason:pageIdentifier:attributes:detail:. [CN] 创建跳过记录。 */
  static skippedTabWithReason(reason: CYLTabBarPageSkipReason, pageIdentifier: string | undefined,
    attributes: Record<string, Object>, detail?: string): CYLTabBarSkippedTab {
    return new CYLTabBarSkippedTab(reason, pageIdentifier, attributes, detail);
  }
}

/** [EN] One resolved tab: its page (or an async factory) and its request. [CN] 一个已解析的 Tab。 */
export class CYLTabBarResolvedPage {
  readonly request: CYLTabBarPageRequest;
  readonly page?: CYLTabBarPage;
  readonly asyncFactory?: CYLTabBarAsyncPageFactory;
  readonly source: CYLTabBarPageSource;

  constructor(request: CYLTabBarPageRequest, source: CYLTabBarPageSource, page?: CYLTabBarPage, asyncFactory?: CYLTabBarAsyncPageFactory) {
    this.request = request;
    this.source = source;
    this.page = page;
    this.asyncFactory = asyncFactory;
  }
}

/** [EN] The result of pagesOfTabs: the kept tabs (with their pages) and the skipped ones. [CN] pagesOfTabs 的结果。 */
export class CYLTabBarPagesResult {
  readonly kept: CYLTabBarResolvedPage[] = [];
  readonly skipped: CYLTabBarSkippedTab[] = [];
}

/**
 * [EN] CYLTabBarPageProviding: a source of pages; CYLTabBarPageRegistry adopts it, an app's router can too.
 * [CN] 页面来源；CYLTabBarPageRegistry 实现它，App 的路由也可以实现。
 */
export interface CYLTabBarPageProviding {
  pageProviderForPageIdentifier(pageIdentifier: string): CYLTabBarPage | undefined;
}

/**
 * [EN] CYLTabBarPageRegistry: page ID -> page (builder) or async factory.
 * [CN] 页面 ID -> 页面（builder）或异步工厂。
 */
export class CYLTabBarPageRegistry implements CYLTabBarPageProviding {
  private static shared: CYLTabBarPageRegistry = new CYLTabBarPageRegistry();
  private pages: Map<string, CYLTabBarPage> = new Map();
  private asyncFactories: Map<string, CYLTabBarAsyncPageFactory> = new Map();

  /** [EN] sharedRegistry: the global registry. [CN] 全局注册表。 */
  static get sharedRegistry(): CYLTabBarPageRegistry {
    return CYLTabBarPageRegistry.shared;
  }

  /** [EN] defaultPageLookupOrder: [instance, resolver, shared]. [CN] 默认查找顺序。 */
  static get defaultPageLookupOrder(): CYLTabBarPageSource[] {
    return [CYLTabBarPageSource.InstanceRegistry, CYLTabBarPageSource.Resolver, CYLTabBarPageSource.SharedRegistry];
  }

  /** [EN] -registerPageProvider:forPageIdentifier: / -registerPageFactory:forPageIdentifier:. [CN] 注册页面。 */
  registerPageProvider(page: CYLTabBarPage, pageIdentifier: string): void {
    this.asyncFactories.delete(pageIdentifier);
    this.pages.set(pageIdentifier, page);
  }

  /** [EN] -registerPageProvider:forPageIdentifiers:. [CN] 为多个 ID 注册同一页面。 */
  registerPageProviderForPageIdentifiers(page: CYLTabBarPage, pageIdentifiers: string[]): void {
    pageIdentifiers.forEach((id: string) => this.registerPageProvider(page, id));
  }

  /** [EN] -registerPageFactory:forPageIdentifier:: the same as a provider (the request is typed). [CN] 与 provider 相同。 */
  registerPageFactory(page: CYLTabBarPage, pageIdentifier: string): void {
    this.registerPageProvider(page, pageIdentifier);
  }

  /** [EN] -registerPageFactory:forPageIdentifiers:. [CN] 为多个 ID 注册。 */
  registerPageFactoryForPageIdentifiers(page: CYLTabBarPage, pageIdentifiers: string[]): void {
    this.registerPageProviderForPageIdentifiers(page, pageIdentifiers);
  }

  /** [EN] -registerAsyncPageFactory:forPageIdentifier:. [CN] 注册异步工厂。 */
  registerAsyncPageFactory(factory: CYLTabBarAsyncPageFactory, pageIdentifier: string): void {
    this.pages.delete(pageIdentifier);
    this.asyncFactories.set(pageIdentifier, factory);
  }

  /** [EN] -registerAsyncPageFactory:forPageIdentifiers:. [CN] 为多个 ID 注册异步工厂。 */
  registerAsyncPageFactoryForPageIdentifiers(factory: CYLTabBarAsyncPageFactory, pageIdentifiers: string[]): void {
    pageIdentifiers.forEach((id: string) => this.registerAsyncPageFactory(factory, id));
  }

  /** [EN] -unregisterPageIdentifier:. [CN] 注销。 */
  unregisterPageIdentifier(pageIdentifier: string): void {
    this.pages.delete(pageIdentifier);
    this.asyncFactories.delete(pageIdentifier);
  }

  /** [EN] -removeAllPageProviders. [CN] 移除全部。 */
  removeAllPageProviders(): void {
    this.pages.clear();
    this.asyncFactories.clear();
  }

  /** [EN] -pageProviderForPageIdentifier:. [CN] 查找页面。 */
  pageProviderForPageIdentifier(pageIdentifier: string): CYLTabBarPage | undefined {
    return this.pages.get(pageIdentifier);
  }

  /** [EN] The async factory of a page ID. [CN] 页面 ID 的异步工厂。 */
  asyncPageFactoryForPageIdentifier(pageIdentifier: string): CYLTabBarAsyncPageFactory | undefined {
    return this.asyncFactories.get(pageIdentifier);
  }

  /** [EN] registeredPageIdentifiers, sorted. [CN] 已注册的页面 ID（排序）。 */
  get registeredPageIdentifiers(): string[] {
    const ids: string[] = [];
    this.pages.forEach((_: CYLTabBarPage, id: string) => ids.push(id));
    this.asyncFactories.forEach((_: CYLTabBarAsyncPageFactory, id: string) => ids.push(id));
    return ids.sort();
  }

  /** [EN] +pageIdentifierOfTab:: the tab's CYLTabBarItemPageIdentifier, or undefined. [CN] Tab 的页面 ID。 */
  static pageIdentifierOfTab(attributes: Record<string, Object>): string | undefined {
    const id = attributes['CYLTabBarItemPageIdentifier'];
    return typeof id === 'string' && id.length > 0 ? id : undefined;
  }

  /**
   * [EN] +pagesOfTabs:registry:resolver:lookupOrder:keptTabs:skipped:: resolves each tab's page in the lookup order; a tab
   *      without an ID or a page is skipped with its reason. [CN] 按查找顺序解析每个 Tab 的页面；没有 ID 或页面的 Tab 被跳过并记录原因。
   */
  static pagesOfTabs(tabs: Record<string, Object>[], registry?: CYLTabBarPageProviding, resolver?: CYLTabBarPageResolver,
    lookupOrder: CYLTabBarPageSource[] = CYLTabBarPageRegistry.defaultPageLookupOrder): CYLTabBarPagesResult {
    const result = new CYLTabBarPagesResult();
    tabs.forEach((tab: Record<string, Object>) => {
      const pageIdentifier = CYLTabBarPageRegistry.pageIdentifierOfTab(tab);
      if (pageIdentifier === undefined) {
        result.skipped.push(new CYLTabBarSkippedTab(CYLTabBarPageSkipReason.NoPageIdentifier, undefined, tab));
        return;
      }
      const request = new CYLTabBarPageRequest(pageIdentifier, tab);
      for (const source of lookupOrder) {
        try {
          if (source === CYLTabBarPageSource.InstanceRegistry && registry !== undefined) {
            const page = registry.pageProviderForPageIdentifier(pageIdentifier);
            if (page !== undefined) {
              result.kept.push(new CYLTabBarResolvedPage(request, source, page));
              return;
            }
          } else if (source === CYLTabBarPageSource.Resolver && resolver !== undefined) {
            const page = resolver(request);
            if (page !== undefined) {
              result.kept.push(new CYLTabBarResolvedPage(request, source, page));
              return;
            }
          } else if (source === CYLTabBarPageSource.SharedRegistry) {
            const shared = CYLTabBarPageRegistry.sharedRegistry;
            const page = shared.pageProviderForPageIdentifier(pageIdentifier);
            const factory = shared.asyncPageFactoryForPageIdentifier(pageIdentifier);
            if (page !== undefined || factory !== undefined) {
              result.kept.push(new CYLTabBarResolvedPage(request, source, page, factory));
              return;
            }
          }
        } catch (error) {
          result.skipped.push(new CYLTabBarSkippedTab(CYLTabBarPageSkipReason.ProviderFailed, pageIdentifier, tab,
            `${source}: ${(error as Error).message}`));
          return;
        }
      }
      result.skipped.push(new CYLTabBarSkippedTab(CYLTabBarPageSkipReason.Unregistered, pageIdentifier, tab,
        `no page for "${pageIdentifier}" in ${lookupOrder.join(', ')}`));
    });
    return result;
  }
}
