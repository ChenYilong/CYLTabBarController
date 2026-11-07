#!/usr/bin/env python3
"""
iOS Keyboard Controller - Text Entry and Hardware Buttons

Handles keyboard input, special keys, and hardware button simulation.
Token-efficient text entry and navigation control.

Usage Examples:
    # Type text into focused field
    python scripts/keyboard.py --type "hello@example.com"

    # Press return key to submit
    python scripts/keyboard.py --key return

    # Press delete 3 times
    python scripts/keyboard.py --key delete --count 3

    # Press a sequence of keys (special key names or single letters)
    python scripts/keyboard.py --key-sequence h,i,return

    # Key chords: hold modifiers (--shift --control --option --command)
    python scripts/keyboard.py --key a --command
    python scripts/keyboard.py --key z --command --shift

    # Select all and delete the focused field's text
    python scripts/keyboard.py --clear

    # Hardware buttons
    python scripts/keyboard.py --button home
    python scripts/keyboard.py --button lock

    # Type character by character (for fields that react per keystroke)
    python scripts/keyboard.py --type "slow typing" --slow

Output Format:
    Typed: "hello@example.com"
    Pressed return
    Pressed command+shift+z
    Pressed home button

Special Keys (USB HID usage codes, as idb expects):
- return/enter 40, escape 41, delete/backspace 42, tab 43, space 44
- right 79, left 80, down 81, up 82
- single letters a-z map to 4-29

Hardware Buttons (idb `ui button` names):
- home, lock/power, side, siri, apple-pay
- volume-up, volume-down (need idb 1.6.3+)

Technical Details:
- `idb ui text` types strings into the focused element (ASCII only)
- `idb ui key <code>` presses one key; `--shift/--control/--option/--command` hold
  modifiers (Cmd+A for --clear). Modifier flags need idb 1.7+ except --command.
- `idb ui key-sequence <codes...>` presses keys in order
- `idb ui button <NAME>` presses a hardware button
"""

import argparse
import sys
import time

from common import build_idb_command, resolve_udid, run_idb, with_idb_upgrade_hint

SLOW_TYPING_DELAY_SECONDS = 0.1
REPEAT_KEY_DELAY_SECONDS = 0.1
FALLBACK_DELETE_COUNT = 50

HID_KEY_A = 4
HID_KEY_DELETE = 42

SPECIAL_KEYS: dict[str, int] = {
    "return": 40,
    "enter": 40,
    "escape": 41,
    "delete": HID_KEY_DELETE,
    "backspace": HID_KEY_DELETE,
    "tab": 43,
    "space": 44,
    "right": 79,
    "left": 80,
    "down": 81,
    "up": 82,
}

# Script-facing name -> idb HIDButtonType name.
HARDWARE_BUTTONS: dict[str, str] = {
    "home": "HOME",
    "lock": "LOCK",
    "power": "LOCK",
    "side": "SIDE_BUTTON",
    "siri": "SIRI",
    "apple-pay": "APPLE_PAY",
    "volume-up": "VOLUME_UP",
    "volume-down": "VOLUME_DOWN",
}

BUTTONS_NEEDING_NEWER_IDB = {"volume-up", "volume-down"}

# Modifier name -> `idb ui key` flag, in the order flags are passed.
MODIFIER_FLAGS: dict[str, str] = {
    "shift": "--shift",
    "control": "--control",
    "option": "--option",
    "command": "--command",
}

# Modifier flags other than --command are missing from idb < 1.7 (argparse rejects them).
MODIFIERS_NEEDING_NEWER_IDB = {"shift", "control", "option"}


def resolve_key_code(key: str) -> int | None:
    """
    Map a key name, single letter, or numeric HID code to a HID usage code.

    Digits are raw HID codes, not the digit keys: "1" is code 1, not the "1" key.

    Example:
        resolve_key_code("return")  # 40
        resolve_key_code("h")       # 11
        resolve_key_code("42")      # 42
        resolve_key_code("nope")    # None
    """
    name = key.strip().lower()
    if name in SPECIAL_KEYS:
        return SPECIAL_KEYS[name]
    if len(name) == 1 and "a" <= name <= "z":
        return HID_KEY_A + ord(name) - ord("a")
    if name.isdigit():
        return int(name)
    return None


class KeyboardController:
    """Controls keyboard and hardware buttons on iOS simulator."""

    def __init__(self, udid: str | None = None):
        """Initialize keyboard controller."""
        self.udid = udid
        self.last_error = ""

    # === PUBLIC API ===

    def type_text(self, text: str, delay_seconds: float = 0.0) -> bool:
        """
        Type text into the focused element.

        Args:
            text: Text to type
            delay_seconds: Pause between characters; 0 types the whole string at once

        Returns:
            Success status
        """
        if delay_seconds <= 0:
            return self._run("ui text", text)
        for char in text:
            if not self._run("ui text", char):
                return False
            time.sleep(delay_seconds)
        return True

    def press_key(self, key: str, count: int = 1, modifiers: tuple[str, ...] = ()) -> bool:
        """
        Press a key `count` times.

        Args:
            key: Key name (return, delete...), single letter, or HID code
            count: Number of presses
            modifiers: Modifiers to hold: shift, control, option, command (e.g. Cmd+A)

        Returns:
            Success status
        """
        key_code = resolve_key_code(key)
        if key_code is None:
            self.last_error = (
                f"Unknown key '{key}' (use a name like return/delete, a letter, or a HID code)"
            )
            return False

        unknown_modifiers = [name for name in modifiers if name not in MODIFIER_FLAGS]
        if unknown_modifiers:
            self.last_error = (
                f"Unknown modifier '{unknown_modifiers[0]}' "
                f"(choose from: {', '.join(MODIFIER_FLAGS)})"
            )
            return False

        modifier_flags = [flag for name, flag in MODIFIER_FLAGS.items() if name in modifiers]
        for press_number in range(count):
            if not self._run("ui key", key_code, *modifier_flags):
                if MODIFIERS_NEEDING_NEWER_IDB.intersection(modifiers):
                    self.last_error = with_idb_upgrade_hint(self.last_error)
                return False
            if press_number < count - 1:
                time.sleep(REPEAT_KEY_DELAY_SECONDS)
        return True

    def press_key_sequence(self, keys: list[str]) -> bool:
        """Press keys in order (names, letters or HID codes)."""
        key_codes = []
        for key in keys:
            key_code = resolve_key_code(key)
            if key_code is None:
                self.last_error = f"Unknown key '{key}' in sequence"
                return False
            key_codes.append(key_code)
        return self._run("ui key-sequence", *key_codes)

    def press_hardware_button(self, button: str) -> bool:
        """Press a hardware button by script-facing name (home, lock, side...)."""
        idb_button = HARDWARE_BUTTONS.get(button.lower())
        if not idb_button:
            self.last_error = (
                f"Unknown button '{button}' (choose from: {', '.join(HARDWARE_BUTTONS)})"
            )
            return False
        ok = self._run("ui button", idb_button)
        if not ok and button.lower() in BUTTONS_NEEDING_NEWER_IDB:
            self.last_error = with_idb_upgrade_hint(self.last_error, requirement="idb 1.6.3+")
        return ok

    def clear_text(self, select_all: bool = True) -> bool:
        """
        Clear the focused text field.

        Args:
            select_all: Cmd+A then delete (fast). False presses delete
                FALLBACK_DELETE_COUNT times, for fields that ignore Cmd+A.

        Returns:
            Success status
        """
        if not select_all:
            return self.press_key("delete", count=FALLBACK_DELETE_COUNT)
        if not self.press_key("a", modifiers=("command",)):
            return False
        return self.press_key("delete")

    def dismiss_keyboard(self) -> bool:
        """Dismiss the keyboard by pressing Return (adds a newline in multi-line fields)."""
        return self.press_key("return")

    # === HELPERS ===

    def _run(self, operation: str, *args: object) -> bool:
        """Run an idb operation, keeping the failure reason in last_error."""
        ok, self.last_error = run_idb(build_idb_command(operation, self.udid, *args))
        return ok


def report(
    ok: bool, success_message: str, failure_message: str, controller: KeyboardController
) -> None:
    """Print the outcome, exiting non-zero with idb's reason on failure."""
    if ok:
        print(success_message)
        return
    reason = f": {controller.last_error}" if controller.last_error else ""
    print(f"{failure_message}{reason}", file=sys.stderr)
    sys.exit(1)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Control keyboard and hardware buttons")

    # Text input
    parser.add_argument("--type", help="Type text into current focus (ASCII only)")
    parser.add_argument("--slow", action="store_true", help="Type slowly (character by character)")

    # Special keys
    parser.add_argument(
        "--key",
        help="Press a key: return, delete, tab, space, arrows, a letter, or a numeric HID "
        "usage code (digits are codes, not characters: 40 = return)",
    )
    parser.add_argument(
        "--key-sequence", help="Press keys in order (comma-separated, e.g. h,i,return)"
    )
    parser.add_argument("--count", type=int, default=1, help="Number of times to press --key")
    for modifier, flag in MODIFIER_FLAGS.items():
        parser.add_argument(
            flag, action="store_true", help=f"Hold {modifier} while pressing --key (e.g. --key a)"
        )

    # Hardware buttons
    parser.add_argument(
        "--button",
        choices=list(HARDWARE_BUTTONS),
        help="Press hardware button (volume-up/down need idb 1.6.3+)",
    )

    # Other operations
    parser.add_argument(
        "--clear", action="store_true", help="Clear focused text field (Cmd+A, delete)"
    )
    parser.add_argument(
        "--dismiss",
        action="store_true",
        help="Dismiss keyboard by pressing Return (adds a newline in multi-line fields)",
    )

    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )

    args = parser.parse_args()

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    controller = KeyboardController(udid=udid)
    modifiers = tuple(name for name in MODIFIER_FLAGS if getattr(args, name))
    if modifiers and not args.key:
        print(
            f"Error: {' '.join(MODIFIER_FLAGS[n] for n in modifiers)} requires --key",
            file=sys.stderr,
        )
        sys.exit(1)

    if args.type:
        delay = SLOW_TYPING_DELAY_SECONDS if args.slow else 0.0
        suffix = " (slowly)" if args.slow else ""
        ok = controller.type_text(args.type, delay)
        report(ok, f'Typed: "{args.type}"{suffix}', "Failed to type text", controller)

    elif args.key:
        ok = controller.press_key(args.key, args.count, modifiers)
        times = f" ({args.count}x)" if args.count > 1 else ""
        chord = "+".join([*modifiers, args.key])
        report(ok, f"Pressed {chord}{times}", f"Failed to press {chord}", controller)

    elif args.key_sequence:
        keys = args.key_sequence.split(",")
        ok = controller.press_key_sequence(keys)
        report(
            ok, f"Pressed sequence: {' -> '.join(keys)}", "Failed to press key sequence", controller
        )

    elif args.button:
        ok = controller.press_hardware_button(args.button)
        report(ok, f"Pressed {args.button} button", f"Failed to press {args.button}", controller)

    elif args.clear:
        ok = controller.clear_text()
        report(ok, "Cleared text field", "Failed to clear text", controller)

    elif args.dismiss:
        ok = controller.dismiss_keyboard()
        report(ok, "Dismissed keyboard", "Failed to dismiss keyboard", controller)

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
