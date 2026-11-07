#!/usr/bin/env python3
"""
iOS Simulator Clipboard Manager

Copy text to simulator clipboard for testing paste flows.
Optimized for minimal token output.

Usage: python scripts/clipboard.py --copy "text to copy"
"""

import argparse
import subprocess
import sys

from common import resolve_udid


class ClipboardManager:
    """Manages clipboard operations on iOS simulator."""

    def __init__(self, udid: str | None = None):
        """Initialize clipboard manager.

        Args:
            udid: Optional device UDID (auto-detects booted simulator if None)
        """
        self.udid = udid

    def copy(self, text: str) -> bool:
        """
        Copy text to simulator clipboard.

        Args:
            text: Text to copy to clipboard

        Returns:
            Success status
        """
        cmd = ["xcrun", "simctl", "pbcopy"]

        if self.udid:
            cmd.append(self.udid)
        else:
            cmd.append("booted")

        cmd.append(text)

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Copy text to iOS simulator clipboard")
    parser.add_argument("--copy", required=True, help="Text to copy to clipboard")
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )
    parser.add_argument("--test-name", help="Test scenario name for tracking")
    parser.add_argument("--expected", help="Expected behavior after paste")

    args = parser.parse_args()

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)

    # Create manager and copy text
    manager = ClipboardManager(udid=udid)

    if manager.copy(args.copy):
        # Token-efficient output
        output = f'Copied: "{args.copy}"'

        if args.test_name:
            output += f" (test: {args.test_name})"

        print(output)

        # Provide usage guidance
        if args.expected:
            print(f"Expected: {args.expected}")

        print()
        print("Next steps:")
        print("1. Tap text field with: python scripts/navigator.py --find-type TextField --tap")
        print("2. Paste with: python scripts/keyboard.py --key return")
        print("   Or use Cmd+V gesture with: python scripts/keyboard.py --key cmd+v")

    else:
        print("Failed to copy text to clipboard")
        sys.exit(1)


if __name__ == "__main__":
    main()
