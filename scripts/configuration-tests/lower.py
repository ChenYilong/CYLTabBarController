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


src = open(confined_path(sys.argv[1], ALLOWED_ROOTS)).read()

# 1. Properties -> explicit ivars + @synthesize.
props = {}
def collect(m):
    name, body = m.group(1), m.group(2)
    for p in re.finditer(r'@property\s*\([^)]*\)\s*(.*?)(\w+);', body):
        props.setdefault(name, []).append((p.group(1).replace('_Nullable', '').strip(), p.group(2)))
    return m.group(0)
re.sub(r'@interface (\w+)[^\n]*\n(.*?)@end', collect, src, flags=re.S)
for name, ps in props.items():
    ivars = '{\n' + ''.join(f'  {t} _{n};\n' for t, n in ps) + '}\n'
    src = re.sub(r'(@interface ' + name + r'\b[^\n{]*\n)', lambda m: m.group(1) + ivars, src, count=1)
    syn = ''.join(f'@synthesize {n} = _{n};\n' for t, n in ps)
    src = re.sub(r'(@implementation ' + name + r'\b[^\n]*\n)', lambda m: m.group(1) + syn, src, count=1)

# 2. Subscripts -> CYLSubGet / CYLSubSet (skip strings, chars, comments; C arrays listed below stay).
C_ARRAYS = {'pair', 'argv', 'cases', 'bytes', 'trailer'}
out = []; i = 0; n = len(src)
def skip_literal(j):
    q = src[j]; j += 1
    while j < n and src[j] != q:
        j += 2 if src[j] == '\\' else 1
    return j + 1
def match_bracket(j):  # src[j] == '['
    depth = 0
    while j < n:
        c = src[j]
        if c in '"\'': j = skip_literal(j); continue
        if c == '[': depth += 1
        elif c == ']':
            depth -= 1
            if depth == 0: return j
        j += 1
    raise SystemExit('unbalanced')
def lower(text):
    return LOWER(text)
def LOWER(s):
    global src, n
    saved = (src, n); src, n = s, len(s)
    res = []; j = 0
    while j < n:
        c = src[j]
        if src.startswith('//', j):
            k = src.find('\n', j); k = n if k < 0 else k; res.append(src[j:k]); j = k; continue
        if src.startswith('/*', j):
            k = src.find('*/', j) + 2; res.append(src[j:k]); j = k; continue
        if c in '"\'':
            k = skip_literal(j); res.append(src[j:k]); j = k; continue
        if c == '[' and j > 0 and (src[j-1].isalnum() or src[j-1] in '_)]'):
            # postfix subscript: find the base expression already emitted
            k = match_bracket(j)
            if re.match(r'^\s*[\w.]+\s+[A-Za-z_]\w*\s*(:|$)', src[j+1:k]):
                # a message send after a cast, e.g. (int)[self peek]: not a subscript
                res.append('['); j += 1; continue
            emitted = ''.join(res)
            b = len(emitted)
            while b > 0:
                ch = emitted[b-1]
                if ch in ')]':
                    opener = '(' if ch == ')' else '['; depth = 0
                    while b > 0:
                        b -= 1
                        if emitted[b] == ch: depth += 1
                        elif emitted[b] == opener:
                            depth -= 1
                            if depth == 0: break
                elif ch.isalnum() or ch in '_.':
                    b -= 1
                else:
                    break
            base = emitted[b:]
            if base in C_ARRAYS:
                res.append(src[j:k+1]); j = k + 1; continue
            key = LOWER(src[j+1:k])
            rest = src[k+1:]
            am = re.match(r'\s*=(?!=)', rest)
            emitted = emitted[:len(emitted) - len(base)]
            if am:
                # value runs to the ';' at depth 0
                v0 = k + 1 + am.end(); depth = 0; v = v0
                while v < n:
                    ch = src[v]
                    if ch in '"\'': v = skip_literal(v); continue
                    if ch in '([{': depth += 1
                    elif ch in ')]}': depth -= 1
                    elif ch == ';' and depth == 0: break
                    v += 1
                value = LOWER(src[v0:v])
                res = [emitted, f'CYLSubSet({base}, ({key}), ({value}))']; j = v; continue
            res = [emitted, f'CYLSubGet({base}, ({key}))']; j = k + 1; continue
        res.append(c); j += 1
    src, n = saved
    return ''.join(res)
print('#include "cyl_sub.h"\n' + LOWER(src))
