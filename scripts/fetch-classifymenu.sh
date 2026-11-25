#!/usr/bin/env bash
# Fetch CollectionViewClassifyMenu's HarmonyOS module (harmony/classifymenu) at the commit pinned in
# CrossPlatform/harmonyos-cyltabbar/classifymenu.pin into CrossPlatform/harmonyos-cyltabbar/cylclassifymenu (git-ignored).
# The example's sectioned lists use its tag list (docs/instructions/examples.md). No copy is committed here.
# Usage: scripts/fetch-classifymenu.sh      Env: CYL_CLASSIFYMENU_REPO (URL or local path; default: GitHub).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HM="$ROOT/CrossPlatform/harmonyos-cyltabbar"
SHA="$(tr -d '[:space:]' < "$HM/classifymenu.pin")"
DEST="$HM/cylclassifymenu"
REPO="${CYL_CLASSIFYMENU_REPO:-https://github.com/ChenYilong/CollectionViewClassifyMenu.git}"
if [[ -f "$DEST/.pinned-sha" && "$(cat "$DEST/.pinned-sha")" = "$SHA" ]]; then exit 0; fi
CACHE="${CYL_CLASSIFYMENU_CACHE:-${TMPDIR:-/tmp}/cyl-classifymenu-cache.git}"
[[ -d "$CACHE" ]] || git init --bare -q "$CACHE"
git --git-dir="$CACHE" cat-file -e "$SHA^{commit}" 2>/dev/null || git --git-dir="$CACHE" fetch -q "$REPO" "$SHA" 2>/dev/null \
  || git --git-dir="$CACHE" fetch -q "$REPO" '+refs/heads/*:refs/cache/*'
rm -rf "$DEST"; mkdir -p "$DEST"
git --git-dir="$CACHE" archive "$SHA" harmony/classifymenu | tar -x -C "$DEST" --strip-components=2
echo "$SHA" > "$DEST/.pinned-sha"
echo "classifymenu $SHA -> $DEST"
