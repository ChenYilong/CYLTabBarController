"""
Xcode build execution.

Handles xcodebuild command construction and execution with xcresult generation.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

from common.env_config import env_int

from .cache import XCResultCache
from .config import Config

BUILD_TIMEOUT = env_int("IOS_SIM_BUILD_TIMEOUT", 1800)
TEST_TIMEOUT = env_int("IOS_SIM_TEST_TIMEOUT", 2700)
INTROSPECT_TIMEOUT = env_int("IOS_SIM_INTROSPECT_TIMEOUT", 60)


class BuildRunner:
    """
    Execute xcodebuild commands with xcresult bundle generation.

    Handles scheme auto-detection, command construction, and build/test execution.
    """

    def __init__(
        self,
        project_path: str | None = None,
        workspace_path: str | None = None,
        scheme: str | None = None,
        configuration: str = "Debug",
        simulator: str | None = None,
        os_version: str | None = None,
        cache: XCResultCache | None = None,
    ):
        """
        Initialize build runner.

        Args:
            project_path: Path to .xcodeproj
            workspace_path: Path to .xcworkspace
            scheme: Build scheme (auto-detected if not provided)
            configuration: Build configuration (Debug/Release)
            simulator: Simulator name
            os_version: iOS version to pin the simulator to (e.g. "26.5")
            cache: XCResult cache (creates default if not provided)
        """
        self.project_path = project_path
        self.workspace_path = workspace_path
        self.scheme = scheme
        self.configuration = configuration
        self.simulator = simulator
        self.os_version = os_version
        self._destination: str | None = None
        self.cache = cache or XCResultCache()

    def auto_detect_scheme(self) -> str | None:
        """
        Auto-detect build scheme from project/workspace.

        Returns:
            Detected scheme name or None
        """
        cmd = ["xcodebuild", "-list"]

        if self.workspace_path:
            cmd.extend(["-workspace", self.workspace_path])
        elif self.project_path:
            cmd.extend(["-project", self.project_path])
        else:
            return None

        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, check=True, timeout=INTROSPECT_TIMEOUT
            )

            # Parse schemes from output
            in_schemes_section = False
            for line in result.stdout.split("\n"):
                line = line.strip()

                if "Schemes:" in line:
                    in_schemes_section = True
                    continue

                if in_schemes_section and line and not line.startswith("Build"):
                    # First scheme in list
                    return line

        except subprocess.CalledProcessError as e:
            print(f"Error auto-detecting scheme: {e}", file=sys.stderr)

        return None

    def get_simulator_destination(self) -> str:
        """
        Get xcodebuild destination string.

        Uses config preferences with fallback to auto-detection.

        Priority:
            1. --simulator CLI flag (self.simulator)
            2. Config preferred_simulator
            3. Config last_used_simulator
            4. Auto-detect first iPhone
            5. Generic iOS Simulator

        Returns:
            Destination string for -destination flag (resolved once, then cached)
        """
        if self._destination is None:
            self._destination = self._resolve_destination()
        return self._destination

    def _resolve_destination(self) -> str:
        # Priority 1: CLI flag
        if self.simulator:
            return self._named_destination(self.simulator, self.os_version)

        # Priority 2-3: Config preferences
        try:
            # Determine project directory from project/workspace path
            project_dir = None
            if self.project_path:
                project_dir = Path(self.project_path).parent
            elif self.workspace_path:
                project_dir = Path(self.workspace_path).parent

            config = Config.load(project_dir=project_dir)
            preferred = config.get_preferred_simulator()

            if preferred:
                resolved_os = self._find_simulator_os(preferred, config.get_preferred_os_version())
                if resolved_os:
                    return f"platform=iOS Simulator,name={preferred},OS={resolved_os}"
                print(f"Warning: Preferred simulator '{preferred}' not available", file=sys.stderr)
                if config.should_fallback_to_any_iphone():
                    print("Falling back to auto-detection...", file=sys.stderr)
                else:
                    # Strict mode: don't fallback
                    return f"platform=iOS Simulator,name={preferred}"

        except Exception as e:
            print(f"Warning: Could not load config: {e}", file=sys.stderr)

        # Priority 4-5: Auto-detect
        return self._auto_detect_simulator()

    def _named_destination(self, name: str, os_version: str | None = None) -> str:
        """Build a destination for a named simulator, pinned to the OS it runs.

        A bare name= makes xcodebuild assume OS:latest, so a device on an older
        runtime (e.g. 26.5 once 27.0 is installed) never matches.
        """
        resolved_os = self._find_simulator_os(name, os_version)
        if resolved_os:
            return f"platform=iOS Simulator,name={name},OS={resolved_os}"
        return f"platform=iOS Simulator,name={name}"

    def _find_simulator_os(self, name: str, os_version: str | None = None) -> str | None:
        """Return the newest iOS version with an available device named exactly `name`.

        With os_version, only that runtime counts. None when no device matches.
        """
        device = self._find_simulator(name, os_version)
        return device[0] if device else None

    def _find_simulator(self, name: str, os_version: str | None = None) -> tuple[str, str] | None:
        """Return (iOS version, udid) of the newest available device named exactly `name`."""
        matches = [
            (version, device.get("udid", ""))
            for version, device in _available_ios_devices()
            if device.get("name") == name and (not os_version or version == os_version)
        ]
        if not matches:
            return None
        return max(matches, key=lambda match: _version_key(match[0]))

    def get_destination_udid(self) -> str | None:
        """Return the UDID of the simulator the destination names, or None if generic/unknown."""
        destination = self.get_simulator_destination()
        name = self._extract_simulator_name_from_destination(destination)
        if not name:
            return None
        os_match = re.search(r"OS=([^,]+)", destination)
        device = self._find_simulator(name, os_match.group(1).strip() if os_match else None)
        return device[1] if device and device[1] else None

    def get_built_app(self) -> tuple[str, str] | None:
        """Return (app path, bundle ID) of the scheme's .app product, or None if there isn't one."""
        cmd = ["xcodebuild", "-showBuildSettings", "-json", *self._project_args()]
        cmd.extend(
            [
                "-scheme",
                self.scheme or "",
                "-configuration",
                self.configuration,
                "-destination",
                self.get_simulator_destination(),
            ]
        )
        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, check=True, timeout=INTROSPECT_TIMEOUT
            )
            targets = json.loads(result.stdout)
        except (subprocess.SubprocessError, OSError, json.JSONDecodeError):
            return None

        for target in targets:
            settings = target.get("buildSettings", {})
            if settings.get("WRAPPER_EXTENSION") != "app":
                continue
            build_dir = settings.get("TARGET_BUILD_DIR")
            product = settings.get("FULL_PRODUCT_NAME")
            bundle_id = settings.get("PRODUCT_BUNDLE_IDENTIFIER")
            if build_dir and product and bundle_id:
                return (str(Path(build_dir) / product), bundle_id)
        return None

    def _project_args(self) -> list[str]:
        if self.workspace_path:
            return ["-workspace", self.workspace_path]
        if self.project_path:
            return ["-project", self.project_path]
        return []

    def _extract_simulator_name_from_destination(self, destination: str) -> str | None:
        """
        Extract simulator name from destination string.

        Args:
            destination: Destination string (e.g., "platform=iOS Simulator,name=iPhone 16 Pro")

        Returns:
            Simulator name or None
        """
        # Pattern: name=<simulator name>
        match = re.search(r"name=([^,]+)", destination)
        if match:
            return match.group(1).strip()
        return None

    def _auto_detect_simulator(self) -> str:
        """
        Auto-detect best available iOS simulator.

        Returns:
            Destination string for -destination flag
        """
        try:
            result = subprocess.run(
                ["xcrun", "simctl", "list", "devices", "available", "iOS"],
                capture_output=True,
                text=True,
                check=True,
                timeout=INTROSPECT_TIMEOUT,
            )

            # simctl lists runtimes oldest-first, so the last "-- iOS x --" section
            # holds the newest runtime. Take the first iPhone in that section, and
            # pin OS= too: the same device name usually exists on several runtimes.
            # Device lines look like: "iPhone 17 Pro (1234ABCD-...) (Shutdown)"
            newest_destination = None
            section_version = None
            first_in_section = True
            for line in result.stdout.split("\n"):
                if line.startswith("--"):
                    version_match = re.search(r"iOS ([\d.]+)", line)
                    section_version = version_match.group(1) if version_match else None
                    first_in_section = True
                    continue
                if first_in_section and section_version and "iPhone" in line and "(" in line:
                    name = line.split("(")[0].strip()
                    if name:
                        newest_destination = (
                            f"platform=iOS Simulator,name={name},OS={section_version}"
                        )
                        first_in_section = False
            if newest_destination:
                return newest_destination

            # Fallback to generic iOS Simulator if no iPhone found
            return "generic/platform=iOS Simulator"

        except (subprocess.SubprocessError, OSError) as e:
            print(f"Warning: Could not auto-detect simulator: {e}", file=sys.stderr)
            return "generic/platform=iOS Simulator"

    def build(self, clean: bool = False) -> tuple[bool, str, str]:
        """
        Build the project.

        Args:
            clean: Perform clean build

        Returns:
            Tuple of (success: bool, xcresult_id: str, stderr: str)
        """
        # Auto-detect scheme if needed
        if not self.scheme:
            self.scheme = self.auto_detect_scheme()
            if not self.scheme:
                print("Error: Could not auto-detect scheme. Use --scheme", file=sys.stderr)
                return (False, "", "")

        # Generate xcresult ID and path
        xcresult_id = self.cache.generate_id()
        xcresult_path = self.cache.get_path(xcresult_id)

        # Build command
        cmd = ["xcodebuild", "-quiet"]  # Suppress verbose output

        if clean:
            cmd.append("clean")

        cmd.append("build")

        if self.workspace_path:
            cmd.extend(["-workspace", self.workspace_path])
        elif self.project_path:
            cmd.extend(["-project", self.project_path])
        else:
            print("Error: No project or workspace specified", file=sys.stderr)
            return (False, "", "")

        cmd.extend(
            [
                "-scheme",
                self.scheme,
                "-configuration",
                self.configuration,
                "-destination",
                self.get_simulator_destination(),
                "-resultBundlePath",
                str(xcresult_path),
            ]
        )

        # Execute build
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=False,  # Don't raise on non-zero exit
                timeout=BUILD_TIMEOUT,
            )

            success = result.returncode == 0

            # xcresult bundle should be created even on failure
            if not xcresult_path.exists():
                print("Warning: xcresult bundle was not created", file=sys.stderr)
                return (success, "", result.stderr)

            # Auto-update config with last used simulator (on success only)
            if success:
                try:
                    # Determine project directory from project/workspace path
                    project_dir = None
                    if self.project_path:
                        project_dir = Path(self.project_path).parent
                    elif self.workspace_path:
                        project_dir = Path(self.workspace_path).parent

                    config = Config.load(project_dir=project_dir)
                    destination = self.get_simulator_destination()
                    simulator_name = self._extract_simulator_name_from_destination(destination)

                    if simulator_name:
                        config.update_last_used_simulator(simulator_name)
                        config.save()

                except Exception as e:
                    # Don't fail build if config update fails
                    print(f"Warning: Could not update config: {e}", file=sys.stderr)

            return (success, xcresult_id, result.stderr)

        except Exception as e:
            print(f"Error executing build: {e}", file=sys.stderr)
            return (False, "", str(e))

    def test(self, test_suite: str | None = None, parallel: bool = True) -> tuple[bool, str, str]:
        """
        Run tests.

        Args:
            test_suite: Specific test suite to run
            parallel: False runs tests on one simulator (-parallel-testing-enabled NO)

        Returns:
            Tuple of (success: bool, xcresult_id: str, stderr: str)
        """
        # Auto-detect scheme if needed
        if not self.scheme:
            self.scheme = self.auto_detect_scheme()
            if not self.scheme:
                print("Error: Could not auto-detect scheme. Use --scheme", file=sys.stderr)
                return (False, "", "")

        # Generate xcresult ID and path
        xcresult_id = self.cache.generate_id()
        xcresult_path = self.cache.get_path(xcresult_id)

        # Build command
        cmd = ["xcodebuild", "-quiet", "test"]

        if self.workspace_path:
            cmd.extend(["-workspace", self.workspace_path])
        elif self.project_path:
            cmd.extend(["-project", self.project_path])
        else:
            print("Error: No project or workspace specified", file=sys.stderr)
            return (False, "", "")

        cmd.extend(
            [
                "-scheme",
                self.scheme,
                "-destination",
                self.get_simulator_destination(),
                "-resultBundlePath",
                str(xcresult_path),
            ]
        )

        if test_suite:
            cmd.extend(["-only-testing", test_suite])
        if not parallel:
            cmd.extend(["-parallel-testing-enabled", "NO"])

        # Execute tests
        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, check=False, timeout=TEST_TIMEOUT
            )

            success = result.returncode == 0

            # xcresult bundle should be created even on failure
            if not xcresult_path.exists():
                print("Warning: xcresult bundle was not created", file=sys.stderr)
                return (success, "", result.stderr)

            # Auto-update config with last used simulator (on success only)
            if success:
                try:
                    # Determine project directory from project/workspace path
                    project_dir = None
                    if self.project_path:
                        project_dir = Path(self.project_path).parent
                    elif self.workspace_path:
                        project_dir = Path(self.workspace_path).parent

                    config = Config.load(project_dir=project_dir)
                    destination = self.get_simulator_destination()
                    simulator_name = self._extract_simulator_name_from_destination(destination)

                    if simulator_name:
                        config.update_last_used_simulator(simulator_name)
                        config.save()

                except Exception as e:
                    # Don't fail test if config update fails
                    print(f"Warning: Could not update config: {e}", file=sys.stderr)

            return (success, xcresult_id, result.stderr)

        except Exception as e:
            print(f"Error executing tests: {e}", file=sys.stderr)
            return (False, "", str(e))


# === HELPERS ===


def _available_ios_devices() -> list[tuple[str, dict]]:
    """Return (iOS version, device) for every available simulator; empty if simctl fails."""
    try:
        result = subprocess.run(
            ["xcrun", "simctl", "list", "devices", "available", "-j"],
            capture_output=True,
            text=True,
            check=True,
            timeout=INTROSPECT_TIMEOUT,
        )
        runtimes = json.loads(result.stdout).get("devices", {})
    except (subprocess.SubprocessError, OSError, json.JSONDecodeError):
        return []

    devices = []
    for runtime_id, runtime_devices in runtimes.items():
        version_match = re.search(r"SimRuntime\.iOS-([\d-]+)$", runtime_id)
        if version_match:
            version = version_match.group(1).replace("-", ".")
            devices.extend((version, device) for device in runtime_devices)
    return devices


def _version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))
