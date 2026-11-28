#!/usr/bin/env python3
"""Flags a Swift protocol declaration whose body contains a function / init / subscript body or a stored property.

Protocols hold requirements only (docs/instructions/code.md, "Protocols hold requirements only"): Swift rejects a body in a
protocol, and a paste at the wrong anchor puts one there (cc74a545: pauseAnimation / resumeAnimation, which broke every
integrator that pinned the branch). A heuristic for code written without a compiler; the real check is the iOS CI build.

    python3 scripts/check-swift-protocol-bodies.py [folder]     # default: the current folder; exit 1 on a hit
"""
import re, sys, pathlib
# The patterns are built from small parts, so each stays simple (SonarCloud python:S5843).
ATTRS = r'(?:@\w+(?:\([^)]*\))?\s+)*'                                  # attributes such as @objc(name)
ACCESS = r'(?:(?:public|open|internal|private|fileprivate)\s+)?'
MEMBER_MODIFIERS = r'(?:(?:open|public|internal|private|final|override|static|class|mutating)\s+)*'
PROPERTY_MODIFIERS = r'(?:(?:public|internal|private|static|class)\s+)*'
PROTO = re.compile(r'^\s*' + ATTRS + ACCESS + r'protocol\s+(\w+)')
BODY = re.compile(r'^' + ATTRS + MEMBER_MODIFIERS + r'(func|init|subscript)\b')
LET = re.compile(r'^' + PROPERTY_MODIFIERS + r'let\b')
STORED_VAR = re.compile(r'^' + PROPERTY_MODIFIERS + r'var\b[^{]*=\s*\S')
def strip(line):
    line = re.sub(r'"(?:\\.|[^"\\])*"', '""', line)   # strings
    return re.sub(r'//.*$', '', line)                  # line comments
hits = 0
for path in sorted(pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '.').rglob('*.swift')):
    if any(part in ('node_modules', 'Pods', '.build', 'build') for part in path.parts):
        continue
    lines = path.read_text(errors='ignore').split('\n')
    i, in_block_comment = 0, False
    while i < len(lines):
        m = PROTO.match(lines[i])
        if not m:
            i += 1; continue
        name, depth, j, started = m.group(1), 0, i, False
        while j < len(lines):
            raw = lines[j]
            line = strip(raw)
            if in_block_comment:
                if '*/' in line: in_block_comment = False
                j += 1; continue
            if '/*' in line and '*/' not in line:
                in_block_comment = True
            line = re.sub(r'/\*.*?\*/', '', line)
            if started and depth == 1:
                member = line.strip()
                body = BODY.match(member)
                if body and '{' in member and not re.search(r'\{\s*get\b', member):
                    print(f'{path}:{j+1}: protocol {name}: body in a requirement: {member[:90]}'); hits += 1
                if LET.match(member) or STORED_VAR.match(member):
                    print(f'{path}:{j+1}: protocol {name}: stored property: {member[:90]}'); hits += 1
            depth += line.count('{') - line.count('}')
            if '{' in line: started = True
            if started and depth <= 0: break
            j += 1
        i = j + 1
print(f'{hits} hit(s)')
sys.exit(1 if hits else 0)
