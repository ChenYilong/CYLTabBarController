#!/usr/bin/env python3
"""
App sandbox / UserDefaults / Core Data inspector for iOS simulators.

Wraps `xcrun simctl get_app_container` to provide semantic access to an
app's data container — no manual CoreSimulator directory archaeology needed.

Key features:
- List files in the app data container (--ls)
- Read a file from the container (--cat, with progressive cache for large files)
- Inspect UserDefaults as JSON or key=value (--userdefaults)
- Locate Core Data stores (--core-data-path)
- Export the full data container (--export)
- JSON output mode (--json) and auto-UDID detection

Keychain is explicitly out of scope — requires entitlements and is risky.
"""

import argparse
import contextlib
import json
import os
import plistlib
import shutil
import subprocess
import sys
from decimal import Decimal
from pathlib import Path

from common.cache_utils import ProgressiveCache
from common.device_utils import resolve_device_identifier


def _env_int(name: str, default: int, *, min_value: int = 0) -> int:
    """Read an integer from the environment with a minimum clamp."""
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        return max(min_value, int(raw))
    except ValueError:
        return default


# Threshold in bytes above which --cat output is cached instead of printed inline
_CAT_CACHE_THRESHOLD_BYTES = _env_int("IOS_SIM_CAT_CACHE_BYTES", 8_192, min_value=512)


class ContainerInspector:
    """Inspect an app's data sandbox on an iOS simulator."""

    def __init__(self, udid: str | None = None):
        """Initialize inspector with optional device UDID.

        Args:
            udid: Simulator UDID (uses booted device if None)
        """
        self.udid = udid
        self._cache = ProgressiveCache()

    # === PUBLIC API ===

    def get_container_path(self, bundle_id: str) -> tuple[bool, str]:
        """Resolve the data container root for a bundle ID.

        Args:
            bundle_id: App bundle identifier (e.g. com.example.app)

        Returns:
            (success, path_or_error_message)
        """
        device = self.udid or "booted"
        try:
            result = subprocess.run(
                ["xcrun", "simctl", "get_app_container", device, bundle_id, "data"],
                check=False,
                capture_output=True,
                text=True,
                timeout=15,
            )
        except subprocess.TimeoutExpired:
            return False, "get_app_container timed out"
        except Exception as e:
            return False, f"get_app_container error: {e}"

        if result.returncode != 0:
            error = result.stderr.strip() or f"exit code {result.returncode}"
            return False, f"Cannot find container for {bundle_id}: {error}"

        container_path = result.stdout.strip()
        if not container_path:
            return False, f"No data container found for {bundle_id}"

        return True, container_path

    def list_files(
        self,
        bundle_id: str,
        relative_path: str = "",
        max_depth: int = 3,
    ) -> tuple[bool, dict]:
        """List files in the app's data container.

        Args:
            bundle_id: App bundle identifier
            relative_path: Sub-path within container (default: container root)
            max_depth: Recursive listing depth (default: 3)

        Returns:
            (success, result_dict) where result_dict contains 'path', 'entries'
        """
        ok, container = self.get_container_path(bundle_id)
        if not ok:
            return False, {"error": container}

        container_resolved = Path(container).resolve()
        target = container_resolved
        if relative_path:
            target = (container_resolved / relative_path).resolve()
            if not target.is_relative_to(container_resolved):
                return False, {"error": f"Path escapes container boundary: {relative_path}"}

        if not target.exists():
            return False, {"error": f"Path does not exist: {target}"}

        if target.is_file():
            return True, {
                "path": str(target),
                "entries": [_describe_path(target, Path(container))],
                "total_files": 1,
            }

        entries = _walk_directory(target, Path(container), current_depth=0, max_depth=max_depth)
        return True, {
            "bundle_id": bundle_id,
            "container_root": container,
            "listed_path": str(target),
            "max_depth": max_depth,
            "entries": entries,
            "total_entries": len(entries),
        }

    def cat_file(self, bundle_id: str, relative_path: str) -> tuple[bool, dict]:
        """Read a file from the container.

        Large files (> 8 KB) are stored in ProgressiveCache and a cache_id is
        returned instead of the raw content — matching the pattern used by
        build_and_test.py and log_monitor.py.

        Args:
            bundle_id: App bundle identifier
            relative_path: Path relative to container root

        Returns:
            (success, result_dict) with 'content' or 'cache_id' key
        """
        ok, container = self.get_container_path(bundle_id)
        if not ok:
            return False, {"error": container}

        container_resolved = Path(container).resolve()
        file_path = (container_resolved / relative_path).resolve()
        if not file_path.is_relative_to(container_resolved):
            return False, {"error": f"Path escapes container boundary: {relative_path}"}
        if not file_path.exists():
            return False, {"error": f"File not found: {file_path}"}

        if file_path.is_dir():
            return False, {"error": f"Path is a directory — use --ls instead: {relative_path}"}

        if file_path.is_symlink() and not file_path.resolve().exists():
            return False, {"error": f"Broken symlink: {relative_path}"}

        try:
            file_bytes = file_path.read_bytes()
        except OSError as exc:
            return False, {"error": f"Cannot read file: {exc}"}

        size_bytes = len(file_bytes)

        # Attempt plist decode first (handles both binary and XML plists)
        plist_data, is_plist = _try_parse_plist(file_bytes)

        if is_plist:
            content = plist_data
            content_type = "plist"
        else:
            # Try UTF-8 text; fall back to hex summary for binary blobs
            try:
                content = file_bytes.decode("utf-8")
                content_type = "text"
            except UnicodeDecodeError:
                content = f"<binary file: {size_bytes} bytes — use --export to retrieve>"
                content_type = "binary"

        base_result = {
            "bundle_id": bundle_id,
            "path": relative_path,
            "size_bytes": size_bytes,
            "content_type": content_type,
        }

        # Cache large text / plist content
        if size_bytes > _CAT_CACHE_THRESHOLD_BYTES and content_type != "binary":
            cache_data = {**base_result, "content": content}
            cache_id = self._cache.save(cache_data, "container-cat")
            return True, {
                **base_result,
                "cache_id": cache_id,
                "note": (
                    f"File is {size_bytes:,} bytes — full content cached. "
                    f"Retrieve with cache_id '{cache_id}'."
                ),
            }

        return True, {**base_result, "content": content}

    def read_userdefaults(self, bundle_id: str) -> tuple[bool, dict]:
        """Read UserDefaults plist for the app.

        Looks in Library/Preferences/<bundle_id>.plist (both binary and XML
        formats are handled via stdlib plistlib).

        Args:
            bundle_id: App bundle identifier

        Returns:
            (success, result_dict) with 'preferences' key containing decoded data
        """
        ok, container = self.get_container_path(bundle_id)
        if not ok:
            return False, {"error": container}

        plist_path = Path(container) / "Library" / "Preferences" / f"{bundle_id}.plist"

        if not plist_path.exists():
            return False, {
                "error": (
                    f"UserDefaults plist not found: {plist_path}. "
                    "The app may not have written any defaults yet."
                )
            }

        try:
            raw_bytes = plist_path.read_bytes()
        except OSError as exc:
            return False, {"error": f"Cannot read plist: {exc}"}

        plist_data, is_plist = _try_parse_plist(raw_bytes)
        if not is_plist:
            return False, {"error": f"File is not a valid plist: {plist_path}"}

        return True, {
            "bundle_id": bundle_id,
            "plist_path": str(plist_path),
            "preferences": plist_data,
            "total_keys": len(plist_data) if isinstance(plist_data, dict) else None,
        }

    def find_core_data_paths(self, bundle_id: str) -> tuple[bool, dict]:
        """Locate Core Data SQLite stores in the container.

        Searches Library/Application Support/ and Documents/ for *.sqlite,
        *.sqlite-wal, and *.sqlite-shm files. Paths are reported only — no
        file opening occurs.

        Args:
            bundle_id: App bundle identifier

        Returns:
            (success, result_dict) with 'stores' list
        """
        ok, container = self.get_container_path(bundle_id)
        if not ok:
            return False, {"error": container}

        container_path = Path(container)
        search_dirs = [
            container_path / "Library" / "Application Support",
            container_path / "Documents",
        ]

        stores: list[dict] = []
        sqlite_extensions = {".sqlite", ".sqlite-wal", ".sqlite-shm"}

        for search_dir in search_dirs:
            if not search_dir.exists():
                continue
            for file_path in search_dir.rglob("*"):
                if file_path.suffix.lower() in sqlite_extensions and file_path.is_file():
                    relative = str(file_path.relative_to(container_path))
                    size_bytes = file_path.stat().st_size
                    stores.append(
                        {
                            "path": relative,
                            "absolute_path": str(file_path),
                            "size_bytes": size_bytes,
                            "type": _classify_sqlite_file(file_path.name),
                        }
                    )

        return True, {
            "bundle_id": bundle_id,
            "container_root": container,
            "stores": stores,
            "total_stores": len(stores),
        }

    def export_container(self, bundle_id: str, dest_dir: str) -> tuple[bool, dict]:
        """Copy the full data container to dest_dir.

        Uses shutil.copytree with symlinks=True to preserve symlink structure.
        Keychain is not included — it is not part of the data container path.

        Args:
            bundle_id: App bundle identifier
            dest_dir: Destination directory (will be created if absent)

        Returns:
            (success, result_dict) with 'destination' and 'size_bytes'
        """
        ok, container = self.get_container_path(bundle_id)
        if not ok:
            return False, {"error": container}

        dest = Path(dest_dir)
        target = dest / bundle_id

        if target.exists():
            return False, {
                "error": (
                    f"Destination already exists: {target}. "
                    "Remove it or choose a different path."
                )
            }

        dest.mkdir(parents=True, exist_ok=True)

        try:
            shutil.copytree(
                container,
                str(target),
                symlinks=True,
                ignore_dangling_symlinks=True,
            )
        except shutil.Error as exc:
            return False, {"error": f"Export failed: {exc}"}
        except OSError as exc:
            return False, {"error": f"Export OS error: {exc}"}

        total_size = _directory_size_bytes(target)

        return True, {
            "bundle_id": bundle_id,
            "source": container,
            "destination": str(target),
            "size_bytes": total_size,
            "size_human": _human_bytes(total_size),
        }


# === PRIVATE HELPERS ===


def _try_parse_plist(data: bytes) -> tuple[dict | list | None, bool]:
    """Attempt to parse bytes as a plist (binary or XML).

    Args:
        data: Raw file bytes

    Returns:
        (parsed_data, is_plist) — parsed_data is None if not a valid plist
    """
    try:
        parsed = plistlib.loads(data)
        return _make_json_serializable(parsed), True
    except Exception:
        return None, False


def _make_json_serializable(obj):
    """Recursively convert plist types to JSON-serializable equivalents.

    Handles bytes (→ hex string), sets (→ list), and datetime (→ ISO string).
    """
    if isinstance(obj, dict):
        return {k: _make_json_serializable(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_make_json_serializable(i) for i in obj]
    if isinstance(obj, bytes):
        return obj.hex()
    if isinstance(obj, set):
        return sorted(_make_json_serializable(i) for i in obj)
    if isinstance(obj, Decimal):
        return float(obj)
    # datetime — plistlib returns datetime.datetime for plist dates
    if hasattr(obj, "isoformat"):
        return obj.isoformat()
    return obj


def _describe_path(path: Path, container_root: Path) -> dict:
    """Build a metadata dict for a single filesystem path."""
    try:
        stat = path.stat()
        size_bytes = stat.st_size if path.is_file() else None
    except OSError:
        size_bytes = None

    relative = str(path.relative_to(container_root))
    kind = "symlink" if path.is_symlink() else ("dir" if path.is_dir() else "file")

    entry: dict = {"path": relative, "kind": kind}
    if size_bytes is not None:
        entry["size_bytes"] = size_bytes
    if path.is_symlink():
        try:
            entry["symlink_target"] = str(path.readlink())
        except OSError:
            entry["symlink_target"] = "<unreadable>"

    return entry


def _walk_directory(
    directory: Path,
    container_root: Path,
    current_depth: int,
    max_depth: int,
) -> list[dict]:
    """Recursively walk a directory up to max_depth, returning metadata entries."""
    entries: list[dict] = []
    try:
        children = sorted(directory.iterdir())
    except PermissionError:
        return entries

    for child in children:
        entries.append(_describe_path(child, container_root))
        if child.is_dir() and not child.is_symlink() and current_depth < max_depth:
            entries.extend(_walk_directory(child, container_root, current_depth + 1, max_depth))

    return entries


def _classify_sqlite_file(filename: str) -> str:
    """Return a human-readable type label for a SQLite-related file."""
    lower = filename.lower()
    if lower.endswith(".sqlite-wal"):
        return "write-ahead-log"
    if lower.endswith(".sqlite-shm"):
        return "shared-memory"
    return "database"


def _directory_size_bytes(path: Path) -> int:
    """Return the total size of all files under a directory."""
    total = 0
    for dirpath, _, filenames in os.walk(path, followlinks=False):
        for fname in filenames:
            fpath = Path(dirpath) / fname
            with contextlib.suppress(OSError):
                total += fpath.stat().st_size
    return total


def _human_bytes(num: int) -> str:
    """Format byte count as a human-readable string (KB / MB / GB)."""
    for unit in ("B", "KB", "MB", "GB"):
        if num < 1024:
            return f"{num:.1f} {unit}"
        num /= 1024
    return f"{num:.1f} TB"


def _format_userdefaults(preferences: dict, bundle_id: str, verbose: bool) -> str:
    """Format UserDefaults output as key=value lines."""
    lines = [f"UserDefaults: {bundle_id}"]
    if not preferences:
        lines.append("  (no keys found)")
        return "\n".join(lines)

    for key, value in sorted(preferences.items()):
        if isinstance(value, dict):
            lines.append(f"  {key} = <dict with {len(value)} keys>")
            if verbose:
                for sub_key, sub_value in sorted(value.items()):
                    lines.append(f"    {sub_key} = {sub_value!r}")
        elif isinstance(value, list):
            lines.append(f"  {key} = <list with {len(value)} items>")
            if verbose:
                for item in value:
                    lines.append(f"    - {item!r}")
        else:
            lines.append(f"  {key} = {value!r}")

    return "\n".join(lines)


# === CLI ===


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="App sandbox / UserDefaults / Core Data inspector for iOS simulators",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python container.py --ls com.example.app
  python container.py --ls com.example.app Library/Preferences
  python container.py --cat com.example.app Library/Preferences/com.example.app.plist
  python container.py --userdefaults com.example.app
  python container.py --core-data-path com.example.app
  python container.py --export com.example.app ./snapshot/
  python container.py --ls com.example.app --udid <DEVICE_UDID> --json
        """,
    )

    # Operation flags — mutually exclusive
    ops = parser.add_mutually_exclusive_group(required=True)
    ops.add_argument(
        "--ls",
        metavar="BUNDLE_ID",
        help="List files in the data container. Optionally pass a sub-path as second argument.",
    )
    ops.add_argument(
        "--cat",
        nargs=2,
        metavar=("BUNDLE_ID", "PATH"),
        help="Print a file from the container. Large files are cached.",
    )
    ops.add_argument(
        "--userdefaults",
        metavar="BUNDLE_ID",
        help="Read and display UserDefaults (Library/Preferences/<bundle>.plist).",
    )
    ops.add_argument(
        "--core-data-path",
        metavar="BUNDLE_ID",
        help="List Core Data SQLite store paths inside the container.",
    )
    ops.add_argument(
        "--export",
        nargs=2,
        metavar=("BUNDLE_ID", "DEST_DIR"),
        help="Copy the full data container to DEST_DIR/BUNDLE_ID.",
    )

    # Sub-path for --ls
    parser.add_argument(
        "path",
        nargs="?",
        default="",
        help="Sub-path for --ls (optional)",
    )

    # Common flags
    parser.add_argument("--udid", help="Simulator UDID (uses booted device if omitted)")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--verbose", action="store_true", help="Show extended detail")
    parser.add_argument(
        "--depth",
        type=int,
        default=3,
        help="Recursive depth for --ls (default: 3)",
    )

    args = parser.parse_args()

    # Resolve device
    try:
        udid = resolve_device_identifier(args.udid)
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)

    inspector = ContainerInspector(udid=udid)

    # === --ls ===
    if args.ls:
        success, result = inspector.list_files(
            args.ls, relative_path=args.path, max_depth=args.depth
        )
        if args.json:
            print(json.dumps({"action": "ls", "success": success, **result}, indent=2))
        elif not success:
            print(f"Error: {result.get('error', result)}", file=sys.stderr)
        else:
            print(f"Container: {result['container_root']}")
            print(f"Listed: {result['listed_path']}  ({result['total_entries']} entries)")
            listing_root = args.path or ""
            root_depth = listing_root.count("/") + 1 if listing_root else 0
            for entry in result["entries"]:
                relative_depth = entry["path"].count("/") - root_depth
                prefix = "  " * max(0, relative_depth)
                size = f"  [{_human_bytes(entry['size_bytes'])}]" if entry.get("size_bytes") else ""
                print(f"  {prefix}{entry['path']}  ({entry['kind']}){size}")
        sys.exit(0 if success else 1)

    # === --cat ===
    if args.cat:
        bundle_id, rel_path = args.cat
        success, result = inspector.cat_file(bundle_id, rel_path)
        if args.json:
            print(json.dumps({"action": "cat", "success": success, **result}, indent=2))
        elif not success:
            print(f"Error: {result.get('error', result)}", file=sys.stderr)
        elif "cache_id" in result:
            print(f"[{result['path']}]  {_human_bytes(result['size_bytes'])}  (cached)")
            print(result["note"])
        else:
            content = result.get("content", "")
            if isinstance(content, dict | list):
                print(json.dumps(content, indent=2))
            else:
                print(content)
        sys.exit(0 if success else 1)

    # === --userdefaults ===
    if args.userdefaults:
        success, result = inspector.read_userdefaults(args.userdefaults)
        if args.json:
            print(json.dumps({"action": "userdefaults", "success": success, **result}, indent=2))
        elif not success:
            print(f"Error: {result.get('error', result)}", file=sys.stderr)
        else:
            prefs = result.get("preferences", {})
            print(_format_userdefaults(prefs, args.userdefaults, verbose=args.verbose))
            print(f"\n({result['total_keys']} keys  •  {result['plist_path']})")
        sys.exit(0 if success else 1)

    # === --core-data-path ===
    if args.core_data_path:
        success, result = inspector.find_core_data_paths(args.core_data_path)
        if args.json:
            print(json.dumps({"action": "core-data-path", "success": success, **result}, indent=2))
        elif not success:
            print(f"Error: {result.get('error', result)}", file=sys.stderr)
        else:
            stores = result.get("stores", [])
            if not stores:
                print(f"No Core Data stores found for {args.core_data_path}")
            else:
                print(f"Core Data stores for {args.core_data_path}:")
                for store in stores:
                    size = _human_bytes(store["size_bytes"])
                    print(f"  {store['path']}  [{size}]  ({store['type']})")
        sys.exit(0 if success else 1)

    # === --export ===
    if args.export:
        bundle_id, dest_dir = args.export
        success, result = inspector.export_container(bundle_id, dest_dir)
        if args.json:
            print(json.dumps({"action": "export", "success": success, **result}, indent=2))
        elif not success:
            print(f"Error: {result.get('error', result)}", file=sys.stderr)
        else:
            print(
                f"Exported: {result['bundle_id']} → {result['destination']}  "
                f"[{result['size_human']}]"
            )
        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
