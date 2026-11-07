#!/usr/bin/env python3
"""
iOS Status Bar Controller

Override simulator status bar for clean screenshots and testing.
Control time, network, wifi, battery display.

Usage: python scripts/status_bar.py --preset clean
"""

import argparse
import subprocess
import sys

from common import resolve_udid


class StatusBarController:
    """Controls iOS simulator status bar appearance."""

    # Preset configurations
    PRESETS = {
        "clean": {
            "time": "9:41",
            "data_network": "5g",
            "wifi_mode": "active",
            "battery_state": "charged",
            "battery_level": 100,
        },
        "testing": {
            "time": "11:11",
            "data_network": "4g",
            "wifi_mode": "active",
            "battery_state": "discharging",
            "battery_level": 50,
        },
        "low_battery": {
            "time": "9:41",
            "data_network": "5g",
            "wifi_mode": "active",
            "battery_state": "discharging",
            "battery_level": 20,
        },
        "airplane": {
            "time": "9:41",
            "data_network": "none",
            "wifi_mode": "failed",
            "battery_state": "charged",
            "battery_level": 100,
        },
    }

    def __init__(self, udid: str | None = None):
        """Initialize status bar controller.

        Args:
            udid: Optional device UDID (auto-detects booted simulator if None)
        """
        self.udid = udid

    def override(
        self,
        time: str | None = None,
        data_network: str | None = None,
        wifi_mode: str | None = None,
        battery_state: str | None = None,
        battery_level: int | None = None,
    ) -> bool:
        """
        Override status bar appearance.

        Args:
            time: Time in HH:MM format (e.g., "9:41")
            data_network: Network type (none, 1x, 3g, 4g, 5g, lte, lte-a)
            wifi_mode: WiFi state (active, searching, failed)
            battery_state: Battery state (charging, charged, discharging)
            battery_level: Battery percentage (0-100)

        Returns:
            Success status
        """
        cmd = ["xcrun", "simctl", "status_bar"]

        if self.udid:
            cmd.append(self.udid)
        else:
            cmd.append("booted")

        cmd.append("override")

        # Add parameters if provided
        if time:
            cmd.extend(["--time", time])
        if data_network:
            cmd.extend(["--dataNetwork", data_network])
        if wifi_mode:
            cmd.extend(["--wifiMode", wifi_mode])
        if battery_state:
            cmd.extend(["--batteryState", battery_state])
        if battery_level is not None:
            cmd.extend(["--batteryLevel", str(battery_level)])

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def clear(self) -> bool:
        """
        Clear status bar override and restore defaults.

        Returns:
            Success status
        """
        cmd = ["xcrun", "simctl", "status_bar"]

        if self.udid:
            cmd.append(self.udid)
        else:
            cmd.append("booted")

        cmd.append("clear")

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Override iOS simulator status bar for screenshots and testing"
    )

    # Preset option
    parser.add_argument(
        "--preset",
        choices=list(StatusBarController.PRESETS.keys()),
        help="Use preset configuration (clean, testing, low-battery, airplane)",
    )

    # Custom options
    parser.add_argument(
        "--time",
        help="Override time (HH:MM format, e.g., '9:41')",
    )
    parser.add_argument(
        "--data-network",
        choices=["none", "1x", "3g", "4g", "5g", "lte", "lte-a"],
        help="Data network type",
    )
    parser.add_argument(
        "--wifi-mode",
        choices=["active", "searching", "failed"],
        help="WiFi state",
    )
    parser.add_argument(
        "--battery-state",
        choices=["charging", "charged", "discharging"],
        help="Battery state",
    )
    parser.add_argument(
        "--battery-level",
        type=int,
        help="Battery level 0-100",
    )

    # Other options
    parser.add_argument(
        "--clear",
        action="store_true",
        help="Clear status bar override and restore defaults",
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

    controller = StatusBarController(udid=udid)

    # Clear mode
    if args.clear:
        if controller.clear():
            print("Status bar override cleared - defaults restored")
        else:
            print("Failed to clear status bar override")
            sys.exit(1)

    # Preset mode
    elif args.preset:
        preset = StatusBarController.PRESETS[args.preset]
        if controller.override(**preset):
            print(f"Status bar: {args.preset} preset applied")
            print(
                f"  Time: {preset['time']}, "
                f"Network: {preset['data_network']}, "
                f"Battery: {preset['battery_level']}%"
            )
        else:
            print(f"Failed to apply {args.preset} preset")
            sys.exit(1)

    # Custom mode
    elif any(
        [
            args.time,
            args.data_network,
            args.wifi_mode,
            args.battery_state,
            args.battery_level is not None,
        ]
    ):
        if controller.override(
            time=args.time,
            data_network=args.data_network,
            wifi_mode=args.wifi_mode,
            battery_state=args.battery_state,
            battery_level=args.battery_level,
        ):
            output = "Status bar override applied:"
            if args.time:
                output += f" Time={args.time}"
            if args.data_network:
                output += f" Network={args.data_network}"
            if args.battery_level is not None:
                output += f" Battery={args.battery_level}%"
            print(output)
        else:
            print("Failed to override status bar")
            sys.exit(1)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
