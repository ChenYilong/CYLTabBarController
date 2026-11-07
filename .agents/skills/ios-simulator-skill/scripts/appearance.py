#!/usr/bin/env python3
"""
iOS Simulator Appearance Manager

Control dark mode, dynamic type size, increase contrast, locale, and region.
Wraps xcrun simctl ui and defaults write for appearance testing.

Usage:
  python scripts/appearance.py --theme dark
  python scripts/appearance.py --contrast high
  python scripts/appearance.py --text-size AX3
  python scripts/appearance.py --locale ar --region SA --bundle-id com.myapp
  python scripts/appearance.py --reset

RTL locales: ar, he, fa, ur, yi (app must restart to reflow layout).
"""

import argparse
import json
import subprocess
import sys

from common import resolve_udid

# === CONSTANTS ===

# Map friendly size aliases to xcrun simctl content_size tokens
TEXT_SIZE_MAP: dict[str, str] = {
    "XS": "extra-small",
    "S": "small",
    "M": "medium",
    "L": "large",
    "XL": "extra-large",
    "XXL": "extra-extra-large",
    "XXXL": "extra-extra-extra-large",
    "AX1": "accessibility-medium",
    "AX2": "accessibility-large",
    "AX3": "accessibility-extra-large",
    "AX4": "accessibility-extra-extra-large",
    "AX5": "accessibility-extra-extra-extra-large",
}

# Locales that require RTL layout direction
RTL_LOCALES: frozenset[str] = frozenset({"ar", "he", "fa", "ur", "yi"})

# Map --contrast values to xcrun simctl increase_contrast tokens
CONTRAST_MAP: dict[str, str] = {"high": "enabled", "normal": "disabled"}

# Default appearance values used by --reset
DEFAULT_THEME = "light"
DEFAULT_CONTRAST = "normal"
DEFAULT_TEXT_SIZE = "M"
DEFAULT_LOCALE = "en"
DEFAULT_REGION = "US"


# === APPEARANCE MANAGER ===


class AppearanceManager:
    """Manages iOS simulator appearance: theme, dynamic type, contrast, and locale."""

    def __init__(self, udid: str | None = None):
        """Initialize appearance manager.

        Args:
            udid: Optional device UDID (auto-detects booted simulator if None)
        """
        self.udid = udid

    # === PUBLIC API ===

    def set_theme(self, theme: str) -> tuple[bool, str]:
        """Switch simulator between light and dark appearance.

        Args:
            theme: 'light' or 'dark'

        Returns:
            (success, message)
        """
        cmd = ["xcrun", "simctl", "ui", self.udid, "appearance", theme]
        return self._run(cmd, f"Theme set: {theme}")

    def set_text_size(self, alias: str) -> tuple[bool, str]:
        """Set dynamic type content size.

        Args:
            alias: Friendly alias (XS, S, M, L, XL, XXL, XXXL, AX1-AX5)

        Returns:
            (success, message)
        """
        token = TEXT_SIZE_MAP.get(alias.upper())
        if not token:
            valid = ", ".join(TEXT_SIZE_MAP.keys())
            return False, f"Unknown text size '{alias}'. Valid: {valid}"

        cmd = ["xcrun", "simctl", "ui", self.udid, "content_size", token]
        return self._run(cmd, f"Text size set: {alias} ({token})")

    def set_contrast(self, mode: str) -> tuple[bool, str]:
        """Enable or disable Increase Contrast, then read it back to confirm.

        Uses simctl (not idb): Apple-maintained and no companion dependency.

        Args:
            mode: 'high' (Increase Contrast on) or 'normal'

        Returns:
            (success, message)
        """
        token = CONTRAST_MAP.get(mode)
        if not token:
            return False, f"Unknown contrast '{mode}'. Valid: {', '.join(CONTRAST_MAP)}"

        ok, msg = self._run(["xcrun", "simctl", "ui", self.udid, "increase_contrast", token], "")
        if not ok:
            return False, msg

        read_cmd = ["xcrun", "simctl", "ui", self.udid, "increase_contrast"]
        try:
            result = subprocess.run(read_cmd, capture_output=True, text=True, check=True)
        except subprocess.CalledProcessError as error:
            return False, error.stderr.strip() if error.stderr else "contrast read-back failed"

        actual = result.stdout.strip()
        if actual != token:
            return False, f"Contrast not applied: expected {token}, device reports {actual}"
        return True, f"Contrast set: {mode}"

    def set_locale(
        self,
        locale: str,
        region: str | None = None,
        bundle_id: str | None = None,
    ) -> tuple[bool, str]:
        """Write AppleLanguages and AppleLocale to simulator global defaults.

        Optionally restarts a specific app via bundle ID so the locale takes
        effect immediately. Without --bundle-id the change applies on next
        cold app launch.

        Args:
            locale: BCP-47 language code (e.g. 'en', 'ar', 'de')
            region: ISO 3166-1 alpha-2 region code (e.g. 'US', 'SA', 'IE')
            bundle_id: Optional app bundle ID — triggers terminate + launch

        Returns:
            (success, message)
        """
        apple_locale = f"{locale}_{region}" if region else locale

        # Write AppleLanguages array
        lang_cmd = [
            "xcrun",
            "simctl",
            "spawn",
            self.udid,
            "defaults",
            "write",
            "-g",
            "AppleLanguages",
            "-array",
            locale,
        ]
        ok, msg = self._run(lang_cmd, "")
        if not ok:
            return False, f"Failed to write AppleLanguages: {msg}"

        # Write AppleLocale string
        locale_cmd = [
            "xcrun",
            "simctl",
            "spawn",
            self.udid,
            "defaults",
            "write",
            "-g",
            "AppleLocale",
            "-string",
            apple_locale,
        ]
        ok, msg = self._run(locale_cmd, "")
        if not ok:
            return False, f"Failed to write AppleLocale: {msg}"

        is_rtl = locale in RTL_LOCALES
        rtl_note = " [RTL layout]" if is_rtl else ""
        summary = f"Locale set: {apple_locale}{rtl_note}"

        if bundle_id:
            restart_ok, restart_msg = self._restart_app(bundle_id)
            if restart_ok:
                summary += f" — app restarted: {bundle_id}"
            else:
                summary += f" — locale written but app restart failed: {restart_msg}"
        else:
            summary += " — restart app to apply"

        return True, summary

    def reset(self) -> tuple[bool, str]:
        """Reset theme, text size, contrast, and locale to system defaults.

        Returns:
            (success, message)
        """
        results: list[str] = []
        errors: list[str] = []

        ok, msg = self.set_theme(DEFAULT_THEME)
        (results if ok else errors).append(msg)

        ok, msg = self.set_text_size(DEFAULT_TEXT_SIZE)
        (results if ok else errors).append(msg)

        ok, msg = self.set_contrast(DEFAULT_CONTRAST)
        (results if ok else errors).append(msg)

        ok, msg = self.set_locale(DEFAULT_LOCALE, DEFAULT_REGION)
        (results if ok else errors).append(msg)

        if errors:
            return False, f"Reset partial — errors: {'; '.join(errors)}"

        return True, "Appearance reset to defaults (light / M / normal contrast / en_US)"

    # === PRIVATE HELPERS ===

    def _run(self, cmd: list[str], success_message: str) -> tuple[bool, str]:
        """Run subprocess command and return (success, message).

        Args:
            cmd: Command list (never shell=True)
            success_message: Human-readable success summary

        Returns:
            (success, message)
        """
        try:
            subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
            )
            return True, success_message
        except subprocess.CalledProcessError as error:
            stderr = error.stderr.strip() if error.stderr else "unknown error"
            return False, stderr

    def _restart_app(self, bundle_id: str) -> tuple[bool, str]:
        """Terminate then launch an app by bundle ID.

        Args:
            bundle_id: App bundle ID

        Returns:
            (success, message)
        """
        terminate_cmd = ["xcrun", "simctl", "terminate", self.udid, bundle_id]
        # Terminate may fail if app is not running — that is acceptable
        subprocess.run(terminate_cmd, capture_output=True, check=False)

        launch_cmd = ["xcrun", "simctl", "launch", self.udid, bundle_id]
        try:
            subprocess.run(launch_cmd, capture_output=True, text=True, check=True)
            return True, f"Launched {bundle_id}"
        except subprocess.CalledProcessError as error:
            stderr = error.stderr.strip() if error.stderr else "launch failed"
            return False, stderr


# === CLI ===


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description=(
            "iOS Simulator Appearance Manager — control dark mode, "
            "dynamic type, increase contrast, locale, and region."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/appearance.py --theme dark
  python scripts/appearance.py --text-size AX3
  python scripts/appearance.py --contrast high
  python scripts/appearance.py --locale ar --region SA
  python scripts/appearance.py --locale de --region DE --bundle-id com.myapp
  python scripts/appearance.py --reset

RTL locales (ar, he, fa, ur, yi): app must restart to reflow layout.
Text sizes: XS S M L XL XXL XXXL AX1 AX2 AX3 AX4 AX5
        """,
    )

    parser.add_argument(
        "--theme",
        choices=["light", "dark"],
        help="Set light or dark appearance",
    )
    parser.add_argument(
        "--text-size",
        choices=list(TEXT_SIZE_MAP.keys()),
        metavar="{" + ",".join(TEXT_SIZE_MAP.keys()) + "}",
        help="Set dynamic type size (XS smallest, AX5 largest)",
    )
    parser.add_argument(
        "--contrast",
        choices=list(CONTRAST_MAP),
        help="Set Increase Contrast: high (on) or normal (off)",
    )
    parser.add_argument(
        "--locale",
        metavar="CODE",
        help="Set locale language code (e.g. en, de, ar, ja)",
    )
    parser.add_argument(
        "--region",
        metavar="CODE",
        help="Set region code (e.g. US, IE, SA). Used with --locale.",
    )
    parser.add_argument(
        "--bundle-id",
        metavar="BUNDLE_ID",
        help="App bundle ID to terminate+relaunch after locale change",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Reset theme, text size, contrast, and locale to system defaults",
    )
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed output",
    )

    args = parser.parse_args()

    # Guard: require at least one action
    if not any([args.theme, args.text_size, args.contrast, args.locale, args.reset]):
        parser.print_help()
        sys.exit(1)

    # Guard: --reset is incompatible with explicit appearance flags
    if args.reset and any([args.theme, args.text_size, args.contrast, args.locale]):
        print(
            "Error: --reset cannot be combined with --theme, --text-size, --contrast, or --locale",
            file=sys.stderr,
        )
        sys.exit(1)

    # Guard: --region without --locale is a no-op
    if args.region and not args.locale:
        print("Error: --region requires --locale", file=sys.stderr)
        sys.exit(1)

    # Guard: --bundle-id without --locale is ambiguous
    if args.bundle_id and not args.locale:
        print("Error: --bundle-id requires --locale", file=sys.stderr)
        sys.exit(1)

    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)

    manager = AppearanceManager(udid=udid)
    device_label = udid if udid else "booted"

    # Collect all requested operations
    operations: list[tuple[str, tuple[bool, str]]] = []

    if args.reset:
        operations.append(("reset", manager.reset()))
    else:
        if args.theme:
            operations.append(("theme", manager.set_theme(args.theme)))

        if args.text_size:
            operations.append(("text_size", manager.set_text_size(args.text_size)))

        if args.contrast:
            operations.append(("contrast", manager.set_contrast(args.contrast)))

        if args.locale:
            operations.append(
                (
                    "locale",
                    manager.set_locale(args.locale, args.region, args.bundle_id),
                )
            )

    overall_success = all(ok for _, (ok, _) in operations)

    if args.json:
        results = {action: {"success": ok, "message": msg} for action, (ok, msg) in operations}
        payload = {
            "success": overall_success,
            "udid": device_label,
            "results": results,
        }
        print(json.dumps(payload))
    elif args.verbose:
        print(f"Device: {device_label}")
        for action, (ok, msg) in operations:
            status = "OK" if ok else "FAIL"
            print(f"  [{status}] {action}: {msg}")
    else:
        for _, (_ok, msg) in operations:
            if msg:
                print(msg)

    sys.exit(0 if overall_success else 1)


if __name__ == "__main__":
    main()
