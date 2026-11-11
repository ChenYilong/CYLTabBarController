#!/usr/bin/env python3
"""Public API comments: one documentation block format per file, on every platform (AGENTS.md, "Comments on public API").

[EN] Every comment on public API, one line or several, is a block in the platform's official documentation form, written
     on its own lines above the declaration (opener, ` * text` lines, closer), and a public file uses one comment format:
       - Objective-C public headers (CYLTabBarController/**/*.h):  /*!  …  */   (HeaderDoc, Xcode Quick Help)
       - Kotlin / Java (Example-Android/cyltabbar, tabpages):      /**  …  */   (KDoc / Javadoc)
       - TypeScript / JavaScript (CrossPlatform/react-native-…):    /**  …  */   (TSDoc / JSDoc)
       - Dart (CrossPlatform/flutter_cyltabbar/lib):               ///          (Effective Dart's only doc form; checked only)
     Reported (exit 1), and rewritten with --fix (same text):
       - a one-line block (`/*! text */`, `/** text */`) → three lines;
       - in an Objective-C header, a `/**` block → `/*!`; `//` / `///` comments right before a declaration or an enum case,
         and every `///` comment → a `/*!` block;
       - a trailing doc comment after code (`///<`, `//!<`, `/**< */`, `/*!< */`, and a trailing `//` on an Objective-C
         declaration) → moved above it, merged into the declaration's existing block when it has one (a second block
         would hide the first);
       - in Dart, a `/**` block (reported only).
     Commented-out code, file headers and `// MARK:` lines are left alone. Python 3 standard library only.
[CN] 公开 API 的每条注释（单行或多行）都使用平台官方文档注释的块形式，独占数行写在声明上方（开头、` * 文字` 行、结尾），每个公开文件只使用一种注释格式
     （各语言见上）。报告（返回 1）并在 --fix 时改写（文字不变）：单行块改为三行；Objective-C 头文件中 `/**` 块改为 `/*!`，声明或枚举值前的 `//`、
     `///` 注释以及所有 `///` 注释改为 `/*!` 块；代码之后的行尾文档注释移到上方，已有文档块时合并进去（否则第二个块会遮住第一个）；Dart 中的 `/**`
     块只报告。注释掉的代码、文件头与 `// MARK:` 不处理。仅使用 Python 3 标准库。

Usage 用法:
    python3 scripts/check-public-api-comments.py          # report
    python3 scripts/check-public-api-comments.py --fix    # rewrite
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINE_COMMENT = re.compile(r'^(\s*)//+[!]? ?(.*)$')
TODO_ONLY = re.compile(r'^\s*//\s*TODO:\s*$')
FILE_HEADER = re.compile(r'^//  |^//\s*$')
MARK = re.compile(r'^\s*//\s*(MARK|pragma)\b')
CODE = re.compile(r'^\s*//+\s*(@|[-+]\s*\(|#|typedef\b|FOUNDATION_EXTERN|static |return |if \(|\}|\{|\*|/\*|.*;\s*$)')
DECLARATION = re.compile(
    r'^\s*(@interface|@protocol|@property|[-+]\s*\(|FOUNDATION_EXTERN|UIKIT_EXTERN|extern |typedef|NS_ENUM|NS_OPTIONS|'
    r'static inline|CYL_EXTERN|#define|[A-Za-z_][\w\s\*]*\([^;]*\)\s*(NS_|CYL_|;))')
ENUM_CASE = re.compile(r'^\s*[A-Za-z_]\w*\s*(=\s*[^,;{}/]*)?\s*(NS_SWIFT_NAME\([^)]*\)\s*)?,?\s*(//.*)?$')
ONE_LINE_BLOCK = re.compile(r'^(\s*)/\*[!*](?!\*)\s*(.*?)\s*\*/\s*$')
TRAILING_DOC = re.compile(r'^(\s*)(\S.*?)\s*(?:///<|//!<)\s?(.*?)\s*$|^(\s*)(\S.*?)\s*/\*[!*]<\s*(.*?)\s*\*/\s*$')
TRAILING_LINE = re.compile(r'^(\s*)(.*?;)\s*//+ ?(.+?)\s*$')


def files():
    """[EN] (path, language) of every public API file. [CN] 每个公开 API 文件的（路径，语言）。"""
    found = []
    for path in glob.glob(os.path.join(ROOT, 'CYLTabBarController', '**', '*.h'), recursive=True):
        if 'Private' not in path:
            found.append((path, 'objc'))
    for module in ('cyltabbar', 'tabpages'):
        for ext in ('kt', 'java'):
            for path in glob.glob(os.path.join(ROOT, 'Example-Android', module, 'src', 'main', '**', '*.' + ext), recursive=True):
                found.append((path, 'jvm'))
    for ext in ('ts', 'tsx', 'js'):
        for path in glob.glob(os.path.join(ROOT, 'CrossPlatform', 'react-native-cyltabbar', 'src', '**', '*.' + ext), recursive=True):
            found.append((path, 'ts'))
    for path in glob.glob(os.path.join(ROOT, 'CrossPlatform', 'flutter_cyltabbar', 'lib', '**', '*.dart'), recursive=True):
        found.append((path, 'dart'))
    return sorted(found)


def merge_into_previous_block(lines, at, texts):
    """[EN] Adds `texts` to the documentation block that ends right before `at`; False when there is none.
    [CN] 把 `texts` 加入紧挨 `at` 之前结束的文档块；没有时返回 False。"""
    if at == 0 or lines[at - 1].strip() != '*/':
        return False
    previous = lines[at - 1]
    indent = previous[:len(previous) - len(previous.lstrip())]
    lines[at - 1:at - 1] = [(indent + '* ' + t).rstrip() for t in texts]
    return True


def block(indent, opener, texts):
    return [indent + opener] + [(indent + ' * ' + t).rstrip() for t in texts] + [indent + ' */']


def objc_line_comment_runs(lines):
    """[EN] Runs of `//` / `///` comments that document something in a header. [CN] 头文件中起文档作用的 `//`、`///` 注释。"""
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
        if not in_header and LINE_COMMENT.match(line) and not MARK.match(line):
            j = i
            while j < len(lines) and LINE_COMMENT.match(lines[j]) and not MARK.match(lines[j]):
                j += 1
            todos = [k for k in range(i, j) if TODO_ONLY.match(lines[k])]
            text = [k for k in range(i, j) if k not in todos]
            following = lines[j] if j < len(lines) else ''
            attached = DECLARATION.match(following) or (in_enum and following.strip() and ENUM_CASE.match(following))
            triple = any(lines[k].lstrip().startswith('///') for k in text)
            if text and (attached or triple) and not any(CODE.match(lines[k]) for k in text):
                yield i, j, todos
            i = j
            continue
        i += 1


def process(lines, language):
    """[EN] (new lines, findings) for one file. [CN] 一个文件的（新内容，问题数）。"""
    findings = 0
    opener = '/*!' if language == 'objc' else '/**'
    if language == 'dart':
        return lines, sum(1 for l in lines if l.lstrip().startswith('/**'))
    # 1. Trailing doc comments → above the code line.
    i = len(lines) - 1
    while i >= 0:
        line = lines[i]
        match = TRAILING_DOC.match(line)
        code_and_text = None
        if match and not line.lstrip().startswith(('/', '*')):
            groups = match.groups()
            code_and_text = (groups[0], groups[1], groups[2]) if groups[1] is not None else (groups[3], groups[4], groups[5])
        elif language == 'objc' and DECLARATION.match(line) and TRAILING_LINE.match(line) and 'http' not in line:
            m = TRAILING_LINE.match(line)
            code_and_text = (m.group(1), m.group(2), m.group(3))
        if code_and_text and code_and_text[2]:
            indent, code, text = code_and_text
            findings += 1
            lines[i] = indent + code
            if not merge_into_previous_block(lines, i, [text]):
                lines[i:i] = block(indent, opener, [text])
        i -= 1
    # 2. Objective-C: documenting `//` / `///` runs → blocks.
    if language == 'objc':
        for start, end, todos in sorted(objc_line_comment_runs(lines), reverse=True):
            findings += 1
            indent = LINE_COMMENT.match(lines[start]).group(1)
            texts = [LINE_COMMENT.match(lines[k]).group(2).rstrip() for k in range(start, end) if k not in todos]
            todo_lines = [lines[k] for k in todos]
            del lines[start:end]
            if merge_into_previous_block(lines, start, texts):
                lines[start:start] = todo_lines
            else:
                lines[start:start] = todo_lines + block(indent, opener, texts)
    # 3. One-line blocks → three lines; Objective-C `/**` → `/*!`.
    result = []
    for line in lines:
        match = ONE_LINE_BLOCK.match(line)
        if match and match.group(2):
            findings += 1
            result.extend(block(match.group(1), opener, [match.group(2)]))
            continue
        if language == 'objc' and re.match(r'^\s*/\*\*(\s|$)', line):
            findings += 1
            line = line.replace('/**', '/*!', 1)
        result.append(line)
    return result, findings


def main():
    do_fix = '--fix' in sys.argv
    total = 0
    for path, language in files():
        with open(path, encoding='utf-8') as handle:
            original = handle.read().split('\n')
        lines, found = process(list(original), language)
        if not found:
            continue
        total += found
        rel = os.path.relpath(path, ROOT)
        if do_fix and language != 'dart':
            with open(path, 'w', encoding='utf-8') as handle:
                handle.write('\n'.join(lines))
        else:
            print('%s: %d comment(s) not in the documentation block format' % (rel, found))
    if total and not do_fix:
        print('%d public API comment(s) to rewrite (run with --fix)' % total)
        return 1
    print('Public API comments OK' if not total else 'Rewrote %d comment(s)' % total)
    return 0


if __name__ == '__main__':
    sys.exit(main())
