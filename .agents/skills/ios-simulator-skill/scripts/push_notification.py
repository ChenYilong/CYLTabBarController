#!/usr/bin/env python3
"""
iOS Push Notification Simulator

Send simulated push notifications to test notification handling.
Supports custom payloads and test tracking. Sending uses simctl push; --list and
--clear use idb (1.7+), since simctl cannot inspect or withdraw delivered notifications.

Usage:
  python scripts/push_notification.py --bundle-id com.app --title "Alert" --body "Message"
  python scripts/push_notification.py --bundle-id com.app --list
  python scripts/push_notification.py --bundle-id com.app --clear
"""

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from common import build_idb_command, resolve_udid, run_idb, with_idb_upgrade_hint
from common.env_config import env_int

MAX_NOTIFICATIONS_LISTED = env_int("IOS_SIM_MAX_ELEMENTS", 25)


class PushNotificationSender:
    """Sends simulated push notifications to iOS simulator."""

    def __init__(self, udid: str | None = None):
        """Initialize push notification sender.

        Args:
            udid: Optional device UDID (auto-detects booted simulator if None)
        """
        self.udid = udid

    def send(
        self,
        bundle_id: str,
        payload: dict | str,
        _test_name: str | None = None,
        _expected_behavior: str | None = None,
    ) -> bool:
        """
        Send push notification to app.

        Args:
            bundle_id: Target app bundle ID
            payload: Push payload (dict or JSON string) or path to JSON file
            test_name: Test scenario name for tracking
            expected_behavior: Expected behavior after notification arrives

        Returns:
            Success status
        """
        # Handle different payload formats
        if isinstance(payload, str):
            # Check if it's a file path
            payload_path = Path(payload)
            if payload_path.exists():
                with open(payload_path) as f:
                    payload_data = json.load(f)
            else:
                # Try to parse as JSON string
                try:
                    payload_data = json.loads(payload)
                except json.JSONDecodeError:
                    print(f"Error: Invalid JSON payload: {payload}")
                    return False
        else:
            payload_data = payload

        # Ensure payload has aps dictionary
        if "aps" not in payload_data:
            payload_data = {"aps": payload_data}

        # Create temp file with payload
        try:
            with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
                json.dump(payload_data, f)
                temp_payload_path = f.name

            # Build simctl command
            cmd = ["xcrun", "simctl", "push"]

            if self.udid:
                cmd.append(self.udid)
            else:
                cmd.append("booted")

            cmd.extend([bundle_id, temp_payload_path])

            # Send notification
            subprocess.run(cmd, capture_output=True, text=True, check=True)

            # Clean up temp file
            Path(temp_payload_path).unlink()

            return True

        except subprocess.CalledProcessError as e:
            print(f"Error sending push notification: {e.stderr}")
            return False
        except Exception as e:
            print(f"Error: {e}")
            return False

    def send_simple(
        self,
        bundle_id: str,
        title: str | None = None,
        body: str | None = None,
        badge: int | None = None,
        sound: bool = True,
    ) -> bool:
        """
        Send simple push notification with common parameters.

        Args:
            bundle_id: Target app bundle ID
            title: Alert title
            body: Alert body
            badge: Badge number
            sound: Whether to play sound

        Returns:
            Success status
        """
        payload = {}

        if title or body:
            alert = {}
            if title:
                alert["title"] = title
            if body:
                alert["body"] = body
            payload["alert"] = alert

        if badge is not None:
            payload["badge"] = badge

        if sound:
            payload["sound"] = "default"

        # Wrap in aps
        full_payload = {"aps": payload}

        return self.send(bundle_id, full_payload)

    def list_delivered(self, bundle_id: str) -> tuple[bool, list[dict] | str]:
        """
        List notifications delivered to an app (idb 1.7+).

        Args:
            bundle_id: Target app bundle ID

        Returns:
            (True, notifications) where each has title/subtitle/body/identifier/date,
            or (False, error message)
        """
        cmd = build_idb_command("notification list", self.udid, bundle_id, "--json")
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        except subprocess.CalledProcessError as e:
            return False, with_idb_upgrade_hint(
                (e.stderr or "").strip() or f"idb exited with status {e.returncode}"
            )
        except FileNotFoundError:
            return False, "idb not found on PATH - run scripts/sim_health_check.sh"

        # idb prints one JSON object per notification, one per line
        try:
            notifications = [json.loads(line) for line in result.stdout.splitlines() if line]
        except json.JSONDecodeError:
            return False, f"Unparseable idb output: {result.stdout[:200]}"
        return True, notifications

    def clear_delivered(self, bundle_id: str) -> tuple[bool, str]:
        """
        Withdraw every notification delivered to an app (idb 1.7+).

        Args:
            bundle_id: Target app bundle ID

        Returns:
            (success, error message - "" on success)
        """
        ok, error = run_idb(build_idb_command("notification clear", self.udid, bundle_id))
        return ok, with_idb_upgrade_hint(error)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Send simulated push notification to iOS app")

    # Required
    parser.add_argument(
        "--bundle-id", required=True, help="Target app bundle ID (e.g., com.example.app)"
    )

    # Simple payload options
    parser.add_argument("--title", help="Alert title (for simple notifications)")
    parser.add_argument("--body", help="Alert body message")
    parser.add_argument("--badge", type=int, help="Badge number")
    parser.add_argument("--no-sound", action="store_true", help="Don't play notification sound")

    # Custom payload
    parser.add_argument(
        "--payload",
        help="Custom JSON payload file or inline JSON string",
    )

    # Inspect / withdraw delivered notifications (idb 1.7+)
    parser.add_argument(
        "--list", action="store_true", help="List notifications delivered to the app"
    )
    parser.add_argument(
        "--clear", action="store_true", help="Withdraw all notifications delivered to the app"
    )
    parser.add_argument("--json", action="store_true", help="Output --list/--clear as JSON")

    # Test tracking
    parser.add_argument("--test-name", help="Test scenario name for tracking")
    parser.add_argument(
        "--expected",
        help="Expected behavior after notification",
    )

    # Device
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )

    args = parser.parse_args()

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)

    sender = PushNotificationSender(udid=udid)

    if args.list or args.clear:
        if args.list and args.clear:
            print("Error: --list and --clear are mutually exclusive")
            sys.exit(1)
        sys.exit(_run_inspection(sender, args))

    # Send notification
    if args.payload:
        # Custom payload mode
        success = sender.send(args.bundle_id, args.payload)
    else:
        # Simple notification mode
        success = sender.send_simple(
            args.bundle_id,
            title=args.title,
            body=args.body,
            badge=args.badge,
            sound=not args.no_sound,
        )

    if success:
        # Token-efficient output
        output = "Push notification sent"

        if args.test_name:
            output += f" (test: {args.test_name})"

        print(output)

        if args.expected:
            print(f"Expected: {args.expected}")

        print()
        print("Notification details:")
        if args.title:
            print(f"  Title: {args.title}")
        if args.body:
            print(f"  Body: {args.body}")
        if args.badge:
            print(f"  Badge: {args.badge}")

        print()
        print("Verify notification handling:")
        print("1. Check app log output: python scripts/log_monitor.py --app " + args.bundle_id)
        print(
            "2. Capture state: python scripts/app_state_capture.py --app-bundle-id "
            + args.bundle_id
        )

    else:
        print("Failed to send push notification")
        sys.exit(1)


def _run_inspection(sender: PushNotificationSender, args: argparse.Namespace) -> int:
    """Handle --list / --clear, print the result, and return the exit code."""
    if args.list:
        ok, result = sender.list_delivered(args.bundle_id)
        if not ok:
            print(f"Error: {result}")
            return 1
        if args.json:
            print(json.dumps({"bundle_id": args.bundle_id, "notifications": result}))
        else:
            print(f"{len(result)} notification(s) delivered to {args.bundle_id}")
            for item in result[:MAX_NOTIFICATIONS_LISTED]:
                print(f"  {item.get('title', '')} | {item.get('body', '')}")
            if len(result) > MAX_NOTIFICATIONS_LISTED:
                print(f"  ... and {len(result) - MAX_NOTIFICATIONS_LISTED} more")
        return 0

    ok, error = sender.clear_delivered(args.bundle_id)
    if not ok:
        print(f"Error: {error}")
        return 1
    if args.json:
        print(json.dumps({"bundle_id": args.bundle_id, "cleared": True}))
    else:
        print(f"Cleared notifications for {args.bundle_id}")
    return 0


if __name__ == "__main__":
    main()
