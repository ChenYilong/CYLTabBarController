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


def header_declarations():
    """[EN] (kind, +/-, selector or property name) for every declaration on the class. [CN] 类上每个声明的（种类、+/-、selector 或属性名）。"""
    text = open(HEADER).read()
    found = []
    for block in re.findall(r'@interface CYLTabBarController\b[^\n]*\n(.*?)\n@end', text, re.S):
        block = re.sub(r'/\*.*?\*/', '', block, flags=re.S)
        block = re.sub(r'//[^\n]*', '', block)
        for match in re.finditer(r'^\s*([-+])\s*\(([^)]*)\)\s*([^;{]+);', block, re.M):
            signature = re.sub(r'\s+', ' ', match.group(3))
            parts = re.findall(r'(\w+)\s*:', signature)
            selector = ''.join(part + ':' for part in parts) if parts else signature.split()[0]
            found.append(('method', match.group(1), selector))
        for match in re.finditer(r'^\s*@property\s*\(([^)]*)\)\s*[^;]*?\b(\w+)\s*;', block, re.M):
            found.append(('property', '-', match.group(2)))
    return found


def main():
    swift = '\n'.join(open(path).read() for path in glob.glob('CYLTabBarController/**/*.swift', recursive=True))
    objc_names = set(re.findall(r'@objc\(([^)]+)\)', swift))
    public_names = {m.group(1) for m in re.finditer(r'@objc\(([^)]+)\)\s*\n?\s*(?:@\w+\s*)*(public|open)\b', swift)}
    counts = collections.Counter()
    todo = []
    for kind, scope, name in header_declarations():
        if kind == 'property':
            setter = 'set' + name[0].upper() + name[1:] + ':'
            state = 'swift' if name in objc_names or setter in objc_names else 'objc-or-synthesized'
        else:
            state = ('swift-public' if name in public_names else 'swift-internal') if name in objc_names else 'not-swift'
        counts[(kind, state)] += 1
        if state != 'swift-public' and state != 'swift':
            todo.append(f'{state:20} {kind:8} {scope}{name}')
    print(sum(counts.values()), 'declarations:', dict(counts))
    print('\n'.join(todo))


if __name__ == '__main__':
    main()
