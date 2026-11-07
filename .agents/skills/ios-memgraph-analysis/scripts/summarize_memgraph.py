#!/usr/bin/env python3
"""Preserve Apple leaks output and emit a bounded best-effort JSON summary."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any


LEAK_LINE = re.compile(r"^\s*Leak:\s+(0x[0-9A-Fa-f]+)\s+size=(\d+)\s*(.*)$")
TOTAL_LINE = re.compile(
    r"Process\s+\S+:\s+(\d+)\s+leaks?\s+for\s+(\d+)\s+total leaked bytes",
    re.IGNORECASE,
)
PREVIEW_BYTES = 1024 * 1024


class ArtifactError(RuntimeError):
    """A raw artifact destination is not fresh enough for safe evidence capture."""


def analyzable_leaks_status(exit_status: int) -> bool:
    return exit_status in {0, 1}


def bounded_text(path: Path, limit: int = PREVIEW_BYTES) -> tuple[str, bool]:
    """Read a bounded head/tail preview while keeping the raw file authoritative."""
    size = path.stat().st_size
    with path.open("rb") as handle:
        if size <= limit:
            data = handle.read()
        else:
            head_size = limit // 2
            tail_size = limit - head_size
            head = handle.read(head_size)
            handle.seek(size - tail_size)
            tail = handle.read(tail_size)
            data = head + b"\n... bounded preview omitted bytes ...\n" + tail
    return data.decode("utf-8", errors="replace"), size > limit


def run_and_preserve(command: list[str], artifact_dir: Path, stem: str) -> dict[str, Any]:
    stdout_path = artifact_dir / f"{stem}.stdout.txt"
    stderr_path = artifact_dir / f"{stem}.stderr.txt"
    existing = [str(path) for path in (stdout_path, stderr_path) if path.exists()]
    if existing:
        raise ArtifactError(f"raw artifact destination already exists: {existing}")
    with stdout_path.open("xb") as stdout_file, stderr_path.open("xb") as stderr_file:
        result = subprocess.run(
            command,
            stdout=stdout_file,
            stderr=stderr_file,
            check=False,
        )
    stdout_preview, stdout_truncated = bounded_text(stdout_path)
    stderr_preview, stderr_truncated = bounded_text(stderr_path)
    return {
        "exit_status": result.returncode,
        "stdout": str(stdout_path),
        "stderr": str(stderr_path),
        "stdout_preview_truncated": stdout_truncated,
        "stderr_preview_truncated": stderr_truncated,
        "combined": stdout_preview
        + ("\n" if stdout_preview and stderr_preview else "")
        + stderr_preview,
    }


def parse_list_output(text: str, app_patterns: list[re.Pattern[str]]) -> dict[str, Any]:
    total_count: int | None = None
    total_bytes: int | None = None
    entries: list[dict[str, Any]] = []
    for line in text.splitlines():
        total_match = TOTAL_LINE.search(line)
        if total_match:
            total_count = int(total_match.group(1))
            total_bytes = int(total_match.group(2))
        leak_match = LEAK_LINE.match(line)
        if not leak_match:
            continue
        address, size, remainder = leak_match.groups()
        normalized = re.sub(r"^zone:\s+\S+\s*", "", remainder.strip())
        segments = [segment.strip() for segment in re.split(r"\s{2,}", normalized) if segment.strip()]
        type_hint = segments[0] if segments else normalized or "<unknown>"
        image_hint = segments[-1] if len(segments) > 1 else "<unknown>"
        searchable = f"{type_hint} {image_hint} {normalized}"
        entries.append(
            {
                "address": address,
                "size_bytes": int(size),
                "type_hint": type_hint,
                "image_hint": image_hint,
                "description": normalized,
                "app_image_match": any(pattern.search(searchable) for pattern in app_patterns),
            }
        )
    return {"reported_count": total_count, "reported_bytes": total_bytes, "entries": entries}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Examples:
  summarize_memgraph.py App.memgraph --artifact-dir analysis --trace-limit 3 --pretty
  summarize_memgraph.py --list-output leaks-list.txt --app-image 'MyApp|FeatureKit'

Exit status: 0 parsed; 1 unrecognized leaks text; 2 invalid input or missing tool;
3 primary leaks command failed.
Summary JSON is written to stdout; live raw outputs are preserved in --artifact-dir.""",
    )
    parser.add_argument(
        "memgraph", nargs="?", type=Path, help="Memory graph for live leaks analysis"
    )
    parser.add_argument(
        "--list-output",
        type=Path,
        help="Parse an existing leaks --list text file without invoking Apple tools",
    )
    parser.add_argument(
        "--artifact-dir",
        type=Path,
        help="Required for live analysis; stores unmodified command stdout/stderr",
    )
    parser.add_argument("--app-image", action="append", default=[], help="Regex; repeat as needed")
    parser.add_argument("--top", type=int, default=20, help="Maximum type groups (1-200)")
    parser.add_argument("--trace-limit", type=int, default=0, help="Addresses to trace (0-20)")
    parser.add_argument("--trace-lines", type=int, default=80, help="Excerpt lines per trace (1-500)")
    parser.add_argument(
        "--group-by-type", action="store_true", help="Preserve a leaks --groupByType report"
    )
    parser.add_argument(
        "--reference-tree", action="store_true", help="Preserve a leaks --referenceTree report"
    )
    parser.add_argument("--pretty", action="store_true", help="Indent JSON output")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not 1 <= args.top <= 200 or not 0 <= args.trace_limit <= 20 or not 1 <= args.trace_lines <= 500:
        print("--top, --trace-limit, or --trace-lines is outside its documented bound", file=sys.stderr)
        return 2
    try:
        app_patterns = [re.compile(value) for value in args.app_image]
    except re.error as error:
        print(f"invalid --app-image expression: {error}", file=sys.stderr)
        return 2

    live = args.list_output is None
    if live:
        if args.memgraph is None or not args.memgraph.is_file():
            print("an existing memgraph is required for live analysis", file=sys.stderr)
            return 2
        if args.artifact_dir is None:
            print("--artifact-dir is required for live analysis", file=sys.stderr)
            return 2
        if not shutil.which("leaks"):
            print("leaks is not available on PATH", file=sys.stderr)
            return 2
        artifact_dir = args.artifact_dir.resolve()
        if artifact_dir.exists():
            print(
                f"--artifact-dir must be a new dedicated raw-artifact directory: {artifact_dir}",
                file=sys.stderr,
            )
            return 2
        try:
            artifact_dir.mkdir(parents=True, exist_ok=False)
            list_run = run_and_preserve(
                ["leaks", "--list", str(args.memgraph.resolve())], artifact_dir, "leaks-list"
            )
        except (ArtifactError, OSError) as error:
            print(f"could not create fresh raw artifacts: {error}", file=sys.stderr)
            return 2
        raw = str(list_run.pop("combined"))
        preview_truncated = bool(
            list_run["stdout_preview_truncated"] or list_run["stderr_preview_truncated"]
        )
        source = {"memgraph": str(args.memgraph.resolve()), "list_command": list_run}
    else:
        if not args.list_output.is_file():
            print(f"--list-output does not exist: {args.list_output}", file=sys.stderr)
            return 2
        if args.trace_limit or args.group_by_type or args.reference_tree:
            print("trace/reference options require a live memgraph, not --list-output", file=sys.stderr)
            return 2
        raw, preview_truncated = bounded_text(args.list_output)
        artifact_dir = None
        source = {
            "list_output": str(args.list_output.resolve()),
            "preview_truncated": preview_truncated,
        }

    if live and not analyzable_leaks_status(int(source["list_command"]["exit_status"])):
        report = {
            "schema_version": 1,
            "status": "tool_failed",
            "source": source,
            "reported_count": None,
            "reported_bytes": None,
            "parsed_entry_count": 0,
            "app_image_patterns": args.app_image,
            "type_groups": [],
            "entries": [],
            "traces": [],
            "artifacts": {},
            "warnings": [
                "The primary leaks --list command exited above 1; preserved output is unusable "
                "as analysis evidence."
            ],
            "interpretation_limit": "Counts, RSS, and graph size alone do not prove an ownership fix.",
        }
        json.dump(report, sys.stdout, indent=2 if args.pretty else None, sort_keys=True)
        sys.stdout.write("\n")
        print("primary leaks --list command failed; inspect preserved raw output", file=sys.stderr)
        return 3

    parsed = parse_list_output(raw, app_patterns)
    warnings: list[str] = [
        "Apple leaks text is parsed best-effort; raw output remains authoritative."
    ]
    if preview_truncated:
        warnings.append(
            "Parsing used a bounded head/tail preview because raw output exceeded 1 MiB; "
            "inspect the preserved source for omitted detail."
        )
    if parsed["reported_count"] and not parsed["entries"]:
        warnings.append("leaks reported entries, but this tool parsed none; inspect raw output")

    counts = Counter(entry["type_hint"] for entry in parsed["entries"])
    bytes_by_type: Counter[str] = Counter()
    for entry in parsed["entries"]:
        bytes_by_type[entry["type_hint"]] += entry["size_bytes"]
    type_groups = [
        {"type_hint": name, "count": count, "bytes": bytes_by_type[name]}
        for name, count in counts.items()
    ]
    type_groups.sort(key=lambda item: (-item["bytes"], -item["count"], item["type_hint"]))

    traces: list[dict[str, Any]] = []
    extra_artifacts: dict[str, Any] = {}
    if live and artifact_dir is not None and args.memgraph is not None:
        prioritized = sorted(
            parsed["entries"],
            key=lambda item: (not item["app_image_match"], -item["size_bytes"], item["address"]),
        )
        for index, entry in enumerate(prioritized[: args.trace_limit]):
            result = run_and_preserve(
                ["leaks", f"--traceTree={entry['address']}", str(args.memgraph.resolve())],
                artifact_dir,
                f"trace-{index + 1}-{entry['address']}",
            )
            combined = str(result.pop("combined"))
            usable = analyzable_leaks_status(int(result["exit_status"]))
            result["usable"] = usable
            if not usable:
                warnings.append(
                    f"traceTree for {entry['address']} exited above 1; preserved artifact is unusable"
                )
            traces.append(
                {
                    "address": entry["address"],
                    "type_hint": entry["type_hint"],
                    "command": result,
                    "excerpt": combined.splitlines()[: args.trace_lines],
                }
            )
        if args.group_by_type:
            result = run_and_preserve(
                ["leaks", "--groupByType", str(args.memgraph.resolve())],
                artifact_dir,
                "leaks-group-by-type",
            )
            result.pop("combined")
            result["usable"] = analyzable_leaks_status(int(result["exit_status"]))
            if not result["usable"]:
                warnings.append(
                    "groupByType exited above 1; preserved artifact is unusable"
                )
            extra_artifacts["group_by_type"] = result
        if args.reference_tree:
            reference_command = ["leaks", "--referenceTree"]
            reference_key = "reference_tree"
            reference_stem = "leaks-reference-tree"
            if args.group_by_type:
                reference_command.append("--groupByType")
                reference_key = "grouped_reference_tree"
                reference_stem = "leaks-grouped-reference-tree"
            reference_command.append(str(args.memgraph.resolve()))
            result = run_and_preserve(
                reference_command,
                artifact_dir,
                reference_stem,
            )
            result.pop("combined")
            result["usable"] = analyzable_leaks_status(int(result["exit_status"]))
            if not result["usable"]:
                warnings.append(
                    f"{reference_key} exited above 1; preserved artifact is unusable"
                )
            extra_artifacts[reference_key] = result

    report = {
        "schema_version": 1,
        "status": "parsed" if parsed["entries"] or parsed["reported_count"] is not None else "unrecognized",
        "source": source,
        "reported_count": parsed["reported_count"],
        "reported_bytes": parsed["reported_bytes"],
        "parsed_entry_count": len(parsed["entries"]),
        "app_image_patterns": args.app_image,
        "type_groups": type_groups[: args.top],
        "entries": parsed["entries"][:200],
        "traces": traces,
        "artifacts": extra_artifacts,
        "warnings": warnings,
        "interpretation_limit": "Counts, RSS, and graph size alone do not prove an ownership fix.",
    }
    json.dump(report, sys.stdout, indent=2 if args.pretty else None, sort_keys=True)
    sys.stdout.write("\n")
    return 0 if report["status"] == "parsed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
