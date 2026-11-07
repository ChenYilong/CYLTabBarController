#!/usr/bin/env python3
"""
iOS Simulator Navigator - Smart Element Finder and Interactor

Finds and interacts with UI elements using accessibility data.
Prioritizes structured navigation over pixel-based interaction.

This script is the core automation tool for iOS simulator navigation. It finds
UI elements by text, type, or accessibility ID and performs actions on them
(tap, enter text). Uses semantic element finding instead of fragile pixel coordinates.

Key Features:
- Find elements by text (fuzzy or exact matching)
- Find elements by type (Button, TextField, etc.)
- Find elements by accessibility identifier
- Tap elements: an accessibility press for uniquely identified controls, else the center point
- Enter text into text fields (typed, or set directly with --set-value)
- List all tappable elements on screen
- Automatic element caching for performance

Usage Examples:
    # Find and tap a button by text
    python scripts/navigator.py --find-text "Login" --tap --udid <device-id>

    # Enter text into first text field
    python scripts/navigator.py --find-type TextField --index 0 --enter-text "username" --udid <device-id>

    # Replace a field's value without the keyboard (any characters, idb 1.7+)
    python scripts/navigator.py --find-id "cityField" --set-value "Zürich" --udid <device-id>

    # Tap element by accessibility ID
    python scripts/navigator.py --find-id "submitButton" --tap --udid <device-id>

    # Turn a toggle off only if it is on (idempotent; exits 1 without tapping otherwise)
    python scripts/navigator.py --find-id "SmartTyping" --tap --expect 1 --udid <device-id>

    # List all interactive elements
    python scripts/navigator.py --list --udid <device-id>

    # Tap at specific coordinates (fallback)
    python scripts/navigator.py --tap-at 200,400 --udid <device-id>

Output Format:
    Tapped: Button "Login" at (320, 450)
    Entered text in: TextField "Username"
    Not found: text='Submit'

Navigation Priority (best to worst):
    1. Find by accessibility label/text (most reliable)
    2. Find by element type + index (good for forms)
    3. Find by accessibility ID (precise but app-specific)
    4. Tap at coordinates (last resort, fragile)

Technical Details:
- Uses IDB's accessibility tree via `idb ui describe-all --json --nested`
- Caches tree for multiple operations (call with force_refresh to update)
- Finds elements by parsing tree recursively
- Taps a Button/Link/Switch/Tab whose AXUniqueId is unique on screen with an accessibility
  press (`idb ui tap <id> --match-key AXUniqueId --api ax`, idb 1.7+), which reaches it even
  under an overlay; everything else is a coordinate tap at the frame center
- Uses `idb ui text` for typing and `idb ui set-value` for --set-value
- Extracts data from AXLabel, AXValue, and AXUniqueId fields
"""

import argparse
import sys
import time
from dataclasses import dataclass

from common import (
    IDB_UPGRADE_COMMAND,
    build_idb_command,
    get_accessibility_tree,
    get_device_screen_size,
    idb_supports_set_value,
    resolve_udid,
    run_idb,
    transform_screenshot_coords,
)
from common.env_config import env_float, env_int

MAX_ELEMENTS_LISTED = env_int("IOS_SIM_MAX_ELEMENTS", 25)
TAP_SETTLE_SECONDS = env_float("IOS_SIM_TAP_SETTLE_MS", 500.0) / 1000.0

# Leaf controls an agent means when it says "tap X"; ranked above containers
# (Application, Window, Group) that often carry the same label.
INTERACTIVE_TYPES = {
    "Button",
    "Link",
    "Cell",
    "TextField",
    "SecureTextField",
    "SearchField",
    "Switch",
    "CheckBox",  # iOS 27 reports toggles as CheckBox with a Toggle trait, not Switch
    "Slider",
    "Tab",
}

# Controls whose accessibility press does what a finger tap does. Text fields are
# excluded: a press doesn't give them keyboard focus, which typing needs.
PRESSABLE_TYPES = {"Button", "Link", "Switch", "CheckBox", "Tab"}
TOGGLE_TYPES = {"Switch", "CheckBox"}
SECURE_TYPES = {"SecureTextField"}

VALUE_READ_BACK_ATTEMPTS = 3
VALUE_READ_BACK_DELAY_SECONDS = 0.3

# After an app relaunch the default read can return only a zero-size app node
# (facebook/idb#964); one axbridge read (screen_mapper.py --deep) brings it back.
STUCK_TREE_HINT = (
    "Not found: accessibility tree is empty (app launching?) - "
    "retry, or run screen_mapper.py --deep once"
)


@dataclass
class Element:
    """Represents a UI element from accessibility tree."""

    type: str
    label: str | None
    value: str | None
    identifier: str | None
    frame: dict[str, float]
    traits: list[str]
    enabled: bool = True

    @property
    def center(self) -> tuple[int, int]:
        """Calculate center point for tapping."""
        x = int(self.frame["x"] + self.frame["width"] / 2)
        y = int(self.frame["y"] + self.frame["height"] / 2)
        return (x, y)

    @property
    def description(self) -> str:
        """Human-readable description."""
        label = self.label or self.value or self.identifier or "Unnamed"
        return f'{self.type} "{label}"'


class Navigator:
    """Navigates iOS apps using accessibility data."""

    def __init__(self, udid: str | None = None):
        """Initialize navigator with optional device UDID."""
        self.udid = udid
        self._tree_cache = None
        self.last_error = ""
        self.last_tap_was_press = False

    def get_accessibility_tree(self, force_refresh: bool = False) -> dict:
        """Get accessibility tree (cached for efficiency)."""
        if self._tree_cache and not force_refresh:
            return self._tree_cache

        # Delegate to shared utility
        self._tree_cache = get_accessibility_tree(self.udid, nested=True)
        return self._tree_cache

    def _flatten_tree(self, node: dict, elements: list[Element] | None = None) -> list[Element]:
        """Flatten accessibility tree into list of elements."""
        if elements is None:
            elements = []

        # Create element from node
        if node.get("type"):
            element = Element(
                type=node.get("type", "Unknown"),
                label=node.get("AXLabel"),
                # Sliders and steppers report AXValue as a number; the rest of the script expects text.
                value=None if node.get("AXValue") is None else str(node.get("AXValue")),
                identifier=node.get("AXUniqueId"),
                frame=node.get("frame", {}),
                traits=node.get("traits", []),
                enabled=node.get("enabled", True),
            )
            elements.append(element)

        # Process children
        for child in node.get("children", []):
            self._flatten_tree(child, elements)

        return elements

    def list_elements(self, force_refresh: bool = False) -> list[Element]:
        """Get flat list of all UI elements on current screen."""
        tree = self.get_accessibility_tree(force_refresh)
        return self._flatten_tree(tree)

    def find_element(
        self,
        text: str | None = None,
        element_type: str | None = None,
        identifier: str | None = None,
        index: int = 0,
        fuzzy: bool = True,
    ) -> Element | None:
        """
        Find element by various criteria.

        Args:
            text: Text to search in label/value
            element_type: Type of element (Button, TextField, etc.)
            identifier: Accessibility identifier
            index: Which matching element to return (0-based)
            fuzzy: Use fuzzy matching for text

        Returns:
            Element if found, None otherwise
        """
        tree = self.get_accessibility_tree()
        elements = self._flatten_tree(tree)

        matches = []

        for elem in elements:
            # Skip disabled elements
            if not elem.enabled:
                continue

            # Check type
            if element_type and elem.type != element_type:
                continue

            # Check identifier (exact match)
            if identifier and elem.identifier != identifier:
                continue

            # Check text (in label or value)
            if text:
                elem_text = (elem.label or "") + " " + (elem.value or "")
                if fuzzy:
                    if text.lower() not in elem_text.lower():
                        continue
                elif text not in (elem.label, elem.value):
                    continue

            matches.append(elem)

        # Only text searches have ambiguous matches worth ranking; type/id-only
        # searches keep tree (screen) order so --index means "Nth on screen".
        if text:
            matches.sort(key=lambda elem: rank_match(elem, text))
        if matches and index < len(matches):
            return matches[index]

        return None

    def tap(self, element: Element) -> bool:
        """
        Tap an element, by accessibility press when it can be addressed unambiguously.

        A press acts on the element itself, so an overlay covering its center (a
        floating search bar, a toolbar) can't steal the tap, and it is the only way
        to flip an iOS 27 toggle: HID touches on a UISwitch don't. If the press fails -
        including on idb before 1.7, which rejects a marker argument - falls back
        to a coordinate tap. Sets last_tap_was_press for reporting.
        """
        marker = self._unique_marker(element)
        self.last_tap_was_press = (
            element.type in PRESSABLE_TYPES
            and marker is not None
            and self._run_marker("ui tap", marker)
        )
        if self.last_tap_was_press:
            return True
        x, y = element.center
        return self.tap_at(x, y)

    def tap_at(self, x: int, y: int) -> bool:
        """Tap at specific coordinates."""
        ok, self.last_error = run_idb(build_idb_command("ui tap", self.udid, x, y))
        return ok

    def enter_text(self, text: str, element: Element | None = None) -> bool:
        """
        Enter text into element or current focus.

        Args:
            text: Text to enter
            element: Optional element to tap first

        Returns:
            Success status
        """
        # Tap element if provided
        if element:
            if not self.tap(element):
                return False
            # Let focus move to the field before typing
            time.sleep(TAP_SETTLE_SECONDS)

        ok, self.last_error = run_idb(build_idb_command("ui text", self.udid, text))
        return ok

    def set_value(self, text: str, element: Element) -> bool:
        """
        Replace an element's value via accessibility, without the keyboard.

        Unlike enter_text this accepts any characters and replaces existing text,
        but focus doesn't move, so a following Return key won't reach the field.
        idb can report success for a value the app then discards, so the value is
        read back before success is claimed (secure fields read back masked, so
        they aren't checked).
        """
        if not idb_supports_set_value():
            self.last_error = f"--set-value needs idb 1.7+: {IDB_UPGRADE_COMMAND}"
            return False
        marker = self._unique_marker(element)
        if marker:
            ok = self._run_marker("ui set-value", marker, "--value", text)
        else:
            x, y = element.center
            ok, self.last_error = run_idb(
                build_idb_command("ui set-value", self.udid, x, y, "--value", text, "--api", "ax")
            )
        if not ok or element.type in SECURE_TYPES:
            return ok
        return self._value_reads_back(element, text)

    def _value_reads_back(self, element: Element, expected: str) -> bool:
        """Re-read the screen until element shows expected; on mismatch, say what it shows."""
        actual = None
        for _ in range(VALUE_READ_BACK_ATTEMPTS):
            time.sleep(VALUE_READ_BACK_DELAY_SECONDS)
            self.get_accessibility_tree(force_refresh=True)
            # A set field can move and lose its placeholder label, so the value is the
            # reliable signal: any same-type element (same id, if it has one) holding it.
            candidates = [
                e
                for e in self.list_elements()
                if e.type == element.type
                and (not element.identifier or e.identifier == element.identifier)
            ]
            if any(e.value == expected for e in candidates):
                return True
            same = next((e for e in candidates if _is_same_element(e, element)), None)
            actual = same.value if same else None
        self.last_error = (
            f"value didn't stick (reads {actual!r}) - retry, or use --enter-text to type it"
        )
        return False

    def _unique_marker(self, element: Element) -> tuple[str, str] | None:
        """
        An idb (marker, match key) that addresses only this element, or None.

        idb matches markers as substrings and silently acts on the first hit, so a
        marker qualifies only when no other element's value for that key contains
        it. Tries the identifier, then the label. Counts every node, typed or not,
        because idb's search does.
        """
        nodes = list(_iter_nodes(self.get_accessibility_tree()))
        for match_key, marker in (("AXUniqueId", element.identifier), ("AXLabel", element.label)):
            if not marker or marker.startswith("-"):
                continue
            holders = [node for node in nodes if marker in (node.get(match_key) or "")]
            if len(holders) == 1:
                return (marker, match_key)
        return None

    def _run_marker(self, operation: str, marker: tuple[str, str], *args: str) -> bool:
        """Run an idb marker action, via the same backend reads use."""
        value, match_key = marker
        ok, self.last_error = run_idb(
            build_idb_command(
                operation, self.udid, value, "--match-key", match_key, "--api", "ax", *args
            )
        )
        return ok

    def find_and_tap(
        self,
        text: str | None = None,
        element_type: str | None = None,
        identifier: str | None = None,
        index: int = 0,
        fuzzy: bool = True,
        expected_value: str | None = None,
    ) -> tuple[bool, str]:
        """
        Find element and tap it.

        Args:
            expected_value: Tap only if the element's AXValue equals this (e.g. "1" for a
                toggle that is on), making "turn X off" safe to repeat

        Returns:
            (success, message) tuple
        """
        element = self.find_element(text, element_type, identifier, index, fuzzy)

        if not element:
            criteria = []
            if text:
                criteria.append(f"text='{text}'")
            if element_type:
                criteria.append(f"type={element_type}")
            if identifier:
                criteria.append(f"id={identifier}")
            if is_stuck_tree(self.get_accessibility_tree()):
                return (False, STUCK_TREE_HINT)
            return (False, f"Not found: {', '.join(criteria)}")

        if expected_value is not None and element.value != expected_value:
            return (
                False,
                f"Not tapped: {element.description} has value {element.value!r}, "
                f"expected {expected_value!r}",
            )

        if self.tap(element):
            if self.last_tap_was_press:
                return (True, f"Tapped: {element.description} (accessibility press)")
            message = f"Tapped: {element.description} at {element.center}"
            if element.type in TOGGLE_TYPES:
                message += " - toggles ignore coordinate taps on iOS 27; check its value"
            return (True, message)
        return (False, f"Failed to tap: {element.description}: {self.last_error}")

    def find_and_enter_text(
        self,
        text_to_enter: str,
        find_text: str | None = None,
        element_type: str | None = "TextField",
        identifier: str | None = None,
        index: int = 0,
        fuzzy: bool = True,
        replace: bool = False,
    ) -> tuple[bool, str]:
        """
        Find element and enter text into it.

        Args:
            replace: Set the value via accessibility (set_value) instead of typing

        Returns:
            (success, message) tuple
        """
        element = self.find_element(find_text, element_type, identifier, index, fuzzy)

        if not element:
            if is_stuck_tree(self.get_accessibility_tree()):
                return (False, STUCK_TREE_HINT)
            return (False, f"{element_type or 'Element'} not found")

        if replace:
            if self.set_value(text_to_enter, element):
                return (True, f"Set value of: {element.description}")
            return (False, f"Failed to set value of {element.description}: {self.last_error}")

        if self.enter_text(text_to_enter, element):
            return (True, f"Entered text in: {element.description}")
        return (False, f"Failed to enter text in {element.description}: {self.last_error}")


def _is_same_element(candidate: Element, original: Element) -> bool:
    """
    Best guess at which re-read element is the one acted on, to report its value.

    Matches on identifier, else type and label, and only then frame: fields move
    once edited (Settings' search bar jumps up the screen when it activates).
    """
    if original.identifier:
        return candidate.identifier == original.identifier
    if original.label:
        return candidate.type == original.type and candidate.label == original.label
    return candidate.type == original.type and candidate.frame == original.frame


def _iter_nodes(node: dict):
    """Yield node and every node below it, depth-first."""
    yield node
    for child in node.get("children", []):
        yield from _iter_nodes(child)


def is_stuck_tree(tree: dict) -> bool:
    """Whether a read returned only a childless, zero-size root (nothing on screen to find)."""
    frame = tree.get("frame") or {}
    has_no_area = not frame.get("width") or not frame.get("height")
    return not tree.get("children") and has_no_area


def rank_match(element: Element, text: str) -> tuple[int, int]:
    """
    Sort key putting the element an agent most likely means first.

    Order: exact label/value match (case-insensitive), then interactive leaf
    types - so a Button beats the Window or Group sharing its label. The sort
    is stable, so ties keep screen order.
    """
    wanted = text.lower()
    is_exact = wanted in ((element.label or "").lower(), (element.value or "").lower())
    is_interactive = element.type in INTERACTIVE_TYPES
    return (0 if is_exact else 1, 0 if is_interactive else 1)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Navigate iOS apps using accessibility data")

    # Finding options
    parser.add_argument("--find-text", help="Find element by text (fuzzy match)")
    parser.add_argument("--find-exact", help="Find element by exact text")
    parser.add_argument("--find-type", help="Element type (Button, TextField, etc.)")
    parser.add_argument("--find-id", help="Accessibility identifier")
    parser.add_argument("--index", type=int, default=0, help="Which match to use (0-based)")

    # Action options
    parser.add_argument("--tap", action="store_true", help="Tap the found element")
    parser.add_argument("--tap-at", help="Tap at coordinates (x,y)")
    parser.add_argument(
        "--expect",
        metavar="VALUE",
        help="With --tap: only tap if the element's value equals VALUE (toggles: 1 on, 0 off)",
    )
    parser.add_argument("--enter-text", help="Tap element, then type text (ASCII)")
    parser.add_argument(
        "--set-value",
        help="Replace element's value without the keyboard (any characters; idb 1.7+). "
        "Focus doesn't move, so a following Return key won't submit",
    )

    # Coordinate transformation
    parser.add_argument(
        "--screenshot-coords",
        action="store_true",
        help="Interpret tap coordinates as from a screenshot (requires --screenshot-width/height)",
    )
    parser.add_argument(
        "--screenshot-width",
        type=int,
        help="Screenshot width for coordinate transformation",
    )
    parser.add_argument(
        "--screenshot-height",
        type=int,
        help="Screenshot height for coordinate transformation",
    )

    # Other options
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )
    parser.add_argument("--list", action="store_true", help="List all tappable elements")

    args = parser.parse_args()

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)

    if args.expect is not None and not args.tap:
        print("Error: --expect requires --tap")
        sys.exit(1)

    navigator = Navigator(udid=udid)

    # List mode
    if args.list:
        elements = navigator.list_elements()

        # Filter to tappable elements
        tappable = [e for e in elements if e.enabled and e.type in INTERACTIVE_TYPES]

        print(f"Tappable elements ({len(tappable)}):")
        for elem in tappable[:MAX_ELEMENTS_LISTED]:
            print(f"  {elem.type}: \"{elem.label or elem.value or 'Unnamed'}\" {elem.center}")

        if len(tappable) > MAX_ELEMENTS_LISTED:
            print(f"  ... and {len(tappable) - MAX_ELEMENTS_LISTED} more")
        sys.exit(0)

    # Direct tap at coordinates
    if args.tap_at:
        coords = args.tap_at.split(",")
        if len(coords) != 2:
            print("Error: --tap-at requires x,y format")
            sys.exit(1)

        x, y = int(coords[0]), int(coords[1])

        # Handle coordinate transformation if requested
        if args.screenshot_coords:
            if not args.screenshot_width or not args.screenshot_height:
                print(
                    "Error: --screenshot-coords requires --screenshot-width and --screenshot-height"
                )
                sys.exit(1)

            device_w, device_h = get_device_screen_size(udid)
            x, y = transform_screenshot_coords(
                x,
                y,
                args.screenshot_width,
                args.screenshot_height,
                device_w,
                device_h,
            )
            print(
                f"Transformed screenshot coords ({coords[0]}, {coords[1]}) "
                f"to device coords ({x}, {y})"
            )

        if navigator.tap_at(x, y):
            print(f"Tapped at ({x}, {y})")
        else:
            print(f"Failed to tap at ({x}, {y}): {navigator.last_error}", file=sys.stderr)
            sys.exit(1)

    # Find and tap
    elif args.tap:
        text = args.find_text or args.find_exact
        fuzzy = args.find_text is not None

        success, message = navigator.find_and_tap(
            text=text,
            element_type=args.find_type,
            identifier=args.find_id,
            index=args.index,
            fuzzy=fuzzy,
            expected_value=args.expect,
        )

        print(message)
        if not success:
            sys.exit(1)

    # Find and enter text
    elif args.enter_text or args.set_value is not None:
        text = args.find_text or args.find_exact
        fuzzy = args.find_text is not None
        replace = args.set_value is not None

        success, message = navigator.find_and_enter_text(
            text_to_enter=args.set_value if replace else args.enter_text,
            find_text=text,
            element_type=args.find_type or "TextField",
            identifier=args.find_id,
            index=args.index,
            fuzzy=fuzzy,
            replace=replace,
        )

        print(message)
        if not success:
            sys.exit(1)

    # Just find (no action)
    else:
        text = args.find_text or args.find_exact
        fuzzy = args.find_text is not None

        element = navigator.find_element(
            text=text,
            element_type=args.find_type,
            identifier=args.find_id,
            index=args.index,
            fuzzy=fuzzy,
        )

        if element:
            print(f"Found: {element.description} at {element.center}")
        else:
            stuck = is_stuck_tree(navigator.get_accessibility_tree())
            print(STUCK_TREE_HINT if stuck else "Element not found")
            sys.exit(1)


if __name__ == "__main__":
    main()
