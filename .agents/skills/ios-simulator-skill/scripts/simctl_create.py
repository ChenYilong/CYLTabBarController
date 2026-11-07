#!/usr/bin/env python3
"""
Create iOS simulators dynamically.

This script creates new simulators with specified device type and iOS version.
Useful for CI/CD pipelines that need on-demand test device provisioning.

Key features:
- Create by device type (iPhone 16 Pro, iPad Air, etc.)
- Specify iOS version (17.0, 18.0, etc.)
- Custom device naming
- Return newly created device UDID
- List available device types and runtimes
"""

import argparse
import subprocess
import sys
from typing import Optional

from common.device_utils import list_simulators


class SimulatorCreator:
    """Create iOS simulators with specified configurations."""

    def __init__(self):
        """Initialize simulator creator."""
        pass

    def create(
        self,
        device_type: str,
        ios_version: str | None = None,
        custom_name: str | None = None,
    ) -> tuple[bool, str, str | None]:
        """
        Create new iOS simulator.

        Args:
            device_type: Device type (e.g., "iPhone 16 Pro", "iPad Air")
            ios_version: iOS version (e.g., "18.0"). If None, uses latest.
            custom_name: Custom device name. If None, uses default.

        Returns:
            (success, message, new_udid) tuple
        """
        # Get available device types and runtimes
        available_types = self._get_device_types()
        if not available_types:
            return False, "Failed to get available device types", None

        # Normalize device type
        device_type_id = None
        for dt in available_types:
            if device_type.lower() in dt["name"].lower():
                device_type_id = dt["identifier"]
                break

        if not device_type_id:
            return (
                False,
                f"Device type '{device_type}' not found. "
                f"Use --list-devices for available types.",
                None,
            )

        # Get available runtimes
        available_runtimes = self._get_runtimes()
        if not available_runtimes:
            return False, "Failed to get available runtimes", None

        # Resolve iOS version
        runtime_id = None
        if ios_version:
            for rt in available_runtimes:
                if ios_version in rt["name"]:
                    runtime_id = rt["identifier"]
                    break

            if not runtime_id:
                return (
                    False,
                    f"iOS version '{ios_version}' not found. "
                    f"Use --list-runtimes for available versions.",
                    None,
                )
        # Use latest runtime
        elif available_runtimes:
            runtime_id = available_runtimes[-1]["identifier"]

        if not runtime_id:
            return False, "No iOS runtime available", None

        # Create device
        try:
            # Build device name
            device_name = (
                custom_name or f"{device_type_id.split('.')[-1]}-{ios_version or 'latest'}"
            )

            cmd = [
                "xcrun",
                "simctl",
                "create",
                device_name,
                device_type_id,
                runtime_id,
            ]

            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=60)

            if result.returncode != 0:
                error = result.stderr.strip() or result.stdout.strip()
                return False, f"Creation failed: {error}", None

            # Extract UDID from output
            new_udid = result.stdout.strip()

            return (
                True,
                f"Device created: {device_name} ({device_type}) iOS {ios_version or 'latest'} "
                f"UDID: {new_udid}",
                new_udid,
            )

        except subprocess.TimeoutExpired:
            return False, "Creation command timed out", None
        except Exception as e:
            return False, f"Creation error: {e}", None

    @staticmethod
    def _get_device_types() -> list[dict]:
        """
        Get available device types.

        Returns:
            List of device type dicts with "name" and "identifier" keys
        """
        try:
            cmd = ["xcrun", "simctl", "list", "devicetypes", "-j"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)

            import json

            data = json.loads(result.stdout)
            devices = []

            for device in data.get("devicetypes", []):
                devices.append(
                    {
                        "name": device.get("name", ""),
                        "identifier": device.get("identifier", ""),
                    }
                )

            return devices
        except Exception:
            return []

    @staticmethod
    def _get_runtimes() -> list[dict]:
        """
        Get available iOS runtimes.

        Returns:
            List of runtime dicts with "name" and "identifier" keys
        """
        try:
            cmd = ["xcrun", "simctl", "list", "runtimes", "-j"]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)

            import json

            data = json.loads(result.stdout)
            runtimes = []

            for runtime in data.get("runtimes", []):
                # Only include iOS runtimes (skip watchOS, tvOS, etc.)
                identifier = runtime.get("identifier", "")
                if "iOS" in identifier or "iOS" in runtime.get("name", ""):
                    runtimes.append(
                        {
                            "name": runtime.get("name", ""),
                            "identifier": runtime.get("identifier", ""),
                        }
                    )

            # Sort by version number (latest first)
            runtimes.sort(key=lambda r: r.get("identifier", ""), reverse=True)

            return runtimes
        except Exception:
            return []

    @staticmethod
    def list_device_types() -> list[dict]:
        """
        List all available device types.

        Returns:
            List of device types with name and identifier
        """
        return SimulatorCreator._get_device_types()

    @staticmethod
    def list_runtimes() -> list[dict]:
        """
        List all available iOS runtimes.

        Returns:
            List of runtimes with name and identifier
        """
        return SimulatorCreator._get_runtimes()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Create iOS simulators dynamically")
    parser.add_argument(
        "--device",
        required=False,
        help="Device type (e.g., 'iPhone 16 Pro', 'iPad Air')",
    )
    parser.add_argument(
        "--runtime",
        help="iOS version (e.g., '18.0', '17.0'). Defaults to latest.",
    )
    parser.add_argument(
        "--name",
        help="Custom device name. Defaults to auto-generated.",
    )
    parser.add_argument(
        "--list-devices",
        action="store_true",
        help="List all available device types",
    )
    parser.add_argument(
        "--list-runtimes",
        action="store_true",
        help="List all available iOS runtimes",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON",
    )

    args = parser.parse_args()

    creator = SimulatorCreator()

    # Handle info queries
    if args.list_devices:
        devices = creator.list_device_types()
        if args.json:
            import json

            print(json.dumps({"devices": devices}))
        else:
            print(f"Available device types ({len(devices)}):")
            for dev in devices[:20]:  # Show first 20
                print(f"  - {dev['name']}")
            if len(devices) > 20:
                print(f"  ... and {len(devices) - 20} more")
        sys.exit(0)

    if args.list_runtimes:
        runtimes = creator.list_runtimes()
        if args.json:
            import json

            print(json.dumps({"runtimes": runtimes}))
        else:
            print(f"Available iOS runtimes ({len(runtimes)}):")
            for rt in runtimes:
                print(f"  - {rt['name']}")
        sys.exit(0)

    # Create device
    if not args.device:
        print(
            "Error: Specify --device, --list-devices, or --list-runtimes",
            file=sys.stderr,
        )
        sys.exit(1)

    success, message, new_udid = creator.create(
        device_type=args.device,
        ios_version=args.runtime,
        custom_name=args.name,
    )

    if args.json:
        import json

        print(
            json.dumps(
                {
                    "action": "create",
                    "device_type": args.device,
                    "runtime": args.runtime,
                    "success": success,
                    "message": message,
                    "new_udid": new_udid,
                }
            )
        )
    else:
        print(message)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
