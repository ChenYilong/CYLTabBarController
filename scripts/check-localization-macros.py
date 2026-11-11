#!/usr/bin/env python3
"""Acceptance check for the localization rule in AGENTS.md ("Localization (i18n / l10n) file structure").

A project passes only when it has at least two different macros (a function of the same name in Swift) that read the
localized files of different layers (the Swift function is named in Swift style, `cylDemoLocalizedString`):
  1. the core macro `CYLLocalizedString`, reading the library bundle (CYLTabBarController/Resources/CYLTabBarController.bundle);
  2. the example macro `CYLDemoLocalizedString`, reading the example-level bundle (Example-Shared/CYLDemo.bundle).
It also checks that every example Xcode project that compiles a file calling the example macro has the macro's source
and the example bundle in the app target.

    python3 scripts/check-localization-macros.py        # exit 1 on a failure

Only the Python standard library is used; run it from anywhere.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = []


def read(rel):
    path = os.path.join(ROOT, rel)
    try:
        with open(path, encoding="utf-8", errors="ignore") as handle:
            return handle.read()
    except OSError:
        failures.append("missing file: " + rel)
        return ""


def check(condition, message):
    if not condition:
        failures.append(message)


# --- layer 1: the core macro and its bundle
core_header = read("CYLTabBarController/CYLUtils/CYLLocalizedString.h")
core_source = read("CYLTabBarController/CYLUtils/CYLLocalizedString.m")
check("CYLLocalizedString(" in core_header, "core macro `CYLLocalizedString` is not declared in CYLLocalizedString.h")
core_bundle = "CYLTabBarController/Resources/CYLTabBarController.bundle"
check(os.path.isdir(os.path.join(ROOT, core_bundle)), "core bundle is missing: " + core_bundle)
check("CYLTabBarController" in core_source, "core macro does not read the CYLTabBarController bundle / table")

# --- layer 2: the example macro and its bundle
demo_header = read("Example-Shared/CYLDemoLocalization.h")
demo_objc = read("Example-Shared/CYLDemoLocalization.m")
demo_swift = read("Example-Shared/CYLDemoLocalization.swift")
check("CYLDemoLocalizedString(" in demo_header, "example macro `CYLDemoLocalizedString` is not declared in CYLDemoLocalization.h")
check(re.search(r"func\s+cylDemoLocalizedString\(", demo_swift) is not None,
      "the Swift function `cylDemoLocalizedString` is missing in CYLDemoLocalization.swift")
demo_bundle = "Example-Shared/CYLDemo.bundle"
check(os.path.isdir(os.path.join(ROOT, demo_bundle)), "example bundle is missing: " + demo_bundle)
check("CYLDemo" in demo_objc and "CYLDemo" in demo_swift, "the example macro does not read CYLDemo.bundle / table `CYLDemo`")

# --- the two layers use two different macros and two different bundles
check("CYLLocalizedString" != "CYLDemoLocalizedString", "one macro cannot serve two layers")
core_languages = {name for name in os.listdir(os.path.join(ROOT, core_bundle))
                  if name.endswith(".lproj")} if os.path.isdir(os.path.join(ROOT, core_bundle)) else set()
demo_languages = {name for name in os.listdir(os.path.join(ROOT, demo_bundle))
                  if name.endswith(".lproj")} if os.path.isdir(os.path.join(ROOT, demo_bundle)) else set()
check("en.lproj" in demo_languages, "the example bundle has no en.lproj (the fallback language)")
check(demo_languages <= core_languages | {"en.lproj"},
      "the example bundle has languages the core bundle lacks: " + ", ".join(sorted(demo_languages - core_languages)))

# --- every example project that compiles a file calling the example macro has the macro's source and the bundle
call = re.compile(r"(?:CYLDemoLocalizedString|cylDemoLocalizedString)\(")
callers = {}
for folder in sorted(os.listdir(ROOT)):
    if not folder.startswith("Example") or folder == "Example-Android":
        continue
    for current, dirs, files in os.walk(os.path.join(ROOT, folder)):
        dirs[:] = [d for d in dirs if d not in ("Pods", "Carthage", "build", "DerivedData", "node_modules", "CYLDemo.bundle")
                   and not d.endswith(".xcodeproj") and not d.endswith(".xcworkspace")]
        for name in files:
            if name.endswith((".swift", ".m")) and not name.startswith("CYLDemoLocalization"):
                with open(os.path.join(current, name), encoding="utf-8", errors="ignore") as handle:
                    if call.search(handle.read()):
                        callers.setdefault(name, []).append(os.path.relpath(os.path.join(current, name), ROOT))
projects = []
for folder in sorted(os.listdir(ROOT)):
    if folder.startswith("Example") and os.path.isdir(os.path.join(ROOT, folder)):
        for entry in os.listdir(os.path.join(ROOT, folder)):
            pbx = os.path.join(ROOT, folder, entry, "project.pbxproj")
            if entry.endswith(".xcodeproj") and os.path.isfile(pbx):
                projects.append(pbx)
projects.append(os.path.join(ROOT, "CYLTabBarController.xcodeproj", "project.pbxproj"))
# [EN] One file reference per line in a project.pbxproj; a quoted or a bare path, matched without backtracking.
REFERENCE_PATH = re.compile(r'\bpath = (?:"([^"]*)"|([^;"]*));')


def compiled_callers(pbx, text):
    """Callers this project really references: a reference with a folder in its path is resolved from the project
    folder; a bare file name only matches a caller inside the project's own folder (another example may have a file
    with the same name)."""
    project_dir = os.path.dirname(os.path.dirname(pbx))
    found = []
    for line in text.splitlines():
        if "isa = PBXFileReference;" not in line:
            continue
        match = REFERENCE_PATH.search(line)
        if not match:
            continue
        ref_path = match.group(1) or match.group(2)
        name = os.path.basename(ref_path)
        for caller in callers.get(name, []):
            caller_abs = os.path.join(ROOT, caller)
            if "/" in ref_path:
                if os.path.normpath(os.path.join(project_dir, ref_path)) == os.path.normpath(caller_abs):
                    found.append(name)
            elif caller_abs.startswith(project_dir + os.sep):
                found.append(name)
    return sorted(set(found))


for pbx in projects:
    with open(pbx, encoding="utf-8", errors="ignore") as handle:
        text = handle.read()
    compiled = compiled_callers(pbx, text)
    if not compiled:
        continue
    swift = any(name.endswith(".swift") for name in compiled)
    objc = any(name.endswith(".m") for name in compiled)
    where = os.path.relpath(pbx, ROOT)
    if swift:
        check("CYLDemoLocalization.swift" in text, where + ": compiles Swift files calling the example macro but not CYLDemoLocalization.swift")
    if objc:
        check("CYLDemoLocalization.m" in text, where + ": compiles ObjC files calling the example macro but not CYLDemoLocalization.m")
    check("CYLDemo.bundle" in text, where + ": compiles files calling the example macro but does not ship CYLDemo.bundle")

if failures:
    print("Localization acceptance FAILED:")
    for message in failures:
        print("  - " + message)
    sys.exit(1)
print("Localization acceptance OK: core macro CYLLocalizedString -> CYLTabBarController.bundle, "
      "example macro CYLDemoLocalizedString -> CYLDemo.bundle (%d languages); %d example projects checked."
      % (len(demo_languages), len(projects)))
