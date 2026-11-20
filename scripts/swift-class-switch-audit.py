#!/usr/bin/env python3
"""
[EN] Class switch audit (docs/Swift-Migration.md, phase 2/3): every method and property CYLTabBarController.h declares on
     CYLTabBarController (the class and its categories), and whether Swift implements it publicly. Once the header no
     longer declares the class, each must be public Swift with the Swift name apps see today, or it disappears for them.
[CN] 类迁移审计：列出 CYLTabBarController.h 中为 CYLTabBarController（类及其分类）声明的每个方法与属性，以及 Swift 是否公开实现它。
     头文件不再声明该类后，每一项都必须是公开的 Swift 成员，且 Swift 名称与 App 现在看到的一致，否则 App 将无法使用。
"""
import collections
import glob
import re

HEADER = 'CYLTabBarController/CYLTabBarController.h'

# [EN] Patterns without lazy wildcards or adjacent overlapping quantifiers, so they run in linear time (SonarCloud python:S8786).
# [CN] 不含惰性通配符或相邻重叠量词的正则，线性时间运行（SonarCloud python:S8786）。
BLOCK_COMMENT = re.compile(r'/\*[^*]*\*+(?:[^/*][^*]*\*+)*/')
LINE_COMMENT = re.compile(r'//[^\n]*')
METHOD = re.compile(r'^[ \t]*([-+])[ \t]*\(([^)]*)\)[ \t\n]*([^;{\s][^;{]*);', re.M)
PROPERTY = re.compile(r'^[ \t]*@property[ \t]*\(([^)]*)\)([^;]*);', re.M)


def interface_blocks(text):
    """[EN] The body of every `@interface CYLTabBarController` (class and categories), comments removed. [CN] 每个 `@interface CYLTabBarController`（类与分类）的内容，已去掉注释。"""
    blocks = []
    current = None
    for line in text.split('\n'):
        if current is None:
            if re.match(r'@interface CYLTabBarController\b', line):
                current = []
        elif line.startswith('@end'):
            blocks.append('\n'.join(current))
            current = None
        else:
            current.append(line)
    return [LINE_COMMENT.sub('', BLOCK_COMMENT.sub('', block)) for block in blocks]


def method_declarations(block):
    """[EN] (kind, +/-, selector) of the methods of one block. [CN] 一个块中各方法的（种类、+/-、selector）。"""
    found = []
    for match in METHOD.finditer(block):
        # [EN] Spaces normalized with split / join and `str.replace`: no backtracking patterns (python:S8786). [CN] 用 split / join 与 `str.replace` 规范空白：不使用会回溯的正则。
        signature = ' '.join(match.group(3).split()).replace(' :', ':')
        parts = re.findall(r'(\w+):', signature)
        selector = ''.join(part + ':' for part in parts) if parts else signature.split()[0]
        found.append(('method', match.group(1), selector))
    return found


def property_declarations(block):
    """[EN] (kind, '-', name) of the properties of one block: the identifier just before the semicolon. [CN] 一个块中各属性的（种类、'-'、名称）：分号前最后一个标识符。"""
    found = []
    for match in PROPERTY.finditer(block):
        declaration = match.group(2).rstrip()
        # [EN] Block-typed properties end with ")" and are skipped. [CN] 块类型属性以 ")" 结尾，被跳过。
        if declaration and (declaration[-1].isalnum() or declaration[-1] == '_'):
            found.append(('property', '-', re.findall(r'\w+', declaration)[-1]))
    return found


def header_declarations():
    """[EN] (kind, +/-, selector or property name) for every declaration on the class. [CN] 类上每个声明的（种类、+/-、selector 或属性名）。"""
    with open(HEADER) as header:
        text = header.read()
    found = []
    for block in interface_blocks(text):
        found += method_declarations(block)
        found += property_declarations(block)
    return found


def method_state(name, objc_names, public_names):
    """[EN] How Swift implements a method. [CN] Swift 如何实现某个方法。"""
    if name not in objc_names:
        return 'not-swift'
    return 'swift-public' if name in public_names else 'swift-internal'


def main():
    swift = ''
    for path in glob.glob('CYLTabBarController/**/*.swift', recursive=True):
        with open(path) as source:
            swift += source.read() + '\n'
    objc_names = set(re.findall(r'@objc\(([^)]+)\)', swift))
    public_names = {m.group(1) for m in re.finditer(r'@objc\(([^)]+)\)\s+(?:@\w+\s+)*(?:public|open)\b', swift)}
    counts = collections.Counter()
    todo = []
    for kind, scope, name in header_declarations():
        if kind == 'property':
            setter = 'set' + name[0].upper() + name[1:] + ':'
            state = 'swift' if name in objc_names or setter in objc_names else 'objc-or-synthesized'
        else:
            state = method_state(name, objc_names, public_names)
        counts[(kind, state)] += 1
        if state not in ('swift-public', 'swift'):
            todo.append(f'{state:20} {kind:8} {scope}{name}')
    print(sum(counts.values()), 'declarations:', dict(counts))
    print('\n'.join(todo))


if __name__ == '__main__':
    main()
