#!/usr/bin/env python3
"""[EN] Copies the strings the HarmonyOS code uses from CYLTabBarController's localization files into HarmonyOS string
     resources, for every language of the iOS bundle (AGENTS.md, "Accessibility and localization in all code").

       python3 HarmonyOS/scripts/sync-strings.py           # writes the string.json files
       python3 HarmonyOS/scripts/sync-strings.py --check   # exit 1 when a string.json is stale

     Source: CYLTabBarController/Resources/CYLTabBarController.bundle/<language>.lproj/CYLTabBarController.strings.
     Output: <module>/src/main/resources/<qualifier>/element/string.json; English goes to "base", the fallback. "%@"
     becomes "%s" (HarmonyOS formats with getStringSync(id, ...args)).
[CN] 把鸿蒙代码用到的字符串从 CYLTabBarController 的本地化文件复制到鸿蒙字符串资源，覆盖 iOS 资源包的所有语言。英文写入 "base"（兜底）；
     "%@" 改为 "%s"。只复制下面列出的键。
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BUNDLE = os.path.join(ROOT, 'CYLTabBarController', 'Resources', 'CYLTabBarController.bundle')
HARMONY = os.path.join(ROOT, 'HarmonyOS')

# [EN] Resource name -> iOS key, per module: only the strings the HarmonyOS code uses.
# [CN] 资源名 -> iOS 键，按模块列出：只包含鸿蒙代码用到的字符串。
MODULES = {
    'cyltabbar': {
        'cyl_badge_new_content': '有新内容',
        'cyl_badge_new_messages': '%@ 条新消息',
        'cyl_plus_button': '加号按钮',
        'cyl_list_separator': '、',
        'cyl_badge_text_NEW': 'NEW',
        'cyl_badge_text_New': 'New',
        'cyl_badge_text_new': 'new',
    },
    'entry': {
        'cyl_demo_home': '首页',
        'cyl_demo_nearby': '同城',
        'cyl_demo_messages': '消息',
        'cyl_demo_me': '我的',
        'cyl_demo_post': '发布',
        'cyl_demo_page': '页面 %@',
    },
}
# [EN] Strings of the demo app itself (module description, ability label), English only: not shown in the UI.
# [CN] 演示 App 自身的字符串（模块描述、Ability 名称），只有英文：不在界面中显示。
ENTRY_EXTRA = {
    'module_desc': 'The demo of CYLTabBarController for HarmonyOS NEXT',
    'EntryAbility_desc': 'CYLTabBarController demo',
    'EntryAbility_label': 'CYLTabBarController',
}


def qualifier(language):
    """[EN] The HarmonyOS resource folder of an .lproj language. [CN] .lproj 语言对应的鸿蒙资源目录。"""
    special = {'en': 'base', 'zh-Hans': 'zh_CN', 'zh-Hant': 'zh_TW', 'pt-BR': 'pt_BR'}
    return special.get(language, language.replace('-', '_'))


def read_strings(path):
    table = {}
    pattern = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;', re.M)
    for key, value in pattern.findall(open(path, encoding='utf-8').read()):
        table[key.encode().decode('unicode_escape').encode('latin-1').decode('utf-8')] = \
            value.encode().decode('unicode_escape').encode('latin-1').decode('utf-8')
    return table


def harmony_value(value):
    return re.sub(r'%(\d+\$)?@', lambda m: '%' + (m.group(1) or '') + 's', value)


def outputs():
    files = {}
    languages = sorted(d[:-6] for d in os.listdir(BUNDLE) if d.endswith('.lproj') and not d.startswith('.'))
    english = read_strings(os.path.join(BUNDLE, 'en.lproj', 'CYLTabBarController.strings'))
    for language in languages:
        table = read_strings(os.path.join(BUNDLE, language + '.lproj', 'CYLTabBarController.strings'))
        for module, keys in MODULES.items():
            strings = []
            for name, key in keys.items():
                value = table.get(key) or english.get(key)
                if value is None:
                    raise SystemExit('missing key %r in en.lproj' % key)
                strings.append({'name': name, 'value': harmony_value(value)})
            if module == 'entry' and language == 'en':
                strings += [{'name': n, 'value': v} for n, v in ENTRY_EXTRA.items()]
            path = os.path.join(HARMONY, module, 'src', 'main', 'resources', qualifier(language), 'element', 'string.json')
            files[path] = json.dumps({'string': strings}, ensure_ascii=False, indent=2) + '\n'
    return files


def main():
    files = outputs()
    if '--check' in sys.argv:
        stale = [p for p, text in files.items() if not os.path.exists(p) or open(p, encoding='utf-8').read() != text]
        for path in stale:
            print('stale: ' + os.path.relpath(path, ROOT))
        return 1 if stale else 0
    for path, text in files.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as handle:
            handle.write(text)
    print('wrote %d string.json files' % len(files))
    return 0


if __name__ == '__main__':
    sys.exit(main())
