#!/usr/bin/env python3
"""
iOS Privacy & Permissions Manager

Grant/revoke/reset app permissions for testing permission flows.
Service names are the tokens `xcrun simctl privacy` accepts (verified
against Xcode 27 command line tools).

Usage: python scripts/privacy_manager.py --grant camera --bundle-id com.app
"""

import argparse
import subprocess
import sys
from datetime import datetime

from common import resolve_udid

# === SERVICE CATALOGUE ===

# Canonical service tokens accepted by `xcrun simctl privacy <device> <action> <service>`.
# Keep in sync with `xcrun simctl help privacy`; simctl fails with a bare
# NSPOSIXErrorDomain code=1 for anything not in this set, so we validate first.
SUPPORTED_SERVICES: dict[str, str] = {
    "all": "All services listed here",
    "calendar": "Calendar access",
    "calls": "Call history",
    "camera": "Camera access",
    "contacts": "Full contact details",
    "contacts-limited": "Basic contact info only",
    "location": "Location services while app is in use",
    "location-always": "Location services at all times",
    "media-library": "Media library access",
    "microphone": "Audio input access",
    "motion": "Motion & fitness data",
    "photos": "Full photo library access",
    "photos-add": "Adding photos to the library",
    "reminders": "Reminders access",
    "siri": "Use of the app with Siri",
}

# Legacy spellings kept working so existing scripts do not break.
SERVICE_ALIASES: dict[str, str] = {
    "mediaLibrary": "media-library",
    "medialibrary": "media-library",
    "photosAdd": "photos-add",
    "locationAlways": "location-always",
    "contactsLimited": "contacts-limited",
}


def canonicalise_service(service: str) -> str | None:
    """Resolve a service name to its simctl token, or None if unsupported.

    Args:
        service: Service name as supplied by the caller, possibly a legacy alias

    Returns:
        The canonical simctl token, or None if simctl would reject it
    """
    resolved = SERVICE_ALIASES.get(service, service)
    return resolved if resolved in SUPPORTED_SERVICES else None


class PrivacyManager:
    """Manages iOS app privacy and permissions."""

    # Retained as a class attribute for backwards compatibility.
    SUPPORTED_SERVICES = SUPPORTED_SERVICES

    def __init__(self, udid: str | None = None):
        """Initialize privacy manager.

        Args:
            udid: Optional device UDID (auto-detects booted simulator if None)
        """
        self.udid = udid

    def apply_permission(
        self,
        action: str,
        bundle_id: str,
        service: str,
        scenario: str | None = None,
        step: int | None = None,
    ) -> tuple[bool, str]:
        """
        Grant, revoke, or reset a privacy permission for an app.

        Args:
            action: One of "grant", "revoke", "reset"
            bundle_id: App bundle ID
            service: Service name (camera, microphone, location, ...)
            scenario: Test scenario name for audit trail
            step: Step number in test scenario

        Returns:
            Tuple of (success, message). On failure the message carries
            simctl's own stderr so the caller can see why.
        """
        token = canonicalise_service(service)
        if token is None:
            supported = ", ".join(SUPPORTED_SERVICES)
            return (False, f"Unknown service '{service}'. Supported: {supported}")

        cmd = [
            "xcrun",
            "simctl",
            "privacy",
            self.udid or "booted",
            action,
            token,
            bundle_id,
        ]

        try:
            subprocess.run(cmd, capture_output=True, check=True, text=True)
        except subprocess.CalledProcessError as error:
            detail = (error.stderr or error.stdout or "").strip()
            return (False, f"simctl privacy {action} {token} failed: {detail}")
        except FileNotFoundError:
            return (False, "xcrun not found. Install the Xcode command line tools.")

        self._log_audit(action, bundle_id, token, scenario, step)
        return (True, SUPPORTED_SERVICES[token])

    @staticmethod
    def _log_audit(
        action: str,
        bundle_id: str,
        service: str,
        scenario: str | None = None,
        step: int | None = None,
    ) -> None:
        """Log permission change to audit trail (for test tracking).

        Args:
            action: grant, revoke, or reset
            bundle_id: App bundle ID
            service: Service name
            scenario: Test scenario name
            step: Step number
        """
        # Could write to file, but for now just log to stdout for transparency
        timestamp = datetime.now().isoformat()
        location = f" (step {step})" if step else ""
        scenario_info = f" in {scenario}" if scenario else ""
        print(
            f"[Audit] {timestamp}: {action.upper()} {service} for {bundle_id}{scenario_info}{location}"
        )


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Manage iOS app privacy and permissions")

    # Required
    parser.add_argument("--bundle-id", required=True, help="App bundle ID (e.g., com.example.app)")

    # Action (mutually exclusive)
    action_group = parser.add_mutually_exclusive_group(required=True)
    action_group.add_argument(
        "--grant",
        help="Grant permission (service name or comma-separated list)",
    )
    action_group.add_argument(
        "--revoke", help="Revoke permission (service name or comma-separated list)"
    )
    action_group.add_argument(
        "--reset",
        help="Reset permission to default (service name or comma-separated list)",
    )
    action_group.add_argument(
        "--list",
        action="store_true",
        help="List all supported services",
    )

    # Test tracking
    parser.add_argument(
        "--scenario",
        help="Test scenario name for audit trail",
    )
    parser.add_argument("--step", type=int, help="Step number in test scenario")

    # Device
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )

    args = parser.parse_args()

    # List supported services
    if args.list:
        print("Supported Privacy Services:\n")
        for service, description in SUPPORTED_SERVICES.items():
            print(f"  {service:<18} - {description}")
        print()
        print("Examples:")
        print("  python scripts/privacy_manager.py --grant camera --bundle-id com.app")
        print("  python scripts/privacy_manager.py --revoke location --bundle-id com.app")
        print("  python scripts/privacy_manager.py --grant camera,photos --bundle-id com.app")
        sys.exit(0)

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    manager = PrivacyManager(udid=udid)

    action, raw_services = (
        ("grant", args.grant)
        if args.grant
        else ("revoke", args.revoke) if args.revoke else ("reset", args.reset)
    )
    services = [s.strip() for s in raw_services.split(",") if s.strip()]

    all_success = True
    for service in services:
        success, message = manager.apply_permission(
            action,
            args.bundle_id,
            service,
            scenario=args.scenario,
            step=args.step,
        )

        if success:
            print(f"\u2713 {action.capitalize()} {service}: {message}")
        else:
            print(f"\u2717 Failed to {action} {service}: {message}", file=sys.stderr)
            all_success = False

    if not all_success:
        sys.exit(1)


if __name__ == "__main__":
    main()
