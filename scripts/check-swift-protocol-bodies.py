#!/usr/bin/env python3
"""Flags a Swift protocol declaration whose body contains a function / init / subscript body or a stored property.

Protocols hold requirements only (docs/instructions/code.md, "Protocols hold requirements only"): Swift rejects a body in a
protocol, and a paste at the wrong anchor puts one there (cc74a545: pauseAnimation / resumeAnimation, which broke every
integrator that pinned the branch). A heuristic for code written without a compiler; the real check is the iOS CI build.

    python3 scripts/check-swift-protocol-bodies.py [folder]     # default: the current folder; exit 1 on a hit
"""
import re, sys, pathlib
PROTO = re.compile(r'^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:public\s+|open\s+|internal\s+|private\s+|fileprivate\s+)?protocol\s+(\w+)')
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
                body = re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:open|public|internal|private|final|override|static|class|mutating)\s+)*(func|init|subscript)\b', member)
                if body and '{' in member and not re.search(r'\{\s*get\b', member):
                    print(f'{path}:{j+1}: protocol {name}: body in a requirement: {member[:90]}'); hits += 1
                if re.match(r'^(?:(?:public|internal|private|static|class)\s+)*(?:let)\b', member) or re.match(r'^(?:(?:public|internal|private|static|class)\s+)*var\b[^{]*=\s*\S', member):
                    print(f'{path}:{j+1}: protocol {name}: stored property: {member[:90]}'); hits += 1
            depth += line.count('{') - line.count('}')
            if '{' in line: started = True
            if started and depth <= 0: break
            j += 1
        i = j + 1
print(f'{hits} hit(s)')
sys.exit(1 if hits else 0)
