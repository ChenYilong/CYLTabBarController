#!/usr/bin/env python3
"""
Progressive disclosure cache for large outputs.

Implements cache system to support progressive disclosure pattern:
- Return concise summary with cache_id for large outputs
- User retrieves full details on demand via cache_id
- Reduces token usage by 96% for common queries

Cache directory: ~/.ios-simulator-skill/cache/
Cache expiration: Configurable per cache type (default 1 hour)

Used by:
- sim_list.py - Simulator listing progressive disclosure
- Future: build logs, UI trees, etc.
"""

import contextlib
import json
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from common.env_config import env_int

DEFAULT_MAX_AGE_HOURS = env_int("IOS_SIM_CACHE_TTL_HOURS", 1)
DEFAULT_MAX_ENTRIES = env_int("IOS_SIM_CACHE_MAX_ENTRIES", 500)


class ProgressiveCache:
    """Cache for progressive disclosure pattern.

    Stores large outputs with timestamped IDs for on-demand retrieval.
    Automatically cleans up expired entries.
    """

    def __init__(
        self,
        cache_dir: str | None = None,
        max_age_hours: int | None = None,
        max_entries: int | None = None,
    ):
        """Initialize cache system.

        Args:
            cache_dir: Cache directory path (default: ~/.ios-simulator-skill/cache/)
            max_age_hours: Max age for cache entries before expiration. Defaults to
                ``IOS_SIM_CACHE_TTL_HOURS`` env var, or 1 hour.
            max_entries: Maximum entries retained; oldest are evicted (LRU by mtime).
                Defaults to ``IOS_SIM_CACHE_MAX_ENTRIES`` env var, or 500.
        """
        if cache_dir is None:
            cache_dir = str(Path("~/.ios-simulator-skill/cache").expanduser())

        self.cache_dir = Path(cache_dir)
        self.max_age_hours = max_age_hours if max_age_hours is not None else DEFAULT_MAX_AGE_HOURS
        self.max_entries = max_entries if max_entries is not None else DEFAULT_MAX_ENTRIES

        # Create cache directory if needed
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def _evict_overflow(self) -> int:
        """Evict oldest entries when count exceeds ``max_entries``. Returns count evicted."""
        files = list(self.cache_dir.glob("*.json"))
        if len(files) <= self.max_entries:
            return 0
        # Sort oldest-first by mtime; delete the head of the overflow
        files.sort(key=lambda p: p.stat().st_mtime)
        to_remove = len(files) - self.max_entries
        for path in files[:to_remove]:
            with contextlib.suppress(OSError):
                path.unlink()
        return to_remove

    def save(self, data: dict[str, Any], cache_type: str) -> str:
        """Save data to cache and return cache_id.

        Args:
            data: Dictionary data to cache
            cache_type: Type of cache ('simulator-list', 'build-log', 'ui-tree', etc.)

        Returns:
            Cache ID like 'sim-20251028-143052' for use in progressive disclosure

        Example:
            cache_id = cache.save({'devices': [...]}, 'simulator-list')
            # Returns: 'sim-20251028-143052'
        """
        # Generate cache_id with timestamp
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        cache_prefix = cache_type.split("-", maxsplit=1)[0]  # e.g., 'sim' from 'simulator-list'
        cache_id = f"{cache_prefix}-{timestamp}"

        # Save to file
        cache_file = self.cache_dir / f"{cache_id}.json"
        with open(cache_file, "w") as f:
            json.dump(
                {
                    "cache_id": cache_id,
                    "cache_type": cache_type,
                    "created_at": datetime.now().isoformat(),
                    "data": data,
                },
                f,
                indent=2,
            )

        self._evict_overflow()
        return cache_id

    def get(self, cache_id: str) -> dict[str, Any] | None:
        """Retrieve data from cache by cache_id.

        Args:
            cache_id: Cache ID from save() or list_entries()

        Returns:
            Cached data dictionary, or None if not found/expired

        Example:
            data = cache.get('sim-20251028-143052')
            if data:
                print(f"Found {len(data)} devices")
        """
        cache_file = self.cache_dir / f"{cache_id}.json"

        if not cache_file.exists():
            return None

        # Check if expired
        if self._is_expired(cache_file):
            cache_file.unlink()  # Delete expired file
            return None

        try:
            with open(cache_file) as f:
                entry = json.load(f)
                return entry.get("data")
        except (OSError, json.JSONDecodeError):
            return None

    def list_entries(self, cache_type: str | None = None) -> list[dict[str, Any]]:
        """List available cache entries with metadata.

        Args:
            cache_type: Filter by type (e.g., 'simulator-list'), or None for all

        Returns:
            List of cache entries with id, type, created_at, age_seconds

        Example:
            entries = cache.list_entries('simulator-list')
            for entry in entries:
                print(f"{entry['id']} - {entry['age_seconds']}s old")
        """
        entries = []

        for cache_file in sorted(self.cache_dir.glob("*.json"), reverse=True):
            # Check if expired
            if self._is_expired(cache_file):
                cache_file.unlink()
                continue

            try:
                with open(cache_file) as f:
                    entry = json.load(f)

                    # Filter by type if specified
                    if cache_type and entry.get("cache_type") != cache_type:
                        continue

                    created_at = datetime.fromisoformat(entry.get("created_at", ""))
                    age_seconds = (datetime.now() - created_at).total_seconds()

                    entries.append(
                        {
                            "id": entry.get("cache_id"),
                            "type": entry.get("cache_type"),
                            "created_at": entry.get("created_at"),
                            "age_seconds": int(age_seconds),
                        }
                    )
            except (OSError, json.JSONDecodeError, ValueError):
                continue

        return entries

    def cleanup(self, max_age_hours: int | None = None) -> int:
        """Remove expired cache entries.

        Args:
            max_age_hours: Age threshold (default: uses instance max_age_hours)

        Returns:
            Number of entries deleted

        Example:
            deleted = cache.cleanup()
            print(f"Deleted {deleted} expired cache entries")
        """
        if max_age_hours is None:
            max_age_hours = self.max_age_hours

        deleted = 0

        for cache_file in self.cache_dir.glob("*.json"):
            if self._is_expired(cache_file, max_age_hours):
                cache_file.unlink()
                deleted += 1

        return deleted

    def clear(self, cache_type: str | None = None) -> int:
        """Clear all cache entries of a type.

        Args:
            cache_type: Type to clear (e.g., 'simulator-list'), or None to clear all

        Returns:
            Number of entries deleted

        Example:
            cleared = cache.clear('simulator-list')
            print(f"Cleared {cleared} simulator list entries")
        """
        deleted = 0

        for cache_file in self.cache_dir.glob("*.json"):
            if cache_type is None:
                # Clear all
                cache_file.unlink()
                deleted += 1
            else:
                # Clear by type
                try:
                    with open(cache_file) as f:
                        entry = json.load(f)
                        if entry.get("cache_type") == cache_type:
                            cache_file.unlink()
                            deleted += 1
                except (OSError, json.JSONDecodeError):
                    pass

        return deleted

    def _is_expired(self, cache_file: Path, max_age_hours: int | None = None) -> bool:
        """Check if cache file is expired.

        Args:
            cache_file: Path to cache file
            max_age_hours: Age threshold (default: uses instance max_age_hours)

        Returns:
            True if file is older than max_age_hours
        """
        if max_age_hours is None:
            max_age_hours = self.max_age_hours

        try:
            with open(cache_file) as f:
                entry = json.load(f)
                created_at = datetime.fromisoformat(entry.get("created_at", ""))
                age = datetime.now() - created_at
                return age > timedelta(hours=max_age_hours)
        except (OSError, json.JSONDecodeError, ValueError):
            return True


# Module-level cache instances (lazy-loaded)
_cache_instances: dict[str, ProgressiveCache] = {}


def get_cache(cache_dir: str | None = None) -> ProgressiveCache:
    """Get or create global cache instance.

    Args:
        cache_dir: Custom cache directory (uses default if None)

    Returns:
        ProgressiveCache instance
    """
    # Use cache_dir as key, or 'default' if None
    key = cache_dir or "default"

    if key not in _cache_instances:
        _cache_instances[key] = ProgressiveCache(cache_dir)

    return _cache_instances[key]
