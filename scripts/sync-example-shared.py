#!/usr/bin/env python3
"""
[EN] Copies what the examples share from Example-Shared into the React Native and Flutter examples, which cannot read
     files outside their own folders (Metro, Flutter assets):
     - Example-Shared/DemoList/demo-list.json and icons/ -> the demo list of the Objective-C example.
     - strings.json: the translations of demo-list.json and ui-texts.json, from the library's string tables.
     React Native also gets src/demo/icons.ts, the `require()` of every icon. Run it after changing Example-Shared;
     `--check` fails when a copy is out of date (for CI).
[CN] 把示例共用的内容从 Example-Shared 复制到 React Native 与 Flutter 示例（它们无法读取自身目录以外的文件：Metro、Flutter assets）：
     - Example-Shared/DemoList/demo-list.json 与 icons/ -> Objective-C 示例的演示列表。
     - strings.json：demo-list.json 与 ui-texts.json 的翻译，来自库的字符串表。
     React Native 还会得到 src/demo/icons.ts，即每个图标的 `require()`。修改 Example-Shared 后运行；`--check` 在副本过期时失败（用于 CI）。
"""
import filecmp
import json
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, 'Example-Shared', 'DemoList')
TARGETS = [
    os.path.join(ROOT, 'CrossPlatform', 'react-native-cyltabbar', 'example', 'src', 'demo'),
    os.path.join(ROOT, 'CrossPlatform', 'flutter_cyltabbar', 'example', 'assets', 'demo'),
]
RN_ICONS = os.path.join(TARGETS[0], 'icons.ts')


# [EN] Translations of the examples' texts (demo-list.json and ui-texts.json, in English), generated from the library's
#      string tables (CYLTabBarController.bundle/<language>.lproj): one table per language, English text -> translation.
#      A text matches an English value of the table; {name} and numbers match %@ / %1$@; "N. Title (API)" keeps N and
#      the API. Texts the Objective-C example shows untranslated (edge cases, API names) stay English.
# [CN] 示例文字（demo-list.json 与 ui-texts.json，英文）的翻译，由库的字符串表（CYLTabBarController.bundle/<语言>.lproj）生成：
#      每种语言一张表，英文 -> 译文。文字与表中的英文值匹配；{name} 与数字匹配 %@ / %1$@；"N. 标题 (API)" 保留 N 与 API。
#      Objective-C 示例中不翻译的文字（异常用例、API 名称）保持英文。
BUNDLE = os.path.join(ROOT, 'CYLTabBarController', 'Resources', 'CYLTabBarController.bundle')
# [EN] The texts only the examples show (Play all, Speed, Loop...) are in the example layer's bundle; the library's tables win.
# [CN] 只有示例显示的文字（全部播放、速度、循环等）在示例层的 bundle 中；库的字符串表优先。
DEMO_BUNDLE = os.path.join(ROOT, 'Example-Shared', 'CYLDemo.bundle')
STRINGS = 'strings.json'

STRINGS_PAIR = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)";', re.M)
PLACEHOLDER = re.compile(r'%(?:(\d+)\$)?@')
SLOT = re.compile(r'\{[A-Za-z]+\}|\d+(?:\.\d+)?')
BADGE_ROW = re.compile(r'^(\d+)\. (.*?)(?: \(([^()]*)\))?$')
LPROJ = '.lproj'


def strings_table(language):
    """[EN] One .strings file of the library as a dictionary. [CN] 库的一个 .strings 文件，转为字典。"""
    path = os.path.join(BUNDLE, language + LPROJ, 'CYLTabBarController.strings')
    unescape = lambda text: text.replace('\\"', '"').replace('\\n', '\n').replace('\\\\', '\\')
    table = {unescape(key): unescape(value) for key, value in STRINGS_PAIR.findall(open(path, encoding='utf-8').read())}
    demo_path = os.path.join(DEMO_BUNDLE, language + LPROJ, 'CYLDemo.strings')
    if os.path.exists(demo_path):
        for key, value in STRINGS_PAIR.findall(open(demo_path, encoding='utf-8').read()):
            table.setdefault(unescape(key), unescape(value))
    return table


def example_texts():
    """[EN] Every text of demo-list.json and ui-texts.json, in order. [CN] demo-list.json 与 ui-texts.json 中的全部文字，按顺序。"""
    texts = []

    def walk(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if key in ('title', 'subtitle') and isinstance(value, str):
                    texts.append(value)
                else:
                    walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    walk(json.load(open(os.path.join(SOURCE, 'demo-list.json'), encoding='utf-8')))
    texts += json.load(open(os.path.join(SOURCE, 'ui-texts.json'), encoding='utf-8'))['texts']
    return [text for text in dict.fromkeys(texts) if text.strip()]


class CYLTranslator:
    """[EN] Finds the key of an English text in the library's tables and translates it. [CN] 在库的字符串表中找到英文文字的键并翻译。"""

    def __init__(self, tables):
        self.tables = tables
        self.english = tables['en']
        # [EN] The English value with its placeholders as \0 -> its key. [CN] 占位符替换为 \0 的英文值 -> 键。
        self.keys = {}
        for key, value in self.english.items():
            self.keys.setdefault(PLACEHOLDER.sub('\0', value), key)

    def translation(self, key, language, arguments):
        """[EN] The key's text in `language`, its %@ / %n$@ filled with `arguments` (1-based). [CN] 键在 `language` 中的文字，其 %@ / %n$@ 用 `arguments`（从 1 开始）填入。"""
        text = self.tables[language].get(key, self.english[key])
        position = [0]

        def fill(match):
            if match.group(1):
                return arguments.get(int(match.group(1)), '')
            position[0] += 1
            return arguments.get(position[0], '')

        return PLACEHOLDER.sub(fill, text)

    def resolve(self, text):
        """[EN] A function language -> translation of `text`, or None. [CN] 返回「语言 -> `text` 的译文」的函数，找不到时为 None。"""
        if text in self.keys:
            key = self.keys[text]
            return lambda language: self.tables[language].get(key, text)
        return self.resolve_slots(text) or self.resolve_badge_row(text)

    def resolve_slots(self, text):
        """[EN] `text` with {name} and, if needed, numbers as the placeholders. [CN] 以 {name} 以及必要时数字作为占位符的 `text`。"""
        for numbers_are_slots in (False, True):
            slots = [match for match in SLOT.finditer(text) if numbers_are_slots or match.group(0).startswith('{')]
            key = self.keys.get(skeleton_of(text, slots)) if slots else None
            if key is None:
                continue
            # [EN] The i-th placeholder of the English value is argument n (%n$@) or i. [CN] 英文值中第 i 个占位符为第 n 个参数（%n$@）或第 i 个。
            order = [int(match.group(1)) if match.group(1) else index + 1
                     for index, match in enumerate(PLACEHOLDER.finditer(self.english[key]))]
            arguments = {order[index]: slot.group(0) for index, slot in enumerate(slots)}
            return lambda language, key=key, arguments=arguments: self.translation(key, language, arguments)
        return None

    def resolve_badge_row(self, text):
        """[EN] Badge rows: "N. " + title + an optional " (API)", the API kept as is. [CN] 角标行："N. " + 标题 + 可选的 " (API)"，API 保持原样。"""
        match = BADGE_ROW.match(text)
        if not match:
            return None
        number, title, api = match.groups()
        for candidate, kept_api in ((title + (f' ({api})' if api else ''), None), (title, api)):
            inner = self.resolve(candidate)
            if inner:
                return lambda language, inner=inner, kept_api=kept_api: f'{number}. {inner(language)}' + (f' ({kept_api})' if kept_api else '')
        return None


def skeleton_of(text, slots):
    """[EN] `text` with every slot replaced by "\\0". [CN] 把每个占位符替换为 "\\0" 后的 `text`。"""
    skeleton, last = '', 0
    for match in slots:
        skeleton += text[last:match.start()] + '\0'
        last = match.end()
    return skeleton + text[last:]

def strings_source():
    """[EN] strings.json: language -> {English text: translation}, only texts that differ. [CN] strings.json：语言 -> {英文: 译文}，只保留不同的文字。"""
    languages = sorted(name[:-len(LPROJ)] for name in os.listdir(BUNDLE) if name.endswith(LPROJ) and not name.startswith('._'))
    translator = CYLTranslator({language: strings_table(language) for language in languages})
    resolved = {text: function for text in example_texts() if (function := translator.resolve(text))}
    tables = {language: {text: function(language) for text, function in resolved.items() if function(language) != text}
              for language in languages}
    return json.dumps(tables, ensure_ascii=False, separators=(',', ':'), sort_keys=True) + '\n'


def icon_names():
    return sorted(name[:-4] for name in os.listdir(os.path.join(SOURCE, 'icons'))
                  if name.endswith('.png') and not name.startswith('._'))


def rn_icons_source():
    lines = [
        '// Generated by scripts/sync-example-shared.py from Example-Shared/DemoList/icons. Do not edit.',
        '// 由 scripts/sync-example-shared.py 根据 Example-Shared/DemoList/icons 生成，请勿手动修改。',
        'export const DEMO_ICONS: Record<string, number> = {',
    ]
    lines += [f"  {name}: require('./icons/{name}.png')," for name in icon_names()]
    lines += ['};', '']
    return '\n'.join(lines)


def files():
    yield 'demo-list.json'
    for name in icon_names():
        yield os.path.join('icons', name + '.png')


def stale_copies():
    """[EN] Copies that differ from Example-Shared, and icons it no longer has. [CN] 与 Example-Shared 不同的副本，以及它已没有的图标。"""
    stale = []
    for target in TARGETS:
        for relative in files():
            copy = os.path.join(target, relative)
            if not os.path.exists(copy) or not filecmp.cmp(os.path.join(SOURCE, relative), copy, shallow=False):
                stale.append(copy)
    kept = {name + '.png' for name in icon_names()}
    for target in TARGETS:
        folder = os.path.join(target, 'icons')
        if os.path.isdir(folder):
            stale += [os.path.join(folder, name) for name in os.listdir(folder)
                      if name.endswith('.png') and not name.startswith('._') and name not in kept]
    return stale


def is_stale(path, content):
    return not os.path.exists(path) or open(path, encoding='utf-8').read() != content


def check():
    stale = stale_copies()
    if is_stale(RN_ICONS, rn_icons_source()):
        stale.append(RN_ICONS)
    strings = strings_source()
    stale += [os.path.join(target, STRINGS) for target in TARGETS if is_stale(os.path.join(target, STRINGS), strings)]
    for path in stale:
        print(f'error: {os.path.relpath(path, ROOT)} is out of date: run scripts/sync-example-shared.py')
    return 1 if stale else 0

def sync():
    for target in TARGETS:
        os.makedirs(os.path.join(target, 'icons'), exist_ok=True)
        for relative in files():
            shutil.copyfile(os.path.join(SOURCE, relative), os.path.join(target, relative))
        # [EN] Icons removed or renamed in Example-Shared go away from the copies too. [CN] Example-Shared 中删除或改名的图标也从副本中移除。
        kept = {name + '.png' for name in icon_names()}
        for name in os.listdir(os.path.join(target, 'icons')):
            if name.endswith('.png') and not name.startswith('._') and name not in kept:
                os.remove(os.path.join(target, 'icons', name))
    with open(RN_ICONS, 'w', encoding='utf-8') as file:
        file.write(rn_icons_source())
    strings = strings_source()
    for target in TARGETS:
        with open(os.path.join(target, STRINGS), 'w', encoding='utf-8') as file:
            file.write(strings)
    print('Synced Example-Shared/DemoList into the React Native and Flutter examples.')
    return 0


if __name__ == '__main__':
    sys.exit(check() if '--check' in sys.argv else sync())
