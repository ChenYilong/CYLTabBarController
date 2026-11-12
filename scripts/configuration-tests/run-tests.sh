#!/bin/sh
# Runs the tests of CYLTabBarConfigurationParser (configuration files): the sample files, the edge cases of
# make-fixtures.py, and every Example exported in every format by scripts/export-tabbar-configurations.py.
# 运行 CYLTabBarConfigurationParser（配置文件）的测试：示例文件、make-fixtures.py 生成的边界情况，以及
# scripts/export-tabbar-configurations.py 以所有格式导出的每个 Example。
#
#   scripts/configuration-tests/run-tests.sh
#
# macOS: needs the Xcode command line tools (swiftc, clang, Foundation). 需要 Xcode 命令行工具（swiftc、clang、Foundation）。
# Linux: not supported since the parser moved to Swift (2026-11-13, no Objective-C interop in Swift on Linux).
#        解析器迁移到 Swift 后（2026-11-13）不再支持 Linux（Linux 上的 Swift 不支持 Objective-C 互操作）。
# Exit status 0 when every check passes. 全部检查通过时退出码为 0。
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
SOURCES="$ROOT/CYLTabBarController"
SAMPLES="$ROOT/Example-Shared/Configurations"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/cyl-configuration-tests.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

echo "== Comment blocks 注释块"
# A merge that loses a "/*!" leaves comment lines as code: a compile error that is easy to miss.
# 合并时丢失 "/*!" 会让注释行变成代码：一个容易被忽略的编译错误。
python3 "$ROOT/scripts/check-comment-blocks.py"

echo "== Fixtures 测试文件"
python3 "$HERE/make-fixtures.py" "$WORK/fixtures"

echo "== Exporting every Example in every format 以所有格式导出每个 Example"
for example in "$ROOT"/Example*; do
    name=$(basename "$example")
    [ "$name" = "Example-Shared" ] && continue
    python3 "$ROOT/scripts/export-tabbar-configurations.py" --format all --output "$WORK/exports/$name" "$example" > /dev/null
done

echo "== Building 编译"
# [EN] The parser is Swift (docs/Swift-Migration.md): compiled into one object with its Objective-C header
#      (CYLTabBarController-Swift.h, found by CYLSwiftInterface.h), then linked with the Objective-C tests.
# [CN] 解析器为 Swift（docs/Swift-Migration.md）：编译为一个目标文件并生成 Objective-C 头文件（CYLTabBarController-Swift.h，
#      由 CYLSwiftInterface.h 查找），再与 Objective-C 测试链接。
if [ "$(uname)" != "Darwin" ]; then
    # [EN] Swift on Linux has no Objective-C interop, so the Objective-C tests cannot call the Swift parser there.
    # [CN] Linux 上的 Swift 不支持与 Objective-C 互操作，因此 Objective-C 测试无法在 Linux 上调用 Swift 解析器。
    echo "Linux: the parser is Swift since 2026-11-13; run these tests on macOS (Xcode command line tools)." >&2
    exit 2
fi
xcrun swiftc -parse-as-library -wmo -c -module-name CYLTabBarController \
    -emit-objc-header-path "$WORK/CYLTabBarController-Swift.h" \
    "$SOURCES"/Swift/CYLTabBarConfigurationParser*.swift -o "$WORK/CYLTabBarConfigurationParser.o"
clang -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter -I"$WORK" -I"$SOURCES" -I"$SOURCES/CYLUtils" \
    -c "$HERE/ConfigurationParserTests.m" -o "$WORK/ConfigurationParserTests.o"
xcrun swiftc "$WORK/CYLTabBarConfigurationParser.o" "$WORK/ConfigurationParserTests.o" -o "$WORK/ConfigurationParserTests"

echo "== Running 运行"
status=0
"$WORK/ConfigurationParserTests" "$SAMPLES" "$WORK/fixtures" "$WORK/exports" > "$WORK/output.txt" 2>&1 || status=$?
# GNUstep logs (date-stamped lines) are left out. 省略 GNUstep 的日志（以日期开头的行）。
grep -v '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} ' "$WORK/output.txt" || true
exit "$status"
