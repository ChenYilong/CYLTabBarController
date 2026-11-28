/**
 * [EN] CYLTabBarConfigurationParser for HarmonyOS, ported from CYLTabBarConfigurationParser.kt (iOS names, raw values,
 *      limits and error codes). Formats so far: JSON and JSON5 / JSONC; the others report UnsupportedFormat (TODO in
 *      docs/HarmonyOS-Parity.md). Values: string, boolean, number, Record (dictionary), Array, null.
 * [CN] 鸿蒙版 CYLTabBarConfigurationParser，从 CYLTabBarConfigurationParser.kt 迁移（iOS 名称、原始值、限制与错误码）。目前支持 JSON 与
 *      JSON5 / JSONC；其他格式返回 UnsupportedFormat（见 docs/HarmonyOS-Parity.md 的 TODO）。
 */

/** [EN] CYLTabBarConfigurationErrorDomain. [CN] 配置错误域。 */
export const CYLTabBarConfigurationErrorDomain: string = 'CYLTabBarConfigurationErrorDomain';
/** [EN] CYLTabBarConfigurationMaximumLength: 5 MB. [CN] 最大长度 5 MB。 */
export const CYLTabBarConfigurationMaximumLength: number = 5 * 1024 * 1024;
/** [EN] CYLTabBarConfigurationMaximumDepth: 64 levels. [CN] 最大嵌套 64 层。 */
export const CYLTabBarConfigurationMaximumDepth: number = 64;

/** [EN] CYLTabBarConfigurationFormat, iOS raw values. [CN] 配置格式，原始值与 iOS 相同。 */
export enum CYLTabBarConfigurationFormat {
  Unknown = 0,
  JSON = 1,
  JSON5 = 2,
  PropertyList = 3,
  YAML = 4,
  TOML = 5,
  INI = 6,
  Properties = 7,
  XML = 8,
  ProtobufText = 9,
  Protobuf = 10,
}

/** [EN] CYLTabBarConfigurationErrorCode, iOS raw values. [CN] 配置错误码，原始值与 iOS 相同。 */
export enum CYLTabBarConfigurationErrorCode {
  FileNotFound = 1,
  UnsupportedFormat = 2,
  InvalidSyntax = 3,
  NotADictionary = 4,
  Network = 5,
  Empty = 6,
  TooLarge = 7,
  TooDeep = 8,
  NoTabs = 9,
  MainThreadRequired = 10,
  NoPages = 11,
}

/** [EN] The NSError of CYLTabBarConfigurationErrorDomain. [CN] 配置错误。 */
export class CYLTabBarConfigurationError extends Error {
  readonly domain: string = CYLTabBarConfigurationErrorDomain;
  readonly code: CYLTabBarConfigurationErrorCode;

  constructor(code: CYLTabBarConfigurationErrorCode, message: string) {
    super(message);
    this.code = code;
  }
}

/**
 * [EN] The parser (class methods of the iOS CYLTabBarConfigurationParser). [CN] 解析器（iOS 类方法）。
 */
export class CYLTabBarConfigurationParser {
  /** [EN] +formatForPathExtension:. [CN] 由扩展名得到格式。 */
  static formatForPathExtension(pathExtension: string): CYLTabBarConfigurationFormat {
    switch (pathExtension.toLowerCase()) {
      case 'json':
        return CYLTabBarConfigurationFormat.JSON;
      case 'json5':
      case 'jsonc':
        return CYLTabBarConfigurationFormat.JSON5;
      case 'plist':
      case 'strings':
        return CYLTabBarConfigurationFormat.PropertyList;
      case 'yaml':
      case 'yml':
        return CYLTabBarConfigurationFormat.YAML;
      case 'toml':
        return CYLTabBarConfigurationFormat.TOML;
      case 'ini':
      case 'cfg':
      case 'conf':
        return CYLTabBarConfigurationFormat.INI;
      case 'properties':
      case 'env':
        return CYLTabBarConfigurationFormat.Properties;
      case 'xml':
        return CYLTabBarConfigurationFormat.XML;
      case 'textproto':
      case 'txtpb':
      case 'pbtxt':
      case 'prototxt':
        return CYLTabBarConfigurationFormat.ProtobufText;
      case 'binpb':
      case 'pb':
      case 'protobuf':
        return CYLTabBarConfigurationFormat.Protobuf;
      default:
        return CYLTabBarConfigurationFormat.Unknown;
    }
  }

  /** [EN] +formatForMIMEType:. [CN] 由 MIME 类型得到格式。 */
  static formatForMIMEType(mimeType: string): CYLTabBarConfigurationFormat {
    const type = mimeType.split(';')[0].trim().toLowerCase();
    if (type.endsWith('/json') || type.endsWith('+json')) {
      return CYLTabBarConfigurationFormat.JSON;
    }
    if (type.endsWith('json5')) {
      return CYLTabBarConfigurationFormat.JSON5;
    }
    if (type.endsWith('yaml')) {
      return CYLTabBarConfigurationFormat.YAML;
    }
    if (type.endsWith('toml')) {
      return CYLTabBarConfigurationFormat.TOML;
    }
    if (type.endsWith('/xml') || type.endsWith('+xml')) {
      return CYLTabBarConfigurationFormat.XML;
    }
    return CYLTabBarConfigurationFormat.Unknown;
  }

  /**
   * [EN] +configurationWithString:format:error:: a dictionary, or throws CYLTabBarConfigurationError. Unknown format:
   *      detected from the text ("{" JSON, then JSON5).
   * [CN] 解析为字典，失败时抛出 CYLTabBarConfigurationError。格式未知时按内容检测。
   */
  static configurationWithString(text: string, format: CYLTabBarConfigurationFormat): Record<string, Object> {
    if (text.length > CYLTabBarConfigurationMaximumLength) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.TooLarge, 'The configuration is larger than 5 MB.');
    }
    const body = text.replace(/^﻿/, '');
    if (body.trim().length === 0) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.Empty, 'The configuration is empty.');
    }
    let kind = format;
    if (kind === CYLTabBarConfigurationFormat.Unknown) {
      const head = body.trimStart();
      kind = head.startsWith('{') || head.startsWith('[') || head.startsWith('//') || head.startsWith('/*')
        ? CYLTabBarConfigurationFormat.JSON5 : CYLTabBarConfigurationFormat.Unknown;
    }
    if (kind !== CYLTabBarConfigurationFormat.JSON && kind !== CYLTabBarConfigurationFormat.JSON5) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.UnsupportedFormat,
        `The format ${kind} is not supported on HarmonyOS yet.`);
    }
    if (CYLTabBarConfigurationParser.bracketDepth(body) > CYLTabBarConfigurationMaximumDepth) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.TooDeep, 'The configuration nests deeper than 64 levels.');
    }
    const json = kind === CYLTabBarConfigurationFormat.JSON ? body : CYLTabBarConfigurationParser.json5ToJSON(body);
    if (json === null) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.InvalidSyntax, 'JSON5: an unterminated string or comment.');
    }
    let root: Object | null = null;
    try {
      root = JSON.parse(json) as Object | null;
    } catch (error) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.InvalidSyntax, `JSON: ${(error as Error).message}`);
    }
    if (root === null || typeof root !== 'object' || Array.isArray(root)) {
      throw new CYLTabBarConfigurationError(CYLTabBarConfigurationErrorCode.NotADictionary, 'The configuration is not a dictionary.');
    }
    return root as Record<string, Object>;
  }

  /** [EN] The deepest bracket nesting outside strings. [CN] 字符串外的最大括号嵌套。 */
  static bracketDepth(text: string): number {
    let depth = 0;
    let deepest = 0;
    let quote = '';
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (quote.length > 0) {
        if (c === '\\') {
          i++;
        } else if (c === quote) {
          quote = '';
        }
      } else if (c === '"' || c === '\'') {
        quote = c;
      } else if (c === '{' || c === '[') {
        depth++;
        deepest = Math.max(deepest, depth);
      } else if (c === '}' || c === ']') {
        depth--;
      }
    }
    return deepest;
  }

  /**
   * [EN] JSON5 / JSONC to JSON (CYLJSON5 of the Kotlin sources): comments and trailing commas removed, single quotes and
   *      unquoted keys turned into JSON; null for an unterminated string or comment.
   * [CN] JSON5 / JSONC 转 JSON：去掉注释与尾逗号，单引号与无引号键转为 JSON；字符串或注释未结束时为 null。
   */
  static json5ToJSON(text: string): string | null {
    let output = '';
    let i = 0;
    const isStart = (c: string): boolean => /[A-Za-z_$]/.test(c);
    const isPart = (c: string): boolean => /[A-Za-z0-9_$]/.test(c);
    while (i < text.length) {
      const c = text[i];
      if (c === '"' || c === '\'') {
        let j = i + 1;
        let content = '';
        while (j < text.length && text[j] !== c) {
          if (text[j] === '\\' && j + 1 < text.length) {
            content += text[j] + text[j + 1];
            j += 2;
          } else {
            content += text[j];
            j++;
          }
        }
        if (j >= text.length) {
          return null;
        }
        output += c === '"' ? `"${content}"` : `"${content.replace(/\\'/g, '\'').replace(/"/g, '\\"')}"`;
        i = j + 1;
      } else if (text.startsWith('//', i)) {
        while (i < text.length && text[i] !== '\n') {
          i++;
        }
      } else if (text.startsWith('/*', i)) {
        const end = text.indexOf('*/', i + 2);
        if (end < 0) {
          return null;
        }
        i = end + 2;
      } else if (c === '}' || c === ']') {
        output = output.replace(/,\s*$/, '');
        output += c;
        i++;
      } else if (isStart(c)) {
        let j = i;
        while (j < text.length && isPart(text[j])) {
          j++;
        }
        const word = text.substring(i, j);
        let next = j;
        while (next < text.length && /\s/.test(text[next])) {
          next++;
        }
        output += next < text.length && text[next] === ':' ? `"${word}"` : word;
        i = j;
      } else {
        output += c;
        i++;
      }
    }
    return output;
  }
}
