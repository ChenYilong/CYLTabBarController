---
name: xcode-build-fixer
description: Apply approved Xcode build optimization changes following best practices, then re-benchmark to verify improvement. Use when a developer has an approved optimization plan from xcode-build-orchestrator, wants to apply specific build fixes, needs help implementing build setting changes, script phase guards, source-level compilation fixes, or SPM restructuring that was recommended by an analysis skill.
---

# Xcode Build Fixer

Use this skill to implement approved build optimization changes and verify them with a benchmark.

## Core Rules

- Only apply changes that have explicit developer approval.
- Apply one logical fix at a time so changes are reviewable and reversible.
- Re-benchmark after applying changes to verify improvement.
- Report exactly what changed, which files were touched, and the measured delta.
- If a change produces no improvement or causes a regression, flag it immediately.

## Inputs

The fixer expects one of:

- An approved optimization plan at `.build-benchmark/optimization-plan.md` with checked approval boxes.
- An explicit developer instruction describing the fix to apply (e.g., "set `DEBUG_INFORMATION_FORMAT` to `dwarf` for Debug").

When working from an optimization plan, read the approval checklist and implement only the checked items.

## Fix Categories

### Build Settings

Change `project.pbxproj` values to match the recommendations in [build-settings-best-practices.md](references/build-settings-best-practices.md).

Typical fixes:

- Set `DEBUG_INFORMATION_FORMAT = dwarf` for Debug
- Set `SWIFT_COMPILATION_MODE = singlefile` for Debug
- Enable `COMPILATION_CACHING = YES`
- Enable `EAGER_LINKING = YES` for Debug
- Align cross-target settings to eliminate module variants

When editing `project.pbxproj`, locate the correct `buildSettings` block by matching the target name and configuration name. Verify the change with `xcodebuild -showBuildSettings` after applying.

### Script Phases

Fix run script phases that waste time during incremental or debug builds.

Typical fixes:

- Add input and output file declarations so Xcode can skip unchanged scripts.
- Add configuration guards: `[[ "$CONFIGURATION" != "Release" ]] && exit 0` for release-only scripts.
- Move input/output lists into `.xcfilelist` files when the list is long.
- Enable `Based on dependency analysis` when inputs and outputs are declared.

### Source-Level Compilation Fixes

Apply code changes that reduce type-checker and compiler overhead. See [references/fix-patterns.md](references/fix-patterns.md) for before/after patterns.

Typical fixes:

- Add explicit type annotations to complex expressions.
- Break long chained or nested expressions into intermediate typed variables.
- Mark classes `final` when they are not subclassed.
- Tighten access control (`private`/`fileprivate`) for internal-only symbols.
- Extract monolithic SwiftUI `body` properties into smaller composed subviews.
- Replace deeply nested result-builder code with separate typed helpers.
- Add explicit return types to closures passed to generic functions.

### SPM Restructuring

Restructure Swift packages to improve build parallelism and reduce rebuild scope.

Typical fixes:

- Move shared types to a lower-layer module to eliminate circular or upward dependencies.
- Split oversized modules (200+ files) by feature area.
- Extract protocol definitions into lightweight interface modules.
- Remove unnecessary `@_exported import` usage.
- Align build options across targets that import the same packages to prevent module variant duplication.
- Pin branch-tracked dependencies to tagged versions or commit hashes for deterministic resolution.

Before applying version pin changes:

- Run `git ls-remote --tags <url>` to confirm tags exist. If the upstream has no tags, pin to a specific revision hash instead.
- Verify the pinned version resolves successfully with `xcodebuild -resolvePackageDependencies` before proceeding.

## Execution Workflow

1. Read the approved optimization plan or developer instruction.
2. For each approved item, identify the exact files and locations to change.
3. Apply the change.
4. Verify the change compiles: run a quick `xcodebuild build` to confirm no errors were introduced.
5. After all approved changes are applied, re-benchmark using the same inputs from the original baseline:
   ```bash
   python3 scripts/benchmark_builds.py \
     --project App.xcodeproj \
     --scheme MyApp \
     --configuration Debug \
     --destination "platform=iOS Simulator,name=iPhone 16" \
     --output-dir .build-benchmark
   ```
6. Compare post-change medians to the baseline and report deltas.

## Evaluating Regressions

Not every slower number is a true regression. The fixer must evaluate the full picture before recommending a revert.

### Compilation caching trade-off

A change like `COMPILATION_CACHING = YES` may make a standard clean build slightly slower (cache population overhead) while making cached clean builds significantly faster. Since cached clean builds reflect the realistic developer workflow (branch switching, pulling changes, Clean Build Folder with a warm cache), a slower standard clean build paired with a faster cached clean build is a net improvement, not a regression. The same logic applies to any change where the first-time cost is higher but subsequent builds benefit.

### Compare all build types

Evaluate standard clean, cached clean (when available), and incremental builds together. A change is only a clear regression if it makes the metrics that matter to the developer's daily workflow worse. If only the cold-start clean build is slower but the developer rarely does truly cold builds, that may be acceptable.

### Per-change vs. cumulative

A single change that regresses on its own may still be worth keeping if it enables a larger cumulative improvement (e.g., enabling compilation caching makes one build type slower but unlocks cache benefits for everything else).

### Best-practice settings are not revert candidates

Some build settings are Apple's recommended modern defaults. These should be applied and kept regardless of whether the immediate benchmark shows a measurable improvement. They are not speculative optimizations -- they align the project with Apple's toolchain direction and will compound in value over future Xcode releases. The fixer must never recommend reverting these settings based on a single benchmark result.

Best-practice settings that should always be kept once applied:

- `COMPILATION_CACHING = YES` -- Apple is actively investing in this; the cache improves with each Xcode release and compounds across real workflows
- `EAGER_LINKING = YES` (Debug) -- allows the linker to overlap with compilation
- `SWIFT_USE_INTEGRATED_DRIVER = YES` -- eliminates inter-process scheduling overhead
- `DEBUG_INFORMATION_FORMAT = dwarf` (Debug) -- avoids unnecessary dSYM generation
- `SWIFT_COMPILATION_MODE = singlefile` (Debug) -- incremental recompilation
- `ONLY_ACTIVE_ARCH = YES` (Debug) -- no reason to build all architectures locally

When reporting on these settings, use language like: "Applied recommended build setting. No immediate benchmark improvement measured, but this aligns with Apple's recommended configuration and positions the project for future Xcode improvements."

### When to recommend revert (speculative changes only)

For changes that are not best-practice settings (e.g., source refactors, linkage experiments, script phase modifications, dependency restructuring):

- If the cumulative pass shows wall-clock regression across all measured build types (standard clean, cached clean, and incremental are all slower), recommend reverting all speculative changes unless the developer explicitly asks to keep specific items for non-performance reasons.
- For each individual speculative change: if it shows no median improvement and no cached/incremental benefit either, flag it with `Recommend revert` and the measured delta.
- Distinguish between "outlier reduction only" (improved worst-case but not median) and "median improvement" (improved typical developer wait).
- When a change trades off one build type for another (e.g., slower standard clean but faster cached clean), present both numbers clearly and let the developer decide. Frame it as: "Standard clean builds are X.Xs slower, but cached clean builds (the realistic daily workflow) are Y.Ys faster."

## Reporting

Lead with the wall-clock result in plain language:

> "Your clean build now takes X.Xs (was Y.Ys) -- Z.Zs faster."
> "Your incremental build now takes X.Xs (was Y.Ys) -- Z.Zs faster."

Then include:

- Post-change clean build wall-clock median
- Post-change incremental build wall-clock median
- Absolute and percentage wall-clock deltas for both
- Confidence notes if benchmark noise is high
- List of files modified per fix
- Any deviations from the original recommendation

If cumulative task metrics improved but wall-clock did not, say plainly: "Compiler workload decreased but build wait time did not improve. This is expected when Xcode runs these tasks in parallel with other equally long work."

If a fix produced no measurable wall-time improvement, note `No measurable wall-time improvement` and suggest whether to keep (e.g. for code quality) or revert.

For changes valuable for non-benchmark reasons (deterministic package resolution, branch-switch caching), label them: "No wait-time improvement expected from this change. The benefit is [deterministic builds / faster branch switching / reduced CI cost]."

Note: `COMPILATION_CACHING` has been measured at 5-14% faster clean builds across tested projects (87 to 1,991 Swift files). The benefit compounds in real developer workflows where the cache persists between builds -- branch switching, pulling changes, and CI with persistent DerivedData. The benchmark script auto-detects this setting and runs a cached clean phase for validation.

## Execution Report

After the optimization pass is complete, produce a structured execution report. This gives the developer a clear summary of what was attempted, what worked, and what the final state is.

Structure:

```markdown
## Execution Report

### Baseline
- Clean build median: X.Xs
- Cached clean build median: X.Xs (if applicable)
- Incremental build median: X.Xs

### Changes Applied

| # | Change | Actionability | Measured Result | Status |
|---|--------|---------------|-----------------|--------|
| 1 | Description | repo-local | Clean: X.Xs→Y.Ys, Incr: X.Xs→Y.Ys | Kept / Reverted / Blocked |
| 2 | ... | ... | ... | ... |

### Final Cumulative Result
- Clean build median: X.Xs (was Y.Ys) -- Z.Zs faster/slower
- Cached clean build median: X.Xs (was Y.Ys) -- Z.Zs faster/slower
- Incremental build median: X.Xs (was Y.Ys) -- Z.Zs faster/slower
- **Net result:** Faster / Slower / Unchanged

### Blocked or Non-Actionable Findings
- Finding: reason it could not be addressed from the repo
```

Status values:

- `Kept` -- Change improved or maintained build times and was kept.
- `Kept (best practice)` -- Change is a recommended build setting; kept regardless of immediate benchmark result.
- `Reverted` -- Change regressed build times and was reverted.
- `Blocked` -- Change could not be applied due to project structure, Xcode behavior, or external constraints.
- `No improvement` -- Change compiled but showed no measurable wall-time benefit. Include whether it was kept (for non-performance reasons) or reverted.

## Escalation

If during implementation you discover issues outside this skill's scope:

- Project-level analysis gaps: hand off to [`xcode-project-analyzer`](../xcode-project-analyzer/SKILL.md)
- Compilation hotspot analysis: hand off to [`xcode-compilation-analyzer`](../xcode-compilation-analyzer/SKILL.md)
- Package graph issues: hand off to [`spm-build-analysis`](../spm-build-analysis/SKILL.md)

## Additional Resources

- For concrete before/after fix patterns, see [references/fix-patterns.md](references/fix-patterns.md)
- For build settings best practices, see [references/build-settings-best-practices.md](references/build-settings-best-practices.md)
- For the recommendation format, see [references/recommendation-format.md](references/recommendation-format.md)
