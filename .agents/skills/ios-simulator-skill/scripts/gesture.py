#!/usr/bin/env python3
"""
iOS Gesture Controller - Swipes and Complex Gestures

Performs navigation gestures like swipes, scrolls, long presses and pinches.
Token-efficient output for common navigation patterns.

Direction semantics:
- --swipe DIR is the direction the finger moves ("swipe up" drags upward).
- --scroll DIR is the direction the content travels, like a mouse wheel:
  "scroll down" reveals content further down, so the finger moves up.

Usage Examples:
    # Simple directional swipe (finger moves left - e.g. reveal row actions)
    python scripts/gesture.py --swipe left

    # Scroll down a list three times
    python scripts/gesture.py --scroll down --scroll-amount 3

    # Pull to refresh
    python scripts/gesture.py --refresh

    # Custom swipe coordinates
    python scripts/gesture.py --swipe-from 100,500 --swipe-to 100,100

    # Pinch to zoom in (scale 2.0) or out (scale 0.5)
    python scripts/gesture.py --pinch out
    python scripts/gesture.py --pinch in --scale 0.25

    # Long press at coordinates
    python scripts/gesture.py --long-press 200,300 --duration 2.0

    # Double tap (or N taps) at coordinates
    python scripts/gesture.py --double-tap 200,300
    python scripts/gesture.py --double-tap 200,300 --tap-count 3

    # Press-hold-drag-release between coordinates and/or accessibility labels
    python scripts/gesture.py --drag 200,300 200,600
    python scripts/gesture.py --drag "Row 1" "Row 4"

    # Rotate the device, or shake it (debug menus, undo)
    python scripts/gesture.py --rotate landscape-left
    python scripts/gesture.py --shake

Output Format:
    Swiped up
    Scrolled down (3x)
    Performed pull to refresh
    Tapped 2x at (200, 300)
    Dragged (200, 300) to (200, 600)
    Rotated to landscape-left
    Shook device

Technical Details:
- Swipes travel a fraction of the screen (70% by default), centred on screen
- Scrolls are repeated 30% swipes with a short pause between them
- Coordinates are in points; screen size comes from the accessibility tree
  (falls back to 390x844 if detection fails)
- Uses `idb ui swipe`, `idb ui tap --duration` and `idb ui pinch`.
  idb durations are in seconds.
- idb 1.7+: `idb ui multi-tap`, `idb ui drag-and-drop`, `idb ui rotate`, `idb ui shake`.
  Drag endpoints are "x,y" or an accessibility label (matched as AXLabel substring).
  Orientation names are physical device rotation: landscape-left leaves the UI
  in landscape with the home indicator on the right.
"""

import argparse
import re
import sys
import time

from common import (
    build_idb_command,
    get_device_screen_size,
    get_screen_size,
    resolve_udid,
    run_idb,
    transform_screenshot_coords,
    with_idb_upgrade_hint,
)

SWIPE_DISTANCE_RATIO = 0.7
SCROLL_DISTANCE_RATIO = 0.3
SCROLL_PAUSE_SECONDS = 0.2
EDGE_INSET_RATIO = 0.05
# idb has no default swipe duration; an instantaneous swipe is ignored by iOS.
SWIPE_DURATION_SECONDS = 0.5

# idb 1.7 orientation arguments, keyed by the script-facing name.
ORIENTATIONS: dict[str, str] = {
    "portrait": "PORTRAIT",
    "portrait-upside-down": "PORTRAIT_UPSIDE_DOWN",
    "landscape-left": "LANDSCAPE_LEFT",
    "landscape-right": "LANDSCAPE_RIGHT",
}

MIN_MULTI_TAP_COUNT = 2

# Operations missing from idb < 1.7; argparse rejects them as an invalid choice.
IDB_1_7_OPERATIONS = {"ui multi-tap", "ui drag-and-drop", "ui rotate", "ui shake"}

# "x,y" drag endpoint, as opposed to an accessibility label.
POINT_PATTERN = re.compile(r"^\d+,\d+$")

# Pinch "out" spreads the fingers (zoom in); "in" closes them (zoom out).
PINCH_SCALE_BY_DIRECTION = {"out": 2.0, "in": 0.5}

# Finger direction -> unit vector in screen coordinates (y grows downward).
FINGER_VECTOR_BY_DIRECTION = {
    "up": (0, -1),
    "down": (0, 1),
    "left": (-1, 0),
    "right": (1, 0),
}

# Content scroll direction -> finger direction that produces it.
FINGER_DIRECTION_FOR_SCROLL = {"down": "up", "up": "down"}


class GestureController:
    """Performs gestures on iOS simulator."""

    def __init__(self, udid: str | None = None):
        """Initialize gesture controller, detecting screen size once."""
        self.udid = udid
        self.screen_size = get_screen_size(udid)
        self.last_error = ""

    # === PUBLIC API ===

    def swipe(self, direction: str, distance_ratio: float = SWIPE_DISTANCE_RATIO) -> bool:
        """
        Swipe with the finger moving in `direction`.

        Args:
            direction: up, down, left, right (finger movement)
            distance_ratio: Fraction of the screen dimension to travel (0.0-1.0)

        Returns:
            Success status
        """
        if direction not in FINGER_VECTOR_BY_DIRECTION:
            self.last_error = f"Unknown direction '{direction}'"
            return False
        start, end = compute_swipe_points(self.screen_size, direction, distance_ratio)
        return self.swipe_between(start, end)

    def swipe_between(
        self,
        start: tuple[int, int],
        end: tuple[int, int],
        duration_seconds: float = SWIPE_DURATION_SECONDS,
    ) -> bool:
        """
        Swipe between two points.

        Args:
            start: Starting coordinates (x, y) in points
            end: Ending coordinates (x, y) in points
            duration_seconds: Swipe duration

        Returns:
            Success status
        """
        return self._run(
            "ui swipe", start[0], start[1], end[0], end[1], "--duration", duration_seconds
        )

    def scroll(self, direction: str, amount: int = 3) -> bool:
        """
        Scroll content in `direction` with repeated short swipes.

        Args:
            direction: up, down (content direction - "down" reveals content below)
            amount: Number of swipes

        Returns:
            Success status
        """
        finger_direction = FINGER_DIRECTION_FOR_SCROLL.get(direction)
        if not finger_direction:
            self.last_error = f"Unknown scroll direction '{direction}'"
            return False
        for swipe_number in range(amount):
            if not self.swipe(finger_direction, distance_ratio=SCROLL_DISTANCE_RATIO):
                return False
            if swipe_number < amount - 1:
                time.sleep(SCROLL_PAUSE_SECONDS)
        return True

    def tap_and_hold(self, x: int, y: int, duration_seconds: float = 2.0) -> bool:
        """Long press at coordinates for `duration_seconds`."""
        return self._run("ui tap", x, y, "--duration", duration_seconds)

    def pinch(
        self,
        direction: str = "out",
        center: tuple[int, int] | None = None,
        scale: float | None = None,
    ) -> bool:
        """
        Pinch around a centre point.

        Args:
            direction: 'out' (fingers apart, zoom in) or 'in' (together, zoom out)
            center: Pinch centre; screen centre when None
            scale: Explicit scale factor (>1 zooms in); overrides direction

        Returns:
            Success status
        """
        if scale is None:
            scale = PINCH_SCALE_BY_DIRECTION.get(direction)
            if scale is None:
                self.last_error = f"Unknown pinch direction '{direction}'"
                return False
        if not center:
            width, height = self.screen_size
            center = (width // 2, height // 2)
        return self._run("ui pinch", center[0], center[1], scale)

    def multi_tap(self, x: int, y: int, count: int = MIN_MULTI_TAP_COUNT) -> bool:
        """Tap `count` times in quick succession at coordinates (idb 1.7+)."""
        if count < MIN_MULTI_TAP_COUNT:
            self.last_error = f"--tap-count must be >= {MIN_MULTI_TAP_COUNT} (got {count})"
            return False
        return self._run("ui multi-tap", x, y, "--count", count)

    def drag_and_drop(
        self, source: tuple[int, int] | str, destination: tuple[int, int] | str
    ) -> bool:
        """
        Press the source, drag to the destination and release (idb 1.7+).

        Unlike a swipe, the source is held first, so it picks up list rows and icons.

        Args:
            source: (x, y) in points, or an accessibility label
            destination: (x, y) in points, or an accessibility label

        Returns:
            Success status
        """
        return self._run("ui drag-and-drop", *_drag_endpoint(source), *_drag_endpoint(destination))

    def rotate(self, orientation: str) -> bool:
        """Rotate the device to a named orientation (idb 1.7+)."""
        idb_orientation = ORIENTATIONS.get(orientation)
        if not idb_orientation:
            self.last_error = (
                f"Unknown orientation '{orientation}' (choose from: {', '.join(ORIENTATIONS)})"
            )
            return False
        return self._run("ui rotate", idb_orientation)

    def shake(self) -> bool:
        """Shake the device (idb 1.7+)."""
        return self._run("ui shake")

    def refresh(self) -> bool:
        """Pull to refresh: drag down from near the top of the content."""
        width, height = self.screen_size
        start = (width // 2, int(height * 0.15))
        end = (width // 2, int(height * 0.55))
        return self.swipe_between(start, end)

    # === HELPERS ===

    def _run(self, operation: str, *args: object) -> bool:
        """Run an idb operation, keeping the failure reason in last_error."""
        ok, self.last_error = run_idb(build_idb_command(operation, self.udid, *args))
        if not ok and operation in IDB_1_7_OPERATIONS:
            self.last_error = with_idb_upgrade_hint(self.last_error)
        return ok


def compute_swipe_points(
    screen_size: tuple[int, int], direction: str, distance_ratio: float
) -> tuple[tuple[int, int], tuple[int, int]]:
    """
    Compute start/end points for a swipe centred on the screen.

    The swipe travels `distance_ratio` of the screen along its axis, clamped so
    neither end lands within EDGE_INSET_RATIO of an edge (system gesture zones).

    Example:
        compute_swipe_points((400, 800), "up", 0.7)  # ((200, 680), (200, 120))
    """
    width, height = screen_size
    dx, dy = FINGER_VECTOR_BY_DIRECTION[direction]
    center_x, center_y = width // 2, height // 2
    max_ratio = 1 - 2 * EDGE_INSET_RATIO
    ratio = max(0.0, min(distance_ratio, max_ratio))
    half_x = int(width * ratio / 2) * dx
    half_y = int(height * ratio / 2) * dy
    start = (center_x - half_x, center_y - half_y)
    end = (center_x + half_x, center_y + half_y)
    return start, end


def _drag_endpoint(target: tuple[int, int] | str) -> list[object]:
    """Expand a drag endpoint into idb arguments: 'X Y' for a point, one label otherwise."""
    return list(target) if isinstance(target, tuple) else [target]


def parse_drag_endpoint(raw: str, flag: str) -> tuple[int, int] | str:
    """Parse a drag endpoint: 'x,y' becomes a point, anything else is an accessibility label."""
    if POINT_PATTERN.match(raw):
        return parse_point(raw, flag)
    return raw


def parse_point(raw: str, flag: str) -> tuple[int, int]:
    """Parse 'x,y' into ints, exiting with an actionable message if malformed."""
    parts = raw.split(",")
    try:
        if len(parts) != 2:
            raise ValueError
        return (int(parts[0]), int(parts[1]))
    except ValueError:
        print(f"Error: {flag} expects x,y integers (got '{raw}')", file=sys.stderr)
        sys.exit(1)


def report(
    ok: bool, success_message: str, failure_message: str, controller: GestureController
) -> None:
    """Print the outcome, exiting non-zero with idb's reason on failure."""
    if ok:
        print(success_message)
        return
    reason = f": {controller.last_error}" if controller.last_error else ""
    print(f"{failure_message}{reason}", file=sys.stderr)
    sys.exit(1)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Perform gestures on iOS simulator")

    # Gesture options
    parser.add_argument(
        "--swipe",
        choices=["up", "down", "left", "right"],
        help="Directional swipe (direction the finger moves)",
    )
    parser.add_argument("--swipe-from", help="Custom swipe start coordinates (x,y)")
    parser.add_argument("--swipe-to", help="Custom swipe end coordinates (x,y)")
    parser.add_argument(
        "--scroll",
        choices=["up", "down"],
        help="Scroll content (down = reveal content below, like a mouse wheel)",
    )
    parser.add_argument(
        "--scroll-amount", type=int, default=3, help="Number of scroll swipes (default: 3)"
    )
    parser.add_argument("--long-press", help="Long press at coordinates (x,y)")
    parser.add_argument(
        "--duration", type=float, default=2.0, help="Long press duration in seconds (default: 2)"
    )
    parser.add_argument(
        "--pinch", choices=["in", "out"], help="Pinch gesture (out = zoom in, in = zoom out)"
    )
    parser.add_argument(
        "--scale", type=float, help="Pinch scale factor, overrides --pinch (>1 zooms in)"
    )
    parser.add_argument("--refresh", action="store_true", help="Pull to refresh gesture")
    parser.add_argument("--double-tap", help="Double tap at coordinates (x,y) (idb 1.7+)")
    parser.add_argument(
        "--tap-count",
        type=int,
        default=MIN_MULTI_TAP_COUNT,
        help="Taps for --double-tap (default: 2)",
    )
    parser.add_argument(
        "--drag",
        nargs=2,
        metavar=("SOURCE", "DESTINATION"),
        help="Press, drag and release; each end is x,y or an accessibility label (idb 1.7+)",
    )
    parser.add_argument("--rotate", choices=list(ORIENTATIONS), help="Rotate the device (idb 1.7+)")
    parser.add_argument("--shake", action="store_true", help="Shake the device (idb 1.7+)")

    # Coordinate transformation
    parser.add_argument(
        "--screenshot-coords",
        action="store_true",
        help="Interpret swipe coordinates as from a screenshot (requires --screenshot-width/height)",
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

    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )

    args = parser.parse_args()

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    controller = GestureController(udid=udid)

    if args.swipe:
        ok = controller.swipe(args.swipe)
        report(ok, f"Swiped {args.swipe}", f"Failed to swipe {args.swipe}", controller)

    elif args.swipe_from and args.swipe_to:
        start = parse_point(args.swipe_from, "--swipe-from")
        end = parse_point(args.swipe_to, "--swipe-to")

        if args.screenshot_coords:
            if not args.screenshot_width or not args.screenshot_height:
                print(
                    "Error: --screenshot-coords requires --screenshot-width and --screenshot-height",
                    file=sys.stderr,
                )
                sys.exit(1)

            device_w, device_h = get_device_screen_size(udid)
            start = transform_screenshot_coords(
                start[0],
                start[1],
                args.screenshot_width,
                args.screenshot_height,
                device_w,
                device_h,
            )
            end = transform_screenshot_coords(
                end[0], end[1], args.screenshot_width, args.screenshot_height, device_w, device_h
            )
            print("Transformed screenshot coords to device coords")

        ok = controller.swipe_between(start, end)
        report(ok, f"Swiped from {start} to {end}", "Failed to swipe", controller)

    elif args.scroll:
        ok = controller.scroll(args.scroll, args.scroll_amount)
        report(
            ok,
            f"Scrolled {args.scroll} ({args.scroll_amount}x)",
            f"Failed to scroll {args.scroll}",
            controller,
        )

    elif args.long_press:
        x, y = parse_point(args.long_press, "--long-press")
        ok = controller.tap_and_hold(x, y, args.duration)
        report(
            ok,
            f"Long pressed at ({x}, {y}) for {args.duration}s",
            "Failed to long press",
            controller,
        )

    elif args.pinch or args.scale is not None:
        if args.scale is not None and args.scale <= 0:
            print(f"Error: --scale must be > 0 (got {args.scale})", file=sys.stderr)
            sys.exit(1)
        ok = controller.pinch(args.pinch or "out", scale=args.scale)
        zoomed_in = args.scale > 1 if args.scale else args.pinch == "out"
        report(ok, "Zoomed in" if zoomed_in else "Zoomed out", "Failed to pinch", controller)

    elif args.refresh:
        ok = controller.refresh()
        report(ok, "Performed pull to refresh", "Failed to refresh", controller)

    elif args.double_tap:
        x, y = parse_point(args.double_tap, "--double-tap")
        ok = controller.multi_tap(x, y, args.tap_count)
        report(ok, f"Tapped {args.tap_count}x at ({x}, {y})", "Failed to tap", controller)

    elif args.drag:
        source = parse_drag_endpoint(args.drag[0], "--drag")
        destination = parse_drag_endpoint(args.drag[1], "--drag")
        ok = controller.drag_and_drop(source, destination)
        report(ok, f"Dragged {source} to {destination}", "Failed to drag", controller)

    elif args.rotate:
        ok = controller.rotate(args.rotate)
        report(ok, f"Rotated to {args.rotate}", f"Failed to rotate to {args.rotate}", controller)

    elif args.shake:
        ok = controller.shake()
        report(ok, "Shook device", "Failed to shake device", controller)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
