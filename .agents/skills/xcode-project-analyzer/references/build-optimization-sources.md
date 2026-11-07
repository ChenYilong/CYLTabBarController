# Build Optimization Sources

This file stores the external sources that the README and skill docs should cite consistently.

## Apple: Improving the speed of incremental builds

Source:

- <https://developer.apple.com/documentation/xcode/improving-the-speed-of-incremental-builds>

Key takeaways:

- Measure first with `Build With Timing Summary` or `xcodebuild -showBuildTimingSummary`.
- Accurate target dependencies improve correctness and parallelism.
- Run scripts should declare inputs and outputs so Xcode can skip unnecessary work.
- `.xcfilelist` files are appropriate when scripts have many inputs or outputs.
- Custom frameworks and libraries benefit from module maps, typically by enabling `DEFINES_MODULE`.
- Module reuse is strongest when related sources compile with consistent options.
- Breaking monolithic targets into better-scoped modules can reduce unnecessary rebuilds.

## Apple: Improving build efficiency with good coding practices

Source:

- <https://developer.apple.com/documentation/xcode/improving-build-efficiency-with-good-coding-practices>

Key takeaways:

- Use framework-qualified imports when module maps are available.
- Keep Objective-C bridging surfaces narrow.
- Prefer explicit type information when inference becomes expensive.
- Use explicit delegate protocols instead of overly generic delegate types.
- Simplify complex expressions that are hard for the compiler to type-check.

## Apple: Building your project with explicit module dependencies

Source:

- <https://developer.apple.com/documentation/xcode/building-your-project-with-explicit-module-dependencies>

Key takeaways:

- Explicit module builds make module work visible in the build log and improve scheduling.
- Repeated builds of the same module often point to avoidable module variants.
- Inconsistent build options across targets can force duplicate module builds.
- Timing summaries can reveal option drift that prevents module reuse.

## SwiftLee: Build performance analysis for speeding up Xcode builds

Source:

- <https://www.avanderlee.com/optimization/analysing-build-performance-xcode/>

Key takeaways:

- Clean and incremental builds should both be measured because they reveal different problems.
- Build Timeline and Build Timing Summary are practical starting points for build optimization.
- Build scripts often produce large incremental-build wins when guarded correctly.
- `-warn-long-function-bodies` and `-warn-long-expression-type-checking` help surface compile hotspots.
- Typical debug and release build setting mismatches are worth auditing, especially in older projects.

## Apple: Xcode Release Notes -- Compilation Caching

Source:

- Xcode Release Notes (149700201)

Key takeaways:

- Compilation caching is an opt-in feature for Swift and C-family languages.
- It caches prior compilation results and reuses them when the same source inputs are recompiled.
- Branch switching and clean builds benefit the most.
- Can be enabled via the "Enable Compilation Caching" build setting or per-user project settings.

## Apple: Demystify explicitly built modules (WWDC24)

Source:

- <https://developer.apple.com/videos/play/wwdc2024/10171/>

Key takeaways:

- Explains how explicitly built modules divide compilation into scan, module build, and source compile stages.
- Unrelated modules build in parallel, improving CPU utilization.
- Module variant duplication is a key bottleneck -- uniform compiler options across targets prevent it.
- The build log shows each module as a discrete task, making it easier to diagnose scheduling issues.

## Swift Compile-Time Best Practices

Well-known Swift language patterns that reduce type-checker workload during compilation:

- Mark classes `final` when they are not intended for subclassing. This eliminates dynamic dispatch overhead and allows the compiler to de-virtualize method calls.
- Restrict access control to the narrowest useful scope (`private`, `fileprivate`). Fewer visible symbols reduce the compiler's search space during type resolution.
- Prefer value types (`struct`, `enum`) over `class` when reference semantics are not needed. Value types are simpler for the compiler to reason about.
- Break long method chains (`.map().flatMap().filter()`) into intermediate `let` bindings with explicit type annotations. Even simple-looking chains can take seconds to type-check.
- Provide explicit return types on closures passed to generic functions, especially in SwiftUI result-builder contexts.
- Decompose large SwiftUI `body` properties into smaller extracted subviews. Each subview narrows the scope of the result-builder expression the type-checker must resolve.

## Bitrise: Demystifying Explicitly Built Modules for Xcode

Source:

- <https://bitrise.io/blog/post/demystifying-explicitly-built-modules-for-xcode>

Key takeaways:

- Explicit module builds give `xcodebuild` visibility into smaller compilation tasks for better parallelism.
- Enabled by default for C/Objective-C in Xcode 16+; experimental for Swift.
- Minimizing module variants by aligning build options is the primary optimization lever.
- Some projects see regressions from dependency scanning overhead -- benchmark before and after.

## Bitrise: Xcode Compilation Cache FAQ

Source:

- <https://docs.bitrise.io/en/bitrise-build-cache/build-cache-for-xcode/xcode-compilation-cache-faq.html>

Key takeaways:

- Granular caching is controlled by `SWIFT_ENABLE_COMPILE_CACHE` and `CLANG_ENABLE_COMPILE_CACHE`, under the umbrella `COMPILATION_CACHING` setting.
- Non-cacheable tasks include `CompileStoryboard`, `CompileXIB`, `CompileAssetCatalogVariant`, `PhaseScriptExecution`, `DataModelCompile`, `CopyPNGFile`, `GenerateDSYMFile`, and `Ld`.
- SPM dependencies are not yet cacheable as of Xcode 26 beta.

## RocketSim Docs: Build Insights

Sources:

- <https://www.rocketsim.app/docs/features/build-insights/build-insights/>
- <https://www.rocketsim.app/docs/features/build-insights/team-build-insights/>

Key takeaways:

- RocketSim automatically tracks clean vs incremental builds over time without build scripts.
- It reports build counts, duration trends, and percentile-based metrics such as p75 and p95.
- Team Build Insights adds machine, Xcode, and macOS comparisons for cross-team visibility.
- This repository is best positioned as the point-in-time analyze-and-improve toolkit, while RocketSim is the monitor-over-time companion.

## Swift Forums: Slow incremental builds because of planning swift module

Source:

- <https://forums.swift.org/t/slow-incremental-builds-because-of-planning-swift-module/84803>

Key takeaways:

- "Planning Swift module" can dominate incremental builds (up to 30s per module), sometimes exceeding clean build time.
- Replanning every module without scheduling compiles is a sign that build inputs are being modified unexpectedly (e.g., a misconfigured linter touching file timestamps).
- Enable **Task Backtraces** (Xcode 16.4+: Scheme Editor > Build > Build Debugging) to see why each task re-ran in an incremental build.
- Heavy Swift macro usage (e.g., TCA / swift-syntax) can cause trivial changes to cascade into near-full rebuilds.
- `swift-syntax` builds universally (all architectures) when no prebuilt binary is available, adding significant overhead.
- `SwiftEmitModule` can take 60s+ after a single-line change in large modules.
- Asset catalog compilation is single-threaded per target; splitting assets into separate bundles across targets enables parallel compilation.
- Multi-platform targets (e.g., adding watchOS) can cause SPM packages to build 3x (iOS arm64, iOS x86_64, watchOS arm64).
- Zero-change incremental builds still incur ~10s of fixed overhead: compute dependencies, send project description, create build description, script phases, codesigning, and validation.
- Codesigning and validation run even when output has not changed.
