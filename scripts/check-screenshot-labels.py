#!/usr/bin/env python3
"""Enforces docs/Screenshot-Guidelines.md: a screenshot in docs/assets must be built by scripts/stitch-screenshots.py.

That script writes a PNG tEXt chunk "CYLScreenshot" holding the image's header and footer. An image passes when the
chunk is there, its header has "Purpose:" and its footer has "Result:".

    python3 scripts/check-screenshot-labels.py            # every image added or changed since 2026-11-18 (history)
    python3 scripts/check-screenshot-labels.py --staged   # only the images staged for this commit (pre-commit hook)

Images added before the check by other sessions and not yet relabeled are listed, one path per line, in
docs/assets/.screenshot-labels-pending: they are reported but do not fail the history mode. A pending image that is
staged again must be relabeled (staged mode ignores the list). The style reference itself is exempt.
Exit status: 0 when every checked image passes, 1 otherwise.
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CUTOFF = '2026-11-18'
KEY = b'tEXtCYLScreenshot\x00'
IMAGE_SUFFIXES = ('.png', '.jpg', '.jpeg', '.gif', '.webp')
PENDING_FILE = os.path.join(ROOT, 'docs', 'assets', '.screenshot-labels-pending')
EXEMPT = {'docs/assets/screenshot-guidelines-reference-example.png'}


def git(*args):
    return subprocess.run(['git', '-C', ROOT, *args], capture_output=True, text=True, check=True).stdout


def is_image(path):
    return path.startswith('docs/assets/') and path.lower().endswith(IMAGE_SUFFIXES)


def staged_images():
    names = git('diff', '--cached', '--name-only', '--diff-filter=AM').split('\n')
    return sorted(p for p in names if is_image(p))


def history_images(since):
    # [EN] `since` comes from the command line: only a date reaches git. [CN] `since` 来自命令行：只有日期才会传给 git。
    if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', since):
        sys.exit(f'--since must be a date (YYYY-MM-DD), not {since!r}')
    names = git('log', f'--since={since} 00:00', '--diff-filter=AM', '--name-only', '--format=', '--', 'docs/assets')
    return sorted({p for p in names.split('\n') if is_image(p)} | set(staged_images()))


def problem(path, staged):
    """The reason `path` fails, or None. Staged images are read from the index, others from the working tree."""
    if staged:
        data = subprocess.run(['git', '-C', ROOT, 'show', f':{path}'], capture_output=True, check=True).stdout
    else:
        full = os.path.join(ROOT, path)
        if not os.path.exists(full):
            return None
        with open(full, 'rb') as handle:
            data = handle.read()
    if not path.lower().endswith('.png'):
        return 'not a PNG built by scripts/stitch-screenshots.py'
    at = data.find(KEY)
    if at < 0:
        return 'no header / caption / footer from scripts/stitch-screenshots.py'
    length = int.from_bytes(data[at - 4:at], 'big')
    text = data[at + len(KEY):at + 4 + length].decode('latin-1')
    if 'Purpose:' not in text:
        return 'the header has no "Purpose:"'
    if 'Result:' not in text:
        return 'the footer has no "Result:"'
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--staged', action='store_true', help='Check only the images staged for the next commit.')
    parser.add_argument('--since', default=CUTOFF)
    options = parser.parse_args()
    pending = set()
    if os.path.exists(PENDING_FILE):
        with open(PENDING_FILE, encoding='utf-8') as handle:
            pending = {line.strip() for line in handle if line.strip() and not line.startswith('#')}
    paths = staged_images() if options.staged else history_images(options.since)
    failures, waiting = [], []
    for path in paths:
        if path in EXEMPT:
            continue
        reason = problem(path, options.staged)
        if reason is None:
            continue
        if not options.staged and path in pending:
            waiting.append(f'{path}: {reason} (pending relabel)')
        else:
            failures.append(f'{path}: {reason}')
    for line in failures + waiting:
        print(line)
    print(f'{len(paths)} image(s) checked, {len(failures)} failing, {len(waiting)} pending relabel. '
          'Rules: docs/Screenshot-Guidelines.md; build with python3 scripts/stitch-screenshots.py.')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
