#!/usr/bin/env python3
"""Public API comments use one documentation block, not stacked single-line comments (AGENTS.md, "Comments on public API").

[EN] A multi-line comment on a public declaration in a public header must be one `/*! ... */` block, so Xcode Quick Help,
     the generated Swift interface and documentation tools show all of it to the caller. Stacked `//` or `///` lines
     before a declaration are reported (exit 1). With --fix they are rewritten into a `/*! ... */` block with the same text;
     a bare `//TODO:` line between the comment and the declaration is moved above the block, so the block stays attached.
     Python 3 standard library only.
[CN] 公开头文件中公开声明上的多行注释必须是一个 `/*! ... */` 块，这样 Xcode Quick Help、生成的 Swift 接口和文档工具才会把全部内容展示给调用者。
     声明前堆叠的 `//` 或 `///` 行会被报告（返回 1）。使用 --fix 时改写为内容相同的 `/*! ... */` 块；注释与声明之间单独的 `//TODO:` 行移到块的上方，
     使块仍紧挨声明。仅使用 Python 3 标准库。

Usage 用法:
    python3 scripts/check-public-api-comments.py          # report
    python3 scripts/check-public-api-comments.py --fix    # rewrite
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINE_COMMENT = re.compile(r'^(\s*)//+ ?(.*)$')
TODO_ONLY = re.compile(r'^\s*//\s*TODO:\s*$')
DECLARATION = re.compile(
    r'^\s*(@interface|@protocol|@property|[-+]\s*\(|FOUNDATION_EXTERN|UIKIT_EXTERN|extern |typedef|NS_ENUM|NS_OPTIONS|'
    r'static inline|CYL_EXTERN|[A-Za-z_][\w\s\*]*\([^;]*\)\s*(NS_|CYL_|;))')


def public_headers():
    """[EN] The headers the podspec makes public. [CN] podspec 公开的头文件。"""
    for path in sorted(glob.glob(os.path.join(ROOT, 'CYLTabBarController', '**', '*.h'), recursive=True)):
        if 'Private' not in path:
            yield path


def blocks(lines):
    """[EN] (start, end, todo lines) of each stacked comment right before a declaration. [CN] 每个紧挨声明的堆叠注释。"""
    i = 0
    while i < len(lines):
        if not LINE_COMMENT.match(lines[i]) or lines[i].lstrip().startswith('//  '):
            i += 1
            continue
        j = i
        while j < len(lines) and LINE_COMMENT.match(lines[j]):
            j += 1
        todos = [k for k in range(i, j) if TODO_ONLY.match(lines[k])]
        text_lines = [k for k in range(i, j) if k not in todos]
        if len(text_lines) >= 2 and j < len(lines) and DECLARATION.match(lines[j]):
            yield i, j, todos
        i = j


def rewrite(lines, start, end, todos):
    indent = LINE_COMMENT.match(lines[start]).group(1)
    body = [LINE_COMMENT.match(lines[k]).group(2).rstrip() for k in range(start, end) if k not in todos]
    block = [lines[k] for k in todos] + [indent + '/*!'] + [(indent + ' * ' + t).rstrip() for t in body] + [indent + ' */']
    return lines[:start] + block + lines[end:]


def main():
    fix = '--fix' in sys.argv
    found = 0
    for path in public_headers():
        with open(path, encoding='utf-8') as handle:
            lines = handle.read().split('\n')
        hits = list(blocks(lines))
        if not hits:
            continue
        found += len(hits)
        for start, _, _ in hits:
            print('%s:%d: stacked // comment on a public declaration' % (os.path.relpath(path, ROOT), start + 1))
        if fix:
            for start, end, todos in reversed(hits):
                lines = rewrite(lines, start, end, todos)
            with open(path, 'w', encoding='utf-8') as handle:
                handle.write('\n'.join(lines))
    if found and not fix:
        print('%d public API comment(s) to rewrite as /*! ... */ (run with --fix)' % found)
        return 1
    print('Public API comments OK' if not found else 'Rewrote %d comment(s)' % found)
    return 0


if __name__ == '__main__':
    sys.exit(main())
