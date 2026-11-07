"""
Common utilities shared across iOS simulator scripts.

This module centralizes genuinely reused code patterns to eliminate duplication
while respecting Jackson's Law - no over-abstraction, only truly shared logic.

Organization:
- device_utils: Device detection, command building, coordinate transformation
- idb_utils: IDB-specific operations (accessibility tree, element manipulation)
- cache_utils: Progressive disclosure caching for large outputs
- screenshot_utils: Screenshot capture with file and inline modes

Importing this package has no side effects. Xcode 27 compatibility is a
dependency requirement, not something this package patches at runtime:
idb-companion 1.5.1+ resolves SimulatorKit under the Xcode 27 layout itself.
Run scripts/sim_health_check.sh if `idb ui` calls misbehave.
"""

from .cache_utils import ProgressiveCache, get_cache
from .device_utils import (
    build_idb_command,
    build_simctl_command,
    get_booted_device_udid,
    get_booted_device_udids,
    get_device_screen_size,
    refuse_without_yes,
    resolve_udid,
    transform_screenshot_coords,
)
from .idb_utils import (
    IDB_UPGRADE_COMMAND,
    count_elements,
    flatten_tree,
    get_accessibility_tree,
    get_screen_size,
    idb_supports_set_value,
    run_idb,
    with_idb_upgrade_hint,
)
from .screenshot_utils import (
    capture_screenshot,
    format_screenshot_result,
    generate_screenshot_name,
    get_size_preset,
    resize_screenshot,
)

__all__ = [
    "IDB_UPGRADE_COMMAND",
    "ProgressiveCache",
    "build_idb_command",
    "build_simctl_command",
    "capture_screenshot",
    "count_elements",
    "flatten_tree",
    "format_screenshot_result",
    "generate_screenshot_name",
    "get_accessibility_tree",
    "get_booted_device_udid",
    "get_booted_device_udids",
    "get_cache",
    "get_device_screen_size",
    "get_screen_size",
    "get_size_preset",
    "idb_supports_set_value",
    "refuse_without_yes",
    "resize_screenshot",
    "resolve_udid",
    "run_idb",
    "transform_screenshot_coords",
    "with_idb_upgrade_hint",
]
