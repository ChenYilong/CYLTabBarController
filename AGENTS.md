# Agent rules for this repository (any tool)

## Behavioral guidelines: read in full first (tag: `behavioral`)

- **You must read [docs/instructions/behavioral.md](docs/instructions/behavioral.md) in full, every line, before any task in this repository.** It holds the
  behavioral guidelines that reduce common LLM coding mistakes (think before coding, simplicity first, surgical changes,
  goal-driven execution). It applies to every task and every tag below.

CYLTabBarController is an iOS tab bar library (Objective-C, usable from Swift and SwiftUI) with classic, Liquid Glass and FlatDesign styles, a raised plus button, Lottie, PAG, Rive and GIF tab icons, and themes. Read these before touching code:

- `README.md`: usage for app developers. `docs/`: one document per feature, each bound to its classes. Start from the `cyl-api-map` skill.
- The headers under `CYLTabBarController/` are the public API.

When code, `docs/` and `README.md` disagree, code wins, then `docs/`. Fix the wrong one in the same change, then the skill that repeats it.

## How this file is organized (tag: `instructions`)

Every rule has a tag. Each tag below has a visible heading with its summary; the full text is in
`docs/instructions/<tag>.md`, linked under the heading: open it when a task touches the tag (a keyword of the tag
appears in the task). Instruction files (this file, `instructions.md`, `docs/instructions.md`, `CLAUDE.md`) stay under
200 lines; what does not fit goes into the tag's file in `docs/instructions/`. Full rule: [docs/instructions/instructions.md](docs/instructions/instructions.md).

| Tag | Heading | Full text |
|:---|:---|:---|
| `behavioral` | [Behavioral guidelines: read in full first](#behavioral-guidelines-read-in-full-first-tag-behavioral) | [docs/instructions/behavioral.md](docs/instructions/behavioral.md) (read in full) |
| `task-workflow` | [Task workflow and sessions](#task-workflow-and-sessions-tag-task-workflow) | [docs/instructions/task-workflow.md](docs/instructions/task-workflow.md) |
| `documentation` | [Documentation and skills](#documentation-and-skills-tag-documentation) | [docs/instructions/documentation.md](docs/instructions/documentation.md) |
| `code` | [Code rules](#code-rules-tag-code) | [docs/instructions/code.md](docs/instructions/code.md) |
| `accessibility-localization` | [Accessibility and localization](#accessibility-and-localization-tag-accessibility-localization) | [docs/instructions/accessibility-localization.md](docs/instructions/accessibility-localization.md) |
| `animation` | [Animated items and optional components](#animated-items-and-optional-components-tag-animation) | [docs/instructions/animation.md](docs/instructions/animation.md) |
| `plus-button` | [Plus button](#plus-button-tag-plus-button) | [docs/instructions/plus-button.md](docs/instructions/plus-button.md) |
| `badges` | [Badge debugging](#badge-debugging-tag-badges) | [docs/instructions/badges.md](docs/instructions/badges.md) |
| `examples` | [Examples and demos](#examples-and-demos-tag-examples) | [docs/instructions/examples.md](docs/instructions/examples.md) |
| `cross-platform` | [React Native and Flutter](#react-native-and-flutter-tag-cross-platform) | [docs/instructions/cross-platform.md](docs/instructions/cross-platform.md) |
| `dependencies` | [Dependencies and upstream ports](#dependencies-and-upstream-ports-tag-dependencies) | [docs/instructions/dependencies.md](docs/instructions/dependencies.md) |
| `macos` | [macOS only: Xcode, simulator, local builds](#macos-only-xcode-simulator-local-builds-tag-macos) | [docs/instructions/macos.md](docs/instructions/macos.md) |
| `windows-harmonyos` | [Windows and HarmonyOS](#windows-and-harmonyos-tag-windows-harmonyos) | [docs/instructions/windows-harmonyos.md](docs/instructions/windows-harmonyos.md) |
| `testing` | [Testing, CI and commands](#testing-ci-and-commands-tag-testing) | [docs/instructions/testing.md](docs/instructions/testing.md) |
| `screenshots` | [Screenshots](#screenshots-tag-screenshots) | [docs/instructions/screenshots.md](docs/instructions/screenshots.md) |
| `git` | [Git, commits and pull requests](#git-commits-and-pull-requests-tag-git) | [docs/instructions/git.md](docs/instructions/git.md) |
| `instructions` | [How this file is organized](#how-this-file-is-organized-tag-instructions) | [docs/instructions/instructions.md](docs/instructions/instructions.md) |

## Task workflow and sessions (tag: `task-workflow`)

- Before any task: list the other sessions (`ListAgents`), avoid duplicate work, tell them the files you change; `Mac*` sessions take iOS, `Win*` sessions the other platforms.
- Start with a `TODO` list and the branch; record the task in the most relevant `docs/` file with the prompt verbatim and a 100 / 60 rubric; score after each step, never stop below 60; print missing points as `TODO` at the end; `DONE` only at 100.
- A hung emulator: tell the sessions that use it, restart it, then tell all sessions it is back.
- Full text: [docs/instructions/task-workflow.md](docs/instructions/task-workflow.md).

## Documentation and skills (tag: `documentation`)

- Skills live in `.agents/skills` (`.claude/skills` points there); use the `cyl-*` skills; third-party skills only through `scripts/sync-agent-skills.py`.
- Every new API, feature, limit or demo updates its `docs/` file, `README.md` and the `cyl-*` skills (at least a `cyl-api-map` row) in the same change.
- Docs and comments are bilingual: read the `[EN]` part, skip `[CN]`; write both. Run `python3 scripts/update-docs-navigation.py` after doc changes; never edit generated blocks.
- Full text: [docs/instructions/documentation.md](docs/instructions/documentation.md).

## Code rules (tag: `code`)

- Swift first for the iOS core; Objective-C only where Swift cannot, with the reason.
- Fix bugs in the core, never only in the example: record the bug, screenshot it, fix the component (`docs/Example-Layer-Fixes.md` only with the owner's approval).
- Never remove or change a public API; no warnings; `CYL` / `cyl_` prefixes; one documentation block format for public API comments; bilingual `[EN]` / `[CN]` comments.
- Every published package ships the root `LICENSE` (`scripts/check-license-notices.py`). Swift migration of the core layer: `docs/Swift-Migration.md`.
- Naming after SonarCloud (added 2026-11-22): in Swift, `CYL` on types, no prefix on members of our types, `cylFoo` (+ `@objc(cyl_foo)`) on system-type extensions; Objective-C selectors keep `cyl_`. Skill `cyl-naming`.
- Swift protocols hold requirements only (no bodies, no stored properties); a new member of a released `@objc` protocol is `@objc optional`; insertion anchors are unique and include the declaration keyword; run `python3 scripts/check-swift-protocol-bodies.py CYLTabBarController` before pushing Swift written without a compiler.
- Full text: [docs/instructions/code.md](docs/instructions/code.md).

## Accessibility and localization (tag: `accessibility-localization`)

- Accessibility is required in every library, component and example (labels, roles, states; decorations hidden); UI tests find controls by label or id first.
- No Chinese string literals in code: `CYLLocalizedString(@"…")`. Localized texts: one bundle per owner, the permanent core bundle, an example bundle and one macro per layer (`scripts/check-localization-macros.py`).
- Full text: [docs/instructions/accessibility-localization.md](docs/instructions/accessibility-localization.md).

## Animated items and optional components (tag: `animation`)

- `CYLAnimatedItemView` (iOS pod `CYLAnimatedItem`, Android `:cylanimateditem`, HarmonyOS `cylanimateditem`) never depends on CYLTabBarController.
- Optional engines are isolated with guards (`CYL_LOTTIE_AVAILABLE`, `CYL_PAG_AVAILABLE`, …, in `CYLAnimatedItemMacros.h`); every key exists, without its engine it warns and shows the still image. FlatDesign code behind `CYL_FLATDESIGN_AVAILABLE`.
- Full text: [docs/instructions/animation.md](docs/instructions/animation.md).

## Plus button (tag: `plus-button`)

- Read `docs/PlusButton.md` before changing plus button images, its stand-in or theming (Liquid Glass stand-in shows only the normal image).
- `-[CYLPlusButton cyl_updateLiquidGlassMask]` and the title-keeps-lens switch are known sources of plus button bugs: turn them off first on any plus button bug.
- Full text: [docs/instructions/plus-button.md](docs/instructions/plus-button.md).

## Badge debugging (tag: `badges`)

- While checking badge positions, build with `CYL_BADGE_ANIMATION_DISABLED` on (each platform's switch); every such control defaults to NO and is never committed on. Details: `docs/Badge-Debugging.md`.
- Full text: [docs/instructions/badges.md](docs/instructions/badges.md).

## Examples and demos (tag: `examples`)

- Examples import only `CYLTabBarController`; tables use the inset grouped style; demo rows never on the first tab, spread over the others; the first tab mirrors the Objective-C example.
- The demo adds the first tab's cover itself, later; animated icon pages offer Play all, speed and loop; default setup: plus button with its own page, a local configuration file, a raised plus button. New demos follow `cyl-new-project`.
- Full text: [docs/instructions/examples.md](docs/instructions/examples.md).

## React Native and Flutter (tag: `cross-platform`)

- React Native and Flutter components are thin wrappers around `CYLTabBarHostView` (iOS and Android); shared behavior goes into the host view, configuration keys into both native libraries.
- Full text: [docs/instructions/cross-platform.md](docs/instructions/cross-platform.md).

## Dependencies and upstream ports (tag: `dependencies`)

- Projects named otherwise depend on the latest CYLTabBarController commit on any branch (`scripts/latest-cyl-commit.sh`), this repository by a relative path; every example also pins CYLTableViewPlaceHolder's latest commit (pull to refresh, placeholders, no MJRefresh).
- Upstream projects used for a port: bring in their open pull requests and list their open issues with a score.
- Full text: [docs/instructions/dependencies.md](docs/instructions/dependencies.md).

## macOS only: Xcode, simulator, local builds (tag: `macos`)

- Xcode projects keep the Objective-C example's format (`objectVersion = 46`); Podfile top lines and `post_install` hook; app icon and launch screen from the ObjC example; no copied sources.
- Clean before every build (new derived data folder); run `scripts/free-ram.sh` before the simulator; details in `cyl-verify` and `cyl-xcode-compat`.
- Full text: [docs/instructions/macos.md](docs/instructions/macos.md).

## Windows and HarmonyOS (tag: `windows-harmonyos`)

- The HarmonyOS component (`CrossPlatform/harmonyos-cyltabbar/cyltabbar`) and its example (`entry`) always stay in the repository and buildable; build from an ASCII path (e.g. `C:\cyl-hm`).
- DevEco Studio: Hyper-V features and a Windows restart, region CN, Huawei sign-in; the emulator installs unsigned HAPs. Accessibility, localization (`scripts/harmonyos-l10n.py`) and UI tests by label: `cyl-harmonyos-a11y-l10n`.
- The local emulator is x86_64: Rive and PAG are arm64-only (see `instructions.md`, "windows-harmonyos").
- Full text: [docs/instructions/windows-harmonyos.md](docs/instructions/windows-harmonyos.md).

## Testing, CI and commands (tag: `testing`)

- Verify before pushing (`pod lib lint … --quick` plus a build or static check) and say what could not be verified.
- iOS CI runs on macOS 26 (read `.github/workflows/ios.yml`); local runs use macOS 27 / Xcode 27 and keep the environment comment current (`scripts/local-run-environment.sh`). Run scripts with bash, not zsh. Commands list in the full text.
- Full text: [docs/instructions/testing.md](docs/instructions/testing.md).

## Screenshots (tag: `screenshots`)

- Every screenshot is committed under `docs/assets/` with its document, original pixels, labeled header / captions / footer by `scripts/stitch-screenshots.py`, checked by `scripts/check-screenshot-labels.py`; one column first; 72 px above a raised plus button. Full rules: `docs/Screenshot-Guidelines.md`.
- Full text: [docs/instructions/screenshots.md](docs/instructions/screenshots.md).

## Git, commits and pull requests (tag: `git`)

- **Before any git operation, read [docs/instructions/git.md](docs/instructions/git.md) in full**, then run the git command.
- `touch .git/hooks/NO_AUTO_SYNC` before every commit; Commitizen style (`feat: ✨`, `fix: 🐛`, `docs: 📝` …), English only, the author line `By  @ChenYilong <luohanchenyilong@163.com>` in the body.
- On a branch other than `master` / `main`: commit and push at the end of every turn without asking; every branch with commits has an open pull request (ask when more than two are open); push over SSH first.
- Never commit `._*` or `*.lock` files; check `docs/` for stale `TODO` / `Linux` notes before every commit.
- Full text: [docs/instructions/git.md](docs/instructions/git.md).
