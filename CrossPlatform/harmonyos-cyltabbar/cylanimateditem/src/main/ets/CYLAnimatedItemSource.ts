/**
 * [EN] An animation value parsed for the engines (pure, unit tested with Node: test/CYLAnimatedItemSource.test.mjs): the
 *      rawfile path (an `asset:` prefix is dropped) or inline Lottie JSON, the options after the first "#" or "?"
 *      ("house.riv#stateMachine=State%20Machine%201&input=active"; "?" is the earlier HarmonyOS form, still in configuration
 *      files), and the type by extension. Moved from the copies in cyltabbar (`cylRiveFileAndOptions`) and in
 *      CollectionViewClassifyMenu's `CYLAnimationSource`, so every engine reads a value the same way.
 * [CN] 为引擎解析的动画值（纯逻辑，用 Node 做单元测试：test/CYLAnimatedItemSource.test.mjs）：rawfile 路径（去掉 `asset:` 前缀）或内联
 *      Lottie JSON、第一个 "#" 或 "?" 之后的选项（"?" 是鸿蒙之前的写法，配置文件仍在使用），以及按扩展名得到的类型。从 cyltabbar
 *      （`cylRiveFileAndOptions`）与 CollectionViewClassifyMenu 的 `CYLAnimationSource` 中的副本迁移而来，使每个引擎以同一方式读取值。
 */
import { CYLAnimatedItemTypeRegistry } from './CYLAnimatedItemTypes';

/**
 * [EN] What the source needs from a Context: its resource manager's rawfile calls. [CN] 来源需要 Context 提供的内容：资源管理器的 rawfile 方法。
 */
export interface CYLAnimatedItemRawFileReader {
  getRawFileContentSync(path: string): Uint8Array;
  getRawFdSync(path: string): object;
  closeRawFdSync(path: string): void;
}

/**
 * [EN] The "name=value" pairs after the first "?" or "#": split at "&", and at a "?" or "#" that starts the next group
 *      ("artboard=CHAT#input=active"), not at one inside a value ("tint=#FF0000", a color written without encoding).
 * [CN] 第一个 "?" 或 "#" 之后的「名称=值」对：在 "&" 处分开，也在开始下一组的 "?" 或 "#" 处分开，但不在值内部的 "#" 处分开。
 */
function cylOptionPairs(text: string): string[] {
  const pairs: string[] = [];
  text.split('&').forEach((piece: string) => {
    let start = 0;
    for (let i = 1; i < piece.length; i++) {
      const c = piece.charAt(i);
      if ((c === '#' || c === '?') && piece.charAt(i - 1) !== '=') {
        pairs.push(piece.substring(start, i));
        start = i + 1;
      }
    }
    pairs.push(piece.substring(start));
  });
  return pairs;
}

function cylDecode(text: string): string {
  try {
    return decodeURIComponent(text);
  } catch (e) {
    return text;
  }
}

/**
 * [EN] The file part of a value and its options (the same rules as cyltabbar's `cylRiveFileAndOptions`).
 * [CN] 值的文件部分与选项（规则与 cyltabbar 的 `cylRiveFileAndOptions` 相同）。
 */
export function cylAnimatedItemFileAndOptions(url: string): [string, Map<string, string>] {
  const options: Map<string, string> = new Map<string, string>();
  const query = url.indexOf('?');
  const hash = url.indexOf('#');
  let at = query;
  if (query < 0) {
    at = hash;
  } else if (hash >= 0) {
    at = Math.min(query, hash);
  }
  if (at < 0) {
    return [url, options];
  }
  cylOptionPairs(url.substring(at + 1)).forEach((pair: string) => {
    const eq = pair.indexOf('=');
    if (eq > 0) {
      options.set(cylDecode(pair.substring(0, eq)), cylDecode(pair.substring(eq + 1)));
    }
  });
  return [url.substring(0, at), options];
}

/**
 * [EN] An animation value split into its file (or inline JSON), options and type.
 * [CN] 拆分为文件（或内联 JSON）、选项与类型的动画值。
 */
export class CYLAnimatedItemSource {
  /** [EN] The value as given. [CN] 原始值。 */
  url: string = '';
  /** [EN] The rawfile path, without `asset:` and options; '' for inline JSON. [CN] rawfile 路径，不含 `asset:` 与选项；内联 JSON 时为 ''。 */
  path: string = '';
  /** [EN] Inline Lottie JSON text. [CN] 内联 Lottie JSON 文本。 */
  inlineJSON?: string;
  options: Map<string, string> = new Map<string, string>();
  /** [EN] "Lottie", "PAG", "Rive", "SVGA", "GIF", an app's type, or ''. [CN] 类型，未知时为 ''。 */
  type: string = '';

  static parse(value: string): CYLAnimatedItemSource {
    const source = new CYLAnimatedItemSource();
    source.url = value;
    const trimmed = value.trim();
    if (!trimmed.startsWith('asset:') && (trimmed.startsWith('{') || trimmed.startsWith('['))) {
      source.inlineJSON = trimmed;
      source.type = 'Lottie';
      return source;
    }
    const raw = trimmed.startsWith('asset:') ? trimmed.substring('asset:'.length) : trimmed;
    const fileAndOptions = cylAnimatedItemFileAndOptions(raw);
    source.path = fileAndOptions[0];
    source.options = fileAndOptions[1];
    source.type = CYLAnimatedItemTypeRegistry.typeOf(source.path);
    return source;
  }

  /** [EN] An option, or undefined. [CN] 某个选项，没有时为 undefined。 */
  option(name: string): string | undefined {
    return this.options.get(name);
  }

  /** [EN] The directory of `path` with a trailing "/", or ''. [CN] `path` 的目录（以 "/" 结尾），或 ''。 */
  get directory(): string {
    const slash = this.path.lastIndexOf('/');
    return slash >= 0 ? this.path.substring(0, slash + 1) : '';
  }

  /** [EN] The last path component. [CN] 路径的最后一部分。 */
  get fileName(): string {
    return this.path.split('/').pop() ?? '';
  }

  /**
   * [EN] The rawfile names to try: `path`, then its last component (the Flutter and React Native examples write
   *      "asset:assets/<file>" for a file at the rawfile root). [CN] 依次尝试的 rawfile 名称：`path`，再试其最后一部分。
   */
  get rawFileCandidates(): string[] {
    return this.path === this.fileName ? [this.path] : [this.path, this.fileName];
  }

  /** [EN] The rawfile's bytes, or undefined. [CN] rawfile 的内容，没有时为 undefined。 */
  rawFileContent(reader: CYLAnimatedItemRawFileReader): Uint8Array | undefined {
    for (const name of this.rawFileCandidates) {
      try {
        return reader.getRawFileContentSync(name);
      } catch (e) {
        // [EN] Try the next name. [CN] 尝试下一个名称。
      }
    }
    return undefined;
  }

  /** [EN] The rawfile path that exists, else `path`. [CN] 存在的 rawfile 路径，否则为 `path`。 */
  existingRawFilePath(reader: CYLAnimatedItemRawFileReader): string {
    for (const name of this.rawFileCandidates) {
      try {
        reader.getRawFdSync(name);
        reader.closeRawFdSync(name);
        return name;
      } catch (e) {
        // [EN] Try the next name. [CN] 尝试下一个名称。
      }
    }
    return this.path;
  }
}
