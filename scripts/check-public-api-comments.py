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
TODO_ONLY = re.compile(r'^\s*//\s*TODO:\s*$')
MARK = re.compile(r'^\s*//\s*(MARK|pragma)\b')
DECLARATION = re.compile(
    r'^\s*(@interface|@protocol|@property|[-+]\s*\(|FOUNDATION_EXTERN|UIKIT_EXTERN|extern |typedef|NS_ENUM|NS_OPTIONS|'
    r'static inline|CYL_EXTERN|#define|[A-Za-z_][\w\s\*]*\([^;]*\)\s*(NS_|CYL_|;))')
IDENTIFIER = re.compile(r'[A-Za-z_]\w*')
# [EN] The parsers below are string operations, not regular expressions: the expressions they replace backtracked
#      (SonarCloud python:S8786 / S5843). Each docstring gives the expression it implements.
# [CN] 下面的解析使用字符串操作而不是正则表达式：被替换的表达式存在回溯（SonarCloud python:S8786 / S5843）。每个 docstring
#      给出它实现的表达式。
CODE_PREFIXES = ('@', '#', '}', '{', '*', 'FOUNDATION_EXTERN', 'static ', 'return ', 'if (')
SWIFT_NAME = 'NS_SWIFT_NAME('


def split_indent(line):
    """[EN] (leading whitespace, the rest). [CN]（行首空白，其余部分）。"""
    rest = line.lstrip()
    return line[:len(line) - len(rest)], rest


def is_word_char(char):
    return char.isalnum() or char == '_'


def line_comment(line):
    r"""[EN] (indent, text) of a `//` comment line, else None: `^(\s*)//+!? ?(.*)$`.
    [CN] `//` 注释行的（缩进，文字），否则为 None。"""
    indent, rest = split_indent(line)
    if not rest.startswith('//'):
        return None
    text = rest[2:].lstrip('/')
    if text.startswith('!'):
        text = text[1:]
    if text.startswith(' '):
        text = text[1:]
    return indent, text


def is_file_header(line):
    r"""[EN] `^// {2}|^//\s*$`. [CN] 文件头注释行。"""
    return line.startswith('//  ') or (line.startswith('//') and not line[2:].strip())


def is_commented_code(line):
    r"""[EN] A comment holding code: `^\s*//+\s*(@|[-+]\s*\(|#|typedef\b|FOUNDATION_EXTERN|static |return |if \(|\}|\{|\*|/\*|.*;\s*$)`.
    [CN] 注释掉的代码。"""
    rest = line.lstrip()
    if not rest.startswith('//'):
        return False
    body = rest[2:].lstrip('/').lstrip()
    if body.startswith(CODE_PREFIXES) or body.rstrip().endswith(';'):
        return True
    if body[:1] in ('-', '+') and body[1:].lstrip().startswith('('):
        return True
    return body.startswith('typedef') and not is_word_char(body[7:8])


def enum_case_tail_is_valid(rest):
    r"""[EN] `,?\s*(//.*)?$` after optional whitespace. [CN] 枚举项的结尾。"""
    rest = rest.lstrip()
    if rest.startswith(','):
        rest = rest[1:].lstrip()
    return not rest or rest.startswith('//')


def swift_name_then_tail(rest):
    r"""[EN] `(NS_SWIFT_NAME\([^)]*\)\s*)?,?\s*(//.*)?$`. [CN] 可选的 NS_SWIFT_NAME 与结尾。"""
    if enum_case_tail_is_valid(rest):
        return True
    if not rest.startswith(SWIFT_NAME):
        return False
    close = rest.find(')', len(SWIFT_NAME))
    return close >= 0 and enum_case_tail_is_valid(rest[close + 1:])


def is_enum_case(line):
    r"""[EN] An enum case line: `^\s*[A-Za-z_]\w*\s*(=\s*[^,;{}/]*)?\s*(NS_SWIFT_NAME\([^)]*\)\s*)?,?\s*(//.*)?$`.
    [CN] 枚举项所在的行。"""
    match = IDENTIFIER.match(line.lstrip())
    if not match:
        return False
    rest = line.lstrip()[match.end():].lstrip()
    if swift_name_then_tail(rest):
        return True
    if not rest.startswith('='):
        return False
    value = rest[1:]
    end = len(value)
    for index, char in enumerate(value):
        if char in ',;{}/':
            end = index
            break
    # [EN] The value may stop before an NS_SWIFT_NAME(...) holding characters a value cannot have.
    # [CN] 值可以在 NS_SWIFT_NAME(...) 之前结束，括号内可以有值中不允许的字符。
    starts = [end] + [index for index in range(end) if value.startswith(SWIFT_NAME, index)]
    return any(swift_name_then_tail(value[index:].lstrip()) for index in starts)


def one_line_block(line):
    r"""[EN] (indent, text) of a one-line doc block, else None: `^(\s*)/\*[!*](?!\*)\s*(.*?)\s*\*/\s*$`.
    [CN] 单行文档注释块的（缩进，文字），否则为 None。"""
    indent, rest = split_indent(line)
    if not (rest.startswith('/*') and rest[2:3] in ('!', '*') and rest[3:4] != '*'):
        return None
    body = rest[3:].rstrip()
    if not body.endswith('*/'):
        return None
    return indent, body[:-2].strip()


def first_marker(line, start, markers):
    """[EN] The first index at or after `start` where one of `markers` begins, else -1. [CN] 第一个标记的位置。"""
    found = [index for index in (line.find(marker, start) for marker in markers) if index >= 0]
    return min(found) if found else -1


def trailing_doc(line):
    r"""[EN] (indent, code, text) of a code line ending in `///<` / `//!<` / `/*!< */`, else None:
    `^(\s*)(\S.*?)\s*(?:///<|//!<)\s?(.*?)\s*$|^(\s*)(\S.*?)\s*/\*[!*]<\s*(.*?)\s*\*/\s*$`.
    [CN] 以尾随文档注释结尾的代码行的（缩进，代码，文字），否则为 None。"""
    indent, rest = split_indent(line)
    if not rest:
        return None
    start = len(indent) + 1
    marker = first_marker(line, start, ('///<', '//!<'))
    if marker >= 0:
        text = line[marker + 4:]
        if text[:1].isspace():
            text = text[1:]
        return indent, line[len(indent):marker].rstrip(), text.rstrip()
    marker = first_marker(line, start, ('/*!<', '/**<'))
    if marker < 0:
        return None
    body = line[marker + 4:].rstrip()
    if not body.endswith('*/'):
        return None
    return indent, line[len(indent):marker].rstrip(), body[:-2].strip()


def trailing_comment_text(tail, slashes):
    r"""[EN] `( ?)(.+?)\s*$` after `//+`; `slashes` extra slashes can be given back. [CN] `//+` 之后的注释文字。"""
    if tail.startswith(' ') and tail[1:]:
        tail = tail[1:]
    if tail:
        return tail.rstrip() or tail[0]
    return '/' if slashes > 0 else None


def trailing_line(line):
    r"""[EN] (indent, code, text) of `code; // text`, else None: `^(\s*)(.*?;)\s*//+ ?(.+?)\s*$`.
    [CN] `代码; // 文字` 的（缩进，代码，文字），否则为 None。"""
    indent, _ = split_indent(line)
    semicolon = line.find(';', len(indent))
    while semicolon >= 0:
        rest = line[semicolon + 1:].lstrip()
        if rest.startswith('//'):
            after = rest[2:]
            tail = after.lstrip('/')
            text = trailing_comment_text(tail, len(after) - len(tail))
            if text is not None:
                return indent, line[len(indent):semicolon + 1], text
        semicolon = line.find(';', semicolon + 1)
    return None

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


def is_documenting_comment(line):
    return line_comment(line) is not None and not MARK.match(line)


def documenting_run(lines, start, in_enum):
    """[EN] (end, TODO-only lines) of the comment run at `start`, and whether it documents the line after it.
    [CN] 从 `start` 开始的注释段的（结束位置，只有 TODO 的行），以及它是否为其后的一行写文档。"""
    end = start
    while end < len(lines) and is_documenting_comment(lines[end]):
        end += 1
    todos = [k for k in range(start, end) if TODO_ONLY.match(lines[k])]
    text = [k for k in range(start, end) if k not in todos]
    following = lines[end] if end < len(lines) else ''
    attached = DECLARATION.match(following) or (in_enum and following.strip() and is_enum_case(following))
    triple = any(lines[k].lstrip().startswith('///') for k in text)
    documents = bool(text) and bool(attached or triple) and not any(is_commented_code(lines[k]) for k in text)
    return end, todos, documents


def enum_state(line, in_enum):
    """[EN] Whether the lines after `line` are inside an enum. [CN] `line` 之后的行是否在枚举中。"""
    if re.search(r'NS_(ENUM|OPTIONS|CLOSED_ENUM|ERROR_ENUM)\(', line):
        return True
    if in_enum and line.strip().startswith('}'):
        return False
    return in_enum


def objc_line_comment_runs(lines):
    """[EN] Runs of `//` / `///` comments that document something in a header. [CN] 头文件中起文档作用的 `//`、`///` 注释。"""
    in_enum = False
    in_header = True
    i = 0
    while i < len(lines):
        line = lines[i]
        if in_header and not (is_file_header(line) or not line.strip()):
            in_header = False
        in_enum = enum_state(line, in_enum)
        if in_header or not is_documenting_comment(line):
            i += 1
            continue
        end, todos, documents = documenting_run(lines, i, in_enum)
        if documents:
            yield i, end, todos
        i = end


def trailing_code_and_text(line, language):
    """[EN] (indent, code, text) of a line with a trailing comment to move, else None. [CN] 需要移动尾随注释的行。"""
    if not line.lstrip().startswith(('/', '*')):
        found = trailing_doc(line)
        if found:
            return found
    if language == 'objc' and DECLARATION.match(line) and 'http' not in line:
        return trailing_line(line)
    return None


def move_trailing_comments(lines, language, opener):
    """[EN] Step 1: trailing doc comments → above the code line; returns the count. [CN] 第 1 步：尾随文档注释移到代码行上方。"""
    findings = 0
    for i in range(len(lines) - 1, -1, -1):
        code_and_text = trailing_code_and_text(lines[i], language)
        if not (code_and_text and code_and_text[2]):
            continue
        indent, code, text = code_and_text
        findings += 1
        lines[i] = indent + code
        if not merge_into_previous_block(lines, i, [text]):
            lines[i:i] = block(indent, opener, [text])
    return findings


def convert_line_comment_runs(lines, opener):
    """[EN] Step 2 (Objective-C): documenting `//` / `///` runs → blocks; returns the count.
    [CN] 第 2 步（Objective-C）：起文档作用的 `//`、`///` 注释改为注释块。"""
    runs = sorted(objc_line_comment_runs(lines), reverse=True)
    for start, end, todos in runs:
        indent = line_comment(lines[start])[0]
        texts = [line_comment(lines[k])[1].rstrip() for k in range(start, end) if k not in todos]
        todo_lines = [lines[k] for k in todos]
        del lines[start:end]
        if merge_into_previous_block(lines, start, texts):
            lines[start:start] = todo_lines
        else:
            lines[start:start] = todo_lines + block(indent, opener, texts)
    return len(runs)


def expand_one_line_blocks(lines, language, opener):
    """[EN] Step 3: one-line blocks → three lines; Objective-C `/**` → `/*!`. [CN] 第 3 步：单行注释块展开为三行。"""
    findings = 0
    result = []
    for line in lines:
        found = one_line_block(line)
        if found and found[1]:
            findings += 1
            result.extend(block(found[0], opener, [found[1]]))
            continue
        if language == 'objc' and re.match(r'^\s*/\*\*(\s|$)', line):
            findings += 1
            line = line.replace('/**', '/*!', 1)
        result.append(line)
    return result, findings


def process(lines, language):
    """[EN] (new lines, findings) for one file. [CN] 一个文件的（新内容，问题数）。"""
    if language == 'dart':
        return lines, sum(1 for l in lines if l.lstrip().startswith('/**'))
    opener = '/*!' if language == 'objc' else '/**'
    findings = move_trailing_comments(lines, language, opener)
    if language == 'objc':
        findings += convert_line_comment_runs(lines, opener)
    result, expanded = expand_one_line_blocks(lines, language, opener)
    return result, findings + expanded


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
