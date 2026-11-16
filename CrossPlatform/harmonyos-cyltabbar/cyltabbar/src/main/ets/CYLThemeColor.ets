import { CYLThemeManager, CYLThemeManagerCenter } from './CYLThemeManager';

/**
 * [EN] UIColor+CYLTheme (issue #216): a color that follows a CYLThemeManager's theme. ArkUI has no dynamic color
 *      object, so a theme color is a CYLThemeColor; read `cyl_rawColor` when building (inside a component that
 *      re-renders on CYLThemeDidChangeListener) to get the current theme's value.
 * [CN] 跟随 CYLThemeManager 主题的颜色。ArkUI 没有动态颜色对象，因此主题颜色是 CYLThemeColor；构建时读取 `cyl_rawColor`
 *      （在随主题监听重绘的组件中）得到当前主题的值。
 */
export type CYLThemeColorProvider = (manager: CYLThemeManager, identifier: string | undefined,
  theme: Object | undefined) => ResourceColor | CYLThemeColor;

export class CYLThemeColor {
  /** [EN] cyl_isThemeColor: always true. [CN] 恒为 true。 */
  readonly cyl_isThemeColor: boolean = true;
  /** [EN] cyl_themeColorName: the name given, else undefined. [CN] 颜色名字。 */
  readonly cyl_themeColorName?: string;
  private readonly managerName: string;
  private readonly provider: CYLThemeColorProvider;

  constructor(name: string | undefined, managerName: string, provider: CYLThemeColorProvider) {
    this.cyl_themeColorName = name;
    this.managerName = managerName;
    this.provider = provider;
  }

  /** [EN] cyl_rawColor: the value in the current theme (a returned theme color is resolved too). [CN] 当前主题下的值。 */
  get cyl_rawColor(): ResourceColor {
    let value: ResourceColor | CYLThemeColor = this;
    for (let depth = 0; depth < 8 && value instanceof CYLThemeColor; depth++) {
      const color = value as CYLThemeColor;
      const manager = CYLThemeManagerCenter.themeManagerWithName(color.managerName);
      value = color.provider(manager, manager.currentThemeIdentifier, manager.currentTheme);
    }
    return value instanceof CYLThemeColor ? Color.Transparent : value as ResourceColor;
  }

  /** [EN] +cyl_colorWithThemeProvider: (the default manager). [CN] 跟随默认管理器。 */
  static cyl_colorWithThemeProvider(provider: CYLThemeColorProvider): CYLThemeColor {
    return new CYLThemeColor(undefined, CYLThemeManagerCenter.defaultThemeManager.name, provider);
  }

  /** [EN] +cyl_colorWithName:themeProvider:. [CN] 带名字、跟随默认管理器。 */
  static cyl_colorWithName(name: string | undefined, provider: CYLThemeColorProvider): CYLThemeColor {
    return new CYLThemeColor(name, CYLThemeManagerCenter.defaultThemeManager.name, provider);
  }

  /** [EN] +cyl_colorWithThemeManagerName:provider:. [CN] 跟随指定名字的管理器。 */
  static cyl_colorWithThemeManagerName(managerName: string, provider: CYLThemeColorProvider): CYLThemeColor {
    return new CYLThemeColor(undefined, managerName, provider);
  }

  /** [EN] +cyl_colorWithName:themeManagerName:provider:. [CN] 带名字、跟随指定管理器。 */
  static cyl_colorWithNameAndThemeManagerName(name: string | undefined, managerName: string,
    provider: CYLThemeColorProvider): CYLThemeColor {
    return new CYLThemeColor(name, managerName, provider);
  }

  /** [EN] cyl_rawColor of any color: a plain color is returned as it is. [CN] 普通颜色原样返回。 */
  static cyl_rawColorOf(color: ResourceColor | CYLThemeColor): ResourceColor {
    return color instanceof CYLThemeColor ? (color as CYLThemeColor).cyl_rawColor : color as ResourceColor;
  }
}
