# Agent rules for this repository (any tool)

CYLTabBarController is an iOS tab bar library (Objective-C, usable from Swift and SwiftUI) with classic, Liquid Glass, and FlatDesign styles, a raised plus button, Lottie, PAG, Rive, and GIF tab icons, and themes.

- `README.md`: usage for app developers. `docs/`: one document per feature, each bound to its classes. Start from the `cyl-api-map` skill.
- The headers under `CYLTabBarController/` are the public API.
- When code, `docs/`, and `README.md` disagree, code wins, then `docs/`. Fix the wrong one in the same change, then the skill that repeats it.

## Instruction format

Every rule has a tag. Each tag has a visible heading with its summary; the full text is in `docs/instructions/<tag>.md`, linked in the final table as `reference` (not required; do not read by default): open it only when a task touches the tag (a keyword of the tag appears in the task). Instruction files (this file, `instructions.md`, `docs/instructions.md`, `CLAUDE.md`) stay under 200 lines; what does not fit goes into the tag's file in `docs/instructions/`. Except for the final table, no other part of this file may contain links.

## Skills and documentation (tag: `skills-and-docs`)

- Use the `cyl-*` project skills for library work; third-party skills are vendored only through the manifest.
- Keep `docs/`, `README.md`, and the affected skills in sync in the same change.
- Bilingual docs and comments: read only the `[EN]` part; new text stays bilingual.
- Full rule: at reference of this tag (not required; do not read by default).

## Code rules (tag: `code-rules`)

- Fix every warning; never remove or change a public API; isolate optional components with guards.
- Follow the plus button image and stand-in rules; always build from a clean derived data folder.
- Xcode project files keep the legacy format that the Xcode 26 CI requires.
- Full rule: at reference of this tag (not required; do not read by default).

## Accessibility and internationalization (tag: `accessibility-i18n`)

- Every control and text in the library, the examples, and the cross-platform ports (HarmonyOS included) is accessible and localized.
- Automated tests find UI by accessibility identifier or label first; coordinates only as a last resort, and a missing label is reported.
- Full rule: at reference of this tag (not required; do not read by default).

## Naming and comments (tag: `naming-and-comments`)

- Use the `CYL` / `cyl_` prefixes; public API comments use each language's documentation block format.
- Comments are bilingual (`[EN]` / `[CN]`); Chinese string literals go through `CYLLocalizedString`.
- Full rule: at reference of this tag (not required; do not read by default).

## Localization structure (tag: `localization`)

- Localized strings are grouped in one bundle or package per owner; the core `CYLTabBarController.bundle` is permanent; each layer has its own macro or helper.
- iOS passes the two-layer macro acceptance check: `scripts/check-localization-macros.py`.
- Full rule: at reference of this tag (not required; do not read by default).

## Examples and demos (tag: `examples`)

- Examples import only the umbrella header, use inset grouped tables, and follow the default setup patterns.
- Demo rows go on the tabs after the first one; the first tab mirrors the Objective-C example.
- Cross-platform wrappers stay thin over `CYLTabBarHostView`.
- Full rule: at reference of this tag (not required; do not read by default).

## Dependencies and integration (tag: `dependencies`)

- External projects depend on the latest CYLTabBarController commit by timestamp; this repository and its demos use local paths.
- Every example also integrates CYLTableViewPlaceHolder at its latest commit (pull to refresh, placeholders, offline UI) and never uses MJRefresh.
- Full rule: at reference of this tag (not required; do not read by default).

## Xcode project setup (tag: `xcode-project-setup`)

- App and demo Podfiles have the required top and bottom configuration; every app has its icon and launch screen assets.
- No copied sources: reference the shared files or use `Example-Shared`.
- Full rule: at reference of this tag (not required; do not read by default).

## HarmonyOS port (tag: `harmonyos`)

- The HarmonyOS port mirrors the iOS public API and example behavior; its implementation is ported from the Android Kotlin sources.
- Before HarmonyOS work, meet the DevEco Studio, region, and emulator prerequisites and follow the accessibility, localization, and UI test rules.
- Full rule: at reference of this tag (not required; do not read by default).

## CI, testing, and screenshots (tag: `ci-testing-screenshots`)

- Confirm the CI runner in `.github/workflows/ios.yml`; report whether each check ran on GitHub CI or locally; keep the local environment comment accurate.
- Save original, labeled screenshots under `docs/assets/`, update the docs and `README.md`, and prefer one-column (vertical) stitched layouts.
- Full rule: at reference of this tag (not required; do not read by default).

## Git and pull requests (tag: `git-workflow`)

- English Commitizen-style commits with the required author line; follow the branch, pull request, and push rules.
- Never commit `._*` or `*.lock` files; check `docs/` for stale `TODO` notes before every commit.
- Record every task in the docs, follow the Swift migration and translation rules, and treat plus button lens changes as high risk.
- Full rule: at reference of this tag (not required; do not read by default).

## Commands (tag: `commands`)

- Run the standard verification and build commands before pushing or when validating a change:

```sh
pod lib lint CYLTabBarController.podspec --quick
scripts/unit-tests.sh "iPhone 17 Pro Max"
scripts/ci-build-example.sh <demo folder>
python3 scripts/update-docs-navigation.py
python3 scripts/sync-agent-skills.py --check
scripts/publish-android.sh staging        # Android library: build and check the Maven bundle (local | staging | central | github)
```

- Run scripts and multi-line shell commands with bash, not zsh: zsh does not split an unquoted variable into words. Use `bash script.sh` or `bash -c '…'`; in zsh, use arrays or `${=var}` and quote every expansion.
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

## Tag reference

| Tag | Heading | Reference (not required; do not read by default) |
|:---|:---|:---|
| `skills-and-docs` | Skills and documentation | [reference](docs/instructions/skills-and-docs.md) (not required; do not read by default) |
| `code-rules` | Code rules | [reference](docs/instructions/code-rules.md) (not required; do not read by default) |
| `accessibility-i18n` | Accessibility and internationalization | [reference](docs/instructions/accessibility-i18n.md) (not required; do not read by default) |
| `naming-and-comments` | Naming and comments | [reference](docs/instructions/naming-and-comments.md) (not required; do not read by default) |
| `localization` | Localization structure | [reference](docs/instructions/localization.md) (not required; do not read by default) |
| `examples` | Examples and demos | [reference](docs/instructions/examples.md) (not required; do not read by default) |
| `dependencies` | Dependencies and integration | [reference](docs/instructions/dependencies.md) (not required; do not read by default) |
| `xcode-project-setup` | Xcode project setup | [reference](docs/instructions/xcode-project-setup.md) (not required; do not read by default) |
| `harmonyos` | HarmonyOS port | [reference](docs/instructions/harmonyos.md) (not required; do not read by default) |
| `ci-testing-screenshots` | CI, testing, and screenshots | [reference](docs/instructions/ci-testing-screenshots.md) (not required; do not read by default) |
| `git-workflow` | Git and pull requests | [reference](docs/instructions/git-workflow.md) (not required; do not read by default) |
| `commands` | Commands | [reference](docs/instructions/commands.md) (not required; do not read by default) |
| `docs-lookup` | Finding the document a prompt refers to | [reference](docs/instructions/docs-lookup.md) (not required; do not read by default) |
| `reply-greeting` | Reply greeting | [reference](docs/instructions/reply-greeting.md) (not required; do not read by default) |
