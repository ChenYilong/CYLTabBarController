"""
Build/test output formatting.

Provides multiple output formats with progressive disclosure support.
"""

import json

from common.env_config import env_int

BUILD_SUMMARY_CAP = env_int("IOS_SIM_BUILD_SUMMARY_CAP", 15)
BUILD_VERBOSE_CAP = env_int("IOS_SIM_BUILD_VERBOSE_CAP", 100)
BUILD_LOG_TAIL = env_int("IOS_SIM_LOG_TAIL", 200)

# Messages xcodebuild emits when the test runner (often a parallel clone) can't start.
RUNNER_FAILURE_PATTERNS = (
    "failed to prepare device",
    "timed out trying to boot",
    "no matching device",
)


def is_runner_failure(errors: list[dict] | None, test_info: dict | None) -> bool:
    """True when no test passed and every error says the test runner couldn't start."""
    if not errors or (test_info or {}).get("passed", 0) > 0:
        return False
    return all(
        any(pattern in error.get("message", "").lower() for pattern in RUNNER_FAILURE_PATTERNS)
        for error in errors
    )


class OutputFormatter:
    """
    Format build/test results for display.

    Supports ultra-minimal default output, verbose mode, and JSON output.
    """

    @staticmethod
    def format_minimal(
        status: str,
        error_count: int,
        warning_count: int,
        xcresult_id: str,
        test_info: dict | None = None,
        hints: list[str] | None = None,
        errors: list[dict] | None = None,
        failed_tests: list[dict] | None = None,
        runner_failed: bool = False,
    ) -> str:
        """
        Format ultra-minimal output (5-10 tokens on success, more on failure).

        On failure, automatically surfaces top errors/failed tests inline so agents
        don't need a second round-trip with --get-errors.

        Args:
            status: Build status (SUCCESS/FAILED)
            error_count: Number of errors
            warning_count: Number of warnings
            xcresult_id: XCResult bundle ID
            test_info: Optional test results dict
            hints: Optional list of actionable hints
            errors: Optional error list to surface on failure
            failed_tests: Optional failed test list to surface on failure
            runner_failed: Tests never ran because the runner couldn't start (is_runner_failure)

        Returns:
            Minimal formatted string
        """
        lines = []

        if runner_failed:
            lines.append(
                f"Tests: NOT RUN (test runner couldn't start on the simulator) [{xcresult_id}]"
            )
            hints = ["Retry, or run tests on one simulator: --no-parallel"]
        elif test_info:
            # Test mode
            total = test_info.get("total", 0)
            passed = test_info.get("passed", 0)
            failed = test_info.get("failed", 0)
            duration = test_info.get("duration", 0.0)

            test_status = "PASS" if failed == 0 else "FAIL"
            lines.append(
                f"Tests: {test_status} ({passed}/{total} passed, {duration:.1f}s) [{xcresult_id}]"
            )
        else:
            # Build mode
            lines.append(
                f"Build: {status} ({error_count} errors, {warning_count} warnings) [{xcresult_id}]"
            )

        # Surface errors inline on failure
        if status == "FAILED" and errors:
            lines.append("")
            lines.append(OutputFormatter.format_errors(errors, limit=BUILD_SUMMARY_CAP))

        # Surface failed tests inline on failure
        if failed_tests:
            lines.append("")
            lines.append(
                OutputFormatter.format_test_failures(failed_tests, limit=BUILD_SUMMARY_CAP)
            )

        # Add hints if provided and build failed
        if hints and status == "FAILED":
            lines.append("")
            lines.extend(hints)

        return "\n".join(lines)

    @staticmethod
    def format_test_failures(failed_tests: list[dict], limit: int = BUILD_SUMMARY_CAP) -> str:
        """
        Format failed test details.

        Args:
            failed_tests: List of dicts with test_name and failure_message
            limit: Maximum failures to show

        Returns:
            Formatted failure list
        """
        if not failed_tests:
            return "No test failures found."

        lines = [f"Failed tests ({len(failed_tests)}):"]
        lines.append("")

        for i, test in enumerate(failed_tests[:limit], 1):
            name = test.get("test_name", "Unknown")
            message = test.get("failure_message", "")
            lines.append(f"{i}. {name}")
            if message:
                lines.append(f"   {message}")
            lines.append("")

        if len(failed_tests) > limit:
            lines.append(f"... and {len(failed_tests) - limit} more failures")

        return "\n".join(lines)

    @staticmethod
    def format_errors(errors: list[dict], limit: int = BUILD_VERBOSE_CAP) -> str:
        """
        Format error details.

        Args:
            errors: List of error dicts
            limit: Maximum errors to show

        Returns:
            Formatted error list
        """
        if not errors:
            return "No errors found."

        lines = [f"Errors ({len(errors)}):"]
        lines.append("")

        for i, error in enumerate(errors[:limit], 1):
            message = error.get("message", "Unknown error")
            location = error.get("location", {})

            # Format location
            loc_parts = []
            if location.get("file"):
                file_path = location["file"].replace("file://", "")
                loc_parts.append(file_path)
            if location.get("line"):
                loc_parts.append(f"line {location['line']}")

            location_str = ":".join(loc_parts) if loc_parts else "unknown location"

            lines.append(f"{i}. {message}")
            lines.append(f"   Location: {location_str}")
            lines.append("")

        if len(errors) > limit:
            lines.append(f"... and {len(errors) - limit} more errors")

        return "\n".join(lines)

    @staticmethod
    def format_warnings(warnings: list[dict], limit: int = BUILD_VERBOSE_CAP) -> str:
        """
        Format warning details.

        Args:
            warnings: List of warning dicts
            limit: Maximum warnings to show

        Returns:
            Formatted warning list
        """
        if not warnings:
            return "No warnings found."

        lines = [f"Warnings ({len(warnings)}):"]
        lines.append("")

        for i, warning in enumerate(warnings[:limit], 1):
            message = warning.get("message", "Unknown warning")
            location = warning.get("location", {})

            # Format location
            loc_parts = []
            if location.get("file"):
                file_path = location["file"].replace("file://", "")
                loc_parts.append(file_path)
            if location.get("line"):
                loc_parts.append(f"line {location['line']}")

            location_str = ":".join(loc_parts) if loc_parts else "unknown location"

            lines.append(f"{i}. {message}")
            lines.append(f"   Location: {location_str}")
            lines.append("")

        if len(warnings) > limit:
            lines.append(f"... and {len(warnings) - limit} more warnings")

        return "\n".join(lines)

    @staticmethod
    def format_log(log: str, lines: int = BUILD_LOG_TAIL) -> str:
        """
        Format build log (show last N lines).

        Args:
            log: Full build log
            lines: Number of lines to show

        Returns:
            Formatted log excerpt
        """
        if not log:
            return "No build log available."

        log_lines = log.strip().split("\n")

        if len(log_lines) <= lines:
            return log

        # Show last N lines
        excerpt = log_lines[-lines:]
        return f"... (showing last {lines} lines of {len(log_lines)})\n\n" + "\n".join(excerpt)

    @staticmethod
    def format_json(data: dict) -> str:
        """
        Format data as JSON.

        Args:
            data: Data to format

        Returns:
            Pretty-printed JSON string
        """
        return json.dumps(data, indent=2)

    @staticmethod
    def generate_hints(errors: list[dict]) -> list[str]:
        """
        Generate actionable hints based on error types.

        Args:
            errors: List of error dicts

        Returns:
            List of hint strings
        """
        hints = []
        error_types: set[str] = set()

        # Collect error types
        for error in errors:
            error_type = error.get("type", "unknown")
            error_types.add(error_type)

        # Generate hints based on error types
        if "provisioning" in error_types:
            hints.append("Provisioning profile issue detected:")
            hints.append("  • Ensure you have a valid provisioning profile for iOS Simulator")
            hints.append(
                '  • For simulator builds, use CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO'
            )
            hints.append(
                "  • Or specify simulator explicitly: --simulator '<name>' (names: python scripts/sim_list.py)"
            )

        if "signing" in error_types:
            hints.append("Code signing issue detected:")
            hints.append("  • For simulator builds, code signing is not required")
            hints.append("  • Ensure build settings target iOS Simulator, not physical device")
            hints.append("  • Check destination: platform=iOS Simulator,name=<device>")

        if not error_types or "build" in error_types:
            # Generic hints when error type is unknown
            if any("destination" in error.get("message", "").lower() for error in errors):
                hints.append("Device selection issue detected:")
                hints.append("  • List available simulators: xcrun simctl list devices available")
                hints.append(
                    "  • Specify simulator: --simulator '<name>' (names: python scripts/sim_list.py)"
                )

        return hints

    @staticmethod
    def format_verbose(
        status: str,
        error_count: int,
        warning_count: int,
        xcresult_id: str,
        errors: list[dict] | None = None,
        warnings: list[dict] | None = None,
        test_info: dict | None = None,
    ) -> str:
        """
        Format verbose output with error/warning details.

        Args:
            status: Build status
            error_count: Error count
            warning_count: Warning count
            xcresult_id: XCResult ID
            errors: Optional error list
            warnings: Optional warning list
            test_info: Optional test results

        Returns:
            Verbose formatted output
        """
        lines = []

        # Header
        if test_info:
            total = test_info.get("total", 0)
            passed = test_info.get("passed", 0)
            failed = test_info.get("failed", 0)
            duration = test_info.get("duration", 0.0)

            test_status = "PASS" if failed == 0 else "FAIL"
            lines.append(f"Tests: {test_status}")
            lines.append(f"  Total: {total}")
            lines.append(f"  Passed: {passed}")
            lines.append(f"  Failed: {failed}")
            lines.append(f"  Duration: {duration:.1f}s")
        else:
            lines.append(f"Build: {status}")

        lines.append(f"XCResult: {xcresult_id}")
        lines.append("")

        # Errors
        if errors and len(errors) > 0:
            lines.append(OutputFormatter.format_errors(errors, limit=BUILD_VERBOSE_CAP))
            lines.append("")

        # Warnings
        if warnings and len(warnings) > 0:
            lines.append(OutputFormatter.format_warnings(warnings, limit=BUILD_VERBOSE_CAP))
            lines.append("")

        # Summary
        lines.append(f"Summary: {error_count} errors, {warning_count} warnings")

        return "\n".join(lines)
