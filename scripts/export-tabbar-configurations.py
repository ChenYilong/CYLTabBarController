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
FORMATS = ['json', 'json5', 'plist', 'binary.plist', 'yaml', 'toml', 'ini', 'properties', 'env', 'xml', 'textproto',
           'binpb']


# ---------------------------------------------------------------------------------------------------------------------
# Source scanning 源码扫描

def strip_comments(text):
    """Removes // and /* */ comments outside string literals. 移除字符串之外的 // 与 /* */ 注释。"""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"' and text[j] != '\n':
                j += 2 if text[j] == '\\' else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif text.startswith('//', i):
            j = text.find('\n', i)
            i = n if j < 0 else j
        elif text.startswith('/*', i):
            j = text.find('*/', i + 2)
            i = n if j < 0 else j + 2
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def matching(text, i):
    """Index of the bracket closing the one at `i`, skipping strings. 跳过字符串，返回与 `i` 处括号匹配的位置。"""
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack, n = [], len(text)
    while i < n:
        c = text[i]
        if c == '"':
            i += 1
            while i < n and text[i] != '"':
                i += 2 if text[i] == '\\' else 1
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
            i += 1
            while i < n and text[i] != '"':
                i += 2 if text[i] == '\\' else 1
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
            i += 1
            while i < len(entry) and entry[i] != '"':
                i += 2 if entry[i] == '\\' else 1
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


def evaluate(expr):
    """The configuration value of an Objective-C / Swift expression, or raises Unresolved.
    Objective-C / Swift 表达式对应的配置值，无法解析时抛出 Unresolved。"""
    e = expr.strip()
    while e.endswith('!') or e.endswith('?'):
        e = e[:-1].strip()
    m = re.fullmatch(STRING, e)
    if m:
        return unescape(m.group(1))
    m = re.fullmatch(r'(?:CYLLocalizedString|NSLocalizedString)\(\s*' + STRING + r'\s*(?:,.*)?\)', e, re.S)
    if m:
        return unescape(m.group(1))  # the localization key 本地化 key
    if number(e) is not None:
        return number(e)
    if e in ('YES', 'true', '@YES'):
        return True
    if e in ('NO', 'false', '@NO'):
        return False
    m = re.fullmatch(r'\[UIImage\s+imageNamed:\s*' + STRING + r'\s*\]|UIImage\(named:\s*' + STRING + r'\s*\)', e)
    if m:
        return unescape(m.group(1) or m.group(2))
    m = re.fullmatch(r'\[UIImage\s+systemImageNamed:\s*' + STRING + r'\s*\]|UIImage\(systemName:\s*' + STRING + r'\s*\)', e)
    if m:
        return 'system:' + unescape(m.group(1) or m.group(2))
    m = re.fullmatch(r'\[\[NSBundle\s+mainBundle\]\s+pathForResource:\s*' + STRING + r'\s+ofType:\s*' + STRING + r'\s*\]'
                     r'|Bundle\.main\.path\(forResource:\s*' + STRING + r'\s*,\s*ofType:\s*' + STRING + r'\s*\)', e)
    if m:
        name, ext = (m.group(1), m.group(2)) if m.group(1) is not None else (m.group(3), m.group(4))
        return '%s.%s' % (name, ext)
    m = re.fullmatch(r'\[\[NSBundle\s+mainBundle\]\s+URLForResource:\s*' + STRING + r'\s+withExtension:\s*' + STRING + r'\s*\]'
                     r'|Bundle\.main\.url\(forResource:\s*' + STRING + r'\s*,\s*withExtension:\s*' + STRING + r'\s*\)', e)
    if m:
        name, ext = (m.group(1), m.group(2)) if m.group(1) is not None else (m.group(3), m.group(4))
        return '%s.%s' % (name, ext)
    m = re.fullmatch(r'\[NSURL\s+fileURLWithPath:\s*(.+)\]|URL\(fileURLWithPath:\s*(.+)\)', e, re.S)
    if m:
        return evaluate(m.group(1) or m.group(2))
    m = re.fullmatch(r'\[NSURL\s+URLWithString:\s*' + STRING + r'\s*\]|URL\(string:\s*' + STRING + r'\s*\)', e)
    if m:
        return unescape(m.group(1) or m.group(2))
    m = re.fullmatch(r'\[NSValue\s+valueWithUIOffset:\s*UIOffsetMake\((.*)\)\s*\]|NSValue\(uiOffset:\s*UIOffset\((.*)\)\s*\)', e, re.S)
    if m:
        values = numbers(m.group(1) or m.group(2), 2)
        if values:
            return fmt_numbers(values)
    m = re.fullmatch(r'\[NSValue\s+valueWithUIEdgeInsets:\s*UIEdgeInsetsMake\((.*)\)\s*\]|NSValue\(uiEdgeInsets:\s*UIEdgeInsets\((.*)\)\s*\)', e, re.S)
    if m:
        values = numbers(m.group(1) or m.group(2), 4)
        if values:
            return fmt_numbers(values)
    m = re.fullmatch(r'\[NSValue\s+valueWithCGSize:\s*CGSizeMake\((.*)\)\s*\]|NSValue\(cgSize:\s*CGSize\((.*)\)\s*\)', e, re.S)
    if m:
        values = numbers(m.group(1) or m.group(2), 2)
        if values:
            return fmt_numbers(values)
    m = re.fullmatch(r'\[UIColor\s+colorWithWhite:\s*(.+?)\s+alpha:\s*(.+?)\s*\]|UIColor\(white:\s*(.+?)\s*,\s*alpha:\s*(.+?)\s*\)', e)
    if m:
        w, a = number(m.group(1) or m.group(3)), number(m.group(2) or m.group(4))
        if w is not None and a is not None:
            return hex_color(w, w, w, a)
    m = re.fullmatch(r'\[UIColor\s+colorWithRed:\s*(.+?)\s+green:\s*(.+?)\s+blue:\s*(.+?)\s+alpha:\s*(.+?)\s*\]'
                     r'|UIColor\(red:\s*(.+?)\s*,\s*green:\s*(.+?)\s*,\s*blue:\s*(.+?)\s*,\s*alpha:\s*(.+?)\s*\)', e)
    if m:
        groups = [g for g in m.groups() if g is not None]
        values = [number(g) for g in groups]
        if None not in values:
            return hex_color(*values)
    m = re.fullmatch(r'\[UIColor\s+(\w+)Color\]|UIColor\.(\w+?)(?:Color)?', e)
    if m and (m.group(1) or m.group(2)) in NAMED_COLORS:
        return NAMED_COLORS[m.group(1) or m.group(2)]
    m = re.fullmatch(r'\[UIFont\s+(bold)?[sS]ystemFontOfSize:\s*(.+?)(?:\s+weight:\s*UIFontWeight(\w+))?\s*\]'
                     r'|UIFont\.(bold)?[sS]ystemFont\(ofSize:\s*(.+?)(?:\s*,\s*weight:\s*(?:UIFont\.Weight)?\.(\w+))?\s*\)', e)
    if m:
        bold, size, weight = (m.group(1), m.group(2), m.group(3)) if m.group(2) is not None else (m.group(4), m.group(5), m.group(6))
        size = number(size)
        if size is not None:
            weight = 'bold' if bold else (weight or '').lower()
            return '%s:%s' % (weight, size) if weight and weight != 'regular' else size
    m = re.fullmatch(r'\[UIFont\s+fontWithName:\s*' + STRING + r'\s+size:\s*(.+?)\s*\]|UIFont\(name:\s*' + STRING + r'\s*,\s*size:\s*(.+?)\s*\)', e)
    if m:
        name, size = (m.group(1), m.group(2)) if m.group(1) is not None else (m.group(3), m.group(4))
        if number(size) is not None:
            return '%s:%s' % (unescape(name), number(size))
    if e.startswith('@{') or (e.startswith('[') and ':' in e and not e.startswith('[[')):
        body = e[2:-1] if e.startswith('@{') else e[1:-1]
        result = {}
        for entry in split_top(body):
            key, value = split_key_value(entry)
            if key is None:
                raise Unresolved(expr)
            result[str(evaluate(key))] = evaluate(value)
        return result
    raise Unresolved(expr)


def dictionary_literals(code):
    """(position, variable name or None, {key: expression}) of every dictionary literal with item keys.
    含有 item 键的每个字典字面量：(位置, 变量名或 None, {键: 表达式})。"""
    found = []
    for m in re.finditer(r'@\{|\[', code):
        start = m.start() + (1 if m.group() == '@{' else 0)
        end = matching(code, start)
        if end < 0:
            continue
        body = code[start + 1:end]
        entries = {}
        for entry in split_top(body):
            key, value = split_key_value(entry)
            if key in ITEM_KEYS:
                entries[key] = value
            elif key is not None and key.strip().startswith('CYLTabBar'):
                entries.setdefault('__unknown__', []).append(key)
        if not any(k in ITEM_KEYS for k in entries):
            continue
        head = code[max(0, m.start() - 120):m.start()]
        name = re.search(r'(?:NSDictionary\s*(?:<[^>]*>)?\s*\*\s*|(?:let|var)\s+)(\w+)\s*(?::[^=]+)?=\s*$', head)
        found.append((m.start(), name.group(1) if name else None, entries))
    return found


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
        elements = split_top(code[start + 1:end])
        positions = []
        offset = start + 1
        for element in elements:
            index = code.find(element, offset)
            literal = index + (1 if element.startswith('@{') else 0)
            if not (element.startswith('@{') or element.startswith('[')) or index not in by_position:
                positions = None
                break
            positions.append(index)
            offset = index + len(element)
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
    value = evaluate(e if e.startswith('@{') or e.startswith('[') else '[' + e + ']')
    return {int(k): v for k, v in value.items()}


def add_lottie_files(code, items, example_dir, report):
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
    for directory, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in ('.git', 'Pods', 'docs', 'Configurations')]
        resources.update(f for f in files if f.endswith('.json'))
    for item, name in zip(items, names):
        if name + '.json' in resources:
            item['CYLTabBarLottieFilePath'] = name + '.json'
            if name + '_dark.json' in resources:
                item['CYLTabBarLottieDarkFilePath'] = name + '_dark.json'
        else:
            report.append('Lottie file %s.json is not in the example; skipped' % name)


def add_dark_colors(code, items, report):
    """Swift `["A", "B"].map { layer in ["\\(layer)_Suffix": UIColor(...)] }` used for `CYLTabBarLottieDarkColors`."""
    if 'CYLTabBarLottieDarkColors' not in code:
        return
    # [EN] Linear regex: each part can match only one way (no nested optional quantifiers).
    # [CN] 线性正则：每一部分只有一种匹配方式（无嵌套的可选量词）。
    m = re.search(r'\[\s*("[^"]*"(?:\s*,\s*"[^"]*")*)\s*(?:,\s*)?\]\s*\.map\s*\{\s*(\w+)\s*(?:->[^{]*?)?\bin\s', code)
    if not m:
        report.append('CYLTabBarLottieDarkColors: built at runtime; skipped')
        return
    layers = re.findall(r'"([^"]*)"', m.group(1))
    start = code.index('[', m.end())
    end = matching(code, start)
    body = code[start + 1:end]
    variable = m.group(2)
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
    navigation = re.findall(r'\[\[(\w*Navigation\w*)\s+alloc\]\s+initWithRootViewController:|(\w*Navigation\w*)\(rootViewController:', code)
    navigation = [a or b for a, b in navigation]
    return classes, (max(set(navigation), key=navigation.count) if navigation else None)


def top_level(code, report):
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


def extract(path, example_dir):
    """The configuration of one source file, and the report of what could not be read."""
    code = strip_comments(open(path, encoding='utf-8').read())
    report = []
    literals = dictionary_literals(code)
    items = items_from_helpers(code, report)
    if items is None:
        by_name = {name: entries for _, name, entries in literals if name}
        order = None
        for m in re.finditer(r'@?\[\s*(\w+(?:\s*,\s*\w+)+)\s*,?\s*\]', code):
            names = [n.strip() for n in m.group(1).split(',')]
            if all(n in by_name for n in names):
                order = names
        chosen = [by_name[n] for n in order] if order else inline_array_items(code, literals) or [entries for _, _, entries in literals]
        items = []
        for entries in chosen:
            item = {}
            for key, expr in entries.items():
                if key == '__unknown__':
                    report.append('unknown keys: %s' % ', '.join(expr))
                    continue
                try:
                    item[key] = evaluate(expr)
                except Unresolved:
                    report.append('%s = %s: only known at runtime; left out' % (key, short(expr)))
            if any(k in item for k in ('CYLTabBarItemTitle', 'CYLTabBarItemImage', 'CYLTabBarItemSelectedImage',
                                      'CYLTabBarLottieFilePath', 'CYLTabBarLottieURL', 'CYLTabBarItemImageURL')):
                items.append(item)
            else:
                report.append('a tab with no literal title or icon (built at runtime); left out')
    if not items:
        report.append('no tab could be read from the source: the tabs are built at runtime')
        return None, report
    add_lottie_files(code, items, example_dir, report)
    add_dark_colors(code, items, report)
    configuration = top_level(code, report)
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
    lines = ['%s = %s' % (k, scalar(v)) for k, v in top]
    for item in items:
        lines += ['', '[[%s]]' % ITEMS_KEY]
        for k, v in item.items():
            if isinstance(v, dict):
                lines.append('%s = { %s }' % (k, ', '.join('%s = %s' % (quote(kk), scalar(vv)) for kk, vv in v.items())))
            else:
                lines.append('%s = %s' % (k, scalar(v)))
    return '\n'.join(lines) + '\n'


def flat_value(v):
    text = scalar(v) if isinstance(v, bool) else str(v)
    return quote(text) if text != text.strip() or text == '' else text


def write_ini(c):
    top, items = ordered(c)
    lines = ['%s = %s' % (k, flat_value(v)) for k, v in top]
    for i, item in enumerate(items):
        lines += ['', '[%s.%d]' % (ITEMS_KEY, i)]
        for k, v in item.items():
            if isinstance(v, dict):
                lines += ['%s.%s = %s' % (k, quote(kk), flat_value(vv)) for kk, vv in v.items()]
            else:
                lines.append('%s = %s' % (k, flat_value(v)))
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


def write_binpb(c, report):
    """A binary cyl.CYLTabBarConfiguration message (proto3: every value is a string). 二进制消息（每个值都是字符串）。"""
    top, items = ordered(c)
    out = bytearray()
    for item in items:
        body = bytearray()
        for k, v in item.items():
            if k not in PROTO_ITEM:
                report.append('%s has no protobuf field; left out of .binpb' % k)
            elif isinstance(v, dict):
                for kk, vv in v.items():
                    body += field(PROTO_ITEM[k], field(1, str(kk).encode()) + field(2, str(vv).encode()))
            else:
                body += field(PROTO_ITEM[k], (scalar(v) if isinstance(v, bool) else str(v)).encode())
        out += field(PROTO_TOP[ITEMS_KEY], bytes(body))
    for k, v in top:
        out += field(PROTO_TOP[k], str(v).encode())
    return bytes(out)


def render(configuration, fmt, report):
    if fmt == 'json':
        top, items = ordered(configuration)
        return (json.dumps(dict(top + [(ITEMS_KEY, items)]), ensure_ascii=False, indent=2) + '\n').encode()
    if fmt in ('plist', 'binary.plist'):
        top, items = ordered(configuration)
        kind = plistlib.FMT_BINARY if fmt == 'binary.plist' else plistlib.FMT_XML
        return plistlib.dumps(dict(top + [(ITEMS_KEY, items)]), fmt=kind, sort_keys=False)
    if fmt == 'binpb':
        return write_binpb(configuration, report)
    writer = {'json5': write_json5, 'yaml': write_yaml, 'toml': write_toml, 'ini': write_ini, 'xml': write_xml,
              'properties': write_properties, 'textproto': write_textproto,
              'env': lambda c: write_properties(c, separator='__', assign='=')}[fmt]
    return writer(configuration).encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('paths', nargs='*', help='Example folders or source files (default: every Example*/)')
    parser.add_argument('--format', default='json,yaml', help='comma-separated: %s, or all' % ', '.join(FORMATS))
    parser.add_argument('--output', help='output folder (default: <example>/Configurations)')
    parser.add_argument('--stdout', action='store_true', help='print instead of writing files')
    parser.add_argument('--check', action='store_true', help='exit 1 if a written file is out of date')
    args = parser.parse_args()
    formats = FORMATS if args.format == 'all' else [f.strip() for f in args.format.split(',') if f.strip()]
    unknown = [f for f in formats if f not in FORMATS]
    if unknown:
        parser.error('unknown format: %s' % ', '.join(unknown))
    if args.output:
        args.output = confined_path(args.output, ALLOWED_ROOTS)
    args.paths = [confined_path(p, ALLOWED_ROOTS) for p in args.paths]
    paths = args.paths or sorted(os.path.join(ROOT, d) for d in os.listdir(ROOT) if d.startswith('Example') and d != 'Example-Shared')
    stale, written = [], 0
    for path in sources(paths):
        rel = os.path.relpath(path, ROOT)
        example_dir = os.path.join(ROOT, rel.split(os.sep)[0]) if not os.path.isabs(rel) and not rel.startswith('..') else os.path.dirname(path)
        configuration, report = extract(path, example_dir)
        print('%s: %s' % (rel, '%d tabs' % len(configuration[ITEMS_KEY]) if configuration else 'no literal tab attributes'))
        for line in report:
            print('    - ' + line)
        if not configuration:
            continue
        out_dir = args.output or os.path.join(example_dir, 'Configurations')
        stem = os.path.splitext(os.path.basename(path))[0]
        for fmt in formats:
            data = render(configuration, fmt, report)
            if args.stdout:
                sys.stdout.write(data.decode('utf-8', errors='replace') if fmt not in ('binpb', 'binary.plist') else '<%d bytes of %s>\n' % (len(data), fmt))
                continue
            target = confined_path(os.path.join(out_dir, '%s.%s' % (stem, fmt)), ALLOWED_ROOTS)
            old = open(target, 'rb').read() if os.path.exists(target) else None
            if old == data:
                continue
            if args.check:
                stale.append(os.path.relpath(target, ROOT))
                continue
            # [EN] The folder of the checked target, not the raw argument. [CN] 使用已检查的目标路径所在目录，而非原始参数。
            os.makedirs(os.path.dirname(target), exist_ok=True)
            open(target, 'wb').write(data)
            written += 1
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
