#!/usr/bin/env python3
"""
Checks that every package this repository publishes ships its license notice inside the package.

Rule (AGENTS.md, "License notice in every published package"): code published to an outside registry (CocoaPods,
Swift Package Manager, Carthage, Maven / Gradle, npm, pub.dev, ohpm, the WeChat Mini Program npm package) carries
the license. When the package has a built-in resource folder (an iOS .bundle, Android Java resources, a mini program
component folder), the license goes into it; otherwise the package root holds it. Exits 1 and names each missing file.
Details: docs/License-Notices.md.
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# (registry, package, license file that must exist, file the package publishes it through)
REQUIRED = [
    ("CocoaPods / SwiftPM / Carthage", "CYLTabBarController", "CYLTabBarController/Resources/CYLTabBarController.bundle/LICENSE", "CYLTabBarController.podspec"),
    ("CocoaPods / SwiftPM / Carthage", "CYLAnimatedItem", "CYLTabBarController/CYLAnimatedItem/Resources/CYLAnimatedItem.bundle/LICENSE", "CYLAnimatedItem.podspec"),
    ("Maven / Gradle", "cyltabbarcontroller", "Example-Android/cyltabbar/src/main/resources/META-INF/cyltabbar/LICENSE", "Example-Android/cyltabbar/build.gradle.kts"),
    ("Maven / Gradle", "cyltabbarcontroller-animateditem", "Example-Android/cylanimateditem/src/main/resources/META-INF/cylanimateditem/LICENSE", "Example-Android/cylanimateditem/build.gradle.kts"),
    ("npm (React Native)", "react-native-cyltabbar", "CrossPlatform/react-native-cyltabbar/LICENSE", "CrossPlatform/react-native-cyltabbar/package.json"),
    ("pub.dev (Flutter)", "flutter_cyltabbar", "CrossPlatform/flutter_cyltabbar/LICENSE", "CrossPlatform/flutter_cyltabbar/pubspec.yaml"),
    ("ohpm (HarmonyOS)", "cyltabbar", "CrossPlatform/harmonyos-cyltabbar/cyltabbar/LICENSE", "CrossPlatform/harmonyos-cyltabbar/cyltabbar/oh-package.json5"),
    ("npm (WeChat Mini Program)", "wechat-miniprogram-cyltabbar", "CrossPlatform/wechat-miniprogram-cyltabbar/LICENSE", "CrossPlatform/wechat-miniprogram-cyltabbar/package.json"),
    ("npm (WeChat Mini Program)", "wechat-miniprogram-cyltabbar (component folder)", "CrossPlatform/wechat-miniprogram-cyltabbar/src/LICENSE", "CrossPlatform/wechat-miniprogram-cyltabbar/package.json"),
]


def main() -> int:
    failures = []
    for registry, package, license_path, manifest in REQUIRED:
        if not (ROOT / manifest).exists():
            continue  # The package is not in this checkout.
        path = ROOT / license_path
        if not path.is_file() or path.stat().st_size == 0:
            failures.append(f"{registry}: {package} has no license notice at {license_path}")
    for line in failures:
        print(f"error: {line}", file=sys.stderr)
    if not failures:
        print(f"License notices OK ({len(REQUIRED)} packages checked)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
