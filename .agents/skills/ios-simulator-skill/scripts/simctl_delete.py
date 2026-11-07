#!/usr/bin/env python3
"""
Delete iOS simulators permanently.

This script permanently removes simulators and frees disk space.
Refuses without --yes, since a deletion can't be undone (AGENTS.md Principle 10).

Key features:
- Delete by UDID or device name
- Refuses without --yes (no interactive prompt: agents can't answer one)
- Batch delete operations
- Report freed disk space estimate
"""

import argparse
import subprocess
import sys
from typing import Optional

from common.device_utils import (
    list_simulators,
    refuse_without_yes,
    resolve_device_identifier,
)


class SimulatorDeleter:
    """Delete iOS simulators."""

    def __init__(self, udid: str | None = None):
        """Initialize with optional device UDID."""
        self.udid = udid

    def delete(self) -> tuple[bool, str]:
        """
        Delete simulator permanently.

        Returns:
            (success, message) tuple
        """
        if not self.udid:
            return False, "Error: Device UDID not specified"

        # Execute delete command
        try:
            cmd = ["xcrun", "simctl", "delete", self.udid]
            result = subprocess.run(cmd, check=False, capture_output=True, text=True, timeout=60)

            if result.returncode != 0:
                error = result.stderr.strip() or result.stdout.strip()
                return False, f"Deletion failed: {error}"

            return True, f"Device deleted: {self.udid} [disk space freed]"

        except subprocess.TimeoutExpired:
            return False, "Deletion command timed out"
        except Exception as e:
            return False, f"Deletion error: {e}"

    @staticmethod
    def delete_all() -> tuple[int, int]:
        """
        Delete all simulators permanently.

        Returns:
            (succeeded, failed) tuple with counts
        """
        simulators = list_simulators(state=None)

        succeeded = 0
        failed = 0

        for sim in simulators:
            deleter = SimulatorDeleter(udid=sim["udid"])
            success, _message = deleter.delete()
            if success:
                succeeded += 1
            else:
                failed += 1

        return succeeded, failed

    @staticmethod
    def delete_by_type(device_type: str) -> tuple[int, int]:
        """
        Delete all simulators of a specific type.

        Args:
            device_type: Device type filter (e.g., "iPhone", "iPad")

        Returns:
            (succeeded, failed) tuple with counts
        """
        simulators = list_simulators(state=None)
        matching = [s for s in simulators if device_type.lower() in s["name"].lower()]

        if not matching:
            return 0, 0

        succeeded = 0
        failed = 0

        for sim in matching:
            deleter = SimulatorDeleter(udid=sim["udid"])
            success, _message = deleter.delete()
            if success:
                succeeded += 1
            else:
                failed += 1

        return succeeded, failed

    @staticmethod
    def delete_old(keep_count: int = 3) -> tuple[int, int]:
        """
        Delete older simulators, keeping most recent versions.

        Useful for cleanup after testing multiple iOS versions.
        Keeps the most recent N simulators of each type.

        Args:
            keep_count: Number of recent simulators to keep per type (default: 3)

        Returns:
            (succeeded, failed) tuple with counts
        """
        simulators = list_simulators(state=None)

        # Group by device type
        by_type: dict[str, list] = {}
        for sim in simulators:
            dev_type = sim["type"]
            if dev_type not in by_type:
                by_type[dev_type] = []
            by_type[dev_type].append(sim)

        # Find candidates for deletion (older ones)
        to_delete = []
        for _dev_type, sims in by_type.items():
            # Sort by runtime (iOS version) - keep newest
            sorted_sims = sorted(sims, key=lambda s: s["runtime"], reverse=True)
            # Mark older ones for deletion
            to_delete.extend(sorted_sims[keep_count:])

        if not to_delete:
            return 0, 0

        succeeded = 0
        failed = 0

        for sim in to_delete:
            deleter = SimulatorDeleter(udid=sim["udid"])
            success, _message = deleter.delete()
            if success:
                succeeded += 1
            else:
                failed += 1

        return succeeded, failed


def describe_deletion(args: argparse.Namespace) -> str | None:
    """What this invocation would delete, for the --yes refusal; None if it names no target."""
    if args.all:
        return "delete all simulators and their data"
    if args.type:
        return f"delete every {args.type} simulator and its data"
    if args.old is not None:
        return f"delete older simulators and their data (keeping {args.old} per type)"
    device_id = args.udid or args.name
    return f"delete {device_id} and all its data" if device_id else None


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Delete iOS simulators permanently")
    parser.add_argument(
        "--udid",
        help="Device UDID or name (required unless using batch options)",
    )
    parser.add_argument(
        "--name",
        help="Device name (alternative to --udid)",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Confirm the deletion: the simulator and all its data can't be recovered",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Delete all simulators",
    )
    parser.add_argument(
        "--type",
        help="Delete all simulators of a specific type (e.g., iPhone)",
    )
    parser.add_argument(
        "--old",
        type=int,
        metavar="KEEP_COUNT",
        help="Delete older simulators, keeping this many per type (e.g., --old 3)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON",
    )

    args = parser.parse_args()

    target = describe_deletion(args)
    if target and not args.yes:
        print(refuse_without_yes(target), file=sys.stderr)
        sys.exit(1)

    # Handle batch operations
    if args.all:
        succeeded, failed = SimulatorDeleter.delete_all()
        if args.json:
            import json

            print(
                json.dumps(
                    {
                        "action": "delete_all",
                        "succeeded": succeeded,
                        "failed": failed,
                        "total": succeeded + failed,
                    }
                )
            )
        else:
            total = succeeded + failed
            print(f"Delete summary: {succeeded}/{total} succeeded, " f"{failed} failed")
        sys.exit(0 if failed == 0 else 1)

    if args.type:
        succeeded, failed = SimulatorDeleter.delete_by_type(args.type)
        if args.json:
            import json

            print(
                json.dumps(
                    {
                        "action": "delete_by_type",
                        "type": args.type,
                        "succeeded": succeeded,
                        "failed": failed,
                        "total": succeeded + failed,
                    }
                )
            )
        else:
            total = succeeded + failed
            print(f"Delete {args.type} summary: {succeeded}/{total} succeeded, " f"{failed} failed")
        sys.exit(0 if failed == 0 else 1)

    if args.old is not None:
        succeeded, failed = SimulatorDeleter.delete_old(keep_count=args.old)
        if args.json:
            import json

            print(
                json.dumps(
                    {
                        "action": "delete_old",
                        "keep_count": args.old,
                        "succeeded": succeeded,
                        "failed": failed,
                        "total": succeeded + failed,
                    }
                )
            )
        else:
            total = succeeded + failed
            print(
                f"Delete old summary: {succeeded}/{total} succeeded, "
                f"{failed} failed (kept {args.old} per type)"
            )
        sys.exit(0 if failed == 0 else 1)

    # Delete single device
    device_id = args.udid or args.name
    if not device_id:
        print("Error: Specify --udid, --name, --all, --type, or --old", file=sys.stderr)
        sys.exit(1)

    try:
        udid = resolve_device_identifier(device_id)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    # Delete device
    deleter = SimulatorDeleter(udid=udid)
    success, message = deleter.delete()

    if args.json:
        import json

        print(
            json.dumps(
                {
                    "action": "delete",
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
