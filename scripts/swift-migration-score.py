#!/usr/bin/env python3
"""
[EN] Score of the Objective-C → Swift migration of the iOS core layer (docs/Swift-Migration.md).

The core layer is the `Core` subspec, the two subspecs it depends on (`CYLUtils`, `CYLBadgeView`) and the FlatDesign
tab bar (`CYLFlatDesignTabBar`, core code by the maintainer's decision of 2026-11-12): the root of CYLTabBarController/
plus its CYLUtils/, CYLBadgeView/ and CYLFlatDesignTabBar/ folders. Third-party adapters (Lottie, PAG, Rive, GIF) are
not in scope.

Every line of a `.m` file counts as Objective-C. A `.h` file counts too, unless it only holds what Swift cannot
express and the rules accept as Swift compatibility: preprocessor lines (macros, `#import`, `#if`), comments, and
`NS_SWIFT_NAME` / `NS_REFINED_FOR_SWIFT` / `NS_ASSUME_NONNULL` markers. Score = 100 × (1 − remaining / baseline),
rounded down; 100 means no Objective-C is left.

    python3 scripts/swift-migration-score.py            # score and the remaining files
    python3 scripts/swift-migration-score.py --brief    # the score line only

[CN] iOS 核心层 Objective-C → Swift 迁移的评分（docs/Swift-Migration.md）。核心层为 `Core` subspec 及其依赖的 `CYLUtils`、
`CYLBadgeView`。`.m` 的每一行都算 Objective-C；`.h` 只含宏、预处理、注释与 Swift 兼容标记时算作已兼容。
评分 = 100 ×（1 − 剩余行数 / 基线行数），向下取整；100 表示没有 Objective-C。
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIBRARY = os.path.join(ROOT, 'CYLTabBarController')
# [EN] Objective-C lines of the core layer on 2026-11-12, before the migration started (FlatDesign included). [CN] 迁移开始前（2026-11-12）的行数。
BASELINE = 59391
COMPATIBLE = re.compile(r'^\s*(#|//|/\*|\*|\*/|NS_ASSUME_NONNULL_(BEGIN|END)|$)')


def core_files():
    """[EN] Objective-C files of the core layer. [CN] 核心层的 Objective-C 文件。"""
    found = []
    for name in os.listdir(LIBRARY):
        if name.endswith(('.h', '.m')) and not name.startswith('._'):
            found.append(os.path.join(LIBRARY, name))
    for folder in ('CYLUtils', 'CYLBadgeView', 'CYLFlatDesignTabBar'):
        for directory, _, names in os.walk(os.path.join(LIBRARY, folder)):
            found += [os.path.join(directory, n) for n in names if n.endswith(('.h', '.m')) and not n.startswith('._')]
    return sorted(found)


def objc_lines(path):
    """[EN] Lines that still count as Objective-C. [CN] 仍算作 Objective-C 的行数。"""
    with open(path, encoding='utf-8', errors='replace') as handle:
        lines = handle.read().split('\n')
    if path.endswith('.m'):
        return len(lines)
    remaining = [line for line in lines if not COMPATIBLE.match(line)]
    return len(lines) if remaining else 0


def main():
    counted = [(objc_lines(path), path) for path in core_files()]
    remaining = sum(count for count, _ in counted)
    score = max(0, int(100 * (1 - remaining / BASELINE)))
    print('Swift migration score: %d / 100 (%d of %d Objective-C lines left)' % (score, remaining, BASELINE))
    if '--brief' not in sys.argv:
        for count, path in sorted(counted, reverse=True):
            if count:
                print('%6d  %s' % (count, os.path.relpath(path, ROOT)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
