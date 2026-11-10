#!/bin/sh
# Prints the newest commit of CYLTabBarController on ANY branch, by commit timestamp (AGENTS.md, "Depending on CYLTabBarController").
#
#   scripts/latest-cyl-commit.sh             # <sha> <committer date, ISO 8601> <branch>
#   scripts/latest-cyl-commit.sh --sha       # the sha only
#   scripts/latest-cyl-commit.sh --podfile   # the Podfile line for a project outside CYLTabBarController
#
# Run it before every build of a project that depends on CYLTabBarController, from any folder: it keeps a small bare
# clone (commits only, no file contents) in $CYL_COMMIT_CACHE (default: $TMPDIR/cyl-latest-commit.git) and fetches every
# branch of $CYL_REPO_URL (default: https://github.com/ChenYilong/CYLTabBarController.git) into it first.
set -eu

REPO="${CYL_REPO_URL:-https://github.com/ChenYilong/CYLTabBarController.git}"
CACHE="${CYL_COMMIT_CACHE:-${TMPDIR:-/tmp}/cyl-latest-commit.git}"
MODE="${1:-}"

[ -d "$CACHE" ] || git init --bare -q "$CACHE"
git -C "$CACHE" fetch -q --prune --no-tags --filter=blob:none "$REPO" '+refs/heads/*:refs/remotes/origin/*'
LINE="$(git -C "$CACHE" for-each-ref --sort=-committerdate --count=1 \
    --format='%(objectname) %(committerdate:iso-strict) %(refname:lstrip=3)' refs/remotes/origin)"
SHA="${LINE%% *}"
[ -n "$SHA" ] || { echo "no commit found in $REPO" >&2; exit 1; }

case "$MODE" in
    --sha) echo "$SHA" ;;
    --podfile) echo "pod 'CYLTabBarController', :git => '${REPO}', :commit => '${SHA}'" ;;
    "") echo "$LINE" ;;
    *) echo "usage: $0 [--sha | --podfile]" >&2; exit 2 ;;
esac
