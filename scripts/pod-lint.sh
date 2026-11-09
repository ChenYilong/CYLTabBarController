#!/bin/sh
# Usage:
#   scripts/pod-lint.sh lib      [extra pod args]   # pod lib lint
#   scripts/pod-lint.sh push     [extra pod args]   # pod trunk push, then update the Carthage and SPM versions (below)
#   scripts/pod-lint.sh carthage                    # only update the Carthage version (binary spec and demo Cartfile)
#   scripts/pod-lint.sh xcframework                 # build build/CYLTabBarController.xcframework.zip (Carthage binary)
#   scripts/pod-lint.sh spm                         # only update the Swift Package Manager version
#   scripts/pod-lint.sh versions                    # update both, without pushing
#   scripts/pod-lint.sh version                     # print s.version
#   scripts/pod-lint.sh check-tag <tag>             # exit 1 unless <tag> equals s.version (used by the Release workflow)
#   scripts/pod-lint.sh bump <x.y.z>                # set s.version, then `versions`: prepares a release pull request
#
# [EN] Release (docs/Mac-CI-CD.md): `bump` on a branch from master → pull request, CI → merge → tag the merge commit
#      with the same version → the Release workflow runs `check-tag` and `push`.
# [CN] 发布流程（docs/Mac-CI-CD.md）：从 master 新建分支执行 `bump` → PR 跑 CI → 合并 → 在合并提交上打同名 tag → Release workflow
#      执行 `check-tag` 与 `push`。
#
# [EN] Carthage and Swift Package Manager have no registry: a release is the git tag that `pod trunk push` also
#      requires. After a push, the places that pin this library's version follow the podspec's s.version:
#      - Carthage: a prebuilt XCFramework (docs/Carthage.md). Apps use `binary "<CYLTabBarController.json URL>"`:
#        Carthage cannot build this repository from source since it holds the Flutter examples' Xcode projects.
#        CYLTabBarController.json gets "<s.version>": "<release asset URL>" (the URL is known before the release, so
#        `bump` adds it to the release pull request); the Release workflow uploads the zip that `xcframework` builds.
#        The demo's Example-Swift-Carthage/Cartfile becomes `binary "..." ~> <s.version>`.
#      - SPM: every `.package(url: ".../CYLTabBarController.git", from: "...")` in README.md and docs/*.md becomes
#        `from: "<s.version>"` (Package.swift has no version; the SPM demo uses a local package).
#      The documentation navigation is regenerated afterwards. Commit the changes.
# [CN] Carthage 与 Swift Package Manager 都没有中央仓库：版本就是 `pod trunk push` 同样需要的 git tag。push 成功后，所有固定本库
#      版本的地方都跟随 podspec 的 s.version：
#      - Carthage：预编译的 XCFramework（docs/Carthage.md）。App 使用 `binary "<CYLTabBarController.json 的 URL>"`：本仓库包含
#        Flutter 示例的 Xcode 工程，Carthage 无法从源码编译。CYLTabBarController.json 添加 "<s.version>": "<Release 附件 URL>"
#        （URL 在发布前已确定，因此 `bump` 会把它加入发布 PR）；Release workflow 上传 `xcframework` 生成的 zip。
#        演示工程的 Example-Swift-Carthage/Cartfile 改为 `binary "..." ~> <s.version>`。
#      - SPM：README.md 与 docs/*.md 中所有 `.package(url: ".../CYLTabBarController.git", from: "...")` 改为
#        `from: "<s.version>"`（Package.swift 没有版本号；SPM 演示工程使用本地 package）。
#      之后重新生成文档导航。请提交这些修改。
set -e
cd "$(dirname "$0")/.."
export XCODE_XCCONFIG_FILE="$PWD/scripts/pod-lint.xcconfig"

PODSPEC=CYLTabBarController.podspec
CARTFILE=Example-Swift-Carthage/Cartfile
CARTHAGE_SPEC=CYLTabBarController.json
CARTHAGE_SPEC_URL='https://raw.githubusercontent.com/ChenYilong/CYLTabBarController/master/CYLTabBarController.json'
CARTHAGE_DEPENDENCY="binary \"$CARTHAGE_SPEC_URL\""
CARTHAGE_ASSET=CYLTabBarController.xcframework.zip
RELEASE_DOWNLOAD_URL='https://github.com/ChenYilong/CYLTabBarController/releases/download'

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
  # [EN] The binary spec: one "version": "zip URL" entry per release, sorted by version, the others kept.
  # [CN] 二进制规格文件：每个版本一条 "版本": "zip URL"，按版本排序，保留已有条目。
  python3 - "$CARTHAGE_SPEC" "$version" "$RELEASE_DOWNLOAD_URL/$version/$CARTHAGE_ASSET" <<'PYTHON'
import json, os, sys
path, version, url = sys.argv[1:4]
spec = json.load(open(path)) if os.path.exists(path) else {}
spec[version] = url
ordered = dict(sorted(spec.items(), key=lambda item: [int(part) for part in item[0].split(".")]))
with open(path, "w") as file:
    json.dump(ordered, file, indent=2)
    file.write("\n")
PYTHON
  # [EN] The demo's dependency line, whatever form it had (github or binary). [CN] 演示工程的依赖行，无论原来是 github 还是 binary 形式。
  sed -e "s|^github \"ChenYilong/CYLTabBarController\".*\$|$CARTHAGE_DEPENDENCY ~> $version|" \
      -e "s|^binary \"[^\"]*CYLTabBarController.json\".*\$|$CARTHAGE_DEPENDENCY ~> $version|" "$CARTFILE" > "$CARTFILE.tmp"
  mv "$CARTFILE.tmp" "$CARTFILE"
  if ! grep -qF "$CARTHAGE_DEPENDENCY ~> $version" "$CARTFILE"; then
    echo "error: the CYLTabBarController line was not found in $CARTFILE" >&2
    exit 1
  fi
  echo "Carthage: $CARTHAGE_SPEC lists $version; $CARTFILE requires it (commit these changes)"
}

# [EN] The XCFramework of the release, zipped for Carthage's binary spec. Built from a clean copy of HEAD without
#      CrossPlatform/: Carthage lists the schemes of every Xcode project it finds, and the Flutter examples' projects
#      need packages that only `flutter pub get` creates.
# [CN] 发布用的 XCFramework，压缩为 Carthage 二进制规格使用的 zip。从 HEAD 的干净副本（去掉 CrossPlatform/）构建：Carthage 会列出
#      找到的每个 Xcode 工程的 scheme，而 Flutter 示例的工程依赖只有 `flutter pub get` 才会生成的包。
build_xcframework() {
  command -v carthage >/dev/null 2>&1 || { echo "error: carthage is not installed (brew install carthage)" >&2; exit 1; }
  root=$PWD
  work=$(mktemp -d "${TMPDIR:-/tmp}/cyl-xcframework.XXXXXX")
  git archive HEAD | tar -x -C "$work"
  rm -rf "$work/CrossPlatform"
  (cd "$work" && carthage build --no-skip-current --use-xcframeworks --platform iOS)
  mkdir -p "$root/build"
  rm -f "$root/build/$CARTHAGE_ASSET"
  (cd "$work/Carthage/Build" && zip -qry "$root/build/$CARTHAGE_ASSET" CYLTabBarController.xcframework)
  rm -rf "$work"
  echo "Carthage: build/$CARTHAGE_ASSET (upload it to the GitHub release of the tag)"
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

# The tag of a release must be the podspec's version (s.source uses it). 发布的 tag 必须等于 podspec 的版本（s.source 使用它）。
check_tag() {
  release_version
  if [ "$1" != "$version" ]; then
    echo "error: the tag '$1' does not match s.version $version in $PODSPEC. Bump it first (scripts/pod-lint.sh bump $1), merge, then tag that commit." >&2
    exit 1
  fi
  echo "Tag $1 matches s.version in $PODSPEC"
}

# Set s.version (only the first s.version line). 设置 s.version（只改第一行 s.version）。
bump_version() {
  case "$1" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *) echo "usage: $0 bump <x.y.z>   (e.g. $0 bump 1.99.73)" >&2; exit 1 ;;
  esac
  if printf '%s' "$1" | grep -q '[^0-9.]'; then
    echo "error: '$1' is not a version like 1.99.73" >&2
    exit 1
  fi
  release_version
  sed "1,/^[[:space:]]*s\.version[[:space:]]*=/s|^\([[:space:]]*s\.version[[:space:]]*=[[:space:]]*[\"']\)[^\"']*\([\"']\)|\1$1\2|" "$PODSPEC" > "$PODSPEC.tmp"
  mv "$PODSPEC.tmp" "$PODSPEC"
  if [ "$(pod_version)" != "$1" ]; then
    echo "error: could not set s.version in $PODSPEC" >&2
    exit 1
  fi
  echo "Podspec: s.version $version → $1 (commit this change, then tag the merged commit $1)"
}

case "$1" in
  push)      shift; pod trunk push "$PODSPEC" --allow-warnings "$@"; update_carthage; update_spm; update_navigation ;;
  version)   release_version; echo "$version" ;;
  check-tag) check_tag "${2:?usage: $0 check-tag <tag>}" ;;
  bump)      bump_version "${2:-}"; update_carthage; update_spm; update_navigation ;;
  carthage) update_carthage ;;
  xcframework) build_xcframework ;;
  spm)      update_spm; update_navigation ;;
  versions) update_carthage; update_spm; update_navigation ;;
  *)        [ "$1" = lib ] && shift; pod lib lint "$PODSPEC" --allow-warnings "$@" ;;
esac
