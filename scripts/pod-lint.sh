#!/bin/sh
# Usage:
#   scripts/pod-lint.sh lib   [extra pod args]   # pod lib lint
#   scripts/pod-lint.sh push  [extra pod args]   # pod trunk push
set -e
cd "$(dirname "$0")/.."
export XCODE_XCCONFIG_FILE="$PWD/scripts/pod-lint.xcconfig"
case "$1" in
  push) shift; pod trunk push CYLTabBarController.podspec --allow-warnings "$@" ;;
  *)    [ "$1" = lib ] && shift; pod lib lint CYLTabBarController.podspec --allow-warnings "$@" ;;
esac
