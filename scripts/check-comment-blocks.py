#!/usr/bin/env python3
"""Finds Objective-C comment blocks that lost their opener: lines outside any comment that look like the inside of one.

[EN] A merge can keep the lines of a `/*! ... */` documentation block but lose its `/*!` (when that line is shared by
     both sides of a conflict and the two sides are joined). The remaining ` * [EN] ...` lines are then plain text in
     the header: a compile error that is easy to miss in review. This prints every line outside a comment that starts
     with `*` (a comment's inside or its `*/`) and exits 1 when there is one. Python 3 standard library only.
[CN] 合并时可能保留了 `/*! ... */` 文档注释的内容，却丢失了它的 `/*!`（该行为冲突两侧共用、两侧被拼接时）。剩下的 ` * [EN] ...` 行就成了
     头文件中的普通文本：一个在审查中容易被忽略的编译错误。本脚本列出所有注释之外、以 `*` 开头的行（注释内部或 `*/`），存在时返回 1。
     仅使用 Python 3 标准库。

Usage 用法:
    python3 scripts/check-comment-blocks.py                 # every .h / .m under CYLTabBarController/ and Example*/
    python3 scripts/check-comment-blocks.py path/to/File.h  # given files or folders 指定的文件或目录
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRAY = re.compile(r'^\s*\*(\s|/|$)')


def stray_lines(text):
    """(line number, line) of every line outside a comment that starts with `*`. 注释之外以 `*` 开头的每一行。"""
    found, in_comment = [], False
    for number, line in enumerate(text.split('\n'), 1):
        if not in_comment and STRAY.match(line):
            found.append((number, line))
        i = 0
        while i < len(line):
            if not in_comment and line.startswith('//', i):
                break
            if not in_comment and line[i] == '"':
                j = i + 1
                while j < len(line) and line[j] != '"':
                    j += 2 if line[j] == '\\' else 1
                i = j + 1
                continue
            if not in_comment and line.startswith('/*', i):
                in_comment, i = True, i + 2
                continue
            if in_comment and line.startswith('*/', i):
                in_comment, i = False, i + 2
                continue
            i += 1
    return found


def files(paths):
    for base in paths:
        if os.path.isfile(base):
            yield base
            continue
        for directory, dirs, names in os.walk(base):
            dirs[:] = [d for d in dirs if d not in ('Pods', '.git', 'build')]
            for name in sorted(names):
                if name.endswith(('.h', '.m')):
                    yield os.path.join(directory, name)


def main():
    paths = sys.argv[1:] or [os.path.join(ROOT, 'CYLTabBarController')] + sorted(
        os.path.join(ROOT, d) for d in os.listdir(ROOT) if d.startswith('Example'))
    count = checked = 0
    for path in files(paths):
        checked += 1
        for number, line in stray_lines(open(path, encoding='utf-8', errors='replace').read()):
            print('%s:%d: %s' % (os.path.relpath(path, ROOT), number, line.strip()[:100]))
            count += 1
    print('%d file(s) checked, %d line(s) of a comment without its opener.' % (checked, count))
    return 1 if count else 0


if __name__ == '__main__':
    sys.exit(main())
