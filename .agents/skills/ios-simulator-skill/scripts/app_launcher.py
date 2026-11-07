#!/usr/bin/env python3
"""
iOS App Launcher - App Lifecycle Control

Launches, terminates, and manages iOS apps in the simulator.
Handles deep links and app switching.

Usage: python scripts/app_launcher.py --launch com.example.app

Launch arguments and environment variables can be passed to the app:
    python scripts/app_launcher.py --launch com.example.app \
        --env DEBUG=1 --args -uiTestingMode 1

--args consumes everything after it (argparse REMAINDER), so it must be the
last flag on the command line. --env is repeatable and each KEY=VALUE pair is
injected into the app process as SIMCTL_CHILD_KEY=VALUE.
"""

import argparse
import contextlib
import os
import subprocess
import sys
import time

from common import build_simctl_command, refuse_without_yes, resolve_udid
from common.env_config import env_float, env_int

RELAUNCH_DELAY_SECONDS = env_float("IOS_SIM_RELAUNCH_DELAY_MS", 1000.0) / 1000.0
APPS_PREVIEW = env_int("IOS_SIM_APPS_PREVIEW", 30)


class AppLauncher:
    """Controls app lifecycle on iOS simulator."""

    def __init__(self, udid: str | None = None):
        """Initialize app launcher."""
        self.udid = udid

    def launch(
        self,
        bundle_id: str,
        wait_for_debugger: bool = False,
        launch_args: list[str] | None = None,
        env_vars: dict[str, str] | None = None,
    ) -> tuple[bool, int | None]:
        """
        Launch an app.

        Args:
            bundle_id: App bundle identifier
            wait_for_debugger: Wait for debugger attachment
            launch_args: Arguments passed to the app as trailing simctl args
            env_vars: Variables injected into the app process as SIMCTL_CHILD_*

        Returns:
            (success, pid) tuple
        """
        cmd = build_simctl_command("launch", self.udid, bundle_id, *(launch_args or []))

        if wait_for_debugger:
            cmd.insert(3, "--wait-for-debugger")  # Insert after "launch" operation

        # Inherit the parent env unless caller supplied app env vars (SIMCTL_CHILD_*).
        run_env = None
        if env_vars:
            run_env = {**os.environ, **{f"SIMCTL_CHILD_{k}": v for k, v in env_vars.items()}}

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True, env=run_env)
            # Parse PID from output if available
            pid = None
            if result.stdout:
                # Output format: "com.example.app: <PID>"
                parts = result.stdout.strip().split(":")
                if len(parts) > 1:
                    with contextlib.suppress(ValueError):
                        pid = int(parts[1].strip())
            return (True, pid)
        except subprocess.CalledProcessError:
            return (False, None)

    def terminate(self, bundle_id: str) -> bool:
        """
        Terminate an app.

        Args:
            bundle_id: App bundle identifier

        Returns:
            Success status
        """
        cmd = build_simctl_command("terminate", self.udid, bundle_id)

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def install(self, app_path: str) -> bool:
        """
        Install an app.

        Args:
            app_path: Path to .app bundle

        Returns:
            Success status
        """
        cmd = build_simctl_command("install", self.udid, app_path)

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def uninstall(self, bundle_id: str) -> bool:
        """
        Uninstall an app.

        Args:
            bundle_id: App bundle identifier

        Returns:
            Success status
        """
        cmd = build_simctl_command("uninstall", self.udid, bundle_id)

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def open_url(self, url: str) -> bool:
        """
        Open URL (for deep linking).

        Args:
            url: URL to open (http://, myapp://, etc.)

        Returns:
            Success status
        """
        cmd = build_simctl_command("openurl", self.udid, url)

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def list_apps(self) -> list[dict[str, str]]:
        """
        List installed apps.

        Returns:
            List of app info dictionaries
        """
        cmd = build_simctl_command("listapps", self.udid)

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)

            # Parse plist output using plutil to convert to JSON
            plist_data = result.stdout

            # Use plutil to convert plist to JSON
            convert_cmd = ["plutil", "-convert", "json", "-o", "-", "-"]
            convert_result = subprocess.run(
                convert_cmd, check=False, input=plist_data, capture_output=True, text=True
            )

            apps = []
            if convert_result.returncode == 0:
                import json

                try:
                    data = json.loads(convert_result.stdout)
                    for bundle_id, app_info in data.items():
                        # Skip system internal apps that are hidden
                        if app_info.get("ApplicationType") == "Hidden":
                            continue

                        apps.append(
                            {
                                "bundle_id": bundle_id,
                                "name": app_info.get(
                                    "CFBundleDisplayName", app_info.get("CFBundleName", bundle_id)
                                ),
                                "path": app_info.get("Path", ""),
                                "version": app_info.get("CFBundleVersion", "Unknown"),
                                "type": app_info.get("ApplicationType", "User"),
                            }
                        )
                except json.JSONDecodeError:
                    pass

            return apps
        except subprocess.CalledProcessError:
            return []

    def get_app_state(self, bundle_id: str) -> str:
        """
        Get app state (running, suspended, etc.).

        Args:
            bundle_id: App bundle identifier

        Returns:
            State string or 'unknown'
        """
        # Check if app is running by trying to get its PID
        cmd = build_simctl_command("spawn", self.udid, "launchctl", "list")

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            if bundle_id in result.stdout:
                return "running"
            return "not running"
        except subprocess.CalledProcessError:
            return "unknown"

    def restart_app(
        self,
        bundle_id: str,
        delay: float = RELAUNCH_DELAY_SECONDS,
        launch_args: list[str] | None = None,
        env_vars: dict[str, str] | None = None,
    ) -> bool:
        """
        Restart an app (terminate then launch).

        Args:
            bundle_id: App bundle identifier
            delay: Delay between terminate and launch
            launch_args: Arguments forwarded to the relaunch
            env_vars: Variables forwarded to the relaunch as SIMCTL_CHILD_*

        Returns:
            Success status
        """
        # Terminate
        self.terminate(bundle_id)
        time.sleep(delay)

        # Launch
        success, _ = self.launch(bundle_id, launch_args=launch_args, env_vars=env_vars)
        return success


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Control iOS app lifecycle")

    # Actions
    parser.add_argument("--launch", help="Launch app by bundle ID")
    parser.add_argument("--terminate", help="Terminate app by bundle ID")
    parser.add_argument("--restart", help="Restart app by bundle ID")
    parser.add_argument("--install", help="Install app from .app path")
    parser.add_argument("--uninstall", help="Uninstall app by bundle ID (needs --yes)")
    parser.add_argument("--open-url", help="Open URL (deep link)")
    parser.add_argument("--list", action="store_true", help="List installed apps")
    parser.add_argument("--state", help="Get app state by bundle ID")

    # Options
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Confirm --uninstall: the app's data on the simulator can't be recovered",
    )
    parser.add_argument(
        "--wait-for-debugger", action="store_true", help="Wait for debugger when launching"
    )
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )
    parser.add_argument(
        "--env",
        action="append",
        metavar="KEY=VALUE",
        help="App environment variable (repeatable); injected as SIMCTL_CHILD_KEY",
    )
    # REMAINDER must be the last flag on the command line.
    parser.add_argument(
        "--args",
        nargs=argparse.REMAINDER,
        help="Launch arguments for the app (everything after this flag)",
    )

    args = parser.parse_args()

    # Parse --env KEY=VALUE pairs, failing fast on malformed input.
    env_vars: dict[str, str] = {}
    for pair in args.env or []:
        key, separator, value = pair.partition("=")
        if not separator or not key:
            print(f"Error: invalid --env '{pair}', expected KEY=VALUE", file=sys.stderr)
            sys.exit(1)
        env_vars[key] = value
    launch_args = args.args or None

    # Resolve UDID with auto-detection
    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)

    launcher = AppLauncher(udid=udid)

    # Execute requested action
    if args.launch:
        success, pid = launcher.launch(
            args.launch,
            args.wait_for_debugger,
            launch_args=launch_args,
            env_vars=env_vars or None,
        )
        if success:
            if pid:
                print(f"Launched {args.launch} (PID: {pid})")
            else:
                print(f"Launched {args.launch}")
        else:
            print(f"Failed to launch {args.launch}")
            sys.exit(1)

    elif args.terminate:
        if launcher.terminate(args.terminate):
            print(f"Terminated {args.terminate}")
        else:
            print(f"Failed to terminate {args.terminate}")
            sys.exit(1)

    elif args.restart:
        if launcher.restart_app(args.restart, launch_args=launch_args, env_vars=env_vars or None):
            print(f"Restarted {args.restart}")
        else:
            print(f"Failed to restart {args.restart}")
            sys.exit(1)

    elif args.install:
        if launcher.install(args.install):
            print(f"Installed {args.install}")
        else:
            print(f"Failed to install {args.install}")
            sys.exit(1)

    elif args.uninstall:
        if not args.yes:
            print(
                refuse_without_yes(f"uninstall {args.uninstall} and delete its data"),
                file=sys.stderr,
            )
            sys.exit(1)
        if launcher.uninstall(args.uninstall):
            print(f"Uninstalled {args.uninstall}")
        else:
            print(f"Failed to uninstall {args.uninstall}")
            sys.exit(1)

    elif args.open_url:
        if launcher.open_url(args.open_url):
            print(f"Opened URL: {args.open_url}")
        else:
            print(f"Failed to open URL: {args.open_url}")
            sys.exit(1)

    elif args.list:
        apps = launcher.list_apps()
        if apps:
            print(f"Installed apps ({len(apps)}):")
            for app in apps[:APPS_PREVIEW]:
                print(f"  {app['bundle_id']}: {app['name']} (v{app['version']})")
            if len(apps) > APPS_PREVIEW:
                print(f"  ... and {len(apps) - APPS_PREVIEW} more")
        else:
            print("No apps found or failed to list")

    elif args.state:
        state = launcher.get_app_state(args.state)
        print(f"{args.state}: {state}")

    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
