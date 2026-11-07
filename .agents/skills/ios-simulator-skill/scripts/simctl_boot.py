#!/usr/bin/env python3
"""
Boot iOS simulators and wait for readiness.

This script boots one or more simulators and optionally waits for them to reach
a ready state. It measures boot time and provides progress feedback.

Key features:
- Boot by UDID or device name
- Wait for device readiness with configurable timeout
- Measure boot performance
- Batch boot operations (boot all, boot by type)
- Progress reporting for CI/CD pipelines
"""

import argparse
import subprocess
import sys
import time

from common.device_utils import (
    get_booted_device_udid,
    list_simulators,
    resolve_device_identifier,
)
from common.env_config import env_float, env_int

DEFAULT_BOOT_TIMEOUT = env_int("IOS_SIM_BOOT_TIMEOUT", 300)
BOOT_SUBPROCESS_TIMEOUT = env_int("IOS_SIM_BOOT_SUBPROCESS_TIMEOUT", 60)
POLL_INTERVAL_SECONDS = env_float("IOS_SIM_POLL_INTERVAL", 0.5, min_value=0.05)


class SimulatorBooter:
    """Boot iOS simulators with optional readiness waiting."""

    def __init__(self, udid: str | None = None):
        """Initialize booter with optional device UDID."""
        self.udid = udid

    def boot(
        self, wait_ready: bool = False, timeout_seconds: int = DEFAULT_BOOT_TIMEOUT
    ) -> tuple[bool, str]:
        """
        Boot simulator and optionally wait for readiness.

        Args:
            wait_ready: Wait for device to be ready before returning
            timeout_seconds: Maximum seconds to wait for readiness

        Returns:
            (success, message) tuple
        """
        if not self.udid:
            return False, "Error: Device UDID not specified"

        start_time = time.time()

        # Check if already booted
        try:
            booted = get_booted_device_udid()
            if booted == self.udid:
                elapsed = time.time() - start_time
                return True, (f"Device already booted: {self.udid} " f"[checked in {elapsed:.1f}s]")
        except RuntimeError:
            pass  # No booted device, proceed with boot

        # Execute boot command
        try:
            cmd = ["xcrun", "simctl", "boot", self.udid]
            result = subprocess.run(
                cmd,
                check=False,
                capture_output=True,
                text=True,
                timeout=BOOT_SUBPROCESS_TIMEOUT,
            )

            if result.returncode != 0:
                error = result.stderr.strip()
                return False, f"Boot failed: {error}"
        except subprocess.TimeoutExpired:
            return False, "Boot command timed out"
        except Exception as e:
            return False, f"Boot error: {e}"

        # Optionally wait for readiness
        if wait_ready:
            ready, wait_message = self._wait_for_ready(timeout_seconds)
            elapsed = time.time() - start_time
            if ready:
                return True, (f"Device booted and ready: {self.udid} " f"[{elapsed:.1f}s total]")
            return False, wait_message

        elapsed = time.time() - start_time
        return True, (
            f"Device booted: {self.udid} [boot in {elapsed:.1f}s] "
            "(use --wait-ready to wait for availability)"
        )

    def _wait_for_ready(self, timeout_seconds: int = DEFAULT_BOOT_TIMEOUT) -> tuple[bool, str]:
        """
        Wait for device to reach ready state.

        Args:
            timeout_seconds: Maximum seconds to wait

        Returns:
            (success, message) tuple
        """
        start_time = time.time()
        poll_interval = POLL_INTERVAL_SECONDS
        checks = 0

        while time.time() - start_time < timeout_seconds:
            try:
                checks += 1
                # Check if device responds to simctl commands
                result = subprocess.run(
                    ["xcrun", "simctl", "spawn", self.udid, "launchctl", "list"],
                    check=False,
                    capture_output=True,
                    text=True,
                    timeout=5,
                )

                if result.returncode == 0:
                    elapsed = time.time() - start_time
                    return True, (
                        f"Device ready: {self.udid} " f"[{elapsed:.1f}s, {checks} checks]"
                    )
            except (subprocess.TimeoutExpired, RuntimeError):
                pass  # Not ready yet

            time.sleep(poll_interval)

        elapsed = time.time() - start_time
        return False, (
            f"Boot timeout: Device did not reach ready state "
            f"within {elapsed:.1f}s ({checks} checks)"
        )

    @staticmethod
    def boot_all() -> tuple[int, int]:
        """
        Boot all available simulators.

        Returns:
            (succeeded, failed) tuple with counts
        """
        simulators = list_simulators(state="available")
        succeeded = 0
        failed = 0

        for sim in simulators:
            booter = SimulatorBooter(udid=sim["udid"])
            success, _message = booter.boot(wait_ready=False)
            if success:
                succeeded += 1
            else:
                failed += 1

        return succeeded, failed

    @staticmethod
    def boot_by_type(device_type: str) -> tuple[int, int]:
        """
        Boot all simulators of a specific type.

        Args:
            device_type: Device type filter (e.g., "iPhone", "iPad")

        Returns:
            (succeeded, failed) tuple with counts
        """
        simulators = list_simulators(state="available")
        succeeded = 0
        failed = 0

        for sim in simulators:
            if device_type.lower() in sim["name"].lower():
                booter = SimulatorBooter(udid=sim["udid"])
                success, _message = booter.boot(wait_ready=False)
                if success:
                    succeeded += 1
                else:
                    failed += 1

        return succeeded, failed


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Boot iOS simulators and wait for readiness")
    parser.add_argument(
        "--udid",
        help="Device UDID or name (required unless using --all or --type)",
    )
    parser.add_argument(
        "--name",
        help="Device name (alternative to --udid)",
    )
    parser.add_argument(
        "--wait-ready",
        action="store_true",
        help="Wait for device to reach ready state",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_BOOT_TIMEOUT,
        help=(
            f"Timeout for --wait-ready in seconds "
            f"(default: {DEFAULT_BOOT_TIMEOUT}, override via IOS_SIM_BOOT_TIMEOUT)"
        ),
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Boot all available simulators",
    )
    parser.add_argument(
        "--type",
        help="Boot all simulators of a specific type (e.g., iPhone, iPad)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON",
    )

    args = parser.parse_args()

    # Handle batch operations
    if args.all:
        succeeded, failed = SimulatorBooter.boot_all()
        if args.json:
            import json

            print(
                json.dumps(
                    {
                        "action": "boot_all",
                        "succeeded": succeeded,
                        "failed": failed,
                        "total": succeeded + failed,
                    }
                )
            )
        else:
            total = succeeded + failed
            print(f"Boot summary: {succeeded}/{total} succeeded, " f"{failed} failed")
        sys.exit(0 if failed == 0 else 1)

    if args.type:
        succeeded, failed = SimulatorBooter.boot_by_type(args.type)
        if args.json:
            import json

            print(
                json.dumps(
                    {
                        "action": "boot_by_type",
                        "type": args.type,
                        "succeeded": succeeded,
                        "failed": failed,
                        "total": succeeded + failed,
                    }
                )
            )
        else:
            total = succeeded + failed
            print(f"Boot {args.type} summary: {succeeded}/{total} succeeded, " f"{failed} failed")
        sys.exit(0 if failed == 0 else 1)

    # Resolve device identifier
    device_id = args.udid or args.name
    if not device_id:
        print("Error: Specify --udid, --name, --all, or --type", file=sys.stderr)
        sys.exit(1)

    try:
        udid = resolve_device_identifier(device_id)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Boot device
    booter = SimulatorBooter(udid=udid)
    success, message = booter.boot(wait_ready=args.wait_ready, timeout_seconds=args.timeout)

    if args.json:
        import json

        print(
            json.dumps(
                {
                    "action": "boot",
                    "device_id": device_id,
                    "udid": udid,
                    "success": success,
                    "message": message,
                }
            )
        )
    else:
        print(message)

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
