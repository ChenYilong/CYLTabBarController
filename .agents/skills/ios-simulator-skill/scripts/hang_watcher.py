#!/usr/bin/env python3
"""
iOS Simulator Hang Watcher — featuring HangBuster session mode.

Two surfaces live in this file:

1. **HangWatcher** (legacy, --watch / --since) — passive os_log hang stream.
   Backward-compatible with PR #75.
2. **HangBuster** (new, --start / --stop / --get-details / --list-sessions /
   --clear-sessions / --diff) — agent-native session recorder. Detaches a
   worker, normalises and thresholds events on the fly, clusters at stop time,
   emits a token-tight summary with progressive drill paths.

The shared filter pipeline lives in ``common/hang_pipeline.py``; session
storage in ``common/hang_sessions.py``.

Environment variables (all read by ``common.env_config.env_int``):

- ``IOS_SIM_HANG_PREDICATE``         Override the default log predicate
- ``IOS_SIM_HANG_MIN_MS``            Min event duration kept (default 250)
- ``IOS_SIM_HANG_SESSION_TTL_HOURS`` Session prune age (default 24)
- ``IOS_SIM_HANG_DEFAULT_TOP_N``     Default top-N for ``--stop`` L1 (default 3)
- ``IOS_SIM_HANG_BUDGET_TOKENS``     Optional default for ``--budget-tokens``
"""

import argparse
import contextlib
import json
import os
import re
import select
import signal
import subprocess
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path

# Resolve imports whether run from repo root or scripts/ directory
_script_dir = str(Path(__file__).resolve().parent)
if _script_dir not in sys.path:
    sys.path.insert(0, _script_dir)

from common.cache_utils import ProgressiveCache  # noqa: E402
from common.device_utils import resolve_device_identifier  # noqa: E402
from common.env_config import env_int  # noqa: E402
from common.hang_pipeline import (  # noqa: E402
    build_normalised_event,
    compress_to_budget,
    diff_sessions,
    event_to_jsonl,
    format_cluster_detail,
    format_diff,
    format_l0,
    format_l1,
    format_l2,
    summary_to_json,
    symbolicate_stack,
)
from common.hang_pipeline import (  # noqa: E402
    extract_duration_ms as _pipeline_extract_duration_ms,
)
from common.hang_pipeline import (  # noqa: E402
    is_hang_message as _pipeline_is_hang_message,
)
from common.hang_pipeline import (  # noqa: E402
    parse_log_line as _pipeline_parse_log_line,
)
from common.hang_sessions import SessionStore  # noqa: E402

# === CONSTANTS ===

# Default predicate: catches RunningBoard kills + SwiftUI/UIKit micro-hangs.
# Override with env var IOS_SIM_HANG_PREDICATE for custom tuning.
DEFAULT_HANG_PREDICATE = (
    '(subsystem == "com.apple.runningboard") '
    'OR (eventMessage CONTAINS "Hang detected") '
    'OR ((eventMessage CONTAINS[c] "main thread") AND (eventMessage CONTAINS[c] "hang"))'
)

# How many times the worker re-spawns ``log stream`` after an EOF / subprocess
# death before giving up and marking the session crashed. Override via env var
# IOS_SIM_HANG_MAX_RESTARTS.
DEFAULT_MAX_STREAM_RESTARTS = 3
# Backoff between restart attempts. Short — log stream usually recovers fast.
RESTART_BACKOFF_SECONDS = 2.0


def _compute_start_timestamp(duration_str: str) -> str:
    """Parse duration string and return ISO-8601 start timestamp.

    Args:
        duration_str: Duration like '30s', '5m', '1h'.

    Raises:
        ValueError: If the format is unrecognised.
    """
    match = re.match(r"(\d+)([smh])", duration_str.lower())
    if not match:
        raise ValueError(
            f"Invalid duration format: {duration_str!r}. Use format like '30s', '5m', '1h'."
        )

    value, unit = match.groups()
    seconds = int(value) * {"s": 1, "m": 60, "h": 3600}[unit]
    start = datetime.now() - timedelta(seconds=seconds)
    return start.strftime("%Y-%m-%d %H:%M:%S")


# === HANG WATCHER ===


class HangWatcher:
    """Watch for iOS simulator hang events via os_log stream."""

    def __init__(self, udid: str | None = None):
        """Initialize hang watcher.

        Args:
            udid: Device UDID. Resolves to booted simulator if None.
        """
        self.udid = udid
        self.hang_events: list[dict] = []
        self.interrupted = False
        self._process: subprocess.Popen | None = None
        self._cache = ProgressiveCache()

    # === PUBLIC API ===

    def watch(
        self,
        duration_seconds: int | None = None,
        bundle_id: str | None = None,
        predicate: str | None = None,
        verbose: bool = False,
        json_mode: bool = False,
    ) -> bool:
        """Stream hang events live from the simulator.

        Runs `xcrun simctl spawn <udid> log stream --predicate <pred>` and
        parses each line into a structured hang event. Stops after
        duration_seconds or on Ctrl-C.

        Args:
            duration_seconds: Stop after N seconds. None = run until Ctrl-C.
            bundle_id: Filter events to a specific app bundle ID.
            predicate: Custom log predicate. Falls back to env var then default.
            verbose: Emit raw log lines alongside structured events.
            json_mode: Emit JSON objects per line instead of formatted text.

        Returns:
            True if stream ran without fatal errors.
        """
        resolved_udid = self._resolve_udid()
        effective_predicate = _resolve_predicate(predicate)
        cmd = self._build_stream_cmd(resolved_udid, effective_predicate)

        if verbose or not json_mode:
            print(
                f"Watching for hangs on {resolved_udid}",
                file=sys.stderr,
            )
            if bundle_id:
                print(f"Post-parse filter: {bundle_id}", file=sys.stderr)
            print(f"Predicate: {effective_predicate}", file=sys.stderr)

        self._register_signal_handler()

        try:
            self._process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
            )

            start_time = datetime.now()

            for raw_line in iter(self._process.stdout.readline, ""):
                if not raw_line:
                    break

                line = raw_line.rstrip()
                event = self._parse_line(line)

                if event:
                    if bundle_id and not self._matches_bundle(event, bundle_id):
                        continue

                    self.hang_events.append(event)

                    if json_mode:
                        print(json.dumps(event))
                        sys.stdout.flush()
                    else:
                        print(self._format_event(event))
                        if verbose:
                            print(f"  raw: {line}")

                elif verbose and line.strip():
                    print(f"  [skip] {line}", file=sys.stderr)

                if (
                    duration_seconds
                    and (datetime.now() - start_time).total_seconds() >= duration_seconds
                ):
                    break

                if self.interrupted:
                    break

            # Terminate before wait — log stream never self-exits on duration elapsed.
            if self._process and self._process.poll() is None:
                self._process.terminate()
                try:
                    self._process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    self._process.kill()
            return True

        except Exception as error:
            print(f"Error streaming hang events: {error}", file=sys.stderr)
            return False

        finally:
            if self._process and self._process.poll() is None:
                self._process.terminate()

    def show_since(
        self,
        since_duration: str,
        bundle_id: str | None = None,
        predicate: str | None = None,
        verbose: bool = False,
        json_mode: bool = False,
    ) -> bool:
        """Show historical hang events using `log show`.

        Args:
            since_duration: Duration string like "5m", "1h", "30s".
            bundle_id: Filter to a specific app bundle ID.
            predicate: Custom log predicate.
            verbose: Include raw log lines.
            json_mode: Emit JSON objects per line.

        Returns:
            True if command ran without fatal errors.
        """
        resolved_udid = self._resolve_udid()
        effective_predicate = _resolve_predicate(predicate)
        start_timestamp = self._compute_start_timestamp(since_duration)
        cmd = self._build_show_cmd(resolved_udid, effective_predicate, start_timestamp)

        if verbose or not json_mode:
            print(f"Showing hangs since {start_timestamp}", file=sys.stderr)

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,
                check=False,
            )

            for raw_line in result.stdout.splitlines():
                line = raw_line.rstrip()
                event = self._parse_line(line)

                if event:
                    if bundle_id and not self._matches_bundle(event, bundle_id):
                        continue

                    self.hang_events.append(event)

                    if json_mode:
                        print(json.dumps(event))
                    else:
                        print(self._format_event(event))
                        if verbose:
                            print(f"  raw: {line}")

            return True

        except subprocess.TimeoutExpired:
            print("Error: log show timed out after 60s", file=sys.stderr)
            return False
        except Exception as error:
            print(f"Error fetching historical hangs: {error}", file=sys.stderr)
            return False

    def get_summary(self) -> str:
        """Return token-efficient summary of captured hang events."""
        total = len(self.hang_events)
        if total == 0:
            return "No hang events detected."

        processes = {}
        for event in self.hang_events:
            proc = event.get("process", "unknown")
            processes[proc] = processes.get(proc, 0) + 1

        top = sorted(processes.items(), key=lambda x: x[1], reverse=True)[:5]
        top_str = ", ".join(f"{p}({c})" for p, c in top)
        return f"Hangs detected: {total} | Processes: {top_str}"

    def get_json_output(self) -> dict:
        """Return full results as a JSON-serialisable dict."""
        return {
            "hang_events": self.hang_events,
            "summary": {
                "total_hangs": len(self.hang_events),
                "processes": list({e.get("process") for e in self.hang_events}),
            },
        }

    def save_to_cache(self) -> str:
        """Persist hang archive to progressive cache and return cache_id."""
        return self._cache.save(self.get_json_output(), "hang-watcher")

    # === PRIVATE HELPERS ===

    def _resolve_udid(self) -> str:
        """Resolve UDID from stored value or booted device."""
        identifier = self.udid or "booted"
        try:
            return resolve_device_identifier(identifier)
        except RuntimeError as error:
            print(f"Error: {error}", file=sys.stderr)
            sys.exit(1)

    def _build_stream_cmd(self, udid: str, predicate: str) -> list[str]:
        """Build xcrun simctl spawn log stream command."""
        return [
            "xcrun",
            "simctl",
            "spawn",
            udid,
            "log",
            "stream",
            "--predicate",
            predicate,
        ]

    def _build_show_cmd(self, udid: str, predicate: str, start: str) -> list[str]:
        """Build xcrun simctl spawn log show command for historical queries."""
        return [
            "xcrun",
            "simctl",
            "spawn",
            udid,
            "log",
            "show",
            "--predicate",
            predicate,
            "--start",
            start,
        ]

    def _parse_line(self, line: str) -> dict | None:
        """Parse a log line into a hang event dict. Delegates to ``hang_pipeline``.

        The legacy event dict carried ``duration_estimate_ms``; we map the
        pipeline's ``duration_ms`` field back onto that name for backward compat.
        """
        event = _pipeline_parse_log_line(line)
        if event is None:
            return None
        if "duration_ms" in event:
            event["duration_estimate_ms"] = event.pop("duration_ms")
        return event

    def _is_hang_message(self, message: str) -> bool:
        """Delegate to ``hang_pipeline.is_hang_message``."""
        return _pipeline_is_hang_message(message)

    def _extract_duration_ms(self, message: str) -> float | None:
        """Delegate to ``hang_pipeline.extract_duration_ms``."""
        return _pipeline_extract_duration_ms(message)

    def _matches_bundle(self, event: dict, bundle_id: str) -> bool:
        """Delegate to module-level ``matches_bundle`` (kept for legacy callers)."""
        return matches_bundle(event, bundle_id)

    def _format_event(self, event: dict) -> str:
        """Format a hang event for human-readable terminal output."""
        duration_str = ""
        if "duration_estimate_ms" in event:
            ms = event["duration_estimate_ms"]
            duration_str = f" [{ms / 1000:.1f}s]" if ms >= 1000 else f" [{ms:.0f}ms]"

        return (
            f"HANG {event['timestamp']} | {event['process']} (PID {event['pid']})"
            f"{duration_str} | {event['message'][:120]}"
        )

    def _compute_start_timestamp(self, duration_str: str) -> str:
        """Parse duration string and return ISO-8601 start timestamp."""
        return _compute_start_timestamp(duration_str)

    def _register_signal_handler(self):
        """Register SIGINT handler for graceful shutdown."""

        def handle_sigint(sig, frame):
            self.interrupted = True
            if self._process:
                self._process.terminate()

        signal.signal(signal.SIGINT, handle_sigint)


# === HANGBUSTER (session mode) ===


def _resolve_predicate(predicate: str | None) -> str:
    """Resolution chain: CLI override → env var → default.

    Bundle filtering is *not* applied here — see ``matches_bundle()``. The
    default hang predicate matches events from RunningBoard, SpringBoard, and
    the watchdog, none of which run inside the target app's process. ANDing a
    ``process == <app>`` clause silently drops the bulk of useful hang signal.
    """
    return predicate or os.getenv("IOS_SIM_HANG_PREDICATE") or DEFAULT_HANG_PREDICATE


def matches_bundle(event: dict, bundle_id: str) -> bool:
    """Check if a parsed log event's process name matches the bundle ID.

    Applied post-parse so hang events from system processes (RunningBoard,
    SpringBoard) still flow through the pipeline; ``--bundle-id`` narrows the
    final output rather than the os_log predicate.
    """
    app_name = bundle_id.rsplit(".", maxsplit=1)[-1].lower()
    return app_name in event.get("process", "").lower()


class HangBuster:
    """Session-mode façade.

    Methods route to ``SessionStore`` + filter pipeline. The worker subprocess
    re-enters this class via ``run_worker()``.
    """

    def __init__(self, store: SessionStore | None = None):
        self.store = store or SessionStore()

    # === PUBLIC API ===

    def start(self, args: dict, udid: str | None) -> str:
        """Create session, detach worker, return session_id once worker registers."""
        self.store.prune_expired()
        aggregate_cap_mb = env_int("IOS_SIM_HANG_TOTAL_CAP_MB", 100)
        if aggregate_cap_mb > 0:
            self.store.prune_to_aggregate_cap(aggregate_cap_mb * 1024 * 1024)
        resolved_udid = self._resolve_udid(udid)
        meta = self.store.create({**args, "udid": resolved_udid})
        cmd = [
            sys.executable,
            __file__,
            "--worker-session-id",
            meta.session_id,
        ]
        # The detached worker survives parent exit. ``start_new_session=True``
        # calls setsid() so the process group is independent of the controlling TTY.
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
            close_fds=True,
        )
        try:
            self.store.wait_for_worker(meta.session_id, timeout_seconds=3.0)
        except TimeoutError:
            self.store.mark_crashed(meta.session_id)
            raise RuntimeError(f"Worker did not register within 3s for {meta.session_id}") from None
        return meta.session_id

    def stop(
        self,
        session_id: str,
        budget_tokens: int | None = None,
        top_n: int | None = None,
        terse: bool = False,
        json_mode: bool = False,
    ) -> str:
        """Signal worker, drain, build summary, return formatted output."""
        delivered = self.store.signal_worker(session_id, signal.SIGTERM)
        if delivered:
            # Give the worker up to 2s to flush + exit cleanly.
            self._wait_for_worker_exit(session_id, timeout_seconds=2.0)
        meta = self.store.load_meta(session_id)
        line_counters = meta.extras.get("line_counters", {})

        if meta.args.get("raw_capture"):
            # Raw-capture sessions skip the clustering pipeline entirely.
            return self._stop_raw_session(session_id, meta, line_counters, json_mode)

        summary = self.store.build_summary(
            session_id,
            matched_lines=line_counters.get("matched", 0),
            total_lines=line_counters.get("total", 0),
            dropped_below_threshold=line_counters.get("dropped", 0),
        )
        # Apply default top_n at summary-write time — keeps ranked clusters bounded.
        effective_top_n = top_n or env_int("IOS_SIM_HANG_DEFAULT_TOP_N", 3)
        summary.clusters = summary.clusters[:effective_top_n]
        self.store.stop(session_id, summary)
        if json_mode:
            return json.dumps(summary_to_json(summary), indent=2)
        if terse:
            return format_l0(summary)
        budget = budget_tokens or env_int("IOS_SIM_HANG_BUDGET_TOKENS", 0) or None
        return compress_to_budget(summary, max_tokens=budget, default_top_n=effective_top_n)

    def _stop_raw_session(self, session_id: str, meta, line_counters: dict, json_mode: bool) -> str:
        """Finalise a raw-capture session: gzip raw.ndjson, write status, report.

        No summary.json is written for raw sessions — clustering is not applied.
        ``--get-details`` redirects to the raw file.
        """
        import gzip
        import shutil

        raw_path = self.store.raw_path(session_id)
        gz_path = self.store.raw_path(session_id, gzipped=True)
        raw_bytes = raw_path.stat().st_size if raw_path.exists() else 0
        no_gzip = bool(meta.args.get("no_gzip"))
        final_path = raw_path
        if not no_gzip and raw_path.exists() and raw_bytes > 0:
            with open(raw_path, "rb") as src, gzip.open(gz_path, "wb") as dst:
                shutil.copyfileobj(src, dst)
            raw_path.unlink()
            final_path = gz_path
            meta.extras["raw_gzipped"] = True
            meta.extras["raw_bytes_compressed"] = gz_path.stat().st_size

        meta.extras["raw_bytes"] = raw_bytes
        # Mark stopped without going through build_summary (no summary.json for raw).
        meta.status = "stopped"
        from datetime import datetime as _dt

        now = _dt.now()
        meta.stopped_at = now.isoformat()
        meta.stopped_at_ms = int(now.timestamp() * 1000)
        self.store._write_meta(meta)
        truncated = bool(meta.extras.get("truncated"))
        if json_mode:
            return json.dumps(
                {
                    "session_id": session_id,
                    "mode": "raw",
                    "raw_path": str(final_path),
                    "raw_bytes": raw_bytes,
                    "raw_bytes_compressed": meta.extras.get("raw_bytes_compressed"),
                    "truncated": truncated,
                    "total_lines": line_counters.get("total", 0),
                    "stream_restarts": line_counters.get("stream_restarts", 0),
                },
                indent=2,
            )
        size_mb = raw_bytes / (1024 * 1024)
        gz_mb = (meta.extras.get("raw_bytes_compressed") or 0) / (1024 * 1024)
        trunc_str = " [TRUNCATED at size cap]" if truncated else ""
        gz_str = f" → {gz_mb:.2f} MB gzipped" if gz_path.exists() else ""
        explore_cmd = "zcat" if gz_path.exists() else "cat"
        return (
            f"Session {session_id}: raw mode, {line_counters.get('total', 0)} lines, "
            f"{size_mb:.2f} MB{gz_str}{trunc_str}\n"
            f"Explore: {explore_cmd} {final_path} | jq ..."
        )

    def get_details(
        self,
        session_id: str,
        cluster: int | None = None,
        raw: bool = False,
        resample: bool = False,
        json_mode: bool = False,
        symbolicate: bool = False,
        app_binary: str | None = None,
        dsym: str | None = None,
    ) -> str:
        """Drill into a stored session. ``cluster`` is 1-indexed for human use."""
        try:
            meta = self.store.load_meta(session_id)
        except FileNotFoundError:
            return f"Unknown session: {session_id}"
        if meta.args.get("raw_capture"):
            # Raw sessions have no clusters — point at the file.
            gz_path = self.store.raw_path(session_id, gzipped=True)
            ndjson_path = self.store.raw_path(session_id)
            target = gz_path if gz_path.exists() else ndjson_path
            cmd = "zcat" if gz_path.exists() else "cat"
            return f"Raw session — explore with: {cmd} {target} | jq ..."
        summary = self.store.load_summary(session_id)
        if summary is None:
            return f"No summary for {session_id}. Run --stop first."
        if raw:
            return self._dump_raw_events(session_id)
        if cluster is not None:
            index = cluster - 1
            if index < 0 or index >= len(summary.clusters):
                return f"Cluster {cluster} out of range (1..{len(summary.clusters)})"
            target = summary.clusters[index]
            events = [
                e for e in self.store.read_events(session_id) if e.fingerprint == target.fingerprint
            ]
            if resample:
                fresh = _attempt_auto_sample(
                    meta.args.get("udid", ""), events[0].pid if events else 0
                )
                target.auto_samples = [fresh]
            if symbolicate:
                _apply_symbolication(target, app_binary, dsym)
            if json_mode:
                from common.hang_pipeline import cluster_to_json

                return json.dumps(cluster_to_json(target), indent=2)
            return format_cluster_detail(target, events)
        if json_mode:
            return json.dumps(summary_to_json(summary), indent=2)
        return format_l2(summary)

    def list_sessions(self, json_mode: bool = False) -> str:
        metas = self.store.list_sessions()
        if json_mode:
            return json.dumps([m.to_json() for m in metas], indent=2)
        if not metas:
            return "No sessions stored."
        lines = [f"Sessions: {len(metas)}"]
        for meta in metas[:20]:
            stopped = meta.stopped_at or "-"
            counters = meta.extras.get("line_counters", {})
            restarts = counters.get("stream_restarts", 0)
            duration_s = (
                (meta.stopped_at_ms - meta.started_at_ms) / 1000.0 if meta.stopped_at_ms else None
            )
            duration_str = f"  capture={duration_s:.1f}s" if duration_s is not None else ""
            restart_str = f"  restarts={restarts}" if restarts else ""
            raw_str = ""
            if meta.args.get("raw_capture"):
                size = meta.extras.get("raw_bytes_compressed") or meta.extras.get("raw_bytes") or 0
                trunc = "T" if meta.extras.get("truncated") else "-"
                raw_str = f"  raw={size / 1024 / 1024:.2f}MB(trunc:{trunc})"
            lines.append(
                f"  {meta.session_id}  {meta.status:8s}  started={meta.started_at}  "
                f"stopped={stopped}{duration_str}{restart_str}{raw_str}"
            )
        if len(metas) > 20:
            lines.append(f"  ... {len(metas) - 20} more")
        return "\n".join(lines)

    def clear_sessions(self, older_than: str | None = None, json_mode: bool = False) -> str:
        deleted = self.store.clear(older_than=older_than)
        if json_mode:
            return json.dumps({"deleted": deleted, "older_than": older_than})
        suffix = f" older than {older_than}" if older_than else ""
        return f"Cleared {deleted} session(s){suffix}."

    def diff(self, session_a: str, session_b: str, json_mode: bool = False) -> str:
        summary_a = self.store.load_summary(session_a)
        summary_b = self.store.load_summary(session_b)
        if summary_a is None or summary_b is None:
            missing = [s for s, x in [(session_a, summary_a), (session_b, summary_b)] if x is None]
            return f"Missing summary.json for: {', '.join(missing)}"
        result = diff_sessions(summary_a, summary_b)
        if json_mode:
            return json.dumps(result, indent=2)
        return format_diff(result)

    # === WORKER ===

    def run_worker(self, session_id: str) -> int:
        """Long-running worker entrypoint. Returns exit code.

        Layout: claim meta → resolve predicate → open events.jsonl line-buffered
        → for each restart attempt, spawn ``xcrun simctl spawn ... log stream``
        and read lines until EOF or subprocess death. SIGTERM flushes and exits
        cleanly. EOF / subprocess death triggers a bounded restart loop
        (``IOS_SIM_HANG_MAX_RESTARTS``); on exhaustion the session is marked
        ``crashed`` rather than left in stale ``running`` state.

        In ``--raw-capture`` mode the worker spawns ``log stream --style ndjson``
        and dumps raw lines to ``raw.ndjson`` instead of parsing into the
        clustering pipeline. Same restart/crash semantics; additional size-cap
        bail when the raw file exceeds ``max_size_mb``.
        """
        meta = self.store.claim_worker(session_id, pid=os.getpid())
        args = meta.args
        min_hang_ms = int(args.get("min_hang_ms", env_int("IOS_SIM_HANG_MIN_MS", 250)))
        bundle_id = args.get("bundle_id")
        predicate_override = args.get("predicate")
        auto_sample = bool(args.get("auto_sample", False))
        auto_spindump = bool(args.get("auto_spindump", False))
        udid = args["udid"]
        predicate = _resolve_predicate(predicate_override)
        max_restarts = env_int("IOS_SIM_HANG_MAX_RESTARTS", DEFAULT_MAX_STREAM_RESTARTS)
        raw_capture = bool(args.get("raw_capture", False))
        max_size_bytes = int(args.get("max_size_mb", 10)) * 1024 * 1024 if raw_capture else 0

        events_path = self.store.events_path(session_id)
        counters = {"total": 0, "matched": 0, "dropped": 0, "stream_restarts": 0}
        sampled_fingerprints: set[str] = set()
        spindumped_fingerprints: set[str] = set()
        stop_flag = {"value": False}
        cap_state = {"hit": False}  # set by raw reader when size cap exceeded

        def _on_sigterm(_signum, _frame):
            stop_flag["value"] = True

        signal.signal(signal.SIGTERM, _on_sigterm)
        signal.signal(signal.SIGINT, _on_sigterm)

        cmd = ["xcrun", "simctl", "spawn", udid, "log", "stream", "--predicate", predicate]
        if raw_capture:
            cmd.extend(["--style", "ndjson"])

        def _spawn_log_stream() -> subprocess.Popen:
            return subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL,
                text=True,
                bufsize=1,
            )

        proc: subprocess.Popen | None = None
        crashed = False
        try:
            with contextlib.ExitStack() as stack:
                out_handle = stack.enter_context(open(events_path, "a", buffering=1))
                raw_handle = (
                    stack.enter_context(open(self.store.raw_path(session_id), "a", buffering=1))
                    if raw_capture
                    else None
                )
                for attempt in range(max_restarts + 1):
                    if stop_flag["value"]:
                        break
                    if attempt > 0:
                        counters["stream_restarts"] = attempt
                        out_handle.write(
                            json.dumps(
                                {
                                    "event": "stream_restart",
                                    "attempt": attempt,
                                    "at_ms": int(time.time() * 1000),
                                }
                            )
                            + "\n"
                        )
                        out_handle.flush()
                        time.sleep(RESTART_BACKOFF_SECONDS)
                        if stop_flag["value"]:
                            break
                    try:
                        proc = _spawn_log_stream()
                    except FileNotFoundError:
                        crashed = True
                        break

                    if raw_capture:
                        exit_code = self._read_stream_into_raw(
                            proc=proc,
                            raw_handle=raw_handle,
                            stop_flag=stop_flag,
                            counters=counters,
                            max_size_bytes=max_size_bytes,
                            session_id=session_id,
                            cap_state=cap_state,
                        )
                    else:
                        exit_code = self._read_stream_into_events(
                            proc=proc,
                            out_handle=out_handle,
                            stop_flag=stop_flag,
                            counters=counters,
                            bundle_id=bundle_id,
                            min_hang_ms=min_hang_ms,
                            auto_sample=auto_sample,
                            auto_spindump=auto_spindump,
                            sampled_fingerprints=sampled_fingerprints,
                            spindumped_fingerprints=spindumped_fingerprints,
                            session_id=session_id,
                            session_start_ms=meta.started_at_ms,
                            udid=udid,
                        )

                    if cap_state["hit"]:
                        # Size-cap is a clean stop, not a crash. Record marker.
                        out_handle.write(
                            json.dumps(
                                {
                                    "event": "size_cap_hit",
                                    "bytes": self.store.raw_path(session_id).stat().st_size,
                                    "at_ms": int(time.time() * 1000),
                                }
                            )
                            + "\n"
                        )
                        out_handle.flush()
                        self._mark_truncated(session_id)
                        break

                    if stop_flag["value"]:
                        # Clean SIGTERM. Don't restart, don't mark crashed.
                        out_handle.write(
                            json.dumps({"event": "stream_ended", "at_ms": int(time.time() * 1000)})
                            + "\n"
                        )
                        out_handle.flush()
                        break

                    # Subprocess died without a stop request. Record it.
                    out_handle.write(
                        json.dumps(
                            {
                                "event": "stream_died",
                                "exit_code": exit_code,
                                "attempt": attempt,
                                "at_ms": int(time.time() * 1000),
                            }
                        )
                        + "\n"
                    )
                    out_handle.flush()
                else:
                    # for/else: ran every restart without a clean break — exhausted.
                    crashed = True

                with contextlib.suppress(OSError):
                    os.fsync(out_handle.fileno())
        finally:
            # raw_handle / out_handle are closed by ExitStack on with-block exit.
            if proc is not None and proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    proc.kill()

            if crashed and not stop_flag["value"]:
                self.store.mark_crashed(session_id)
            # SessionStore.persist_worker_counters preserves terminal status
            # (stopped from parent's stop(), or crashed above) and avoids
            # clobbering it back to running.
            self.store.persist_worker_counters(session_id, counters)

        return 2 if crashed else 0

    def _read_stream_into_raw(
        self,
        *,
        proc: subprocess.Popen,
        raw_handle,
        stop_flag: dict,
        counters: dict,
        max_size_bytes: int,
        session_id: str,
        cap_state: dict,
    ) -> int | None:
        """Raw NDJSON capture: dump lines verbatim to raw.ndjson, no parsing.

        Sets ``cap_state['hit'] = True`` and returns when the file exceeds
        ``max_size_bytes``. The caller treats that as a clean stop (no
        restart, no crash) and writes a ``size_cap_hit`` marker.
        """
        raw_path = self.store.raw_path(session_id)
        bytes_written = raw_path.stat().st_size if raw_path.exists() else 0
        last_fsync = time.time()
        while not stop_flag["value"]:
            if proc.stdout is None:
                return proc.poll()
            ready, _, _ = select.select([proc.stdout], [], [], 0.25)
            if not ready:
                if time.time() - last_fsync > 1.0:
                    raw_handle.flush()
                    with contextlib.suppress(OSError):
                        os.fsync(raw_handle.fileno())
                    last_fsync = time.time()
                exit_code = proc.poll()
                if exit_code is not None:
                    return exit_code
                continue
            line = proc.stdout.readline()
            if not line:
                with contextlib.suppress(subprocess.TimeoutExpired):
                    proc.wait(timeout=0.5)
                return proc.poll()
            counters["total"] += 1
            # Drop non-JSON banners like `log stream`'s "Filtering the log data..." and
            # any pwuid warnings. Raw consumers expect strict NDJSON.
            stripped = line.lstrip()
            if not stripped.startswith("{"):
                continue
            raw_handle.write(line if line.endswith("\n") else line + "\n")
            bytes_written += len(line) + (0 if line.endswith("\n") else 1)
            if max_size_bytes > 0 and bytes_written >= max_size_bytes:
                cap_state["hit"] = True
                raw_handle.flush()
                with contextlib.suppress(OSError):
                    os.fsync(raw_handle.fileno())
                return proc.poll()
        return proc.poll()

    def _mark_truncated(self, session_id: str) -> None:
        """Best-effort: set extras.truncated=True. Called when size cap hit."""
        try:
            meta = self.store.load_meta(session_id)
        except FileNotFoundError:
            return
        meta.extras["truncated"] = True
        # Write meta directly via the public store path; intentional: SessionStore
        # exposes no extras setter and we want one round-trip not two.
        self.store._write_meta(meta)

    def _read_stream_into_events(
        self,
        *,
        proc: subprocess.Popen,
        out_handle,
        stop_flag: dict,
        counters: dict,
        bundle_id: str | None,
        min_hang_ms: int,
        auto_sample: bool,
        auto_spindump: bool,
        sampled_fingerprints: set[str],
        spindumped_fingerprints: set[str],
        session_id: str,
        session_start_ms: int,
        udid: str,
    ) -> int | None:
        """Read lines until EOF / subprocess death / stop request.

        Returns the subprocess exit code (None if still alive when stop_flag
        was set, otherwise the recorded poll() value at exit time). Does not
        emit ``stream_died`` / ``stream_ended`` events itself — the caller
        decides which marker to write based on stop_flag.
        """
        last_fsync = time.time()
        while not stop_flag["value"]:
            if proc.stdout is None:
                return proc.poll()
            ready, _, _ = select.select([proc.stdout], [], [], 0.25)
            if not ready:
                if time.time() - last_fsync > 1.0:
                    out_handle.flush()
                    with contextlib.suppress(OSError):
                        os.fsync(out_handle.fileno())
                    last_fsync = time.time()
                # If the subprocess silently died, poll() returns its code now.
                # Otherwise keep waiting — quiet log streams are normal.
                exit_code = proc.poll()
                if exit_code is not None:
                    return exit_code
                continue
            line = proc.stdout.readline()
            if not line:
                # EOF — subprocess closed stdout. Wait briefly for poll() to
                # settle so we report a meaningful exit code.
                with contextlib.suppress(subprocess.TimeoutExpired):
                    proc.wait(timeout=0.5)
                return proc.poll()
            counters["total"] += 1
            raw_event = _pipeline_parse_log_line(line.rstrip())
            if raw_event is None:
                continue
            if bundle_id and not matches_bundle(raw_event, bundle_id):
                continue
            counters["matched"] += 1
            duration = raw_event.get("duration_ms")
            if duration is None or duration < min_hang_ms:
                counters["dropped"] += 1
                continue
            normalised = build_normalised_event(
                raw_event,
                session_start_ms=session_start_ms,
                current_ms=int(time.time() * 1000),
            )
            if normalised is None:
                continue
            if auto_sample and normalised.fingerprint not in sampled_fingerprints:
                sampled_fingerprints.add(normalised.fingerprint)
                self._stash_auto_sample(
                    session_id, normalised, _attempt_auto_sample(udid, normalised.pid)
                )
            if auto_spindump and normalised.fingerprint not in spindumped_fingerprints:
                spindumped_fingerprints.add(normalised.fingerprint)
                self._stash_auto_sample(
                    session_id, normalised, _attempt_auto_spindump(udid, normalised.pid)
                )
            out_handle.write(event_to_jsonl(normalised) + "\n")
        return proc.poll()

    # === PRIVATE ===

    def _wait_for_worker_exit(self, session_id: str, timeout_seconds: float) -> None:
        meta = self.store.load_meta(session_id)
        if not meta.pid:
            return
        deadline = time.time() + timeout_seconds
        while time.time() < deadline:
            try:
                os.kill(meta.pid, 0)
            except ProcessLookupError:
                return
            time.sleep(0.05)

    def _dump_raw_events(self, session_id: str) -> str:
        path = self.store.events_path(session_id)
        if not path.exists():
            return ""
        with open(path) as handle:
            return handle.read()

    def _resolve_udid(self, udid: str | None) -> str:
        identifier = udid or "booted"
        try:
            return resolve_device_identifier(identifier)
        except RuntimeError as error:
            raise RuntimeError(str(error)) from error

    def _stash_auto_sample(self, session_id: str, normalised, sample: dict) -> None:
        """Record an auto-sample side-channel for later cluster annotation.

        Delegates to SessionStore's append-only JSONL writer — concurrent stashes
        from a busy worker no longer race against each other.
        """
        self.store.stash_auto_sample(session_id, normalised.fingerprint, sample)


SAMPLE_DURATION_SECONDS = 1
SAMPLE_TIMEOUT_SECONDS = 5
SPINDUMP_DURATION_SECONDS = 1
SPINDUMP_TIMEOUT_SECONDS = 10
ATOS_TIMEOUT_SECONDS = 10


def _attempt_auto_sample(udid: str, pid: int) -> dict:
    """Capture a main-thread stack via ``xcrun simctl spawn <udid> sample``.

    Shells out to the in-simulator ``sample`` binary, which writes a textual
    main-thread profile to stdout. Short duration keeps the worker hot path
    responsive; fingerprint dedup at the caller means we sample at most once
    per unique hang pattern per session.
    """
    if not udid:
        return {
            "kind": "simctl-sample",
            "stack": None,
            "captured_at_ms": int(time.time() * 1000),
            "symbolicated": False,
            "reason": "no udid available",
        }
    if not pid:
        return {
            "kind": "simctl-sample",
            "stack": None,
            "captured_at_ms": int(time.time() * 1000),
            "symbolicated": False,
            "reason": "no pid available",
        }
    cmd = [
        "xcrun",
        "simctl",
        "spawn",
        udid,
        "sample",
        str(pid),
        str(SAMPLE_DURATION_SECONDS),
        "-mayDie",
        "-file",
        "-",
    ]
    captured_at_ms = int(time.time() * 1000)
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=SAMPLE_TIMEOUT_SECONDS,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {
            "kind": "simctl-sample",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": "timeout",
        }
    except FileNotFoundError:
        return {
            "kind": "simctl-sample",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": "xcrun not found",
        }
    if result.returncode != 0 or not result.stdout.strip():
        return {
            "kind": "simctl-sample",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": (result.stderr.strip() or f"sample exited {result.returncode}")[:200],
        }
    return {
        "kind": "simctl-sample",
        "stack": result.stdout,
        "captured_at_ms": captured_at_ms,
        "symbolicated": False,
        "reason": None,
    }


def _attempt_auto_spindump(udid: str, pid: int) -> dict:
    """Capture a hang report via ``xcrun simctl spawn <udid> spindump``.

    ``spindump`` is Apple's own hang-report tool — it produces a structured
    text report explicitly designed for the "what was main thread doing"
    question. Heavier than ``sample`` so we run a slightly longer timeout.
    """
    captured_at_ms = int(time.time() * 1000)
    if not udid:
        return {
            "kind": "spindump",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": "no udid available",
        }
    if not pid:
        return {
            "kind": "spindump",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": "no pid available",
        }
    cmd = [
        "xcrun",
        "simctl",
        "spawn",
        udid,
        "spindump",
        str(pid),
        str(SPINDUMP_DURATION_SECONDS),
        "-file",
        "-",
    ]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=SPINDUMP_TIMEOUT_SECONDS,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {
            "kind": "spindump",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": "timeout",
        }
    except FileNotFoundError:
        return {
            "kind": "spindump",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": "xcrun not found",
        }
    if result.returncode != 0 or not result.stdout.strip():
        return {
            "kind": "spindump",
            "stack": None,
            "captured_at_ms": captured_at_ms,
            "symbolicated": False,
            "reason": (result.stderr.strip() or f"spindump exited {result.returncode}")[:200],
        }
    return {
        "kind": "spindump",
        "stack": result.stdout,
        "captured_at_ms": captured_at_ms,
        "symbolicated": False,
        "reason": None,
    }


def _apply_symbolication(cluster, app_binary: str | None, dsym: str | None) -> None:
    """In-place: rewrite each auto-sample's stack via atos using the chosen target.

    No-ops if no target path is resolvable or atos returns nothing — failures
    must never strip the existing (unsymbolicated) stack, only enhance it.
    """
    target = _resolve_symbolication_target(app_binary, dsym)
    if not target:
        return
    samples = cluster.auto_samples or ([cluster.auto_sample] if cluster.auto_sample else [])
    for sample in samples:
        if not sample or not sample.get("stack"):
            continue
        original = sample["stack"]
        rewritten = symbolicate_stack(original, lambda addrs: _run_atos(target, addrs))
        if rewritten != original:
            sample["stack"] = rewritten
            sample["symbolicated"] = True


def _run_atos(binary_path: str, addresses: list[str]) -> dict[str, str]:
    """Resolve a batch of runtime addresses via ``xcrun atos -o <path>``.

    Returns ``{addr: resolved_text}`` for every input address; addresses atos
    couldn't resolve come back as themselves (atos echoes the input). Failures
    return an empty dict so callers can fall through cleanly.
    """
    if not binary_path or not addresses:
        return {}
    cmd = ["xcrun", "atos", "-o", binary_path, *addresses]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=ATOS_TIMEOUT_SECONDS,
            check=False,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return {}
    if result.returncode != 0:
        return {}
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    # atos prints one resolved line per input address, in input order.
    return dict(zip(addresses, lines, strict=False))


def _resolve_symbolication_target(app_binary: str | None, dsym: str | None) -> str | None:
    """Pick the path atos should resolve against. dSYM wins when both set."""
    explicit = dsym or app_binary
    if explicit:
        return explicit
    env_dsym = os.environ.get("IOS_SIM_HANG_DSYM", "").strip()
    if env_dsym:
        return env_dsym
    env_binary = os.environ.get("IOS_SIM_HANG_APP_BINARY", "").strip()
    return env_binary or None


# === CLI ===


def _add_legacy_args(parser: argparse.ArgumentParser) -> argparse._MutuallyExclusiveGroup:
    """Add the v1 --watch / --since flags plus the new HangBuster subcommands.

    All modes share the same parser so users can keep using v1 invocations
    unchanged. Subcommands are mutually exclusive (mode_group).
    """
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument(
        "--watch", action="store_true", help="Legacy live stream (until --duration / Ctrl-C)"
    )
    mode_group.add_argument(
        "--since",
        metavar="DURATION",
        help="Legacy historical query (e.g. 5m, 1h, 30s)",
    )
    mode_group.add_argument(
        "--start",
        action="store_true",
        help="Start a HangBuster session (detached worker, returns session ID)",
    )
    mode_group.add_argument(
        "--stop", metavar="SESSION_ID", help="Stop a session and emit the summary"
    )
    mode_group.add_argument(
        "--get-details",
        metavar="SESSION_ID",
        help="Drill into a stored session (combine with --cluster N or --raw)",
    )
    mode_group.add_argument(
        "--list-sessions", action="store_true", help="List stored HangBuster sessions"
    )
    mode_group.add_argument("--clear-sessions", action="store_true", help="Delete stored sessions")
    mode_group.add_argument(
        "--diff", nargs=2, metavar=("SESSION_A", "SESSION_B"), help="Compare two sessions"
    )
    # Internal worker entry — hidden from --help. Detached child re-enters this script with it.
    mode_group.add_argument("--worker-session-id", metavar="ID", help=argparse.SUPPRESS)
    return mode_group


def main():
    """Main entry point — supports v1 + HangBuster modes from one parser."""
    parser = argparse.ArgumentParser(
        description=(
            "Watch for iOS simulator hang events via os_log. "
            "Use --watch/--since for the v1 stream, or --start/--stop for HangBuster session mode."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # HangBuster session mode (agent-friendly):
  SID=$(python scripts/hang_watcher.py --start --min-hang-ms 200)
  # ... interact with the simulator ...
  python scripts/hang_watcher.py --stop $SID
  python scripts/hang_watcher.py --get-details $SID --cluster 1
  python scripts/hang_watcher.py --list-sessions
  python scripts/hang_watcher.py --diff $SID_A $SID_B
  python scripts/hang_watcher.py --clear-sessions --older-than 24h

  # Legacy:
  python scripts/hang_watcher.py --watch --duration 60
  python scripts/hang_watcher.py --since 5m --json

Environment variables:
  IOS_SIM_HANG_PREDICATE         Override the default log predicate
  IOS_SIM_HANG_MIN_MS            Min event duration kept (default 250)
  IOS_SIM_HANG_SESSION_TTL_HOURS Session prune age (default 24)
  IOS_SIM_HANG_DEFAULT_TOP_N     Default top-N for --stop (default 3)
  IOS_SIM_HANG_BUDGET_TOKENS     Default token budget for --stop
        """,
    )
    _add_legacy_args(parser)

    # Filters / target
    parser.add_argument(
        "--bundle-id",
        help=(
            "Post-parse filter: drop events whose process name does not contain the "
            "app suffix from this bundle ID. Hang capture itself stays simulator-global "
            "(RunningBoard/SpringBoard events are kept)."
        ),
    )
    parser.add_argument("--predicate", help="Override the default os_log predicate")
    parser.add_argument("--udid", help="Device UDID (uses booted simulator if omitted)")

    # Legacy-only
    parser.add_argument(
        "--duration", type=int, metavar="SECONDS", help="Stop after N seconds (--watch only)"
    )

    # HangBuster knobs
    parser.add_argument(
        "--min-hang-ms",
        type=int,
        help="Drop events below this duration (default 250 / env IOS_SIM_HANG_MIN_MS)",
    )
    parser.add_argument(
        "--auto-sample",
        action="store_true",
        help="On hang, capture a main-thread stack via `xcrun simctl spawn <udid> sample`",
    )
    parser.add_argument(
        "--auto-spindump",
        action="store_true",
        help="On hang, capture a spindump report via `xcrun simctl spawn <udid> spindump`",
    )
    parser.add_argument("--top", type=int, dest="top_n", help="Top-N clusters to retain in summary")
    parser.add_argument(
        "--all", action="store_true", dest="all_clusters", help="Keep all clusters (no top-N cap)"
    )
    parser.add_argument(
        "--budget-tokens", type=int, help="Max tokens for --stop output (picks L0/L1/L2)"
    )
    parser.add_argument(
        "--cluster", type=int, help="Cluster index (1-based) for --get-details drill"
    )
    parser.add_argument(
        "--resample", action="store_true", help="With --get-details: force a fresh auto-sample"
    )
    parser.add_argument("--raw", action="store_true", help="With --get-details: dump events.jsonl")
    parser.add_argument(
        "--symbolicate",
        action="store_true",
        help="With --get-details: resolve [0x...] frames via `xcrun atos`",
    )
    parser.add_argument(
        "--app-binary",
        help="Path to unstripped app binary for --symbolicate (env: IOS_SIM_HANG_APP_BINARY)",
    )
    parser.add_argument(
        "--dsym",
        help="Path to .dSYM for --symbolicate (preferred over --app-binary; env: IOS_SIM_HANG_DSYM)",
    )
    parser.add_argument(
        "--older-than", help="With --clear-sessions: delete sessions older than e.g. 24h"
    )
    parser.add_argument("--terse", action="store_true", help="--stop: force L0 one-line output")

    # Raw capture (HangBuster)
    parser.add_argument(
        "--raw-capture",
        action="store_true",
        help=(
            "With --start: capture raw os_log NDJSON to raw.ndjson instead of bucketed events. "
            "Explore afterwards with: zcat <session>/raw.ndjson.gz | jq ..."
        ),
    )
    parser.add_argument(
        "--max-size-mb",
        type=int,
        default=10,
        help="Raw-capture per-session size cap in MB (default 10). Worker stops at cap.",
    )
    parser.add_argument(
        "--no-gzip",
        action="store_true",
        help="Skip gzip of raw.ndjson on --stop (raw-capture mode only).",
    )

    # Output
    parser.add_argument("--json", action="store_true", help="Emit JSON output")
    parser.add_argument("--verbose", action="store_true", help="Include raw lines (legacy modes)")

    args = parser.parse_args()

    # === HangBuster worker entry ===
    if args.worker_session_id:
        buster = HangBuster()
        sys.exit(buster.run_worker(args.worker_session_id))

    # === HangBuster session subcommands ===
    if args.start:
        buster = HangBuster()
        start_args = {
            "min_hang_ms": (
                args.min_hang_ms
                if args.min_hang_ms is not None
                else env_int("IOS_SIM_HANG_MIN_MS", 250)
            ),
            "bundle_id": args.bundle_id,
            "predicate": args.predicate,
            "auto_sample": args.auto_sample,
            "auto_spindump": args.auto_spindump,
            "raw_capture": args.raw_capture,
            "max_size_mb": args.max_size_mb,
            "no_gzip": args.no_gzip,
        }
        try:
            session_id = buster.start(start_args, udid=args.udid)
        except RuntimeError as error:
            print(f"Error: {error}", file=sys.stderr)
            sys.exit(1)
        print(session_id)
        sys.exit(0)

    if args.stop:
        buster = HangBuster()
        top_n = None if args.all_clusters else args.top_n
        out = buster.stop(
            args.stop,
            budget_tokens=args.budget_tokens,
            top_n=top_n,
            terse=args.terse,
            json_mode=args.json,
        )
        print(out)
        sys.exit(0)

    if args.get_details:
        buster = HangBuster()
        out = buster.get_details(
            args.get_details,
            cluster=args.cluster,
            raw=args.raw,
            resample=args.resample,
            json_mode=args.json,
            symbolicate=args.symbolicate,
            app_binary=args.app_binary,
            dsym=args.dsym,
        )
        print(out)
        sys.exit(0)

    if args.list_sessions:
        buster = HangBuster()
        print(buster.list_sessions(json_mode=args.json))
        sys.exit(0)

    if args.clear_sessions:
        buster = HangBuster()
        print(buster.clear_sessions(older_than=args.older_than, json_mode=args.json))
        sys.exit(0)

    if args.diff:
        buster = HangBuster()
        print(buster.diff(args.diff[0], args.diff[1], json_mode=args.json))
        sys.exit(0)

    # === Legacy modes ===
    if args.since:
        try:
            _compute_start_timestamp(args.since)
        except ValueError as error:
            parser.error(str(error))

    watcher = HangWatcher(udid=args.udid)
    if args.watch:
        success = watcher.watch(
            duration_seconds=args.duration,
            bundle_id=args.bundle_id,
            predicate=args.predicate,
            verbose=args.verbose,
            json_mode=args.json,
        )
    else:
        success = watcher.show_since(
            since_duration=args.since,
            bundle_id=args.bundle_id,
            predicate=args.predicate,
            verbose=args.verbose,
            json_mode=args.json,
        )
    if not success:
        sys.exit(1)
    if not args.json and not args.watch:
        print(f"\n{watcher.get_summary()}")
    if watcher.hang_events:
        cache_id = watcher.save_to_cache()
        print(f"Archive saved: {cache_id}", file=sys.stderr)
    sys.exit(0)


if __name__ == "__main__":
    main()
