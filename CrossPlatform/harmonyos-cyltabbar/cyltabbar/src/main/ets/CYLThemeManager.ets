import { preferences } from '@kit.ArkData';

/**
 * [EN] Skins (issue #216), ported from CYLThemeManager.kt with the iOS names (CYLThemeManager.h, CYLThemeManagerCenter.h):
 *      a manager holds themes by identifier; setting currentThemeIdentifier notifies the listeners
 *      (CYLThemeDidChangeNotification), and the tab bar controllers following the manager apply the theme.
 * [CN] 皮肤（issue #216），从 CYLThemeManager.kt 迁移，使用 iOS 名称：管理器按 identifier 保存主题；设置 currentThemeIdentifier 时通知监听者
 *      （CYLThemeDidChangeNotification），跟随该管理器的 TabBarController 应用主题。
 */

/** [EN] CYLThemeManagerNameDefault. [CN] 默认管理器的名称。 */
export const CYLThemeManagerNameDefault: string = 'Default';

/** [EN] CYLThemeDidChangeNotification: (manager, identifier, theme). [CN] 主题变化的回调。 */
export type CYLThemeDidChangeListener = (manager: CYLThemeManager, identifier: string | undefined, theme: Object | undefined) => void;

/**
 * [EN] CYLThemeManager: one dimension of themes.
 * [CN] CYLThemeManager：一个维度的主题。
 */
export class CYLThemeManager {
  /** [EN] name: the name given by CYLThemeManagerCenter.themeManagerWithName. [CN] 由 CYLThemeManagerCenter 创建时的名称。 */
  readonly name: string;
  /** [EN] respondsSystemStyleAutomatically: follow the system dark mode through identifierForTrait. [CN] 通过 identifierForTrait 跟随系统深色模式。 */
  respondsSystemStyleAutomatically: boolean = false;
  /** [EN] identifierForTrait: 'dark' / 'light' -> the identifier to use. [CN] 系统外观 -> 主题 identifier。 */
  identifierForTrait?: (colorMode: string) => string | undefined;
  /** [EN] persistsCurrentThemeIdentifier: saved in preferences, restored by restore(context). [CN] 当前主题保存到 preferences，由 restore(context) 恢复。 */
  persistsCurrentThemeIdentifier: boolean = false;
  /** [EN] themeChangeAnimationDuration (ms): followers cross-fade when > 0. [CN] 大于 0 时跟随者淡入淡出（毫秒）。 */
  themeChangeAnimationDuration: number = 0;
  /** [EN] themeGenerator: makes the theme of an unregistered identifier. [CN] 为未注册的 identifier 创建主题。 */
  themeGenerator?: (identifier: string) => Object | undefined;
  /** [EN] themeIdentifierGenerator: makes the identifier of an unregistered theme. [CN] 为未注册的主题创建 identifier。 */
  themeIdentifierGenerator?: (theme: Object) => string | undefined;
  private identifiers: string[] = [];
  private themeObjects: Object[] = [];
  private current?: string;
  private listeners: CYLThemeDidChangeListener[] = [];
  private store?: preferences.Preferences;

  /** [EN] -init / +new: an unnamed manager; prefer CYLThemeManagerCenter.themeManagerWithName. [CN] 无名管理器；建议用 CYLThemeManagerCenter。 */
  constructor(name: string = '') {
    this.name = name;
  }

  /** [EN] themeIdentifiers, in the order added. [CN] 所有主题 identifier，按添加顺序。 */
  get themeIdentifiers(): string[] {
    return this.identifiers.slice();
  }

  /** [EN] themes, in the order added. [CN] 所有主题对象，按添加顺序。 */
  get themes(): Object[] {
    return this.themeObjects.slice();
  }

  /** [EN] currentThemeIdentifier; setting it notifies the listeners (unknown identifiers go through themeGenerator). [CN] 当前主题；设置时通知监听者。 */
  get currentThemeIdentifier(): string | undefined {
    return this.current;
  }

  set currentThemeIdentifier(identifier: string | undefined) {
    if (identifier !== undefined && this.identifiers.indexOf(identifier) < 0 && this.themeGenerator !== undefined) {
      const theme = this.themeGenerator(identifier);
      if (theme !== undefined) {
        this.addThemeIdentifier(identifier, theme);
      }
    }
    if (identifier === this.current) {
      return;
    }
    this.current = identifier;
    if (this.persistsCurrentThemeIdentifier && this.store !== undefined) {
      this.store.putSync(this.cylKey(), identifier ?? '');
      this.store.flush();
    }
    const theme = this.currentTheme;
    this.listeners.slice().forEach((listener: CYLThemeDidChangeListener) => listener(this, identifier, theme));
  }

  /** [EN] currentTheme: the theme of currentThemeIdentifier; setting it selects that theme. [CN] 当前主题对象；设置即选择该主题。 */
  get currentTheme(): Object | undefined {
    return this.current === undefined ? undefined : this.themeForIdentifier(this.current);
  }

  set currentTheme(theme: Object | undefined) {
    this.currentThemeIdentifier = theme === undefined ? undefined : this.identifierForTheme(theme);
  }

  /** [EN] -addThemeIdentifier:theme: (replaces the theme of an existing identifier). [CN] 添加主题（已存在则替换）。 */
  addThemeIdentifier(identifier: string, theme: Object): void {
    const index = this.identifiers.indexOf(identifier);
    if (index >= 0) {
      this.themeObjects[index] = theme;
    } else {
      this.identifiers.push(identifier);
      this.themeObjects.push(theme);
    }
  }

  /** [EN] -removeThemeIdentifier:. [CN] 按 identifier 移除主题。 */
  removeThemeIdentifier(identifier: string): void {
    const index = this.identifiers.indexOf(identifier);
    if (index >= 0) {
      this.identifiers.splice(index, 1);
      this.themeObjects.splice(index, 1);
    }
  }

  /** [EN] -removeTheme:. [CN] 移除主题对象。 */
  removeTheme(theme: Object): void {
    const index = this.themeObjects.indexOf(theme);
    if (index >= 0) {
      this.identifiers.splice(index, 1);
      this.themeObjects.splice(index, 1);
    }
  }

  /** [EN] -themeForIdentifier:. [CN] identifier 对应的主题。 */
  themeForIdentifier(identifier: string): Object | undefined {
    const index = this.identifiers.indexOf(identifier);
    return index >= 0 ? this.themeObjects[index] : undefined;
  }

  /** [EN] -identifierForTheme: (themeIdentifierGenerator for unregistered themes). [CN] 主题对应的 identifier。 */
  identifierForTheme(theme: Object): string | undefined {
    const index = this.themeObjects.indexOf(theme);
    if (index >= 0) {
      return this.identifiers[index];
    }
    const identifier = this.themeIdentifierGenerator?.(theme);
    if (identifier !== undefined) {
      this.addThemeIdentifier(identifier, theme);
    }
    return identifier;
  }

  /** [EN] -updateThemeForTraitCollection:: with respondsSystemStyleAutomatically, picks the theme of the color mode. [CN] 按系统外观选择主题。 */
  updateThemeForTraitCollection(colorMode: string): void {
    if (this.respondsSystemStyleAutomatically && this.identifierForTrait !== undefined) {
      const identifier = this.identifierForTrait(colorMode);
      if (identifier !== undefined) {
        this.currentThemeIdentifier = identifier;
      }
    }
  }

  /** [EN] Adds a CYLThemeDidChangeNotification observer. [CN] 添加主题变化监听。 */
  addListener(listener: CYLThemeDidChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  removeListener(listener: CYLThemeDidChangeListener): void {
    this.listeners = this.listeners.filter((item: CYLThemeDidChangeListener) => item !== listener);
  }

  /**
   * [EN] persistsCurrentThemeIdentifier: opens the preferences store and restores the saved identifier.
   * [CN] 打开 preferences 并恢复保存的主题。
   */
  restore(context: Context): void {
    this.store = preferences.getPreferencesSync(context, { name: 'cyl_theme' });
    const saved = this.store.getSync(this.cylKey(), '') as string;
    if (this.persistsCurrentThemeIdentifier && saved.length > 0) {
      this.currentThemeIdentifier = saved;
    }
  }

  private cylKey(): string {
    return `CYLThemeManager.${this.name}`;
  }
}

/**
 * [EN] CYLThemeManagerCenter: one manager per name.
 * [CN] 每个名称一个管理器。
 */
export class CYLThemeManagerCenter {
  private static managers: CYLThemeManager[] = [];

  /** [EN] +themeManagerWithName:. [CN] 获取（必要时创建）该名称的管理器。 */
  static themeManagerWithName(name: string): CYLThemeManager {
    const found = CYLThemeManagerCenter.managers.find((manager: CYLThemeManager) => manager.name === name);
    if (found !== undefined) {
      return found;
    }
    const manager = new CYLThemeManager(name);
    CYLThemeManagerCenter.managers.push(manager);
    return manager;
  }

  /** [EN] defaultThemeManager. [CN] 默认管理器。 */
  static get defaultThemeManager(): CYLThemeManager {
    return CYLThemeManagerCenter.themeManagerWithName(CYLThemeManagerNameDefault);
  }

  /** [EN] themeManagers. [CN] 已创建的所有管理器。 */
  static get themeManagers(): CYLThemeManager[] {
    return CYLThemeManagerCenter.managers.slice();
  }

  /** [EN] +updateThemesForTraitCollection:. [CN] 让所有管理器按系统外观更新主题。 */
  static updateThemesForTraitCollection(colorMode: string): void {
    CYLThemeManagerCenter.managers.forEach((manager: CYLThemeManager) => manager.updateThemeForTraitCollection(colorMode));
  }
}
