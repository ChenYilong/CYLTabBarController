#!/usr/bin/env bash
# Fetch CollectionViewClassifyMenu at the commit pinned in CrossPlatform/harmonyos-cyltabbar/classifymenu.pin (one pin for
# every platform): the HarmonyOS module (harmony/classifymenu) into CrossPlatform/harmonyos-cyltabbar/cylclassifymenu, the
# Android library (android/merged/library) into Example-Android/cylclassifymenu, both git-ignored.
# The examples' sectioned lists use its tag list (docs/instructions/examples.md). No copy is committed here.
# Usage: scripts/fetch-classifymenu.sh [harmony|android]   (default: harmony)
# Env: CYL_CLASSIFYMENU_REPO (URL or local path; default: GitHub).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HM="$ROOT/CrossPlatform/harmonyos-cyltabbar"
SHA="$(tr -d '[:space:]' < "$HM/classifymenu.pin")"
PLATFORM="${1:-harmony}"
case "$PLATFORM" in
  harmony) DEST="$HM/cylclassifymenu"; SRCDIR="harmony/classifymenu"; STRIP=2 ;;
  android) DEST="$ROOT/Example-Android/cylclassifymenu"; SRCDIR="android/merged/library"; STRIP=3 ;;
  *) echo "usage: $0 [harmony|android]" >&2; exit 2 ;;
esac
REPO="${CYL_CLASSIFYMENU_REPO:-https://github.com/ChenYilong/CollectionViewClassifyMenu.git}"
if [[ -f "$DEST/.pinned-sha" && "$(cat "$DEST/.pinned-sha")" = "$SHA" ]]; then exit 0; fi
CACHE="${CYL_CLASSIFYMENU_CACHE:-${TMPDIR:-/tmp}/cyl-classifymenu-cache.git}"
[[ -d "$CACHE" ]] || git init --bare -q "$CACHE"
git --git-dir="$CACHE" cat-file -e "$SHA^{commit}" 2>/dev/null || git --git-dir="$CACHE" fetch -q "$REPO" "$SHA" 2>/dev/null \
  || git --git-dir="$CACHE" fetch -q "$REPO" '+refs/heads/*:refs/cache/*'
rm -rf "$DEST"; mkdir -p "$DEST"
git --git-dir="$CACHE" archive "$SHA" "$SRCDIR" | tar -x -C "$DEST" --strip-components=$STRIP
# [EN] The library's own build file uses its repository's version catalog; the example builds it with its own (Example-Android/cylclassifymenu.build.gradle.kts).
if [[ "$PLATFORM" = android ]]; then cp "$ROOT/Example-Android/cylclassifymenu.build.gradle.kts" "$DEST/build.gradle.kts"; rm -rf "$DEST/src/test" "$DEST/src/androidTest"; fi
echo "$SHA" > "$DEST/.pinned-sha"
echo "classifymenu $SHA -> $DEST"
