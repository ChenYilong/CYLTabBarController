#!/usr/bin/env python3
"""Export the tab bar configurations written in code to configuration files.

[EN] Searches Objective-C and Swift sources for the tab bar item attributes (`CYLTabBarItemTitle : ...` dictionary
     literals, `CYLLocalizedTabBarItemsAttributes(...)`, `CYLTabBarItemsAttributesAddingLottieFiles(...)`, Lottie dark
     colors built with `.map`), the view controller classes and the initializer parameters (context, style type, image
     insets, title offset), and writes them as configuration files that `+[CYLTabBarController
     tabBarControllerWithConfigurationFile:error:]` reads. Values that only exist at runtime (variables, enums, method
     calls) cannot be read from the source: they are left out and listed in the report, so a file is never wrong, only
     incomplete. Python 3 standard library only.
[CN] 在 Objective-C 与 Swift 源码中查找 TabBarItem 属性（`CYLTabBarItemTitle : ...` 字典字面量、`CYLLocalizedTabBarItemsAttributes(...)`、
     `CYLTabBarItemsAttributesAddingLottieFiles(...)`、用 `.map` 生成的 Lottie 深色颜色）、子控制器类与初始化参数（context、样式、图片内边距、
     标题偏移），并写成 `+[CYLTabBarController tabBarControllerWithConfigurationFile:error:]` 可读取的配置文件。只在运行时才有的值
     （变量、枚举、方法调用）无法从源码读取：这些值不会写入，并在报告中列出，因此文件不会出错，只会不完整。仅使用 Python 3 标准库。

Usage 用法:
    python3 scripts/export-tabbar-configurations.py                      # every Example*/, JSON + YAML
    python3 scripts/export-tabbar-configurations.py --format all         # every format 所有格式
    python3 scripts/export-tabbar-configurations.py --format toml,binpb Example-Swift
    python3 scripts/export-tabbar-configurations.py --check              # exit 1 if a file is out of date 文件过期时返回 1
    python3 scripts/export-tabbar-configurations.py --stdout --format yaml path/to/MyTabBarController.m

Files are written to `<example>/Configurations/<source file name>.<extension>`.
文件写入 `<example>/Configurations/<源文件名>.<扩展名>`。
"""

import argparse
import json
import os
import plistlib
import re
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# [EN] Arguments may only name paths in the repository or the temporary folder. [CN] 参数只能指向仓库或临时目录内的路径。
ALLOWED_ROOTS = (ROOT, tempfile.gettempdir())


def confined_path(path, roots):
    """[EN] The real path of `path` when it lies inside one of `roots`, else exit: no path traversal from arguments.
    [CN] `path` 位于 `roots` 之一内时返回其真实路径，否则退出：防止通过参数进行路径穿越。"""
    real = os.path.realpath(path)
    for root in roots:
        root = os.path.realpath(root)
        if real == root or real.startswith(root + os.sep):
            return real
    sys.exit('%s: outside %s' % (path, ' / '.join(roots)))

ITEM_KEYS = [
    'CYLTabBarItemTitle', 'CYLTabBarItemImage', 'CYLTabBarItemSelectedImage', 'CYLTabBarItemDarkImage',
    'CYLTabBarItemSelectedDarkImage', 'CYLTabBarItemImageURL', 'CYLTabBarItemSelectedImageURL',
    'CYLTabBarItemImageURLSize', 'CYLTabBarItemImageInsets', 'CYLTabBarItemTitlePositionAdjustment',
    'CYLTabBarItemImagePositionAdjustment', 'CYLTabBarLottieFilePath', 'CYLTabBarLottieURL', 'CYLTabBarLottieSize',
    'CYLTabBarItemIdentifier', 'CYLTabBarLottieDarkURL', 'CYLTabBarLottieDarkFilePath', 'CYLTabBarLottieDarkColors',
    'CYLTabBarItemViewControllerClass', 'CYLTabBarItemNavigationControllerClass', 'CYLTabBarItemSelectedTitle',
    'CYLTabBarItemTitleColor', 'CYLTabBarItemSelectedTitleColor', 'CYLTabBarItemIconColor', 'CYLTabBarItemSelectedIconColor',
    'CYLTabBarItemSelectedBackgroundColor', 'CYLTabBarItemBackgroundColor', 'CYLTabBarItemTitleFont', 'CYLTabBarItemSelectedTitleFont',
    'CYLTabBarItemAccessibilityIdentifier', 'CYLTabBarItemAccessibilityLabel', 'CYLTabBarItemAccessibilityHint',
]
ITEMS_KEY = 'CYLTabBarControllerTabBarItemsAttributes'
TOP_KEYS = ['CYLTabBarControllerContext', 'CYLTabBarControllerStyleType', 'CYLTabBarControllerImageInsets',
            'CYLTabBarControllerTitlePositionAdjustment', 'CYLTabBarControllerNavigationControllerClass']
STYLE_NAMES = {'Default': 'default', 'System': 'system', 'FlatDesign': 'flatDesign', 'LiquidGlass': 'liquidGlass',
               'default': 'default', 'system': 'system', 'flatDesign': 'flatDesign', 'liquidGlass': 'liquidGlass'}
# Field numbers of cyl_tabbar_configuration.proto. cyl_tabbar_configuration.proto 的字段编号。
PROTO_TOP = {ITEMS_KEY: 1, 'CYLTabBarControllerImageInsets': 2, 'CYLTabBarControllerTitlePositionAdjustment': 3,
             'CYLTabBarControllerStyleType': 4, 'CYLTabBarControllerContext': 5,
             'CYLTabBarControllerNavigationControllerClass': 6}
PROTO_ITEM = {key: number for number, key in enumerate(ITEM_KEYS[:17], 1)}
PROTO_ITEM.update({'CYLTabBarLottieDarkColors': 18, 'CYLTabBarItemViewControllerClass': 19,
                   'CYLTabBarItemNavigationControllerClass': 20, 'CYLTabBarItemSelectedTitle': 21})
PROTO_ITEM.update({key: number for number, key in enumerate(ITEM_KEYS[ITEM_KEYS.index('CYLTabBarItemTitleColor'):], 22)})
# [EN] Repeated literals. [CN] 重复使用的字面量。
BINARY_PLIST = 'binary.plist'
JSON_EXTENSION = '.json'
ASSIGNMENT_FORMAT = '%s = %s'
FORMATS = ['json', 'json5', 'plist', BINARY_PLIST, 'yaml', 'toml', 'ini', 'properties', 'env', 'xml', 'textproto',
           'binpb']


# ---------------------------------------------------------------------------------------------------------------------
# Source scanning 源码扫描

def string_end(text, i, stop_at_newline=False):
    """[EN] Index of the quote closing the string literal that starts at `i` (or of the end of the line / text).
    [CN] 关闭从 `i` 开始的字符串字面量的引号位置（或行尾 / 文本结尾）。"""
    j, n = i + 1, len(text)
    while j < n and text[j] != '"' and not (stop_at_newline and text[j] == '\n'):
        j += 2 if text[j] == '\\' else 1
    return j


def comment_end(text, i):
    """[EN] End of the // or /* */ comment starting at `i`, else None. [CN] 从 `i` 开始的注释的结尾，否则为 None。"""
    if text.startswith('//', i):
        j = text.find('\n', i)
        return len(text) if j < 0 else j
    if text.startswith('/*', i):
        j = text.find('*/', i + 2)
        return len(text) if j < 0 else j + 2
    return None


def strip_comments(text):
    """Removes // and /* */ comments outside string literals. 移除字符串之外的 // 与 /* */ 注释。"""
    out, i, n = [], 0, len(text)
    while i < n:
        if text[i] == '"':
            j = string_end(text, i, stop_at_newline=True)
            out.append(text[i:j + 1])
            i = j + 1
            continue
        end = comment_end(text, i)
        if end is None:
            out.append(text[i])
            i += 1
        else:
            i = end
    return ''.join(out)


def matching(text, i):
    """Index of the bracket closing the one at `i`, skipping strings. 跳过字符串，返回与 `i` 处括号匹配的位置。"""
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack, n = [], len(text)
    while i < n:
        c = text[i]
        if c == '"':
            i = string_end(text, i)
        elif c in pairs:
            stack.append(pairs[c])
        elif c in ')]}':
            if not stack or stack.pop() != c:
                return -1
            if not stack:
                return i
        i += 1
    return -1


def split_top(text, separator=','):
    """Splits at `separator` outside brackets and strings. 在括号与字符串之外按 `separator` 拆分。"""
    parts, depth, start, i, n = [], 0, 0, 0, len(text)
    while i < n:
        c = text[i]
        if c == '"':
            i = string_end(text, i)
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        elif c == separator and depth == 0:
            parts.append(text[start:i])
            start = i + 1
        i += 1
    parts.append(text[start:])
    return [p.strip() for p in parts if p.strip()]


def split_key_value(entry):
    """`key : value` at the first top-level colon (not `::` or `?:`). 在第一个顶层冒号处拆分 `key : value`。"""
    depth, i = 0, 0
    while i < len(entry):
        c = entry[i]
        if c == '"':
            i = string_end(entry, i)
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        elif c == ':' and depth == 0:
            return entry[:i].strip(), entry[i + 1:].strip()
        i += 1
    return None, None


STRING = r'@?"((?:[^"\\]|\\.)*)"'
NUMBER_EXPR = re.compile(r'^[\d\s.+\-*/()]+$')


def unescape(s):
    return s.encode('utf-8').decode('unicode_escape').encode('latin-1').decode('utf-8') if '\\' in s else s


def number(expr):
    """A number from a literal arithmetic expression, e.g. `-3.5` or `(-25+2)/2`; None otherwise.
    字面量算术表达式的值，例如 `-3.5`、`(-25+2)/2`；否则为 None。"""
    expr = expr.strip().rstrip('f')
    if not expr or not NUMBER_EXPR.match(expr):
        return None
    try:
        value = eval(expr, {'__builtins__': {}}, {})  # digits and operators only 仅数字与运算符
    except Exception:
        return None
    return int(value) if float(value).is_integer() else round(float(value), 4)


def numbers(args, count):
    values = [number(re.sub(r'^\w+\s*:', '', a)) for a in split_top(args)]
    return values if len(values) == count and None not in values else None


def fmt_numbers(values):
    return '{' + ', '.join(str(v) for v in values) + '}'


def hex_color(r, g, b, a):
    return '#' + ''.join('%02X' % max(0, min(255, round(v * 255))) for v in (r, g, b, a))


# UIKit's fixed colors (the dynamic system colors follow Dark Mode and stay in code). UIKit 的固定颜色（动态系统颜色随深色模式变化，保留在代码中）。
NAMED_COLORS = {'black': '#000000FF', 'white': '#FFFFFFFF', 'clear': '#00000000', 'red': '#FF0000FF', 'green': '#00FF00FF',
                'blue': '#0000FFFF', 'gray': '#808080FF', 'darkGray': '#555555FF', 'lightGray': '#AAAAAAFF',
                'yellow': '#FFFF00FF', 'orange': '#FF8000FF', 'purple': '#800080FF', 'brown': '#996633FF',
                'cyan': '#00FFFFFF', 'magenta': '#FF00FFFF'}


class Unresolved(Exception):
    pass


# [EN] Returned by an evaluator that does not recognize the expression. [CN] 求值函数无法识别表达式时的返回值。
NOT_MATCHED = object()
BUNDLE = r'\[NSBundle\s+mainBundle\]'
# (Objective-C selector, function, Swift label, initializer, number of values) of the NSValue geometry.
# NSValue 几何值的（Objective-C 选择子，函数，Swift 标签，初始化方法，数值个数）。
GEOMETRY = (('valueWithUIOffset', 'UIOffsetMake', 'uiOffset', 'UIOffset', 2),
            ('valueWithUIEdgeInsets', 'UIEdgeInsetsMake', 'uiEdgeInsets', 'UIEdgeInsets', 4),
            ('valueWithCGSize', 'CGSizeMake', 'cgSize', 'CGSize', 2))
# (bold, Objective-C selector parts, Swift function, Swift labels) of the system fonts. 系统字体的参数。
SYSTEM_FONTS = ((False, ['systemFontOfSize', 'weight'], 'UIFont.systemFont', ['ofSize', 'weight']),
                (False, ['systemFontOfSize'], 'UIFont.systemFont', ['ofSize']),
                (True, ['boldSystemFontOfSize'], 'UIFont.boldSystemFont', ['ofSize']))


def string_value(expr):
    """The text of a string literal (`@"..."` or `"..."`), else None. 字符串字面量的内容，否则为 None。"""
    m = re.fullmatch(STRING, expr.strip())
    return unescape(m.group(1)) if m else None


def call_inside(expr, callee):
    """The text inside `callee(...)`, else None. `callee(...)` 括号内的文本，否则为 None。"""
    e = expr.strip()
    if e.startswith(callee + '(') and matching(e, len(callee)) == len(e) - 1:
        return e[len(callee) + 1:-1]
    return None


def message_arguments(e, receiver, parts):
    """[EN] The arguments of the Objective-C message `[receiver part0:a part1:b]`, else None (no backtracking regex).
    [CN] Objective-C 消息 `[receiver part0:a part1:b]` 的参数，否则为 None（不使用会回溯的正则）。"""
    m = re.match(r'\[' + receiver + r'\s+', e)
    if not m or matching(e, 0) != len(e) - 1:
        return None
    rest, values = e[m.end():-1], []
    for index, part in enumerate(parts):
        if not rest.startswith(part + ':'):
            return None
        rest = rest[len(part) + 1:]
        if index + 1 == len(parts):
            values.append(rest.strip())
            break
        following = re.search(r'\s' + parts[index + 1] + ':', rest)
        if not following:
            return None
        values.append(rest[:following.start()].strip())
        rest = rest[following.start():].lstrip()
    return values


def call_arguments(e, callee, labels):
    """[EN] The arguments of the Swift call `callee(label0: a, label1: b)`, else None.
    [CN] Swift 调用 `callee(label0: a, label1: b)` 的参数，否则为 None。"""
    inside = call_inside(e, callee)
    if inside is None:
        return None
    arguments = split_top(inside)
    if len(arguments) != len(labels):
        return None
    values = []
    for argument, label in zip(arguments, labels):
        key, value = split_key_value(argument)
        if key != label:
            return None
        values.append(value)
    return values


def arguments_of(e, objc, swift):
    """Arguments of the Objective-C message `objc` = (receiver, parts) or the Swift call `swift` = (callee, labels)."""
    values = message_arguments(e, *objc)
    return values if values is not None else call_arguments(e, *swift)


def evaluate_string(e):
    value = string_value(e)
    return NOT_MATCHED if value is None else value


def evaluate_localized(e):
    """The key of `CYLLocalizedString("key")` / `NSLocalizedString("key", ...)`. 本地化 key。"""
    for callee in ('CYLLocalizedString', 'NSLocalizedString'):
        inside = call_inside(e, callee)
        arguments = split_top(inside) if inside is not None else []
        value = string_value(arguments[0]) if arguments else None
        if value is not None:
            return value
    return NOT_MATCHED


def evaluate_scalar(e):
    value = number(e)
    if value is not None:
        return value
    if e in ('YES', 'true', '@YES'):
        return True
    if e in ('NO', 'false', '@NO'):
        return False
    return NOT_MATCHED


def evaluate_image(e):
    values = arguments_of(e, ('UIImage', ['imageNamed']), ('UIImage', ['named']))
    name = string_value(values[0]) if values else None
    if name is not None:
        return name
    values = arguments_of(e, ('UIImage', ['systemImageNamed']), ('UIImage', ['systemName']))
    name = string_value(values[0]) if values else None
    return NOT_MATCHED if name is None else 'system:' + name


def evaluate_resource(e):
    """`[[NSBundle mainBundle] pathForResource:ofType:]`, `Bundle.main.url(forResource:withExtension:)`... -> "name.ext"."""
    for parts, swift in ((['pathForResource', 'ofType'], ('Bundle.main.path', ['forResource', 'ofType'])),
                         (['URLForResource', 'withExtension'], ('Bundle.main.url', ['forResource', 'withExtension']))):
        values = arguments_of(e, (BUNDLE, parts), swift)
        names = [string_value(v) for v in values] if values else [None]
        if None not in names:
            return '%s.%s' % tuple(names)
    return NOT_MATCHED


def evaluate_url(e):
    values = arguments_of(e, ('NSURL', ['fileURLWithPath']), ('URL', ['fileURLWithPath']))
    if values:
        return evaluate(values[0])
    values = arguments_of(e, ('NSURL', ['URLWithString']), ('URL', ['string']))
    url = string_value(values[0]) if values else None
    return NOT_MATCHED if url is None else url


def evaluate_geometry(e):
    """NSValue offsets, edge insets and sizes -> "{a, b}". NSValue 偏移、边距与尺寸。"""
    for selector, function, label, initializer, count in GEOMETRY:
        objc = message_arguments(e, 'NSValue', [selector])
        swift = call_arguments(e, 'NSValue', [label])
        inside = call_inside(objc[0], function) if objc else (call_inside(swift[0], initializer) if swift else None)
        values = numbers(inside, count) if inside is not None else None
        if values:
            return fmt_numbers(values)
    return NOT_MATCHED


def evaluate_color(e):
    values = arguments_of(e, ('UIColor', ['colorWithWhite', 'alpha']), ('UIColor', ['white', 'alpha']))
    if values:
        white, alpha = number(values[0]), number(values[1])
        if white is not None and alpha is not None:
            return hex_color(white, white, white, alpha)
    values = arguments_of(e, ('UIColor', ['colorWithRed', 'green', 'blue', 'alpha']),
                          ('UIColor', ['red', 'green', 'blue', 'alpha']))
    components = [number(v) for v in values] if values else [None]
    if None not in components:
        return hex_color(*components)
    m = re.fullmatch(r'\[UIColor\s+(\w+)Color\]|UIColor\.(\w+)', e)
    name = (m.group(1) or m.group(2)) if m else ''
    if m and m.group(2) and name.endswith('Color') and len(name) > len('Color'):
        name = name[:-len('Color')]
    return NAMED_COLORS.get(name, NOT_MATCHED)


def font_weight_name(weight):
    """`UIFontWeightBold`, `.bold` or `UIFont.Weight.bold` -> `bold`."""
    return weight.strip().replace('UIFontWeight', '').split('.')[-1].lower()


def evaluate_font(e):
    """System fonts -> a size or "weight:size"; named fonts -> "Name:size". 系统字体与命名字体。"""
    for bold, parts, callee, labels in SYSTEM_FONTS:
        values = arguments_of(e, ('UIFont', parts), (callee, labels))
        size = number(values[0]) if values else None
        if size is None:
            continue
        weight = 'bold' if bold else (font_weight_name(values[1]) if len(values) > 1 else '')
        return '%s:%s' % (weight, size) if weight and weight != 'regular' else size
    values = arguments_of(e, ('UIFont', ['fontWithName', 'size']), ('UIFont', ['name', 'size']))
    name, size = (string_value(values[0]), number(values[1])) if values else (None, None)
    if name is not None and size is not None:
        return '%s:%s' % (name, size)
    return NOT_MATCHED


def evaluate_dictionary(e, expr):
    if not (e.startswith('@{') or (e.startswith('[') and ':' in e and not e.startswith('[['))):
        return NOT_MATCHED
    body = e[2:-1] if e.startswith('@{') else e[1:-1]
    result = {}
    for entry in split_top(body):
        key, value = split_key_value(entry)
        if key is None:
            raise Unresolved(expr)
        result[str(evaluate(key))] = evaluate(value)
    return result


EVALUATORS = (evaluate_string, evaluate_localized, evaluate_scalar, evaluate_image, evaluate_resource, evaluate_url,
              evaluate_geometry, evaluate_color, evaluate_font)


def evaluate(expr):
    """The configuration value of an Objective-C / Swift expression, or raises Unresolved.
    Objective-C / Swift 表达式对应的配置值，无法解析时抛出 Unresolved。"""
    e = expr.strip()
    while e.endswith(('!', '?')):
        e = e[:-1].strip()
    for evaluator in EVALUATORS:
        value = evaluator(e)
        if value is not NOT_MATCHED:
            return value
    value = evaluate_dictionary(e, expr)
    if value is NOT_MATCHED:
        raise Unresolved(expr)
    return value


def tab_entries(body):
    """{item key: expression} of a dictionary literal's body. 字典字面量内容中的 {item 键: 表达式}。"""
    entries = {}
    for entry in split_top(body):
        key, value = split_key_value(entry)
        if key in ITEM_KEYS:
            entries[key] = value
        elif key is not None and key.strip().startswith('CYLTabBar'):
            entries.setdefault('__unknown__', []).append(key)
    return entries


def assigned_name(head):
    """[EN] The variable of `NSDictionary *name =` or `let name: Type =` at the end of `head`, else None.
    [CN] `head` 末尾 `NSDictionary *name =` 或 `let name: Type =` 中的变量名，否则为 None。"""
    head = head.rstrip()
    if not head.endswith('='):
        return None
    left = head[:-1].rstrip()
    index = left.rfind('NSDictionary')
    m = re.fullmatch(r'NSDictionary(?:\s*<[^>]*>)?\s*\*\s*(\w+)', left[index:]) if index >= 0 else None
    if m:
        return m.group(1)
    declaration = None
    for declaration in re.finditer(r'(?:let|var)\s+(\w+)', left):
        pass
    rest = left[declaration.end():].strip() if declaration else None
    if rest is not None and (not rest or (len(rest) > 1 and rest.startswith(':') and '=' not in rest)):
        return declaration.group(1)
    return None


def dictionary_literals(code):
    """(position, variable name or None, {key: expression}) of every dictionary literal with item keys.
    含有 item 键的每个字典字面量：(位置, 变量名或 None, {键: 表达式})。"""
    found = []
    for m in re.finditer(r'@\{|\[', code):
        start = m.start() + (1 if m.group() == '@{' else 0)
        end = matching(code, start)
        if end < 0:
            continue
        entries = tab_entries(code[start + 1:end])
        if any(k in ITEM_KEYS for k in entries):
            found.append((m.start(), assigned_name(code[max(0, m.start() - 120):m.start()]), entries))
    return found


def element_positions(code, start, elements, by_position):
    """Positions of an array literal's elements when all are tab dictionaries, else None. 元素全部为 Tab 字典时的位置。"""
    positions, offset = [], start + 1
    for element in elements:
        index = code.find(element, offset)
        if not element.startswith(('@{', '[')) or index not in by_position:
            return None
        positions.append(index)
        offset = index + len(element)
    return positions


def inline_array_items(code, literals):
    """The tabs of the longest array literal whose elements are all tab dictionaries, e.g. `@[ @{...}, @{...} ]`.
    元素全部为 Tab 字典的最长数组字面量中的 Tab。"""
    by_position = {position: entries for position, _, entries in literals}
    best = []
    for m in re.finditer(r'@\[|\[', code):
        start = m.start() + (1 if m.group() == '@[' else 0)
        end = matching(code, start)
        if end < 0:
            continue
        positions = element_positions(code, start, split_top(code[start + 1:end]), by_position)
        if positions and len(positions) > len(best):
            best = [by_position[p] for p in positions]
    return best


def items_from_helpers(code, report):
    """Items built by `CYLLocalizedTabBarItemsAttributes(titles, images, selectedImages, darkImages)`.
    由 `CYLLocalizedTabBarItemsAttributes(...)` 生成的 item。"""
    m = re.search(r'CYLLocalizedTabBarItemsAttributes\(', code)
    if not m:
        return None
    end = matching(code, m.end() - 1)
    args = split_top(code[m.end():end])
    try:
        lists = [evaluate_list(a) for a in args[:3]]
        dark = evaluate_index_map(args[3]) if len(args) > 3 else {}
    except Unresolved as error:
        report.append('CYLLocalizedTabBarItemsAttributes: not a literal (%s)' % short(str(error)))
        return None
    items = []
    for i, title in enumerate(lists[0]):
        item = {'CYLTabBarItemTitle': title}
        if i < len(lists[1]):
            item['CYLTabBarItemImage'] = lists[1][i]
        if i < len(lists[2]):
            item['CYLTabBarItemSelectedImage'] = lists[2][i]
        if i in dark:
            item['CYLTabBarItemDarkImage'] = dark[i]
        items.append(item)
    return items


def evaluate_list(expr):
    e = expr.strip()
    if e.startswith('@['):
        e = e[1:]
    if not (e.startswith('[') and e.endswith(']')):
        raise Unresolved(expr)
    return [evaluate(x) for x in split_top(e[1:-1])]


def evaluate_index_map(expr):
    e = expr.strip()
    if e in ('nil', '[:]', '@{}'):
        return {}
    value = evaluate(e if e.startswith(('@{', '[')) else '[' + e + ']')
    return {int(k): v for k, v in value.items()}


def add_lottie_files(code, items, report):
    """`CYLTabBarItemsAttributesAddingLottieFiles(items, names, nil)`: "<name>.json", and "<name>_dark.json" when it exists."""
    m = re.search(r'CYLTabBarItemsAttributesAddingLottieFiles\(', code)
    if not m:
        return
    end = matching(code, m.end() - 1)
    args = split_top(code[m.end():end])
    try:
        names = evaluate_list(args[1])
    except (Unresolved, IndexError):
        report.append('CYLTabBarItemsAttributesAddingLottieFiles: names are not a literal list')
        return
    resources = set()
    for _, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in ('.git', 'Pods', 'docs', 'Configurations')]
        resources.update(f for f in files if f.endswith(JSON_EXTENSION))
    for item, name in zip(items, names):
        if name + JSON_EXTENSION in resources:
            item['CYLTabBarLottieFilePath'] = name + JSON_EXTENSION
            if name + '_dark' + JSON_EXTENSION in resources:
                item['CYLTabBarLottieDarkFilePath'] = name + '_dark' + JSON_EXTENSION
        else:
            report.append('Lottie file %s.json is not in the example; skipped' % name)


def skip_space_left(code, j):
    while j >= 0 and code[j].isspace():
        j -= 1
    return j


def string_list_before(code, end):
    """[EN] The plain string literals of the list `["A", "B"]` closed by the "]" at `end`, read backwards; else None.
    [CN] 由 `end` 处 "]" 结束的字符串列表 `["A", "B"]` 中的字符串（向前读取），否则为 None。"""
    j = skip_space_left(code, end - 1)
    if j >= 0 and code[j] == ',':
        j -= 1
    elements = []
    while True:
        j = skip_space_left(code, j)
        k = code.rfind('"', 0, j) if j >= 0 and code[j] == '"' else -1
        if k < 0:
            return None
        elements.append(code[k + 1:j])
        j = skip_space_left(code, k - 1)
        if j >= 0 and code[j] == '[':
            return elements[::-1]
        if j < 0 or code[j] != ',':
            return None
        j -= 1


def dark_color_map(code):
    """[EN] (layer names, variable, position after `in`) of the first `["A", "B"].map { layer in`, else None.
    Each `].map {` is read backwards once, so the scan runs in linear time.
    [CN] 第一个 `["A", "B"].map { layer in` 的（图层名，变量，`in` 之后的位置），否则为 None；每个 `].map {` 只向前读取一次，线性时间。"""
    for closure in re.finditer(r'\]\s*\.map\s*\{\s*(\w+)', code):
        layers = string_list_before(code, closure.start())
        if not layers:
            continue
        keyword = re.compile(r'\s+in\s').match(code, closure.end()) or re.compile(r'\s*->[^{]*?\bin\s').match(code, closure.end())
        if keyword:
            return layers, closure.group(1), keyword.end()
    return None


def add_dark_colors(code, items, report):
    """Swift `["A", "B"].map { layer in ["\\(layer)_Suffix": UIColor(...)] }` used for `CYLTabBarLottieDarkColors`."""
    if 'CYLTabBarLottieDarkColors' not in code:
        return
    found = dark_color_map(code)
    if not found:
        report.append('CYLTabBarLottieDarkColors: built at runtime; skipped')
        return
    layers, variable, position = found
    start = code.index('[', position)
    end = matching(code, start)
    body = code[start + 1:end]
    try:
        template = {}
        for entry in split_top(body):
            key, value = split_key_value(entry)
            template[key] = evaluate(value)
    except Unresolved as error:
        report.append('CYLTabBarLottieDarkColors: %s' % short(str(error)))
        return
    for item, layer in zip(items, layers):
        colors = {}
        for key, color in template.items():
            k = key.strip().strip('"').replace('\\(%s)' % variable, layer)
            colors[k] = color
        item['CYLTabBarLottieDarkColors'] = colors


def view_controller_classes(code):
    """Content view controller classes in order, and the navigation controller class.
    按顺序列出内容子控制器类，以及导航控制器类。"""
    classes = []
    for m in re.finditer(r'\[\[(\w+)\s+alloc\]\s+init\]|\b([A-Z]\w*(?:ViewController|Controller))\(\)', code):
        name = m.group(1) or m.group(2)
        if 'Navigation' in name or 'TabBarController' in name or 'Alert' in name:
            continue
        if name.endswith('Controller') and name not in classes:
            classes.append(name)
    # [EN] Any class, then keep the navigation controllers (a linear regex). [CN] 先匹配任意类，再保留导航控制器（线性正则）。
    navigation = re.findall(r'\[\[(\w+)\s+alloc\]\s+initWithRootViewController:|\b(\w+)\(rootViewController:', code)
    navigation = [a or b for a, b in navigation if 'Navigation' in (a or b)]
    return classes, (max(set(navigation), key=navigation.count) if navigation else None)


def top_level(code):
    top = {}
    m = re.findall(r'context:\s*' + STRING, code)
    if m:
        top['CYLTabBarControllerContext'] = unescape(m[-1])
    styles = re.findall(r'(?:[Ss]tyle(?:Type)?\s*=(?!=)|[Ss]tyle(?:Type)?:)\s*CYLTabBarStyleType(\w+)\b'
                        r'|(?:[Ss]tyle(?:Type)?\s*=(?!=)|[Ss]tyleType:)\s*\.(\w+)', code)
    if styles:
        a, b = styles[-1]
        style = STYLE_NAMES.get(a or b)
        if style:
            top['CYLTabBarControllerStyleType'] = style
    m = re.findall(r'titlePositionAdjustment\s*=\s*(?:UIOffsetMake|UIOffset)\(([^)]*)\)', code)
    if m:
        values = numbers(m[-1], 2)
        if values and any(values):
            top['CYLTabBarControllerTitlePositionAdjustment'] = fmt_numbers(values)
    m = re.findall(r'imageInsets\s*=\s*(?:UIEdgeInsetsMake|UIEdgeInsets)\(([^)]*)\)', code)
    if m:
        values = numbers(m[-1], 4)
        if values and any(values):
            top['CYLTabBarControllerImageInsets'] = fmt_numbers(values)
    return top


def short(text, limit=70):
    text = ' '.join(text.split())
    return text if len(text) <= limit else text[:limit - 1] + '…'


# [EN] A tab needs one of these to be shown. [CN] Tab 至少需要其中之一才能显示。
VISIBLE_KEYS = ('CYLTabBarItemTitle', 'CYLTabBarItemImage', 'CYLTabBarItemSelectedImage', 'CYLTabBarLottieFilePath',
                'CYLTabBarLottieURL', 'CYLTabBarItemImageURL')


def literal_order(code, by_name):
    """[EN] The names of the last array literal `@[a, b, c]` (two or more) whose elements are all named tab dictionaries.
    [CN] 最后一个元素全部为具名 Tab 字典的数组字面量 `@[a, b, c]`（至少两个）中的变量名。"""
    order = None
    for m in re.finditer(r'\[([\w\s,]+)\]', code):
        names = [n.strip() for n in m.group(1).split(',')]
        if names and not names[-1]:
            names.pop()
        if len(names) >= 2 and all(n in by_name for n in names):
            order = names
    return order


def evaluated_item(entries, report):
    item = {}
    for key, expr in entries.items():
        if key == '__unknown__':
            report.append('unknown keys: %s' % ', '.join(expr))
            continue
        try:
            item[key] = evaluate(expr)
        except Unresolved:
            report.append('%s: only known at runtime; left out' % (ASSIGNMENT_FORMAT % (key, short(expr))))
    return item


def items_from_literals(code, literals, report):
    """The tabs written as dictionary literals. 以字典字面量编写的 Tab。"""
    by_name = {name: entries for _, name, entries in literals if name}
    order = literal_order(code, by_name)
    chosen = [by_name[n] for n in order] if order else inline_array_items(code, literals) or [entries for _, _, entries in literals]
    items = []
    for entries in chosen:
        item = evaluated_item(entries, report)
        if any(k in item for k in VISIBLE_KEYS):
            items.append(item)
        else:
            report.append('a tab with no literal title or icon (built at runtime); left out')
    return items


def add_view_controller_classes(code, items, configuration, report):
    classes, navigation = view_controller_classes(code)
    if classes and len(classes) == len(items):
        for item, name in zip(items, classes):
            item.setdefault('CYLTabBarItemViewControllerClass', name)
        if navigation:
            configuration['CYLTabBarControllerNavigationControllerClass'] = navigation
    elif classes:
        report.append('view controller classes not matched to the tabs (%d classes, %d tabs); left out' % (len(classes), len(items)))
    else:
        report.append('view controller classes are created elsewhere; tabs use UIViewController')


def extract(path):
    """The configuration of one source file, and the report of what could not be read."""
    code = strip_comments(open(path, encoding='utf-8').read())
    report = []
    literals = dictionary_literals(code)
    items = items_from_helpers(code, report)
    if items is None:
        items = items_from_literals(code, literals, report)
    if not items:
        report.append('no tab could be read from the source: the tabs are built at runtime')
        return None, report
    add_lottie_files(code, items, report)
    add_dark_colors(code, items, report)
    configuration = top_level(code)
    add_view_controller_classes(code, items, configuration, report)
    configuration[ITEMS_KEY] = items
    return configuration, report


def sources(paths):
    """Source files that define tab bar item attributes. 定义了 TabBarItem 属性的源文件。"""
    for base in paths:
        files = [base] if os.path.isfile(base) else [os.path.join(d, f) for d, _, fs in os.walk(base) for f in fs]
        for path in sorted(files):
            if not path.endswith(('.m', '.swift')) or 'Tests' in path or '/Pods/' in path:
                continue
            text = open(path, encoding='utf-8', errors='replace').read()
            if re.search(r'CYLTabBarItemTitle\s*:|CYLLocalizedTabBarItemsAttributes\(', strip_comments(text)):
                yield path


# ---------------------------------------------------------------------------------------------------------------------
# Writers 输出

def quote(s):
    return json.dumps(s, ensure_ascii=False)


def scalar(v):
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return str(v)
    return quote(v)


def ordered(configuration):
    top = [(k, configuration[k]) for k in TOP_KEYS if k in configuration]
    return top, configuration[ITEMS_KEY]


def write_yaml(c):
    top, items = ordered(c)
    lines = ['%s: %s' % (k, scalar(v)) for k, v in top] + [ITEMS_KEY + ':']
    for item in items:
        prefix = '  - '
        for k, v in item.items():
            if isinstance(v, dict):
                lines.append('%s%s:' % (prefix, k))
                lines += ['      %s: %s' % (quote(kk), scalar(vv)) for kk, vv in v.items()]
            else:
                lines.append('%s%s: %s' % (prefix, k, scalar(v)))
            prefix = '    '
    return '\n'.join(lines) + '\n'


def write_json5(c):
    top, items = ordered(c)
    def s(v):
        return "'%s'" % str(v).replace('\\', '\\\\').replace("'", "\\'") if isinstance(v, str) else scalar(v)
    lines = ['{'] + ['  %s: %s,' % (k, s(v)) for k, v in top] + ['  %s: [' % ITEMS_KEY]
    for item in items:
        lines.append('    {')
        for k, v in item.items():
            if isinstance(v, dict):
                lines.append('      %s: { %s },' % (k, ', '.join('%s: %s' % (s(kk), s(vv)) for kk, vv in v.items())))
            else:
                lines.append('      %s: %s,' % (k, s(v)))
        lines.append('    },')
    return '\n'.join(lines + ['  ],', '}']) + '\n'


def write_toml(c):
    top, items = ordered(c)
    lines = [ASSIGNMENT_FORMAT % (k, scalar(v)) for k, v in top]
    for item in items:
        lines += ['', '[[%s]]' % ITEMS_KEY]
        for k, v in item.items():
            if isinstance(v, dict):
                lines.append('%s = { %s }' % (k, ', '.join(ASSIGNMENT_FORMAT % (quote(kk), scalar(vv)) for kk, vv in v.items())))
            else:
                lines.append(ASSIGNMENT_FORMAT % (k, scalar(v)))
    return '\n'.join(lines) + '\n'


def flat_value(v):
    text = scalar(v) if isinstance(v, bool) else str(v)
    return quote(text) if text != text.strip() or text == '' else text


def write_ini(c):
    top, items = ordered(c)
    lines = [ASSIGNMENT_FORMAT % (k, flat_value(v)) for k, v in top]
    for i, item in enumerate(items):
        lines += ['', '[%s.%d]' % (ITEMS_KEY, i)]
        for k, v in item.items():
            if isinstance(v, dict):
                lines += ['%s.%s = %s' % (k, quote(kk), flat_value(vv)) for kk, vv in v.items()]
            else:
                lines.append(ASSIGNMENT_FORMAT % (k, flat_value(v)))
    return '\n'.join(lines) + '\n'


def write_properties(c, separator='.', assign=' = ', prefix=''):
    top, items = ordered(c)
    lines = ['%s%s%s%s' % (prefix, k, assign, flat_value(v)) for k, v in top]
    for i, item in enumerate(items):
        base = '%s%s%d%s' % (ITEMS_KEY, separator, i, separator)
        for k, v in item.items():
            if isinstance(v, dict):
                lines += ['%s%s%s%s%s' % (base, k, separator, quote(kk), assign + flat_value(vv)) for kk, vv in v.items()]
            else:
                lines.append('%s%s%s%s' % (base, k, assign, flat_value(v)))
    return '\n'.join(lines) + '\n'


def xml_text(s):
    return str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')


def write_xml(c):
    top, items = ordered(c)
    lines = ['<?xml version="1.0" encoding="UTF-8"?>', '<CYLTabBarController>']
    lines += ['    <%s>%s</%s>' % (k, xml_text(v), k) for k, v in top]
    lines.append('    <%s>' % ITEMS_KEY)
    for item in items:
        lines.append('        <item>')
        for k, v in item.items():
            if isinstance(v, dict):
                # Keypaths are not element names: key / value entries. keypath 不能作为元素名：使用 key / value 条目。
                lines.append('            <%s>' % k)
                lines += ['                <item key="%s" value="%s"/>' % (xml_text(kk), xml_text(vv)) for kk, vv in v.items()]
                lines.append('            </%s>' % k)
            else:
                lines.append('            <%s type="string">%s</%s>' % (k, xml_text(v), k))
        lines.append('        </item>')
    return '\n'.join(lines + ['    </%s>' % ITEMS_KEY, '</CYLTabBarController>']) + '\n'


def write_textproto(c):
    top, items = ordered(c)
    lines = ['# proto-file: cyl_tabbar_configuration.proto', '# proto-message: cyl.CYLTabBarConfiguration']
    lines += ['%s: %s' % (k, quote(str(v))) for k, v in top]
    for item in items:
        lines.append('%s {' % ITEMS_KEY)
        for k, v in item.items():
            if isinstance(v, dict):
                lines += ['  %s { key: %s value: %s }' % (k, quote(kk), quote(str(vv))) for kk, vv in v.items()]
            else:
                lines.append('  %s: %s' % (k, quote(str(v))))
        lines.append('}')
    return '\n'.join(lines) + '\n'


def varint(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        out.append(b | (0x80 if n else 0))
        if not n:
            return bytes(out)


def field(number, payload):
    return varint(number << 3 | 2) + varint(len(payload)) + payload


def item_message(item, report):
    """The bytes of one cyl.CYLTabBarItem message. 一个 cyl.CYLTabBarItem 消息的字节。"""
    body = bytearray()
    for k, v in item.items():
        if k not in PROTO_ITEM:
            report.append('%s has no protobuf field; left out of .binpb' % k)
        elif isinstance(v, dict):
            for kk, vv in v.items():
                body += field(PROTO_ITEM[k], field(1, str(kk).encode()) + field(2, str(vv).encode()))
        else:
            body += field(PROTO_ITEM[k], (scalar(v) if isinstance(v, bool) else str(v)).encode())
    return bytes(body)


def write_binpb(c, report):
    """A binary cyl.CYLTabBarConfiguration message (proto3: every value is a string). 二进制消息（每个值都是字符串）。"""
    top, items = ordered(c)
    out = bytearray()
    for item in items:
        out += field(PROTO_TOP[ITEMS_KEY], item_message(item, report))
    for k, v in top:
        out += field(PROTO_TOP[k], str(v).encode())
    return bytes(out)


def render(configuration, fmt, report):
    if fmt == 'json':
        top, items = ordered(configuration)
        return (json.dumps(dict(top + [(ITEMS_KEY, items)]), ensure_ascii=False, indent=2) + '\n').encode()
    if fmt in ('plist', BINARY_PLIST):
        top, items = ordered(configuration)
        kind = plistlib.FMT_BINARY if fmt == BINARY_PLIST else plistlib.FMT_XML
        return plistlib.dumps(dict(top + [(ITEMS_KEY, items)]), fmt=kind, sort_keys=False)
    if fmt == 'binpb':
        return write_binpb(configuration, report)
    writer = {'json5': write_json5, 'yaml': write_yaml, 'toml': write_toml, 'ini': write_ini, 'xml': write_xml,
              'properties': write_properties, 'textproto': write_textproto,
              'env': lambda c: write_properties(c, separator='__', assign='=')}[fmt]
    return writer(configuration).encode()


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('paths', nargs='*', help='Example folders or source files (default: every Example*/)')
    parser.add_argument('--format', default='json,yaml', help='comma-separated: %s, or all' % ', '.join(FORMATS))
    parser.add_argument('--output', help='output folder (default: <example>/Configurations)')
    parser.add_argument('--stdout', action='store_true', help='print instead of writing files')
    parser.add_argument('--check', action='store_true', help='exit 1 if a written file is out of date')
    args = parser.parse_args()
    args.formats = FORMATS if args.format == 'all' else [f.strip() for f in args.format.split(',') if f.strip()]
    unknown = [f for f in args.formats if f not in FORMATS]
    if unknown:
        parser.error('unknown format: %s' % ', '.join(unknown))
    if args.output:
        args.output = confined_path(args.output, ALLOWED_ROOTS)
    args.paths = [confined_path(p, ALLOWED_ROOTS) for p in args.paths]
    return args


def example_folder(path):
    """The Example folder of a source file (or its folder outside the repository). 源文件所属的 Example 目录。"""
    rel = os.path.relpath(path, ROOT)
    return os.path.join(ROOT, rel.split(os.sep)[0]) if not os.path.isabs(rel) and not rel.startswith('..') else os.path.dirname(path)


def write_file(target, data, args, stale):
    """Writes `data` to the checked `target` when it changed; returns 1 when written. 内容变化时写入，写入时返回 1。"""
    old = open(target, 'rb').read() if os.path.exists(target) else None
    if old == data:
        return 0
    if args.check:
        stale.append(os.path.relpath(target, ROOT))
        return 0
    # [EN] The folder of the checked target, not the raw argument. [CN] 使用已检查的目标路径所在目录，而非原始参数。
    os.makedirs(os.path.dirname(target), exist_ok=True)
    open(target, 'wb').write(data)
    return 1


def export_source(path, args, stale):
    """Exports one source file in every requested format; returns the number of files written. 返回写入的文件数。"""
    configuration, report = extract(path)
    print('%s: %s' % (os.path.relpath(path, ROOT), '%d tabs' % len(configuration[ITEMS_KEY]) if configuration else 'no literal tab attributes'))
    for line in report:
        print('    - ' + line)
    if not configuration:
        return 0
    out_dir = args.output or os.path.join(example_folder(path), 'Configurations')
    stem = os.path.splitext(os.path.basename(path))[0]
    written = 0
    for fmt in args.formats:
        data = render(configuration, fmt, report)
        if args.stdout:
            sys.stdout.write(data.decode('utf-8', errors='replace') if fmt not in ('binpb', BINARY_PLIST) else '<%d bytes of %s>\n' % (len(data), fmt))
            continue
        written += write_file(confined_path(os.path.join(out_dir, '%s.%s' % (stem, fmt)), ALLOWED_ROOTS), data, args, stale)
    return written


def main():
    args = parse_arguments()
    paths = args.paths or sorted(os.path.join(ROOT, d) for d in os.listdir(ROOT) if d.startswith('Example') and d != 'Example-Shared')
    stale = []
    written = sum(export_source(path, args, stale) for path in sources(paths))
    if args.check:
        if stale:
            print('Out of date (run scripts/export-tabbar-configurations.py):\n  ' + '\n  '.join(stale))
            return 1
        print('All configuration files are up to date.')
        return 0
    if not args.stdout:
        print('%d file(s) written.' % written)
    return 0


if __name__ == '__main__':
    sys.exit(main())
