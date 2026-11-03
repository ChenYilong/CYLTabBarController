#!/bin/sh
# Usage:
#   scripts/pod-lint.sh lib      [extra pod args]   # pod lib lint
#   scripts/pod-lint.sh push     [extra pod args]   # pod trunk push, then update the Carthage and SPM versions (below)
#   scripts/pod-lint.sh carthage                    # only update the Carthage version
#   scripts/pod-lint.sh spm                         # only update the Swift Package Manager version
#   scripts/pod-lint.sh versions                    # update both, without pushing
#
# [EN] Carthage and Swift Package Manager have no registry: a release is the git tag that `pod trunk push` also
#      requires. After a push, the places that pin this library's version follow the podspec's s.version:
#      - Carthage: the demo's Example-Swift-Carthage/Cartfile becomes "~> <s.version>".
#      - SPM: every `.package(url: ".../CYLTabBarController.git", from: "...")` in README.md and docs/*.md becomes
#        `from: "<s.version>"` (Package.swift has no version; the SPM demo uses a local package).
#      The documentation navigation is regenerated afterwards. Commit the changes.
# [CN] Carthage 与 Swift Package Manager 都没有中央仓库：版本就是 `pod trunk push` 同样需要的 git tag。push 成功后，所有固定本库
#      版本的地方都跟随 podspec 的 s.version：
#      - Carthage：演示工程的 Example-Swift-Carthage/Cartfile 改为 "~> <s.version>"。
#      - SPM：README.md 与 docs/*.md 中所有 `.package(url: ".../CYLTabBarController.git", from: "...")` 改为
#        `from: "<s.version>"`（Package.swift 没有版本号；SPM 演示工程使用本地 package）。
#      之后重新生成文档导航。请提交这些修改。
set -e
cd "$(dirname "$0")/.."
export XCODE_XCCONFIG_FILE="$PWD/scripts/pod-lint.xcconfig"

PODSPEC=CYLTabBarController.podspec
CARTFILE=Example-Swift-Carthage/Cartfile
CARTHAGE_DEPENDENCY='github "ChenYilong/CYLTabBarController"'

SPM_URL='https://github.com/ChenYilong/CYLTabBarController.git'

# The version in the podspec, e.g. 1.99.73. podspec 中的版本号，例如 1.99.73。
pod_version() {
  sed -n 's/^[[:space:]]*s\.version[[:space:]]*=[[:space:]]*["'\'']\([^"'\'']*\)["'\''].*/\1/p' "$PODSPEC" | head -n 1
}

release_version() {
  version=$(pod_version)
  if [ -z "$version" ]; then
    echo "error: no s.version found in $PODSPEC" >&2
    exit 1
  fi
}

update_carthage() {
  release_version
  if [ ! -f "$CARTFILE" ]; then
    echo "error: $CARTFILE not found" >&2
    exit 1
  fi
  # The tag must exist on the remote, or Carthage cannot resolve the version. 远端必须有该 tag，否则 Carthage 无法解析该版本。
  if ! git ls-remote --exit-code --tags origin "refs/tags/$version" >/dev/null 2>&1; then
    echo "warning: tag $version is not on origin yet; push it (git push origin $version) before using the Cartfile" >&2
  fi
  # Rewrite only the dependency line (portable sed: write a temp file). 只改写依赖那一行（兼容 macOS 与 Linux 的 sed）。
  sed "s|^$CARTHAGE_DEPENDENCY.*\$|$CARTHAGE_DEPENDENCY ~> $version|" "$CARTFILE" > "$CARTFILE.tmp"
  mv "$CARTFILE.tmp" "$CARTFILE"
  if ! grep -q "^$CARTHAGE_DEPENDENCY ~> $version\$" "$CARTFILE"; then
    echo "error: the $CARTHAGE_DEPENDENCY line was not found in $CARTFILE" >&2
    exit 1
  fi
  echo "Carthage: $CARTFILE now requires $CARTHAGE_DEPENDENCY ~> $version (commit this change)"
}

update_spm() {
  release_version
  # `from: "x.y.z"` after this repository's URL; the dots of the URL are escaped for sed.
  # 本仓库 URL 之后的 `from: "x.y.z"`；为 sed 转义 URL 中的点。
  url_pattern=$(printf '%s' "$SPM_URL" | sed 's/[.]/\\./g')
  changed=0
  for file in README.md docs/*.md; do
    [ -f "$file" ] || continue
    grep -q "$url_pattern\", from: \"" "$file" || continue
    sed "s|\($url_pattern\", from: \"\)[^\"]*\"|\1$version\"|g" "$file" > "$file.tmp"
    if cmp -s "$file" "$file.tmp"; then
      rm -f "$file.tmp"
    else
      mv "$file.tmp" "$file"
      changed=1
      echo "SPM: $file now uses from: \"$version\" (commit this change)"
    fi
  done
  [ "$changed" = 1 ] || echo "SPM: every .package(url: \"$SPM_URL\", from: ...) already uses $version"
}

# Docs changed, so the generated navigation must follow (CLAUDE.md). 文档有改动，生成的导航需要同步（CLAUDE.md）。
update_navigation() {
  if command -v python3 >/dev/null 2>&1 && [ -f scripts/update-docs-navigation.py ]; then
    python3 scripts/update-docs-navigation.py
  fi
}

case "$1" in
  push)     shift; pod trunk push "$PODSPEC" --allow-warnings "$@"; update_carthage; update_spm; update_navigation ;;
  carthage) update_carthage ;;
  spm)      update_spm; update_navigation ;;
  versions) update_carthage; update_spm; update_navigation ;;
  *)        [ "$1" = lib ] && shift; pod lib lint "$PODSPEC" --allow-warnings "$@" ;;
esac
