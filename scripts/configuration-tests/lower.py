#!/usr/bin/env python3
"""Linux only: lowers the Objective-C 2 features GNUstep's GCC runtime lacks, so the parser can be tested there.

[EN] Ubuntu's GNUstep is built for the GCC Objective-C runtime, where clang supports neither object subscripting nor
     auto-synthesized properties. This rewrites a copy of a source file: subscripts become CYLSubGet / CYLSubSet calls
     (cyl_sub.h) and properties get explicit ivars and @synthesize. The library is never changed; on macOS
     run-tests.sh builds the real file directly. Test tool only, Python 3 standard library.
[CN] Ubuntu 的 GNUstep 基于 GCC Objective-C 运行时，clang 在该运行时下不支持对象下标与属性自动合成。本脚本改写源文件的副本：下标改为
     CYLSubGet / CYLSubSet 调用（cyl_sub.h），属性改为显式实例变量与 @synthesize。不会修改库本身；在 macOS 上 run-tests.sh 直接编译原文件。
     仅为测试工具，使用 Python 3 标准库。

Usage 用法: python3 lower.py Source.m > Source_lowered.m
"""
import os
import re
import sys
import tempfile

# [EN] The repository and the temporary folder. [CN] 仓库与临时目录。
ALLOWED_ROOTS = (os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), tempfile.gettempdir())


def confined_path(path, roots):
    """[EN] The real path of `path` when it lies inside one of `roots`, else exit: no path traversal from arguments.
    [CN] `path` 位于 `roots` 之一内时返回其真实路径，否则退出：防止通过参数进行路径穿越。"""
    real = os.path.realpath(path)
    for root in roots:
        root = os.path.realpath(root)
        if real == root or real.startswith(root + os.sep):
            return real
    sys.exit('%s: outside %s' % (path, ' / '.join(roots)))


C_ARRAYS = {'pair', 'argv', 'cases', 'bytes', 'trailer'}
# [EN] "(int)[self peek]": a message send after a cast, not a subscript. [CN] 类型转换后的消息发送，不是下标。
CAST_SEND = re.compile(r'^\s*[\w.]+\s+[A-Za-z_]\w*\s*(:|$)')
ASSIGNMENT = re.compile(r'\s*=(?!=)')


def is_identifier_character(c):
    return c.isalnum() or c == '_'


# 1. Properties -> explicit ivars + @synthesize. 属性 -> 显式实例变量 + @synthesize。

def interface_bodies(src):
    """[EN] (class name, body) of every @interface ... @end, found without backtracking regexes.
    [CN] 每个 @interface ... @end 的（类名，内容），不使用会回溯的正则。"""
    position = src.find('@interface ')
    while position >= 0:
        name = re.match(r'\w+', src[position + len('@interface '):])
        line_end = src.find('\n', position)
        end = src.find('@end', line_end) if line_end >= 0 else -1
        if not name or end < 0:
            return
        yield name.group(0), src[line_end + 1:end]
        position = src.find('@interface ', end + len('@end'))


def properties(body):
    """[EN] (type, name) of every @property of a class body. [CN] 类内容中每个 @property 的（类型，名称）。"""
    found = []
    for match in re.finditer(r'@property\s*\([^)]*\)([^;\n]*);', body):
        declaration = match.group(1).lstrip()
        k = len(declaration)
        while k > 0 and is_identifier_character(declaration[k - 1]):
            k -= 1
        if k < len(declaration):
            found.append((declaration[:k].replace('_Nullable', '').strip(), declaration[k:]))
    return found


def synthesize_properties(src):
    for name, body in list(interface_bodies(src)):
        declared = properties(body)
        if not declared:
            continue
        ivars = '{\n' + ''.join(f'  {t} _{n};\n' for t, n in declared) + '}\n'
        src = re.sub(r'(@interface ' + name + r'\b[^\n{]*\n)', lambda m, text=ivars: m.group(1) + text, src, count=1)
        synthesized = ''.join(f'@synthesize {n} = _{n};\n' for _, n in declared)
        src = re.sub(r'(@implementation ' + name + r'\b[^\n]*\n)', lambda m, text=synthesized: m.group(1) + text, src, count=1)
    return src


# 2. Subscripts -> CYLSubGet / CYLSubSet (strings, chars and comments are skipped; the C arrays above stay).
#    下标 -> CYLSubGet / CYLSubSet（跳过字符串、字符与注释；上面列出的 C 数组保持不变）。

def opener_index(emitted, b, closer):
    """[EN] Index of the bracket that opens the one ending at `b`. [CN] 与 `b` 处结束的括号配对的左括号位置。"""
    opener = '(' if closer == ')' else '['
    depth = 0
    while b > 0:
        b -= 1
        if emitted[b] == closer:
            depth += 1
        elif emitted[b] == opener:
            depth -= 1
            if depth == 0:
                break
    return b


def base_start(emitted):
    """[EN] Where the expression being subscripted starts in the text already emitted. [CN] 被下标访问的表达式在已输出文本中的起点。"""
    b = len(emitted)
    while b > 0:
        ch = emitted[b - 1]
        if ch in ')]':
            b = opener_index(emitted, b, ch)
        elif is_identifier_character(ch) or ch == '.':
            b -= 1
        else:
            break
    return b


class Lowerer:
    def __init__(self, text):
        self.src = text
        self.n = len(text)

    def skip_literal(self, j):
        quote = self.src[j]
        j += 1
        while j < self.n and self.src[j] != quote:
            j += 2 if self.src[j] == '\\' else 1
        return j + 1

    def match_bracket(self, j):
        """[EN] Index of the "]" closing the "[" at `j`. [CN] 与 `j` 处 "[" 配对的 "]" 的位置。"""
        depth = 0
        while j < self.n:
            c = self.src[j]
            if c in '"\'':
                j = self.skip_literal(j)
                continue
            if c == '[':
                depth += 1
            elif c == ']':
                depth -= 1
                if depth == 0:
                    return j
            j += 1
        raise SystemExit('unbalanced')

    def verbatim_end(self, j):
        """[EN] End of the comment or literal starting at `j`, else None. [CN] 从 `j` 开始的注释或字面量的结尾，否则为 None。"""
        if self.src.startswith('//', j):
            k = self.src.find('\n', j)
            return self.n if k < 0 else k
        if self.src.startswith('/*', j):
            return self.src.find('*/', j) + 2
        if self.src[j] in '"\'':
            return self.skip_literal(j)
        return None

    def is_subscript(self, j):
        return self.src[j] == '[' and j > 0 and (is_identifier_character(self.src[j - 1]) or self.src[j - 1] in ')]')

    def statement_end(self, v):
        """[EN] The ";" ending the assigned value, at depth 0. [CN] 赋值语句结尾处深度为 0 的 ";"。"""
        depth = 0
        while v < self.n:
            ch = self.src[v]
            if ch in '"\'':
                v = self.skip_literal(v)
                continue
            if ch in '([{':
                depth += 1
            elif ch in ')]}':
                depth -= 1
            elif ch == ';' and depth == 0:
                break
            v += 1
        return v

    def subscript(self, j, res):
        """[EN] Rewrites the subscript at `j`; returns the new output and position. [CN] 改写 `j` 处的下标，返回新的输出与位置。"""
        k = self.match_bracket(j)
        if CAST_SEND.match(self.src[j + 1:k]):
            res.append('[')
            return res, j + 1
        emitted = ''.join(res)
        base = emitted[base_start(emitted):]
        if base in C_ARRAYS:
            res.append(self.src[j:k + 1])
            return res, k + 1
        key = lower(self.src[j + 1:k])
        emitted = emitted[:len(emitted) - len(base)]
        assignment = ASSIGNMENT.match(self.src, k + 1)
        if assignment:
            v = self.statement_end(assignment.end())
            value = lower(self.src[assignment.end():v])
            return [emitted, f'CYLSubSet({base}, ({key}), ({value}))'], v
        return [emitted, f'CYLSubGet({base}, ({key}))'], k + 1

    def run(self):
        res = []
        j = 0
        while j < self.n:
            end = self.verbatim_end(j)
            if end is not None:
                res.append(self.src[j:end])
                j = end
            elif self.is_subscript(j):
                res, j = self.subscript(j, res)
            else:
                res.append(self.src[j])
                j += 1
        return ''.join(res)


def lower(text):
    return Lowerer(text).run()


if __name__ == '__main__':
    source = open(confined_path(sys.argv[1], ALLOWED_ROOTS)).read()
    print('#include "cyl_sub.h"\n' + lower(synthesize_properties(source)))
