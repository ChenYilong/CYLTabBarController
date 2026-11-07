---
name: xcode-project-analyzer
description: Audit Xcode project configuration, build settings, scheme behavior, and script phases to find build-time improvements with explicit approval gates. Use when a developer wants project-level build analysis, slow incremental builds, guidance on target dependencies, build settings review, run script phase analysis, parallelization improvements, or module-map and DEFINES_MODULE configuration.
---

# Xcode Project Analyzer

Use this skill for project- and target-level build inefficiencies that are unlikely to be solved by source edits alone.

## Core Rules

- Recommendation-first by default.
- Require explicit approval before changing project files, schemes, or build settings.
- Prefer measured findings tied to timing summaries, build logs, or project configuration evidence.
- Distinguish debug-only pain from release-only pain.

## What To Review

- scheme build order and target dependencies
- debug vs release build settings against the [build settings best practices](references/build-settings-best-practices.md)
- run script phases and dependency-analysis settings
- derived-data churn or obviously invalidating custom steps
- opportunities for parallelization
- explicit module dependency settings and module-map readiness
- "Planning Swift module" time in the Build Timing Summary -- if it dominates incremental builds, suspect unexpected input modification or macro-related invalidation
- asset catalog compilation time, especially in targets with large or numerous catalogs
- `ExtractAppIntentsMetadata` time in the Build Timing Summary -- if this phase consumes significant time, record it as `xcode-behavior` (report the cost and impact, but do not suggest a repo-local optimization unless there is explicit Apple guidance)
- zero-change build overhead -- if a no-op rebuild exceeds a few seconds, investigate fixed-cost phases (script execution, codesign, validation, CopySwiftLibs)
- CocoaPods usage -- if a `Podfile` or `Pods.xcodeproj` exists, CocoaPods is deprecated; recommend migrating to SPM and do not attempt CocoaPods-specific optimizations (see [project-audit-checks.md](references/project-audit-checks.md))
- Task Backtraces (Xcode 16.4+: Scheme Editor > Build > Build Debugging) to diagnose why tasks re-run unexpectedly in incremental builds

## Build Settings Best Practices Audit

Every project audit should include a build settings checklist comparing the project's Debug and Release configurations against the recommended values in [build-settings-best-practices.md](references/build-settings-best-practices.md). Present results using checkmark/cross indicators (`[x]`/`[ ]`). The scope is strictly build performance -- do not flag language-migration settings like `SWIFT_STRICT_CONCURRENCY` or `SWIFT_UPCOMING_FEATURE_*`.

## Apple-Derived Checks

Review these items in every audit:

- target dependencies are accurate and not missing or inflated
- schemes build in `Dependency Order`
- run scripts declare inputs and outputs
- `.xcfilelist` files are used when scripts have many inputs or outputs
- `DEFINES_MODULE` is enabled where custom frameworks or libraries should expose module maps
- headers are self-contained enough for module-map use
- explicit module dependency settings are consistent for targets that should share modules

## Typical Wins

- skip debug-time scripts that only matter in release
- add missing script guards or dependency-analysis metadata
- remove accidental serial bottlenecks in schemes
- align build settings that cause unnecessary module variants
- fix stale project structure that forces broader rebuilds than necessary
- identify linters or formatters that touch file timestamps without changing content, silently invalidating build inputs and forcing module replanning
- split large asset catalogs into separate resource bundles across targets to parallelize compilation
- use Task Backtraces to pinpoint the exact input change that triggers unnecessary incremental work

## Reporting Format

For each issue, include:

- evidence
- likely scope
- why it affects clean builds, incremental builds, or both
- estimated impact
- approval requirement

If the evidence points to package graph or build plugins, hand off to [`spm-build-analysis`](../spm-build-analysis/SKILL.md) by reading its SKILL.md and applying its workflow to the same project context.

## Additional Resources

- For the detailed audit checklist, see [references/project-audit-checks.md](references/project-audit-checks.md)
- For build settings best practices, see [references/build-settings-best-practices.md](references/build-settings-best-practices.md)
- For the shared recommendation structure, see [references/recommendation-format.md](references/recommendation-format.md)
- For Apple-aligned source summaries, see [references/build-optimization-sources.md](references/build-optimization-sources.md)
