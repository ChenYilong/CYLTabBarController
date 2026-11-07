#!/usr/bin/env python3
"""Capture a .memgraph from one exact process on a booted iOS Simulator."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, text=True, capture_output=True, check=False)


def booted_devices() -> list[dict[str, str]]:
    result = run(["xcrun", "simctl", "list", "devices", "booted", "-j"])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "simctl could not list devices")
    try:
        document = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"simctl returned malformed JSON: {error}") from error
    devices: list[dict[str, str]] = []
    for runtime, values in document.get("devices", {}).items():
        if not runtime.startswith("com.apple.CoreSimulator.SimRuntime.iOS-"):
            continue
        for item in values:
            if item.get("state") == "Booted" and item.get("isAvailable", True):
                devices.append(
                    {"udid": str(item.get("udid")), "name": str(item.get("name")), "runtime": runtime}
                )
    return devices


def choose_device(devices: list[dict[str, str]], requested: str | None) -> dict[str, str]:
    if requested:
        matches = [item for item in devices if item["udid"] == requested]
        if len(matches) != 1:
            raise RuntimeError(f"--udid is not one available booted Simulator: {requested}")
        return matches[0]
    if len(devices) != 1:
        choices = ", ".join(f"{item['name']} ({item['udid']})" for item in devices) or "none"
        raise RuntimeError(f"expected one booted Simulator, found {len(devices)}: {choices}; pass --udid")
    return devices[0]


def exact_label(label: str, bundle_id: str) -> bool:
    escaped = re.escape(bundle_id)
    patterns = (
        rf"^{escaped}$",
        rf"^(?:com\.apple\.)?UIKitApplication:{escaped}(?:\[[^]]+\])*$",
        rf"^application<{escaped}>$",
    )
    return any(re.fullmatch(pattern, label) for pattern in patterns)


def process_candidates(udid: str, bundle_id: str) -> list[dict[str, Any]]:
    result = run(["xcrun", "simctl", "spawn", udid, "launchctl", "list"])
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "launchctl list failed")
    candidates: list[dict[str, Any]] = []
    for line in result.stdout.splitlines():
        columns = line.split(None, 2)
        if len(columns) != 3 or not columns[0].isdigit():
            continue
        pid, _, label = columns
        if exact_label(label, bundle_id):
            candidates.append({"pid": int(pid), "label": label})
    return candidates


def capture_succeeded(exit_status: int, memgraph: Path) -> bool:
    """Accept leaks' no-leak/leak statuses only when a nonempty graph exists."""
    try:
        return exit_status in {0, 1} and memgraph.is_file() and memgraph.stat().st_size > 0
    except OSError:
        return False


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Example:
  capture_sim_memgraph.py --udid SIMULATOR-UDID \\
    --bundle-id com.example.MyApp --output-dir /tmp/myapp-memory --pretty

Exit status: 0 captured; 2 invalid input, missing tool, or device error;
3 zero/ambiguous process matches; 4 leaks failed to create a graph.
The manifest JSON is written to stdout; raw tool output is preserved in --output-dir.""",
    )
    parser.add_argument("--bundle-id", required=True, help="Exact running app bundle identifier")
    parser.add_argument(
        "--output-dir", required=True, type=Path, help="Directory for graph, manifest, and raw output"
    )
    parser.add_argument("--udid", help="Required when more than one Simulator is booted")
    parser.add_argument("--pretty", action="store_true", help="Indent manifest JSON")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not shutil.which("xcrun") or not shutil.which("leaks"):
        print("xcrun and leaks must both be available on PATH", file=sys.stderr)
        return 2

    output = args.output_dir.resolve()
    if output.exists() and (not output.is_dir() or any(output.iterdir())):
        print(
            f"--output-dir must be an empty directory to prevent stale captures: {output}",
            file=sys.stderr,
        )
        return 2
    output.mkdir(parents=True, exist_ok=True)

    try:
        device = choose_device(booted_devices(), args.udid)
        candidates = process_candidates(device["udid"], args.bundle_id)
    except RuntimeError as error:
        print(error, file=sys.stderr)
        return 2
    if len(candidates) != 1:
        print(
            f"expected one exact running process for {args.bundle_id}, found {len(candidates)}: {candidates}",
            file=sys.stderr,
        )
        return 3

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    safe_bundle = re.sub(r"[^A-Za-z0-9_.-]", "_", args.bundle_id)
    pid = candidates[0]["pid"]
    prefix = f"{safe_bundle}-{pid}-{timestamp}"
    memgraph = output / f"{prefix}.memgraph"
    stdout_path = output / f"{prefix}.leaks.stdout.txt"
    stderr_path = output / f"{prefix}.leaks.stderr.txt"
    manifest_path = output / f"{prefix}.manifest.json"

    result = run(["leaks", f"--outputGraph={memgraph}", str(pid)])
    stdout_path.write_text(result.stdout, encoding="utf-8")
    stderr_path.write_text(result.stderr, encoding="utf-8")
    status = "captured" if capture_succeeded(result.returncode, memgraph) else "failed"
    manifest = {
        "schema_version": 1,
        "status": status,
        "captured_at_utc": timestamp,
        "bundle_id": args.bundle_id,
        "device": device,
        "process": candidates[0],
        "memgraph": str(memgraph),
        "leaks_exit_status": result.returncode,
        "raw_stdout": str(stdout_path),
        "raw_stderr": str(stderr_path),
        "manifest": str(manifest_path),
        "note": "Capture suspends the process; duration is not performance evidence.",
    }
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    json.dump(manifest, sys.stdout, indent=2 if args.pretty else None, sort_keys=True)
    sys.stdout.write("\n")
    if status == "failed":
        print(
            f"leaks did not create a usable nonempty graph (exit {result.returncode}): "
            f"{memgraph}; inspect preserved stdout/stderr and manifest",
            file=sys.stderr,
        )
        return 4
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
