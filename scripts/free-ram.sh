#!/bin/sh
# Usage:
#   scripts/free-ram.sh            # free up RAM before running the iOS Simulator (never asks for a password)
#   scripts/free-ram.sh --install  # one-time setup: let `sudo purge` run without a password (asks for it once)
#
# [EN] Frees memory before the iOS Simulator starts (CLAUDE.md asks AI agents to run it first):
#      1. `purge` flushes the disk cache ("Cached Files" in Activity Monitor), as "Free Up RAM" tools do.
#         It runs with `sudo -n`, which never prompts: without the --install rule it is skipped with a hint.
#      2. Prints the memory pressure before and after, and the five processes that use the most memory.
#      It never quits an app or a simulator. On a system other than macOS it does nothing.
# [CN] 在启动 iOS 模拟器前释放内存（CLAUDE.md 要求 AI 代理先运行本脚本）：
#      1. `purge` 清空磁盘缓存（活动监视器中的「已缓存文件」），与各类「释放内存」工具的做法相同。
#         使用不会弹出密码提示的 `sudo -n`：未执行 --install 时跳过该步骤并给出提示。
#      2. 输出清理前后的内存压力，以及内存占用最多的 5 个进程。
#      不会退出任何 App 或模拟器。在 macOS 以外的系统上什么都不做。
set -e

if [ "$(uname -s)" != "Darwin" ]; then
  echo "free-ram: not macOS, nothing to do"
  exit 0
fi

PURGE=/usr/sbin/purge
SUDOERS_FILE=/etc/sudoers.d/cyl-free-ram

# [EN] One-time setup: a sudoers rule that allows only `sudo purge` without a password, for the current user.
# [CN] 一次性设置：为当前用户添加 sudoers 规则，只允许无密码执行 `sudo purge`。
if [ "$1" = "--install" ]; then
  user=$(id -un)
  rule="$user ALL=(root) NOPASSWD: $PURGE"
  tmp=$(mktemp)
  echo "$rule" > "$tmp"
  # Validate before installing, so a broken rule can never lock sudo. 安装前先校验，避免错误规则导致 sudo 不可用。
  if ! visudo -cf "$tmp" >/dev/null; then
    rm -f "$tmp"
    echo "free-ram: the sudoers rule did not validate" >&2
    exit 1
  fi
  sudo install -m 0440 -o root -g wheel "$tmp" "$SUDOERS_FILE"
  rm -f "$tmp"
  echo "free-ram: installed $SUDOERS_FILE ($rule)"
  exit 0
fi

pressure() {
  memory_pressure 2>/dev/null | tail -n 1 || true
}

echo "free-ram: before: $(pressure)"

if sudo -n "$PURGE" 2>/dev/null; then
  echo "free-ram: purge done"
else
  echo "free-ram: purge skipped (it needs a password). Run once: scripts/free-ram.sh --install"
fi

echo "free-ram: after: $(pressure)"
echo "free-ram: top 5 processes by memory:"
ps -axo rss=,comm= | sort -rn | head -n 5 | awk '{ rss = $1; $1 = ""; printf "  %6.0f MB %s\n", rss / 1024, $0 }'
exit 0
