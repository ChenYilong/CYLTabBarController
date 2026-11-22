#!/usr/bin/env bash
# [EN] Copies the HarmonyOS and mini program ports of CYLDeallocBlockExecutor from a library commit into this repository
#      (ohpm and npm cannot install a git dependency, and the library is not published yet), and writes VENDORED.md next to
#      each copy. --check regenerates both copies in a temporary folder and fails when the repository differs from the pinned commit.
#      Usage: scripts/sync-cyldeallocblockexecutor.sh [--check] [<library commit>]
#      Without a commit the one pinned in CrossPlatform/harmonyos-cyltabbar/cyldeallocblockexecutor/VENDORED.md is used.
#      The library repository: $CYL_DEALLOC_LIBRARY (a path) or https://github.com/ChenYilong/CYLDeallocBlockExecutor.git.
# [CN] 把 CYLDeallocBlockExecutor 的鸿蒙与小程序移植从库的某个提交复制到本仓库（ohpm 与 npm 无法安装 git 依赖，库尚未发布），并在每份副本旁写
#      VENDORED.md。--check 在临时目录重新生成两份副本，仓库与固定提交不一致时失败。
#      TODO: replace the copies with the ohpm and npm packages after the library is published (owner's OK).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
harmony_dest="CrossPlatform/harmonyos-cyltabbar/cyldeallocblockexecutor"
mini_dest="CrossPlatform/wechat-miniprogram-cyltabbar/src/cyl-dealloc-block-executor"
repository_url="https://github.com/ChenYilong/CYLDeallocBlockExecutor.git"
branch="feat/lifecycle-callbacks-android"

check=0
commit=""
for argument in "$@"; do
  case "$argument" in
    --check) check=1 ;;
    *) commit="$argument" ;;
  esac
done

if [ -z "$commit" ]; then
  # shellcheck disable=SC2016
  commit="$(sed -n 's/^- Commit: `\([0-9a-f]\{40\}\)`.*/\1/p' "$root/$harmony_dest/VENDORED.md" | head -1)"
  [ -n "$commit" ] || { echo "no pinned commit in $harmony_dest/VENDORED.md" >&2; exit 2; }
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
library="${CYL_DEALLOC_LIBRARY:-}"
if [ -z "$library" ]; then
  git clone --quiet --no-checkout "$repository_url" "$work/library"
  library="$work/library"
fi
git -C "$library" cat-file -e "$commit^{commit}" 2>/dev/null || git -C "$library" fetch --quiet origin "$branch"
full="$(git -C "$library" rev-parse "$commit^{commit}")"

vendored_md() {
  # $1: the library folder, $2: what it is
  cat <<EOF
# [CN]外部副本：CYLDeallocBlockExecutor（$2）
# [EN]Vendored copy: CYLDeallocBlockExecutor ($2)

| 中文 | English |
|:---|:---|
| 本目录是库 CYLDeallocBlockExecutor 的副本，不要直接修改；用 \`scripts/sync-cyldeallocblockexecutor.sh\` 更新，\`--check\` 检查是否与固定提交一致。 | This folder is a copy of the library CYLDeallocBlockExecutor. Do not edit it here; update it with \`scripts/sync-cyldeallocblockexecutor.sh\`; \`--check\` fails when it differs from the pinned commit. |
| 原因：ohpm 与 npm 不能安装 git 依赖，库尚未发布。 | Why: ohpm and npm cannot install a git dependency and the library is not published yet. |
| TODO：库发布后改用 ohpm / npm 包（需要所有者同意）。 | TODO: replace this copy with the ohpm / npm package after the library is published (the owner's OK is needed). |

- Library: https://github.com/ChenYilong/CYLDeallocBlockExecutor
- Branch: \`$branch\` (pull request #13)
- Folder in the library: \`$1\`
- Commit: \`$full\`
EOF
}

generate() {
  # $1: output root
  local out="$1"
  mkdir -p "$out/$harmony_dest" "$out/$mini_dest"
  git -C "$library" archive "$full" harmonyos/cyldeallocblockexecutor | tar -x -C "$work/h"
  git -C "$library" archive "$full" miniprogram | tar -x -C "$work/m"
  cp -R "$work/h/harmonyos/cyldeallocblockexecutor/." "$out/$harmony_dest/"
  cp "$work/m/miniprogram/cyl-dealloc-block-executor.js" "$work/m/miniprogram/package.json" "$work/m/miniprogram/LICENSE" "$out/$mini_dest/"
  rm -rf "$out/$harmony_dest/test"
  vendored_md "harmonyos/cyldeallocblockexecutor" "HarmonyOS, ArkTS" > "$out/$harmony_dest/VENDORED.md"
  vendored_md "miniprogram" "WeChat Mini Program, JavaScript" > "$out/$mini_dest/VENDORED.md"
}

mkdir -p "$work/h" "$work/m"
if [ "$check" -eq 1 ]; then
  generate "$work/expected"
  status=0
  for destination in "$harmony_dest" "$mini_dest"; do
    diff -r -x build -x BuildProfile.ets -x oh_modules -x .hvigor "$work/expected/$destination" "$root/$destination" || status=1
  done
  [ "$status" -eq 0 ] && echo "cyldeallocblockexecutor copies match $full" || echo "the copies differ from $full: run scripts/sync-cyldeallocblockexecutor.sh" >&2
  exit "$status"
fi
for destination in "$harmony_dest" "$mini_dest"; do
  rm -rf "${root:?}/$destination"
done
generate "$root"
echo "cyldeallocblockexecutor copies updated to $full"
