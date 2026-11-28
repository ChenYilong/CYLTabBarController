#!/usr/bin/env python3
"""[EN] The iOS -> HarmonyOS NEXT API map of CYLTabBarController (docs/HarmonyOS-API-Map.md).

Lists every public symbol of the iOS library (the same inventory as scripts/android-api-map.py: classes, protocols,
methods, properties, constants, enums and functions of the public headers), with the English part of its documentation
comment and its HarmonyOS NEXT (ArkTS / ArkUI) counterpart from scripts/harmonyos-api-map.json ("TODO" when there is
none yet). Unlike the Android map, Liquid Glass symbols count: the HarmonyOS version implements the Liquid Glass tab bar.
Score = 100 * implemented / all symbols; 100 means every iOS public API has a HarmonyOS counterpart.

    python3 scripts/harmonyos-api-map.py           # writes docs/HarmonyOS-API-Map.md
    python3 scripts/harmonyos-api-map.py --check   # fails when the document is stale

[CN] CYLTabBarController 的 iOS -> HarmonyOS NEXT API 对照表（docs/HarmonyOS-API-Map.md）。列出 iOS 库的全部公开符号（与
scripts/android-api-map.py 相同的清单），附其文档注释的英文部分，以及 scripts/harmonyos-api-map.json 中对应的 HarmonyOS NEXT（ArkTS / ArkUI）
接口（尚无时为 "TODO"）。与 Android 对照表不同，液态玻璃相关符号也计入：鸿蒙版本要实现液态玻璃 TabBar。完成率 = 100 × 已实现 / 全部符号。
"""
import importlib.util
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC_PATH = os.path.join(ROOT, 'docs', 'HarmonyOS-API-Map.md')
MAP_PATH = os.path.join(ROOT, 'scripts', 'harmonyos-api-map.json')

_spec = importlib.util.spec_from_file_location('android_api_map', os.path.join(ROOT, 'scripts', 'android-api-map.py'))
android = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(android)


def comment_of(path, name):
    """[EN] The English part of the documentation comment right above `name`'s declaration. [CN] 声明上方文档注释的英文部分。"""
    full_path = os.path.join(ROOT, path)
    if not os.path.exists(full_path):  # [EN] the header moved to Swift: its frozen comment is in scripts/ios-public-api.json. [CN] 头文件已移入 Swift：其注释已冻结在 scripts/ios-public-api.json。
        return ''
    text = open(full_path, encoding='utf-8', errors='replace').read()
    for match in re.finditer(re.escape(name), text):
        line_start = text.rfind('\n', 0, match.start()) + 1
        line = text[line_start:text.find('\n', match.start())]
        if line.lstrip().startswith(('*', '/*', '//')):
            continue
        before = text[:line_start].rstrip()
        if not before.endswith('*/'):
            continue
        start = before.rfind('/*')
        block = before[start:]
        english = re.search(r'\[EN\]((?:(?!\[CN\]|\*/)[\s\S])*)', block)
        body = english.group(1) if english else re.sub(r'(^/\*!?)|(\*/$)', '', block)
        body = ' '.join(l.strip().lstrip('*').strip() for l in body.split('\n'))
        return ' '.join(body.split()).replace('|', '\\|')
    return ''


# [EN] Swift-only sources of the iOS library (docs/Swift-Migration.md): their Objective-C API is not in any header (a
#      compatibility header such as CYLAnimatedItemView.h holds no declarations), so it is read from the Swift file.
# [CN] 只有 Swift 实现的 iOS 源文件（docs/Swift-Migration.md）：它们的 Objective-C API 不在任何头文件中（CYLAnimatedItemView.h 等兼容头文件
#      没有声明），因此从 Swift 文件读取。
SWIFT_SOURCES = [
    'CYLTabBarController/CYLAnimatedItem/Swift/CYLAnimatedItemView.swift',
    'CYLTabBarController/CYLAnimatedItem/Swift/CYLAnimatedItemStackView.swift',
]
SWIFT_ADOPTED = {'gestureRecognizer'}
SWIFT_TYPE = re.compile(r'^(?:@objc(?:\((\w+)\))?\s+)?(?:@objcMembers\s+)?(?:public|open)\s+(?:final\s+)?(enum|protocol|class)\s+(\w+)')
SWIFT_OBJC_NAME = re.compile(r'@objc\(([\w:]+)\)')


def swift_english(doc):
    """[EN] The English part of a Swift documentation comment. [CN] Swift 文档注释的英文部分。"""
    text = re.sub(r'^\s*(/\*\*|\*/|///?|\*)', '', doc, flags=re.M)
    english = re.search(r'\[EN\]((?:(?!\[CN\])[\s\S])*)', text)
    body = english.group(1) if english else text
    return ' '.join(body.split()).replace('|', '\\|')


def swift_selector(name, params):
    """[EN] The Objective-C selector Swift makes for `func name(params)`. [CN] Swift 为 `func name(params)` 生成的 Objective-C 选择器。"""
    labels = []
    depth = 0
    part = ''
    for char in params:
        depth += char in '([<'
        depth -= char in ')]>'
        if char == ',' and depth == 0:
            labels.append(part)
            part = ''
        else:
            part += char
    if part.strip():
        labels.append(part)
    labels = [label.split(':')[0].split() for label in labels]
    if not labels:
        return name
    first = labels[0][0]
    selector = name + (':' if first == '_' else 'With' + first[0].upper() + first[1:] + ':')
    return selector + ''.join(label[0] + ':' for label in labels[1:])


OBJC = '@objc'


class SwiftSourceScanner:
    """
    [EN] Reads one Swift source line by line and collects its public Objective-C symbols (types at depth 0, their members
         at depth 1), with the English part of each documentation comment.
    [CN] 逐行读取一个 Swift 源文件，收集其公开的 Objective-C 符号（第 0 层的类型及其第 1 层的成员）以及每个文档注释的英文部分。
    """

    def __init__(self, header):
        self.header = header
        self.depth = 0
        self.owner = None
        self.owner_kind = ''
        self.members = False
        self.doc = ''
        self.in_doc = False
        self.attributes = ''
        self.rows = []

    def scan(self, source):
        for raw in source.split('\n'):
            self.line(raw)
        return self.rows

    def comment_line(self, line):
        """[EN] True when the line is part of a comment (and was taken). [CN] 该行属于注释（并已处理）时为 True。"""
        if self.in_doc:
            self.doc += '\n' + line
            self.in_doc = '*/' not in line
            return True
        if line.startswith('/**'):
            self.doc, self.in_doc = line, '*/' not in line
            return True
        if line.startswith('///'):
            self.doc += '\n' + line
            return True
        return line.startswith('//') or not line

    def line(self, raw):
        line = raw.strip()
        if self.comment_line(line):
            return
        if self.depth == 0:
            self.type_line(line)
        elif self.depth == 1 and self.owner is not None:
            self.member_line(line)
        self.attributes = (self.attributes + ' ' + line).strip() if line.startswith('@') and not re.search(
            r'\b(var|let|func|class|enum|protocol|struct)\s', line) else ''
        self.depth += raw.count('{') - raw.count('}')
        # [EN] An attribute line keeps the comment above it for the declaration below. [CN] 属性行保留其上方的注释，留给下面的声明。
        if not self.attributes:
            self.doc = ''

    def add(self, kind, owner, name, key):
        self.rows.append({'header': self.header, 'kind': kind, 'owner': owner, 'name': name, 'key': key,
                          'comment': swift_english(self.doc)})

    def type_line(self, line):
        match = SWIFT_TYPE.match(self.attributes + ' ' + line if self.attributes else line)
        if match and (OBJC in self.attributes or OBJC in line):
            self.owner, self.owner_kind = match.group(3), match.group(2)
            self.members = '@objcMembers' in self.attributes + line or self.owner_kind == 'protocol'
            self.add(self.owner_kind, '', self.owner, self.owner)
        elif not line.startswith('@'):
            self.owner = None

    def member_line(self, line):
        text = (self.attributes + ' ' + line).strip()
        declaration = re.search(r'\b(var|let|func)\s+(\w+)', text)
        # [EN] An initializer with an Objective-C name (`@objc(initWith…:)`) is a method of the API.
        # [CN] 带 Objective-C 名称（`@objc(initWith…:)`）的初始化方法属于 API。
        initializer = re.search(r'@objc\((init\w*:[\w:]*)\)', self.attributes) if re.search(r'\binit\s*\(', line) else None
        if initializer and re.search(r'\b(public|open)\b', text):
            name = '-' + initializer.group(1)
            self.add('method', self.owner, name, '%s %s' % (self.owner, name))
        if declaration and self.is_exposed(line, text, declaration):
            self.add_member(text, declaration)

    def is_exposed(self, line, text, declaration):
        """[EN] A public, Objective-C visible member that is the type's own API. [CN] 公开、Objective-C 可见且属于该类型自己 API 的成员。"""
        public = self.owner_kind == 'protocol' or re.search(r'\b(public|open)\b', text)
        # [EN] `private(set)` is still public to read; UIKit delegate methods the class adopts are not its own API.
        # [CN] `private(set)` 仍可公开读取；类所采用的 UIKit 代理方法不属于它自己的 API。
        excluded = (re.search(r'\b(private|fileprivate|override|internal)\b(?!\(set\))', text) or '@nonobjc' in text
                    or declaration.group(2) in SWIFT_ADOPTED)
        exposed = self.members or OBJC in text
        if not (public and not excluded and exposed):
            return False
        return not line.startswith('@objc(') or re.match(r'@objc\([\w:]+\)\s+\S', line) is not None

    def add_member(self, text, declaration):
        objc = SWIFT_OBJC_NAME.search(text[:text.find(declaration.group(0))])
        if declaration.group(1) == 'func':
            params = text[text.find('(', declaration.end()) + 1:]
            params = params[:params.find(')')] if ')' in params else params
            name = objc.group(1) if objc else swift_selector(declaration.group(2), params)
            name = ('+' if re.search(r'\b(class|static)\s+func', text) else '-') + name
            kind = 'method'
        else:
            name = objc.group(1) if objc else declaration.group(2)
            kind = 'property'
        self.add(kind, self.owner, name, '%s %s' % (self.owner, name))


def swift_rows():
    """[EN] The public Objective-C symbols of SWIFT_SOURCES, keyed as the header inventory keys them. [CN] SWIFT_SOURCES 的公开
    Objective-C 符号，键与头文件清单相同。"""
    out = []
    for path in SWIFT_SOURCES:
        out += SwiftSourceScanner(path).scan(open(os.path.join(ROOT, path), encoding='utf-8').read())
    seen = set()
    return [row for row in out if not (row['key'] in seen or seen.add(row['key']))]

def rows():
    out = []
    for row in android.inventory():
        row['comment'] = row.get('comment') or comment_of(row['header'], row['name'])
        out.append(row)
    return out + swift_rows()


def load_map():
    if not os.path.exists(MAP_PATH):
        return {}
    with open(MAP_PATH, encoding='utf-8') as handle:
        return json.load(handle)


def document(items, mapping):
    done = sum(1 for r in items if mapping.get(r['key']) and not mapping.get(r['key']).startswith('TODO'))
    score = int(100 * done / len(items)) if items else 0
    out = ['# 鸿蒙 API 对照表 / The HarmonyOS API map', '', '<!-- bound-classes: none -->', '',
           '<!-- Generated by scripts/harmonyos-api-map.py from the public headers and scripts/harmonyos-api-map.json; do not edit by hand. -->',
           '<!-- 由 scripts/harmonyos-api-map.py 根据公开头文件与 scripts/harmonyos-api-map.json 生成；请勿手动编辑。 -->', '',
           '| 中文 | English |', '|:---|:---|',
           '| iOS 库的每个公开符号、其注释（英文部分）与 HarmonyOS NEXT（ArkTS / ArkUI）对应接口；尚未实现时为 TODO。液态玻璃相关接口也计入。任务与参考项目见 [Android-Library.md](Android-Library.md) 的任务记录。 | Every public symbol of the iOS library, its comment (English part) and its HarmonyOS NEXT (ArkTS / ArkUI) counterpart; TODO while not implemented. Liquid Glass APIs count too. Task and reference projects: the task log of [Android-Library.md](Android-Library.md). |',
           '| **完成率：%d / 100**（已实现 %d / 共 %d 个符号）。每实现一个接口，在 `scripts/harmonyos-api-map.json` 中写入其鸿蒙接口并重新生成本文档。 | **Score: %d / 100** (%d of %d symbols implemented). For each API implemented, write its HarmonyOS API into `scripts/harmonyos-api-map.json` and regenerate this document. |'
           % (score, done, len(items), score, done, len(items)), '']
    header = None
    for r in items:
        if r['header'] != header:
            header = r['header']
            out += ['', '### `%s`' % os.path.relpath(header, 'CYLTabBarController').replace(os.sep, '/'), '',
                    '| iOS 公开 API / iOS public API | 接口注释 / Comment | 鸿蒙对应接口 / HarmonyOS API |', '|:---|:---|:---|']
        api = ('%s %s' % (r['owner'], r['name'])) if r['owner'] and r['kind'] in ('method', 'property') else r['name']
        out.append('| `%s` | %s | %s |' % (api.replace('|', '\\|'), r['comment'] or '—', mapping.get(r['key']) or 'TODO'))
    return '\n'.join(out) + '\n'


def main():
    text = document(rows(), load_map())
    if '--check' in sys.argv:
        current = open(DOC_PATH, encoding='utf-8').read() if os.path.exists(DOC_PATH) else ''
        if android.without_navigation(current) != android.without_navigation(text):
            print('docs/HarmonyOS-API-Map.md is stale: run python3 scripts/harmonyos-api-map.py')
            return 1
        return 0
    existing = open(DOC_PATH, encoding='utf-8').read() if os.path.exists(DOC_PATH) else ''
    with open(DOC_PATH, 'w', encoding='utf-8') as handle:
        handle.write(android.with_navigation_of(existing, text) if existing else text)
    print(text.split('\n')[10][:160])
    return 0


if __name__ == '__main__':
    sys.exit(main())
