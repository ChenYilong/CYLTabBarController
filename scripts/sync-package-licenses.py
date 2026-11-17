#!/usr/bin/env python3
"""
Puts the license file into every package this repository publishes (CocoaPods, Swift Package Manager, Maven / Gradle,
npm, pub.dev, ohpm and the WeChat Mini Program components), inside the package's own resource folder, so the license
travels with the code into every app that installs it. See docs/Package-Licenses.md.

    python3 scripts/sync-package-licenses.py           # write the missing or stale license files
    python3 scripts/sync-package-licenses.py --check   # exit 1 and name each missing or stale file

Each entry is (destination, source). A destination with a source is a copy of that source and is rewritten when it
differs. A destination without a source is a license of its own that must exist (it is never overwritten).
"""

import argparse
import filecmp
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ROOT_LICENSE = "LICENSE"

ENTRIES = [
    # iOS, CocoaPods and Swift Package Manager: the resource bundles each pod ships (podspec `resources`, Package.swift
    # `.copy`).
    ("CYLTabBarController/Resources/CYLTabBarController.bundle/LICENSE", ROOT_LICENSE),
    ("CYLTabBarController/CYLAnimatedItem/Resources/CYLAnimatedItem.bundle/LICENSE", None),
    # Android, Maven / Gradle: Java resources end up inside the AAR / JAR; one folder per module so apps that use
    # several modules get no duplicate path.
    ("Example-Android/cyltabbar/src/main/resources/META-INF/cyltabbar/LICENSE", ROOT_LICENSE),
    ("Example-Android/cylanimateditem/src/main/resources/META-INF/cylanimateditem/LICENSE", None),
    ("Example-Android/tabpages/src/main/resources/META-INF/tabpages/LICENSE", ROOT_LICENSE),
    # npm (React Native): npm always packs the package root's LICENSE.
    ("CrossPlatform/react-native-cyltabbar/LICENSE", None),
    # pub.dev (Flutter): pub requires the package root's LICENSE.
    ("CrossPlatform/flutter_cyltabbar/LICENSE", ROOT_LICENSE),
    # ohpm (HarmonyOS): the HAR's root LICENSE, and a copy in its raw resources, which are packed into the app.
    ("CrossPlatform/harmonyos-cyltabbar/cyltabbar/LICENSE", ROOT_LICENSE),
    ("CrossPlatform/harmonyos-cyltabbar/cyltabbar/src/main/resources/rawfile/cyltabbar/LICENSE", ROOT_LICENSE),
    # WeChat Mini Program components (npm): the package root's LICENSE, and a copy in the folder that DevTools'
    # "build npm" copies into the app (`miniprogram` in package.json).
    ("CrossPlatform/wechat-miniprogram-cyltabbar/LICENSE", None),
    ("CrossPlatform/wechat-miniprogram-cyltabbar/src/LICENSE", "CrossPlatform/wechat-miniprogram-cyltabbar/LICENSE"),
    ("CrossPlatform/gif-miniprogram/LICENSE", None),
    ("CrossPlatform/gif-miniprogram/miniprogram_dist/LICENSE", "CrossPlatform/gif-miniprogram/LICENSE"),
    ("CrossPlatform/lottie-miniprogram/LICENSE", None),
    ("CrossPlatform/lottie-miniprogram/miniprogram_dist/LICENSE", "CrossPlatform/lottie-miniprogram/LICENSE"),
    ("CrossPlatform/pag-miniprogram/LICENSE", None),
    ("CrossPlatform/pag-miniprogram/miniprogram_dist/LICENSE", "CrossPlatform/pag-miniprogram/LICENSE"),
    ("CrossPlatform/rive-miniprogram/LICENSE", None),
    ("CrossPlatform/rive-miniprogram/miniprogram_dist/LICENSE", "CrossPlatform/rive-miniprogram/LICENSE"),
    ("CrossPlatform/svga-miniprogram/LICENSE", None),
    ("CrossPlatform/svga-miniprogram/miniprogram_dist/LICENSE", "CrossPlatform/svga-miniprogram/LICENSE"),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("--check", action="store_true", help="only report; exit 1 when a file is missing or stale")
    args = parser.parse_args()
    problems = []
    for destination, source in ENTRIES:
        destination_path = os.path.join(ROOT, destination)
        if source is None:
            if not os.path.isfile(destination_path):
                problems.append(f"missing (a license of its own, add it by hand): {destination}")
            continue
        source_path = os.path.join(ROOT, source)
        if not os.path.isfile(source_path):
            problems.append(f"missing source {source} for {destination}")
            continue
        if os.path.isfile(destination_path) and filecmp.cmp(source_path, destination_path, shallow=False):
            continue
        if args.check:
            problems.append(f"{'stale' if os.path.exists(destination_path) else 'missing'}: {destination} (copy of {source})")
            continue
        os.makedirs(os.path.dirname(destination_path), exist_ok=True)
        shutil.copyfile(source_path, destination_path)
        print(f"wrote {destination}")
    for problem in problems:
        print(problem, file=sys.stderr)
    if problems:
        print("Run: python3 scripts/sync-package-licenses.py (see docs/Package-Licenses.md)", file=sys.stderr)
        return 1
    print(f"Checked {len(ENTRIES)} package license files: OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
