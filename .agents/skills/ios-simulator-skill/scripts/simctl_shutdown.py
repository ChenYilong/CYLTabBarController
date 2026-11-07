#!/usr/bin/env python3
"""
Shutdown iOS simulators with optional state verification.

This script shuts down one or more running simulators and optionally
verifies completion. Supports batch operations for efficient cleanup.

Key features:
- Shutdown by UDID or device name
- Verify shutdown completion with timeout
- Batch shutdown operations (all, by type)
- Progress reporting for CI/CD pipelines
"""

import argparse
import subprocess
import sys
import time
from typing import Optional

from common.device_utils import (
    list_simulators,
    resolve_device_identifier,
)


class SimulatorShutdown:
    """Shutdown iOS simulators with optional verification."""

    def __init__(self, udid: str | None = None):
        """Initialize with optional device UDID."""
        self.udid = udid

    def shutdown(self, verify: bool = True, timeout_seconds: int = 30) -> tuple[bool, str]:
        """
        Shutdown simulator and optionally verify completion.

        Args:
            verify: Wait for shutdown to complete
            timeout_seconds: Maximum seconds to wait for shutdown

        Returns:
            (success, message) tuple
        """
        if not self.udid:
            return False, "Error: Device UDID not specified"

        start_time = time.time()

        # Check if already shutdown
        simulators = list_simulators(state="booted")
        if not any(s["udid"] == self.udid for s in simulators):
            elapsed = time.time() - start_time
            return True, (f"Device already shutdown: {self.udid} " f"[checked in {elapsed:.1f}s]")

        # Execute shutdown command
        try:
            cmd = ["xcrun", "simctl", "shutdown", self.udid]
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=30)

            if result.returncode != 0:
                error = result.stderr.strip()
                return False, f"Shutdown failed: {error}"
        except subprocess.TimeoutExpired:
            return False, "Shutdown command timed out"
        except Exception as e:
            return False, f"Shutdown error: {e}"

        # Optionally verify shutdown
        if verify:
            ready, verify_message = self._verify_shutdown(timeout_seconds)
            elapsed = time.time() - start_time
            if ready:
                return True, (f"Device shutdown confirmed: {self.udid} " f"[{elapsed:.1f}s total]")
            return False, verify_message

        elapsed = time.time() - start_time
        return True, (
            f"Device shutdown: {self.udid} [{elapsed:.1f}s] "
            "(use --verify to wait for confirmation)"
        )

    def _verify_shutdown(self, timeout_seconds: int = 30) -> tuple[bool, str]:
        """
        Verify device has fully shutdown.

        Args:
            timeout_seconds: Maximum seconds to wait

        Returns:
            (success, message) tuple
        """
        start_time = time.time()
        poll_interval = 0.5
        checks = 0

        while time.time() - start_time < timeout_seconds:
            try:
                checks += 1
                # Check booted devices
                simulators = list_simulators(state="booted")
                if not any(s["udid"] == self.udid for s in simulators):
                    elapsed = time.time() - start_time
                    return True, (
                        f"Device shutdown verified: {self.udid} "
                        f"[{elapsed:.1f}s, {checks} checks]"
                    )
            except RuntimeError:
                pass  # Error checking, retry

            time.sleep(poll_interval)

        elapsed = time.time() - start_time
        return False, (
            f"Shutdown verification timeout: Device did not fully shutdown "
            f"within {elapsed:.1f}s ({checks} checks)"
        )

    @staticmethod
    def shutdown_all() -> tuple[int, int]:
        """
        Shutdown all booted simulators.

        Returns:
            (succeeded, failed) tuple with counts
        """
        simulators = list_simulators(state="booted")
        succeeded = 0
        failed = 0

        for sim in simulators:
            shutdown = SimulatorShutdown(udid=sim["udid"])
            success, _message = shutdown.shutdown(verify=False)
            if success:
                succeeded += 1
            else:
                failed += 1

        return succeeded, failed

    @staticmethod
    def shutdown_by_type(device_type: str) -> tuple[int, int]:
        """
        Shutdown all booted simulators of a specific type.

        Args:
            device_type: Device type filter (e.g., "iPhone", "iPad")

        Returns:
            (succeeded, failed) tuple with counts
        """
        simulators = list_simulators(state="booted")
        succeeded = 0
        failed = 0

        for sim in simulators:
            if device_type.lower() in sim["name"].lower():
                shutdown = SimulatorShutdown(udid=sim["udid"])
                success, _message = shutdown.shutdown(verify=False)
                if success:
                    succeeded += 1
                else:
                    failed += 1

        return succeeded, failed


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Shutdown iOS simulators with optional verification"
    )
    parser.add_argument(
        "--udid",
        help="Device UDID or name (required unless using --all or --type)",
    )
    parser.add_argument(
        "--name",
        help="Device name (alternative to --udid)",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Wait for shutdown to complete and verify state",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="Timeout for --verify in seconds (default: 30)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Shutdown all booted simulators",
    )
    parser.add_argument(
        "--type",
        help="Shutdown all booted simulators of a specific type (e.g., iPhone)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON",
    )

    args = parser.parse_args()

    # Handle batch operations
    if args.all:
        succeeded, failed = SimulatorShutdown.shutdown_all()
        if args.json:
            import json

            print(
                json.dumps(
                    {
                        "action": "shutdown_all",
                        "succeeded": succeeded,
                        "failed": failed,
                        "total": succeeded + failed,
                    }
                )
            )
        else:
            total = succeeded + failed
            print(f"Shutdown summary: {succeeded}/{total} succeeded, " f"{failed} failed")
        sys.exit(0 if failed == 0 else 1)

    if args.type:
        succeeded, failed = SimulatorShutdown.shutdown_by_type(args.type)
        if args.json:
            import json

            print(
                json.dumps(
                    {
                        "action": "shutdown_by_type",
                        "type": args.type,
                        "succeeded": succeeded,
                        "failed": failed,
                        "total": succeeded + failed,
                    }
                )
            )
        else:
            total = succeeded + failed
            print(
                f"Shutdown {args.type} summary: {succeeded}/{total} succeeded, " f"{failed} failed"
            )
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

    # Shutdown device
    shutdown = SimulatorShutdown(udid=udid)
    success, message = shutdown.shutdown(verify=args.verify, timeout_seconds=args.timeout)

    if args.json:
        import json

        print(
            json.dumps(
                {
                    "action": "shutdown",
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
