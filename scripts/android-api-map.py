#!/usr/bin/env python3
"""[EN] The iOS -> Android API map of CYLTabBarController.

Reads every public symbol of the iOS library (its public headers: classes, protocols, methods, properties, constants,
enums and functions), merges the Android status of each one from Example-Android/cyltabbar/api-map.json, and writes
docs/Android-API-Map.md: one table per header with the iOS API, the Android API, the status and a note, plus the
migration score. `--check` fails when the document is stale, when a symbol of the JSON no longer exists in the headers,
or when the JSON holds an invalid status.

Status values: done (the same behavior), partial (part of the behavior, see the note), planned (not ported yet),
n/a (iOS only: UIKit, Lottie / PAG / Rive runtimes, FlatDesign's KVC, Liquid Glass..., counted out of the score).
Score = (done + 0.5 * partial) / (every symbol that is not n/a).

[CN] CYLTabBarController 的 iOS -> Android API 对照表。

读取 iOS 库的全部公开符号（公开头文件中的类、协议、方法、属性、常量、枚举与函数），合并 Example-Android/cyltabbar/api-map.json 中每个符号的
Android 状态，写出 docs/Android-API-Map.md：每个头文件一张表（iOS API、Android API、状态、说明）以及迁移完成率。`--check` 在文档过期、
JSON 中的符号在头文件中已不存在、或 JSON 中的状态无效时失败。

状态：done（行为相同）、partial（部分行为，见说明）、planned（尚未移植）、n/a（仅 iOS：UIKit、Lottie / PAG / Rive 运行库、扁平样式的 KVC、
液态玻璃等，不计入完成率）。完成率 = (done + 0.5 * partial) / (所有非 n/a 的符号)。
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEADERS_ROOT = os.path.join(ROOT, 'CYLTabBarController')
MAP_PATH = os.path.join(ROOT, 'Example-Android', 'cyltabbar', 'api-map.json')
DOC_PATH = os.path.join(ROOT, 'docs', 'Android-API-Map.md')
STATUSES = ('done', 'partial', 'planned', 'n/a')
# [EN] Private headers (podspec private_header_files, and the demo-only settings list). [CN] 私有头文件（podspec 的 private_header_files，以及仅用于演示的设置列表）。
PRIVATE = {
    'CYLTabBarController/UIControl+CYLTabBarItemAnimation.h', 'CYLTabBarController/CYLTabBarItemAnimationService.h',
    'CYLTabBarController/CYLTabBarController+CYLPrivate.h', 'CYLTabBarController/CYLUtils/CYLComponents/CYLTheme/CYLThemePrivate.h',
    'CYLTabBarController/CYLBadgeView/CYLBadgeViewDefines.h', 'CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationEngine.h',
}


def strip_comments(text):
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)


def selector_of(declaration):
    """[EN] "- (void)foo:(id)a bar:(int)b" -> "-foo:bar:". [CN] 方法声明 -> 选择器。"""
    kind = declaration[0]
    body = declaration[1:]
    # [EN] Remove the parenthesized types, innermost first (no nested quantifiers). [CN] 从最内层起去掉括号中的类型（不用嵌套量词）。
    previous = None
    while previous != body:
        previous = body
        body = re.sub(r'\([^()]*\)', ' ', body)
    parts = re.findall(r'(\w+)\s*(:)?', body)
    selector = ''.join(name + (colon or '') for name, colon in parts if colon) or (parts[0][0] if parts else body.strip())
    return kind + selector


def public_headers():
    headers = []
    for folder, _, files in os.walk(HEADERS_ROOT):
        for name in files:
            path = os.path.relpath(os.path.join(folder, name), ROOT)
            if name.endswith('.h') and path not in PRIVATE and not name.startswith('_'):
                headers.append(path)
    return sorted(headers)


MACROS = re.compile(r'\b(NS_\w+|CYL_\w+|DEPRECATED_MSG_ATTRIBUTE\([^)]*\)|API_\w+\([^)]*\)|UI_APPEARANCE_SELECTOR)\b')
TYPEDEF_MARKERS = ('(^', 'NS_TYPED', 'NS_STRING_ENUM')


def property_symbol(line, owner):
    """[EN] The property of an "@property" line, or None. [CN] "@property" 行的属性，或 None。"""
    body = line.split(';')[0]
    body = re.sub(r'^@property\s*\([^)]*\)', '', body)
    # [EN] Deprecation messages hold words that are not names ("... instead."). [CN] 废弃提示中的单词不是名称。
    body = re.sub(r'"[^"]*"', '', body)
    body = re.sub(r'\b\w*DEPRECATED\w*\s*\(\s*\)', '', body)
    body = re.sub(r'NS_SWIFT_NAME\([^)]*\)', '', body)
    body = MACROS.sub('', body)
    body = re.sub(r'<[^>]*>', '', body)
    block = re.search(r'\(\s*\^\s*(\w+)\s*\)', body)
    names = [block.group(1)] if block else re.findall(r'\w+', body)
    return ('property', owner, names[-1]) if names else None


def extern_symbol(line):
    """[EN] The function or constant of an extern line, or None. [CN] extern 行的函数或常量，或 None。"""
    head = line.split(';')[0]
    call = re.search(r'\b(\w+)\s*\(', head)
    if call and call.group(1) not in ('NS_SWIFT_NAME', 'DEPRECATED_MSG_ATTRIBUTE', 'API_AVAILABLE'):
        return ('function', '', call.group(1) + '()')
    head = re.sub(r'\b(NS_\w+|CYL_\w+|DEPRECATED_MSG_ATTRIBUTE\([^)]*\)|API_\w+\([^)]*\)|const)\b', '', head)
    names = re.findall(r'\w+', head)
    return ('constant', '', names[-1]) if names else None


def typedef_symbol(line):
    """[EN] The enum or typedef of a "typedef" line, or None. [CN] "typedef" 行的枚举或类型，或 None。"""
    m = re.match(r'typedef\s+NS_(ENUM|OPTIONS)\s*\(\s*\w+\s*,\s*(\w+)\s*\)', line)
    if m:
        return ('enum', '', m.group(2))
    block = re.search(r'\(\s*\^\s*(\w+)\s*\)', line)
    if block:
        return ('typedef', '', block.group(1))
    if ';' not in line or not (any(marker in line for marker in TYPEDEF_MARKERS) or line.startswith('typedef NSString')):
        return None
    # [EN] The last name before ";", without the trailing enum macros (no backtracking regex). [CN] ";" 前的最后一个名称，去掉末尾的枚举宏（不用回溯正则）。
    words = re.findall(r'\w+', line.split(';')[0])
    words = [word for word in words if not word.startswith(('NS_TYPED_', 'NS_STRING_ENUM'))]
    return ('typedef', '', words[-1]) if words else None


def owner_symbol(line):
    """[EN] (owner, symbol) of an "@interface" / "@protocol" line, or None. [CN] "@interface" / "@protocol" 行的（所属，符号），或 None。"""
    m = re.match(r'@interface\s+(\w+)\s*(?:\((\w*)\))?', line)
    if m:
        owner = m.group(1) + ('(%s)' % m.group(2) if m.group(2) is not None else '')
        return owner, ('class' if m.group(2) is None else 'category', owner, owner)
    m = re.match(r'@protocol\s+(\w+)\s*<', line)
    if m:
        return m.group(1), ('protocol', m.group(1), m.group(1))
    return None


def declaration_symbol(line, owner):
    """[EN] The symbol a declaration line declares, or None. [CN] 声明行声明的符号，或 None。"""
    if line.startswith(('-', '+')) and re.match(r'[-+]\s*\(', line):
        return ('method', owner or '', selector_of(line.split(';')[0]))
    if line.startswith('@property') and owner:
        return property_symbol(line, owner)
    if re.match(r'(?:FOUNDATION_EXTERN|UIKIT_EXTERN|extern)\b', line):
        return extern_symbol(line)
    if line.startswith('typedef'):
        return typedef_symbol(line)
    return None


def symbols_of(path):
    """[EN] The public symbols of one header, in order: (kind, owner, name). [CN] 一个头文件的公开符号（kind、所属、名称）。"""
    text = strip_comments(open(os.path.join(ROOT, path), encoding='utf-8', errors='replace').read())
    symbols = []
    owner = None
    pending = ''
    for raw in text.split('\n'):
        line = (pending + ' ' + raw.strip()).strip() if pending else raw.strip()
        pending = ''
        if not line:
            continue
        declared = owner_symbol(line)
        if declared:
            owner = declared[0]
            symbols.append(declared[1])
        elif line.startswith('@end'):
            owner = None
        elif line.startswith(('-', '+')) and re.match(r'[-+]\s*\(', line) and ';' not in line:
            pending = line
        else:
            symbol = declaration_symbol(line, owner)
            if symbol:
                symbols.append(symbol)
    return symbols


def inventory():
    rows = []
    for path in public_headers():
        for kind, owner, name in symbols_of(path):
            key = '%s %s' % (owner, name) if owner and kind in ('method', 'property') else name
            rows.append({'header': path, 'kind': kind, 'owner': owner, 'name': name, 'key': key})
    return rows


def load_map():
    if not os.path.exists(MAP_PATH):
        return {}
    with open(MAP_PATH, encoding='utf-8') as handle:
        return json.load(handle)


def score(rows, mapping):
    counted = 0.0
    total = 0
    for row in rows:
        entry = mapping.get(row['key'], {})
        status = entry.get('status', 'planned')
        if status == 'n/a':
            continue
        total += 1
        counted += {'done': 1.0, 'partial': 0.5}.get(status, 0.0)
    return (round(100 * counted / total) if total else 0), total


def document(rows, mapping):
    out = ['# Android API 对照表 / The Android API map', '', '<!-- bound-classes: none -->', '',
           '<!-- Generated by scripts/android-api-map.py from the public headers and Example-Android/cyltabbar/api-map.json; do not edit by hand. -->',
           '<!-- 由 scripts/android-api-map.py 根据公开头文件与 Example-Android/cyltabbar/api-map.json 生成；请勿手动编辑。 -->', '']
    percent, total = score(rows, mapping)
    counts = dict.fromkeys(STATUSES, 0)
    for row in rows:
        counts[mapping.get(row['key'], {}).get('status', 'planned')] += 1
    out += ['| 中文 | English |', '|:---|:---|',
            '| iOS 库的每个公开符号（公开头文件中的类、协议、方法、属性、常量、枚举、函数）及其 Android 版本（`Example-Android/cyltabbar`，Kotlin 与 Java）。状态：done 行为相同；partial 部分行为（见说明）；planned 尚未移植；n/a 仅 iOS（UIKit、扁平样式、液态玻璃、Core Animation 等），不计入完成率。 | Every public symbol of the iOS library (classes, protocols, methods, properties, constants, enums and functions of the public headers) with its Android version (`Example-Android/cyltabbar`, Kotlin and Java). Status: done, the same behavior; partial, part of it (see the note); planned, not ported yet; n/a, iOS only (UIKit, FlatDesign, Liquid Glass, Core Animation...), left out of the score. |',
            '| **迁移完成率：%d / 100**（done + 0.5 × partial，共 %d 个计入的符号；done %d、partial %d、planned %d、n/a %d）。 | **Migration score: %d / 100** (done + 0.5 × partial over %d counted symbols; done %d, partial %d, planned %d, n/a %d). |'
            % (percent, total, counts['done'], counts['partial'], counts['planned'], counts['n/a'], percent, total, counts['done'], counts['partial'], counts['planned'], counts['n/a']),
            '']
    by_header = {}
    for row in rows:
        by_header.setdefault(row['header'], []).append(row)
    for header in sorted(by_header):
        header_rows = by_header[header]
        done = sum(1 for r in header_rows if mapping.get(r['key'], {}).get('status') == 'done')
        out += ['## `%s`' % header.replace('CYLTabBarController/', '', 1), '',
                '| iOS API | Android API | 状态 Status | 说明 / Note |', '|:---|:---|:---|:---|']
        for row in header_rows:
            entry = mapping.get(row['key'], {})
            status = entry.get('status', 'planned')
            android = entry.get('android', '')
            note = entry.get('note', '')
            ios = '`%s`' % row['name'] if row['kind'] in ('class', 'category', 'protocol', 'constant', 'enum', 'typedef', 'function') else '`%s` `%s`' % (row['owner'], row['name'])
            out.append('| %s | %s | %s | %s |' % (ios, '`%s`' % android if android else '—', status, note))
        out.append('')
        del done
    return '\n'.join(out)


NAV_BLOCKS = (re.compile(r'<!-- binding:start -->.*?<!-- binding:end -->\n*', re.S),
              re.compile(r'## 目录 / Contents\n*<!-- navigation:start -->.*?<!-- navigation:end -->\n*', re.S))


def without_navigation(text):
    """[EN] The document without the blocks scripts/update-docs-navigation.py writes. [CN] 去掉 update-docs-navigation.py 写入的块。"""
    for pattern in NAV_BLOCKS:
        text = pattern.sub('', text)
    return re.sub(r'\n+', '\n', text)


def with_navigation_of(existing, text):
    """[EN] Keeps the navigation blocks of the existing document in the new text. [CN] 把现有文档的导航块保留到新文本中。"""
    binding = NAV_BLOCKS[0].search(existing or '')
    contents = NAV_BLOCKS[1].search(existing or '')
    if binding:
        text = text.replace('<!-- bound-classes: none -->\n', '<!-- bound-classes: none -->\n' + binding.group(0), 1)
    if contents:
        first = text.find('\n## ')
        if first >= 0:
            text = text[:first + 1] + contents.group(0) + text[first + 1:]
    return text


def problems_of(rows, mapping):
    """[EN] Entries of the map that are not public symbols, or have an unknown status. [CN] 不是公开符号或状态未知的条目。"""
    problems = []
    keys = {row['key'] for row in rows}
    for key, entry in mapping.items():
        if key not in keys:
            problems.append('api-map.json: %s is not a public iOS symbol' % key)
        if entry.get('status') not in STATUSES:
            problems.append('api-map.json: %s has the status %r; use one of %s' % (key, entry.get('status'), ', '.join(STATUSES)))
    return problems


def check(rows, mapping, text, problems):
    """[EN] `--check`: the document is up to date and the map is valid. [CN] `--check`：文档是最新的且对照表有效。"""
    current = open(DOC_PATH, encoding='utf-8').read() if os.path.exists(DOC_PATH) else ''
    if problems:
        print('\n'.join(problems))
    if without_navigation(current).rstrip('\n') != without_navigation(text).rstrip('\n'):
        problems.append('%s is out of date: run python3 scripts/android-api-map.py' % os.path.relpath(DOC_PATH, ROOT))
        print(problems[-1])
    if not problems:
        print('docs/Android-API-Map.md is up to date (%d symbols, score %d).' % (len(rows), score(rows, mapping)[0]))
    return 1 if problems else 0


def write(rows, mapping, text, problems):
    """[EN] Writes the document, keeping its navigation blocks. [CN] 写入文档，保留其导航块。"""
    if problems:
        print('\n'.join(problems))
        return 1
    existing = open(DOC_PATH, encoding='utf-8').read() if os.path.exists(DOC_PATH) else ''
    with open(DOC_PATH, 'w', encoding='utf-8') as handle:
        handle.write(with_navigation_of(existing, text))
    print('wrote %s: %d symbols, score %d' % (os.path.relpath(DOC_PATH, ROOT), len(rows), score(rows, mapping)[0]))
    return 0


def main():
    rows = inventory()
    if '--list' in sys.argv:
        for row in rows:
            print('%s\t%s\t%s' % (row['kind'], row['header'], row['key']))
        return 0
    mapping = load_map()
    problems = problems_of(rows, mapping)
    text = document(rows, mapping)
    if '--check' in sys.argv:
        return check(rows, mapping, text, problems)
    return write(rows, mapping, text, problems)


if __name__ == '__main__':
    sys.exit(main())
