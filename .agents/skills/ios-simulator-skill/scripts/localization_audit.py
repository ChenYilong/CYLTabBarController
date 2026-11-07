#!/usr/bin/env python3
"""
iOS Localization Catalog Audit

Parses .xcstrings (JSON) or .strings/.stringsdict (plist) catalogs and reports:
  - Per-locale missing/untranslated keys
  - Keys in source but absent from catalog (missing)
  - Keys in catalog but absent from source (unused)
  - Format-specifier placeholder mismatches across locales

Pure file analysis — no simulator interaction required.

Usage:
    python scripts/localization_audit.py --catalog Localizable.xcstrings
    python scripts/localization_audit.py --catalog Localizable.xcstrings --source ./MyApp
    python scripts/localization_audit.py --catalog Localizable.xcstrings --strict
"""

import argparse
import json
import plistlib
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

# === TYPES ===


@dataclass
class LocaleGap:
    """A key that is missing or needs review in a specific locale."""

    key: str
    locale: str
    reason: str  # "missing", "needs_review", "new", "stale"


@dataclass
class PlaceholderMismatch:
    """A key where placeholder counts differ across locales."""

    key: str
    source_locale: str
    source_placeholders: list[str]
    offending_locale: str
    offending_placeholders: list[str]


@dataclass
class AuditReport:
    """Structured result of a full catalog audit."""

    catalog_path: str
    source_language: str
    total_keys: int
    locales: list[str]
    gaps: list[LocaleGap] = field(default_factory=list)
    missing_from_catalog: list[str] = field(default_factory=list)  # in source, not catalog
    unused_in_source: list[str] = field(default_factory=list)  # in catalog, not source
    placeholder_mismatches: list[PlaceholderMismatch] = field(default_factory=list)

    def has_findings(self) -> bool:
        return bool(
            self.gaps
            or self.missing_from_catalog
            or self.unused_in_source
            or self.placeholder_mismatches
        )

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


# === PLACEHOLDER EXTRACTION ===

# Matches %d, %@, %s, %lld, %ld, %f, %g, %i, %u and positional %1$@, %2$d etc.
# Length-modifier group (hh|h|ll|l|z|t|q) handles %lld, %lu, %ld, %hhu etc.
_PLACEHOLDER_RE = re.compile(
    r"%(?:\d+\$)?(?:[-+0 #]*)?(?:\d+)?(?:\.\d+)?(?:hh|h|ll|l|z|t|q)?[diouxXeEfgGcsSpaAqQzZtb@]"
)

# Swift source patterns for localized strings
_SWIFT_LOCALIZED_RE = re.compile(
    r'String\s*\(\s*localized\s*:\s*"([^"\\]*(?:\\.[^"\\]*)*)"|'
    r'NSLocalizedString\s*\(\s*"([^"\\]*(?:\\.[^"\\]*)*)"'
)


def _extract_placeholders(value: str) -> list[str]:
    """Extract all format specifiers from a string value."""
    return _PLACEHOLDER_RE.findall(value)


# === XCSTRINGS PARSER ===


def _parse_xcstrings(catalog_path: Path) -> tuple[str, dict[str, dict[str, Any]]]:
    """
    Parse an .xcstrings JSON catalog.

    Returns:
        (source_language, strings_dict)
        strings_dict maps key -> {locale -> {"state": ..., "value": ...}}
    """
    try:
        raw = json.loads(catalog_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in {catalog_path}: {exc}") from exc

    source_language: str = raw.get("sourceLanguage", "en")
    raw_strings: dict = raw.get("strings", {})

    strings: dict[str, dict[str, Any]] = {}
    for key, entry in raw_strings.items():
        localizations: dict = entry.get("localizations", {})
        strings[key] = {}
        for locale, loc_data in localizations.items():
            if "stringUnit" in loc_data:
                unit = loc_data["stringUnit"]
                strings[key][locale] = {
                    "state": unit.get("state", ""),
                    "value": unit.get("value", ""),
                }
            elif "variations" in loc_data:
                # Plural variations — grab first available unit for placeholder check
                variations = loc_data["variations"]
                plural = variations.get("plural", {})
                first_variant = next(iter(plural.values()), {})
                unit = first_variant.get("stringUnit", {})
                strings[key][locale] = {
                    "state": unit.get("state", ""),
                    "value": unit.get("value", ""),
                }

    return source_language, strings


# === LEGACY .strings / .stringsdict PARSER ===


def _parse_strings_file(catalog_path: Path) -> tuple[str, dict[str, dict[str, Any]]]:
    """
    Parse a legacy .strings or .stringsdict file via plistlib.

    .strings files are treated as a single-locale catalog whose locale is
    inferred from the path (e.g. en.lproj/Localizable.strings → "en").
    Returns a minimal structure compatible with the audit logic.
    """
    # Attempt to infer locale from parent directory (e.g. "en.lproj")
    parent = catalog_path.parent.name
    locale = parent.removesuffix(".lproj") if parent.endswith(".lproj") else "unknown"
    source_language = locale

    suffix = catalog_path.suffix.lower()

    if suffix == ".stringsdict":
        try:
            data = plistlib.loads(catalog_path.read_bytes())
        except Exception as exc:
            raise ValueError(f"Failed to parse .stringsdict {catalog_path}: {exc}") from exc
        # Each key maps to a plural rule dict — extract NSStringLocalizedFormatKey as value
        strings: dict[str, dict[str, Any]] = {}
        for key, plural_dict in data.items():
            value = plural_dict.get("NSStringLocalizedFormatKey", "")
            strings[key] = {locale: {"state": "translated", "value": value}}
        return source_language, strings

    # .strings — may be binary or XML plist, or legacy =; format
    plist_error: Exception | None = None
    try:
        data = plistlib.loads(catalog_path.read_bytes())
        strings = {k: {locale: {"state": "translated", "value": v}} for k, v in data.items()}
        return source_language, strings
    except Exception as exc:
        plist_error = exc

    # Fallback: text-format .strings  ("key" = "value";)
    _kv_re = re.compile(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"', re.MULTILINE)
    text_error: Exception | None = None
    try:
        try:
            text = catalog_path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            text_error = exc
            text = catalog_path.read_text(encoding="latin-1")
        strings = {}
        for match in _kv_re.finditer(text):
            k, v = match.group(1), match.group(2)
            strings[k] = {locale: {"state": "translated", "value": v}}
        return source_language, strings
    except Exception as exc:
        if text_error is None:
            text_error = exc

    raise ValueError(
        f"Failed to parse .strings file {catalog_path}: "
        f"plist error: {plist_error}; text-decode error: {text_error}"
    )


# === SWIFT SOURCE SCANNER ===


def _scan_swift_sources(source_dir: Path) -> set[str]:
    """
    Scan *.swift files under source_dir for localized string keys.

    Matches:
        String(localized: "key")
        NSLocalizedString("key", ...)

    Note: regex-based for v1 — swift-syntax AST parsing would be more robust
    for multiline literals and string interpolation edge-cases.
    """
    keys: set[str] = set()
    for swift_file in source_dir.rglob("*.swift"):
        try:
            content = swift_file.read_text(encoding="utf-8")
        except OSError:
            continue
        for match in _SWIFT_LOCALIZED_RE.finditer(content):
            key = match.group(1) or match.group(2)
            if key:
                keys.add(key)
    return keys


# === CORE AUDITOR ===


class LocalizationAuditor:
    """Audits an .xcstrings or legacy .strings catalog for localization gaps."""

    def __init__(self, catalog_path: Path, source_dir: Path | None = None):
        self.catalog_path = catalog_path
        self.source_dir = source_dir

    def _load_catalog(self) -> tuple[str, dict[str, dict[str, Any]]]:
        suffix = self.catalog_path.suffix.lower()
        if suffix == ".xcstrings":
            return _parse_xcstrings(self.catalog_path)
        if suffix in {".strings", ".stringsdict"}:
            return _parse_strings_file(self.catalog_path)
        raise ValueError(
            f"Unsupported catalog format '{suffix}'. "
            "Expected .xcstrings, .strings, or .stringsdict."
        )

    def _collect_gaps(
        self,
        strings: dict[str, dict[str, Any]],
        all_locales: set[str],
        source_language: str,
    ) -> list[LocaleGap]:
        """Find keys with missing or needs-review translations per locale."""
        gaps: list[LocaleGap] = []
        non_source_locales = all_locales - {source_language}

        for key, locale_map in strings.items():
            for locale in non_source_locales:
                if locale not in locale_map:
                    gaps.append(LocaleGap(key=key, locale=locale, reason="missing"))
                else:
                    state = locale_map[locale].get("state", "")
                    if state in {"needs_review", "new", "stale"}:
                        gaps.append(LocaleGap(key=key, locale=locale, reason=state))

        return sorted(gaps, key=lambda g: (g.locale, g.key))

    def _check_placeholder_mismatches(
        self,
        strings: dict[str, dict[str, Any]],
        source_language: str,
    ) -> list[PlaceholderMismatch]:
        """Verify placeholder counts match source language for every locale."""
        mismatches: list[PlaceholderMismatch] = []

        for key, locale_map in strings.items():
            source_entry = locale_map.get(source_language)
            if not source_entry:
                continue
            source_value = source_entry.get("value", "")
            source_placeholders = _extract_placeholders(source_value)

            for locale, entry in locale_map.items():
                if locale == source_language:
                    continue
                value = entry.get("value", "")
                if not value:
                    continue  # gaps already reported separately
                locale_placeholders = _extract_placeholders(value)
                # Note: only count is compared; positional-type swaps not detected
                if len(locale_placeholders) != len(source_placeholders):
                    mismatches.append(
                        PlaceholderMismatch(
                            key=key,
                            source_locale=source_language,
                            source_placeholders=source_placeholders,
                            offending_locale=locale,
                            offending_placeholders=locale_placeholders,
                        )
                    )

        return sorted(mismatches, key=lambda m: (m.offending_locale, m.key))

    def audit(self) -> AuditReport:
        """Run the full audit and return a structured report."""
        source_language, strings = self._load_catalog()

        all_locales: set[str] = set()
        for locale_map in strings.values():
            all_locales.update(locale_map.keys())

        report = AuditReport(
            catalog_path=str(self.catalog_path),
            source_language=source_language,
            total_keys=len(strings),
            locales=sorted(all_locales),
        )

        report.gaps = self._collect_gaps(strings, all_locales, source_language)
        report.placeholder_mismatches = self._check_placeholder_mismatches(strings, source_language)

        if self.source_dir:
            source_keys = _scan_swift_sources(self.source_dir)
            catalog_keys = set(strings.keys())
            report.missing_from_catalog = sorted(source_keys - catalog_keys)
            report.unused_in_source = sorted(catalog_keys - source_keys)

        return report


# === OUTPUT FORMATTING ===


def _format_default(report: AuditReport) -> str:
    """Compact summary — 3-5 lines."""
    gap_by_locale: dict[str, int] = {}
    for gap in report.gaps:
        gap_by_locale[gap.locale] = gap_by_locale.get(gap.locale, 0) + 1

    gap_summary = ", ".join(
        f"{count} in {locale}" for locale, count in sorted(gap_by_locale.items())
    )
    if not gap_summary:
        gap_summary = "none"

    lines = [
        f"Catalog: {report.total_keys} keys, {len(report.locales)} locales, "
        f"{len(report.gaps)} gaps.",
        f"Missing/needs-review: {gap_summary}.",
    ]

    if report.missing_from_catalog:
        lines.append(f"Missing from catalog: {len(report.missing_from_catalog)} keys.")
    if report.unused_in_source:
        lines.append(f"Unused in source: {len(report.unused_in_source)} keys.")
    if report.placeholder_mismatches:
        lines.append(f"Placeholder mismatches: {len(report.placeholder_mismatches)}.")

    if not report.has_findings():
        lines.append("No issues found.")

    return "\n".join(lines)


def _format_verbose(report: AuditReport) -> str:
    """Detailed listing of every finding."""
    sections: list[str] = [_format_default(report), ""]

    if report.gaps:
        sections.append("=== Translation Gaps ===")
        current_locale = None
        for gap in report.gaps:
            if gap.locale != current_locale:
                sections.append(f"\n[{gap.locale}]")
                current_locale = gap.locale
            sections.append(f"  {gap.reason:15s}  {gap.key}")

    if report.missing_from_catalog:
        sections.append("\n=== Keys in Source, Missing from Catalog ===")
        for key in report.missing_from_catalog:
            sections.append(f"  {key}")

    if report.unused_in_source:
        sections.append("\n=== Keys in Catalog, Unused in Source ===")
        for key in report.unused_in_source:
            sections.append(f"  {key}")

    if report.placeholder_mismatches:
        sections.append("\n=== Placeholder Mismatches ===")
        for m in report.placeholder_mismatches:
            sections.append(
                f"  [{m.offending_locale}] {m.key}\n"
                f"    {m.source_locale}: {m.source_placeholders}\n"
                f"    {m.offending_locale}: {m.offending_placeholders}"
            )

    return "\n".join(sections)


# === CLI ===


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Audit .xcstrings / .strings catalogs for localization gaps.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/localization_audit.py --catalog Localizable.xcstrings
  python scripts/localization_audit.py --catalog App.xcstrings --source ./MyApp
  python scripts/localization_audit.py --catalog App.xcstrings --strict --json
        """,
    )
    parser.add_argument(
        "--catalog",
        required=True,
        type=Path,
        metavar="PATH",
        help="Path to .xcstrings, .strings, or .stringsdict catalog file.",
    )
    parser.add_argument(
        "--source",
        type=Path,
        metavar="DIR",
        help="Swift source root for unused/missing key cross-reference.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit with non-zero status if any findings are present.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        dest="json_output",
        help="Output structured JSON report.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="List every gap, unused key, and placeholder mismatch.",
    )
    return parser


def main() -> None:
    parser = _build_parser()
    args = parser.parse_args()

    catalog_path: Path = args.catalog
    if not catalog_path.exists():
        print(f"Error: catalog not found: {catalog_path}", file=sys.stderr)
        sys.exit(1)

    source_dir: Path | None = args.source
    if source_dir is not None and not source_dir.is_dir():
        print(f"Error: source directory not found: {source_dir}", file=sys.stderr)
        sys.exit(1)

    try:
        auditor = LocalizationAuditor(catalog_path=catalog_path, source_dir=source_dir)
        report = auditor.audit()
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)

    if args.json_output:
        print(json.dumps(report.to_dict(), indent=2))
    elif args.verbose:
        print(_format_verbose(report))
    else:
        print(_format_default(report))

    if args.strict and report.has_findings():
        sys.exit(2)


if __name__ == "__main__":
    main()
