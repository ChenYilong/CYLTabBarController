#!/usr/bin/env python3
"""
iOS Simulator Media Manager

Seed or empty the photo library so photo-picker flows start from a known state.

Adding uses simctl addmedia (Apple-maintained, no companion needed). Clearing uses
`idb photos clear` (idb 1.7+) because simctl has no way to remove media. With both
flags, the library is cleared first, so it ends up holding exactly the added files.

Usage:
  python scripts/media.py --add photo1.jpg photo2.png
  python scripts/media.py --clear --yes
  python scripts/media.py --clear --yes --add fixtures/*.jpg --json
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

from common import (
    build_idb_command,
    build_simctl_command,
    refuse_without_yes,
    resolve_udid,
    run_idb,
    with_idb_upgrade_hint,
)

SIMULATOR_DEVICES_DIR = Path.home() / "Library/Developer/CoreSimulator/Devices"
PHOTO_SUFFIXES = {".jpg", ".jpeg", ".png", ".heic", ".gif", ".mov", ".mp4"}

# === MEDIA MANAGER ===


class MediaManager:
    """Adds media to, and clears media from, an iOS simulator photo library."""

    def __init__(self, udid: str | None = None):
        """Initialize media manager.

        Args:
            udid: Optional device UDID (auto-detects booted simulator if None)
        """
        self.udid = udid

    # === PUBLIC API ===

    def add(self, paths: list[str]) -> tuple[bool, str]:
        """
        Add photos, videos, or contacts (vCard) to the photo library.

        Args:
            paths: Media files to add (all must exist)

        Returns:
            (success, message)
        """
        missing = [path for path in paths if not Path(path).is_file()]
        if missing:
            return False, f"File not found: {', '.join(missing)}"

        cmd = build_simctl_command("addmedia", self.udid, *paths)
        try:
            subprocess.run(cmd, capture_output=True, text=True, check=True)
        except subprocess.CalledProcessError as e:
            return False, (e.stderr or "").strip() or f"simctl exited with status {e.returncode}"
        return True, f"Added {len(paths)} file(s) to photo library"

    def clear(self) -> tuple[bool, str]:
        """
        Remove every photo and video from the library (idb 1.7+).

        Returns:
            (success, message)
        """
        ok, error = run_idb(build_idb_command("photos clear", self.udid))
        if not ok:
            return False, with_idb_upgrade_hint(error)
        return True, "Photo library cleared"

    def photo_count(self) -> int | None:
        """Photos and videos in the library, or None when it can't be found on disk."""
        if not self.udid:
            return None
        dcim = SIMULATOR_DEVICES_DIR / self.udid / "data/Media/DCIM"
        if not dcim.is_dir():
            return None
        return sum(1 for path in dcim.rglob("*") if path.suffix.lower() in PHOTO_SUFFIXES)


def clear_refusal(manager: MediaManager, is_confirmed: bool) -> str | None:
    """
    Why --clear must not run yet, or None when it may.

    Clearing an empty library loses nothing, so it needs no confirmation.
    """
    if is_confirmed:
        return None
    count = manager.photo_count()
    if count == 0:
        return None
    lost = "the photo library" if count is None else f"{count} photo(s)"
    return refuse_without_yes(f"delete {lost} on {manager.udid}")


# === CLI ===


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="iOS Simulator Media Manager - seed or empty the photo library.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/media.py --add photo1.jpg photo2.png
  python scripts/media.py --clear --yes
  python scripts/media.py --clear --yes --add fixtures/*.jpg   # library = exactly these files

--clear needs idb 1.7+ (brew upgrade facebook/fb/idb-cli facebook/fb/idb-companion).
        """,
    )
    parser.add_argument("--add", nargs="+", metavar="FILE", help="Photos/videos/vCards to add")
    parser.add_argument(
        "--clear", action="store_true", help="Empty the photo library first (needs --yes)"
    )
    parser.add_argument(
        "--yes", action="store_true", help="Confirm --clear: deleted photos can't be recovered"
    )
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )
    parser.add_argument("--json", action="store_true", help="Output results as JSON")

    args = parser.parse_args()

    if not (args.add or args.clear):
        parser.print_help()
        sys.exit(1)

    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    manager = MediaManager(udid=udid)
    refusal = clear_refusal(manager, args.yes) if args.clear else None
    if refusal:
        print(refusal, file=sys.stderr)
        sys.exit(1)

    operations: list[tuple[str, tuple[bool, str]]] = []

    if args.clear:
        operations.append(("clear", manager.clear()))
    # Never add into a library we failed to clear - the result would be ambiguous
    if args.add and all(ok for _, (ok, _) in operations):
        operations.append(("add", manager.add(args.add)))

    overall_success = all(ok for _, (ok, _) in operations)

    if args.json:
        results = {action: {"success": ok, "message": msg} for action, (ok, msg) in operations}
        print(json.dumps({"success": overall_success, "udid": udid, "results": results}))
    else:
        for action, (ok, msg) in operations:
            print(msg if ok else f"Error ({action}): {msg}", file=sys.stdout if ok else sys.stderr)

    sys.exit(0 if overall_success else 1)


if __name__ == "__main__":
    main()
