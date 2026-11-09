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
- **Accessibility is required everywhere.** The library code shipped to CocoaPods / SPM and to Gradle / Maven, the
  React Native and Flutter components, and every example fully support accessibility (VoiceOver, TalkBack, Voice
  Control, Switch Control, Dynamic Type where the platform has it). This applies to new code, to code you change, and to
  existing code you review: fix what is missing when you meet it.
  - Every control and every piece of text is an accessibility element with a meaningful label (and value, trait / role,
    state such as selected or on/off, and hint when useful): tabs, the plus button, badges (read as part of their host,
    e.g. "Messages, 99+ new"), covers and decorations (hidden from accessibility, the tab reads instead), list rows
    (title and subtitle in one element), switches, sliders and buttons inside rows, menus and their items.
  - Hide purely decorative views from accessibility; never leave an interactive view without a label.
  - React Native: `accessible`, `accessibilityRole`, `accessibilityLabel`, `accessibilityState` /
    `accessibilityValue`. Flutter: `Semantics` (or the widgets' `semanticLabel`), `ExcludeSemantics` for decorations.
    Android: `contentDescription`, `importantForAccessibility`, `stateDescription`. iOS: `accessibilityLabel`,
    `accessibilityTraits`, `accessibilityValue`, `accessibilityElementsHidden`.
  - Automated tests and simulator / emulator checks drive the UI through accessibility first: find elements by their
    accessibility label or identifier (XCUITest queries, `axe describe-ui`, `uiautomator`, Flutter `find.bySemanticsLabel`,
    React Native `getByLabelText`), and fall back to coordinates only when no element can be found, then file the
    missing label as a bug and fix it.
  - The convention: every component and every text of this project supports accessibility. A change that adds a control
    or a text without it is not done.
- **Naming: keep the project's prefixes.** Every class, protocol, type and function of this project starts with `CYL`,
  and every category method and category property starts with `cyl_`. A file you create or bring in (copied from
  another project, a sample, a snippet) follows the same rules:
  - Name new classes, structs, enums, protocols, file-private C functions and constants with the `CYL` prefix
    (`CYLBadgeView`, `CYLDemoTheme`), and the file after its main type (`CYLBadgeView.m`, `UIView+CYLBadgeExtention.m`).
  - Name every method and property added in a category with the `cyl_` prefix (`-cyl_showBadgeValue:`), also in
    extensions of system types written in Swift, Kotlin, Dart or TypeScript in this repository.
  - Remove any other prefix the copied code carries (another project's or author's prefix, `XX`, `My`, `QMUI`, `JX`…)
    and rename its symbols, files and references accordingly; keep a credit to the source in a comment instead.
  - Keep the names of public APIs that already shipped, as the Public API rule requires; this rule is for new code.
  - Sample apps follow it too: React Native and Flutter components, helpers and assets of the examples use `CYL`
    (`CYLBadgeView`, `cyl_badge_sample_icon`), unless the platform's own naming forbids it (e.g. Dart file names are
    snake_case: `cyl_badge_view.dart`).
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
- **Demo behavior: the first tab's cover is added by the demo, later.** In the Objective-C example the big icon over
  the first tab (the "淘" cover, `-setSelectedCoverShow:`) is put on by the example itself, 1.5 s after launch
  (`-cyl_demo_decorateTabBarController:`), not by the library. Icons are replaced the normal way (skins, network icons,
  `-setTabBarItemIcon:…`), and a cover added after them stays on top. Every example (iOS, Android, React Native,
  Flutter) does the same: when the tab icons change (a new skin, icons downloaded from the network), the example adds
  the cover again once the new icons are in. Do not change the library to keep a cover over icons that replace it later.
- **New demos** follow the `cyl-new-project` skill. **PlusButton with forced title alignment**: give it a title; see `cyl-plus-button`.
- **Xcode project files** keep the ObjC example's format (`objectVersion = 46`, `compatibilityVersion = "Xcode 3.2"`, no folder sync, deployment target below 27), or CI on Xcode 26 fails. Check before committing any `.xcodeproj` change. Full rules: the `cyl-xcode-compat` skill.
- **Clean before every build and run**: build into an empty derived data folder (delete it first, or pass a new
  `-derivedDataPath`), for apps, tests and scripts alike. The Objective-C demo does not relink after a change in the
  library only, so a reused build tests an old binary and its result means nothing (2026-11-09: two experiments ran
  stale code). Confirm a new symbol is in the app (`strings <app>/<binary> | grep <symbol>`) when in doubt.
- **Simulator**: run `scripts/free-ram.sh` before every simulator use. Details and common failures: the `cyl-verify` skill.

## Xcode projects: Podfile, app icon, launch screen

Whenever you work on a project that runs in Xcode (a demo, an example, any app with a Podfile), check these three things first and fix what is missing:

1. **Top of the Podfile.** It must start with these lines. `<projectname>` is the name of the `.xcodeproj` in the same folder as the Podfile:

   ```ruby
   platform :ios, '15.0'

   ENV['SWIFT_VERSION'] = '5'

   project '<projectname>.xcodeproj'
   ```

2. **Bottom of the Podfile.** It must end with this hook. If it is missing, append it at the bottom:

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
         config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
       end
     end
   end
   ```

   CocoaPods allows only one `post_install` hook per Podfile. If the Podfile already has one (React Native's
   `react_native_post_install`, Flutter's `flutter_additional_ios_build_settings`), put the `targets.each` loop inside
   that hook instead of adding a second one. React Native pods need React Native's own minimum (15.1,
   `min_ios_version_supported`): those Podfiles use it in both places instead of 15.0, so no pod goes below what React
   Native supports.
   Flutter Podfiles keep Flutter's build configurations on the project line:
   `project 'Runner.xcodeproj', { 'Debug' => :debug, 'Profile' => :release, 'Release' => :release }`.

3. **App icon and launch screen.** If the project has no app icon or no launch screen, copy them from the ObjC example
   (the root `CYLTabBarController.xcodeproj`). Look at every asset catalog the target compiles, not only its own folder:
   several demos share another demo's catalog (`Example-Rive` and RN `example-rive` use `Example-SwiftUI-Rive`'s, RN
   `example-pag` uses `Example-PAG`'s), and a second `AppIcon` set makes actool warn "used by multiple app icon sets".
   A launch screen can also be a build setting (`INFOPLIST_KEY_UILaunchStoryboardName`); `UILaunchScreen_Generation`
   alone is a blank screen and counts as none.
   - App icon: `Example/Images.xcassets/AppIcon.appiconset`, copied into the project's asset catalog; set
     `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.
   - Launch screen: `Example/Base.lproj/LaunchScreen.storyboard` and the image it shows,
     `Example/Images.xcassets/CYLTabBar.imageset`; set `UILaunchStoryboardName` to `LaunchScreen` in the Info.plist.
   - Add the copied files to the target, keeping the project format of the `cyl-xcode-compat` skill (explicit file
     lists, no folder sync).

The root `Podfile` is the reference: it already has the top lines and the hook.

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
- **Never commit `*.lock` files** (`Podfile.lock`, `yarn.lock`, `pubspec.lock`, `Gemfile.lock`): `.gitignore` excludes
  `*.lock`. Gradle's `gradle.lockfile` (and `settings-gradle.lockfile`) does not end in `.lock` and stays committed.
  SonarCloud's "lock file is missing" findings (`text:S8564` package.json, `text:S8568` Gemfile, `text:S8571`
  pubspec.yaml) are therefore avoided by excluding those manifests in `.sonarcloud.properties` (`sonar.exclusions`;
  automatic analysis ignores `sonar.issue.ignore.*` there), never by committing a lock file.
- **Before every commit, check `docs/` for stale notes**: search every document in `docs/` (and `README.md`) for the
  keywords **`TODO`** and **`Linux`**, and for other notes left by an environment that could not run the code
  ("without Xcode", "no simulator", "no screenshots", `无法运行`, `没有截图`):

  ```sh
  grep -rn -i -E "TODO|Linux|without Xcode|no (iOS )?simulator|no screenshots?|无法(编译|运行)|没有截图|暂无(测试)?截图" docs README.md
  ```

  For each hit about a feature: test it (build, unit tests, run it on the simulator or emulator), then update the
  document with what was verified and the test screenshots (`docs/assets/`, layout as the `cyl-docs` skill says), and
  `README.md` when its section is affected. A finished TODO becomes DONE with its evidence; a TODO that only the
  maintainer can do (a repository setting, a release) stays, with what was checked and when. A bug found while testing
  is fixed in the same change. Details: the `cyl-docs` skill, "Stale notes before every commit".
- **Push over SSH first**: `git push origin <branch>` (`origin` is `git@github.com:ChenYilong/CYLTabBarController.git`).
  Use HTTPS with the `gh` credential helper only when SSH fails: its token has no `workflow` scope, so GitHub rejects
  any push that changes `.github/workflows/*` ("refusing to allow an OAuth App to create or update workflow").
- Branch from the latest `master` for each issue or feature.
- Commit messages are in English, Conventional Commits as configured for commitizen in `package.json`
  (`feat: ✨ …`, `fix: 🐛 …`, `docs: 📝 …`).
- Follow the Commitizen defaults: emojis are enabled and the format is
  `{type}{scope}: {emoji}{subject}`. Scope is optional and there are no
  predefined scopes. The configured message length is 3–64 characters. The
  examples use a space between the emoji and subject. The
  interactive types, in order, are `test`, `feat`, `fix`, `chore`, `docs`,
  `refactor`, `style`, `ci`, and `perf`; `release` is defined but not listed.
- Default type meanings and emojis: `chore` (build or auxiliary tools, 🤖),
  `ci` (CI changes, 🎡), `docs` (documentation only, ✏️), `feat` (new feature,
  🎸), `fix` (bug fix, 🐛), `perf` (performance improvement, ⚡️), `refactor`
  (neither a feature nor fix, 💡), `style` (markup or formatting only, 💄),
  `test` (adding missing tests, 💍), and `release` (release commit, 🏹).
- The question sequence is `type`, `scope`, `subject`, `body`, `breaking`,
  `issues`, and `lerna`. Prompts request a change type, optional scope, a short
  imperative subject, longer description, breaking changes, issues closed (for
  example `#123`), and affected packages. Use this repository's established
  emoji mappings when they differ from defaults: `feat: ✨`, `fix: 🐛`,
  `docs: 📝`, `chore: 🔧`, and `refactor: ♻️`. Keep commit text in English.
- Before every commit, review the changed scope and its issue, comparison, and implementation-status documents.
  Record each incomplete or unverified item in the commit under a `TODO` heading in the most relevant existing
  `docs/` document. State the current score or status, remaining work, implementation constraints, known defects,
  API design and compatibility risks, optimization opportunities, and verification required for completion.
  Reserved keys, stubs, and successful compilation alone are not completion evidence.
- The Conventional Commit subject summarizes completed work in English; put details and pending tasks in the body.
  If the detailed description exceeds 50 characters, create or update a suitable `docs/` note and link it in the
  commit body. Reuse existing trackers and avoid duplicate documents.
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
