#!/usr/bin/env python3
"""
Build and Test Automation for Xcode Projects

Ultra token-efficient build automation with progressive disclosure via xcresult bundles.

Features:
- Minimal default output (5-10 tokens)
- Progressive disclosure for error/warning/log details
- Native xcresult bundle support
- Clean modular architecture

Usage Examples:
    # Build (minimal output)
    python scripts/build_and_test.py --project MyApp.xcodeproj
    # Output: Build: SUCCESS (0 errors, 3 warnings) [xcresult-20251018-143052]

    # Get error details
    python scripts/build_and_test.py --get-errors xcresult-20251018-143052

    # Get warnings
    python scripts/build_and_test.py --get-warnings xcresult-20251018-143052

    # Get build log
    python scripts/build_and_test.py --get-log xcresult-20251018-143052

    # Get everything as JSON
    python scripts/build_and_test.py --get-all xcresult-20251018-143052 --json

    # List recent builds
    python scripts/build_and_test.py --list-xcresults

    # Verbose mode (for debugging)
    python scripts/build_and_test.py --project MyApp.xcodeproj --verbose
"""

import argparse
import sys
import time
from pathlib import Path

from app_launcher import AppLauncher

# Import our modular components
from common.env_config import env_int
from simctl_boot import SimulatorBooter

from xcode import BuildRunner, OutputFormatter, XCResultCache, XCResultParser
from xcode.reporter import is_runner_failure

BUILD_LOG_PREVIEW_CHARS = env_int("IOS_SIM_BUILD_LOG_PREVIEW", 4000)
BUILD_JSON_CAP = env_int("IOS_SIM_BUILD_JSON_CAP", 50)
LAUNCH_RETRY_DELAY_S = 1.0


def run_built_app(builder: BuildRunner) -> tuple[dict | None, str]:
    """Install and launch the app a successful build produced.

    Returns (run info, message): info is None on failure and the message is one line
    naming the failed step and what to do next.
    """
    built_app = builder.get_built_app()
    if not built_app:
        return None, f"Run failed: no .app target in scheme {builder.scheme} (is it a framework?)"
    app_path, bundle_id = built_app

    udid = builder.get_destination_udid()
    if not udid:
        return (
            None,
            "Run failed: no simulator to run on; pass --simulator '<name>' (see sim_list.py)",
        )

    booted, boot_message = SimulatorBooter(udid).boot(wait_ready=True)
    if not booted and "Booted" not in boot_message:
        return None, f"Run failed: could not boot {udid}: {boot_message}"

    launcher = AppLauncher(udid)
    if not launcher.install(app_path):
        return None, f"Run failed: could not install {app_path}; retry or try --clean"
    launched, pid = launcher.launch(bundle_id)
    if not launched:
        # Seen once right after a fresh install; a second attempt succeeded.
        time.sleep(LAUNCH_RETRY_DELAY_S)
        launched, pid = launcher.launch(bundle_id)
    if not launched:
        return None, f"Run failed: installed {bundle_id} but launch failed; check log_monitor.py"

    device_name = builder._extract_simulator_name_from_destination(
        builder.get_simulator_destination()
    )
    pid_text = f"pid {pid}" if pid else "pid unknown"
    info = {"bundle_id": bundle_id, "app_path": app_path, "udid": udid, "pid": pid}
    return info, f"Launched: {bundle_id} on {device_name} ({pid_text})"


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Build and test Xcode projects with progressive disclosure",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Build project (minimal output)
  python scripts/build_and_test.py --project MyApp.xcodeproj

  # Run tests
  python scripts/build_and_test.py --project MyApp.xcodeproj --test

  # Get error details from previous build
  python scripts/build_and_test.py --get-errors xcresult-20251018-143052

  # Get all details as JSON
  python scripts/build_and_test.py --get-all xcresult-20251018-143052 --json

  # List recent builds
  python scripts/build_and_test.py --list-xcresults
        """,
    )

    # Build/test mode arguments
    build_group = parser.add_argument_group("Build/Test Options")
    project_group = build_group.add_mutually_exclusive_group()
    project_group.add_argument("--project", help="Path to .xcodeproj file")
    project_group.add_argument("--workspace", help="Path to .xcworkspace file")

    build_group.add_argument("--scheme", help="Build scheme (auto-detected if not specified)")
    build_group.add_argument(
        "--configuration",
        default="Debug",
        help="Build configuration (default: Debug). Accepts any valid Xcode configuration.",
    )
    build_group.add_argument(
        "--simulator", help="Simulator name (default: an iPhone on the newest installed runtime)"
    )
    build_group.add_argument(
        "--os", dest="os_version", help="iOS version to pin --simulator to, e.g. 26.5"
    )
    build_group.add_argument("--clean", action="store_true", help="Clean before building")
    build_group.add_argument("--test", action="store_true", help="Run tests")
    build_group.add_argument("--suite", help="Specific test suite to run")
    build_group.add_argument(
        "--run", action="store_true", help="After a successful build, install and launch the app"
    )
    build_group.add_argument(
        "--no-parallel",
        action="store_true",
        help="Run tests on one simulator (no parallel clones)",
    )

    # Progressive disclosure arguments
    disclosure_group = parser.add_argument_group("Progressive Disclosure Options")
    disclosure_group.add_argument(
        "--get-errors", metavar="XCRESULT_ID", help="Get error details from xcresult"
    )
    disclosure_group.add_argument(
        "--get-warnings", metavar="XCRESULT_ID", help="Get warning details from xcresult"
    )
    disclosure_group.add_argument(
        "--get-log", metavar="XCRESULT_ID", help="Get build log from xcresult"
    )
    disclosure_group.add_argument(
        "--get-all", metavar="XCRESULT_ID", help="Get all details from xcresult"
    )
    disclosure_group.add_argument(
        "--list-xcresults", action="store_true", help="List recent xcresult bundles"
    )

    # Output options
    output_group = parser.add_argument_group("Output Options")
    output_group.add_argument("--verbose", action="store_true", help="Show detailed output")
    output_group.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()
    if args.run and args.test:
        print("Error: --run builds and launches the app; it can't be combined with --test")
        return 1

    # Initialize cache
    cache = XCResultCache()

    # Handle list mode
    if args.list_xcresults:
        xcresults = cache.list()
        if args.json:
            import json

            print(json.dumps(xcresults, indent=2))
        elif not xcresults:
            print("No xcresult bundles found")
        else:
            print(f"Recent XCResult bundles ({len(xcresults)}):")
            print()
            for xc in xcresults:
                print(f"  {xc['id']}")
                print(f"    Created: {xc['created']}")
                print(f"    Size: {xc['size_mb']} MB")
                print()
        return 0

    # Handle retrieval modes
    xcresult_id = args.get_errors or args.get_warnings or args.get_log or args.get_all

    if xcresult_id:
        xcresult_path = cache.get_path(xcresult_id)

        if not xcresult_path or not xcresult_path.exists():
            print(f"Error: XCResult bundle not found: {xcresult_id}", file=sys.stderr)
            print("Use --list-xcresults to see available bundles", file=sys.stderr)
            return 1

        # Load cached stderr for progressive disclosure
        cached_stderr = cache.get_stderr(xcresult_id)
        parser = XCResultParser(xcresult_path, stderr=cached_stderr)

        # Get errors
        if args.get_errors:
            errors = parser.get_errors()
            if args.json:
                import json

                print(json.dumps(errors, indent=2))
            else:
                print(OutputFormatter.format_errors(errors))
            return 0

        # Get warnings
        if args.get_warnings:
            warnings = parser.get_warnings()
            if args.json:
                import json

                print(json.dumps(warnings, indent=2))
            else:
                print(OutputFormatter.format_warnings(warnings))
            return 0

        # Get log
        if args.get_log:
            log = parser.get_build_log()
            if log:
                print(OutputFormatter.format_log(log))
            else:
                print("No build log available", file=sys.stderr)
                return 1
            return 0

        # Get all
        if args.get_all:
            error_count, warning_count = parser.count_issues()
            errors = parser.get_errors()
            warnings = parser.get_warnings()
            build_log = parser.get_build_log()

            if args.json:
                import json

                data = {
                    "xcresult_id": xcresult_id,
                    "error_count": error_count,
                    "warning_count": warning_count,
                    "errors": errors,
                    "warnings": warnings,
                    "log_preview": build_log[:BUILD_LOG_PREVIEW_CHARS] if build_log else None,
                }
                print(json.dumps(data, indent=2))
            else:
                print(f"XCResult: {xcresult_id}")
                print(f"Errors: {error_count}, Warnings: {warning_count}")
                print()
                if errors:
                    print(OutputFormatter.format_errors(errors, limit=10))
                    print()
                if warnings:
                    print(OutputFormatter.format_warnings(warnings, limit=10))
                    print()
                if build_log:
                    print("Build Log (last 30 lines):")
                    print(OutputFormatter.format_log(build_log, lines=30))
            return 0

    # Build/test mode
    if not args.project and not args.workspace:
        # Try to auto-detect in current directory
        cwd = Path.cwd()
        projects = list(cwd.glob("*.xcodeproj"))
        workspaces = list(cwd.glob("*.xcworkspace"))

        if workspaces:
            args.workspace = str(workspaces[0])
        elif projects:
            args.project = str(projects[0])
        else:
            parser.error("No project or workspace specified and none found in current directory")

    # Initialize builder
    builder = BuildRunner(
        project_path=args.project,
        workspace_path=args.workspace,
        scheme=args.scheme,
        configuration=args.configuration,
        simulator=args.simulator,
        os_version=args.os_version,
        cache=cache,
    )

    # Execute build or test
    if args.test:
        success, xcresult_id, stderr = builder.test(
            test_suite=args.suite, parallel=not args.no_parallel
        )
    else:
        success, xcresult_id, stderr = builder.build(clean=args.clean)

    if not xcresult_id and not stderr:
        print("Error: Build/test failed without creating xcresult or error output", file=sys.stderr)
        return 1

    # Save stderr to cache for progressive disclosure
    if xcresult_id and stderr:
        cache.save_stderr(xcresult_id, stderr)

    # Parse results
    xcresult_path = cache.get_path(xcresult_id) if xcresult_id else None
    parser = XCResultParser(xcresult_path, stderr=stderr)
    error_count, warning_count = parser.count_issues()

    # Format output
    status = "SUCCESS" if success else "FAILED"

    # Collect errors on failure (used by all output modes)
    errors = parser.get_errors() if not success else None
    hints = OutputFormatter.generate_hints(errors) if errors else None

    # Collect test info and failed tests when testing
    test_info = None
    failed_tests = None
    if args.test and xcresult_path:
        test_results = parser.get_test_results()
        if test_results:
            # Xcode 16 `xcresulttool get test-results summary` keys are
            # totalTestCount / passedTests / failedTests (fall back to the
            # legacy total/passed/failed names for older Xcode).
            start = test_results.get("startTime")
            finish = test_results.get("finishTime")
            duration = (
                round(finish - start, 1)
                if isinstance(start, (int, float)) and isinstance(finish, (int, float))
                else test_results.get("duration", 0.0)
            )
            test_info = {
                "total": test_results.get("totalTestCount", test_results.get("total", 0)),
                "passed": test_results.get("passedTests", test_results.get("passed", 0)),
                "failed": test_results.get("failedTests", test_results.get("failed", 0)),
                "duration": duration,
            }
        if not success:
            failed_tests = parser.get_failed_tests()

    runner_failed = args.test and not success and is_runner_failure(errors, test_info)

    run_info = None
    run_message = None
    if args.run and success:
        run_info, run_message = run_built_app(builder)
        success = run_info is not None

    if args.verbose:
        # Verbose mode with error/warning details
        verbose_errors = errors if error_count > 0 else None
        warnings = parser.get_warnings() if warning_count > 0 else None

        output = OutputFormatter.format_verbose(
            status=status,
            error_count=error_count,
            warning_count=warning_count,
            xcresult_id=xcresult_id or "N/A",
            errors=verbose_errors,
            warnings=warnings,
            test_info=test_info,
        )
        print(output)
    elif args.json:
        # JSON mode
        data = {
            "success": success,
            "xcresult_id": xcresult_id or None,
            "error_count": error_count,
            "warning_count": warning_count,
        }
        if test_info:
            data["test_info"] = test_info
        if not success:
            if errors:
                data["errors"] = errors[:BUILD_JSON_CAP]
            if failed_tests:
                data["failed_tests"] = failed_tests[:BUILD_JSON_CAP]
        if runner_failed:
            data["status"] = "not_run"
        if run_info:
            data["run"] = run_info
        elif run_message:
            data["run_error"] = run_message
        if hints:
            data["hints"] = hints
        import json

        print(json.dumps(data, indent=2))
    else:
        # Minimal mode (default)
        output = OutputFormatter.format_minimal(
            status=status,
            error_count=error_count,
            warning_count=warning_count,
            xcresult_id=xcresult_id or "N/A",
            test_info=test_info,
            hints=hints,
            errors=errors,
            failed_tests=failed_tests,
            runner_failed=runner_failed,
        )
        print(output)
    if run_message and not args.json:
        print(run_message)

    # Exit with appropriate code
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
