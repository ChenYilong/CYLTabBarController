#!/usr/bin/env python3
"""Public API comments use one documentation block format (AGENTS.md, "Comments on public API").

[EN] Every comment on a public declaration in a public header, one line or several, is a `/*! ... */` block, so Xcode Quick
     Help, the generated Swift interface and documentation tools show it to the caller, and every public header keeps one
     comment format. Reported (exit 1): `//` or `///` lines right before a declaration or an enum case, and a trailing
     `// ...` after a declaration. With --fix each becomes a `/*! ... */` block with the same text, placed before the
     declaration (merged into the declaration's existing block when it has one, which would otherwise be hidden); a bare `//TODO:` line is moved above the block, so the block stays attached. Commented-out code, file
     headers and `// MARK:` lines are left alone. Python 3 standard library only.
[CN] 公开头文件中公开声明上的每条注释（单行或多行）都是 `/*! ... */` 块，这样 Xcode Quick Help、生成的 Swift 接口和文档工具才会展示给调用者，
     且每个公开头文件只使用一种注释格式。报告（返回 1）：紧挨声明或枚举值之前的 `//`、`///` 行，以及声明之后的行尾 `// ...`。使用 --fix 时
     改写为内容相同、位于声明之前的 `/*! ... */` 块；单独的 `//TODO:` 行移到块的上方，使块仍紧挨声明。注释掉的代码、文件头与 `// MARK:` 不处理。
     仅使用 Python 3 标准库。

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
FILE_HEADER = re.compile(r'^//  |^//\s*$')
MARK = re.compile(r'^\s*//\s*(MARK|pragma)\b')
CODE = re.compile(r'^\s*//+\s*(@|[-+]\s*\(|#|typedef\b|FOUNDATION_EXTERN|static |return |if \(|\}|\{|.*;\s*$)')
DECLARATION = re.compile(
    r'^\s*(@interface|@protocol|@property|[-+]\s*\(|FOUNDATION_EXTERN|UIKIT_EXTERN|extern |typedef|NS_ENUM|NS_OPTIONS|'
    r'static inline|CYL_EXTERN|[A-Za-z_][\w\s\*]*\([^;]*\)\s*(NS_|CYL_|;))')
ENUM_CASE = re.compile(r'^\s*[A-Za-z_]\w*\s*(=\s*[^,;{}/]*)?\s*(NS_SWIFT_NAME\([^)]*\)\s*)?,?\s*(//.*)?$')
TRAILING = re.compile(r'^(\s*)(.*?;)\s*//+ ?(.+?)\s*$')


def public_headers():
    """[EN] The headers the podspec makes public. [CN] podspec 公开的头文件。"""
    for path in sorted(glob.glob(os.path.join(ROOT, 'CYLTabBarController', '**', '*.h'), recursive=True)):
        if 'Private' not in path:
            yield path


def is_comment(line):
    return bool(LINE_COMMENT.match(line)) and not MARK.match(line)


def findings(lines):
    """[EN] ('block', start, end, todos) and ('trailing', index) findings. [CN] 查找结果。"""
    in_enum = False
    in_header = True
    i = 0
    while i < len(lines):
        line = lines[i]
        if in_header and not (FILE_HEADER.match(line) or not line.strip()):
            in_header = False
        if re.search(r'NS_(ENUM|OPTIONS|CLOSED_ENUM|ERROR_ENUM)\(', line):
            in_enum = True
        elif in_enum and line.strip().startswith('}'):
            in_enum = False
        if not in_header and is_comment(line):
            j = i
            while j < len(lines) and is_comment(lines[j]):
                j += 1
            todos = [k for k in range(i, j) if TODO_ONLY.match(lines[k])]
            text = [k for k in range(i, j) if k not in todos]
            following = lines[j] if j < len(lines) else ''
            attached = DECLARATION.match(following) or (in_enum and following.strip() and ENUM_CASE.match(following))
            if text and attached and not any(CODE.match(lines[k]) for k in text):
                yield ('block', i, j, todos)
            i = j
            continue
        if not in_header and DECLARATION.match(line) and TRAILING.match(line) and '"' not in line.split('//')[0][-1:]:
            yield ('trailing', i)
        i += 1


def merge_into_previous_block(lines, at, texts):
    """[EN] When the line before `at` closes a documentation block, add `texts` to that block and return True: a second
    block would hide the first one (the nearest block documents the declaration).
    [CN] 若 `at` 的上一行结束了一个文档块，把 `texts` 加入该块并返回 True：再加一个块会遮住原来的块（离声明最近的块生效）。"""
    if at == 0:
        return False
    previous = lines[at - 1]
    if previous.strip() == '*/':
        indent = previous[:len(previous) - len(previous.lstrip())]
        lines[at - 1:at - 1] = [(indent + '* ' + t).rstrip() for t in texts]
        return True
    single = re.match(r'^(\s*)/\*!\s*(.*?)\s*\*/\s*$', previous)
    if single:
        indent = single.group(1)
        lines[at - 1:at] = [indent + '/*!', (indent + ' * ' + single.group(2)).rstrip()] + [(indent + ' * ' + t).rstrip() for t in texts] + [indent + ' */']
        return True
    return False


def fix(lines, found):
    for item in sorted(found, key=lambda f: f[1], reverse=True):
        if item[0] == 'block':
            _, start, end, todos = item
            indent = LINE_COMMENT.match(lines[start]).group(1)
            body = [LINE_COMMENT.match(lines[k]).group(2).rstrip() for k in range(start, end) if k not in todos]
            todo_lines = [lines[k] for k in todos]
            del lines[start:end]
            if merge_into_previous_block(lines, start, body):
                lines[start:start] = todo_lines
            else:
                lines[start:start] = todo_lines + [indent + '/*!'] + [(indent + ' * ' + t).rstrip() for t in body] + [indent + ' */']
        else:
            index = item[1]
            match = TRAILING.match(lines[index])
            indent, code, text = match.group(1), match.group(2), match.group(3)
            lines[index] = indent + code
            if not merge_into_previous_block(lines, index, [text]):
                lines[index:index] = [indent + '/*!', indent + ' * ' + text, indent + ' */']
    return lines


def main():
    do_fix = '--fix' in sys.argv
    total = 0
    for path in public_headers():
        with open(path, encoding='utf-8') as handle:
            lines = handle.read().split('\n')
        found = list(findings(lines))
        if not found:
            continue
        total += len(found)
        if do_fix:
            with open(path, 'w', encoding='utf-8') as handle:
                handle.write('\n'.join(fix(lines, found)))
        else:
            for item in found:
                kind = 'trailing // comment' if item[0] == 'trailing' else '// comment'
                print('%s:%d: %s on a public declaration' % (os.path.relpath(path, ROOT), item[1] + 1, kind))
    if total and not do_fix:
        print('%d public API comment(s) to rewrite as /*! ... */ (run with --fix)' % total)
        return 1
    print('Public API comments OK' if not total else 'Rewrote %d comment(s)' % total)
    return 0


if __name__ == '__main__':
    sys.exit(main())
