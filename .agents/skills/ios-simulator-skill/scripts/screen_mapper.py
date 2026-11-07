#!/usr/bin/env python3
"""
iOS Screen Mapper - Current Screen Analyzer

Maps the current screen's UI elements for navigation decisions.
Provides token-efficient summaries of available interactions.

This script analyzes the iOS simulator screen using IDB's accessibility tree
and provides a compact, actionable summary of what's currently visible and
interactive on the screen. Perfect for AI agents making navigation decisions.

Key Features:
- Token-efficient output (5-7 lines by default)
- Identifies buttons, text fields, navigation elements
- Counts interactive and focusable elements
- Progressive detail with --verbose flag
- Navigation hints with --hints flag
- --deep reads through idb's axbridge backend (idb 1.7+) to reach web content and
  in-app alerts the default backend can't see

Usage Examples:
    # Quick summary (default)
    python scripts/screen_mapper.py --udid <device-id>

    # Detailed element breakdown
    python scripts/screen_mapper.py --udid <device-id> --verbose

    # Include navigation suggestions
    python scripts/screen_mapper.py --udid <device-id> --hints

    # Full JSON output for parsing
    python scripts/screen_mapper.py --udid <device-id> --json

    # Include web views and in-app alerts (slower, noisier)
    python scripts/screen_mapper.py --udid <device-id> --deep

Output Format (default):
    Screen: LoginViewController (45 elements, 7 interactive)
    Buttons: "Login", "Cancel", "Forgot Password"
    TextFields: 2 (0 filled)
    Navigation: NavBar: "Sign In"
    Focusable: 7 elements

Technical Details:
- Uses IDB's accessibility tree via `idb ui describe-all --json --nested`
- Parses IDB's array format: [{ root element with children }]
- Identifies element types: Button, TextField, NavigationBar, TabBar, etc.
- Extracts labels from AXLabel, AXValue, and AXUniqueId fields
- Reports how much of the screen labelled elements cover; a near-empty screen
  usually means content the default backend can't see (Safari/WKWebView pages,
  web alerts), and the summary suggests --deep
"""

import argparse
import json
import subprocess
import sys
from collections import defaultdict

from common import get_accessibility_tree, resolve_udid
from common.env_config import env_int

BUTTONS_PREVIEW = env_int("IOS_SIM_SCREEN_BUTTONS_PREVIEW", 15)
SECTION_ITEMS_PREVIEW = env_int("IOS_SIM_SCREEN_SECTION_ITEMS", 10)

# Below this, the default backend is probably missing content (measured: a Safari
# page 0.03, Settings 0.68, Maps 1.0), so the summary suggests --deep.
LOW_COVERAGE_RATIO = 0.10
COVERAGE_GRID_POINTS = 8
DEEP_API = "axbridge"


class ScreenMapper:
    """
    Analyzes current screen for navigation decisions.

    This class fetches the iOS accessibility tree from IDB and analyzes it
    to provide actionable summaries for navigation. It categorizes elements
    by type, counts interactive elements, and identifies key UI patterns.

    Attributes:
        udid (Optional[str]): Device UDID to target, or None for booted device
        INTERACTIVE_TYPES (Set[str]): Element types that users can interact with

    Design Philosophy:
        - Token efficiency: Provide minimal but complete information
        - Progressive disclosure: Summary by default, details on request
        - Navigation-focused: Highlight elements relevant for automation
    """

    # Element types we care about for navigation
    # These are the accessibility element types that indicate user interaction points
    INTERACTIVE_TYPES = {
        "Button",
        "Link",
        "TextField",
        "SecureTextField",
        "Cell",
        "Switch",
        "Slider",
        "Stepper",
        "SegmentedControl",
        "TabBar",
        "NavigationBar",
        "Toolbar",
    }

    def __init__(self, udid: str | None = None, deep: bool = False):
        """
        Initialize screen mapper.

        Args:
            udid: Optional device UDID. If None, uses booted simulator.
            deep: Read through idb's axbridge backend (see get_accessibility_tree)

        Example:
            mapper = ScreenMapper(udid="656DC652-1C9F-4AB2-AD4F-F38E65976BDA")
            mapper = ScreenMapper()  # Uses booted device
        """
        self.udid = udid
        self.deep = deep

    def get_accessibility_tree(self) -> dict:
        """
        Fetch accessibility tree from iOS simulator via IDB.

        Delegates to shared utility for consistent tree fetching across all scripts.
        """
        return get_accessibility_tree(self.udid, nested=True, api=DEEP_API if self.deep else None)

    def analyze_tree(self, node: dict, depth: int = 0) -> dict:
        """Analyze accessibility tree for navigation info."""
        analysis = {
            "elements_by_type": defaultdict(list),
            "total_elements": 0,
            "interactive_elements": 0,
            "text_fields": [],
            "buttons": [],
            "navigation": {},
            "screen_name": None,
            "focusable": 0,
        }

        self._analyze_recursive(node, analysis, depth)

        # Post-process for clean output
        analysis["elements_by_type"] = dict(analysis["elements_by_type"])
        analysis["screen_coverage"] = round(labelled_leaf_coverage(node), 2)

        return analysis

    def _analyze_recursive(self, node: dict, analysis: dict, depth: int):
        """Recursively analyze tree nodes."""
        elem_type = node.get("type")
        label = node.get("AXLabel", "")
        value = node.get("AXValue", "")
        identifier = node.get("AXUniqueId", "")

        # Count element
        if elem_type:
            analysis["total_elements"] += 1

            # Track by type
            if elem_type in self.INTERACTIVE_TYPES:
                analysis["interactive_elements"] += 1

                # Store concise info (label only, not full node)
                elem_info = label or value or identifier or "Unnamed"
                analysis["elements_by_type"][elem_type].append(elem_info)

                # Special handling for common types
                if elem_type == "Button":
                    analysis["buttons"].append(elem_info)
                elif elem_type in ("TextField", "SecureTextField"):
                    analysis["text_fields"].append(
                        {"type": elem_type, "label": elem_info, "has_value": bool(value)}
                    )
                elif elem_type == "NavigationBar":
                    analysis["navigation"]["nav_title"] = label or "Navigation"
                elif elem_type == "TabBar":
                    # Count tab items
                    tab_count = len(node.get("children", []))
                    analysis["navigation"]["tab_count"] = tab_count

            # Track focusable elements (axbridge reports enabled as null, not true)
            if node.get("enabled") is not False and elem_type in self.INTERACTIVE_TYPES:
                analysis["focusable"] += 1

        # Try to identify screen name from view controller
        if not analysis["screen_name"] and identifier:
            if "ViewController" in identifier or "Screen" in identifier:
                analysis["screen_name"] = identifier

        # Process children
        for child in node.get("children", []):
            self._analyze_recursive(child, analysis, depth + 1)

    def format_summary(self, analysis: dict, verbose: bool = False) -> str:
        """Format analysis as token-efficient summary."""
        lines = []

        # Screen identification (1 line)
        screen = analysis["screen_name"] or "Unknown Screen"
        total = analysis["total_elements"]
        interactive = analysis["interactive_elements"]
        lines.append(f"Screen: {screen} ({total} elements, {interactive} interactive)")

        # Buttons summary (1 line)
        if analysis["buttons"]:
            button_list = ", ".join(f'"{b}"' for b in analysis["buttons"][:BUTTONS_PREVIEW])
            if len(analysis["buttons"]) > BUTTONS_PREVIEW:
                button_list += f" +{len(analysis['buttons']) - BUTTONS_PREVIEW} more"
            lines.append(f"Buttons: {button_list}")

        # Text fields summary (1 line)
        if analysis["text_fields"]:
            field_count = len(analysis["text_fields"])
            [f["type"] for f in analysis["text_fields"]]
            filled = sum(1 for f in analysis["text_fields"] if f["has_value"])
            lines.append(f"TextFields: {field_count} ({filled} filled)")

        # Navigation summary (1 line)
        nav_parts = []
        if "nav_title" in analysis["navigation"]:
            nav_parts.append(f"NavBar: \"{analysis['navigation']['nav_title']}\"")
        if "tab_count" in analysis["navigation"]:
            nav_parts.append(f"TabBar: {analysis['navigation']['tab_count']} tabs")
        if nav_parts:
            lines.append(f"Navigation: {', '.join(nav_parts)}")

        # Focusable count (1 line)
        lines.append(f"Focusable: {analysis['focusable']} elements")

        # Near-empty screen: the default backend can't see web content (1 line)
        coverage = analysis.get("screen_coverage", 1.0)
        if not self.deep and coverage < LOW_COVERAGE_RATIO:
            lines.append(
                f"Coverage: labelled elements cover {coverage:.0%} of the screen - "
                "web content or an alert may be hidden; retry with --deep"
            )

        # Verbose mode adds element type breakdown
        if verbose:
            lines.append("\nElements by type:")
            for elem_type, items in analysis["elements_by_type"].items():
                if items:  # Only show types that exist
                    lines.append(f"  {elem_type}: {len(items)}")
                    for item in items[:SECTION_ITEMS_PREVIEW]:
                        lines.append(f"    - {item}")
                    if len(items) > SECTION_ITEMS_PREVIEW:
                        lines.append(f"    ... +{len(items) - SECTION_ITEMS_PREVIEW} more")

        return "\n".join(lines)

    def get_navigation_hints(self, analysis: dict) -> list[str]:
        """Generate navigation hints based on screen analysis."""
        hints = []

        # Check for common patterns
        if "Login" in str(analysis.get("buttons", [])):
            hints.append("Login screen detected - find TextFields for credentials")

        if analysis["text_fields"]:
            unfilled = [f for f in analysis["text_fields"] if not f["has_value"]]
            if unfilled:
                hints.append(f"{len(unfilled)} empty text field(s) - may need input")

        if not analysis["buttons"] and not analysis["text_fields"]:
            hints.append("No interactive elements - try swiping or going back")

        if "tab_count" in analysis.get("navigation", {}):
            hints.append(f"Tab bar available with {analysis['navigation']['tab_count']} tabs")

        return hints


def labelled_leaf_coverage(root: dict) -> float:
    """
    Fraction of the root's frame covered by labelled leaf elements.

    Samples a grid of points and counts those inside a leaf that carries a label
    or value. Unlabelled leaves are skipped: Safari's web view shows up as an
    empty full-screen Sheet, which would otherwise count as full coverage.
    """
    screen = root.get("frame") or {}
    width, height = screen.get("width", 0), screen.get("height", 0)
    if width <= 0 or height <= 0:
        return 0.0
    leaves = [
        node["frame"]
        for node in _iter_descendants(root)
        if not node.get("children")
        and (node.get("AXLabel") or node.get("AXValue"))
        and node.get("frame")
    ]
    step = COVERAGE_GRID_POINTS
    points = [
        (screen.get("x", 0) + x + step / 2, screen.get("y", 0) + y + step / 2)
        for x in range(0, int(width), step)
        for y in range(0, int(height), step)
    ]
    covered = sum(1 for point in points if any(_contains(frame, point) for frame in leaves))
    return covered / len(points)


def _iter_descendants(node: dict):
    """Yield every node below node, depth-first."""
    for child in node.get("children", []):
        yield child
        yield from _iter_descendants(child)


def _contains(frame: dict, point: tuple[float, float]) -> bool:
    """Whether point lies inside frame."""
    x, y = point
    return frame.get("x", 0) <= x < frame.get("x", 0) + frame.get("width", 0) and frame.get(
        "y", 0
    ) <= y < frame.get("y", 0) + frame.get("height", 0)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Map current screen UI elements")
    parser.add_argument("--verbose", action="store_true", help="Show detailed element breakdown")
    parser.add_argument("--json", action="store_true", help="Output raw JSON analysis")
    parser.add_argument("--hints", action="store_true", help="Include navigation hints")
    parser.add_argument(
        "--deep",
        action="store_true",
        help="Read through idb's axbridge backend (idb 1.7+): sees web content and in-app "
        "alerts, but is noisier and turns on the device's accessibility automation mode",
    )
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )

    args = parser.parse_args()

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)

    # Create mapper and analyze
    mapper = ScreenMapper(udid=udid, deep=args.deep)
    tree = mapper.get_accessibility_tree()
    analysis = mapper.analyze_tree(tree)

    # Output based on format
    if args.json:
        # Full JSON (verbose)
        print(json.dumps(analysis, indent=2, default=str))
    else:
        # Token-efficient summary (default)
        summary = mapper.format_summary(analysis, verbose=args.verbose)
        print(summary)

        # Add hints if requested
        if args.hints:
            hints = mapper.get_navigation_hints(analysis)
            if hints:
                print("\nHints:")
                for hint in hints:
                    print(f"  - {hint}")


if __name__ == "__main__":
    main()
