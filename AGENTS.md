# Agent rules for this repository (any tool)

CYLTabBarController is an iOS tab bar library (Objective-C, usable from Swift and SwiftUI) with classic, Liquid Glass and FlatDesign styles, a raised plus button, Lottie, PAG, Rive and GIF tab icons, and themes. Read these before touching code:

- `README.md`: usage for app developers. `docs/`: one document per feature, each bound to its classes. Start from the `cyl-api-map` skill.
- The headers under `CYLTabBarController/` are the public API.

When code, `docs/` and `README.md` disagree, code wins, then `docs/`. Fix the wrong one in the same change, then the skill that repeats it.

## Skills

`.agents/skills` holds the skills; `.claude/skills` only points there.

- **Project skills, `cyl-*`, maintained here. Use them:**

| Skill | Use it when |
|:---|:---|
| `cyl-new-project` | Creating a new app or demo on this library. **Every new demo must follow it** |
| `cyl-plus-button` | Writing or changing a plus button: title alignment, stand-in, images, limits |
| `cyl-xcode-compat` | Touching a `.xcodeproj` or a deployment target; which Xcode or iOS a feature needs |
| `cyl-tab-animation` | Lottie, PAG, Rive or GIF tab icons; suggest running the matching demo first |
| `cyl-theme` | Skins, in-place tab updates |
| `cyl-api-map` | Finding the API and document for a feature |
| `cyl-docs` | Adding a feature, editing `README.md` or `docs/` |
| `cyl-verify` | Building, testing, running the simulator, reading common failures |

- **Third-party skills** are listed in `.agents/skills.json`, pinned in `.agents/skills.lock.json`, and vendored by `python3 scripts/sync-agent-skills.py`. Do not edit them by hand: change the manifest and sync. See [docs/Agent-Skills.md](docs/Agent-Skills.md) for what is there and why. Their advice is generic: where one conflicts with a rule here, this file and the `cyl-*` skills win. For example, they target modern Swift, while this library is Objective-C with a Swift 5 API.

## Keep the skills current

Every new API, feature, limit or demo updates, in the same change: the `docs/` file, `README.md`, and the `cyl-*` skills it affects (at least a row in `cyl-api-map`). The goal: someone can start a new project from these skills alone. `scripts/sync-agent-skills.py --check` fails when a document or a demo is missing from them. A change to animated tab icons also updates [docs/Tab-Icon-Animation-Quick-Start.md](docs/Tab-Icon-Animation-Quick-Start.md).

## Reading the bilingual docs and comments

The documents in `docs/` and the code comments are bilingual. AI agents read only the English part and skip the Chinese part:

- **Keywords**: `[EN]` starts the English part, `[CN]` the Chinese part. Always read what starts with `[EN]`; skip what starts
  with `[CN]`.
- **`docs/`**: read the `## [EN]…` heading and skip its `## [CN]…` twin. In a table with `中文 | English` columns, read only the
  right column. In a heading or a cell written as `中文 / English`, read only the part after the `/`.
- **Code comments**: read the `[EN]` block and skip the `[CN]` block, which runs until the next `[EN]`, the next tag or the end of the
  comment.
- **Exception**: text with no English version (e.g. an older comment in Chinese only) is read as is, since it is the only source.
- **Writing is not affected**: new text is still written in both languages, as the `cyl-docs` skill and the code rules require.

## Documentation

Every new feature and user-visible change ships with bilingual documentation in `docs/` and `README.md`, as two-column tables, and `python3 scripts/update-docs-navigation.py` is run after any change to them. Never edit generated blocks by hand. Full rules: the `cyl-docs` skill.

## Code rules

- **No warnings**: fix every build and static-analyzer warning you meet, including old ones in code you did not change.
- **Public API**: never remove or change an existing public API; add new API instead. Prefer implementing an existing
  protocol method over adding a new category method; file-private C functions and private headers are fine.
- **Swift-friendly names for underscored protocol methods**: Swift method names must not contain underscores, but a
  Swift class that implements an Objective-C protocol method must use its imported name (e.g. `cyl_play…`); renaming it
  no longer satisfies the protocol. Adding `NS_SWIFT_NAME` to the existing method would change a Swift API already
  released on `master`, which the Public API rule forbids. Instead, add a new method with the same name minus the
  underscore, keeping the `cyl` prefix (e.g. `-cyl_playSelectAnimationWithTabButton:…` →
  `-cylPlaySelectAnimationWithTabButton:…`), and define its Swift name with `NS_SWIFT_NAME` on the new method only.
  Both spellings run the same logic: the library calls the underscore-free one when it is implemented, otherwise the
  underscored one. If the old method was `@required`, make it `@optional` so a class can implement only the new one.
- **PlusButton images**: read [docs/PlusButton.md](docs/PlusButton.md) before changing the plus button's images, its stand-in or
  its theming. With a plus child view controller on Liquid Glass (not FlatDesign), the stand-in ignores selected images and shows
  only the real plus button's normal image. Selected images stay available to apps and themes for FlatDesign and the classic
  tab bar, so keep this in the plus button's internals, behind a Liquid Glass guard.
  When the app asks for the title to be aligned (`+alignsTitleWithTabBarItemTitles`), the stand-in and the real plus button line
  up by icon only: take the icon's coordinates and ignore the other subviews.
- **Optional components are isolated with guards**:
  - FlatDesign code in Core: `#if CYL_FLATDESIGN_AVAILABLE` (defined once in `CYLUtils/CYLUtilsMacros.h`), and run only
    for `CYLTabBarStyleTypeFlatDesign`, so Liquid Glass and the classic style are never affected.
  - Lottie: separate `__has_include` guards; check keys first; call through `respondsToSelector:` and
    `cyl_performSelector`.
  - An animation library's own keys exist only with that library: its header defines `CYL_<LIBRARY>_AVAILABLE`
    (`__has_include` of the library), and the header's content and the `.m` definitions sit inside it (`CYL_PAG_AVAILABLE`,
    `CYL_RIVE_AVAILABLE`). Core and CYLUtils get no library switch. The released Lottie keys stay defined and are marked
    `CYL_LOTTIE_REQUIRED` (a compile warning without Lottie). See docs/Tab-Bar-Item-Animation.md.
- **Comments are bilingual**: write `[EN]` / `[CN]` blocks; mark fixes with `FIX: issue #N`. A comment written in
  Chinese is tagged `[CN]` and is followed directly by its English translation tagged `[EN]`, in the same comment style
  (`//`, `///`, or inside the same block comment; for a trailing comment, on the next line). Comments that only
  contain a person's name, and commented-out code, need no translation.
- **No Chinese text in code**: every string literal that contains Chinese, including log, assert and debug messages,
  goes through `CYLLocalizedString(@"<original Chinese text>")` (Swift: `CYLLocalizedString("...")`), with
  `[NSString stringWithFormat:]` / `String(format:)` for values. `CYLLocalizedString()` is declared with
  `NS_FORMAT_ARGUMENT(1)`, so keep placeholders and arguments in step. The only exceptions are resource identifiers
  (e.g. an image asset name) and constants that are documented as localization keys; never touch Xcode project
  files, plists or storyboards for this.
- **Localization tables**: every key is added to **all** `.lproj` folders in
  `CYLTabBarController/Resources/CYLTabBarController.bundle/`, keeping the same `%@` / `%1$@` specifiers; every
  table has the same keys.
- **Examples**: they import only `#import <CYLTabBarController/CYLTabBarController.h>` (Swift: `import CYLTabBarController`),
  and their Podfiles must not need changes.
- **Verify** before pushing: `pod lib lint CYLTabBarController.podspec --quick`, plus a build or static check of the
  changed code. Say plainly what could not be verified.

- **React Native and Flutter components** live in `CrossPlatform/` ([docs/Cross-Platform-Components.md](docs/Cross-Platform-Components.md)),
  thin wrappers around `CYLTabBarHostView` (iOS and Android): put shared behavior in the host view, not in a wrapper.
  Their examples use this repository's iOS pod and Android sources: a library change that affects configuration
  initialization, the plus button or badges is checked in them too. A configuration key they need goes into both
  libraries (iOS and `Example-Android`), never only into a wrapper.
- **New demos** follow the `cyl-new-project` skill. **PlusButton with forced title alignment**: give it a title; see `cyl-plus-button`.
- **Xcode project files** keep the ObjC example's format (`objectVersion = 46`, `compatibilityVersion = "Xcode 3.2"`, no folder sync, deployment target below 27), or CI on Xcode 26 fails. Check before committing any `.xcodeproj` change. Full rules: the `cyl-xcode-compat` skill.
- **Simulator**: run `scripts/free-ram.sh` before every simulator use. Details and common failures: the `cyl-verify` skill.

## Git and pull requests

- **Never commit `._*` files.** macOS writes these AppleDouble metadata files next to every file on an external volume
  (e.g. `._.claude`, `._.git`, `._.github`, `._.gitignore`, `._.pullapprove.yml`, `._ChatKit`). `.gitignore` excludes
  `._*`. Before git commands, delete them, including the ones in `.git/objects` (`._pack-*.idx` makes git report
  `non-monotonic index`):

  ```sh
  find . -name '._*' -not -path './.git/*' -delete
  find .git/objects -type f -name '._*' -delete
  git fsck --full
  ```

  Some were committed anyway: take them out of the repository with `git rm --cached` in a new commit; an unpushed commit
  that holds only them is undone instead. Rewriting pushed history needs a force push: ask first.
- Branch from the latest `master` for each issue or feature.
- Commit messages are in English, Conventional Commits as configured for commitizen in `package.json`
  (`feat: ✨ …`, `fix: 🐛 …`, `docs: 📝 …`).
- Push early and open the pull request once the change is substantial; the PR body closes the issue (`Closes #N`).
- Before merging, squash the PR into a single commit and push with `--force-with-lease` (never a plain force push).
  On someone else's branch, merge `master` in instead of rebasing.
- After opening the PR, comment on the issue (in the issue's language) with the changes, the commit link, and an
  invitation to try the latest version.

## Commands

```sh
pod lib lint CYLTabBarController.podspec --quick
scripts/unit-tests.sh "iPhone 17 Pro Max"
scripts/ci-build-example.sh <demo folder>
python3 scripts/update-docs-navigation.py
python3 scripts/sync-agent-skills.py --check
scripts/publish-android.sh staging        # Android library: build and check the Maven bundle (local | staging | central | github)
```
