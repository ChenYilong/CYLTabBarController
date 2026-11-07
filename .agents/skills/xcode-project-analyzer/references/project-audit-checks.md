# Project Audit Checks

Use this reference when reviewing build-system configuration rather than source-level compile behavior.

## Target And Scheme Checks

- Confirm target dependencies are explicit and accurate.
- Remove dependencies that no longer reflect real build requirements.
- Ensure the scheme builds targets in `Dependency Order`.
- Look for oversized or monolithic targets that block parallel work.

## Build Script Checks

- Does each script need to run during incremental builds?
- Are input and output files declared?
- Should inputs and outputs be moved into `.xcfilelist` files?
- Can the script skip debug builds, simulator builds, or unchanged inputs?
- Would the script become parallelizable if dependency analysis were declared correctly?
- Could a misconfigured linter or formatter script be touching file timestamps without changing content? This silently invalidates build inputs and forces replanning of every module.

## Build Planning And Incremental Overhead Checks

- Check whether "Planning Swift module" appears as a significant category in the Build Timing Summary. In projects with many modules this step can take up to 30s per module, sometimes exceeding clean build time.
- If modules are replanned but no compiles are scheduled, suspect unexpected input modification (see Build Script Checks above).
- Enable **Task Backtraces** (Xcode 16.4+) to diagnose why tasks re-run in incremental builds: Scheme Editor > Build tab > Build Debugging > enable "Task Backtraces." Expanding tasks in the build log will show a backtrace explaining what input change triggered the re-run.
- Measure zero-change incremental build time as a baseline. Even with no source changes, builds incur fixed overhead: compute dependencies, send project description to build service, create build description, run script phases, codesign, and validate. If this baseline exceeds a few seconds, investigate each contributor.
- Check whether codesigning and validation run on every build even when the build output has not changed.

## Zero-Change Build Overhead Analysis

When a zero-change build (no edits, immediate rebuild) takes more than a few seconds, the overhead comes from fixed-cost phases rather than compilation. Investigate these categories in the Build Timing Summary:

- **PhaseScriptExecution**: Script phases with `alwaysOutOfDate = 1` or missing input/output declarations run on every build regardless of changes. Linters, formatters, and upload scripts are common offenders.
- **CodeSign**: Codesigning runs on every build for the app target and any embedded frameworks. Time scales with the number of signed binaries.
- **ValidateEmbeddedBinary**: Validates embedded binaries against the host app's provisioning profile. Runs unconditionally.
- **CopySwiftLibs**: Copies Swift standard libraries into the app bundle. Runs even when nothing changed.
- **RegisterWithLaunchServices**: Registers the built app with Launch Services. Fast but present in every build.
- **ProcessInfoPlistFile**: Re-processes Info.plist files. Time scales with the number of targets.
- **ExtractAppIntentsMetadata**: Extracts App Intents metadata from all targets. This phase is driven by Xcode and runs across all targets including CocoaPods and SwiftPM dependencies, not just first-party targets. If the project does not use App Intents, the work is unnecessary overhead, but it is not cleanly suppressible from project-level build settings alone. Classify findings about this phase as `xcode-behavior` actionability -- report the measured cost for awareness but do not promise a repo-local fix.

A zero-change build above 5 seconds on Apple Silicon typically indicates script phase overhead or an excessive number of targets requiring codesign and validation passes.

## Asset Catalog Checks

- Asset catalog compilation (`CompileAssetCatalog`) is single-threaded per target. Multiple catalogs within the same target compile sequentially in a single process.
- If asset catalog compilation appears as a significant timing category, recommend splitting assets into separate resource bundles across separate targets to enable parallel compilation.
- Asset catalog compilation is not cacheable by the Xcode compilation cache (`CompileAssetCatalogVariant` is non-cacheable).
- Check whether asset catalogs rebuild during incremental builds even when no assets changed. If so, investigate whether build inputs for the catalog step are being invalidated unexpectedly.

## Build Setting Checks

Audit project-level and target-level settings against the [build settings best practices](build-settings-best-practices.md). Present results as a checklist with `[x]`/`[ ]` indicators.

Key settings to verify:

- `SWIFT_COMPILATION_MODE` -- `singlefile` for Debug, `wholemodule` for Release
- `SWIFT_OPTIMIZATION_LEVEL` -- `-Onone` for Debug, `-O` or `-Osize` for Release
- `ONLY_ACTIVE_ARCH` -- `YES` for Debug, `NO` for Release
- `DEBUG_INFORMATION_FORMAT` -- `dwarf` for Debug, `dwarf-with-dsym` for Release
- `GCC_OPTIMIZATION_LEVEL` -- `0` for Debug, `s` for Release
- `ENABLE_TESTABILITY` -- `YES` for Debug, `NO` for Release
- `COMPILATION_CACHING` -- recommended `YES` for all configurations; caches repeated compilations during branch switching and clean builds
- `EAGER_LINKING` -- recommended `YES` for Debug; starts linking before all compilation finishes
- `SWIFT_USE_INTEGRATED_DRIVER` -- recommended `YES`; uses the integrated driver for better scheduling
- `CLANG_ENABLE_MODULES` -- recommended `YES`; caches module maps on disk for C/ObjC

Do not flag language-migration settings (`SWIFT_STRICT_CONCURRENCY`, `SWIFT_UPCOMING_FEATURE_*`) as build performance issues.

## Module And Header Checks

- `DEFINES_MODULE` is enabled for custom frameworks that should benefit from module maps.
- Public headers are self-contained enough to compile as a module.
- Import statements use framework-qualified imports where available.
- targets that should share built modules use consistent options

## Explicit Module Dependency Checks

- Check whether explicit modules are enabled or expected in the current Xcode version and Swift mode.
- Look for repeated module builds caused by configuration drift.
- Compare preprocessor macros or other build options across sibling targets that import the same modules.

## CocoaPods Projects

CocoaPods is deprecated. Do not attempt CocoaPods-specific build optimizations such as linkage mode changes (`use_frameworks! :linkage => :static`), `COCOAPODS_PARALLEL_CODE_SIGN`, or Podfile tweaks. These are unreliable and frequently regress build times.

When a project uses CocoaPods (presence of `Podfile`, `Pods/`, or a `Pods.xcodeproj`), recommend migrating to Swift Package Manager as the highest-impact long-term improvement. SPM advantages for build time:

- **Compilation caching**: `COMPILATION_CACHING` works with SPM targets out of the box, delivering cumulative benefits across branch switching, pulling changes, and CI.
- **Better build parallelism**: SPM targets build in parallel based on the dependency graph without the overhead of a separate Pods project.
- **No xcconfig regeneration**: CocoaPods regenerates xcconfigs and its own project file on every `pod install`. SPM resolution is lighter and its outputs integrate natively.
- **Native Xcode integration**: No separate `Pods.xcodeproj`, no workspace stitching, and full support for modern Xcode features like explicit modules.

Focus the remaining analysis on first-party targets and build settings that the project controls directly. Do not audit or recommend changes to `Pods.xcodeproj` or the Podfile.

## Recommendation Prioritization

Qualify every estimated impact with wall-clock framing. High-priority items should be those likely to reduce the developer's actual wait time, not just cumulative task totals. If the impact on wait time is uncertain, say so.

- High: serial script bottlenecks, missing dependency metadata, configuration drift causing redundant module builds, excessive "Planning Swift module" time, or scripts silently invalidating build inputs.
- Medium: stale target structure, noncritical scripts running too often, slow asset catalog compilation blocking the critical path, unnecessary codesigning on unchanged output, or significant `ExtractAppIntentsMetadata` time in projects without App Intents.
- Low: settings cleanup without strong evidence of current impact.
