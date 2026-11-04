#!/bin/sh
# Runs the tests of CYLTabBarConfigurationParser (configuration files): the sample files, the edge cases of
# make-fixtures.py, and every Example exported in every format by scripts/export-tabbar-configurations.py.
# 运行 CYLTabBarConfigurationParser（配置文件）的测试：示例文件、make-fixtures.py 生成的边界情况，以及
# scripts/export-tabbar-configurations.py 以所有格式导出的每个 Example。
#
#   scripts/configuration-tests/run-tests.sh
#
# macOS: needs the Xcode command line tools (clang, Foundation). 需要 Xcode 命令行工具（clang、Foundation）。
# Linux: needs clang and GNUstep base: sudo apt-get install clang libgnustep-base-dev gnustep-make
#        需要 clang 与 GNUstep base（安装命令见上）。
# Exit status 0 when every check passes. 全部检查通过时退出码为 0。
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
SOURCES="$ROOT/CYLTabBarController"
SAMPLES="$SOURCES/Resources/CYLTabBarController.bundle/Configurations"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/cyl-configuration-tests.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

echo "== Fixtures 测试文件"
python3 "$HERE/make-fixtures.py" "$WORK/fixtures"

echo "== Exporting every Example in every format 以所有格式导出每个 Example"
for example in "$ROOT"/Example*; do
    name=$(basename "$example")
    [ "$name" = "Example-Shared" ] && continue
    python3 "$ROOT/scripts/export-tabbar-configurations.py" --format all --output "$WORK/exports/$name" "$example" > /dev/null
done

echo "== Building 编译"
if [ "$(uname)" = "Darwin" ]; then
    clang -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I"$SOURCES" \
        "$SOURCES/CYLTabBarConfigurationParser.m" "$HERE/ConfigurationParserTests.m" \
        -framework Foundation -o "$WORK/ConfigurationParserTests"
else
    if ! command -v gnustep-config > /dev/null 2>&1; then
        echo "GNUstep is missing: sudo apt-get install clang libgnustep-base-dev gnustep-make" >&2
        exit 2
    fi
    # GCC's libobjc headers. GCC 的 libobjc 头文件。
    OBJC_INCLUDE=$(ls -d /usr/lib/gcc/*/*/include 2> /dev/null | tail -n 1)
    python3 "$HERE/lower.py" "$SOURCES/CYLTabBarConfigurationParser.m" > "$WORK/CYLTabBarConfigurationParser_lowered.m"
    # shellcheck disable=SC2046
    clang $(gnustep-config --objc-flags) -I"$OBJC_INCLUDE" -I"$SOURCES" -I"$HERE" -DFOUNDATION_EXTERN=extern \
        -fno-blocks -fobjc-runtime=gcc -Wno-everything \
        "$WORK/CYLTabBarConfigurationParser_lowered.m" "$HERE/ConfigurationParserTests.m" \
        $(gnustep-config --base-libs) -o "$WORK/ConfigurationParserTests"
    echo "   (Linux: also checking the real source for warnings 同时检查原始源码的警告)"
    # shellcheck disable=SC2046
    warnings=$(clang $(gnustep-config --objc-flags) -I"$OBJC_INCLUDE" -I"$SOURCES" -DFOUNDATION_EXTERN=extern -fno-blocks \
        -fobjc-runtime=gnustep-2.0 -Wall -Wextra -Wshadow -Wno-unused-parameter -c "$SOURCES/CYLTabBarConfigurationParser.m" \
        -o /dev/null 2>&1 | grep -cE 'warning|error' || true)
    if [ "$warnings" != "0" ]; then
        echo "CYLTabBarConfigurationParser.m has $warnings warning(s)" >&2
        exit 1
    fi
fi

echo "== Running 运行"
status=0
"$WORK/ConfigurationParserTests" "$SAMPLES" "$WORK/fixtures" "$WORK/exports" > "$WORK/output.txt" 2>&1 || status=$?
# GNUstep logs (date-stamped lines) are left out. 省略 GNUstep 的日志（以日期开头的行）。
grep -v '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} ' "$WORK/output.txt" || true
exit "$status"
