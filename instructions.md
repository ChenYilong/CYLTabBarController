# CYLTabBarController folder instructions

## Behavioral guidelines: read in full first (tag: `behavioral`)

- **You must read [docs/instructions/behavioral.md](docs/instructions/behavioral.md) in full, every line, before any task in this repository.** It holds the
  behavioral guidelines that reduce common LLM coding mistakes (think before coding, simplicity first, surgical changes,
  goal-driven execution). It applies to every task and every tag below.

Read this file before reading or writing files in this repository. It inherits the vault's root `instructions.md`.
Organized by tag (tag: `instructions`): each heading has its tag and a summary; the full text is in
`docs/instructions/<tag>.md`, opened when a task touches the tag. This file stays under 200 lines
([docs/instructions/instructions.md](docs/instructions/instructions.md)).

## Where the rules are (tag: `instructions`)

- `AGENTS.md` (loaded through `CLAUDE.md`): the agent rules of this repository, one heading per tag. Read it first.
- `docs/instructions/<tag>.md`: the full text of each tag. `docs/instructions.md`: the rules of the documentation folder.
- `.agents/skills/cyl-*` (linked from `.claude/skills`): the project skills; `cyl-docs` for documents and screenshots,
  `cyl-verify` for builds, tests, simulators and emulators.

## Screenshots (tag: `screenshots`)

- Original pixels, labeled header / captions / footer by `scripts/stitch-screenshots.py`, checked by
  `scripts/check-screenshot-labels.py` and the pre-commit hook; one column first; 72 px above a raised plus button.
- Full text: [docs/instructions/screenshots.md](docs/instructions/screenshots.md) and `docs/Screenshot-Guidelines.md`.

## Code rules (tag: `code`)

- The iOS core is Swift; every new piece of code is Swift first (added 2026-11-19, owner); Objective-C only where Swift
  cannot do the job, with the reason. Full text: [docs/instructions/code.md](docs/instructions/code.md).

## Naming after the static analysis (tag: `code`, added 2026-11-22)

- SonarCloud flags `cyl_` Swift names (`swift:S100`, 743 of 956 issues on PR #788). Swift: `CYL` on types, no prefix on members of our types, `cylFoo` (with `@objc(cyl_foo)`) on system-type extensions, released names as deprecated shims; other languages keep the prefix only on global names. Full text: [docs/instructions/code.md](docs/instructions/code.md); skill `cyl-naming`.

## Sessions (tag: `task-workflow`)

- Session roles by name (added 2026-11-19): `Mac*` sessions take iOS, `Win*` sessions the other platforms; assign by
  message when both are active. Full text: [docs/instructions/task-workflow.md](docs/instructions/task-workflow.md).

## HarmonyOS x86_64 emulator, Rive and PAG (tag: `windows-harmonyos`)

- The local HarmonyOS emulator is x86_64; @ohos/rive and @tencent/libpag ship arm64-v8a only. `cylanimateditem` owns the
  x86_64 test path: `CYLAnimatedItemEngines` ABI check (still images on x86_64), the `emulator` build target,
  `tools/cyl_hap_x86_64.py` (`cylanimateditem/README.md`, "x86_64 emulator").
- Owner's two plans for arm64-only tests (added 2026-11-22): Plan 1, x86_64 builds of the Rive and PAG libraries from
  GitHub inside `cylanimateditem`, guarded by the device architecture, compile and no crash first, behind a debug build
  option until verified (removing it needs the owner's approval); Plan 2, if it fails, the macOS (arm64) session tests.
- Plan 1 status (2026-11-22): Rive done behind the debug guard (the debug engine kit in
  `cylanimateditem/x86_64-debug-engines/`, `CYLAnimatedItemEngines.loadX86_64DebugEngines`); PAG done the same way
  (`x86_64-debug-engines/pag`, libpag 4.4.31); the debug guard stays until the owner approves removing it.
- Full text: [docs/instructions/windows-harmonyos.md](docs/instructions/windows-harmonyos.md), "From instructions.md".

## Git (tag: `git`)

- Before any git operation (commit, push, pull, rebase, merge, branch, pull request), read
  [docs/instructions/git.md](docs/instructions/git.md) in full, then run the git command (added 2026-11-22, owner).
