/**
 * [EN] The animation types of CYLAnimatedItemView and which of them an app registered (pure, unit tested with Node:
 *      test/CYLAnimatedItemTypes.test.mjs). Built in: Lottie, PAG, Rive, SVGA, GIF. An app can add its own type with its
 *      file extensions (`register('APNG', ['png', 'apng'])`), add extensions to a known type, and unregister a type
 *      (a type it added is then forgotten; a built-in type stays known and only stops playing). `CYLAnimatedItemEngines`
 *      is the public face of this registry.
 * [CN] CYLAnimatedItemView 的动画类型，以及 App 注册了其中哪些（纯逻辑，用 Node 做单元测试：test/CYLAnimatedItemTypes.test.mjs）。内置：Lottie、
 *      PAG、Rive、SVGA、GIF。App 可以添加自己的类型及其扩展名（`register('APNG', ['png', 'apng'])`）、为已知类型添加扩展名，也可以注销类型
 *      （自己添加的类型随之被遗忘；内置类型仍为已知类型，只是不再播放）。`CYLAnimatedItemEngines` 是该注册表的公开接口。
 */

/** [EN] One animation type: its name, the package an app adds, and its file extensions. [CN] 一种动画类型：名称、App 需要加入的包与扩展名。 */
export class CYLAnimatedItemType {
  name: string = '';
  packageName: string = '';
  extensions: string[] = [];

  constructor(name: string, packageName: string, extensions: string[]) {
    this.name = name;
    this.packageName = packageName;
    this.extensions = extensions;
  }
}

const CYL_BUILT_IN_TYPES: CYLAnimatedItemType[] = [
  new CYLAnimatedItemType('Lottie', '@ohos/lottie', ['json', 'lottie']),
  new CYLAnimatedItemType('PAG', 'libpag', ['pag']),
  new CYLAnimatedItemType('Rive', '@ohos/rive', ['riv']),
  new CYLAnimatedItemType('SVGA', 'an SVGA player', ['svga']),
  new CYLAnimatedItemType('GIF', 'the system Image component', ['gif'])
];

export class CYLAnimatedItemTypeRegistry {
  private static added: CYLAnimatedItemType[] = [];
  private static extraExtensions: Map<string, string[]> = new Map();
  private static registered: string[] = [];

  /** [EN] Every known type: the built-in ones, then the ones apps added. [CN] 所有已知类型：内置类型，然后是 App 添加的类型。 */
  static knownTypes(): CYLAnimatedItemType[] {
    return CYL_BUILT_IN_TYPES.concat(CYLAnimatedItemTypeRegistry.added);
  }

  /** [EN] The known type named `name`, or undefined. [CN] 名为 `name` 的已知类型；没有时为 undefined。 */
  static typeNamed(name: string): CYLAnimatedItemType | undefined {
    return CYLAnimatedItemTypeRegistry.knownTypes().find((type: CYLAnimatedItemType) => type.name === name);
  }

  /** [EN] The extensions of a type, its added ones included, lower case. [CN] 某类型的扩展名（含添加的扩展名），小写。 */
  static extensionsOf(name: string): string[] {
    const type = CYLAnimatedItemTypeRegistry.typeNamed(name);
    const own = type === undefined ? [] : type.extensions;
    return own.concat(CYLAnimatedItemTypeRegistry.extraExtensions.get(name) ?? []);
  }

  /**
   * [EN] The type of a file from its extension, or '' when unknown. A trailing ".bin" is skipped ("icons.riv.bin" is Rive).
   *      A type an app added wins over a built-in type for the same extension.
   * [CN] 根据扩展名得到文件的类型，未知时为 ''。忽略末尾的 ".bin"（"icons.riv.bin" 为 Rive）。同一扩展名时 App 添加的类型优先于内置类型。
   */
  static typeOf(url: string): string {
    const file = url.split('#')[0].split('?')[0].replace(/\.bin$/i, '');
    const dot = file.lastIndexOf('.');
    if (dot < 0) {
      return '';
    }
    const extension = file.substring(dot + 1).toLowerCase();
    const types = CYLAnimatedItemTypeRegistry.added.concat(CYL_BUILT_IN_TYPES);
    for (const type of types) {
      if (CYLAnimatedItemTypeRegistry.extensionsOf(type.name).includes(extension)) {
        return type.name;
      }
    }
    return '';
  }

  /**
   * [EN] Registers the engine of `name`. With `extensions`, an unknown name becomes a new type with them, and a known
   *      type gets them in addition (lower case, without the dot).
   * [CN] 注册 `name` 的引擎。传入 `extensions` 时，未知名称成为带这些扩展名的新类型，已知类型则额外获得这些扩展名（小写，不带点）。
   */
  static register(name: string, extensions?: string[], packageName?: string): void {
    if (name.length === 0) {
      return;
    }
    const clean = (extensions ?? []).map((extension: string) => extension.replace(/^\./, '').toLowerCase()).filter((extension: string) => extension.length > 0);
    const known = CYLAnimatedItemTypeRegistry.typeNamed(name);
    if (known === undefined && clean.length > 0) {
      CYLAnimatedItemTypeRegistry.added.push(new CYLAnimatedItemType(name, packageName ?? '', clean));
    } else if (known !== undefined && clean.length > 0) {
      const extra = CYLAnimatedItemTypeRegistry.extraExtensions.get(name) ?? [];
      clean.forEach((extension: string) => {
        if (!known.extensions.includes(extension) && !extra.includes(extension)) {
          extra.push(extension);
        }
      });
      CYLAnimatedItemTypeRegistry.extraExtensions.set(name, extra);
    }
    if (!CYLAnimatedItemTypeRegistry.registered.includes(name)) {
      CYLAnimatedItemTypeRegistry.registered.push(name);
    }
  }

  /**
   * [EN] Unregisters the engine of `name`: its files show the static image again. A type an app added is forgotten
   *      with its extensions; a built-in type stays known (and loses the extensions added to it).
   * [CN] 注销 `name` 的引擎：其文件重新显示静态图片。App 添加的类型连同扩展名一起被遗忘；内置类型仍为已知类型（添加给它的扩展名被移除）。
   */
  static unregister(name: string): void {
    CYLAnimatedItemTypeRegistry.registered = CYLAnimatedItemTypeRegistry.registered.filter((each: string) => each !== name);
    CYLAnimatedItemTypeRegistry.added = CYLAnimatedItemTypeRegistry.added.filter((type: CYLAnimatedItemType) => type.name !== name);
    CYLAnimatedItemTypeRegistry.extraExtensions.delete(name);
  }

  static isRegistered(name: string): boolean {
    return CYLAnimatedItemTypeRegistry.registered.includes(name);
  }

  static registeredTypes(): string[] {
    return CYLAnimatedItemTypeRegistry.registered.slice();
  }

  /** [EN] The known types nobody registered. [CN] 没有注册的已知类型。 */
  static missingTypes(): string[] {
    return CYLAnimatedItemTypeRegistry.knownTypes()
      .filter((type: CYLAnimatedItemType) => !CYLAnimatedItemTypeRegistry.isRegistered(type.name))
      .map((type: CYLAnimatedItemType) => type.name);
  }

  /** [EN] Whether a registered engine plays `url`. [CN] 是否有已注册的引擎能播放 `url`。 */
  static canPlay(url: string): boolean {
    const name = CYLAnimatedItemTypeRegistry.typeOf(url);
    return name.length > 0 && CYLAnimatedItemTypeRegistry.isRegistered(name);
  }

  /** [EN] Forgets every registration and added type (tests). [CN] 清除所有注册与添加的类型（测试用）。 */
  static reset(): void {
    CYLAnimatedItemTypeRegistry.added = [];
    CYLAnimatedItemTypeRegistry.extraExtensions = new Map();
    CYLAnimatedItemTypeRegistry.registered = [];
  }
}
