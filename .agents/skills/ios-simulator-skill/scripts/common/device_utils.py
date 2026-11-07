#!/usr/bin/env python3
"""
Shared device and simulator utilities.

Common patterns for interacting with simulators via xcrun simctl and IDB.
Standardizes command building and device targeting to prevent errors.

Follows Jackson's Law - only extracts genuinely reused patterns.

Used by:
- app_launcher.py (8 call sites) - App lifecycle commands
- Multiple scripts (15+ locations) - IDB command building
- navigator.py, gesture.py - Coordinate transformation
- test_recorder.py, app_state_capture.py - Auto-UDID detection
"""

import json
import re
import subprocess
import sys


def build_simctl_command(
    operation: str,
    udid: str | None = None,
    *args,
) -> list[str]:
    """
    Build xcrun simctl command with proper device handling.

    Standardizes command building to prevent device targeting bugs.
    Automatically uses "booted" if no UDID provided.

    Used by:
    - app_launcher.py: launch, terminate, install, uninstall, openurl, listapps, spawn
    - Multiple scripts: generic simctl operations

    Args:
        operation: simctl operation (launch, terminate, install, etc.)
        udid: Device UDID (uses 'booted' if None)
        *args: Additional command arguments

    Returns:
        Complete command list ready for subprocess.run()

    Examples:
        # Launch app on booted simulator
        cmd = build_simctl_command("launch", None, "com.app.bundle")
        # Returns: ["xcrun", "simctl", "launch", "booted", "com.app.bundle"]

        # Launch on specific device
        cmd = build_simctl_command("launch", "ABC123", "com.app.bundle")
        # Returns: ["xcrun", "simctl", "launch", "ABC123", "com.app.bundle"]

        # Install app on specific device
        cmd = build_simctl_command("install", "ABC123", "/path/to/app.app")
        # Returns: ["xcrun", "simctl", "install", "ABC123", "/path/to/app.app"]
    """
    cmd = ["xcrun", "simctl", operation]

    # Add device (booted or specific UDID)
    cmd.append(udid if udid else "booted")

    # Add remaining arguments
    cmd.extend(str(arg) for arg in args)

    return cmd


def refuse_without_yes(action: str) -> str:
    """
    One-line refusal for a destructive action the user hasn't confirmed.

    Agents have no one to answer an interactive prompt, so destructive scripts
    refuse instead and the agent asks the user (AGENTS.md Principle 10).

    Example:
        refuse_without_yes("erase iPhone 18 Pro")
        # "Refusing to erase iPhone 18 Pro without --yes: confirm with the user, ..."
    """
    return f"Refusing to {action} without --yes: confirm with the user, then re-run with --yes"


def build_idb_command(
    operation: str,
    udid: str | None = None,
    *args,
) -> list[str]:
    """
    Build IDB command with proper device targeting.

    Standardizes IDB command building across all scripts using IDB.
    Handles device UDID consistently.

    Used by:
    - navigator.py: ui tap, ui text, ui describe-all
    - gesture.py: ui swipe, ui tap
    - keyboard.py: ui key, ui text, ui tap
    - And more: 15+ locations

    Args:
        operation: IDB operation path (e.g., "ui tap", "ui text", "ui describe-all")
        udid: Device UDID (omits --udid flag if None, IDB uses booted by default)
        *args: Additional command arguments

    Returns:
        Complete command list ready for subprocess.run()

    Examples:
        # Tap on booted simulator
        cmd = build_idb_command("ui tap", None, "200", "400")
        # Returns: ["idb", "ui", "tap", "200", "400"]

        # Tap on specific device
        cmd = build_idb_command("ui tap", "ABC123", "200", "400")
        # Returns: ["idb", "ui", "tap", "200", "400", "--udid", "ABC123"]

        # Get accessibility tree
        cmd = build_idb_command("ui describe-all", "ABC123", "--json", "--nested")
        # Returns: ["idb", "ui", "describe-all", "--json", "--nested", "--udid", "ABC123"]

        # Enter text
        cmd = build_idb_command("ui text", None, "hello world")
        # Returns: ["idb", "ui", "text", "hello world"]
    """
    # Split operation into parts (e.g., "ui tap" -> ["ui", "tap"])
    cmd = ["idb"] + operation.split()

    # Add arguments
    cmd.extend(str(arg) for arg in args)

    # Add device targeting if specified (optional for IDB, uses booted by default)
    if udid:
        cmd.extend(["--udid", udid])

    return cmd


def get_booted_device_udids() -> list[str]:
    """
    List the UDIDs of every currently booted simulator.

    Queries `xcrun simctl list devices booted` and extracts each UDID in the
    order reported.

    Returns:
        UDIDs of all booted simulators, or an empty list if none are booted
        (or the query fails).

    Example:
        udids = get_booted_device_udids()
        # ["ABC123-...", "DEF456-..."] when two simulators are running
    """
    try:
        result = subprocess.run(
            ["xcrun", "simctl", "list", "devices", "booted"],
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError:
        return []

    # Format: "  iPhone 16 Pro (ABC123-DEF456) (Booted)"
    udids: list[str] = []
    for line in result.stdout.split("\n"):
        match = re.search(r"\(([A-F0-9\-]{36})\)", line)
        if match:
            udids.append(match.group(1))
    return udids


def get_booted_device_udid() -> str | None:
    """
    Auto-detect a booted simulator UDID.

    Returns the first booted simulator. When more than one simulator is booted
    the choice is ambiguous — gesture/tap commands can silently target a device
    other than the one you are watching (idb reports success on the wrong
    device, so nothing appears to happen). In that case a warning is printed to
    stderr naming the selected device and advising an explicit ``--udid``.

    Returns:
        UDID of a booted simulator, or None if no simulator is booted.

    Example:
        udid = get_booted_device_udid()
        if udid:
            print(f"Booted simulator: {udid}")
        else:
            print("No simulator is currently booted")
    """
    udids = get_booted_device_udids()
    if not udids:
        return None
    if len(udids) > 1:
        print(
            f"Warning: {len(udids)} booted simulators detected ({', '.join(udids)}). "
            f"Auto-selecting {udids[0]} — pass --udid to target a specific device.",
            file=sys.stderr,
        )
    return udids[0]


def resolve_udid(udid_arg: str | None) -> str:
    """
    Resolve device UDID with auto-detection fallback.

    If udid_arg is provided, returns it immediately.
    If None, attempts to auto-detect booted simulator.
    Raises error if neither is available.

    Args:
        udid_arg: Explicit UDID from command line, or None

    Returns:
        Valid UDID string

    Raises:
        RuntimeError: If no UDID provided and no booted simulator found

    Example:
        try:
            udid = resolve_udid(args.udid)  # args.udid might be None
            print(f"Using device: {udid}")
        except RuntimeError as e:
            print(f"Error: {e}")
            sys.exit(1)
    """
    if udid_arg:
        return udid_arg

    booted_udid = get_booted_device_udid()
    if booted_udid:
        return booted_udid

    raise RuntimeError(
        "No device UDID provided and no simulator is currently booted.\n"
        "Boot a simulator or provide --udid explicitly:\n"
        "  xcrun simctl boot <device-name>\n"
        "  python scripts/script_name.py --udid <device-udid>"
    )


def get_device_screen_size(udid: str | None) -> tuple[int, int]:
    """
    Get the device's screen size in points, as reported by `idb describe`.

    Uses the target description rather than the accessibility tree: the tree's
    root is the frontmost app, whose frame is 0x0 while it launches. Every idb
    client reports screen_dimensions, so this needs no version check.
    Falls back to iPhone 14 defaults (390x844) if detection fails.

    Args:
        udid: Device UDID

    Returns:
        Tuple of (width, height) in points

    Example:
        width, height = get_device_screen_size("ABC123")
        print(f"Device screen: {width}x{height}")
    """
    try:
        cmd = build_idb_command("describe", udid, "--json")
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        dimensions = json.loads(result.stdout)["screen_dimensions"]
        width = int(dimensions["width_points"])
        height = int(dimensions["height_points"])
    except Exception:
        # Graceful fallback to iPhone 14 Pro defaults
        return (390, 844)
    if width <= 0 or height <= 0:
        return (390, 844)
    return (width, height)


def resolve_device_identifier(identifier: str) -> str:
    """
    Resolve device name or partial UDID to full UDID.

    Supports multiple identifier formats:
    - Full UDID: "ABC-123-DEF456..." (36 character UUID)
    - Device name: "iPhone 16 Pro" (matches full name)
    - Partial match: "iPhone 16" (matches first device containing this string)
    - Special: "booted" (resolves to currently booted device)

    Args:
        identifier: Device UDID, name, or special value "booted"

    Returns:
        Full device UDID

    Raises:
        RuntimeError: If identifier cannot be resolved

    Example:
        udid = resolve_device_identifier("iPhone 16 Pro")
        # Returns: "ABC123DEF456..."

        udid = resolve_device_identifier("booted")
        # Returns UDID of booted simulator
    """
    # Handle "booted" special case
    if identifier.lower() == "booted":
        booted = get_booted_device_udid()
        if booted:
            return booted
        raise RuntimeError(
            "No simulator is currently booted. "
            "Boot a simulator first: xcrun simctl boot <device-udid>"
        )

    # Check if already a full UDID (36 character UUID format)
    if re.match(r"^[A-F0-9\-]{36}$", identifier, re.IGNORECASE):
        return identifier.upper()

    # Try to match by device name
    simulators = list_simulators(state=None)
    exact_matches = [s for s in simulators if s["name"].lower() == identifier.lower()]
    if exact_matches:
        return exact_matches[0]["udid"]

    # Try partial match
    partial_matches = [s for s in simulators if identifier.lower() in s["name"].lower()]
    if partial_matches:
        return partial_matches[0]["udid"]

    # No match found
    raise RuntimeError(
        f"Device '{identifier}' not found. "
        f"Use 'xcrun simctl list devices' to see available simulators."
    )


def list_simulators(state: str | None = None) -> list[dict]:
    """
    List iOS simulators with optional state filtering.

    Queries xcrun simctl and returns structured list of simulators.
    Optionally filters by state (available, booted, all).

    Args:
        state: Optional filter - "available", "booted", or None for all

    Returns:
        List of simulator dicts with keys:
        - "name": Device name (e.g., "iPhone 16 Pro")
        - "udid": Device UDID (36 char UUID)
        - "state": Device state ("Booted", "Shutdown", "Unavailable")
        - "runtime": iOS version (e.g., "iOS 18.0", "unavailable")
        - "type": Device type ("iPhone", "iPad", "Apple Watch", etc.)

    Example:
        # List all simulators
        all_sims = list_simulators()
        print(f"Total simulators: {len(all_sims)}")

        # List only available simulators
        available = list_simulators(state="available")
        for sim in available:
            print(f"{sim['name']} ({sim['state']}) - {sim['udid']}")

        # List only booted simulators
        booted = list_simulators(state="booted")
        for sim in booted:
            print(f"Booted: {sim['name']}")
    """
    try:
        # Query simctl for device list
        cmd = ["xcrun", "simctl", "list", "devices", "-j"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        data = json.loads(result.stdout)
        simulators = []

        # Parse JSON response
        # Format: {"devices": {"iOS 18.0": [{...}, {...}], "iOS 17.0": [...], ...}}
        for ios_version, devices in data.get("devices", {}).items():
            for device in devices:
                sim = {
                    "name": device.get("name", "Unknown"),
                    "udid": device.get("udid", ""),
                    "state": device.get("state", "Unknown"),
                    "runtime": ios_version,
                    "type": _extract_device_type(device.get("name", "")),
                }
                simulators.append(sim)

        # Apply state filtering
        if state == "booted":
            return [s for s in simulators if s["state"] == "Booted"]
        if state == "available":
            return [s for s in simulators if s["state"] == "Shutdown"]  # Available to boot
        if state is None:
            return simulators
        return [s for s in simulators if s["state"].lower() == state.lower()]

    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError) as e:
        raise RuntimeError(f"Failed to list simulators: {e}") from e


def _extract_device_type(device_name: str) -> str:
    """
    Extract device type from device name.

    Parses device name to determine type (iPhone, iPad, Watch, etc.).

    Args:
        device_name: Full device name (e.g., "iPhone 16 Pro")

    Returns:
        Device type string

    Example:
        _extract_device_type("iPhone 16 Pro")  # Returns "iPhone"
        _extract_device_type("iPad Air")        # Returns "iPad"
        _extract_device_type("Apple Watch Series 9") # Returns "Watch"
    """
    if "iPhone" in device_name:
        return "iPhone"
    if "iPad" in device_name:
        return "iPad"
    if "Watch" in device_name or "Apple Watch" in device_name:
        return "Watch"
    if "TV" in device_name or "Apple TV" in device_name:
        return "TV"
    return "Unknown"


def transform_screenshot_coords(
    x: float,
    y: float,
    screenshot_width: int,
    screenshot_height: int,
    device_width: int,
    device_height: int,
) -> tuple[int, int]:
    """
    Transform screenshot coordinates to device coordinates.

    Handles the case where a screenshot was downscaled (e.g., to 'half' size)
    and needs to be transformed back to actual device pixel coordinates
    for accurate tapping.

    The transformation is linear:
    device_x = (screenshot_x / screenshot_width) * device_width
    device_y = (screenshot_y / screenshot_height) * device_height

    Args:
        x, y: Coordinates in the screenshot
        screenshot_width, screenshot_height: Screenshot dimensions (e.g., 195, 422)
        device_width, device_height: Actual device dimensions (e.g., 390, 844)

    Returns:
        Tuple of (device_x, device_y) in device pixels

    Example:
        # Screenshot taken at 'half' size: 195x422 (from 390x844 device)
        device_x, device_y = transform_screenshot_coords(
            100, 200,  # Tap point in screenshot
            195, 422,  # Screenshot dimensions
            390, 844   # Device dimensions
        )
        print(f"Tap at device coords: ({device_x}, {device_y})")
        # Output: Tap at device coords: (200, 400)
    """
    device_x = int((x / screenshot_width) * device_width)
    device_y = int((y / screenshot_height) * device_height)
    return (device_x, device_y)
