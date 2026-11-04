//
//  CYLTabBarConfigurationParser.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarConfigurationParser.h"

NSString *const CYLTabBarConfigurationErrorDomain = @"CYLTabBarConfigurationErrorDomain";
const NSUInteger CYLTabBarConfigurationMaximumLength = 5 * 1024 * 1024;
const NSUInteger CYLTabBarConfigurationMaximumDepth = 64;

// [EN] Pure Foundation, and no blocks, so that the parsers can also be built and tested outside Apple platforms.
// [CN] 仅使用 Foundation 且不使用 block，以便在非 Apple 平台上也能编译与测试这些解析器。

#pragma mark - Helpers

static NSError *CYLConfigurationError(CYLTabBarConfigurationErrorCode code, NSString *description) {
    return [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey : description }];
}

static NSError *CYLConfigurationSyntaxError(NSString *formatName, NSUInteger line, NSString *reason) {
    NSString *description = line > 0
        ? [NSString stringWithFormat:@"%@ configuration, line %lu: %@", formatName, (unsigned long)line, reason]
        : [NSString stringWithFormat:@"%@ configuration: %@", formatName, reason];
    return CYLConfigurationError(CYLTabBarConfigurationErrorInvalidSyntax, description);
}

static NSError *CYLConfigurationTooDeepError(NSString *formatName) {
    return CYLConfigurationError(CYLTabBarConfigurationErrorTooDeep,
                                 [NSString stringWithFormat:@"%@ configuration: nested deeper than %lu levels.", formatName, (unsigned long)CYLTabBarConfigurationMaximumDepth]);
}

/*!
 * [EN] The deepest nesting of { [ ( outside quoted strings: checked before Apple's recursive parsers (JSON, property
 *      lists) run, so a hostile file cannot overflow the stack.
 * [CN] 引号字符串之外 { [ ( 的最大嵌套层数：在 Apple 的递归解析器（JSON、属性列表）运行前检查，避免恶意文件导致栈溢出。
 */
static NSUInteger CYLBracketDepth(NSString *text) {
    NSUInteger depth = 0, deepest = 0;
    unichar quote = 0;
    NSUInteger length = text.length;
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [text characterAtIndex:i];
        if (quote) {
            if (c == '\\') {
                i++;
            } else if (c == quote) {
                quote = 0;
            }
        } else if (c == '"' || c == '\'') {
            quote = c;
        } else if (c == '{' || c == '[' || c == '(') {
            deepest = MAX(deepest, ++depth);
        } else if ((c == '}' || c == ']' || c == ')') && depth > 0) {
            depth--;
        }
    }
    return deepest;
}

/// [EN] The deepest nesting of <dict> / <array> in an XML property list. [CN] XML 属性列表中 <dict> / <array> 的最大嵌套层数。
static NSUInteger CYLXMLPropertyListDepth(NSString *text) {
    NSUInteger depth = 0, deepest = 0;
    NSUInteger length = text.length;
    NSRange search = NSMakeRange(0, length);
    while (search.length > 0) {
        NSRange open = [text rangeOfString:@"<" options:0 range:search];
        if (open.location == NSNotFound) {
            break;
        }
        NSRange close = [text rangeOfString:@">" options:0 range:NSMakeRange(open.location, length - open.location)];
        if (close.location == NSNotFound) {
            break;
        }
        NSString *tag = [text substringWithRange:NSMakeRange(open.location + 1, close.location - open.location - 1)];
        BOOL selfClosing = [tag hasSuffix:@"/"];
        if (!selfClosing && ([tag hasPrefix:@"dict"] || [tag hasPrefix:@"array"])) {
            deepest = MAX(deepest, ++depth);
        } else if (([tag hasPrefix:@"/dict"] || [tag hasPrefix:@"/array"]) && depth > 0) {
            depth--;
        }
        search = NSMakeRange(NSMaxRange(close), length - NSMaxRange(close));
    }
    return deepest;
}

/// [EN] A big-endian unsigned integer of `size` bytes. [CN] `size` 字节的大端无符号整数。
static uint64_t CYLReadBigEndian(const uint8_t *bytes, NSUInteger size) {
    uint64_t value = 0;
    for (NSUInteger i = 0; i < size; i++) {
        value = (value << 8) | bytes[i];
    }
    return value;
}

/*!
 * [EN] Checks the structure of a binary property list without recursion: every offset and reference in bounds, no
 *      container nested deeper than the limit, and a bounded number of visits (which also stops reference cycles).
 *      Returns NO with `*tooDeep` set when it is nested too deeply.
 * [CN] 以非递归方式检查二进制属性列表的结构：所有偏移与引用都在范围内、容器嵌套不超过上限、访问次数有限（也可阻止循环引用）。嵌套过深时返回 NO 并设置 `*tooDeep`。
 */
static BOOL CYLBinaryPropertyListIsSafe(NSData *data, BOOL *tooDeep) {
    const uint8_t *bytes = data.bytes;
    NSUInteger length = data.length;
    *tooDeep = NO;
    if (length < 8 + 32) {
        return NO;
    }
    const uint8_t *trailer = bytes + length - 32;
    NSUInteger offsetSize = trailer[6];
    NSUInteger referenceSize = trailer[7];
    uint64_t objectCount = CYLReadBigEndian(trailer + 8, 8);
    uint64_t topObject = CYLReadBigEndian(trailer + 16, 8);
    uint64_t tableOffset = CYLReadBigEndian(trailer + 24, 8);
    if (offsetSize < 1 || offsetSize > 8 || referenceSize < 1 || referenceSize > 8 || objectCount == 0 ||
        topObject >= objectCount || tableOffset >= length || objectCount > (length - tableOffset) / offsetSize) {
        return NO;
    }
    NSMutableArray<NSNumber *> *stack = [NSMutableArray arrayWithObject:@(topObject)];
    NSMutableArray<NSNumber *> *depths = [NSMutableArray arrayWithObject:@1];
    NSUInteger visits = 0;
    while (stack.count > 0) {
        uint64_t object = stack.lastObject.unsignedLongLongValue;
        NSUInteger depth = depths.lastObject.unsignedIntegerValue;
        [stack removeLastObject];
        [depths removeLastObject];
        if (++visits > 100000 || object >= objectCount) {
            return NO;
        }
        uint64_t offset = CYLReadBigEndian(bytes + tableOffset + object * offsetSize, offsetSize);
        if (offset >= tableOffset) {
            return NO;
        }
        uint8_t marker = bytes[offset];
        uint8_t type = marker >> 4;
        if (type != 0xA && type != 0xC && type != 0xD) {
            continue; // Not a container. 不是容器。
        }
        if (depth > CYLTabBarConfigurationMaximumDepth) {
            *tooDeep = YES;
            return NO;
        }
        uint64_t count = marker & 0x0F;
        uint64_t position = offset + 1;
        if (count == 0x0F) {
            // The count follows as an int object: 0x1N, 2^N bytes. 数量以整数对象形式紧随其后：0x1N，2^N 字节。
            if (position >= tableOffset || (bytes[position] >> 4) != 0x1 || (bytes[position] & 0x0F) > 3) {
                return NO;
            }
            NSUInteger size = (NSUInteger)1 << (bytes[position] & 0x0F);
            if (position + 1 + size > tableOffset) {
                return NO;
            }
            count = CYLReadBigEndian(bytes + position + 1, size);
            position += 1 + size;
        }
        uint64_t references = (type == 0xD) ? count * 2 : count;
        // References must fit, and the pending work stays bounded (a container listed again and again).
        // 引用必须在范围内，且待处理的工作量有上限（同一容器被反复引用时）。
        if (count > objectCount || references > (tableOffset - position) / referenceSize || stack.count + references > 200000) {
            return NO;
        }
        for (uint64_t i = 0; i < references; i++) {
            [stack addObject:@(CYLReadBigEndian(bytes + position + i * referenceSize, referenceSize))];
            [depths addObject:@(depth + 1)];
        }
    }
    return YES;
}

static BOOL CYLIsInlineSpace(unichar c) {
    return c == ' ' || c == '\t';
}

static BOOL CYLIsSpaceOrNewline(unichar c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

static NSString *CYLTrimmed(NSString *string) {
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/*!
 * [EN] UTF-16 and UTF-32 text with a BOM (as some Windows editors save it) re-encoded as UTF-8, so every parser and the
 *      format detection read it; anything else is returned as it is (A16).
 * [CN] 带 BOM 的 UTF-16 与 UTF-32 文本（部分 Windows 编辑器这样保存）重新编码为 UTF-8，使所有解析器与格式识别都能读取；其他数据原样返回（A16）。
 */
static NSData *CYLUTF8DataFromData(NSData *data) {
    const uint8_t *bytes = data.bytes;
    NSUInteger length = data.length;
    NSStringEncoding encoding = 0;
    NSUInteger bom = 0;
    if (length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00) {
        encoding = NSUTF32LittleEndianStringEncoding;
        bom = 4;
    } else if (length >= 4 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF) {
        encoding = NSUTF32BigEndianStringEncoding;
        bom = 4;
    } else if (length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
        encoding = NSUTF16LittleEndianStringEncoding;
        bom = 2;
    } else if (length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
        encoding = NSUTF16BigEndianStringEncoding;
        bom = 2;
    }
    if (!encoding) {
        return data;
    }
    NSString *string = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(bom, length - bom)] encoding:encoding];
    return [string dataUsingEncoding:NSUTF8StringEncoding] ?: data;
}

static NSString *_Nullable CYLStringFromData(NSData *data) {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0 && [string characterAtIndex:0] == 0xFEFF) {
        string = [string substringFromIndex:1];
    }
    return string;
}

/// [EN] Splits text into lines (\n, \r\n or \r). [CN] 将文本拆分为行（\n、\r\n 或 \r）。
static NSArray<NSString *> *CYLLines(NSString *text) {
    NSString *normalized = [[text stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"]
                            stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    return [normalized componentsSeparatedByString:@"\n"];
}

/*!
 * [EN] A decimal or hexadecimal integer, or a float, or nil. `allowsUnderscores`: TOML's `_` digit separators (only
 *      there: elsewhere a name like `1_2` must stay a string).
 * [CN] 十进制或十六进制整数、浮点数，否则返回 nil。`allowsUnderscores`：TOML 的 `_` 数字分隔符（仅限 TOML：其他格式中
 *      `1_2` 这样的名称必须保持字符串）。
 */
static NSNumber *_Nullable CYLNumberFromString(NSString *string, BOOL allowsUnderscores) {
    NSString *text = allowsUnderscores ? [string stringByReplacingOccurrencesOfString:@"_" withString:@""] : string;
    if (text.length == 0) {
        return nil;
    }
    NSUInteger length = text.length;
    NSUInteger index = 0;
    unichar first = [text characterAtIndex:0];
    if (first == '+' || first == '-') {
        index = 1;
    }
    if (index >= length) {
        return nil;
    }
    if (length > index + 2 && [text characterAtIndex:index] == '0' &&
        ([text characterAtIndex:index + 1] == 'x' || [text characterAtIndex:index + 1] == 'X')) {
        unsigned long long value = 0;
        NSScanner *scanner = [NSScanner scannerWithString:[text substringFromIndex:index]];
        if ([scanner scanHexLongLong:&value] && scanner.isAtEnd) {
            long long signedValue = (long long)value;
            return @(first == '-' ? -signedValue : signedValue);
        }
        return nil;
    }
    BOOL sawDigit = NO;
    BOOL sawDot = NO;
    BOOL sawExponent = NO;
    for (NSUInteger i = index; i < length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            sawDigit = YES;
        } else if (c == '.' && !sawDot && !sawExponent) {
            sawDot = YES;
        } else if ((c == 'e' || c == 'E') && sawDigit && !sawExponent && i + 1 < length) {
            sawExponent = YES;
            unichar next = [text characterAtIndex:i + 1];
            if (next == '+' || next == '-') {
                i++;
            }
        } else {
            return nil;
        }
    }
    if (!sawDigit) {
        return nil;
    }
    if (sawDot || sawExponent) {
        return @([text doubleValue]);
    }
    return @([text longLongValue]);
}

/*!
 * [EN] An unquoted scalar of a text format: true / false as booleans, null / ~ as NSNull (YAML), numbers as NSNumber,
 *      anything else as the string itself.
 * [CN] 文本格式中未加引号的标量：true / false 为布尔值，null / ~ 为 NSNull（YAML），数字为 NSNumber，其余保持字符串。
 */
static id CYLTypedScalar(NSString *raw, BOOL allowsNull) {
    NSString *text = CYLTrimmed(raw);
    NSString *lowercase = text.lowercaseString;
    if ([lowercase isEqualToString:@"true"]) {
        return @(YES);
    }
    if ([lowercase isEqualToString:@"false"]) {
        return @(NO);
    }
    if (allowsNull && ([lowercase isEqualToString:@"null"] || [text isEqualToString:@"~"] || text.length == 0)) {
        return [NSNull null];
    }
    NSNumber *number = CYLNumberFromString(text, NO);
    return number ?: text;
}

/// [EN] Appends the character of a `\uXXXX` / `\UXXXXXXXX` escape. [CN] 追加 `\uXXXX` / `\UXXXXXXXX` 转义对应的字符。
static BOOL CYLAppendUnicodeEscape(NSMutableString *output, NSString *hex) {
    unsigned int value = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    if (![scanner scanHexInt:&value] || !scanner.isAtEnd) {
        return NO;
    }
    if (value > 0xFFFF) {
        value -= 0x10000;
        unichar pair[2] = { (unichar)(0xD800 + (value >> 10)), (unichar)(0xDC00 + (value & 0x3FF)) };
        [output appendString:[NSString stringWithCharacters:pair length:2]];
    } else {
        unichar character = (unichar)value;
        [output appendString:[NSString stringWithCharacters:&character length:1]];
    }
    return YES;
}

/*!
 * [EN] Reads a double-quoted string starting at `*index` (on the quote), with JSON / TOML / YAML escapes; `*index` ends
 *      after the closing quote. nil when it is not closed.
 * [CN] 读取从 `*index`（指向引号）开始的双引号字符串，支持 JSON / TOML / YAML 转义；结束时 `*index` 位于右引号之后。未闭合时返回 nil。
 */
static NSString *_Nullable CYLReadDoubleQuoted(NSString *text, NSUInteger *index) {
    NSMutableString *output = [NSMutableString string];
    NSUInteger i = *index + 1;
    NSUInteger length = text.length;
    while (i < length) {
        unichar c = [text characterAtIndex:i];
        if (c == '"') {
            *index = i + 1;
            return output;
        }
        if (c == '\\' && i + 1 < length) {
            unichar e = [text characterAtIndex:i + 1];
            i += 2;
            switch (e) {
                case 'n': [output appendString:@"\n"]; break;
                case 't': [output appendString:@"\t"]; break;
                case 'r': [output appendString:@"\r"]; break;
                case 'b': [output appendString:@"\b"]; break;
                case 'f': [output appendString:@"\f"]; break;
                case '0': [output appendString:@"\0"]; break;
                case 'u':
                case 'U': {
                    NSUInteger count = (e == 'u') ? 4 : 8;
                    if (i + count > length || !CYLAppendUnicodeEscape(output, [text substringWithRange:NSMakeRange(i, count)])) {
                        return nil;
                    }
                    i += count;
                    break;
                }
                default: {
                    unichar character = e;
                    [output appendString:[NSString stringWithCharacters:&character length:1]];
                    break;
                }
            }
            continue;
        }
        [output appendString:[NSString stringWithCharacters:&c length:1]];
        i++;
    }
    return nil;
}

/*!
 * [EN] Reads a single-quoted string starting at `*index`. `doubledQuoteEscapes`: YAML's '' for one quote; otherwise no
 *      escapes at all (TOML literal strings).
 * [CN] 读取从 `*index` 开始的单引号字符串。`doubledQuoteEscapes` 为 YES 时 '' 表示一个单引号（YAML）；否则没有转义（TOML 字面量字符串）。
 */
static NSString *_Nullable CYLReadSingleQuoted(NSString *text, NSUInteger *index, BOOL doubledQuoteEscapes) {
    NSMutableString *output = [NSMutableString string];
    NSUInteger i = *index + 1;
    NSUInteger length = text.length;
    while (i < length) {
        unichar c = [text characterAtIndex:i];
        if (c == '\'') {
            if (doubledQuoteEscapes && i + 1 < length && [text characterAtIndex:i + 1] == '\'') {
                [output appendString:@"'"];
                i += 2;
                continue;
            }
            *index = i + 1;
            return output;
        }
        [output appendString:[NSString stringWithCharacters:&c length:1]];
        i++;
    }
    return nil;
}

/// [EN] A value without its surrounding quotes, if it has a matching pair. [CN] 去掉成对的外层引号后的值。
static id CYLUnquotedOrTypedValue(NSString *raw) {
    NSString *text = CYLTrimmed(raw);
    if (text.length >= 2) {
        unichar first = [text characterAtIndex:0];
        unichar last = [text characterAtIndex:text.length - 1];
        if (first == '"' && last == '"') {
            NSUInteger index = 0;
            NSString *string = CYLReadDoubleQuoted(text, &index);
            if (string && index == text.length) {
                return string;
            }
        }
        if (first == '\'' && last == '\'') {
            return [text substringWithRange:NSMakeRange(1, text.length - 2)];
        }
    }
    return CYLTypedScalar(text, NO);
}

#pragma mark - Dotted paths (INI, .properties, TOML)

/// [EN] The mutable dictionary at `key` of `dictionary`, created when missing. [CN] `dictionary` 中 `key` 对应的可变字典，不存在时创建。
static NSMutableDictionary *_Nullable CYLChildDictionary(NSMutableDictionary *dictionary, NSString *key) {
    id child = dictionary[key];
    if (!child) {
        child = [NSMutableDictionary dictionary];
        dictionary[key] = child;
        return child;
    }
    if ([child isKindOfClass:[NSMutableArray class]]) {
        // TOML: `[a.b]` after `[[a]]` is a table of the last element. TOML：`[[a]]` 之后的 `[a.b]` 属于最后一个元素。
        id last = [(NSMutableArray *)child lastObject];
        return [last isKindOfClass:[NSMutableDictionary class]] ? last : nil;
    }
    return [child isKindOfClass:[NSMutableDictionary class]] ? child : nil;
}

/// [EN] Sets `value` at `path` under `root`, creating the dictionaries in between. NO when a non-table is in the way.
/// [CN] 在 `root` 下的 `path` 处设置 `value`，并创建中间的字典。路径中遇到非字典值时返回 NO。
static BOOL CYLSetValueAtPath(NSMutableDictionary *root, NSArray<NSString *> *path, id value) {
    if (path.count == 0) {
        return NO;
    }
    NSMutableDictionary *dictionary = root;
    for (NSUInteger i = 0; i + 1 < path.count; i++) {
        dictionary = CYLChildDictionary(dictionary, path[i]);
        if (!dictionary) {
            return NO;
        }
    }
    dictionary[path.lastObject] = value;
    return YES;
}

/// [EN] Splits `a.b."c.d"` into its parts (quoted parts may contain dots). [CN] 将 `a.b."c.d"` 拆分为各部分（带引号的部分可包含点）。
static NSArray<NSString *> *_Nullable CYLSplitDottedKey(NSString *key) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSUInteger i = 0;
    NSUInteger length = key.length;
    while (i <= length) {
        while (i < length && CYLIsInlineSpace([key characterAtIndex:i])) {
            i++;
        }
        if (i >= length) {
            return nil;
        }
        unichar c = [key characterAtIndex:i];
        NSString *part = nil;
        if (c == '"') {
            part = CYLReadDoubleQuoted(key, &i);
        } else if (c == '\'') {
            part = CYLReadSingleQuoted(key, &i, NO);
        } else {
            NSUInteger start = i;
            while (i < length && [key characterAtIndex:i] != '.') {
                i++;
            }
            part = CYLTrimmed([key substringWithRange:NSMakeRange(start, i - start)]);
        }
        if (part.length == 0) {
            return nil;
        }
        [parts addObject:part];
        if (parts.count > CYLTabBarConfigurationMaximumDepth) {
            return nil; // A path this long would build a too deeply nested tree. 路径过长会生成嵌套过深的树。
        }
        while (i < length && CYLIsInlineSpace([key characterAtIndex:i])) {
            i++;
        }
        if (i >= length) {
            break;
        }
        if ([key characterAtIndex:i] != '.') {
            return nil;
        }
        i++;
    }
    return parts;
}

/*!
 * [EN] Flat formats (INI, .properties) write list elements as numeric path parts (`items.0.title`): every dictionary
 *      whose keys are all non-negative integers becomes an array, in the order of the numbers.
 * [CN] 扁平格式（INI、.properties）用数字路径表示数组元素（`items.0.title`）：键全部为非负整数的字典转换为数组，按数字排序。
 */
static id CYLArraysFromNumericKeys(id value) {
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        NSMutableDictionary *converted = [NSMutableDictionary dictionary];
        BOOL allNumeric = dictionary.count > 0;
        for (NSString *key in dictionary) {
            converted[key] = CYLArraysFromNumericKeys(dictionary[key]);
            NSScanner *scanner = [NSScanner scannerWithString:key];
            NSInteger number = 0;
            if (![scanner scanInteger:&number] || !scanner.isAtEnd || number < 0) {
                allNumeric = NO;
            }
        }
        if (!allNumeric) {
            return converted;
        }
        NSArray *keys = [converted.allKeys sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray *sortedKeys = [NSMutableArray arrayWithArray:keys];
        // Numeric order, not string order ("10" after "9"). 按数值而非字符串排序（"10" 在 "9" 之后）。
        for (NSUInteger i = 0; i < sortedKeys.count; i++) {
            for (NSUInteger j = i + 1; j < sortedKeys.count; j++) {
                if ([sortedKeys[j] integerValue] < [sortedKeys[i] integerValue]) {
                    [sortedKeys exchangeObjectAtIndex:i withObjectAtIndex:j];
                }
            }
        }
        NSMutableArray *array = [NSMutableArray array];
        for (NSString *key in sortedKeys) {
            [array addObject:converted[key]];
        }
        return array;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (id element in (NSArray *)value) {
            [array addObject:CYLArraysFromNumericKeys(element)];
        }
        return array;
    }
    return value;
}

#pragma mark - JSON5 / JSONC

/*!
 * [EN] JSON5 / JSONC to JSON: removes line comments (//) and block comments, and trailing commas; turns single-quoted
 *      strings into double-quoted ones, and quotes unquoted keys.
 * [CN] 将 JSON5 / JSONC 转为 JSON：移除行注释（//）、块注释及尾逗号；单引号字符串改为双引号，为未加引号的键加上引号。
 */
static NSString *_Nullable CYLJSONFromJSON5(NSString *text) {
    NSMutableString *output = [NSMutableString stringWithCapacity:text.length];
    NSUInteger length = text.length;
    NSUInteger i = 0;
    while (i < length) {
        unichar c = [text characterAtIndex:i];
        if (c == '"') {
            NSUInteger start = i;
            NSString *string = CYLReadDoubleQuoted(text, &i);
            if (!string) {
                return nil;
            }
            [output appendString:[text substringWithRange:NSMakeRange(start, i - start)]];
            continue;
        }
        if (c == '\'') {
            NSString *string = CYLReadSingleQuoted(text, &i, NO);
            if (!string) {
                return nil;
            }
            NSString *escaped = [[string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
                                 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            [output appendFormat:@"\"%@\"", escaped];
            continue;
        }
        if (c == '/' && i + 1 < length && [text characterAtIndex:i + 1] == '/') {
            while (i < length && [text characterAtIndex:i] != '\n') {
                i++;
            }
            continue;
        }
        if (c == '/' && i + 1 < length && [text characterAtIndex:i + 1] == '*') {
            NSRange end = [text rangeOfString:@"*/" options:0 range:NSMakeRange(i + 2, length - i - 2)];
            if (end.location == NSNotFound) {
                return nil;
            }
            i = NSMaxRange(end);
            continue;
        }
        if (c == '}' || c == ']') {
            NSInteger back = (NSInteger)output.length - 1;
            while (back >= 0 && CYLIsSpaceOrNewline([output characterAtIndex:(NSUInteger)back])) {
                back--;
            }
            if (back >= 0 && [output characterAtIndex:(NSUInteger)back] == ',') {
                [output deleteCharactersInRange:NSMakeRange((NSUInteger)back, 1)];
            }
            [output appendString:[NSString stringWithCharacters:&c length:1]];
            i++;
            continue;
        }
        BOOL startsIdentifier = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_' || c == '$';
        if (startsIdentifier) {
            NSUInteger start = i;
            while (i < length) {
                unichar d = [text characterAtIndex:i];
                BOOL partOfIdentifier = (d >= 'A' && d <= 'Z') || (d >= 'a' && d <= 'z') || (d >= '0' && d <= '9') || d == '_' || d == '$';
                if (!partOfIdentifier) {
                    break;
                }
                i++;
            }
            NSString *identifier = [text substringWithRange:NSMakeRange(start, i - start)];
            NSUInteger next = i;
            while (next < length && CYLIsSpaceOrNewline([text characterAtIndex:next])) {
                next++;
            }
            if (next < length && [text characterAtIndex:next] == ':') {
                [output appendFormat:@"\"%@\"", identifier];
            } else {
                [output appendString:identifier];
            }
            continue;
        }
        [output appendString:[NSString stringWithCharacters:&c length:1]];
        i++;
    }
    return output;
}

#pragma mark - YAML

/// [EN] One meaningful YAML line: its indentation and its text without the comment. [CN] 一行有效的 YAML：缩进与去掉注释后的文本。
@interface CYLYAMLLine : NSObject
@property (nonatomic, assign) NSUInteger indent;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) NSUInteger number;
@end

@implementation CYLYAMLLine
@end

@interface CYLYAMLParser : NSObject
@property (nonatomic, strong) NSArray<NSString *> *rawLines;
@property (nonatomic, strong) NSMutableArray<CYLYAMLLine *> *lines;
@property (nonatomic, assign) NSUInteger position;
@property (nonatomic, assign) NSUInteger depth;
@property (nonatomic, strong, nullable) NSError *error;
@end

@implementation CYLYAMLParser

/// [EN] The text before a ` #` comment, outside quotes. [CN] 引号之外 ` #` 注释之前的文本。
static NSString *CYLYAMLStripComment(NSString *text) {
    BOOL inSingle = NO;
    BOOL inDouble = NO;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c == '\\' && inDouble) {
            i++;
            continue;
        }
        if (c == '"' && !inSingle) {
            inDouble = !inDouble;
        } else if (c == '\'' && !inDouble) {
            inSingle = !inSingle;
        } else if (c == '#' && !inSingle && !inDouble && (i == 0 || CYLIsInlineSpace([text characterAtIndex:i - 1]))) {
            return [text substringToIndex:i];
        }
    }
    return text;
}

- (instancetype)initWithText:(NSString *)text {
    if (self = [super init]) {
        _rawLines = CYLLines(text);
        _lines = [NSMutableArray array];
        NSUInteger number = 0;
        for (NSString *raw in _rawLines) {
            number++;
            NSString *withoutComment = CYLYAMLStripComment(raw);
            NSString *trimmed = CYLTrimmed(withoutComment);
            if (trimmed.length == 0 || [trimmed hasPrefix:@"%"] || [trimmed isEqualToString:@"---"] || [trimmed isEqualToString:@"..."]) {
                continue;
            }
            NSUInteger indent = 0;
            while (indent < withoutComment.length && CYLIsInlineSpace([withoutComment characterAtIndex:indent])) {
                indent++;
            }
            CYLYAMLLine *line = [[CYLYAMLLine alloc] init];
            line.indent = indent;
            line.text = CYLTrimmed([withoutComment substringFromIndex:indent]);
            line.number = number;
            [_lines addObject:line];
        }
    }
    return self;
}

- (void)failAtLine:(NSUInteger)line reason:(NSString *)reason {
    if (!self.error) {
        self.error = CYLConfigurationSyntaxError(@"YAML", line, reason);
    }
}

- (nullable CYLYAMLLine *)currentLine {
    return self.position < self.lines.count ? self.lines[self.position] : nil;
}

static BOOL CYLYAMLIsSequenceEntry(NSString *text) {
    return [text isEqualToString:@"-"] || [text hasPrefix:@"- "];
}

/// [EN] The location of the `:` that ends a mapping key, outside quotes and brackets, or NSNotFound.
/// [CN] 结束映射键的 `:` 的位置（在引号与括号之外），没有时为 NSNotFound。
static NSUInteger CYLYAMLKeyColonLocation(NSString *text) {
    BOOL inSingle = NO;
    BOOL inDouble = NO;
    NSInteger depth = 0;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c == '\\' && inDouble) {
            i++;
            continue;
        }
        if (c == '"' && !inSingle) {
            inDouble = !inDouble;
        } else if (c == '\'' && !inDouble) {
            inSingle = !inSingle;
        } else if (!inSingle && !inDouble) {
            if (c == '[' || c == '{') {
                depth++;
            } else if (c == ']' || c == '}') {
                depth--;
            } else if (c == ':' && depth == 0 && (i + 1 == text.length || CYLIsInlineSpace([text characterAtIndex:i + 1]))) {
                return i;
            }
        }
    }
    return NSNotFound;
}

/// [EN] Every nested block and flow collection counts one level (A10). [CN] 每个嵌套的块与流式集合计一层（A10）。
- (BOOL)enterLevel {
    if (++self.depth > CYLTabBarConfigurationMaximumDepth) {
        self.error = self.error ?: CYLConfigurationTooDeepError(@"YAML");
        return NO;
    }
    return YES;
}

- (nullable id)parseBlockAtIndent:(NSUInteger)indent {
    id value = [self enterLevel] ? [self parseBlockBodyAtIndent:indent] : nil;
    self.depth--;
    return value;
}

- (nullable id)parseBlockBodyAtIndent:(NSUInteger)indent {
    CYLYAMLLine *line = [self currentLine];
    if (!line || line.indent < indent) {
        return [NSNull null];
    }
    if (CYLYAMLIsSequenceEntry(line.text)) {
        return [self parseSequenceAtIndent:line.indent];
    }
    if (CYLYAMLKeyColonLocation(line.text) != NSNotFound) {
        return [self parseMappingAtIndent:line.indent];
    }
    // A lone scalar (or a flow collection) as the whole block. 整个块只有一个标量（或流式集合）。
    self.position++;
    return [self scalarOrFlowFromText:line.text line:line];
}

- (NSMutableArray *)parseSequenceAtIndent:(NSUInteger)indent {
    NSMutableArray *sequence = [NSMutableArray array];
    while (!self.error) {
        CYLYAMLLine *line = [self currentLine];
        if (!line || line.indent != indent || !CYLYAMLIsSequenceEntry(line.text)) {
            break;
        }
        NSString *rest = line.text.length > 1 ? CYLTrimmed([line.text substringFromIndex:2]) : @"";
        if (rest.length == 0) {
            self.position++;
            CYLYAMLLine *next = [self currentLine];
            id value = (next && next.indent > indent) ? [self parseBlockAtIndent:next.indent] : [NSNull null];
            [sequence addObject:value ?: [NSNull null]];
            continue;
        }
        if (CYLYAMLIsSequenceEntry(rest) || CYLYAMLKeyColonLocation(rest) != NSNotFound) {
            // `- key: value`: a mapping (or a nested sequence) whose first line starts after the dash.
            // `- key: value`：一个映射（或嵌套序列），其第一行从短横线之后开始。
            NSUInteger restIndent = indent + (line.text.length - rest.length);
            line.indent = restIndent;
            line.text = rest;
            [sequence addObject:[self parseBlockAtIndent:restIndent] ?: [NSNull null]];
            continue;
        }
        self.position++;
        [sequence addObject:[self scalarOrFlowFromText:rest line:line] ?: [NSNull null]];
    }
    return sequence;
}

- (NSMutableDictionary *)parseMappingAtIndent:(NSUInteger)indent {
    NSMutableDictionary *mapping = [NSMutableDictionary dictionary];
    while (!self.error) {
        CYLYAMLLine *line = [self currentLine];
        if (!line || line.indent != indent) {
            if (line && line.indent > indent) {
                [self failAtLine:line.number reason:@"unexpected indentation"];
            }
            break;
        }
        if (CYLYAMLIsSequenceEntry(line.text)) {
            break;
        }
        NSUInteger colon = CYLYAMLKeyColonLocation(line.text);
        if (colon == NSNotFound) {
            [self failAtLine:line.number reason:@"expected \"key: value\""];
            break;
        }
        NSString *key = [self keyFromText:CYLTrimmed([line.text substringToIndex:colon])];
        NSString *valueText = CYLTrimmed([line.text substringFromIndex:colon + 1]);
        self.position++;
        id value = nil;
        if (valueText.length == 0) {
            CYLYAMLLine *next = [self currentLine];
            if (next && (next.indent > indent || (next.indent == indent && CYLYAMLIsSequenceEntry(next.text)))) {
                value = [self parseBlockAtIndent:next.indent];
            } else {
                value = [NSNull null];
            }
        } else if ([valueText hasPrefix:@"|"] || [valueText hasPrefix:@">"]) {
            value = [self blockScalarFolded:[valueText hasPrefix:@">"] parentIndent:indent];
        } else {
            value = [self scalarOrFlowFromText:valueText line:line];
        }
        if (value && ![value isKindOfClass:[NSNull class]]) {
            mapping[key] = value;
        }
    }
    return mapping;
}

- (NSString *)keyFromText:(NSString *)text {
    id key = [self scalarOrFlowFromText:text line:nil];
    return [key isKindOfClass:[NSString class]] ? key : [NSString stringWithFormat:@"%@", key];
}

/// [EN] `|` (lines kept) or `>` (lines folded into one) block scalar. [CN] `|`（保留换行）或 `>`（折叠为一行）块标量。
- (NSString *)blockScalarFolded:(BOOL)folded parentIndent:(NSUInteger)parentIndent {
    // Use the raw lines, so that blank lines and '#' inside the text are kept. 使用原始行，保留文本中的空行与 '#'。
    CYLYAMLLine *first = [self currentLine];
    if (!first || first.indent <= parentIndent) {
        return @"";
    }
    NSUInteger blockIndent = first.indent;
    NSUInteger rawIndex = first.number - 1;
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    while (rawIndex < self.rawLines.count) {
        NSString *raw = self.rawLines[rawIndex];
        NSString *trimmed = CYLTrimmed(raw);
        NSUInteger rawIndent = 0;
        while (rawIndent < raw.length && CYLIsInlineSpace([raw characterAtIndex:rawIndent])) {
            rawIndent++;
        }
        if (trimmed.length > 0 && rawIndent < blockIndent) {
            break;
        }
        [parts addObject:raw.length > blockIndent ? [raw substringFromIndex:blockIndent] : @""];
        rawIndex++;
    }
    while (parts.count > 0 && [parts.lastObject length] == 0) {
        [parts removeLastObject];
    }
    while ([self currentLine] && [self currentLine].number <= rawIndex) {
        self.position++;
    }
    return [parts componentsJoinedByString:folded ? @" " : @"\n"];
}

- (nullable id)scalarOrFlowFromText:(NSString *)text line:(nullable CYLYAMLLine *)line {
    if (text.length == 0) {
        return [NSNull null];
    }
    unichar first = [text characterAtIndex:0];
    if (first == '[' || first == '{') {
        NSMutableString *flow = [text mutableCopy];
        // A flow collection may span several lines. 流式集合可以跨多行。
        while (![self flowIsBalanced:flow] && [self currentLine]) {
            [flow appendFormat:@" %@", [self currentLine].text];
            self.position++;
        }
        NSUInteger index = 0;
        id value = [self parseFlowValueInText:flow index:&index line:line.number];
        while (index < flow.length && CYLIsSpaceOrNewline([flow characterAtIndex:index])) {
            index++;
        }
        if (index != flow.length && !self.error) {
            [self failAtLine:line.number reason:@"unexpected text after a flow collection"];
        }
        return value;
    }
    if (first == '"') {
        NSUInteger index = 0;
        NSString *string = CYLReadDoubleQuoted(text, &index);
        if (!string) {
            [self failAtLine:line.number reason:@"unterminated double-quoted string"];
        }
        return string;
    }
    if (first == '\'') {
        NSUInteger index = 0;
        NSString *string = CYLReadSingleQuoted(text, &index, YES);
        if (!string) {
            [self failAtLine:line.number reason:@"unterminated single-quoted string"];
        }
        return string;
    }
    return CYLTypedScalar(text, YES);
}

- (BOOL)flowIsBalanced:(NSString *)text {
    NSInteger depth = 0;
    BOOL inSingle = NO;
    BOOL inDouble = NO;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c == '\\' && inDouble) {
            i++;
            continue;
        }
        if (c == '"' && !inSingle) {
            inDouble = !inDouble;
        } else if (c == '\'' && !inDouble) {
            inSingle = !inSingle;
        } else if (!inSingle && !inDouble) {
            if (c == '[' || c == '{') {
                depth++;
            } else if (c == ']' || c == '}') {
                depth--;
            }
        }
    }
    return depth <= 0;
}

- (nullable id)parseFlowValueInText:(NSString *)text index:(NSUInteger *)index line:(NSUInteger)line {
    id value = [self enterLevel] ? [self parseFlowValueBodyInText:text index:index line:line] : nil;
    self.depth--;
    return value;
}

- (nullable id)parseFlowValueBodyInText:(NSString *)text index:(NSUInteger *)index line:(NSUInteger)line {
    NSUInteger length = text.length;
    while (*index < length && CYLIsSpaceOrNewline([text characterAtIndex:*index])) {
        (*index)++;
    }
    if (*index >= length) {
        [self failAtLine:line reason:@"unexpected end of a flow collection"];
        return nil;
    }
    unichar c = [text characterAtIndex:*index];
    if (c == '[' || c == '{') {
        BOOL isSequence = (c == '[');
        unichar close = isSequence ? ']' : '}';
        (*index)++;
        NSMutableArray *array = [NSMutableArray array];
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        while (!self.error) {
            while (*index < length && CYLIsSpaceOrNewline([text characterAtIndex:*index])) {
                (*index)++;
            }
            if (*index >= length) {
                [self failAtLine:line reason:@"unterminated flow collection"];
                return nil;
            }
            if ([text characterAtIndex:*index] == close) {
                (*index)++;
                break;
            }
            id value = [self parseFlowValueInText:text index:index line:line];
            if (self.error) {
                return nil;
            }
            while (*index < length && CYLIsSpaceOrNewline([text characterAtIndex:*index])) {
                (*index)++;
            }
            if (!isSequence) {
                if (*index >= length || [text characterAtIndex:*index] != ':') {
                    [self failAtLine:line reason:@"expected ':' in a flow mapping"];
                    return nil;
                }
                (*index)++;
                id mapped = [self parseFlowValueInText:text index:index line:line];
                if (self.error) {
                    return nil;
                }
                NSString *key = [value isKindOfClass:[NSString class]] ? value : [NSString stringWithFormat:@"%@", value];
                if (mapped && ![mapped isKindOfClass:[NSNull class]]) {
                    dictionary[key] = mapped;
                }
                while (*index < length && CYLIsSpaceOrNewline([text characterAtIndex:*index])) {
                    (*index)++;
                }
            } else {
                [array addObject:value ?: [NSNull null]];
            }
            if (*index < length && [text characterAtIndex:*index] == ',') {
                (*index)++;
            }
        }
        return isSequence ? (id)array : (id)dictionary;
    }
    if (c == '"') {
        NSString *string = CYLReadDoubleQuoted(text, index);
        if (!string) {
            [self failAtLine:line reason:@"unterminated double-quoted string"];
        }
        return string;
    }
    if (c == '\'') {
        NSString *string = CYLReadSingleQuoted(text, index, YES);
        if (!string) {
            [self failAtLine:line reason:@"unterminated single-quoted string"];
        }
        return string;
    }
    NSUInteger start = *index;
    while (*index < length) {
        unichar d = [text characterAtIndex:*index];
        if (d == ',' || d == ']' || d == '}') {
            break;
        }
        if (d == ':' && (*index + 1 >= length || CYLIsSpaceOrNewline([text characterAtIndex:*index + 1]))) {
            break;
        }
        (*index)++;
    }
    return CYLTypedScalar([text substringWithRange:NSMakeRange(start, *index - start)], YES);
}

- (nullable id)parse {
    if (self.lines.count == 0) {
        return [NSMutableDictionary dictionary];
    }
    id value = [self parseBlockAtIndent:0];
    CYLYAMLLine *left = [self currentLine];
    if (left && !self.error) {
        [self failAtLine:left.number reason:@"unexpected indentation"];
    }
    return self.error ? nil : value;
}

@end

#pragma mark - TOML

@interface CYLTOMLParser : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSUInteger depth;
@property (nonatomic, strong, nullable) NSError *error;
@end

@implementation CYLTOMLParser

- (NSUInteger)currentLine {
    NSUInteger line = 1;
    for (NSUInteger i = 0; i < self.index && i < self.text.length; i++) {
        if ([self.text characterAtIndex:i] == '\n') {
            line++;
        }
    }
    return line;
}

- (void)fail:(NSString *)reason {
    if (!self.error) {
        self.error = CYLConfigurationSyntaxError(@"TOML", [self currentLine], reason);
    }
}

- (BOOL)atEnd {
    return self.index >= self.text.length;
}

- (unichar)peek {
    return [self atEnd] ? 0 : [self.text characterAtIndex:self.index];
}

- (BOOL)hasPrefixAtIndex:(NSString *)prefix {
    return self.index + prefix.length <= self.text.length &&
           [[self.text substringWithRange:NSMakeRange(self.index, prefix.length)] isEqualToString:prefix];
}

- (void)skipInlineSpace {
    while (![self atEnd] && CYLIsInlineSpace([self peek])) {
        self.index++;
    }
}

/// [EN] Skips spaces, newlines and comments. [CN] 跳过空白、换行与注释。
- (void)skipSpaceNewlinesAndComments {
    while (![self atEnd]) {
        unichar c = [self peek];
        if (CYLIsSpaceOrNewline(c)) {
            self.index++;
        } else if (c == '#') {
            while (![self atEnd] && [self peek] != '\n') {
                self.index++;
            }
        } else {
            break;
        }
    }
}

/// [EN] After a value or a header: only spaces and a comment until the end of the line. [CN] 值或表头之后，行尾只能有空白与注释。
- (void)expectEndOfLine {
    [self skipInlineSpace];
    if ([self peek] == '#') {
        while (![self atEnd] && [self peek] != '\n') {
            self.index++;
        }
    }
    if ([self peek] == '\r') {
        self.index++;
    }
    if (![self atEnd] && [self peek] != '\n') {
        [self fail:@"expected the end of the line"];
    }
}

- (nullable NSArray<NSString *> *)parseKeyUntil:(NSString *)terminators {
    NSUInteger start = self.index;
    BOOL inSingle = NO;
    BOOL inDouble = NO;
    while (![self atEnd]) {
        unichar c = [self peek];
        if (c == '"' && !inSingle) {
            inDouble = !inDouble;
        } else if (c == '\'' && !inDouble) {
            inSingle = !inSingle;
        } else if (!inSingle && !inDouble && [terminators rangeOfString:[NSString stringWithCharacters:&c length:1]].location != NSNotFound) {
            break;
        } else if (c == '\n') {
            break;
        }
        self.index++;
    }
    NSString *raw = [self.text substringWithRange:NSMakeRange(start, self.index - start)];
    NSArray<NSString *> *parts = CYLSplitDottedKey(raw);
    if (parts && [raw rangeOfString:@"\""].location == NSNotFound && [raw rangeOfString:@"'"].location == NSNotFound) {
        // Bare keys only (A17): `[1, 2]` is not a table. 仅裸键（A17）：`[1, 2]` 不是表。
        NSCharacterSet *bare = [[NSCharacterSet characterSetWithCharactersInString:
                                 @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] invertedSet];
        for (NSString *part in parts) {
            if ([part rangeOfCharacterFromSet:bare].location != NSNotFound) {
                parts = nil;
                break;
            }
        }
    }
    if (!parts) {
        [self fail:@"invalid key"];
    }
    return parts;
}

- (nullable id)parseValue {
    if (++self.depth > CYLTabBarConfigurationMaximumDepth) {
        self.error = self.error ?: CYLConfigurationTooDeepError(@"TOML");
        self.depth--;
        return nil;
    }
    id value = [self parseValueBody];
    self.depth--;
    return value;
}

- (nullable id)parseValueBody {
    [self skipInlineSpace];
    unichar c = [self peek];
    if ([self hasPrefixAtIndex:@"\"\"\""] || [self hasPrefixAtIndex:@"'''"]) {
        BOOL literal = (c == '\'');
        NSString *delimiter = literal ? @"'''" : @"\"\"\"";
        self.index += 3;
        // A newline right after the opening delimiter is trimmed. 紧随开始分隔符的换行会被去掉。
        if ([self peek] == '\n') {
            self.index++;
        } else if ([self hasPrefixAtIndex:@"\r\n"]) {
            self.index += 2;
        }
        NSRange end = [self.text rangeOfString:delimiter options:0 range:NSMakeRange(self.index, self.text.length - self.index)];
        if (end.location == NSNotFound) {
            [self fail:@"unterminated multi-line string"];
            return nil;
        }
        NSString *body = [self.text substringWithRange:NSMakeRange(self.index, end.location - self.index)];
        self.index = NSMaxRange(end);
        if (literal) {
            return body;
        }
        NSString *quoted = [NSString stringWithFormat:@"\"%@\"", [body stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
        NSUInteger index = 0;
        return CYLReadDoubleQuoted(quoted, &index) ?: body;
    }
    if (c == '"') {
        NSUInteger index = self.index;
        NSString *string = CYLReadDoubleQuoted(self.text, &index);
        if (!string) {
            [self fail:@"unterminated string"];
            return nil;
        }
        self.index = index;
        return string;
    }
    if (c == '\'') {
        NSUInteger index = self.index;
        NSString *string = CYLReadSingleQuoted(self.text, &index, NO);
        if (!string) {
            [self fail:@"unterminated literal string"];
            return nil;
        }
        self.index = index;
        return string;
    }
    if (c == '[') {
        self.index++;
        NSMutableArray *array = [NSMutableArray array];
        while (!self.error) {
            [self skipSpaceNewlinesAndComments];
            if ([self atEnd]) {
                [self fail:@"unterminated array"];
                return nil;
            }
            if ([self peek] == ']') {
                self.index++;
                break;
            }
            id value = [self parseValue];
            if (!value) {
                return nil;
            }
            [array addObject:value];
            [self skipSpaceNewlinesAndComments];
            if ([self peek] == ',') {
                self.index++;
            } else if ([self peek] != ']') {
                [self fail:@"expected ',' or ']' in an array"];
                return nil;
            }
        }
        return array;
    }
    if (c == '{') {
        self.index++;
        NSMutableDictionary *table = [NSMutableDictionary dictionary];
        while (!self.error) {
            [self skipInlineSpace];
            if ([self peek] == '}') {
                self.index++;
                break;
            }
            NSArray<NSString *> *key = [self parseKeyUntil:@"="];
            if (!key || [self peek] != '=') {
                [self fail:@"expected '=' in an inline table"];
                return nil;
            }
            self.index++;
            id value = [self parseValue];
            if (!value || !CYLSetValueAtPath(table, key, value)) {
                [self fail:@"invalid value in an inline table"];
                return nil;
            }
            [self skipInlineSpace];
            if ([self peek] == ',') {
                self.index++;
            } else if ([self peek] != '}') {
                [self fail:@"expected ',' or '}' in an inline table"];
                return nil;
            }
        }
        return table;
    }
    NSUInteger start = self.index;
    while (![self atEnd]) {
        unichar d = [self peek];
        if (d == ',' || d == ']' || d == '}' || d == '#' || CYLIsSpaceOrNewline(d)) {
            break;
        }
        self.index++;
    }
    NSString *token = [self.text substringWithRange:NSMakeRange(start, self.index - start)];
    if ([token isEqualToString:@"true"]) {
        return @(YES);
    }
    if ([token isEqualToString:@"false"]) {
        return @(NO);
    }
    NSNumber *number = CYLNumberFromString(token, YES);
    if (!number) {
        [self fail:[NSString stringWithFormat:@"invalid value \"%@\" (strings need quotes)", token]];
    }
    return number;
}

- (nullable NSMutableDictionary *)parse {
    NSMutableDictionary *root = [NSMutableDictionary dictionary];
    NSMutableDictionary *table = root;
    while (!self.error) {
        [self skipSpaceNewlinesAndComments];
        if ([self atEnd]) {
            break;
        }
        if ([self hasPrefixAtIndex:@"[["]) {
            self.index += 2;
            NSArray<NSString *> *path = [self parseKeyUntil:@"]"];
            if (!path || ![self hasPrefixAtIndex:@"]]"]) {
                [self fail:@"expected ']]'"];
                break;
            }
            self.index += 2;
            [self expectEndOfLine];
            NSMutableDictionary *parent = root;
            for (NSUInteger i = 0; i + 1 < path.count && parent; i++) {
                parent = CYLChildDictionary(parent, path[i]);
            }
            id existing = parent[path.lastObject];
            if (!parent || (existing && ![existing isKindOfClass:[NSMutableArray class]])) {
                [self fail:@"array of tables conflicts with an existing key"];
                break;
            }
            NSMutableArray *array = existing ?: [NSMutableArray array];
            parent[path.lastObject] = array;
            table = [NSMutableDictionary dictionary];
            [array addObject:table];
            continue;
        }
        if ([self peek] == '[') {
            self.index++;
            NSArray<NSString *> *path = [self parseKeyUntil:@"]"];
            if (!path || [self peek] != ']') {
                [self fail:@"expected ']'"];
                break;
            }
            self.index++;
            [self expectEndOfLine];
            table = root;
            for (NSString *part in path) {
                table = CYLChildDictionary(table, part);
                if (!table) {
                    [self fail:@"table conflicts with an existing key"];
                    break;
                }
            }
            continue;
        }
        NSArray<NSString *> *key = [self parseKeyUntil:@"="];
        if (!key || [self peek] != '=') {
            [self fail:@"expected \"key = value\""];
            break;
        }
        self.index++;
        id value = [self parseValue];
        if (!value) {
            break;
        }
        if (!CYLSetValueAtPath(table, key, value)) {
            [self fail:@"key conflicts with an existing value"];
            break;
        }
        [self expectEndOfLine];
    }
    return self.error ? nil : root;
}

@end

#pragma mark - INI and .properties / .env

/*!
 * [EN] INI: `[a.b]` sections (dotted paths, numbers for array elements), `key = value` or `key: value`, comments on
 *      their own line starting with `;` or `#`.
 * [CN] INI：`[a.b]` 节（点分隔路径，数字表示数组元素）、`key = value` 或 `key: value`，以 `;` 或 `#` 开头的整行注释。
 */
static NSDictionary *_Nullable CYLDictionaryFromINI(NSString *text, NSError **error) {
    NSMutableDictionary *root = [NSMutableDictionary dictionary];
    NSArray<NSString *> *section = @[];
    NSUInteger number = 0;
    for (NSString *raw in CYLLines(text)) {
        number++;
        NSString *line = CYLTrimmed(raw);
        if (line.length == 0 || [line hasPrefix:@";"] || [line hasPrefix:@"#"]) {
            continue;
        }
        if ([line hasPrefix:@"["]) {
            if (![line hasSuffix:@"]"]) {
                if (error) { *error = CYLConfigurationSyntaxError(@"INI", number, @"expected ']'"); }
                return nil;
            }
            NSArray<NSString *> *path = CYLSplitDottedKey([line substringWithRange:NSMakeRange(1, line.length - 2)]);
            if (!path) {
                if (error) { *error = CYLConfigurationSyntaxError(@"INI", number, @"invalid section name"); }
                return nil;
            }
            section = path;
            continue;
        }
        NSRange equals = [line rangeOfString:@"="];
        NSRange colon = [line rangeOfString:@":"];
        NSRange separator = equals;
        if (separator.location == NSNotFound || (colon.location != NSNotFound && colon.location < equals.location)) {
            separator = colon;
        }
        if (separator.location == NSNotFound) {
            if (error) { *error = CYLConfigurationSyntaxError(@"INI", number, @"expected \"key = value\""); }
            return nil;
        }
        NSArray<NSString *> *key = CYLSplitDottedKey([line substringToIndex:separator.location]);
        if (!key) {
            if (error) { *error = CYLConfigurationSyntaxError(@"INI", number, @"invalid key"); }
            return nil;
        }
        id value = CYLUnquotedOrTypedValue([line substringFromIndex:NSMaxRange(separator)]);
        if (!CYLSetValueAtPath(root, [section arrayByAddingObjectsFromArray:key], value)) {
            if (error) { *error = CYLConfigurationSyntaxError(@"INI", number, @"key conflicts with an existing value"); }
            return nil;
        }
    }
    return CYLArraysFromNumericKeys(root);
}

/// [EN] Java .properties escapes (\n, \t, \uXXXX, \=, \:, \\...). [CN] Java .properties 转义（\n、\t、\uXXXX、\=、\:、\\ 等）。
static NSString *CYLUnescapedPropertiesString(NSString *text) {
    if ([text rangeOfString:@"\\"].location == NSNotFound) {
        return text;
    }
    NSMutableString *output = [NSMutableString string];
    NSUInteger length = text.length;
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [text characterAtIndex:i];
        if (c != '\\' || i + 1 >= length) {
            [output appendString:[NSString stringWithCharacters:&c length:1]];
            continue;
        }
        unichar e = [text characterAtIndex:++i];
        if (e == 'n') {
            [output appendString:@"\n"];
        } else if (e == 't') {
            [output appendString:@"\t"];
        } else if (e == 'r') {
            [output appendString:@"\r"];
        } else if (e == 'u' && i + 4 < length &&
                   CYLAppendUnicodeEscape(output, [text substringWithRange:NSMakeRange(i + 1, 4)])) {
            i += 4;
        } else {
            [output appendString:[NSString stringWithCharacters:&e length:1]];
        }
    }
    return output;
}

/*!
 * [EN] .properties and .env: `a.b.0.c = value` (also `:` or a space as separator), `#` or `!` comment lines, a trailing
 *      `\` continues the line; .env style `export KEY="value"` and `__` as a path separator are accepted too.
 * [CN] .properties 与 .env：`a.b.0.c = value`（分隔符也可为 `:` 或空格）、以 `#` 或 `!` 开头的注释行、行尾 `\` 表示续行；
 *      也接受 .env 风格的 `export KEY="value"`，以及用 `__` 作为路径分隔符。
 */
static NSDictionary *_Nullable CYLDictionaryFromProperties(NSString *text, NSError **error) {
    NSMutableDictionary *root = [NSMutableDictionary dictionary];
    NSArray<NSString *> *lines = CYLLines(text);
    NSUInteger number = 0;
    for (NSUInteger index = 0; index < lines.count; index++) {
        number = index + 1;
        NSString *line = [lines[index] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (line.length == 0 || [line hasPrefix:@"#"] || [line hasPrefix:@"!"]) {
            continue;
        }
        while ([line hasSuffix:@"\\"] && ![line hasSuffix:@"\\\\"] && index + 1 < lines.count) {
            index++;
            line = [[line substringToIndex:line.length - 1] stringByAppendingString:CYLTrimmed(lines[index])];
        }
        if ([line hasPrefix:@"export "]) {
            line = CYLTrimmed([line substringFromIndex:7]);
        }
        NSUInteger separator = NSNotFound;
        for (NSUInteger i = 0; i < line.length; i++) {
            unichar c = [line characterAtIndex:i];
            if (c == '\\') {
                i++;
                continue;
            }
            if (c == '=' || c == ':' || CYLIsInlineSpace(c)) {
                separator = i;
                break;
            }
        }
        if (separator == NSNotFound) {
            if (error) { *error = CYLConfigurationSyntaxError(@"Properties", number, @"expected \"key = value\""); }
            return nil;
        }
        NSString *key = CYLUnescapedPropertiesString([line substringToIndex:separator]);
        NSString *rest = [line substringFromIndex:separator];
        rest = [rest stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([rest hasPrefix:@"="] || [rest hasPrefix:@":"]) {
            rest = [[rest substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        id value = nil;
        if (rest.length >= 2 && ([rest hasPrefix:@"\""] || [rest hasPrefix:@"'"])) {
            value = CYLUnquotedOrTypedValue(rest);
        } else {
            value = CYLTypedScalar(CYLUnescapedPropertiesString(rest), NO);
        }
        NSString *dotted = [key stringByReplacingOccurrencesOfString:@"__" withString:@"."];
        // A quoted part may contain dots, e.g. a Lottie keypath: a."Icon.**.Color". 带引号的部分可以包含点，例如 Lottie keypath。
        NSArray<NSString *> *path = [dotted rangeOfString:@"\""].location != NSNotFound
            ? CYLSplitDottedKey(dotted)
            : [dotted componentsSeparatedByString:@"."];
        if (path.count == 0 || path.count > CYLTabBarConfigurationMaximumDepth) {
            if (error) { *error = CYLConfigurationSyntaxError(@"Properties", number, @"invalid key"); }
            return nil;
        }
        for (NSString *part in path) {
            if (part.length == 0) {
                if (error) { *error = CYLConfigurationSyntaxError(@"Properties", number, @"invalid key"); }
                return nil;
            }
        }
        if (!CYLSetValueAtPath(root, path, value)) {
            if (error) { *error = CYLConfigurationSyntaxError(@"Properties", number, @"key conflicts with an existing value"); }
            return nil;
        }
    }
    return CYLArraysFromNumericKeys(root);
}

#pragma mark - XML (not a plist)

@interface CYLXMLNode : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *attributes;
@property (nonatomic, strong) NSMutableArray<CYLXMLNode *> *children;
@property (nonatomic, strong) NSMutableString *text;
@end

@implementation CYLXMLNode
@end

@interface CYLXMLTreeBuilder : NSObject <NSXMLParserDelegate>
@property (nonatomic, strong, nullable) CYLXMLNode *root;
@property (nonatomic, strong) NSMutableArray<CYLXMLNode *> *stack;
@property (nonatomic, assign) BOOL tooDeep;
@end

@implementation CYLXMLTreeBuilder

- (instancetype)init {
    if (self = [super init]) {
        _stack = [NSMutableArray array];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict {
    if (self.tooDeep || self.stack.count >= CYLTabBarConfigurationMaximumDepth) {
        // Some parsers keep calling back after -abortParsing: ignore everything from here.
        // 部分解析器在 -abortParsing 之后仍会回调：此后的回调全部忽略。
        self.tooDeep = YES;
        [parser abortParsing];
        return;
    }
    CYLXMLNode *node = [[CYLXMLNode alloc] init];
    node.name = elementName;
    node.attributes = attributeDict ?: @{};
    node.children = [NSMutableArray array];
    node.text = [NSMutableString string];
    [self.stack.lastObject.children addObject:node];
    if (!self.root) {
        self.root = node;
    }
    [self.stack addObject:node];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.tooDeep) {
        return;
    }
    [self.stack.lastObject.text appendString:string];
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    NSString *string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    if (string) {
        [self.stack.lastObject.text appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if (self.tooDeep) {
        return;
    }
    [self.stack removeLastObject];
}

@end

/*!
 * [EN] An element as a value: with children, a dictionary (children by name, a repeated name makes an array) or, when
 *      every child is `<item>` (or `type="array"`), an array; with only attributes, a dictionary of the attributes; else
 *      its text as a scalar (`type="string"` keeps it a string).
 * [CN] 将元素转换为值：有子元素时为字典（按名称，名称重复时为数组），子元素全部为 `<item>`（或 `type="array"`）时为数组；只有属性时为属性字典；
 *      否则为其文本标量（`type="string"` 时保持字符串）。
 */
static id CYLValueFromXMLNode(CYLXMLNode *node) {
    NSString *type = node.attributes[@"type"];
    NSMutableDictionary<NSString *, NSString *> *attributes = [node.attributes mutableCopy];
    [attributes removeObjectForKey:@"type"];
    BOOL allItems = node.children.count > 0;
    for (CYLXMLNode *child in node.children) {
        if (![child.name isEqualToString:@"item"]) {
            allItems = NO;
        }
    }
    if ([type isEqualToString:@"array"] || allItems) {
        NSMutableArray *array = [NSMutableArray array];
        for (CYLXMLNode *child in node.children) {
            [array addObject:CYLValueFromXMLNode(child)];
        }
        return array;
    }
    if (node.children.count > 0 || attributes.count > 0 || [type isEqualToString:@"dict"]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (NSString *key in attributes) {
            dictionary[key] = CYLTypedScalar(attributes[key], NO);
        }
        // Children grouped by name, in order: a repeated name makes an array. 按名称分组（保持顺序）：名称重复时组成数组。
        NSMutableArray<NSString *> *names = [NSMutableArray array];
        NSMutableDictionary<NSString *, NSMutableArray *> *values = [NSMutableDictionary dictionary];
        for (CYLXMLNode *child in node.children) {
            if (!values[child.name]) {
                values[child.name] = [NSMutableArray array];
                [names addObject:child.name];
            }
            [values[child.name] addObject:CYLValueFromXMLNode(child)];
        }
        for (NSString *name in names) {
            NSArray *group = values[name];
            dictionary[name] = group.count == 1 ? group.firstObject : group;
        }
        return dictionary;
    }
    NSString *text = CYLTrimmed(node.text);
    if ([type isEqualToString:@"string"]) {
        return node.text.length > 0 ? [node.text copy] : @"";
    }
    return CYLTypedScalar(text, NO);
}

static NSDictionary *_Nullable CYLDictionaryFromXML(NSData *data, NSError **error) {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    CYLXMLTreeBuilder *builder = [[CYLXMLTreeBuilder alloc] init];
    parser.delegate = builder;
    // Never fetch or expand external entities (XXE, A14). 绝不获取或展开外部实体（XXE，A14）。
    parser.shouldResolveExternalEntities = NO;
    BOOL parsed = [parser parse];
    if (builder.tooDeep) {
        if (error) { *error = CYLConfigurationTooDeepError(@"XML"); }
        return nil;
    }
    if (!parsed || !builder.root) {
        NSString *reason = parser.parserError.localizedDescription ?: @"invalid XML";
        if (error) { *error = CYLConfigurationSyntaxError(@"XML", (NSUInteger)parser.lineNumber, reason); }
        return nil;
    }
    // The root element (e.g. <CYLTabBarController>) holds the configuration. 根元素（如 <CYLTabBarController>）包含配置。
    id value = CYLValueFromXMLNode(builder.root);
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    if (error) { *error = CYLConfigurationError(CYLTabBarConfigurationErrorNotADictionary, @"XML configuration: the root element must contain elements"); }
    return nil;
}

#pragma mark - Protocol Buffers text format

/*!
 * [EN] Protocol Buffers text format, without a schema: `name: value`, `name { ... }` (or `< ... >`), `name: [a, b]`;
 *      a name written several times makes an array; `#` comments; `,` or `;` between fields; strings with C escapes
 *      (octal and \x escapes are bytes, decoded as UTF-8, as protoc writes non-ASCII text); `true` / `false` as booleans,
 *      numbers as NSNumber, enum names as strings.
 * [CN] Protocol Buffers 文本格式，无需结构定义：`name: value`、`name { ... }`（或 `< ... >`）、`name: [a, b]`；同名字段出现多次时组成数组；
 *      `#` 注释；字段之间可用 `,` 或 `;`；字符串支持 C 转义（八进制与 \x 转义按字节处理，再按 UTF-8 解码，与 protoc 输出非 ASCII 文本的方式一致）；
 *      `true` / `false` 为布尔值，数字为 NSNumber，枚举名为字符串。
 */
@interface CYLTextProtoParser : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSUInteger depth;
@property (nonatomic, strong, nullable) NSError *error;
@end

@implementation CYLTextProtoParser

- (NSUInteger)currentLine {
    NSUInteger line = 1;
    for (NSUInteger i = 0; i < self.index && i < self.text.length; i++) {
        if ([self.text characterAtIndex:i] == '\n') {
            line++;
        }
    }
    return line;
}

- (void)fail:(NSString *)reason {
    if (!self.error) {
        self.error = CYLConfigurationSyntaxError(@"Protobuf text", [self currentLine], reason);
    }
}

- (BOOL)atEnd {
    return self.index >= self.text.length;
}

- (unichar)peek {
    return [self atEnd] ? 0 : [self.text characterAtIndex:self.index];
}

- (void)skipSpaceAndComments {
    while (![self atEnd]) {
        unichar c = [self peek];
        if (CYLIsSpaceOrNewline(c)) {
            self.index++;
        } else if (c == '#') {
            while (![self atEnd] && [self peek] != '\n') {
                self.index++;
            }
        } else {
            break;
        }
    }
}

static BOOL CYLIsTextProtoNameCharacter(unichar c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '.' || c == '/';
}

- (nullable NSString *)parseName {
    if ([self peek] == '[') {
        // An extension or Any type URL: [package.name]. 扩展或 Any 类型 URL：[package.name]。
        NSRange end = [self.text rangeOfString:@"]" options:0 range:NSMakeRange(self.index, self.text.length - self.index)];
        if (end.location == NSNotFound) {
            [self fail:@"expected ']'"];
            return nil;
        }
        NSString *name = [self.text substringWithRange:NSMakeRange(self.index + 1, end.location - self.index - 1)];
        self.index = NSMaxRange(end);
        return CYLTrimmed(name);
    }
    NSUInteger start = self.index;
    while (![self atEnd] && CYLIsTextProtoNameCharacter([self peek])) {
        self.index++;
    }
    if (self.index == start) {
        [self fail:@"expected a field name"];
        return nil;
    }
    return [self.text substringWithRange:NSMakeRange(start, self.index - start)];
}

/// [EN] One quoted string; escapes are bytes, so octal UTF-8 sequences become text. [CN] 一个带引号的字符串；转义按字节处理，八进制 UTF-8 序列可还原为文本。
- (nullable NSString *)parseQuotedString {
    unichar quote = [self peek];
    self.index++;
    NSMutableData *bytes = [NSMutableData data];
    while (![self atEnd]) {
        unichar c = [self peek];
        if (c == quote) {
            self.index++;
            NSString *string = [[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding];
            if (!string) {
                [self fail:@"a string is not valid UTF-8"];
            }
            return string;
        }
        if (c == '\n') {
            break;
        }
        if (c != '\\') {
            NSString *character = [NSString stringWithCharacters:&c length:1];
            [bytes appendData:[character dataUsingEncoding:NSUTF8StringEncoding]];
            self.index++;
            continue;
        }
        self.index++;
        unichar e = [self peek];
        self.index++;
        unsigned char byte = 0;
        if (e >= '0' && e <= '7') {
            unsigned int value = e - '0';
            for (NSUInteger n = 0; n < 2 && ![self atEnd] && [self peek] >= '0' && [self peek] <= '7'; n++) {
                value = value * 8 + ([self peek] - '0');
                self.index++;
            }
            byte = (unsigned char)value;
            [bytes appendBytes:&byte length:1];
        } else if (e == 'x' || e == 'X') {
            unsigned int value = 0;
            NSUInteger digits = 0;
            while (digits < 2 && ![self atEnd] && isxdigit((int)[self peek])) {
                unichar h = [self peek];
                value = value * 16 + (unsigned int)((h <= '9') ? h - '0' : (h | 0x20) - 'a' + 10);
                self.index++;
                digits++;
            }
            byte = (unsigned char)value;
            [bytes appendBytes:&byte length:1];
        } else if (e == 'u' || e == 'U') {
            NSUInteger count = (e == 'u') ? 4 : 8;
            if (self.index + count > self.text.length) {
                [self fail:@"invalid unicode escape"];
                return nil;
            }
            NSMutableString *character = [NSMutableString string];
            if (!CYLAppendUnicodeEscape(character, [self.text substringWithRange:NSMakeRange(self.index, count)])) {
                [self fail:@"invalid unicode escape"];
                return nil;
            }
            self.index += count;
            [bytes appendData:[character dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            const char *simple = NULL;
            switch (e) {
                case 'n': simple = "\n"; break;
                case 't': simple = "\t"; break;
                case 'r': simple = "\r"; break;
                case 'a': simple = "\a"; break;
                case 'b': simple = "\b"; break;
                case 'f': simple = "\f"; break;
                case 'v': simple = "\v"; break;
                default: break;
            }
            if (simple) {
                [bytes appendBytes:simple length:1];
            } else {
                NSString *character = [NSString stringWithCharacters:&e length:1];
                [bytes appendData:[character dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    [self fail:@"unterminated string"];
    return nil;
}

- (nullable id)parseScalar {
    unichar c = [self peek];
    if (c == '"' || c == '\'') {
        // Adjacent strings are concatenated. 相邻的字符串会被连接。
        NSMutableString *string = [NSMutableString string];
        while (!self.error && ([self peek] == '"' || [self peek] == '\'')) {
            NSString *part = [self parseQuotedString];
            if (!part) {
                return nil;
            }
            [string appendString:part];
            [self skipSpaceAndComments];
        }
        return string;
    }
    NSUInteger start = self.index;
    while (![self atEnd]) {
        unichar d = [self peek];
        if (CYLIsSpaceOrNewline(d) || d == ',' || d == ';' || d == '}' || d == '>' || d == ']' || d == '#') {
            break;
        }
        self.index++;
    }
    NSString *token = [self.text substringWithRange:NSMakeRange(start, self.index - start)];
    if (token.length == 0) {
        [self fail:@"expected a value"];
        return nil;
    }
    if ([token isEqualToString:@"true"] || [token isEqualToString:@"True"] || [token isEqualToString:@"t"]) {
        return @(YES);
    }
    if ([token isEqualToString:@"false"] || [token isEqualToString:@"False"] || [token isEqualToString:@"f"]) {
        return @(NO);
    }
    NSString *numeric = token;
    if (numeric.length > 1 && ([numeric hasSuffix:@"f"] || [numeric hasSuffix:@"F"]) && ![numeric hasPrefix:@"0x"] && ![numeric hasPrefix:@"0X"]) {
        numeric = [numeric substringToIndex:numeric.length - 1];
    }
    return CYLNumberFromString(numeric, NO) ?: token;
}

- (nullable id)parseValue {
    if (++self.depth > CYLTabBarConfigurationMaximumDepth) {
        self.error = self.error ?: CYLConfigurationTooDeepError(@"Protobuf text");
        self.depth--;
        return nil;
    }
    id value = [self parseValueBody];
    self.depth--;
    return value;
}

- (nullable id)parseValueBody {
    [self skipSpaceAndComments];
    unichar c = [self peek];
    if (c == '{' || c == '<') {
        self.index++;
        NSMutableDictionary *message = [self parseFieldsUntil:(c == '{') ? '}' : '>'];
        if (!message) {
            return nil;
        }
        self.index++;
        return message;
    }
    if (c == '[') {
        self.index++;
        NSMutableArray *array = [NSMutableArray array];
        while (!self.error) {
            [self skipSpaceAndComments];
            if ([self peek] == ']') {
                self.index++;
                return array;
            }
            id value = [self parseValue];
            if (!value) {
                return nil;
            }
            [array addObject:value];
            [self skipSpaceAndComments];
            if ([self peek] == ',') {
                self.index++;
            } else if ([self peek] != ']') {
                [self fail:@"expected ',' or ']'"];
                return nil;
            }
        }
        return nil;
    }
    return [self parseScalar];
}

/// [EN] Fields until `terminator` (0: the end of the text); the terminator is not consumed. [CN] 解析字段直到 `terminator`（0 表示文本结尾），不消耗结束符。
- (nullable NSMutableDictionary *)parseFieldsUntil:(unichar)terminator {
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    NSMutableSet<NSString *> *repeated = [NSMutableSet set];
    while (!self.error) {
        [self skipSpaceAndComments];
        if ([self atEnd]) {
            if (terminator != 0) {
                [self fail:@"unterminated message"];
                return nil;
            }
            break;
        }
        if (terminator != 0 && [self peek] == terminator) {
            break;
        }
        NSString *name = [self parseName];
        if (!name) {
            return nil;
        }
        [self skipSpaceAndComments];
        BOOL hasColon = ([self peek] == ':');
        if (hasColon) {
            self.index++;
            [self skipSpaceAndComments];
        } else if ([self peek] != '{' && [self peek] != '<') {
            [self fail:[NSString stringWithFormat:@"expected ':' or '{' after \"%@\"", name]];
            return nil;
        }
        id value = [self parseValue];
        if (!value) {
            return nil;
        }
        id existing = message[name];
        if (!existing) {
            message[name] = value;
        } else if ([repeated containsObject:name]) {
            [(NSMutableArray *)existing addObject:value];
        } else {
            message[name] = [NSMutableArray arrayWithObjects:existing, value, nil];
            [repeated addObject:name];
        }
        [self skipSpaceAndComments];
        if ([self peek] == ',' || [self peek] == ';') {
            self.index++;
        }
    }
    return self.error ? nil : message;
}

@end

#pragma mark - Protocol Buffers binary

/*!
 * [EN] The built-in schema of a binary configuration, the same as Configurations/cyl_tabbar_configuration.proto:
 *      message name -> field number -> @[field name, kind]. Kinds: "string", "map" (map<string, string>), or
 *      "repeated:<Message>". Field numbers never change; unknown fields are skipped.
 * [CN] 二进制配置的内置结构定义，与 Configurations/cyl_tabbar_configuration.proto 相同：消息名 -> 字段编号 -> @[字段名, 类型]。
 *      类型为 "string"、"map"（map<string, string>）或 "repeated:<消息名>"。字段编号永不改变；未知字段会被跳过。
 */
static NSDictionary<NSString *, NSDictionary<NSNumber *, NSArray<NSString *> *> *> *CYLProtobufSchema(void) {
    // A literal each time (cheap, and thread-safe without dispatch_once). 每次返回字面量（开销小，且无需 dispatch_once 即线程安全）。
    return @{
            @"CYLTabBarConfiguration" : @{
                @1 : @[ @"CYLTabBarControllerTabBarItemsAttributes", @"repeated:CYLTabBarItem" ],
                @2 : @[ @"CYLTabBarControllerImageInsets", @"string" ],
                @3 : @[ @"CYLTabBarControllerTitlePositionAdjustment", @"string" ],
                @4 : @[ @"CYLTabBarControllerStyleType", @"string" ],
                @5 : @[ @"CYLTabBarControllerContext", @"string" ],
                @6 : @[ @"CYLTabBarControllerNavigationControllerClass", @"string" ],
            },
            @"CYLTabBarItem" : @{
                @1 : @[ @"CYLTabBarItemTitle", @"string" ],
                @2 : @[ @"CYLTabBarItemImage", @"string" ],
                @3 : @[ @"CYLTabBarItemSelectedImage", @"string" ],
                @4 : @[ @"CYLTabBarItemDarkImage", @"string" ],
                @5 : @[ @"CYLTabBarItemSelectedDarkImage", @"string" ],
                @6 : @[ @"CYLTabBarItemImageURL", @"string" ],
                @7 : @[ @"CYLTabBarItemSelectedImageURL", @"string" ],
                @8 : @[ @"CYLTabBarItemImageURLSize", @"string" ],
                @9 : @[ @"CYLTabBarItemImageInsets", @"string" ],
                @10 : @[ @"CYLTabBarItemTitlePositionAdjustment", @"string" ],
                @11 : @[ @"CYLTabBarItemImagePositionAdjustment", @"string" ],
                @12 : @[ @"CYLTabBarLottieFilePath", @"string" ],
                @13 : @[ @"CYLTabBarLottieURL", @"string" ],
                @14 : @[ @"CYLTabBarLottieSize", @"string" ],
                @15 : @[ @"CYLTabBarItemIdentifier", @"string" ],
                @16 : @[ @"CYLTabBarLottieDarkURL", @"string" ],
                @17 : @[ @"CYLTabBarLottieDarkFilePath", @"string" ],
                @18 : @[ @"CYLTabBarLottieDarkColors", @"map" ],
                @19 : @[ @"CYLTabBarItemViewControllerClass", @"string" ],
                @20 : @[ @"CYLTabBarItemNavigationControllerClass", @"string" ],
            },
            @"CYLMapEntry" : @{
                @1 : @[ @"key", @"string" ],
                @2 : @[ @"value", @"string" ],
            },
        };
}

/// [EN] Reads a base-128 varint at `*offset`. NO when it runs past `length` or is longer than 10 bytes.
/// [CN] 读取 `*offset` 处的 base-128 varint。超出 `length` 或超过 10 字节时返回 NO。
static BOOL CYLReadVarint(const uint8_t *bytes, NSUInteger length, NSUInteger *offset, uint64_t *value) {
    uint64_t result = 0;
    for (NSUInteger shift = 0; shift < 70; shift += 7) {
        if (*offset >= length) {
            return NO;
        }
        uint8_t byte = bytes[(*offset)++];
        result |= (uint64_t)(byte & 0x7F) << shift;
        if (!(byte & 0x80)) {
            *value = result;
            return YES;
        }
    }
    return NO;
}

/*!
 * [EN] Decodes the bytes of one message of the built-in schema; nil on malformed data. Every field must fit in the
 *      message, so random bytes are rejected.
 * [CN] 按内置结构定义解码一个消息的字节；数据损坏时返回 nil。每个字段都必须在消息范围内，因此随机字节会被拒绝。
 */
static NSMutableDictionary *_Nullable CYLDecodeProtobufMessage(const uint8_t *bytes, NSUInteger length, NSString *messageName) {
    NSDictionary<NSNumber *, NSArray<NSString *> *> *fields = CYLProtobufSchema()[messageName];
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    NSUInteger offset = 0;
    while (offset < length) {
        uint64_t key = 0;
        if (!CYLReadVarint(bytes, length, &offset, &key) || key >> 3 == 0) {
            return nil;
        }
        uint64_t fieldNumber = key >> 3;
        uint32_t wireType = (uint32_t)(key & 0x7);
        NSArray<NSString *> *field = fieldNumber <= INT32_MAX ? fields[@((NSInteger)fieldNumber)] : nil;
        if (wireType == 0) {
            uint64_t ignored = 0;
            if (!CYLReadVarint(bytes, length, &offset, &ignored)) {
                return nil;
            }
            continue; // No varint fields in the schema. 结构定义中没有 varint 字段。
        }
        if (wireType == 1 || wireType == 5) {
            NSUInteger size = (wireType == 1) ? 8 : 4;
            if (offset + size > length) {
                return nil;
            }
            offset += size;
            continue;
        }
        if (wireType != 2) {
            return nil; // Groups (3, 4) are not used; other values are invalid. 不使用 group（3、4），其他值无效。
        }
        uint64_t size = 0;
        if (!CYLReadVarint(bytes, length, &offset, &size) || size > length - offset) {
            return nil;
        }
        const uint8_t *payload = bytes + offset;
        offset += (NSUInteger)size;
        if (!field) {
            continue; // An unknown field, e.g. from a newer schema. 未知字段，例如来自更新的结构定义。
        }
        NSString *name = field[0];
        NSString *kind = field[1];
        if ([kind isEqualToString:@"string"]) {
            NSString *string = [[NSString alloc] initWithBytes:payload length:(NSUInteger)size encoding:NSUTF8StringEncoding];
            if (!string) {
                return nil;
            }
            message[name] = string;
        } else if ([kind isEqualToString:@"map"]) {
            NSMutableDictionary *entry = CYLDecodeProtobufMessage(payload, (NSUInteger)size, @"CYLMapEntry");
            if (!entry) {
                return nil;
            }
            NSMutableDictionary *map = message[name] ?: [NSMutableDictionary dictionary];
            map[entry[@"key"] ?: @""] = entry[@"value"] ?: @"";
            message[name] = map;
        } else if ([kind hasPrefix:@"repeated:"]) {
            NSMutableDictionary *element = CYLDecodeProtobufMessage(payload, (NSUInteger)size, [kind substringFromIndex:9]);
            if (!element) {
                return nil;
            }
            NSMutableArray *array = message[name] ?: [NSMutableArray array];
            [array addObject:element];
            message[name] = array;
        }
    }
    return message;
}

static NSDictionary *_Nullable CYLDictionaryFromProtobuf(NSData *data, NSError **error) {
    NSDictionary *dictionary = CYLDecodeProtobufMessage(data.bytes, data.length, @"CYLTabBarConfiguration");
    if (!dictionary && error) {
        *error = CYLConfigurationSyntaxError(@"Protobuf", 0, @"the data is not a valid cyl.CYLTabBarConfiguration message (see cyl_tabbar_configuration.proto)");
    }
    return dictionary;
}

/// [EN] Control bytes other than tab and newlines: binary data, not text. [CN] 含有除制表符与换行之外的控制字节：二进制数据而非文本。
static BOOL CYLDataLooksBinary(NSData *data) {
    const uint8_t *bytes = data.bytes;
    for (NSUInteger i = 0; i < data.length; i++) {
        uint8_t byte = bytes[i];
        if (byte < 0x20 && byte != '\t' && byte != '\n' && byte != '\r') {
            return YES;
        }
    }
    return NO;
}

#pragma mark - CYLTabBarConfigurationParser

static BOOL CYLDataHasPrefix(NSData *data, const char *prefix) {
    size_t length = strlen(prefix);
    return data.length >= length && memcmp(data.bytes, prefix, length) == 0;
}

@interface CYLTabBarConfigurationParser ()
/// [EN] One parse in one format, without the retry of A7. [CN] 按一种格式解析一次，不含 A7 的重试。
+ (nullable NSDictionary<NSString *, id> *)cyl_dictionaryWithData:(NSData *)data
                                                           format:(CYLTabBarConfigurationFormat)format
                                                            error:(NSError *_Nullable *_Nullable)error;
@end

@implementation CYLTabBarConfigurationParser

+ (NSDictionary<NSString *, NSNumber *> *)formatsByPathExtension {
    return @{
        @"json" : @(CYLTabBarConfigurationFormatJSON),
        @"json5" : @(CYLTabBarConfigurationFormatJSON5),
        @"jsonc" : @(CYLTabBarConfigurationFormatJSON5),
        @"plist" : @(CYLTabBarConfigurationFormatPropertyList),
        @"strings" : @(CYLTabBarConfigurationFormatPropertyList),
        @"yaml" : @(CYLTabBarConfigurationFormatYAML),
        @"yml" : @(CYLTabBarConfigurationFormatYAML),
        @"toml" : @(CYLTabBarConfigurationFormatTOML),
        @"ini" : @(CYLTabBarConfigurationFormatINI),
        @"cfg" : @(CYLTabBarConfigurationFormatINI),
        @"conf" : @(CYLTabBarConfigurationFormatINI),
        @"properties" : @(CYLTabBarConfigurationFormatProperties),
        @"env" : @(CYLTabBarConfigurationFormatProperties),
        @"xml" : @(CYLTabBarConfigurationFormatXML),
        @"textproto" : @(CYLTabBarConfigurationFormatProtobufText),
        @"txtpb" : @(CYLTabBarConfigurationFormatProtobufText),
        @"pbtxt" : @(CYLTabBarConfigurationFormatProtobufText),
        @"prototxt" : @(CYLTabBarConfigurationFormatProtobufText),
        @"binpb" : @(CYLTabBarConfigurationFormatProtobuf),
        @"pb" : @(CYLTabBarConfigurationFormatProtobuf),
        @"protobuf" : @(CYLTabBarConfigurationFormatProtobuf),
    };
}

+ (NSArray<NSString *> *)supportedPathExtensions {
    return [[[self formatsByPathExtension] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

+ (CYLTabBarConfigurationFormat)formatForPathExtension:(NSString *)pathExtension {
    NSNumber *format = pathExtension ? [self formatsByPathExtension][pathExtension.lowercaseString] : nil;
    return format ? (CYLTabBarConfigurationFormat)format.integerValue : CYLTabBarConfigurationFormatUnknown;
}

+ (CYLTabBarConfigurationFormat)formatForMIMEType:(NSString *)MIMEType {
    NSString *type = CYLTrimmed([[MIMEType componentsSeparatedByString:@";"].firstObject lowercaseString] ?: @"");
    if (type.length == 0) {
        return CYLTabBarConfigurationFormatUnknown;
    }
    if ([type rangeOfString:@"protobuf"].location != NSNotFound || [type rangeOfString:@"textproto"].location != NSNotFound) {
        // text/x-protobuf, text/x-textproto: text format; application/x-protobuf...: binary. 文本类型为文本格式，其他为二进制。
        return [type hasPrefix:@"text/"] ? CYLTabBarConfigurationFormatProtobufText : CYLTabBarConfigurationFormatProtobuf;
    }
    if ([type hasSuffix:@"json5"]) {
        return CYLTabBarConfigurationFormatJSON5;
    }
    if ([type hasSuffix:@"json"]) {
        return CYLTabBarConfigurationFormatJSON;
    }
    if ([type rangeOfString:@"yaml"].location != NSNotFound) {
        return CYLTabBarConfigurationFormatYAML;
    }
    if ([type rangeOfString:@"toml"].location != NSNotFound) {
        return CYLTabBarConfigurationFormatTOML;
    }
    if ([type rangeOfString:@"plist"].location != NSNotFound) {
        return CYLTabBarConfigurationFormatPropertyList;
    }
    if ([type hasSuffix:@"/xml"] || [type hasSuffix:@"+xml"]) {
        // XML may also be a plist: let the content decide. XML 也可能是 plist：由内容决定。
        return CYLTabBarConfigurationFormatUnknown;
    }
    if ([type rangeOfString:@"properties"].location != NSNotFound) {
        return CYLTabBarConfigurationFormatProperties;
    }
    if ([type rangeOfString:@"ini"].location != NSNotFound) {
        return CYLTabBarConfigurationFormatINI;
    }
    return CYLTabBarConfigurationFormatUnknown;
}

+ (NSString *)nameOfFormat:(CYLTabBarConfigurationFormat)format {
    switch (format) {
        case CYLTabBarConfigurationFormatJSON: return @"JSON";
        case CYLTabBarConfigurationFormatJSON5: return @"JSON5";
        case CYLTabBarConfigurationFormatPropertyList: return @"Property List";
        case CYLTabBarConfigurationFormatYAML: return @"YAML";
        case CYLTabBarConfigurationFormatTOML: return @"TOML";
        case CYLTabBarConfigurationFormatINI: return @"INI";
        case CYLTabBarConfigurationFormatProperties: return @"Properties";
        case CYLTabBarConfigurationFormatXML: return @"XML";
        case CYLTabBarConfigurationFormatProtobufText: return @"Protobuf text";
        case CYLTabBarConfigurationFormatProtobuf: return @"Protobuf";
        case CYLTabBarConfigurationFormatUnknown: break;
    }
    return @"Unknown";
}

+ (CYLTabBarConfigurationFormat)formatBySniffingData:(NSData *)data {
    data = CYLUTF8DataFromData(data);
    if (CYLDataHasPrefix(data, "bplist")) {
        return CYLTabBarConfigurationFormatPropertyList;
    }
    if (CYLDataLooksBinary(data)) {
        // Binary data: only a protobuf message can be. 二进制数据：只可能是 protobuf 消息。
        NSDictionary *dictionary = CYLDictionaryFromProtobuf(data, NULL);
        return dictionary.count > 0 ? CYLTabBarConfigurationFormatProtobuf : CYLTabBarConfigurationFormatUnknown;
    }
    NSString *text = CYLStringFromData(data);
    NSString *trimmed = CYLTrimmed(text ?: @"");
    if (trimmed.length == 0) {
        return CYLTabBarConfigurationFormatUnknown;
    }
    unichar first = [trimmed characterAtIndex:0];
    if (first == '<') {
        BOOL isPlist = [trimmed rangeOfString:@"<plist"].location != NSNotFound || [trimmed rangeOfString:@"DOCTYPE plist"].location != NSNotFound;
        return isPlist ? CYLTabBarConfigurationFormatPropertyList : CYLTabBarConfigurationFormatXML;
    }
    NSMutableArray<NSNumber *> *candidates = [NSMutableArray array];
    if (first == '{') {
        [candidates addObjectsFromArray:@[ @(CYLTabBarConfigurationFormatJSON), @(CYLTabBarConfigurationFormatJSON5) ]];
    } else {
        if (first == '/' || first == '[') {
            // JSON5 only starts with '{', a comment, or '[' for a (rejected) array. JSON5 只能以 '{'、注释或 '['（数组，不接受）开头。
            [candidates addObject:@(CYLTabBarConfigurationFormatJSON5)];
        }
        [candidates addObjectsFromArray:@[ @(CYLTabBarConfigurationFormatTOML), @(CYLTabBarConfigurationFormatYAML),
                                           @(CYLTabBarConfigurationFormatProtobufText) ]];
        // Without [sections], .properties first: it also reads .env (`export`, `__` paths). 没有 [节] 时先尝试 .properties：它也能读取 .env。
        BOOL hasSections = [trimmed hasPrefix:@"["] || [trimmed rangeOfString:@"\n["].location != NSNotFound;
        [candidates addObjectsFromArray:hasSections
            ? @[ @(CYLTabBarConfigurationFormatINI), @(CYLTabBarConfigurationFormatProperties) ]
            : @[ @(CYLTabBarConfigurationFormatProperties), @(CYLTabBarConfigurationFormatINI) ]];
    }
    // OpenStep property lists and .strings files (also after a leading comment). OpenStep 属性列表与 .strings 文件（也可能以注释开头）。
    [candidates addObject:@(CYLTabBarConfigurationFormatPropertyList)];
    for (NSNumber *candidate in candidates) {
        CYLTabBarConfigurationFormat format = (CYLTabBarConfigurationFormat)candidate.integerValue;
        if (format == CYLTabBarConfigurationFormatYAML && [trimmed rangeOfString:@":"].location == NSNotFound) {
            continue; // Plain text is a valid YAML scalar, not a configuration. 纯文本是合法的 YAML 标量，但不是配置。
        }
        NSError *error = nil;
        NSDictionary *dictionary = [self cyl_dictionaryWithData:data format:format error:&error];
        if (dictionary.count > 0 || error.code == CYLTabBarConfigurationErrorTooDeep) {
            // Too deep: this is the format, and the caller gets the TooDeep error. 嵌套过深：就是该格式，调用方会得到 TooDeep 错误。
            return format;
        }
    }
    return CYLTabBarConfigurationFormatUnknown;
}

+ (NSDictionary<NSString *, id> *)dictionaryWithData:(NSData *)data
                                              format:(CYLTabBarConfigurationFormat)format
                                               error:(NSError **)error {
    data = CYLUTF8DataFromData(data ?: [NSData data]);
    NSError *firstError = nil;
    NSDictionary<NSString *, id> *dictionary = [self cyl_dictionaryWithData:data format:format error:&firstError];
    if (dictionary || format == CYLTabBarConfigurationFormatUnknown ||
        (firstError.code != CYLTabBarConfigurationErrorInvalidSyntax && firstError.code != CYLTabBarConfigurationErrorNotADictionary)) {
        if (error) {
            *error = firstError;
        }
        return dictionary;
    }
    // The extension or Content-Type was wrong (e.g. YAML in a .json file): detect the format and try again (A7).
    // 扩展名或 Content-Type 有误（例如 .json 文件中是 YAML）：根据内容识别格式并重试（A7）。
    CYLTabBarConfigurationFormat detected = [self formatBySniffingData:data];
    // Never retry as .properties, INI or Protobuf text: they accept almost any `key value` text, so a syntax error of
    // the declared format would come back as a meaningless dictionary instead of its error (A17).
    // 不以 .properties、INI 或 Protobuf 文本重试：它们几乎接受任何 `key value` 文本，原格式的语法错误会变成毫无意义的字典，而不是错误（A17）。
    BOOL distinctive = detected != CYLTabBarConfigurationFormatProperties && detected != CYLTabBarConfigurationFormatINI &&
                       detected != CYLTabBarConfigurationFormatProtobufText;
    if (detected != CYLTabBarConfigurationFormatUnknown && detected != format && distinctive) {
        dictionary = [self cyl_dictionaryWithData:data format:detected error:NULL];
        if (dictionary) {
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🟡 CYLTabBarConfigurationParser: the content is %@, not %@; read as %@.",
                  [self nameOfFormat:detected], [self nameOfFormat:format], [self nameOfFormat:detected]);
#endif
            return dictionary;
        }
    }
    if (error) {
        *error = firstError;
    }
    return nil;
}

+ (nullable NSDictionary<NSString *, id> *)cyl_dictionaryWithData:(NSData *)data
                                                           format:(CYLTabBarConfigurationFormat)format
                                                            error:(NSError **)error {
    if (data.length > CYLTabBarConfigurationMaximumLength) {
        if (error) {
            *error = CYLConfigurationError(CYLTabBarConfigurationErrorTooLarge,
                                           [NSString stringWithFormat:@"The configuration is %lu bytes, more than the %lu allowed.",
                                            (unsigned long)data.length, (unsigned long)CYLTabBarConfigurationMaximumLength]);
        }
        return nil;
    }
    NSString *text = CYLStringFromData(data);
    if (data.length == 0 || (text && CYLTrimmed(text).length == 0)) {
        if (error) { *error = CYLConfigurationError(CYLTabBarConfigurationErrorEmpty, @"The configuration is empty."); }
        return nil;
    }
    if (format == CYLTabBarConfigurationFormatUnknown) {
        format = [self formatBySniffingData:data];
        if (format == CYLTabBarConfigurationFormatUnknown) {
            if (error) {
                *error = CYLConfigurationError(CYLTabBarConfigurationErrorUnsupportedFormat,
                                               [NSString stringWithFormat:@"The configuration format could not be detected. Supported file extensions: %@.",
                                                [[self supportedPathExtensions] componentsJoinedByString:@", "]]);
            }
            return nil;
        }
    }
    NSString *formatName = [self nameOfFormat:format];
    id result = nil;
    NSError *parseError = nil;
    if (format == CYLTabBarConfigurationFormatPropertyList) {
        // Apple's parser is recursive: check the nesting first (A10). Apple 的解析器是递归的：先检查嵌套层数（A10）。
        BOOL tooDeep = NO;
        if (CYLDataHasPrefix(data, "bplist")) {
            if (!CYLBinaryPropertyListIsSafe(data, &tooDeep)) {
                if (error) {
                    *error = tooDeep ? CYLConfigurationTooDeepError(formatName)
                                     : CYLConfigurationSyntaxError(formatName, 0, @"invalid binary property list structure");
                }
                return nil;
            }
        } else {
            NSString *plistText = text ?: @"";
            BOOL isXML = [plistText rangeOfString:@"<plist"].location != NSNotFound || [CYLTrimmed(plistText) hasPrefix:@"<"];
            tooDeep = (isXML ? CYLXMLPropertyListDepth(plistText) : CYLBracketDepth(plistText)) > CYLTabBarConfigurationMaximumDepth;
        }
        if (tooDeep) {
            if (error) { *error = CYLConfigurationTooDeepError(formatName); }
            return nil;
        }
        result = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&parseError];
        if (!result && !CYLDataHasPrefix(data, "bplist")) {
            // A .strings file: `"key" = value;` pairs without the outer braces. .strings 文件：没有外层大括号的 `"key" = value;`。
            NSData *wrapped = text ? [[NSString stringWithFormat:@"{\n%@\n}", text] dataUsingEncoding:NSUTF8StringEncoding] : nil;
            id strings = wrapped ? [NSPropertyListSerialization propertyListWithData:wrapped options:NSPropertyListImmutable format:NULL error:NULL] : nil;
            if (strings) {
                result = strings;
                parseError = nil;
            }
        }
        if (!result) {
            parseError = CYLConfigurationSyntaxError(formatName, 0, parseError.localizedDescription ?: @"invalid property list");
        }
    } else if (format == CYLTabBarConfigurationFormatXML) {
        result = CYLDictionaryFromXML(data, &parseError);
    } else if (format == CYLTabBarConfigurationFormatProtobuf) {
        result = CYLDictionaryFromProtobuf(data, &parseError);
    } else {
        if (!text) {
            parseError = CYLConfigurationSyntaxError(formatName, 0, @"the file is not UTF-8 text");
        } else if (format == CYLTabBarConfigurationFormatJSON || format == CYLTabBarConfigurationFormatJSON5) {
            NSString *JSON = (format == CYLTabBarConfigurationFormatJSON5) ? CYLJSONFromJSON5(text) : text;
            if (CYLBracketDepth(JSON ?: @"") > CYLTabBarConfigurationMaximumDepth) {
                if (error) { *error = CYLConfigurationTooDeepError(formatName); }
                return nil;
            }
            NSData *JSONData = [JSON dataUsingEncoding:NSUTF8StringEncoding];
            result = JSONData ? [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&parseError] : nil;
            if (!result) {
                parseError = CYLConfigurationSyntaxError(formatName, 0, parseError.localizedDescription ?: @"invalid JSON");
            }
        } else if (format == CYLTabBarConfigurationFormatYAML) {
            CYLYAMLParser *parser = [[CYLYAMLParser alloc] initWithText:text];
            result = [parser parse];
            parseError = parser.error;
        } else if (format == CYLTabBarConfigurationFormatTOML) {
            CYLTOMLParser *parser = [[CYLTOMLParser alloc] init];
            parser.text = [[text stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"] stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
            result = [parser parse];
            parseError = parser.error;
        } else if (format == CYLTabBarConfigurationFormatINI) {
            result = CYLDictionaryFromINI(text, &parseError);
        } else if (format == CYLTabBarConfigurationFormatProperties) {
            result = CYLDictionaryFromProperties(text, &parseError);
        } else if (format == CYLTabBarConfigurationFormatProtobufText) {
            CYLTextProtoParser *parser = [[CYLTextProtoParser alloc] init];
            parser.text = text;
            result = [parser parseFieldsUntil:0];
            parseError = parser.error;
        }
    }
    if (!result) {
        if (error) {
            *error = parseError ?: CYLConfigurationSyntaxError(formatName, 0, @"invalid content");
        }
        return nil;
    }
    if ([result isKindOfClass:[NSDictionary class]] && [(NSDictionary *)result count] == 0) {
        if (error) {
            *error = CYLConfigurationError(CYLTabBarConfigurationErrorEmpty,
                                           [NSString stringWithFormat:@"%@ configuration: no key (only whitespace or comments).", formatName]);
        }
        return nil;
    }
    if (![result isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = CYLConfigurationError(CYLTabBarConfigurationErrorNotADictionary,
                                           [NSString stringWithFormat:@"%@ configuration: the top level must be a dictionary (key-value pairs).", formatName]);
        }
        return nil;
    }
    return result;
}

+ (NSDictionary<NSString *, id> *)dictionaryWithContentsOfFile:(NSString *)path error:(NSError **)error {
    BOOL isDirectory = NO;
    BOOL exists = path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory;
    unsigned long long size = exists ? [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL] fileSize] : 0;
    if (size > CYLTabBarConfigurationMaximumLength) {
        // Not read at all: a huge file never reaches memory. 完全不读取：超大文件不会进入内存。
        if (error) {
            *error = CYLConfigurationError(CYLTabBarConfigurationErrorTooLarge,
                                           [NSString stringWithFormat:@"\"%@\" is %llu bytes, more than the %lu allowed.",
                                            path.lastPathComponent, size, (unsigned long)CYLTabBarConfigurationMaximumLength]);
        }
        return nil;
    }
    NSData *data = exists ? [NSData dataWithContentsOfFile:path] : nil;
    if (!data) {
        if (error) {
            *error = CYLConfigurationError(CYLTabBarConfigurationErrorFileNotFound,
                                           [NSString stringWithFormat:@"No configuration file at \"%@\".", path ?: @""]);
        }
        return nil;
    }
    return [self dictionaryWithData:data format:[self formatForPathExtension:path.pathExtension] error:error];
}

@end
