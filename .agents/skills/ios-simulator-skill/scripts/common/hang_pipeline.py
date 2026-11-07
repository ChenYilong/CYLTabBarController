#!/usr/bin/env python3
"""HangBuster filter pipeline — pure functions, no I/O.

Stages: parse → normalise → threshold → bucket → cluster → aggregate → rank → format.

Each function is independently testable; the worker and the `--stop` path both
compose them. Scoped to hang detection for now (AHA — promote to a generic
log-filter module when a second consumer needs it).

Token budgets are enforced via a documented char/4 heuristic
(`estimate_tokens`) — accurate to within ~10% of real tokenizers and
dependency-free.
"""

from __future__ import annotations

import hashlib
import itertools
import json
import math
import re
from collections.abc import Callable
from dataclasses import asdict, dataclass, field
from datetime import datetime
from enum import StrEnum

# === CONSTANTS ===

FINGERPRINT_VERSION = 2
"""Bump when normalise_message, compute_fingerprint, or severity boundaries change.
`--diff` skips structural comparison across mismatched versions.

v2 (2026-05): compute_fingerprint() now hashes its input with sha256[:16].
v1 used the raw symbol / normalised prefix — collision risk when heavy upstream
normalisation reduced distinct messages to identical prefixes."""

_HEX_ADDR = re.compile(r"0x[0-9a-fA-F]{4,}")
_PID_REF = re.compile(r"\bpid[:= ]\s*\d+\b", re.IGNORECASE)
_BARE_INT = re.compile(r"\b\d{4,}\b")
_WHITESPACE = re.compile(r"\s+")
_BOILERPLATE_PREFIXES = (
    "Hang detected by RunningBoard:",
    "Hang detected:",
    "[RunningBoard]",
)
_SYMBOL_PATTERNS = [
    re.compile(r"([+-]?\[[A-Za-z_][\w]*\s+[A-Za-z_][\w:]*\])"),  # [Foo bar:] / +[Foo bar:]
    re.compile(r"\b([A-Z][A-Za-z0-9_]+\.[A-Za-z_][\w]+(?:\([^)]*\))?)\b"),  # Swift Foo.bar()
]

_LOG_LINE_PATTERN = re.compile(
    r"^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+(?:[+-]\d{4})?)"
    r"\s+0x[\da-f]+"
    r"\s+\S+"
    r"\s+0x[\da-f]+"
    r"\s+(\d+)"
    r"\s+\d+"
    r"\s+([^:]+):"
    r"\s*(.*)",
    re.IGNORECASE,
)

_DURATION_PATTERNS = [
    # Order matters: ms before s, so "487ms" doesn't get parsed as 487 seconds.
    re.compile(r"(\d+(?:\.\d+)?)\s*(?:ms|milliseconds?)\b", re.IGNORECASE),
    re.compile(r"(\d+(?:\.\d+)?)\s*(?:s|seconds?)\b", re.IGNORECASE),
]


# === TYPES ===


class Severity(StrEnum):
    """Hang severity bucket. String-valued for stable JSON serialisation."""

    MINOR = "minor"
    WARN = "warn"
    CRITICAL = "critical"
    FROZEN = "frozen"


_SEVERITY_WEIGHT = {
    Severity.MINOR: 1,
    Severity.WARN: 2,
    Severity.CRITICAL: 4,
    Severity.FROZEN: 8,
}


@dataclass
class NormalisedEvent:
    """A single hang event after parse + normalise + bucket."""

    delta_ms: int
    process: str
    pid: int
    duration_ms: float
    severity: Severity
    symbol: str | None
    message_prefix: str
    fingerprint: str
    raw_message: str = ""


@dataclass
class Cluster:
    """A group of NormalisedEvents sharing a fingerprint."""

    fingerprint: str
    count: int
    max_duration_ms: float
    total_duration_ms: float
    first_delta_ms: int
    severity: Severity
    symbol_or_prefix: str
    sample_event: NormalisedEvent
    auto_sample: dict | None = None
    auto_samples: list[dict] | None = None


@dataclass
class SessionSummary:
    """End-state summary of a session. Persisted to summary.json."""

    session_id: str
    started_at: str
    duration_ms: int
    event_count: int
    dropped_below_threshold: int
    matched_lines: int
    total_lines: int
    clusters: list[Cluster]
    aggregates: dict
    fingerprint_version: int = FINGERPRINT_VERSION


# === STAGE 1: PARSE ===


def parse_log_line(line: str) -> dict | None:
    """Parse one `xcrun simctl spawn log stream` line into a raw event dict.

    Returns ``None`` for non-log lines or lines that don't describe a hang.
    """
    if not line.strip():
        return None
    match = _LOG_LINE_PATTERN.match(line)
    if not match:
        return None
    timestamp_str, pid_str, process_name, message = match.groups()
    message = message.strip()
    if not is_hang_message(message):
        return None
    event: dict = {
        "timestamp": timestamp_str.strip(),
        "pid": int(pid_str),
        "process": process_name.strip(),
        "message": message,
    }
    duration_ms = extract_duration_ms(message)
    if duration_ms is not None:
        event["duration_ms"] = duration_ms
    return event


def is_hang_message(message: str) -> bool:
    """Return True if message text describes a hang/stall/watchdog event."""
    lower = message.lower()
    return any(kw in lower for kw in ("hang", "stall", "unresponsive", "watchdog", "jetsam"))


def extract_duration_ms(message: str) -> float | None:
    """Parse hang duration from message text. Returns milliseconds."""
    match = _DURATION_PATTERNS[0].search(message)
    if match:
        return float(match.group(1))
    match = _DURATION_PATTERNS[1].search(message)
    if match:
        return float(match.group(1)) * 1000
    return None


# === STAGE 2: NORMALISE ===


def normalise_message(message: str, max_len: int = 40) -> str:
    """Strip boilerplate, redact volatile tokens, truncate to ``max_len``."""
    text = message
    for prefix in _BOILERPLATE_PREFIXES:
        if text.startswith(prefix):
            text = text[len(prefix) :].lstrip()
            break
    text = _HEX_ADDR.sub("<addr>", text)
    text = _PID_REF.sub("<pid>", text)
    text = _BARE_INT.sub("<n>", text)
    text = _WHITESPACE.sub(" ", text).strip()
    if len(text) > max_len:
        text = text[:max_len].rstrip()
    return text


def extract_symbol(message: str) -> str | None:
    """Return the first Obj-C / Swift symbol mention if present."""
    for pattern in _SYMBOL_PATTERNS:
        match = pattern.search(message)
        if match:
            return match.group(1)
    return None


# === STAGE 3: THRESHOLD ===


def above_threshold(duration_ms: float | None, min_hang_ms: int) -> bool:
    """Drop events with no duration or below the minimum hang threshold."""
    return duration_ms is not None and duration_ms >= min_hang_ms


# === STAGE 4: SEVERITY BUCKET ===


def bucket_severity(duration_ms: float) -> Severity:
    """Map ms to a severity band."""
    if duration_ms < 250:
        return Severity.MINOR
    if duration_ms < 500:
        return Severity.WARN
    if duration_ms < 2000:
        return Severity.CRITICAL
    return Severity.FROZEN


# === STAGE 5: NORMALISED EVENT + FINGERPRINT ===


def build_normalised_event(
    raw_event: dict, session_start_ms: int, current_ms: int | None = None
) -> NormalisedEvent | None:
    """Combine stages 2 + 4 + fingerprint into one ``NormalisedEvent``.

    Returns ``None`` if duration is missing — threshold filtering should have
    dropped these already, but we guard for safety.
    """
    duration = raw_event.get("duration_ms")
    if duration is None:
        return None
    if current_ms is None:
        current_ms = _timestamp_to_ms(raw_event.get("timestamp", ""))
    delta_ms = max(0, current_ms - session_start_ms) if current_ms else 0
    message = raw_event.get("message", "")
    symbol = extract_symbol(message)
    prefix = normalise_message(message)
    fingerprint = compute_fingerprint(symbol, prefix)
    return NormalisedEvent(
        delta_ms=delta_ms,
        process=raw_event.get("process", "unknown"),
        pid=int(raw_event.get("pid", 0)),
        duration_ms=float(duration),
        severity=bucket_severity(float(duration)),
        symbol=symbol,
        message_prefix=prefix,
        fingerprint=fingerprint,
        raw_message=message,
    )


def compute_fingerprint(symbol: str | None, message_prefix: str) -> str:
    """Stable identity hash for clustering and diff.

    Hashed (sha256[:16]) so distinct messages with overlapping normalised
    prefixes don't collide into the same cluster. Symbol when present (high
    signal); otherwise normalised message prefix is the hash input.

    The human-readable label lives in ``Cluster.symbol_or_prefix`` — the
    fingerprint is purely an identity key.
    """
    key = f"sym:{symbol}" if symbol else f"msg:{message_prefix}"
    return f"fp:{hashlib.sha256(key.encode()).hexdigest()[:16]}"


def _timestamp_to_ms(ts: str) -> int:
    """Parse an os_log timestamp like '2026-05-22 14:30:52.123456-0800' to ms epoch."""
    if not ts:
        return 0
    try:
        # `%z` requires a colon-less offset, which is what os_log emits.
        dt = datetime.strptime(ts, "%Y-%m-%d %H:%M:%S.%f%z")
    except ValueError:
        try:
            dt = datetime.strptime(ts.split(".", maxsplit=1)[0], "%Y-%m-%d %H:%M:%S")
        except ValueError:
            return 0
    return int(dt.timestamp() * 1000)


# === STAGE 6: CLUSTER ===


def cluster_events(events: list[NormalisedEvent]) -> list[Cluster]:
    """Group events by fingerprint, aggregating count + duration stats."""
    by_fp: dict[str, list[NormalisedEvent]] = {}
    for event in events:
        by_fp.setdefault(event.fingerprint, []).append(event)
    clusters: list[Cluster] = []
    for fingerprint, group in by_fp.items():
        durations = [e.duration_ms for e in group]
        deltas = [e.delta_ms for e in group]
        max_severity = max(group, key=lambda e: _SEVERITY_WEIGHT[e.severity]).severity
        sample = max(group, key=lambda e: e.duration_ms)
        clusters.append(
            Cluster(
                fingerprint=fingerprint,
                count=len(group),
                max_duration_ms=max(durations),
                total_duration_ms=sum(durations),
                first_delta_ms=min(deltas),
                severity=max_severity,
                symbol_or_prefix=sample.symbol or sample.message_prefix,
                sample_event=sample,
            )
        )
    return clusters


# === STAGE 7: AGGREGATE ===


def detect_temporal_bursts(
    events: list[NormalisedEvent], window_ms: int = 1000, min_count: int = 3
) -> list[dict]:
    """Find windows containing ``min_count`` or more events within ``window_ms``."""
    if not events:
        return []
    sorted_events = sorted(events, key=lambda e: e.delta_ms)
    bursts: list[dict] = []
    i = 0
    while i < len(sorted_events):
        window_start = sorted_events[i].delta_ms
        j = i
        while j < len(sorted_events) and sorted_events[j].delta_ms - window_start <= window_ms:
            j += 1
        burst_size = j - i
        if burst_size >= min_count:
            bursts.append(
                {
                    "starts_at_ms": window_start,
                    "ends_at_ms": sorted_events[j - 1].delta_ms,
                    "count": burst_size,
                }
            )
            i = j
        else:
            i += 1
    return bursts


def detect_quiet_periods(events: list[NormalisedEvent], threshold_ms: int = 5000) -> list[dict]:
    """Find gaps between adjacent events that exceed ``threshold_ms``."""
    if len(events) < 2:
        return []
    sorted_events = sorted(events, key=lambda e: e.delta_ms)
    periods: list[dict] = []
    for prev, curr in itertools.pairwise(sorted_events):
        gap = curr.delta_ms - prev.delta_ms
        if gap >= threshold_ms:
            periods.append({"from_ms": prev.delta_ms, "to_ms": curr.delta_ms, "gap_ms": gap})
    return periods


def process_distribution(events: list[NormalisedEvent]) -> dict[str, int]:
    """Count events per process name."""
    dist: dict[str, int] = {}
    for event in events:
        dist[event.process] = dist.get(event.process, 0) + 1
    return dist


# === STAGE 8: RANK ===


def rank_clusters(clusters: list[Cluster], top_n: int | None = None) -> list[Cluster]:
    """Sort by severity_weight * max_duration_ms * log(count + 1), descending."""

    def score(cluster: Cluster) -> float:
        weight = _SEVERITY_WEIGHT[cluster.severity]
        return weight * cluster.max_duration_ms * math.log(cluster.count + 1)

    ranked = sorted(clusters, key=score, reverse=True)
    return ranked if top_n is None else ranked[:top_n]


# === STAGE 9: FORMAT ===


def format_l0(summary: SessionSummary) -> str:
    """Single-line status (~20 tokens). Cache-friendly for agent context."""
    if not summary.clusters:
        return f"Session {summary.session_id}: no hangs above threshold."
    top = summary.clusters[0]
    critical = sum(
        1 for c in summary.clusters if c.severity in (Severity.CRITICAL, Severity.FROZEN)
    )
    return (
        f"Session {summary.session_id}: {summary.duration_ms / 1000:.1f}s, "
        f"{summary.event_count} hangs ({critical} critical), top: "
        f"{top.symbol_or_prefix} {top.max_duration_ms:.0f}ms ×{top.count}"
    )


def format_l1(summary: SessionSummary, top_n: int = 3) -> str:
    """Default ~80-120 token output: header + top-N clusters + drill hint."""
    if not summary.clusters:
        return (
            f"Session {summary.session_id}: {summary.duration_ms / 1000:.1f}s, "
            f"no hangs ≥ threshold (scanned {summary.matched_lines}/{summary.total_lines} lines).\n"
            f"Drill: hang_watcher.py --get-details {summary.session_id}"
        )
    lines = [
        f"Session {summary.session_id}: {summary.duration_ms / 1000:.1f}s captured, "
        f"{len(summary.clusters)} clusters ({summary.event_count} events)"
    ]
    icons = {
        Severity.MINOR: "·",
        Severity.WARN: "⚠",
        Severity.CRITICAL: "‼",
        Severity.FROZEN: "🛑",
    }
    for cluster in summary.clusters[:top_n]:
        icon = icons[cluster.severity]
        at = f"{cluster.first_delta_ms / 1000:.1f}s"
        lines.append(
            f"{icon} {cluster.max_duration_ms:.0f}ms × {cluster.count} — "
            f"{cluster.symbol_or_prefix} at {at}"
        )
    lines.append(f"Drill: hang_watcher.py --get-details {summary.session_id} [--cluster N]")
    return "\n".join(lines)


def format_l2(summary: SessionSummary) -> str:
    """Expanded ~300 token output: all clusters + aggregates."""
    parts = [format_l1(summary, top_n=len(summary.clusters))]
    sev_hist = _severity_histogram(summary.clusters)
    parts.append("Severity: " + ", ".join(f"{k}={v}" for k, v in sev_hist.items() if v))
    aggregates = summary.aggregates or {}
    bursts = aggregates.get("bursts", [])
    if bursts:
        burst_str = "; ".join(
            f"{b['count']} in {(b['ends_at_ms'] - b['starts_at_ms'])}ms @ {b['starts_at_ms'] / 1000:.1f}s"
            for b in bursts[:3]
        )
        parts.append(f"Bursts: {burst_str}")
    quiet = aggregates.get("quiet_periods", [])
    if quiet:
        parts.append(f"Quiet periods: {len(quiet)} (longest {max(q['gap_ms'] for q in quiet)}ms)")
    proc = aggregates.get("process_distribution", {})
    if len(proc) > 1:
        top_proc = sorted(proc.items(), key=lambda kv: kv[1], reverse=True)[:3]
        parts.append("Processes: " + ", ".join(f"{p}({c})" for p, c in top_proc))
    parts.append(
        f"Lines: matched {summary.matched_lines}/{summary.total_lines}, "
        f"dropped {summary.dropped_below_threshold} sub-threshold"
    )
    return "\n".join(parts)


def format_cluster_detail(cluster: Cluster, events: list[NormalisedEvent]) -> str:
    """L3: per-event detail for a single cluster, plus stack if sampled."""
    lines = [
        f"Cluster: {cluster.symbol_or_prefix}",
        f"  fingerprint={cluster.fingerprint} severity={cluster.severity.value}",
        f"  count={cluster.count} max={cluster.max_duration_ms:.0f}ms "
        f"total={cluster.total_duration_ms:.0f}ms first@{cluster.first_delta_ms}ms",
    ]
    for event in events[:20]:
        lines.append(
            f"  · t={event.delta_ms}ms duration={event.duration_ms:.0f}ms "
            f"process={event.process} pid={event.pid}"
        )
        if event.raw_message:
            lines.append(f"      msg: {event.raw_message[:120]}")
    for sample in _iter_auto_samples(cluster):
        lines.extend(_format_auto_sample(sample))
    return "\n".join(lines)


def _iter_auto_samples(cluster: Cluster) -> list[dict]:
    """Yield auto-samples for a cluster, preferring the multi-kind list and
    falling back to the legacy single ``auto_sample`` field for old summaries."""
    if cluster.auto_samples:
        return cluster.auto_samples
    if cluster.auto_sample:
        return [cluster.auto_sample]
    return []


_ADDRESS_RE = re.compile(r"\[(0x[0-9a-fA-F]+)\]")


def extract_stack_addresses(stack: str) -> list[str]:
    """Return unique ``0x...`` addresses from a sample/spindump stack, in order.

    Both ``sample`` and ``spindump`` print frame addresses in ``[0xADDR]``
    notation at the end of each frame line. We match that form and only that
    form — looser regexes risk grabbing unrelated hex tokens.
    """
    seen: set[str] = set()
    ordered: list[str] = []
    for match in _ADDRESS_RE.finditer(stack):
        addr = match.group(1)
        if addr not in seen:
            seen.add(addr)
            ordered.append(addr)
    return ordered


def symbolicate_stack(stack: str, resolver: Callable[[list[str]], dict[str, str]]) -> str:
    """Rewrite ``[0xADDR]`` tokens with ``[0xADDR → resolved]`` using ``resolver``.

    ``resolver`` takes the deduped address list and returns ``{addr: text}``.
    Addresses with no resolution (or a resolved text equal to the address
    itself) are left unchanged so we don't add noise where atos couldn't help.
    """
    addresses = extract_stack_addresses(stack)
    if not addresses:
        return stack
    resolved = resolver(addresses) or {}

    def _replace(match: re.Match) -> str:
        addr = match.group(1)
        text = resolved.get(addr)
        if not text or text.strip() == addr:
            return match.group(0)
        return f"[{addr} → {text.strip()}]"

    return _ADDRESS_RE.sub(_replace, stack)


def _format_auto_sample(sample: dict) -> list[str]:
    """Render one auto-sample block: header + first 10 stack lines or a reason."""
    kind = sample.get("kind") or "auto-sample"
    stack = sample.get("stack")
    if not stack:
        return [f"{kind}: unavailable ({sample.get('reason', 'unknown')})"]
    # Stack is multi-line text from `sample` or `spindump`. Show the first 10
    # non-empty lines so the cluster detail stays bounded.
    head = [line for line in stack.splitlines() if line.strip()][:10]
    return [f"{kind} stack (top 10):", *(f"  {line}" for line in head)]


def format_diff(diff: dict) -> str:
    """Render a diff_sessions() result for human + agent consumption."""
    if diff.get("version_mismatch"):
        return (
            f"⚠ fingerprint_version mismatch: A={diff['fingerprint_version_a']} "
            f"B={diff['fingerprint_version_b']}. Structural compare skipped."
        )
    new = diff.get("new_clusters", [])
    resolved = diff.get("resolved_clusters", [])
    drift = diff.get("drift", [])
    stable = diff.get("stable_count", 0)
    verdict = diff.get("verdict", "no change")
    lines = [f"Diff {diff['session_a']} → {diff['session_b']}: {verdict}"]
    if new:
        lines.append(f"New ({len(new)}):")
        for cluster in new[:5]:
            lines.append(
                f"  + {cluster['severity']} {cluster['max_duration_ms']:.0f}ms × "
                f"{cluster['count']} — {cluster['symbol_or_prefix']}"
            )
    if resolved:
        lines.append(f"Resolved ({len(resolved)}):")
        for cluster in resolved[:5]:
            lines.append(
                f"  - {cluster['severity']} {cluster['max_duration_ms']:.0f}ms × "
                f"{cluster['count']} — {cluster['symbol_or_prefix']}"
            )
    if drift:
        lines.append(f"Drift ({len(drift)}):")
        for entry in drift[:5]:
            # inf delta (0 → N) renders as "new"; finite deltas keep the % suffix.
            delta = entry["delta_pct"]
            delta_str = "new" if delta == float("inf") else f"{delta:+.0f}%"
            lines.append(
                f"  ~ {entry['symbol_or_prefix']}: "
                f"{entry['max_duration_ms_a']:.0f} → {entry['max_duration_ms_b']:.0f}ms "
                f"({delta_str})"
            )
    if stable:
        lines.append(f"Stable: {stable} cluster(s) unchanged")
    return "\n".join(lines)


def _severity_histogram(clusters: list[Cluster]) -> dict[str, int]:
    """Total event count per severity band across clusters."""
    hist = {s.value: 0 for s in Severity}
    for cluster in clusters:
        hist[cluster.severity.value] += cluster.count
    return hist


# === STAGE 10: TOKEN BUDGET ===


def estimate_tokens(text: str) -> int:
    """Documented char/4 heuristic. Real tokenizers differ ~10%; tests use this estimator."""
    return len(text) // 4


def compress_to_budget(
    summary: SessionSummary, max_tokens: int | None, default_top_n: int = 3
) -> str:
    """Pick the densest level that fits ``max_tokens``.

    Order: L2 (full) → L1 (top-N) → L0 (one-liner). When ``max_tokens`` is
    ``None`` we return L1 unconditionally.
    """
    if max_tokens is None:
        return format_l1(summary, top_n=default_top_n)
    if max_tokens >= 200:
        candidate = format_l2(summary)
        if estimate_tokens(candidate) <= max_tokens:
            return candidate
    if max_tokens >= 60:
        candidate = format_l1(summary, top_n=default_top_n)
        if estimate_tokens(candidate) <= max_tokens:
            return candidate
        # Shrink top-N until it fits, never below 1.
        for n in (2, 1):
            candidate = format_l1(summary, top_n=n)
            if estimate_tokens(candidate) <= max_tokens:
                return candidate
    return format_l0(summary)


# === DIFF ===


def diff_sessions(
    summary_a: SessionSummary, summary_b: SessionSummary, drift_threshold_pct: float = 20.0
) -> dict:
    """Compare two SessionSummary instances. Returns a dict structured for format_diff."""
    if summary_a.fingerprint_version != summary_b.fingerprint_version:
        return {
            "session_a": summary_a.session_id,
            "session_b": summary_b.session_id,
            "version_mismatch": True,
            "fingerprint_version_a": summary_a.fingerprint_version,
            "fingerprint_version_b": summary_b.fingerprint_version,
            "verdict": "skipped (version mismatch)",
        }
    a_map = {c.fingerprint: c for c in summary_a.clusters}
    b_map = {c.fingerprint: c for c in summary_b.clusters}
    new_keys = b_map.keys() - a_map.keys()
    resolved_keys = a_map.keys() - b_map.keys()
    shared_keys = a_map.keys() & b_map.keys()
    drift: list[dict] = []
    stable = 0
    for key in shared_keys:
        ca, cb = a_map[key], b_map[key]
        if ca.max_duration_ms == 0 and cb.max_duration_ms == 0:
            stable += 1
            continue
        if ca.max_duration_ms == 0:
            # 0 → N: a previously-silent cluster now hangs; treat as max worsening.
            delta_pct: float = float("inf")
        elif cb.max_duration_ms == 0:
            # N → 0: cluster present in A but flat in B; fully improved.
            delta_pct = -100.0
        else:
            delta_pct = (cb.max_duration_ms - ca.max_duration_ms) / ca.max_duration_ms * 100
        if delta_pct == float("inf") or abs(delta_pct) >= drift_threshold_pct:
            drift.append(
                {
                    "fingerprint": key,
                    "symbol_or_prefix": cb.symbol_or_prefix,
                    "max_duration_ms_a": ca.max_duration_ms,
                    "max_duration_ms_b": cb.max_duration_ms,
                    "delta_pct": delta_pct,
                }
            )
        else:
            stable += 1
    new_clusters = [_cluster_to_dict(b_map[k]) for k in new_keys]
    resolved_clusters = [_cluster_to_dict(a_map[k]) for k in resolved_keys]
    new_critical = sum(
        1 for c in new_clusters if c["severity"] in (Severity.CRITICAL.value, Severity.FROZEN.value)
    )
    if new_critical:
        verdict = f"regression: {new_critical} new critical"
    elif new_clusters:
        verdict = f"regression: {len(new_clusters)} new minor"
    elif resolved_clusters and not drift:
        verdict = f"improvement: {len(resolved_clusters)} resolved"
    elif drift:
        worsened = sum(1 for d in drift if d["delta_pct"] > 0)
        verdict = f"drift: {worsened} worsened, {len(drift) - worsened} improved"
    else:
        verdict = "no change"
    return {
        "session_a": summary_a.session_id,
        "session_b": summary_b.session_id,
        "version_mismatch": False,
        "new_clusters": new_clusters,
        "resolved_clusters": resolved_clusters,
        "drift": drift,
        "stable_count": stable,
        "verdict": verdict,
    }


def _cluster_to_dict(cluster: Cluster) -> dict:
    """Lightweight dict view for diff output (skips full sample_event for token economy)."""
    return {
        "fingerprint": cluster.fingerprint,
        "symbol_or_prefix": cluster.symbol_or_prefix,
        "severity": cluster.severity.value,
        "count": cluster.count,
        "max_duration_ms": cluster.max_duration_ms,
        "first_delta_ms": cluster.first_delta_ms,
    }


# === SERIALISATION HELPERS ===


def cluster_to_json(cluster: Cluster) -> dict:
    """JSON-serialisable representation of a Cluster (handles enum + nested dataclass)."""
    # asdict() already serialises Severity (StrEnum) members via their string value.
    return asdict(cluster)


def summary_to_json(summary: SessionSummary) -> dict:
    """JSON-serialisable representation of a SessionSummary."""
    return {
        "session_id": summary.session_id,
        "started_at": summary.started_at,
        "duration_ms": summary.duration_ms,
        "event_count": summary.event_count,
        "dropped_below_threshold": summary.dropped_below_threshold,
        "matched_lines": summary.matched_lines,
        "total_lines": summary.total_lines,
        "fingerprint_version": summary.fingerprint_version,
        "clusters": [cluster_to_json(c) for c in summary.clusters],
        "aggregates": summary.aggregates,
    }


def summary_from_json(payload: dict) -> SessionSummary:
    """Rehydrate a SessionSummary from disk JSON."""
    clusters = [_cluster_from_json(c) for c in payload.get("clusters", [])]
    return SessionSummary(
        session_id=payload["session_id"],
        started_at=payload["started_at"],
        duration_ms=payload["duration_ms"],
        event_count=payload["event_count"],
        dropped_below_threshold=payload.get("dropped_below_threshold", 0),
        matched_lines=payload.get("matched_lines", 0),
        total_lines=payload.get("total_lines", 0),
        clusters=clusters,
        aggregates=payload.get("aggregates", {}),
        fingerprint_version=payload.get("fingerprint_version", 1),
    )


def _cluster_from_json(payload: dict) -> Cluster:
    sample_payload = payload["sample_event"]
    sample = NormalisedEvent(
        delta_ms=sample_payload["delta_ms"],
        process=sample_payload["process"],
        pid=sample_payload["pid"],
        duration_ms=sample_payload["duration_ms"],
        severity=Severity(sample_payload["severity"]),
        symbol=sample_payload.get("symbol"),
        message_prefix=sample_payload["message_prefix"],
        fingerprint=sample_payload["fingerprint"],
        raw_message=sample_payload.get("raw_message", ""),
    )
    return Cluster(
        fingerprint=payload["fingerprint"],
        count=payload["count"],
        max_duration_ms=payload["max_duration_ms"],
        total_duration_ms=payload["total_duration_ms"],
        first_delta_ms=payload["first_delta_ms"],
        severity=Severity(payload["severity"]),
        symbol_or_prefix=payload["symbol_or_prefix"],
        sample_event=sample,
        auto_sample=payload.get("auto_sample"),
        auto_samples=payload.get("auto_samples"),
    )


def event_to_jsonl(event: NormalisedEvent) -> str:
    """Encode one normalised event as a single JSONL line."""
    return json.dumps(asdict(event), separators=(",", ":"))


def event_from_jsonl(line: str) -> NormalisedEvent:
    """Decode a single JSONL line back to NormalisedEvent."""
    payload = json.loads(line)
    return NormalisedEvent(
        delta_ms=payload["delta_ms"],
        process=payload["process"],
        pid=payload["pid"],
        duration_ms=payload["duration_ms"],
        severity=Severity(payload["severity"]),
        symbol=payload.get("symbol"),
        message_prefix=payload["message_prefix"],
        fingerprint=payload["fingerprint"],
        raw_message=payload.get("raw_message", ""),
    )


# === BUILDERS ===


@dataclass
class SummaryBuilder:
    """Compose clusters + aggregates into a SessionSummary in one place."""

    session_id: str
    started_at: str
    duration_ms: int
    matched_lines: int = 0
    total_lines: int = 0
    dropped_below_threshold: int = 0
    extras: dict = field(default_factory=dict)

    def build(
        self,
        events: list[NormalisedEvent],
        top_n: int | None = None,
        auto_samples_by_fp: dict[str, list[dict]] | None = None,
    ) -> SessionSummary:
        """Cluster, aggregate, rank, and emit a SessionSummary.

        ``auto_samples_by_fp`` attaches per-fingerprint stack captures (from
        ``--auto-sample`` / ``--auto-spindump``) onto the matching clusters so
        they survive into ``summary.json``.
        """
        clusters = rank_clusters(cluster_events(events), top_n=top_n)
        if auto_samples_by_fp:
            for cluster in clusters:
                samples = auto_samples_by_fp.get(cluster.fingerprint)
                if samples:
                    cluster.auto_samples = samples
        aggregates = {
            "bursts": detect_temporal_bursts(events),
            "quiet_periods": detect_quiet_periods(events),
            "process_distribution": process_distribution(events),
        }
        aggregates.update(self.extras)
        return SessionSummary(
            session_id=self.session_id,
            started_at=self.started_at,
            duration_ms=self.duration_ms,
            event_count=len(events),
            dropped_below_threshold=self.dropped_below_threshold,
            matched_lines=self.matched_lines,
            total_lines=self.total_lines,
            clusters=clusters,
            aggregates=aggregates,
        )
