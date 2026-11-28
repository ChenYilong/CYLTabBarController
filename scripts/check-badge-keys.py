#!/usr/bin/env python3
"""[EN] The badge style keys (docs/Animated-Item-Badge-CrossPlatform.md, "The common API") must be the same eleven strings, in the same order, on every
platform: iOS Swift, Android Kotlin, HarmonyOS ArkTS, the mini program, React Native and Flutter. Reads each source and compares; runs anywhere, needs no
toolchain of the platforms. Exit code 1 on a difference.
[CN] 角标样式键（docs/Animated-Item-Badge-CrossPlatform.md，"统一接口"）在所有平台上必须是同样的十一个字符串、同样的顺序：iOS Swift、Android Kotlin、
鸿蒙 ArkTS、小程序、React Native 与 Flutter。读取每个源文件并比较；任何环境都能运行，不需要各平台的工具链。有差异时退出码为 1。"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPECTED = ['value', 'color', 'animation', 'radius', 'centerOffset', 'textColor', 'font', 'borderColor', 'borderWidth', 'maximumNumber', 'respectsReduceMotion']

SOURCES = [
    ('iOS', 'CYLTabBarController/CYLBadgeView/Swift/CYLBadgeAttributeKey.swift', r'static let \w+ = "(\w+)"'),
    ('Android', 'Example-Android/cylbadge/src/main/kotlin/com/cyl/tabbar/CYLBadgeAttributeKey.kt', r'const val [A-Z_]+ = "(\w+)"'),
    ('HarmonyOS', 'CrossPlatform/harmonyos-cyltabbar/cylbadge/src/main/ets/CYLBadgeAttributeParser.ts', r"static readonly \w+: string = '(\w+)'"),
    ('mini program', 'CrossPlatform/wechat-miniprogram-cyltabbar/src/cyl-badge/cyl_badge_model.js', r"^\s+(?:value|color|animation|radius|centerOffset|textColor|font|borderColor|borderWidth|maximumNumber|respectsReduceMotion): '(\w+)'"),
    ('React Native', 'CrossPlatform/react-native-cyltabbar/src/CYLAnimationView.native.tsx', r"^\s+\w+: '(\w+)',?$"),
    ('Flutter', 'CrossPlatform/flutter_cyltabbar/lib/src/cyl_badge_attribute_key.dart', r"static const \w+ = '(\w+)';"),
]


def keys_of(path, pattern):
    text = open(os.path.join(ROOT, path), encoding='utf-8').read()
    # [EN] The mini program lists the keys on one or two lines of an object literal. [CN] 小程序把键写在对象字面量的一两行里。
    found = re.findall(pattern, text, re.M)
    if not found:
        return []
    return [k for k in found if k in EXPECTED]


# [EN] The names that cross a bridge must exist on both sides: React Native's four spec props in the iOS view and the Android manager, Flutter's two channel
#      calls in Dart, the iOS plugin and the Android view. [CN] 跨桥的名称两侧都必须存在：React Native 规范的四个 prop 在 iOS 视图与 Android 管理器中，
#      Flutter 的两个 channel 调用在 Dart、iOS 插件与 Android 视图中。
BRIDGES = [
    ('React Native bridge', ['badgeValue', 'badgeHidden', 'badgeAttributesJSON', 'reservesBadgeSpace'], [
        'CrossPlatform/react-native-cyltabbar/src/CyltabbarAnimationViewNativeComponent.ts',
        'CrossPlatform/react-native-cyltabbar/ios/CyltabbarAnimationView.mm',
        'CrossPlatform/react-native-cyltabbar/android/src/main/java/com/cyltabbar/CyltabbarAnimationViewManager.kt']),
    ('Flutter bridge', ['setBadge', 'setReservesBadgeSpace'], [
        'CrossPlatform/flutter_cyltabbar/lib/src/cyl_animation_view.dart',
        'CrossPlatform/flutter_cyltabbar/ios/flutter_cyltabbar/Sources/flutter_cyltabbar/FlutterCyltabbarPlugin.m',
        'CrossPlatform/flutter_cyltabbar/android/src/main/kotlin/com/cyl/tabbar/flutter_cyltabbar/CYLFlutterAnimationView.kt']),
]


def main():
    failed = False
    for name, names, files in BRIDGES:
        for path in files:
            text = open(os.path.join(ROOT, path), encoding='utf-8').read()
            missing = [n for n in names if n not in text]
            if missing:
                failed = True
                print(f'FAIL  {name}: {path} lacks {missing}')
        else:
            pass
        if not failed:
            print(f'PASS  {name}: {", ".join(names)} on both sides')
    for name, path, pattern in SOURCES:
        keys = keys_of(path, pattern)
        if name == 'mini program':
            text = open(os.path.join(ROOT, path), encoding='utf-8').read()
            block = re.search(r'const CYLBadgeAttributeKey = \{(.*?)\};', text, re.S).group(1)
            keys = re.findall(r"(\w+): '(\w+)'", block)
            keys = [v for k, v in keys]
        if name == 'React Native':
            text = open(os.path.join(ROOT, path), encoding='utf-8').read()
            block = re.search(r'export const CYLBadgeAttributeKey = \{(.*?)\} as const;', text, re.S).group(1)
            keys = re.findall(r"\w+: '(\w+)'", block)
        if keys == EXPECTED:
            print(f'PASS  {name}: the eleven keys')
        else:
            failed = True
            print(f'FAIL  {name}: {keys}')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
