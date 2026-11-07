#!/usr/bin/env python3
"""
Shared IDB utility functions.

This module provides common IDB operations used across multiple scripts.
Follows Jackson's Law - only shared code that's truly reused, not speculative.

Used by:
- navigator.py - Accessibility tree navigation
- screen_mapper.py - UI element analysis
- accessibility_audit.py - WCAG compliance checking
- test_recorder.py - Test documentation
- app_state_capture.py - State snapshots
- gesture.py - Touch gesture operations
"""

import functools
import json
import subprocess
import sys

from .device_utils import get_device_screen_size

HELP_PROBE_TIMEOUT_SECONDS = 10
TREE_READ_ATTEMPTS = 2

IDB_UPGRADE_COMMAND = "brew upgrade facebook/fb/idb-cli facebook/fb/idb-companion"
# How argparse rejects a subcommand or flag that an older idb client doesn't have.
OLD_IDB_REJECTIONS = ("invalid choice", "unrecognized arguments")


def with_idb_upgrade_hint(error: str, requirement: str = "idb 1.7+") -> str:
    """
    Turn an old-idb argparse rejection into one actionable line; pass other errors through.

    argparse prints its whole usage block before the error, which is noise to an
    agent, so only the line naming the problem is kept.

    Example:
        with_idb_upgrade_hint("usage: idb ...\nidb: error: invalid choice: 'shake'")
        # "idb: error: invalid choice: 'shake' (needs idb 1.7+: brew upgrade ...)"
    """
    if not any(rejection in error for rejection in OLD_IDB_REJECTIONS):
        return error
    lines = [line.strip() for line in error.splitlines() if line.strip()]
    error_line = next(
        (line for line in reversed(lines) if any(r in line for r in OLD_IDB_REJECTIONS)),
        error.strip(),
    )
    return f"{error_line} (needs {requirement}: {IDB_UPGRADE_COMMAND})"


def idb_supports_set_value() -> bool:
    """
    Whether this idb has `ui set-value` (idb 1.7+).

    Probed from `--help` rather than a version number: upstream publishes no
    changelog, so the help text is the only reliable record of what a client has.
    """
    return "--value" in _ui_help("set-value")


def run_idb(cmd: list[str]) -> tuple[bool, str]:
    """
    Run an idb command, returning its outcome instead of raising.

    Callers surface the stderr so a failed tap or keystroke says *why* it
    failed (dead companion, unknown button, old idb) rather than just "failed".

    Args:
        cmd: Complete idb command, e.g. from build_idb_command()

    Returns:
        (success, stderr) - stderr is "" on success, or a reason on failure

    Example:
        ok, error = run_idb(["idb", "ui", "tap", "200", "400"])
        if not ok:
            print(f"Failed to tap: {error}", file=sys.stderr)
    """
    try:
        subprocess.run(cmd, capture_output=True, text=True, check=True)
        return (True, "")
    except subprocess.CalledProcessError as e:
        return (False, (e.stderr or "").strip() or f"idb exited with status {e.returncode}")
    except FileNotFoundError:
        return (False, "idb not found on PATH - run scripts/sim_health_check.sh")


def get_accessibility_tree(
    udid: str | None = None, nested: bool = True, api: str | None = None
) -> dict:
    """
    Fetch accessibility tree from IDB.

    The accessibility tree represents the complete UI hierarchy of the current
    screen, with all element properties needed for semantic navigation.

    Args:
        udid: Device UDID (uses booted simulator if None)
        nested: Include nested structure (default True). If False, returns flat array.
        api: idb read backend (`--api`, idb 1.7+). None keeps idb's default, `ax`:
            what VoiceOver sees. "axbridge" walks the app's view hierarchy from
            inside the simulator, so it also sees web content and in-app alerts,
            but returns many unlabelled container views and turns on the device's
            accessibility automation mode, which idb does not restore.

    Returns:
        Root element of accessibility tree as dict.
        Structure: {
            "type": "Window",
            "AXLabel": "App Name",
            "frame": {"x": 0, "y": 0, "width": 390, "height": 844},
            "children": [...]
        }

    Raises:
        SystemExit: If IDB command fails or returns invalid JSON

    Example:
        tree = get_accessibility_tree("UDID123")
        # Root is Window element with all children nested
    """
    cmd = ["idb", "ui", "describe-all", "--json"]
    if nested:
        cmd.append("--nested")
    if api:
        cmd.extend(["--api", api])
    if udid:
        cmd.extend(["--udid", udid])

    # One retry: a read that races a backend starting up (axbridge's in-simulator
    # guest, a fresh companion) can answer with something other than JSON.
    for attempt in range(TREE_READ_ATTEMPTS):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error: Failed to get accessibility tree: {e.stderr}", file=sys.stderr)
            sys.exit(1)
        try:
            tree_data = json.loads(result.stdout)
        except json.JSONDecodeError:
            if attempt + 1 < TREE_READ_ATTEMPTS:
                continue
            output = (result.stdout or result.stderr).strip()[:200] or "(no output)"
            print(
                f"Error: idb returned non-JSON accessibility output: {output}\n"
                "Retry, or run scripts/sim_health_check.sh",
                file=sys.stderr,
            )
            sys.exit(1)

        # IDB returns array format, extract first element (root)
        if isinstance(tree_data, list) and len(tree_data) > 0:
            return tree_data[0]
        return tree_data
    raise AssertionError("unreachable: loop always returns or exits")


def flatten_tree(node: dict, depth: int = 0, elements: list[dict] | None = None) -> list[dict]:
    """
    Flatten nested accessibility tree into list of elements.

    Converts the hierarchical accessibility tree into a flat list where each
    element includes its depth for context.

    Used by:
    - navigator.py - Element finding
    - screen_mapper.py - Element analysis
    - accessibility_audit.py - Audit scanning

    Args:
        node: Root node of tree (typically from get_accessibility_tree)
        depth: Current depth (used internally, start at 0)
        elements: Accumulator list (used internally, start as None)

    Returns:
        Flat list of elements, each with "depth" key indicating nesting level.
        Structure of each element: {
            "type": "Button",
            "AXLabel": "Login",
            "frame": {...},
            "depth": 2,
            ...
        }

    Example:
        tree = get_accessibility_tree()
        flat = flatten_tree(tree)
        for elem in flat:
            print(f"{'  ' * elem['depth']}{elem.get('type')}: {elem.get('AXLabel')}")
    """
    if elements is None:
        elements = []

    # Add current node with depth tracking
    node_copy = node.copy()
    node_copy["depth"] = depth
    elements.append(node_copy)

    # Process children recursively
    for child in node.get("children", []):
        flatten_tree(child, depth + 1, elements)

    return elements


def count_elements(node: dict) -> int:
    """
    Count total elements in tree (recursive).

    Traverses entire tree counting all elements for reporting purposes.

    Used by:
    - test_recorder.py - Element counting per step
    - screen_mapper.py - Summary statistics

    Args:
        node: Root node of tree

    Returns:
        Total element count including root and all descendants

    Example:
        tree = get_accessibility_tree()
        total = count_elements(tree)
        print(f"Screen has {total} elements")
    """
    count = 1
    for child in node.get("children", []):
        count += count_elements(child)
    return count


def get_screen_size(udid: str | None = None) -> tuple[int, int]:
    """
    Get screen dimensions in points, for gesture positioning.

    Delegates to get_device_screen_size(), which falls back to 390x844 when idb
    fails. (get_accessibility_tree() exits the process on failure, so it cannot
    be used where a fallback is wanted.)

    Args:
        udid: Device UDID (uses booted if None)

    Returns:
        (width, height) tuple. Defaults to (390, 844) if detection fails.

    Example:
        width, height = get_screen_size()
        center_x = width // 2
    """
    return get_device_screen_size(udid)


@functools.cache
def _ui_help(command: str) -> str:
    """`idb ui <command> --help` output, or "" when this idb lacks the command."""
    try:
        result = subprocess.run(
            ["idb", "ui", command, "--help"],
            capture_output=True,
            text=True,
            check=False,
            timeout=HELP_PROBE_TIMEOUT_SECONDS,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""
    return result.stdout if result.returncode == 0 else ""
