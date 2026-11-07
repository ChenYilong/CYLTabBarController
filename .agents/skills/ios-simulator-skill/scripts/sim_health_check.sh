#!/usr/bin/env bash
#
# iOS Simulator Testing Environment Health Check
#
# Verifies that all required tools and dependencies are properly installed
# and configured for iOS simulator testing.
#
# Usage: bash scripts/sim_health_check.sh [--help]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# idb-companion below this cannot find SimulatorKit under the Xcode 27 layout:
# every `idb ui` write (tap/swipe/type) then fails. Fixed upstream in 1.5.1.
MIN_COMPANION_VERSION="1.5.1"
# Below this idb still works, but keyboard.py's volume buttons need it.
RECOMMENDED_IDB_VERSION="1.6.3"

# version_lt A B: true when version A is older than version B.
version_lt() {
    [ "$1" != "$2" ] && [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]
}

# Check flags
SHOW_HELP=false
JSON_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        --json)
            JSON_MODE=true
            shift
            ;;
    esac
done

if [ "$SHOW_HELP" = true ]; then
    cat <<EOF
iOS Simulator Testing - Environment Health Check

Verifies that your environment is properly configured for iOS simulator testing.

Usage: bash scripts/sim_health_check.sh [options]

Options:
  --help, -h    Show this help message
  --json        Emit machine-readable results instead of formatted text

This script checks for:
  - Xcode Command Line Tools installation
  - iOS Simulator availability
  - idb CLI installation (required for tap/swipe/type)
  - idb-companion version (>= $MIN_COMPANION_VERSION required on Xcode 27, >= $RECOMMENDED_IDB_VERSION recommended)
  - idb CLI and companion on the same minor version
  - Python 3.12+ installation (for scripts)
  - Available simulator devices
  - Xcode 27 SimulatorKit layout compatibility
  - Stale idb companion registrations
  - idb companion runtime: axbridge guest present, no companions older than the install

Exit codes:
  0 - All checks passed
  1 - One or more checks failed (see output for details)
EOF
    exit 0
fi
# In --json mode the formatted output is suppressed wholesale rather than
# guarding every echo; the JSON is written to the saved descriptor at the end.
exec 3>&1
if [ "$JSON_MODE" = true ]; then
    exec 1>/dev/null
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  iOS Simulator Testing - Environment Health Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Structured results, collected for --json alongside the human output.
# Each entry is one JSON object; remediation is the command that fixes it.
JSON_RESULTS=()

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

record() {
    # record <status> <message> [remediation]
    JSON_RESULTS+=("{\"status\":\"$1\",\"message\":\"$(json_escape "$2")\",\"remediation\":\"$(json_escape "${3:-}")\"}")
}

# Function to print check status
check_passed() {
    echo -e "${GREEN}✓${NC} $1"
    record "pass" "$1"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
    record "fail" "$1" "${2:-}"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

check_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    record "warn" "$1" "${2:-}"
}


# Check 1: macOS
echo -e "${BLUE}[1/11]${NC} Checking operating system..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_VERSION=$(sw_vers -productVersion)
    check_passed "macOS detected (version $OS_VERSION)"
else
    check_failed "Not running on macOS (detected: $OSTYPE)"
    echo "       iOS Simulator testing requires macOS"
fi
echo ""

# Check 2: Xcode Command Line Tools
echo -e "${BLUE}[2/11]${NC} Checking Xcode Command Line Tools..."
if command -v xcrun &> /dev/null; then
    XCODE_PATH=$(xcode-select -p 2>/dev/null || echo "not found")
    if [ "$XCODE_PATH" != "not found" ]; then
        XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -n 1 || echo "Unknown")
        check_passed "Xcode Command Line Tools installed"
        echo "       Path: $XCODE_PATH"
        echo "       Version: $XCODE_VERSION"
    else
        check_failed "Xcode Command Line Tools path not set"
        echo "       Run: xcode-select --install"
    fi
else
    check_failed "xcrun command not found"
    echo "       Install Xcode Command Line Tools: xcode-select --install"
fi
echo ""

# Check 3: simctl availability
echo -e "${BLUE}[3/11]${NC} Checking simctl (Simulator Control)..."
if command -v xcrun &> /dev/null && xcrun simctl help &> /dev/null; then
    check_passed "simctl is available"
else
    check_failed "simctl not available"
    echo "       simctl comes with Xcode Command Line Tools"
fi
echo ""

# Check 4: idb CLI
# Required, not optional: every tap, swipe and keystroke goes through `idb ui`.
IDB_INSTALL_CMD="brew install facebook/fb/idb"
IDB_UPGRADE_CMD="brew upgrade facebook/fb/idb-cli facebook/fb/idb-companion"
# Only known for a Homebrew client, whose path carries the version; check 5 uses it.
IDB_CLIENT_VERSION=""
echo -e "${BLUE}[4/11]${NC} Checking idb CLI..."
if command -v idb &> /dev/null; then
    # Probe the idb the scripts will actually run: a pyenv python3 shim puts its own
    # bin/ first on PATH, where an old pip `fb-idb` can shadow the brew idb-cli.
    SHELL_IDB=$(command -v idb)
    SCRIPT_IDB=$(python3 -c 'import shutil; print(shutil.which("idb") or "")' 2>/dev/null)
    SCRIPT_IDB=${SCRIPT_IDB:-$SHELL_IDB}
    # `ui pinch` arrived with `ui key --command` in idb-cli 1.5.1; gesture.py and
    # keyboard.py --clear need both.
    IDB_CLIENT_VERSION=$(realpath "$SCRIPT_IDB" 2>/dev/null | sed -n 's#.*/Cellar/idb-cli/\([^/]*\)/.*#\1#p')
    if "$SCRIPT_IDB" ui pinch --help &> /dev/null; then
        check_passed "idb CLI ${IDB_CLIENT_VERSION:+$IDB_CLIENT_VERSION }is installed and current"
        echo "       Path: $SCRIPT_IDB"
    elif [ "$SCRIPT_IDB" != "$SHELL_IDB" ]; then
        check_failed "Python scripts see an old idb CLI at $SCRIPT_IDB (shadows $SHELL_IDB)" "pip uninstall fb-idb"
        echo "       Likely a pip-installed fb-idb under pyenv. Fix: pip uninstall fb-idb && pyenv rehash"
    else
        check_failed "idb CLI at $SCRIPT_IDB is too old (no 'ui pinch'; need idb-cli >= 1.5.1)" "$IDB_UPGRADE_CMD"
        echo "       Upgrade: $IDB_UPGRADE_CMD"
    fi
else
    check_failed "idb CLI not found in PATH" "$IDB_INSTALL_CMD"
    echo "       Required for all interactive scripts (navigator.py, gesture.py, keyboard.py)"
    echo "       Install: $IDB_INSTALL_CMD"
fi
echo ""

# Check 5: idb-companion version
# idb-companion <= 1.1.8 hardcodes the pre-Xcode-27 SimulatorKit path. Under
# Xcode 27 its HID writes fail, so taps silently do nothing while reads work.
echo -e "${BLUE}[5/11]${NC} Checking idb-companion >= ${MIN_COMPANION_VERSION}..."
if command -v idb_companion &> /dev/null; then
    COMPANION_VERSION=$(brew list --versions idb-companion 2>/dev/null | awk '{print $2}')
    if [ -z "$COMPANION_VERSION" ]; then
        check_warning "idb-companion found but its version could not be determined" "$IDB_INSTALL_CMD"
        echo "       Not installed via Homebrew; ensure it is >= ${MIN_COMPANION_VERSION} on Xcode 27"
    elif version_lt "$COMPANION_VERSION" "$MIN_COMPANION_VERSION"; then
        check_failed "idb-companion $COMPANION_VERSION is too old (need >= ${MIN_COMPANION_VERSION})" "$IDB_UPGRADE_CMD"
        echo "       On Xcode 27 this makes taps/swipes silently do nothing"
        echo "       Upgrade: $IDB_UPGRADE_CMD"
    elif version_lt "$COMPANION_VERSION" "$RECOMMENDED_IDB_VERSION"; then
        check_warning "idb-companion $COMPANION_VERSION works, but ${RECOMMENDED_IDB_VERSION}+ is recommended (volume buttons need it)" "$IDB_UPGRADE_CMD"
        echo "       Upgrade: $IDB_UPGRADE_CMD"
    else
        check_passed "idb-companion $COMPANION_VERSION (>= ${MIN_COMPANION_VERSION} required)"
    fi
    # Newer client features (--format complete, marker taps) are served by the companion,
    # so a 1.7 client against a 1.5 companion fails or falls back to legacy output.
    if [ -n "$IDB_CLIENT_VERSION" ] && [ -n "$COMPANION_VERSION" ] \
        && [ "${IDB_CLIENT_VERSION%.*}" != "${COMPANION_VERSION%.*}" ]; then
        check_warning "idb CLI $IDB_CLIENT_VERSION and idb-companion $COMPANION_VERSION are on different minor versions" "$IDB_UPGRADE_CMD"
        echo "       Upgrade both together: $IDB_UPGRADE_CMD"
    fi
else
    check_failed "idb-companion not found in PATH" "$IDB_INSTALL_CMD"
    echo "       Install: $IDB_INSTALL_CMD"
fi
echo ""

# Check 6: Python 3.12+ installation
echo -e "${BLUE}[6/11]${NC} Checking Python 3.12+..."
if command -v python3 &> /dev/null; then
    PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
    PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 12 ]; }; then
        check_failed "Python $PYTHON_MAJOR.$PYTHON_MINOR found — Python 3.12+ required"
        echo "       Upgrade: brew install python@3.12"
    else
        check_passed "Python $PYTHON_MAJOR.$PYTHON_MINOR (>= 3.12 required)"
    fi
else
    check_failed "Python 3 not found"
    echo "       Python 3.12+ is required for testing scripts"
    echo "       Install: brew install python@3.12"
fi
echo ""

# Check 7: Available simulators
echo -e "${BLUE}[7/11]${NC} Checking available iOS Simulators..."
if command -v xcrun &> /dev/null; then
    SIMULATOR_COUNT=$(xcrun simctl list devices available 2>/dev/null | grep -c "iPhone\|iPad" || echo "0")

    if [ "$SIMULATOR_COUNT" -gt 0 ]; then
        check_passed "Found $SIMULATOR_COUNT available simulator(s)"

        # Show first 5 simulators
        echo ""
        echo "       Available simulators (showing up to 5):"
        xcrun simctl list devices available 2>/dev/null | grep "iPhone\|iPad" | head -5 | while read -r line; do
            echo "       - $line"
        done
    else
        check_warning "No simulators found"
        echo "       Create simulators via Xcode or simctl"
        echo "       Example: xcrun simctl create 'iPhone 15' 'iPhone 15'"
    fi
else
    check_failed "Cannot check simulators (simctl not available)"
fi
echo ""

# Check 8: Booted simulators
echo -e "${BLUE}[8/11]${NC} Checking booted simulators..."
if command -v xcrun &> /dev/null; then
    BOOTED_SIMS=$(xcrun simctl list devices booted 2>/dev/null | grep -c "iPhone\|iPad" || echo "0")

    if [ "$BOOTED_SIMS" -gt 0 ]; then
        check_passed "$BOOTED_SIMS simulator(s) currently booted"

        echo ""
        echo "       Booted simulators:"
        xcrun simctl list devices booted 2>/dev/null | grep "iPhone\|iPad" | while read -r line; do
            echo "       - $line"
        done
    else
        check_warning "No simulators currently booted"
        echo "       Boot a simulator to begin testing"
        echo "       Example: xcrun simctl boot <device-udid>"
        echo "       Or open the UI: open -b com.apple.dt.Devices  (Device Hub, Xcode 27+; older Xcode: open -a Simulator)"
    fi
else
    check_failed "Cannot check booted simulators (simctl not available)"
fi
echo ""

# Check 9: Required Python packages (optional check)
echo -e "${BLUE}[9/11]${NC} Checking Python packages..."
if command -v python3 &> /dev/null; then
    MISSING_PACKAGES=()

    # Check for PIL/Pillow (for visual_diff.py)
    if python3 -c "import PIL" 2>/dev/null; then
        check_passed "Pillow (PIL) installed - visual diff available"
    else
        MISSING_PACKAGES+=("pillow")
        check_warning "Pillow (PIL) not installed - visual diff won't work"
    fi

    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo ""
        echo "       Install missing packages:"
        echo "       pip3 install ${MISSING_PACKAGES[*]}"
    fi
else
    check_warning "Cannot check Python packages (Python 3 not available)"
fi
echo ""

# Check 10: Xcode 27 layout and stale companion registrations
# Two Xcode 27 traps that both present as "idb reports success but nothing happens".
echo -e "${BLUE}[10/11]${NC} Checking Xcode 27 compatibility..."
XCODE27_ISSUES=0

DEVELOPER_PATH=$(xcode-select -p 2>/dev/null || echo "")
if [ -n "$DEVELOPER_PATH" ] && [ ! -d "$DEVELOPER_PATH/Library/PrivateFrameworks/SimulatorKit.framework" ]; then
    # Xcode 27+ layout: SimulatorKit lives in Contents/SharedFrameworks instead.
    # Check 5 already owns the version verdict; this only explains the stakes.
    echo "       Xcode 27+ framework layout detected (SimulatorKit under SharedFrameworks)"
    echo "       This layout needs idb-companion >= ${MIN_COMPANION_VERSION} (see check 5)"
fi

# A dead companion left in idb's registry makes every later idb call fail with
# "Connection refused" instead of spawning a working replacement.
STALE_UDIDS=""
if [ -f /tmp/idb/state ]; then
    STALE_UDIDS=$(python3 - <<'PY' 2>/dev/null || true
import json, os, re
UDID = re.compile(r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}")
try:
    with open("/tmp/idb/state") as handle:
        entries = json.load(handle)
except Exception:
    raise SystemExit
for entry in entries:
    pid = entry.get("pid")
    if not pid:
        continue
    try:
        os.kill(pid, 0)
    except OSError:
        # Only report well-formed simulator UDIDs.
        udid = str(entry.get("udid", ""))
        if UDID.fullmatch(udid):
            print(udid)
PY
)
fi

if [ -n "$STALE_UDIDS" ]; then
    for udid in $STALE_UDIDS; do
        check_failed "Stale idb companion registered for $udid" "idb disconnect $udid"
        echo "       Fix: idb disconnect $udid"
    done
    XCODE27_ISSUES=$((XCODE27_ISSUES + 1))
fi

# Leftover from the pre-1.5.1 DEVELOPER_DIR shim, which this skill no longer uses.
for legacy_shim in "$HOME/.ios-simulator-skill/xcode27-idb-shim" "$HOME/.ios-simulator-skill/Xcode27Shim.app"; do
    if [ -d "$legacy_shim" ]; then
        check_warning "Obsolete idb shim left at $legacy_shim" "rm -rf \"$legacy_shim\""
        echo "       No longer used; safe to delete: rm -rf \"$legacy_shim\""
    fi
done

if [ "$XCODE27_ISSUES" -eq 0 ]; then
    check_passed "No known Xcode 27 compatibility issues"
fi
echo ""

# Check 11: idb companion runtime
# Two things idb itself never reports: a missing axbridge guest, and companions still
# running a binary that has since been upgraded (they keep the old code until restarted).
echo -e "${BLUE}[11/11]${NC} Checking idb companion runtime..."
RUNTIME_ISSUES=0
COMPANION_REAL=""
if command -v idb_companion &> /dev/null; then
    COMPANION_REAL=$(realpath "$(command -v idb_companion)" 2>/dev/null || true)
fi

if [ -n "$COMPANION_REAL" ]; then
    # idb 1.7 loads its axbridge guest from Resources/ beside the real binary. Without it,
    # axbridge calls fail with "The SimulatorFrameworkBridge guest binary was not found in
    # the companion Resources directory". Older companions have no axbridge at all.
    BRIDGE="$(dirname "$COMPANION_REAL")/Resources/SimulatorFrameworkBridge-iOS"
    if [ -n "$COMPANION_VERSION" ] && version_lt "$COMPANION_VERSION" "1.7.0"; then
        echo "       axbridge needs idb-companion 1.7+ (screen_mapper.py --deep, gesture.py --drag)"
    elif [ ! -x "$BRIDGE" ]; then
        check_warning "idb-companion has no axbridge guest at $BRIDGE" "brew reinstall facebook/fb/idb-companion"
        echo "       Needed by screen_mapper.py --deep and gesture.py --drag"
        RUNTIME_ISSUES=$((RUNTIME_ISSUES + 1))
    fi

    # Homebrew writes INSTALL_RECEIPT.json at install time; the binary's own mtime is
    # its build date, so it can't tell an old process from a new one.
    RECEIPT="$(dirname "$(dirname "$COMPANION_REAL")")/INSTALL_RECEIPT.json"
    if [ -f "$RECEIPT" ]; then
        INSTALLED_AT=$(stat -f %m "$RECEIPT")
        STALE_PIDS=""
        for pid in $(pgrep -x idb_companion || true); do
            started=$(LC_ALL=C ps -o lstart= -p "$pid" 2>/dev/null) || continue
            # shellcheck disable=SC2086 # word-splitting trims ps's padding
            started_at=$(LC_ALL=C date -j -f "%a %b %d %T %Y" "$(echo $started)" +%s 2>/dev/null) || continue
            if [ "$started_at" -lt "$INSTALLED_AT" ]; then
                STALE_PIDS="$STALE_PIDS $pid"
            fi
        done
        if [ -n "$STALE_PIDS" ]; then
            check_warning "idb companions started before idb-companion was last installed (pids:$STALE_PIDS)" "idb kill"
            echo "       They still run the old binary. Restart them: idb kill (the next idb call starts a fresh one)"
            RUNTIME_ISSUES=$((RUNTIME_ISSUES + 1))
        fi
    fi
fi

if [ -z "$COMPANION_REAL" ]; then
    echo "       Skipped: idb-companion not found (see check 5)"
elif [ "$RUNTIME_ISSUES" -eq 0 ]; then
    check_passed "idb companion runtime is current"
fi
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"

if [ "$JSON_MODE" = true ]; then
    exec 1>&3
    if [ "$CHECKS_FAILED" -gt 0 ]; then OVERALL="fail"; else OVERALL="pass"; fi
    printf '{"status":"%s","passed":%d,"failed":%d,"checks":[' "$OVERALL" "$CHECKS_PASSED" "$CHECKS_FAILED"
    for index in "${!JSON_RESULTS[@]}"; do
        [ "$index" -gt 0 ] && printf ','
        printf '%s' "${JSON_RESULTS[$index]}"
    done
    printf ']}\n'
    [ "$CHECKS_FAILED" -gt 0 ] && exit 1
    exit 0
fi

if [ "$CHECKS_FAILED" -gt 0 ]; then
    echo -e "Checks failed: ${RED}$CHECKS_FAILED${NC}"
    echo ""
    echo -e "${YELLOW}Action required:${NC} Fix the failed checks above before testing"
    exit 1
else
    echo ""
    echo -e "${GREEN}✓ Environment is ready for iOS simulator testing${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Boot a simulator: xcrun simctl boot <device>"
    echo "  2. Launch your app: xcrun simctl launch booted <bundle-id>"
    echo "  3. Run accessibility audit: python scripts/accessibility_audit.py"
    exit 0
fi
