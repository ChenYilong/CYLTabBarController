#!/usr/bin/env python3
"""[EN] The HarmonyOS parity tracker of CYLTabBarController (docs/HarmonyOS-Parity.md).

Two tables scored together:
  1. every public API of the iOS library (the inventory of scripts/harmonyos-api-map.py), and
  2. every demo of the Objective-C Example (the rows of docs/ObjC-Example-Parity/README.md),
each with its HarmonyOS counterpart in the second column ("TODO" until implemented).
HarmonyOS counterparts: scripts/harmonyos-api-map.json (API key -> HarmonyOS API) and
scripts/harmonyos-parity.json ({"demos": {"<#>": "<HarmonyOS implementation>"}}).
Score = 100 * (done APIs + done demos) / (all APIs + all demos); no TODO left = 100.

    python3 scripts/harmonyos-parity.py           # writes docs/HarmonyOS-Parity.md
    python3 scripts/harmonyos-parity.py --check   # fails when the document is stale

[CN] CYLTabBarController 鸿蒙对齐进度（docs/HarmonyOS-Parity.md）。两个表格合并打分：1. iOS 库全部公开 API；2. Objective-C
Example 全部演示（docs/ObjC-Example-Parity/README.md 的行）。第二列为鸿蒙对应实现，未实现时为 TODO。
完成率 = 100 × (已完成 API + 已完成演示) / (全部 API + 全部演示)；没有 TODO 即满分。
"""
import importlib.util
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC_PATH = os.path.join(ROOT, 'docs', 'HarmonyOS-Parity.md')
DEMO_MAP_PATH = os.path.join(ROOT, 'scripts', 'harmonyos-parity.json')
EXAMPLE_PARITY = os.path.join(ROOT, 'docs', 'ObjC-Example-Parity', 'README.md')

_spec = importlib.util.spec_from_file_location('harmonyos_api_map', os.path.join(ROOT, 'scripts', 'harmonyos-api-map.py'))
api_map = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(api_map)

# [EN] The HarmonyOS toolchain the port is built and tested with. [CN] 鸿蒙端开发与测试所用的工具链。
HARMONY_VERSION = 'HarmonyOS 6.0.1 (API 21, SDK 6.0.1.112 Release), DevEco Studio 6.0 (DS-243.24978.46.36.601251), ArkTS / ArkUI, Stage model'


def demos():
    """[EN] (#, title) of each Objective-C Example demo. [CN] 每个 Objective-C Example 演示的（序号，标题）。"""
    out = []
    for line in open(EXAMPLE_PARITY, encoding='utf-8'):
        match = re.match(r'^\| (\d+) \| (.*?) \|', line)
        if match:
            out.append((match.group(1), match.group(2)))
    return out


def load(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding='utf-8') as handle:
        return json.load(handle)


# [EN] Full-score criteria: every row's HarmonyOS column carries exactly one status. [CN] 满分标准：每行第二列带一个状态。
STATUS_BUILT = '(built; emulator check pending'
STATUS_VERIFIED = '(verified on emulator'
STATUS_NA = 'N/A on HarmonyOS:'
CRITERIA = [
    ('**满分标准（100 分）**：表 1 与表 2 没有 TODO，且每行第二列只能是以下三种状态之一；`--check` 拒绝不带状态的行。',
     '**Full-score criteria (100)**: no TODO in tables 1 and 2, and every row second column has one of the three statuses below; `--check` rejects a row without one.'),
    ('1. 已编译：`<鸿蒙 API / 文件>` + `(built; emulator check pending / 已编译，模拟器验证待做)`。条件：实现在 `cyltabbar`（库）或 `entry`（演示）中，`scripts/harmonyos-build.sh` 构建成功（`BUILD SUCCESSFUL`），演示可从 entry 的界面进入。计入完成率。',
     '1. Built: `<HarmonyOS API / file>` + `(built; emulator check pending / 已编译，模拟器验证待做)`. Requires: implemented in `cyltabbar` (library) or `entry` (demo), `scripts/harmonyos-build.sh` succeeds (`BUILD SUCCESSFUL`), and a demo can be reached from the entry UI. Counts toward the score.'),
    ('2. 已验证：`<鸿蒙 API / 文件>` + `(verified on emulator: <机型> HarmonyOS <版本>, <日期> / 已在模拟器验证)`。条件：在模拟器或真机上运行，行为与 iOS Example 一致；可见改动附截图（`docs/assets/`）。',
     '2. Verified: `<HarmonyOS API / file>` + `(verified on emulator: <device> HarmonyOS <version>, <date> / 已在模拟器验证)`. Requires: run on the emulator or a real device and behaving as in the iOS Example; a visible change has a screenshot (`docs/assets/`).'),
    ('3. 不适用：以 `N/A on HarmonyOS:` 开头，写明原因与鸿蒙上的等价做法（例如 Objective-C 运行时、UIKit 私有视图层级、已废弃 API）。只用于在 ArkUI 中没有意义的 API，不能用来跳过难做的功能。',
     '3. Not applicable: starts with `N/A on HarmonyOS:` and gives the reason and the HarmonyOS equivalent (e.g. the Objective-C runtime, UIKit private view hierarchy, deprecated APIs). Only for APIs that have no meaning in ArkUI, never to skip a hard feature.'),
    ('4. 待审不适用：以 `TODO: N/A on HarmonyOS:` 开头并写明原因，表示提议标为不适用、尚待审核；仍按 TODO 计，不计入完成率。审核通过后去掉 `TODO: ` 前缀。',
     '4. Proposed not applicable: starts with `TODO: N/A on HarmonyOS:` and a reason; proposed, not yet reviewed; still counts as TODO, not toward the score. Drop the `TODO: ` prefix once reviewed.'),
    ('最终满分：完成率 100，且所有「已编译」行在模拟器上验证后改为「已验证」（验证率 100）。',
     'Final full score: score 100, and every "built" row is checked on the emulator and changed to "verified" (verified rate 100).'),
]


STATUS_PROPOSED_NA = 'TODO: N/A on HarmonyOS:'


def is_done(value):
    """[EN] Counts toward the score: a value that does not start with TODO. [CN] 计入完成率：不以 TODO 开头的值。"""
    return bool(value) and not value.startswith('TODO')


def status_of(value):
    """[EN] built / verified / na, or None when the row has no valid status. [CN] 行状态；无效时为 None。"""
    if value.startswith(STATUS_PROPOSED_NA):
        return 'proposed'
    if value.startswith(STATUS_NA):
        return 'na'
    if STATUS_VERIFIED in value:
        return 'verified'
    if STATUS_BUILT in value:
        return 'built'
    return None


def invalid_rows():
    """[EN] Done rows without a valid status. [CN] 已完成但没有有效状态的行。"""
    bad = [('api', k) for k, v in api_map.load_map().items() if v and not status_of(v)]
    bad += [('demo', k) for k, v in load(DEMO_MAP_PATH).get('demos', {}).items() if v and not status_of(v)]
    return bad


def document():
    apis = api_map.rows()
    api_done = api_map.load_map()
    demo_rows = demos()
    demo_done = load(DEMO_MAP_PATH).get('demos', {})
    done_a = sum(1 for r in apis if is_done(api_done.get(r['key'])))
    done_d = sum(1 for n, _ in demo_rows if is_done(demo_done.get(n)))
    total = len(apis) + len(demo_rows)
    score = int(100 * (done_a + done_d) / total) if total else 0
    values = [api_done.get(r['key']) for r in apis] + [demo_done.get(n) for n, _ in demo_rows]
    verified = sum(1 for v in values if v and status_of(v) in ('verified', 'na'))
    verified_rate = int(100 * verified / total) if total else 0
    out = ['# 鸿蒙端对齐 / HarmonyOS parity', '', '<!-- bound-classes: none -->', '',
           '<!-- Generated by scripts/harmonyos-parity.py; do not edit by hand. -->',
           '<!-- 由 scripts/harmonyos-parity.py 生成；请勿手动编辑。 -->', '',
           '| 中文 | English |', '|:---|:---|',
           '| 鸿蒙系统版本：%s | HarmonyOS version: %s |' % (HARMONY_VERSION, HARMONY_VERSION),
           '| 原则：API 对标 iOS 端；example 对标 iOS 端 Objective-C Example，一比一复刻；内部实现对标 Android 端 Kotlin 源码（`Example-Android/cyltabbar`）迁移到鸿蒙。 | Principles: the API matches iOS; the example is a one-to-one replica of the iOS Objective-C Example; the internals are ported from the Android Kotlin sources (`Example-Android/cyltabbar`). |',
           '| 表 1：iOS 库的全部公开 API；表 2：iOS Objective-C Example 的全部演示（[ObjC-Example-Parity](ObjC-Example-Parity/README.md)）。第二列为鸿蒙对应实现，默认 TODO；每完成一个功能，在 `scripts/harmonyos-api-map.json`（API）或 `scripts/harmonyos-parity.json`（演示）写入实现并运行 `python3 scripts/harmonyos-parity.py`，移除一个 TODO。 | Table 1: every public API of the iOS library; table 2: every demo of the iOS Objective-C Example ([ObjC-Example-Parity](ObjC-Example-Parity/README.md)). The second column is the HarmonyOS implementation, TODO by default; for each feature done, write it into `scripts/harmonyos-api-map.json` (APIs) or `scripts/harmonyos-parity.json` (demos) and run `python3 scripts/harmonyos-parity.py`, removing one TODO. |',
           '| **完成率（两表合并）：%d / 100**：API %d / %d，演示 %d / %d；没有 TODO 即 100。 | **Score (both tables): %d / 100**: APIs %d / %d, demos %d / %d; no TODO left is 100. |'
           % (score, done_a, len(apis), done_d, len(demo_rows), score, done_a, len(apis), done_d, len(demo_rows)),
           '| **验证率：%d / 100**：已验证或不适用 %d / %d。 | **Verified rate: %d / 100**: verified or not applicable %d / %d. |'
           % (verified_rate, verified, total, verified_rate, verified, total)]
    out += ['| %s | %s |' % pair for pair in CRITERIA]
    out += ['',
           '## 表 1：iOS 公开 API / Table 1: iOS public APIs']
    header = None
    for r in apis:
        if r['header'] != header:
            header = r['header']
            out += ['', '### `%s`' % os.path.relpath(header, 'CYLTabBarController').replace('\\', '/'), '',
                    '| iOS 公开 API / iOS public API | 鸿蒙对应实现 / HarmonyOS implementation | 接口注释 / Comment |', '|:---|:---|:---|']
        api = ('%s %s' % (r['owner'], r['name'])) if r['owner'] and r['kind'] in ('method', 'property') else r['name']
        out.append('| `%s` | %s | %s |' % (api.replace('|', '\\|'), api_done.get(r['key']) or 'TODO', r['comment'] or '—'))
    out += ['', '## 表 2：Example 演示 / Table 2: Example demos', '',
            '| # | 鸿蒙对应实现 / HarmonyOS implementation | iOS Example 演示 / iOS Example demo |', '|:---|:---|:---|']
    for number, title in demo_rows:
        out.append('| %s | %s | %s |' % (number, demo_done.get(number) or 'TODO', title))
    return '\n'.join(out) + '\n', score


def main():
    text, score = document()
    current = open(DOC_PATH, encoding='utf-8').read() if os.path.exists(DOC_PATH) else ''
    if '--check' in sys.argv:
        bad = invalid_rows()
        if bad:
            print('rows without a status (built / verified / N/A on HarmonyOS:):', bad[:20])
            return 1
        if api_map.android.without_navigation(current) != api_map.android.without_navigation(text):
            print('docs/HarmonyOS-Parity.md is stale: run python3 scripts/harmonyos-parity.py')
            return 1
        return 0
    with open(DOC_PATH, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(api_map.android.with_navigation_of(current, text) if current else text)
    print('score', score)
    return 0


if __name__ == '__main__':
    sys.exit(main())
