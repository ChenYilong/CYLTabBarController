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
branch="feat/lifecycle-callbacks"

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
- Branch: \`$branch\` (pull request #12)
- Folder in the library: \`$1\`
- Commit: \`$full\`
EOF
}

generate() {
  # $1: output root
  local out="$1"
  mkdir -p "$out/$harmony_dest/src/main/ets" "$out/$mini_dest"
  git -C "$library" archive "$full" HarmonyOS MiniProgram LICENSE | tar -x -C "$work/x"
  # [EN] HarmonyOS: the registry and controller as plain TypeScript, imported without the `.ts` extension (ArkTS resolves by name).
  # [CN] 鸿蒙：注册表与控制器为纯 TypeScript，导入时不带 `.ts` 扩展名（ArkTS 按名称解析）。
  for file in types registry controller; do
    sed "s#from '\./\([a-z]*\)\.ts'#from './\1'#" "$work/x/HarmonyOS/src/$file.ts" > "$out/$harmony_dest/src/main/ets/$file.ts"
  done
  cp "$work/x/HarmonyOS/cyldeallocblockexecutor/oh-package.json5" "$work/x/HarmonyOS/cyldeallocblockexecutor/build-profile.json5" \
     "$work/x/HarmonyOS/cyldeallocblockexecutor/hvigorfile.ts" "$work/x/LICENSE" "$out/$harmony_dest/"
  cp "$work/x/HarmonyOS/cyldeallocblockexecutor/src/main/module.json5" "$out/$harmony_dest/src/main/"
  cat > "$out/$harmony_dest/Index.ets" <<'EOT'
export { LifecycleController } from './src/main/ets/controller';
export { LifecycleRegistry } from './src/main/ets/registry';
export { LifecycleEvent, LifecycleTiming } from './src/main/ets/types';
EOT
  # [EN] Mini Program: CommonJS files of the library, no build step. [CN] 小程序：库中的 CommonJS 文件，无需构建。
  cp "$work/x/MiniProgram/index.js" "$work/x/MiniProgram/registry.js" "$work/x/MiniProgram/types.js" "$work/x/MiniProgram/controller.js" \
     "$work/x/MiniProgram/package.json" "$work/x/LICENSE" "$out/$mini_dest/"
  vendored_md "HarmonyOS" "HarmonyOS, ArkTS" > "$out/$harmony_dest/VENDORED.md"
  vendored_md "MiniProgram" "WeChat Mini Program, JavaScript" > "$out/$mini_dest/VENDORED.md"
}

mkdir -p "$work/x"
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
