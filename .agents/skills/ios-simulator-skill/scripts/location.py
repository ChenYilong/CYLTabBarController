#!/usr/bin/env python3
"""
GPS location simulation for iOS simulators.

Set a fixed coordinate, use a named city preset, play back a GPX route,
walk a multi-waypoint path, or clear any active location override.

Wraps `xcrun simctl location <udid> set/clear/start/run`.

Key features:
- Set precise lat/lng coordinates
- 15 built-in city presets
- GPX scenario playback (built-in scenarios only — simctl limitation)
- Multi-waypoint path with configurable speed and update interval
- Clear active location override
- Standard --json, --verbose, and --udid flags

Usage examples:
    python scripts/location.py --lat 53.3498 --lng -6.2603
    python scripts/location.py --city Dublin
    python scripts/location.py --gpx FreewayDrive
    python scripts/location.py --waypoints "37.33,-122.03 37.78,-122.41" --speed 10
    python scripts/location.py --clear
"""

import argparse
import json
import subprocess
import sys

from common import resolve_udid

# === PRESETS ===

_CITY_ALIASES: set[str] = {"nyc", "sf", "la"}

CITY_PRESETS: dict[str, tuple[float, float]] = {
    "dublin": (53.3498, -6.2603),
    "london": (51.5074, -0.1278),
    "newyork": (40.7128, -74.0060),
    "nyc": (40.7128, -74.0060),
    "sanfrancisco": (37.7749, -122.4194),
    "sf": (37.7749, -122.4194),
    "tokyo": (35.6762, 139.6503),
    "sydney": (-33.8688, 151.2093),
    "paris": (48.8566, 2.3522),
    "berlin": (52.5200, 13.4050),
    "beijing": (39.9042, 116.4074),
    "mumbai": (19.0760, 72.8777),
    "cairo": (30.0444, 31.2357),
    "saopaulo": (-23.5505, -46.6333),
    "losangeles": (34.0522, -118.2437),
    "la": (34.0522, -118.2437),
}


# === MAIN CLASS ===


class LocationManager:
    """Manage simulated GPS location on an iOS simulator."""

    def __init__(self, udid: str | None = None):
        """Initialize with optional device UDID.

        Args:
            udid: Simulator UDID — auto-detects booted device if None.
        """
        self.udid = udid

    def set_coordinate(self, lat: float, lng: float, verbose: bool = False) -> tuple[bool, str]:
        """
        Set simulator GPS to a fixed coordinate.

        Args:
            lat: Latitude in decimal degrees (-90 to 90).
            lng: Longitude in decimal degrees (-180 to 180).
            verbose: Include extra context in the returned message.

        Returns:
            (success, message) tuple.
        """
        if not (-90 <= lat <= 90):
            return False, f"Invalid latitude {lat}: must be between -90 and 90"
        if not (-180 <= lng <= 180):
            return False, f"Invalid longitude {lng}: must be between -180 and 180"

        coord = f"{lat},{lng}"
        cmd = ["xcrun", "simctl", "location", self.udid, "set", coord]

        try:
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=15)
        except subprocess.TimeoutExpired:
            return False, "Error: location set timed out"
        except Exception as e:
            return False, f"Error: {e}"

        if result.returncode != 0:
            error = result.stderr.strip() or "unknown error"
            return False, f"location set failed: {error}"

        if verbose:
            return True, (
                f"Location set\n"
                f"  Latitude:  {lat}\n"
                f"  Longitude: {lng}\n"
                f"  Device:    {self.udid}"
            )
        return True, f"Location set: {lat}, {lng}"

    def set_city(self, city_name: str, verbose: bool = False) -> tuple[bool, str]:
        """
        Set location to a named city preset.

        Args:
            city_name: Case-insensitive city name from CITY_PRESETS.
            verbose: Include coordinate detail in the returned message.

        Returns:
            (success, message) tuple.
        """
        key = city_name.lower().replace(" ", "")
        if key not in CITY_PRESETS:
            available = ", ".join(sorted({k for k in CITY_PRESETS if k not in _CITY_ALIASES}))
            return False, f"Unknown city '{city_name}'. Available: {available}"

        lat, lng = CITY_PRESETS[key]
        success, message = self.set_coordinate(lat, lng, verbose=verbose)

        if success and not verbose:
            return True, f"Location set: {city_name.title()} ({lat}, {lng})"
        return success, message

    def run_gpx_scenario(self, scenario: str, verbose: bool = False) -> tuple[bool, str]:
        """
        Run a named GPX location scenario built into the simulator.

        Use `xcrun simctl location <udid> list` to see available scenarios.

        Args:
            scenario: Scenario name (e.g. "FreewayDrive", "ApplePark").
            verbose: Include extra context in the returned message.

        Returns:
            (success, message) tuple.
        """
        cmd = ["xcrun", "simctl", "location", self.udid, "run", scenario]

        try:
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=15)
        except subprocess.TimeoutExpired:
            return False, "Error: location run timed out"
        except Exception as e:
            return False, f"Error: {e}"

        if result.returncode != 0:
            error = result.stderr.strip() or "unknown error"
            return False, f"GPX scenario failed: {error}"

        if verbose:
            return True, f"GPX scenario running\n  Scenario: {scenario}\n  Device:   {self.udid}"
        return True, f"GPX scenario running: {scenario}"

    def list_scenarios(self) -> tuple[bool, list[str], str]:
        """
        List built-in location scenarios available on this simulator.

        Returns:
            (success, scenarios, error) tuple where scenarios is a list of names
            and error is an empty string on success or a description of the failure.
        """
        cmd = ["xcrun", "simctl", "location", self.udid, "list"]

        try:
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=15)
        except subprocess.TimeoutExpired:
            return False, [], "Error: list scenarios timed out"
        except Exception as e:
            return False, [], f"Error: {e}"

        if result.returncode != 0:
            error = result.stderr.strip() or "unknown error"
            return False, [], f"list scenarios failed: {error}"

        lines = [ln.strip() for ln in result.stdout.splitlines() if ln.strip()]
        return True, lines, ""

    def start_waypoints(
        self,
        waypoints: list[tuple[float, float]],
        speed_mps: float = 20.0,
        interval_seconds: float | None = None,
        distance_meters: float | None = None,
        verbose: bool = False,
    ) -> tuple[bool, str]:
        """
        Animate the location along a series of waypoints.

        Requires at least two waypoints.

        Args:
            waypoints: List of (lat, lng) pairs.
            speed_mps: Movement speed in metres per second (default 20 m/s).
            interval_seconds: Location update interval in seconds; mutually exclusive with distance_meters.
            distance_meters: Location update distance in metres; mutually exclusive with interval_seconds.
            verbose: Include waypoint list in the returned message.

        Returns:
            (success, message) tuple.
        """
        if len(waypoints) < 2:
            return False, "At least two waypoints are required for --waypoints"

        coord_args = [f"{lat},{lng}" for lat, lng in waypoints]
        cmd = [
            "xcrun",
            "simctl",
            "location",
            self.udid,
            "start",
            f"--speed={speed_mps}",
        ]
        if interval_seconds is not None:
            cmd.append(f"--interval={interval_seconds}")
        if distance_meters is not None:
            cmd.append(f"--distance={distance_meters}")
        cmd.extend(coord_args)

        try:
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=15)
        except subprocess.TimeoutExpired:
            return False, "Error: location start timed out"
        except Exception as e:
            return False, f"Error: {e}"

        if result.returncode != 0:
            error = result.stderr.strip() or "unknown error"
            return False, f"Waypoint route failed: {error}"

        if verbose:
            pts = "\n".join(f"  {i + 1}. {lat}, {lng}" for i, (lat, lng) in enumerate(waypoints))
            return True, (
                f"Waypoint route started\n"
                f"  Speed:     {speed_mps} m/s\n"
                f"  Waypoints:\n{pts}\n"
                f"  Device:    {self.udid}"
            )
        return True, f"Waypoint route started: {len(waypoints)} points at {speed_mps} m/s"

    def clear(self, verbose: bool = False) -> tuple[bool, str]:
        """
        Clear any active location simulation and restore real GPS.

        Args:
            verbose: Include extra context in the returned message.

        Returns:
            (success, message) tuple.
        """
        cmd = ["xcrun", "simctl", "location", self.udid, "clear"]

        try:
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=15)
        except subprocess.TimeoutExpired:
            return False, "Error: location clear timed out"
        except Exception as e:
            return False, f"Error: {e}"

        if result.returncode != 0:
            error = result.stderr.strip() or "unknown error"
            return False, f"location clear failed: {error}"

        if verbose:
            return True, f"Location cleared\n  Device: {self.udid}"
        return True, "Location cleared"


# === CLI ===


def _parse_waypoints(raw: str) -> list[tuple[float, float]]:
    """
    Parse a whitespace-separated string of 'lat,lng' pairs.

    Args:
        raw: e.g. "53.34,-6.26 51.50,-0.12"

    Returns:
        List of (lat, lng) float tuples.

    Raises:
        ValueError: If any pair is malformed.
    """
    pairs = []
    for token in raw.split():
        parts = token.split(",")
        if len(parts) != 2:
            raise ValueError(f"Expected 'lat,lng', got: {token!r}")
        try:
            pairs.append((float(parts[0]), float(parts[1])))
        except ValueError:
            raise ValueError(f"Non-numeric coordinate in: {token!r}") from None
    return pairs


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Simulate GPS location on an iOS simulator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/location.py --lat 53.3498 --lng -6.2603
  python scripts/location.py --city Dublin
  python scripts/location.py --gpx FreewayDrive
  python scripts/location.py --waypoints "37.33,-122.03 37.78,-122.41" --speed 10
  python scripts/location.py --clear
  python scripts/location.py --list-scenarios
""",
    )

    # Device selection
    parser.add_argument("--udid", help="Target device UDID (auto-detects booted simulator)")

    # Location actions (mutually exclusive)
    action_group = parser.add_mutually_exclusive_group(required=True)
    action_group.add_argument("--lat", type=float, help="Latitude (requires --lng)")
    action_group.add_argument("--city", metavar="NAME", help="Named city preset")
    action_group.add_argument("--gpx", metavar="SCENARIO", help="Run a built-in GPX scenario name")
    action_group.add_argument(
        "--waypoints",
        metavar="'lat,lng ...'",
        help="Whitespace-separated lat,lng pairs for animated route",
    )
    action_group.add_argument("--clear", action="store_true", help="Clear location override")
    action_group.add_argument(
        "--list-scenarios", action="store_true", help="List available built-in GPX scenarios"
    )

    # Coordinate companion
    parser.add_argument("--lng", type=float, help="Longitude (used with --lat)")

    # Waypoint options
    parser.add_argument(
        "--speed",
        type=float,
        default=20.0,
        metavar="M_PER_SEC",
        help="Movement speed in m/s for --waypoints (default: 20)",
    )

    waypoint_pace = parser.add_mutually_exclusive_group()
    waypoint_pace.add_argument(
        "--interval",
        type=float,
        metavar="SECONDS",
        help="Location update interval in seconds for --waypoints (mutually exclusive with --distance)",
    )
    waypoint_pace.add_argument(
        "--distance",
        type=float,
        metavar="METERS",
        help="Location update distance in metres for --waypoints (mutually exclusive with --interval)",
    )

    # Output flags
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    # Validate --lat and --lng must be provided together
    if (args.lat is None) != (args.lng is None):
        parser.error("--lat and --lng must be provided together")

    # Resolve device UDID
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    manager = LocationManager(udid=udid)

    # === Dispatch ===

    if args.lat is not None:
        success, message = manager.set_coordinate(args.lat, args.lng, verbose=args.verbose)
        action = "set_coordinate"
        extra: dict = {"lat": args.lat, "lng": args.lng}

    elif args.city:
        success, message = manager.set_city(args.city, verbose=args.verbose)
        action = "set_city"
        key = args.city.lower().replace(" ", "")
        extra = {
            "city": args.city,
            "lat": CITY_PRESETS[key][0] if key in CITY_PRESETS else None,
            "lng": CITY_PRESETS[key][1] if key in CITY_PRESETS else None,
        }

    elif args.gpx:
        success, message = manager.run_gpx_scenario(args.gpx, verbose=args.verbose)
        action = "run_gpx"
        extra = {"scenario": args.gpx}

    elif args.waypoints:
        try:
            waypoints = _parse_waypoints(args.waypoints)
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
        success, message = manager.start_waypoints(
            waypoints,
            speed_mps=args.speed,
            interval_seconds=args.interval,
            distance_meters=args.distance,
            verbose=args.verbose,
        )
        action = "start_waypoints"
        extra = {
            "waypoints": [{"lat": lat, "lng": lng} for lat, lng in waypoints],
            "speed_mps": args.speed,
        }

    elif args.list_scenarios:
        ok, scenarios, list_error = manager.list_scenarios()
        if args.json:
            payload: dict = {"action": "list_scenarios", "udid": udid, "scenarios": scenarios}
            if not ok:
                payload["error"] = list_error
            print(json.dumps(payload))
        elif ok and scenarios:
            print("\n".join(f"  {s}" for s in scenarios))
        elif ok:
            print("No scenarios available")
        else:
            print(list_error, file=sys.stderr)
        sys.exit(0 if ok else 1)

    else:  # --clear
        success, message = manager.clear(verbose=args.verbose)
        action = "clear"
        extra = {}

    # === Output ===

    if args.json:
        print(
            json.dumps(
                {
                    "action": action,
                    "udid": udid,
                    "success": success,
                    "message": message,
                    **extra,
                }
            )
        )
    else:
        print(message)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
