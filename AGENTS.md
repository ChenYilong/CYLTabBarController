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
- **Comments on public API: one documentation block format, for one line or many.** A caller reads a public API's
  comment through the IDE's documentation (Xcode Quick Help, the generated Swift interface, Android Studio, editor
  hovers), and only a documentation comment gets there whole. **The official documentation rules of each language are
  the reference**; within them:
  - **One-line comments use the block format too.** A one-line comment on public API is written like a multi-line one:
    three lines above the declaration (`/*!`, ` * text`, ` */` in Objective-C). Never `/*! text */` on one line, and
    never a trailing comment after a declaration or an enum case (`/**< */`, `/*!< */`, `///<`, `//`).
  - **One format per public file**, for short and long comments alike.
  - **Every platform and language**, each in its documentation tool's block form:
    - Objective-C public headers: `/*! … */` (HeaderDoc; Xcode shows it to Objective-C callers and in the Swift interface
      generated from the header).
    - Swift: `/** … */` (Swift Markup; Swift does not read `/*!` as documentation).
    - Kotlin, Java, TypeScript, JavaScript: `/** … */` (KDoc, Javadoc, TSDoc / JSDoc).
    - Python: a triple-quoted docstring on its own lines.
    - Go: `/* … */`; C#: `/** … */` with XML tags; Rust: `/** … */`.
    - A language without a block form uses its only documentation comment form in the whole file.
    - Where a language's official rule names one form, that rule wins: Dart keeps `///` (Effective Dart requires it for
      doc comments), and the official guides of Go (`//`), C# and Rust (`///`) prefer line comments; follow them in those
      languages.
  Check with `python3 scripts/check-public-api-comments.py` (iOS public headers, the Android library modules, the React
  Native sources, the Flutter sources); `--fix` rewrites one-line blocks into three lines, `//` / `///` comments in
  Objective-C headers into `/*! … */` blocks, and moves trailing comments above the declaration (merged into its existing
  block when it has one, since a second block would hide the first).
- **Comments are bilingual**: write `[EN]` / `[CN]` blocks; mark fixes with `FIX: issue #N`. A comment written in
  Chinese is tagged `[CN]` and is followed directly by its English translation tagged `[EN]`, in the same comment style
  (inside the same block comment on public API; `//` lines elsewhere). Comments that only
  contain a person's name, and commented-out code, need no translation.
- **No Chinese text in code**: every string literal that contains Chinese, including log, assert and debug messages,
  goes through `CYLLocalizedString(@"<original Chinese text>")` (Swift: `CYLLocalizedString("...")`), with
  `[NSString stringWithFormat:]` / `String(format:)` for values. `CYLLocalizedString()` is declared with
  `NS_FORMAT_ARGUMENT(1)`, so keep placeholders and arguments in step. The only exceptions are resource identifiers
  (e.g. an image asset name) and constants that are documented as localization keys; never touch Xcode project
  files, plists or storyboards for this.
- **Localization (i18n / l10n) file structure.** Localized texts are always many files, one per language: they are
  never left as loose `.lproj` folders in a target or folder, but grouped and reached through one entry point.
  - **iOS: one `.bundle` per owner.** Put all the `.lproj` folders of a set of tables into one `.bundle`
    (`<Name>.bundle/<language>.lproj/<Table>.strings`). Several bundles are fine, one per owner or purpose.
  - **The core bundle is permanent.** `CYLTabBarController/Resources/CYLTabBarController.bundle` (table
    `CYLTabBarController`) ships with the library: always keep it, with its name, path and table name, and update it
    carefully. It holds the library's own texts only. Every key goes into **all** its `.lproj` folders with the same
    `%@` / `%1$@` specifiers, so every table has the same keys; never rename or remove a key that released code reads;
    check for duplicate keys with `LC_ALL=C sort`.
  - **Examples have their own bundle, at the example level.** Texts that only an example shows go into a bundle that
    belongs to the example (in its own folder, or in `Example-Shared/` when several examples share it), not into the
    core bundle. Xcode's `Base.lproj` for storyboards and launch screens stays where Xcode puts it.
  - **Always a macro per bundle.** Each bundle gets one macro (and a Swift function named in Swift style, lowerCamelCase: `cylDemoLocalizedString` for
    `CYLDemoLocalizedString`, as SonarCloud rule swift:S100 requires) that maps a key to
    its bundle and table, so callers never spell the bundle out: the core one is `CYLLocalizedString(@"…")`; an
    example's is, for instance, `CYLDemoLocalizedString(@"…")` over `NSLocalizedStringFromTableInBundle`. Declare it
    with `NS_FORMAT_ARGUMENT(1)` and `CYL_RETURNS_LOCALIZED_STRING`, like the core one.
  - **Acceptance criterion: at least two different macros, one per layer.** A project passes only when it has at least
    two different macros (and their Swift-style Swift functions) that read the localized files of two different
    layers: (1) a **core** macro that reads the localized files inside the library's own bundle; (2) an **example**
    macro that reads the localized files at the example level. On iOS these are `CYLLocalizedString` →
    `CYLTabBarController.bundle` and `CYLDemoLocalizedString` → `Example-Shared/CYLDemo.bundle`. Other platforms use a
    different package form, name and folder name (Android `res/values*/` per module, a table file per example for React
    Native and Flutter), but each layer is still a folder or package of per-language files reached through its own
    macro or helper. It fails when one macro reads both layers, when an example reads the core bundle through
    `NSLocalizedString` or `NSBundle` calls of its own, when an example's texts sit in the core bundle, or when
    loose `.lproj` folders are left in a target. An example project that compiles a file calling the example macro
    must also compile the macro's source (`CYLDemoLocalization.m` / `.swift`) and ship `CYLDemo.bundle`. Run
    `python3 scripts/check-localization-macros.py` for the iOS side; it exits 1 and names each failure.
  - **Other platforms, the same way.** Android: the library's strings in the library module's `res/values*/` (the core
    tables: kept, updated carefully, generated from the iOS tables by `scripts/android-library-strings.py`), an
    example's strings in its own module's `res/values*/`, each reached through one helper (`CYLLocalization.string` for
    the library, an example helper for an example). React Native and Flutter: one table file per example
    (`strings.json`, generated by `scripts/sync-example-shared.py`) behind one function (`t()`).
  - Gaps against this rule are listed under TODO in [docs/Configuration-Localization.md](docs/Configuration-Localization.md).
- **Example lists keep their rounded sections.** Every table in an example uses the inset grouped style
  (`UITableViewStyleInsetGrouped` / `.insetGrouped`), so each section has its own rounded background. In a
  `UITableViewController`, `self.view` is the table: never paint it `systemBackgroundColor` (white on white hides the
  sections); use `systemGroupedBackgroundColor` or leave the default. A library helper that adds a plain table (e.g.
  `cyl_addBadgeHelperTable`) is created by the example itself with `.insetGrouped`. Keep this when porting a demo.
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
- **Demo table rows: never on the first tab, spread over the others.** In every example (Swift, SwiftUI, Android,
  React Native, Flutter), a new table-view demo row goes on a tab item **other than the first**, and each new one goes on
  the **next tab in turn** (the second, then the third, and so on, back to the second after the last), so the rows spread
  over the tabs instead of piling up on one. The **first tab item always imitates the Objective-C example's table view**
  (the sections and rows of `Example/Classes/Module/Home/CYLHomeViewController`): change it only to follow a change there.
- **New demos** follow the `cyl-new-project` skill. **PlusButton with forced title alignment**: give it a title; see `cyl-plus-button`.
- **Xcode project files** keep the ObjC example's format (`objectVersion = 46`, `compatibilityVersion = "Xcode 3.2"`, no folder sync, deployment target below 27), or CI on Xcode 26 fails. Check before committing any `.xcodeproj` change. Full rules: the `cyl-xcode-compat` skill.
- **Clean before every build and run**: build into an empty derived data folder (delete it first, or pass a new
  `-derivedDataPath`), for apps, tests and scripts alike. The Objective-C demo does not relink after a change in the
  library only, so a reused build tests an old binary and its result means nothing (2026-11-09: two experiments ran
  stale code). Confirm a new symbol is in the app (`strings <app>/<binary> | grep <symbol>`) when in doubt.
- **Simulator**: run `scripts/free-ram.sh` before every simulator use. Details and common failures: the `cyl-verify` skill.

## Depending on CYLTabBarController

A project always integrates CYLTabBarController through CocoaPods. The version it depends on is always the **latest commit
of CYLTabBarController**, which can sit on any branch, not only `master` or `main`.

1. **Find the latest commit before every build.** Never reuse a commit you found earlier. Run
   `scripts/latest-cyl-commit.sh` (from any folder, with the absolute path outside this repository): it fetches every
   branch of `https://github.com/ChenYilong/CYLTabBarController.git` and prints the newest commit by **commit
   timestamp** (`<sha> <date> <branch>`); `--sha` prints the sha only and `--podfile` prints the Podfile line.
2. **A project whose name is not CYLTabBarController depends on that commit:**
   `pod 'CYLTabBarController', :git => 'https://github.com/ChenYilong/CYLTabBarController.git', :commit => '<sha>'`
   (a subspec the same way: `pod 'CYLTabBarController/PAG', :git => …, :commit => '<sha>'`). Never a version number
   (`'~> 1.99'`), a branch or a tag. Put the new sha into the Podfile, run `pod install`, then build.
3. **A project whose name is CYLTabBarController (this repository, and the demos in it) depends on it locally**, by a
   relative path to the folder that holds `CYLTabBarController.podspec`: from a demo folder
   `pod 'CYLTabBarController', :path => '../'`; from `CrossPlatform/<component>/example/ios` count the folders up to the
   repository root. Never an absolute path, a commit or a version.
4. Say in the reply which commit (sha, date, branch) a build used. If the commit cannot be fetched (offline), say so and
   do not guess: keep the sha already in the Podfile and report that it may not be the latest.

### Depending on CYLTableViewPlaceHolder (every example)

Every example, existing and new, also integrates **CYLTableViewPlaceHolder** through CocoaPods at its **latest commit on
any branch**, found by commit timestamp before every build, exactly as for CYLTabBarController above:
`CYL_REPO_URL=https://github.com/ChenYilong/CYLTableViewPlaceHolder.git CYL_COMMIT_CACHE=$TMPDIR/cyl-placeholder-latest.git scripts/latest-cyl-commit.sh --sha`,
then `pod 'CYLTableViewPlaceHolder', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '<sha>'`
(with the `LottieSwift` subspec for animated placeholders, the same `:git` and `:commit`). Never a version, a branch or
a tag. Then, in the iOS examples:
- **Every scroll view** (table, collection, plain `UIScrollView`) supports pull to refresh (`cyl_header`, e.g.
  `CYLRefreshNormalHeader`) and shows a placeholder when it has no data (`cyl_placeholderViewBlock:`), a no-network
  placeholder when the device is offline, and a red bar at the top while offline. Prefer animated icons (the Lottie
  files in `CYLTableViewPlaceHolder.bundle/Animations/`). Follow the scenario example of CYLTableViewPlaceHolder
  (`Examples/Example-Scenarios`) for the code.
- **No MJRefresh.** Its pod is not used; its API maps to CYLTableViewPlaceHolder's refresh component by renaming
  `mj_` to `cyl_` and the `MJRefresh` class prefix to `CYLRefresh`.
- A build error that CYLTableViewPlaceHolder causes is not worked around silently: it is listed with its cause in
  `docs/CYLTableViewPlaceHolder-Integration-Issues.md`, so it can be fixed in that library.

### How the examples set CYLTabBarController up (the default)

Unless a task says otherwise, every CYLTabBarController in the example layer is integrated the same way:
1. **With a plus button that has its own page** (a `plusChildViewController`): the plus button selects a page, it is not
   only an action.
2. **Initialized from a local configuration file** in the app (`Example-Shared/Configurations/cyl_tabbar_configuration.*`
   or the example's own copy), with `+[CYLTabBarController tabBarControllerWithConfigurationFile:error:]`: the tabs come
   from `CYLTabBarControllerTabBarItemsAttributes`, the plus button from `CYLTabBarControllerPlusButton`, and the plus
   button's page from `CYLTabBarItemPageIdentifier` inside it (resolved like a tab's page: the configuration's resolver,
   the page registry or the global registry). See [docs/Configuration-File.md](docs/Configuration-File.md).
A demo that shows another setup on purpose (no plus button, a plus button without a page, attributes built in code, a
`CYLPlusButtonSubclassing` subclass) says so in its title or comment.
3. **A raised plus button (added 2026-11-12)**: when an example demonstrates the plus button, always prefer the raised look: the top of the plus button reaches above the top edge of the tab bar (an image taller than the bar, and/or `+multiplierOfTabBarHeight:` below 0.5 or a negative `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`), in every style (classic, Liquid Glass, FlatDesign). A demo that needs a flat plus button (inside the bar) says so in its title or comment.

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

4. **No copied sources.** SonarCloud counts every copied file as duplicated code. Before copying a file from another
   demo, reference it instead:
   - The HealthyHome demos (`Example-SwiftUI`, `Example-Swift-Carthage`, `Example-PAG`, `Example-Swift-SwiftManager`)
     compile the sources of `Example-Swift-03/HealthyHome` (file references with `sourceTree = SOURCE_ROOT` and a
     `../Example-Swift-03/HealthyHome/…` path). A demo-specific difference goes into that file behind a Swift compile
     condition set only in that demo's app target (`SWIFT_ACTIVE_COMPILATION_CONDITIONS = "$(inherited) …"`):
     `CYL_DEMO_PAG`, `CYL_DEMO_SWIFTUI`, `CYL_DEMO_FLATDESIGN_DELEGATE` (the FlatDesign delegate of Carthage and PAG).
   - Sources shared by unrelated demos go into `Example-Shared/` (e.g. `CYLPlusButtonSubclass+Layout.swift`, used by
     Example-Swift and Example-Swift-02; each keeps its own `plusButton()`). React Native examples reference
     `example/ios/…` (e.g. `SceneDelegate.swift`).
   - The sample configuration files are in `Example-Shared/Configurations/`, bundled as a folder reference.
   - Test helpers shared by several test files go into one file (Android: `CYLTestSupport.kt`; scripts:
     `scripts/configuration-tests/confined_paths.py`).

## CI/CD and where tests run

- **GitHub CI/CD for iOS runs on macOS 26 by default.** Before you rely on a CI environment, always read
  [`.github/workflows/ios.yml` on master](https://github.com/ChenYilong/CYLTabBarController/blob/master/.github/workflows/ios.yml)
  to confirm it: its macOS jobs use `runs-on: ${{ vars.MACOS_RUNNER || 'macos-26' }}`, so the repository variable
  `MACOS_RUNNER` (e.g. `xcode-27`) can move them to another runner. Code that must pass CI builds with the Xcode of that
  runner (`xcodebuild -version` is printed in the job log).
- **Running locally ignores that limit.** "Local" means not going through GitHub CI/CD but testing directly on this Mac:
  the default local system is **macOS 27**, with **Xcode 27** (`/Applications/Xcode.app`, never Xcode-beta) and its
  simulators, which you can run directly (`xcrun simctl`, `scripts/unit-tests.sh`, the scripts under `scripts/`).
- **Before every local build, check the local environment comment** at the top of
  [`.github/workflows/ios.yml`](.github/workflows/ios.yml) (read that file first, as above): its first line records the local
  run environment, e.g. `# local-run-environment: macOS 27.3 (26C5035r), Xcode 27.2 (27B52)`. The local environment is
  agreed to stay the same: add the comment when it is missing, leave it when macOS and Xcode are unchanged, and rewrite it
  when either version differs. `scripts/local-run-environment.sh` does exactly that (`--check` only reports); it reads the
  Xcode of `/Applications/Xcode.app`, not the `xcode-select` default (which may be a beta). Commit a changed comment with
  the work it belongs to.
- Say in the report where a check ran: GitHub CI (which runner) or locally (macOS and Xcode version).

- **Screenshots (added 2026-11-12)**: every screenshot, from CI/CD and from local builds, is saved in the repository with the related document in `docs/` (create the document when none fits; images in `docs/assets/`) and committed to git. Use clear original screenshots: never scaled down or recompressed; a crop that keeps the original resolution is allowed. When the result looks as expected, also update `README.md` with the latest screenshots, in the related section (create it when there is none). Every screenshot, in the document and in the README, is labeled with: the platform (iOS, Android, Flutter, React Native, HarmonyOS, WeChat Mini Program); the environment: operating system version, simulator or emulator (device model and OS version), and the SDK version of that platform (iOS SDK / Xcode, Android SDK / API level, Flutter SDK, React Native, HarmonyOS SDK, WeChat Mini Program base library); this repository's version or commit (with its link); and the time it was taken.
- **Screenshot moments and layout (added 2026-11-12)**: take and commit screenshots at key moments: when a TODO or Linux note can be removed, when a pull request can be merged, or when the result is judged as expected with no bug and no open issue. The README shows cropped key details, a full screen only when it is needed; several details go into one stitched image. Stitching order of preference: a vertical stack (one column, top to bottom), easiest to read on a phone; then two columns with several rows; last, a single horizontal row, at most three images in a row. (Corrected by the maintainer on 2026-11-12: the original wording said both "prefer a horizontal arrangement" and "a horizontal row is the worst", which contradict each other; the rule is to prefer a vertical stack.)

## Git and pull requests

- **Before every Commitizen-style (`git cz`) commit**, run this first in the repository root, so the vault's auto sync does not commit or push in the middle of it:

  ```sh
  touch .git/hooks/NO_AUTO_SYNC
  ```

- **On any branch other than `master` or `main`, commit and push as soon as the work is written, without asking
  for confirmation.** On `master` or `main`, ask first.

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
- **Swift for the iOS core layer (added 2026-11-12)**: the core layer (`Core`, `CYLUtils`, `CYLBadgeView` subspecs) is being translated from Objective-C to Swift, bottom-up, keeping every Objective-C name (`@objc(name)`); third-party adapters and the examples stay unless a change is needed. Follow [docs/Swift-Coding-Style.md](docs/Swift-Coding-Style.md); record each step and the score of `python3 scripts/swift-migration-score.py` in [docs/Swift-Migration.md](docs/Swift-Migration.md) and in the commit body; continue until the score is 100 (no Objective-C left; macro-only headers count as compatible).
- **Upstream projects used for translation (added 2026-11-12)**: when a document of this project links to another project's GitHub repository that is the source of a translation or port (for example the projects ported to Kotlin in the Android folder), do not translate only its default branch. (1) Pull requests: visit the upstream's open pull requests and bring them in. If the translation has not started, merge the open pull requests into the source first; if it is already done, translate each open pull request's change and merge it into our port. (2) Issues: list the upstream's open issues in a table in the related document in `docs/` (create one when none fits): column 1 the issue link, column 2 its description, column 3 the fix status (`TODO` by default). Find each issue's counterpart in our code and try to fix it. (3) Score: 100 means every listed issue is resolved; give a score after each fix and continue until 100. (4) Order: for a translation not started yet, merge the open pull requests, fix issues until the score reaches 60, translate, then fix the remaining issues up to 100; for a finished translation, translate and merge the open pull requests, then fix the issues on the translated code up to 100. The same rule applies to every platform.
- **`-[CYLPlusButton cyl_updateLiquidGlassMask]` is a known source of plus button bugs (added 2026-11-12)**: implement it only with great care. When any plus button bug shows up (missing, cut, offset, flickering), first disable this method (its first line returns, through `CYL_PLUS_BUTTON_LENS_MASK_ENABLED` set to 0) and test again, to rule it out before looking anywhere else. Known failure: on iOS 26 and later, Liquid Glass (not FlatDesign), with a plus button that has a plus child view controller, select the plus button, then drag the Liquid Glass lens to another item: the plus button is cut in two. The maintainer removed an earlier implementation because of this. Keep an implementation only after complete testing shows that dragging the lens never cuts the plus button (the drag UI tests in `Example-SwiftUI/HealthyHomeUITests`, recorded on video, raised and flat plus buttons), and that the plus button is never missing or offset on first display or when the plus tab is selected in code.
- **Record every task in `docs/` before starting it (added 2026-11-12)**: before any task, find the most relevant existing document in `docs/` (create one only when none fits) and add a `TODO` entry with the task's full context, the user's requirements, and the user's prompt quoted verbatim. Then start the work. When the task is finished, change that entry to `DONE` with the result and its evidence (commits, tests, screenshots). Purpose: if the work is interrupted, the next session can find the context again.
- **Every new branch gets a pull request, automatically (added 2026-11-12)**: after creating a branch and pushing its first commit, open a pull request right away, without asking. Target branch: the branch it was created from (preferred); otherwise `main` or `master`.
- **Every commit message carries the author line** `By  @ChenYilong <luohanchenyilong@163.com>` (exactly as written,
  two spaces after `By`) on its own line in the body, after the description and before any trailers such as
  `Claude-Session:` or `Co-authored-by:`. A commit without it is incomplete: amend it before pushing.
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
