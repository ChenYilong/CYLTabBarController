#!/usr/bin/env bash
# [EN] Builds and runs the tab bar item animation tests on macOS (Xcode command line tools), as the "Animation tests"
#      GitHub Actions workflow does: the real registry, view animator and player sources of the CYLTabBarItemAnimation
#      subspec, and the real Core functions, extracted from their files so the test always runs the current code. Only
#      Foundation is linked; stub/UIKit declares the few UIKit types those sources use.
# [CN] 在 macOS（Xcode 命令行工具）上编译并运行 Tab 图标动画的测试，与 GitHub Actions 的「Animation tests」工作流相同：使用
#      CYLTabBarItemAnimation 子库中真实的注册表、视图 animator 与播放器源码，以及从源码中提取的真实 Core 函数，使测试总是运行当前的代码。只链接
#      Foundation；stub/UIKit 声明这些源码用到的少量 UIKit 类型。
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
animation="$root/CYLTabBarController/CYLTabBarItemAnimation"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

# [EN] The Core functions under test. [CN] 被测试的 Core 函数。
python3 -I - "$root" "$build/core.m" <<'PY'
import sys
root, out = sys.argv[1], sys.argv[2]
def extract(path, start, end):
    text = open(f"{root}/CYLTabBarController/{path}", encoding="utf-8").read()
    i = text.index(start)
    return text[i:text.index(end, i)]
code = extract("UIControl+CYLTabBarItemAnimation.m", "id CYLTabBarItemAttributesAnimationValue(", "#pragma mark - Categories")
code += extract("UIControl+CYLTabBarItemAnimation.m", "NSURL *CYLTabBarAnimationURLWithOptions(", "NSDictionary *CYLTabBarItemAttributesAddingAnimationFile(")
style = extract("CYLConstants.m", "@interface CYLTabBarItemAnimationStyleRegistry", "/// [EN] Core's style source: the one style registry.")
open(out.replace("core.m", "style.m"), "w", encoding="utf-8").write(
    "#import <UIKit/UIKit.h>\n"
    f'#import "{root}/CYLTabBarController/CYLTabBarItemAnimationService.h"\n' + style)
open(out, "w", encoding="utf-8").write(
    "#import <Foundation/Foundation.h>\n"
    "typedef NSString *CYLTabBarAnimationOption;\n"
    "@interface CYLTestService : NSObject\n"
    "- (NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes;\n"
    "@end\n"
    "CYLTestService *CYLTabBarItemAnimationGetService(void);\n" + code)
PY

xcrun clang -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter -DDEBUG=1 \
    -I"$here/stub" -I"$animation" \
    "$here/main.m" "$here/stub/UIKit.m" "$build/core.m" "$build/style.m" \
    "$animation/CYLTabBarItemAnimatorRegistry.m" \
    "$animation/CYLTabBarItemAnimationFactory.m" \
    "$animation/CYLTabBarItemAnimationEngine.m" \
    "$animation/CYLTabBarItemViewAnimator.m" \
    "$animation/CYLTabBarItemAnimationPlayer.m" \
    -framework Foundation -framework CoreGraphics -o "$build/tests"
"$build/tests"
