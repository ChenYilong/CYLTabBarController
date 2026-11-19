#!/usr/bin/env python3
"""
[EN] Writes the string tables of the Android example layer (demokit `res/values*/cyl_demo_strings.xml`) from the iOS
     example bundle `Example-Shared/CYLDemo.bundle` (and the core bundle `CYLTabBarController.bundle` for texts both
     show), one values folder per iOS .lproj folder (33 languages), so the Android example says what the iOS example
     says (docs/Configuration-Localization.md, Android example strings). The texts are the English literals the Kotlin
     code passes to `cylDemoText("...")` / `DemoText.string("...")` in demokit and app; each is looked up by its English
     value in the iOS tables, and its resource name is `cyl_demo_` + the first 10 hex digits of its SHA-1 (the same as
     `DemoText.resourceName`). A text the iOS tables lack is reported and shown in English. `--check` fails when a file is
     out of date or a text has no iOS entry (for CI).
[CN] 从 iOS 示例 bundle `Example-Shared/CYLDemo.bundle`（两端都显示的文字取自核心 bundle `CYLTabBarController.bundle`）生成 Android 示例层的
     字符串表（demokit 的 `res/values*/cyl_demo_strings.xml`），每个 iOS .lproj 文件夹对应一个 values 文件夹（33 种语言），使 Android 示例与 iOS
     示例说法一致（docs/Configuration-Localization.md「Android 示例字符串」）。文字为 demokit 与 app 的 Kotlin 代码传给 `cylDemoText("...")` /
     `DemoText.string("...")` 的英文字面量；按英文值在 iOS 字符串表中查找，资源名为 `cyl_demo_` 加 SHA-1 前 10 位十六进制（与
     `DemoText.resourceName` 相同）。iOS 字符串表中没有的文字会被报告，并以英文显示。`--check` 在文件过期或文字没有 iOS 条目时失败（用于 CI）。
"""
import glob
import hashlib
import os
import re
import sys
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUNDLES = [os.path.join(ROOT, 'Example-Shared', 'CYLDemo.bundle'),
           os.path.join(ROOT, 'CYLTabBarController', 'Resources', 'CYLTabBarController.bundle')]
SOURCES = [os.path.join(ROOT, 'Example-Android', 'demokit', 'src', 'main', 'kotlin'),
           os.path.join(ROOT, 'Example-Android', 'app', 'src', 'main', 'kotlin')]
RES = os.path.join(ROOT, 'Example-Android', 'demokit', 'src', 'main', 'res')
FILE = 'cyl_demo_strings.xml'
PAIR = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')
CALL = re.compile(r'(?:cylDemoTextKey|cylDemoText|DemoText\.string)\(\s*"((?:[^"\\$]|\\.)*)"')
KEYS = re.compile(r'cylDemoTextKeys\(([^)]*)\)')
LITERAL = re.compile(r'"((?:[^"\\$]|\\.)*)"')
# [EN] Module apps whose own values/strings.xml are translated from the same tables (by English value), one file per language.
# [CN] 各模块 App 自己的 values/strings.xml 也按英文值从相同的字符串表翻译，每种语言一个文件。
APPS = [os.path.join(ROOT, 'Example-Android', app, 'src', 'main', 'res') for app in ('example-pag', 'example-gif', 'example-rive')]
APP_FILE = 'cyl_app_strings.xml'
STRING = re.compile(r'<string name="([^"]+)"([^>]*)>(.*?)</string>', re.S)


def unescape(text):
    """[EN] A .strings or Kotlin literal to its text (\\" \\n \\\\ \\t). [CN] 将 .strings 或 Kotlin 字面量转为文字。"""
    return re.sub(r'\\(.)', lambda m: {'n': '\n', 't': '\t'}.get(m.group(1), m.group(1)), text)


def load(path):
    table = {}
    for line in open(path, encoding='utf-8'):
        m = PAIR.match(line)
        if m:
            table[unescape(m.group(1))] = unescape(m.group(2))
    return table


def tables():
    """[EN] language -> {key: value}, over both bundles (the example bundle first). [CN] 语言 -> {键: 值}，合并两个 bundle（示例 bundle 优先）。"""
    result = {}
    for bundle in BUNDLES:
        for folder in sorted(glob.glob(os.path.join(bundle, '*.lproj'))):
            language = os.path.basename(folder)[:-len('.lproj')]
            if language.startswith('._'):
                continue
            merged = result.setdefault(language, {})
            for path in sorted(glob.glob(os.path.join(folder, '*.strings'))):
                for key, value in load(path).items():
                    merged.setdefault(key, value)
    return result


def texts():
    found = []
    for source in SOURCES:
        for path in sorted(glob.glob(os.path.join(source, '**', '*.kt'), recursive=True)):
            source_text = open(path, encoding='utf-8').read()
            literals = [m.group(1) for m in CALL.finditer(source_text)]
            for keys in KEYS.finditer(source_text):
                literals += [m.group(1) for m in LITERAL.finditer(keys.group(1))]
            for literal in literals:
                text = unescape(literal)
                if text not in found:
                    found.append(text)
    return found


def app_strings(res):
    """[EN] (name, English text) of a module app's translatable strings. [CN] 模块 App 可翻译字符串的（名称，英文）。"""
    path = os.path.join(res, 'values', 'strings.xml')
    if not os.path.exists(path):
        return []
    result = []
    for name, attributes, value in STRING.findall(open(path, encoding='utf-8').read()):
        if 'translatable="false"' in attributes:
            continue
        text = value.replace("\\'", "'").replace('\\"', '"').replace('\\n', '\n').replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
        result.append((name, text))
    return result


def resource_name(text):
    return 'cyl_demo_' + hashlib.sha1(text.encode('utf-8')).hexdigest()[:10]


def folder_of(language):
    return 'values' if language == 'en' else 'values-b+' + language.replace('-', '+')


def android_escape(text):
    text = escape(text).replace('\\', '\\\\').replace('"', '\\"').replace("'", "\\'").replace('\n', '\\n')
    if text.startswith(('@', '?')):
        text = '\\' + text
    return text


def render(entries):
    lines = ['<?xml version="1.0" encoding="utf-8"?>',
             '<!-- Generated by scripts/android-demo-strings.py from Example-Shared/CYLDemo.bundle; do not edit by hand. -->',
             '<resources>']
    for name, value in entries:
        formatted = ' formatted="false"' if '%' in value else ''
        lines.append(f'    <string name="{name}"{formatted}>{android_escape(value)}</string>')
    lines.append('</resources>')
    return '\n'.join(lines) + '\n'


def main():
    check = '--check' in sys.argv
    all_tables = tables()
    english = all_tables.get('en', {})
    key_of = {}
    for key, value in english.items():
        key_of.setdefault(value, key)
    wanted = texts()
    apps = [(res, app_strings(res)) for res in APPS]
    missing = [text for text in wanted if text not in key_of and text not in english]
    app_missing = [f'{os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(res))))}: {text}' for res, pairs in apps for _, text in pairs
                if text not in key_of and text not in english]
    stale = []
    for language, table in sorted(all_tables.items()):
        entries = []
        for text in wanted:
            key = key_of.get(text, text if text in english else None)
            if key is None:
                continue
            value = table.get(key)
            if value is None:
                continue
            entries.append((resource_name(text), value))
        outputs = [(os.path.join(RES, folder_of(language), FILE), render(entries))]
        for res, pairs in apps:
            if language == 'en' or not pairs:
                continue
            app_entries = []
            for name, text in pairs:
                key = key_of.get(text, text if text in english else None)
                value = table.get(key) if key is not None else None
                app_entries.append((name, value if value is not None else text))
            outputs.append((os.path.join(res, folder_of(language), APP_FILE), render(app_entries)))
        for path, content in outputs:
            write_or_check(path, content, check, stale)
    missing += app_missing
    print(f'{len(wanted)} texts, {len(wanted) - len(missing) + len(app_missing)} with iOS entries, {len(all_tables)} languages; '
          f'{sum(len(p) for _, p in apps)} module app strings.')
    for text in missing:
        print(f'  no iOS entry: {text!r}')
    if check and (stale or missing):
        for path in stale:
            print(f'  out of date: {os.path.relpath(path, ROOT)}')
        print('Run: python3 scripts/android-demo-strings.py (and add missing texts to Example-Shared/CYLDemo.bundle)')
        sys.exit(1)


def write_or_check(path, content, check, stale):
    old = open(path, encoding='utf-8').read() if os.path.exists(path) else None
    if old != content:
        if check:
            stale.append(path)
        else:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'w', encoding='utf-8', newline='\n').write(content)


if __name__ == '__main__':
    main()
