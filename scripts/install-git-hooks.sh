#!/usr/bin/env bash
# [EN] Installs the repository's git hooks (.githooks/) into .git/hooks, keeping hooks that are already there
#      (an existing pre-commit is kept as pre-commit.chained and still runs). Run once per clone:
#      bash scripts/install-git-hooks.sh
# [CN] 把仓库的 git hook（.githooks/）安装到 .git/hooks，保留已有的 hook。每个克隆运行一次。
set -euo pipefail
root=$(git rev-parse --show-toplevel)
hooks="$root/.git/hooks"
for hook in "$root"/.githooks/*; do
    name=$(basename "$hook")
    target="$hooks/$name"
    if [[ -e "$target" ]] && ! cmp -s "$hook" "$target" && ! grep -q "check-screenshot-labels" "$target" 2>/dev/null; then
        mv "$target" "$target.chained"
        echo "kept the existing $name as $name.chained"
    fi
    cp "$hook" "$target"
    chmod +x "$target"
    echo "installed $name"
done
