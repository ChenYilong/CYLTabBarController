#!/usr/bin/env python3
"""Checks that screenshots follow docs/Screenshot-Guidelines.md: every PNG added to docs/assets from 2026-11-18 on was
built by scripts/stitch-screenshots.py (it carries the "CYLScreenshot" tEXt chunk with its header and footer).

    python3 scripts/check-screenshot-labels.py            # exit 1 and list the images without labels
    python3 scripts/check-screenshot-labels.py --since 2026-11-18

Images added before the rules (2026-11-18) are not checked. JPEG files are reported as needing a PNG rebuild.
"""
import argparse
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MARKER = b'tEXtCYLScreenshot\x00'
# [EN] Not a screenshot of this repository's code: the style reference itself. [CN] 不是本仓库代码的截图：样式参考图本身。
EXEMPT = {'docs/assets/screenshot-guidelines-reference-example.png'}


def added_images(since):
    out = subprocess.run(['git', '-C', ROOT, 'log', f'--since={since} 00:00', '--diff-filter=A', '--name-only',
                          '--format=', '--', 'docs/assets', 'README.md'], capture_output=True, text=True, check=True).stdout
    paths = sorted({line.strip() for line in out.splitlines() if line.strip().lower().endswith(('.png', '.jpg', '.jpeg'))})
    staged = subprocess.run(['git', '-C', ROOT, 'diff', '--cached', '--name-only', '--diff-filter=A', '--', 'docs/assets'],
                            capture_output=True, text=True, check=True).stdout.split()
    return sorted(set(paths) | {p for p in staged if p.lower().endswith(('.png', '.jpg', '.jpeg'))})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--since', default='2026-11-18')
    options = parser.parse_args()
    failures = []
    for path in added_images(options.since):
        full = os.path.join(ROOT, path)
        if path in EXEMPT or not os.path.exists(full):
            continue
        with open(full, 'rb') as handle:
            if MARKER not in handle.read():
                failures.append(path)
    for path in failures:
        print(f'{path}: no header / footer from scripts/stitch-screenshots.py (docs/Screenshot-Guidelines.md)')
    print(f'{len(failures)} screenshot(s) without labels')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
