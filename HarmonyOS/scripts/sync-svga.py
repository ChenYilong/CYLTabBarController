#!/usr/bin/env python3
"""[EN] Copies the SVGA tab icons of Example-SwiftUI-Rive (SVGAAssets, Apache-2.0, see its NOTICE.md) into the demo's
     rawfile folder, entry/src/main/resources/rawfile/svga. `--check` exits 1 when a copy is missing or differs.
[CN] 把 Example-SwiftUI-Rive 的 SVGA Tab 图标（SVGAAssets，Apache-2.0，见其 NOTICE.md）复制到演示的 rawfile 目录
     entry/src/main/resources/rawfile/svga。`--check` 在副本缺失或不同时以 1 退出。
"""
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCE = os.path.join(ROOT, 'Example-SwiftUI-Rive', 'AnimatedApp', 'SVGAAssets')
TARGET = os.path.join(ROOT, 'HarmonyOS', 'entry', 'src', 'main', 'resources', 'rawfile', 'svga')
FILES = ['tab_home.svga', 'tab_search.svga', 'tab_chat.svga', 'tab_profile.svga', 'NOTICE.md']


def main():
    stale = [f for f in FILES if not os.path.exists(os.path.join(TARGET, f))
             or open(os.path.join(TARGET, f), 'rb').read() != open(os.path.join(SOURCE, f), 'rb').read()]
    if '--check' in sys.argv:
        for name in stale:
            print('stale: ' + name)
        return 1 if stale else 0
    os.makedirs(TARGET, exist_ok=True)
    for name in stale:
        shutil.copyfile(os.path.join(SOURCE, name), os.path.join(TARGET, name))
    print('copied %d file(s)' % len(stale))
    return 0


if __name__ == '__main__':
    sys.exit(main())
