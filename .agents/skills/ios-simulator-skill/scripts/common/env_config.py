#!/usr/bin/env python3
"""Env-var overrides for tunable defaults.

All overrides use the ``IOS_SIM_`` prefix. See SKILL.md → Configuration
for the canonical list of supported variables.
"""

import os
import sys


def env_int(name: str, default: int, min_value: int = 1) -> int:
    """Read ``name`` as an int, falling back to ``default`` on miss or parse error."""
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    try:
        value = int(raw)
    except ValueError:
        print(f"warning: {name}={raw!r} is not an int; using default {default}", file=sys.stderr)
        return default
    return max(value, min_value)


def env_float(name: str, default: float, min_value: float = 0.0) -> float:
    """Read ``name`` as a float, falling back to ``default`` on miss or parse error."""
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    try:
        value = float(raw)
    except ValueError:
        print(f"warning: {name}={raw!r} is not a float; using default {default}", file=sys.stderr)
        return default
    return max(value, min_value)
