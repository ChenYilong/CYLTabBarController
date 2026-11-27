# Agent rules for this repository (any tool)

## Behavioral guidelines: read in full first (tag: `behavioral`)

- **You must read the `behavioral` reference doc in full, every line, before any task in this repository.** It holds the
  behavioral guidelines that reduce common LLM coding mistakes (think before coding, simplicity first, surgical changes,
  goal-driven execution). It applies to every task and every tag below.

CYLTabBarController is a cross-platform tab bar library (iOS, Android, Flutter, React Native, WeChat Mini Program, and HarmonyOS) with classic, Liquid Glass, and FlatDesign styles, a raised plus button, Lottie, PAG, Rive, and GIF tab icons, and themes. Read these before touching code:

- `docs/`: one document per feature, each bound to its classes. Start from the `cyl-api-map` skill.
- The headers under `CYLTabBarController/` are the public API.

When code and `docs/` disagree, code wins, then `docs/`. Fix the wrong one in the same change, then the skill that repeats it.

## Instruction format

Every rule has a tag. Each tag has a visible heading with its summary; the full text is in `docs/instructions/<tag>.md`, linked in the final table as `reference` (not required; do not read by default): open it only when a task touches the tag (a keyword of the tag appears in the task). Instruction files (this file, `instructions.md`, `docs/instructions.md`, `CLAUDE.md`) stay under 200 lines; what does not fit goes into the tag's file in `docs/instructions/`. Except for the final table, no other part of this file may contain links.

## Task workflow and sessions (tag: `task-workflow`)

- Before any task: list the other sessions (`ListAgents`), avoid duplicate work, tell them the files you change; `Mac*` sessions take iOS, `Win*` sessions the other platforms.
- Start with a `TODO` list and the branch; record the task in memory with the prompt verbatim and a 100 / 60 rubric; score after each step, never stop below 60; print missing points as `TODO` at the end; `DONE` only at 100.
- A hung emulator: tell the sessions that use it, restart it, then tell all sessions it is back.
- Full rule: at reference of this tag (not required; do not read by default).

## Documentation and skills (tag: `documentation`)

- Skills live in `.agents/skills` (`.claude/skills` points there); use the `cyl-*` skills; third-party skills only through `scripts/sync-agent-skills.py`.
- Every new API, feature, limit, or demo updates its `docs/` file, `README.md`, and the `cyl-*` skills (at least a `cyl-api-map` row) in the same change.
- Docs and comments are bilingual: read the `[EN]` part, skip `[CN]`; write both. Run `python3 scripts/update-docs-navigation.py` after doc changes; never edit generated blocks.
- Full rule: at reference of this tag (not required; do not read by default).

## Code rules (tag: `code`)

- Swift first for the iOS core; Objective-C only where Swift cannot, with the reason.
- Fix bugs in the core, never only in the example: record the bug, screenshot it, fix the component (`docs/Example-Layer-Fixes.md` only with the owner's approval).
- Never remove or change a public API; no warnings; `CYL` / `cyl_` prefixes; one documentation block format for public API comments; bilingual `[EN]` / `[CN]` comments.
- Every published package ships the root `LICENSE` (`scripts/check-license-notices.py`). Swift migration of the core layer: `docs/Swift-Migration.md`.
- Full rule: at reference of this tag (not required; do not read by default).

## Accessibility and localization (tag: `accessibility-localization`)

- Accessibility is required in every library, component, and example (labels, roles, states; decorations hidden); UI tests find controls by label or id first.
- No Chinese string literals in code: `CYLLocalizedString(@"…")`. Localized texts: one bundle per owner, the permanent core bundle, an example bundle, and one macro per layer (`scripts/check-localization-macros.py`).
- Full rule: at reference of this tag (not required; do not read by default).

## Animated items and optional components (tag: `animation`)

- `CYLAnimatedItemView` (iOS pod `CYLAnimatedItem`, Android `:cylanimateditem`, HarmonyOS `cylanimateditem`) never depends on CYLTabBarController.
- Optional engines are isolated with guards (`CYL_LOTTIE_AVAILABLE`, `CYL_PAG_AVAILABLE`, …, in `CYLAnimatedItemMacros.h`); every key exists, without its engine it warns and shows the still image. FlatDesign code behind `CYL_FLATDESIGN_AVAILABLE`.
- Full rule: at reference of this tag (not required; do not read by default).

## Plus button (tag: `plus-button`)

- Read `docs/PlusButton.md` before changing plus button images, its stand-in, or theming (Liquid Glass stand-in shows only the normal image).
- `-[CYLPlusButton cyl_updateLiquidGlassMask]` and the title-keeps-lens switch are known sources of plus button bugs: turn them off first on any plus button bug.
- Full rule: at reference of this tag (not required; do not read by default).

## Badge debugging (tag: `badges`)

- While checking badge positions, build with `CYL_BADGE_ANIMATION_DISABLED` on (each platform's switch); every such control defaults to NO and is never committed on. Details: `docs/Badge-Debugging.md`.
- Full rule: at reference of this tag (not required; do not read by default).

## Examples and demos (tag: `examples`)

- Examples import only `CYLTabBarController`; tables use the inset grouped style; demo rows never on the first tab, spread over the others; the first tab mirrors the Objective-C example.
- The demo adds the first tab's cover itself, later; animated icon pages offer Play all, speed, and loop; default setup: plus button with its own page, a local configuration file, a raised plus button. New demos follow `cyl-new-project`.
- Full rule: at reference of this tag (not required; do not read by default).

## React Native and Flutter (tag: `cross-platform`)

- React Native and Flutter components are thin wrappers around `CYLTabBarHostView` (iOS and Android); shared behavior goes into the host view, configuration keys into both native libraries.
- Full rule: at reference of this tag (not required; do not read by default).

## Dependencies and upstream ports (tag: `dependencies`)

- Projects named otherwise depend on the latest CYLTabBarController commit on any branch (`scripts/latest-cyl-commit.sh`), this repository by a relative path; every example also pins CYLTableViewPlaceHolder's latest commit (pull to refresh, placeholders, no MJRefresh).
- Upstream projects used for a port: bring in their open pull requests and list their open issues with a score.
- Full rule: at reference of this tag (not required; do not read by default).

## macOS only: Xcode, simulator, local builds (tag: `macos`)

- Xcode projects keep the Objective-C example's format (`objectVersion = 46`); Podfile top lines and `post_install` hook; app icon and launch screen from the ObjC example; no copied sources.
- Clean before every build (new derived data folder); run `scripts/free-ram.sh` before the simulator; details in `cyl-verify` and `cyl-xcode-compat`.
- Full rule: at reference of this tag (not required; do not read by default).

## Windows and HarmonyOS (tag: `windows-harmonyos`)

- The HarmonyOS component (`CrossPlatform/harmonyos-cyltabbar/cyltabbar`) and its example (`entry`) always stay in the repository and buildable; build from an ASCII path (for example `C:\cyl-hm`).
- DevEco Studio: Hyper-V features and a Windows restart, region CN, Huawei sign-in; the emulator installs unsigned HAPs. Accessibility, localization (`scripts/harmonyos-l10n.py`), and UI tests by label: `cyl-harmonyos-a11y-l10n`.
- The local emulator is x86_64: Rive and PAG are arm64-only (see `instructions.md`, "windows-harmonyos").
- Full rule: at reference of this tag (not required; do not read by default).

## Testing, CI and commands (tag: `testing`)

- Verify before pushing (`pod lib lint … --quick` plus a build or static check) and say what could not be verified.
- iOS CI runs on macOS 26 (read `.github/workflows/ios.yml`); local runs use macOS 27 / Xcode 27 and keep the environment comment current (`scripts/local-run-environment.sh`). Run scripts with bash, not zsh. Commands list in the full text.
- Full rule: at reference of this tag (not required; do not read by default).

## Screenshots (tag: `screenshots`)

- Every screenshot is committed under `docs/assets/` with its document, original pixels, labeled header / captions / footer by `scripts/stitch-screenshots.py`, checked by `scripts/check-screenshot-labels.py`; one column first; 72 px above a raised plus button. Full rules: `docs/Screenshot-Guidelines.md`.
- Full rule: at reference of this tag (not required; do not read by default).

## Git, commits and pull requests (tag: `git`)

- **Before any git operation, read the `git` reference doc in full, then run the git command.**
- `touch .git/hooks/NO_AUTO_SYNC` before every commit; Commitizen style (`feat: ✨`, `fix: 🐛`, `docs: 📝` …), English only, the author line `By  @ChenYilong <luohanchenyilong@163.com>` in the body.
- On a branch other than `master` / `main`: commit and push at the end of every turn without asking; every branch with commits has an open pull request (ask when more than two are open); push over SSH first.
- Never commit `._*` or `*.lock` files; check `docs/` for stale `TODO` / `Linux` notes before every commit.
- Full rule: at reference of this tag (not required; do not read by default).

## Finding the document a prompt refers to (tag: `docs-lookup`)

- When a prompt mentions a related document without naming it, find it in memory and the conversation context first: prefer the file mentioned most often and most recently.
- If it is still unclear which document is meant, create a new document instead of searching for one.
- Never scan the contents of every file under `docs/`, and never read a document under `docs/` in full unless the owner explicitly names that document and asks for a full read, or authorizes it.
- Full rule: at reference of this tag (not required; do not read by default).

## Reply greeting (tag: `reply-greeting`)

- Start every reply with `Hi, <OS>/<folder>:`, then answer. `<OS>` is the session's operating system; `<folder>` is the name of the session's working folder.
- Example: a macOS session in `/Volumes/obsidian/chenyilong/chenyilong/CYLTabBarController` starts with `Hi, macOS/CYLTabBarController:`.
- Full rule: at reference of this tag (not required; do not read by default).

## How this file is organized (tag: `instructions`)

- This file is the compact index. Each tag heading gives the summary; the final table gives the `reference` link for full details.
- Do not read reference docs by default; open a reference only when the task touches that tag.
- Full rule: at reference of this tag (not required; do not read by default).

## Tag reference

| Tag | Heading | Reference (not required; do not read by default) |
|:---|:---|:---|
| `behavioral` | Behavioral guidelines: read in full first | [reference](docs/instructions/behavioral.md) (not required; do not read by default) |
| `task-workflow` | Task workflow and sessions | [reference](docs/instructions/task-workflow.md) (not required; do not read by default) |
| `documentation` | Documentation and skills | [reference](docs/instructions/documentation.md) (not required; do not read by default) |
| `code` | Code rules | [reference](docs/instructions/code.md) (not required; do not read by default) |
| `accessibility-localization` | Accessibility and localization | [reference](docs/instructions/accessibility-localization.md) (not required; do not read by default) |
| `animation` | Animated items and optional components | [reference](docs/instructions/animation.md) (not required; do not read by default) |
| `plus-button` | Plus button | [reference](docs/instructions/plus-button.md) (not required; do not read by default) |
| `badges` | Badge debugging | [reference](docs/instructions/badges.md) (not required; do not read by default) |
| `examples` | Examples and demos | [reference](docs/instructions/examples.md) (not required; do not read by default) |
| `cross-platform` | React Native and Flutter | [reference](docs/instructions/cross-platform.md) (not required; do not read by default) |
| `dependencies` | Dependencies and upstream ports | [reference](docs/instructions/dependencies.md) (not required; do not read by default) |
| `macos` | macOS only: Xcode, simulator, local builds | [reference](docs/instructions/macos.md) (not required; do not read by default) |
| `windows-harmonyos` | Windows and HarmonyOS | [reference](docs/instructions/windows-harmonyos.md) (not required; do not read by default) |
| `testing` | Testing, CI and commands | [reference](docs/instructions/testing.md) (not required; do not read by default) |
| `screenshots` | Screenshots | [reference](docs/instructions/screenshots.md) (not required; do not read by default) |
| `git` | Git, commits and pull requests | [reference](docs/instructions/git.md) (not required; do not read by default) |
| `docs-lookup` | Finding the document a prompt refers to | [reference](docs/instructions/docs-lookup.md) (not required; do not read by default) |
| `reply-greeting` | Reply greeting | [reference](docs/instructions/reply-greeting.md) (not required; do not read by default) |
| `instructions` | How this file is organized | [reference](docs/instructions/instructions.md) (not required; do not read by default) |
