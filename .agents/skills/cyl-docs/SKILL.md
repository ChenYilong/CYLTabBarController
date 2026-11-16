---
name: cyl-docs
description: "Documentation rules of CYLTabBarController: bilingual format, screenshots and assets, generated navigation, document-to-class bindings, and keeping skills up to date. Use when adding a feature, changing behavior, or editing README.md or docs/."
---

# Documentation rules

## Every new API or feature, in the same change

1. A document in `docs/` and `README.md` (section 1 below).
2. The skills: a row in `cyl-api-map`, and a change to any `cyl-*` skill whose rules or limits it affects. A new limit goes where the next person will read it.
3. A new demo follows `cyl-new-project`, and is added to its table.
4. `README.md` is checked against the code it describes. Code wins, then `docs/`, then `README.md`: fix what is wrong, then the skill.

Then run:

```sh
python3 scripts/update-docs-navigation.py
python3 scripts/sync-agent-skills.py --check
python3 scripts/android-api-map.py --check   # after a public header changes 公开头文件变化后
python3 scripts/android-library-strings.py --check   # after a .lproj changes .lproj 变化后
python3 scripts/sync-example-shared.py --check     # after Example-Shared or a .lproj changes Example-Shared 或 .lproj 变化后
```

## 1. Documentation is part of every new feature

Every new feature (and every user-visible behavior change) ships with **bilingual Chinese–English documentation in
two places**:

1. **A document in `docs/`**: a new file named after the feature, e.g. `docs/Login-Required-Tabs.md`. It explains what
   the feature does, how to use it (Objective-C, and Swift when it differs), the API, the demo, and its limits.
2. **An update to `README.md`**: at least a feature bullet in the latest-version preview that links to the `docs/`
   file; add a full README section when the feature is part of the core usage.

### Bilingual format

- Prose is written as a two-column table: **the left column in Chinese, the right column in English**, one row per
  passage. Copy the header row from any existing table in `README.md` or `docs/` (its left header is the Chinese word
  for "Chinese", its right header is `English`):

  ```markdown
  | <Chinese header> | English |
  |:---|:---|
  | <the passage in Chinese> | The same passage in English. |
  ```

- Tables with more columns (API tables, comparisons) either carry both languages in each cell, or are given twice:
  a Chinese table followed by its English twin with the same rows.
- Headings come in pairs on consecutive lines, `## [CN]<Chinese title>` then `## [EN]<English title>`, or as a single
  heading `## <Chinese title> / <English title>`.
- Code blocks are shared between the two languages; their comments may be bilingual.
- Both columns say the same thing. Do not leave a passage in only one language.

### Screenshots and attachments

- **Debugging screenshots** that show the feature working (no bugs visible) are kept: save them in `docs/assets/` and
  embed them in the feature's `docs/` file.
- **Final screenshots** of the finished feature also go into `README.md`.
- **Screenshot layout**: a matrix (e.g. styles × libraries) stays a grid. Any other set of screenshots is stacked **top to
  bottom**, one per row (a two-column table row each, or one image per line), never side by side: stacked, the same tab
  bar item lines up vertically, so its states (selected, pressed, a value of a setting, before and after a fix) compare
  at a glance. Crop each screenshot to the same region and width (e.g. only the tab bar), and label each row with the
  state it shows. Example: `docs/Android-Liquid-Glass.md` (the dock at three surface opacities).
- If a change could not be run (no simulator or device), say so in the document instead of adding screenshots, and
  never present a mock-up or a diagram as a screenshot.
- **Attachment layout (Obsidian rule)**: a Markdown file's attachments live in an `assets/` folder **next to that file**,
  and are linked with the **shortest relative path**:
  - `docs/*.md` → `docs/assets/`, linked as `assets/name.png`
  - `README.md` → `assets/` at the repository root, linked as `assets/name.png`
  - No absolute paths, no `../` paths for attachments, no other attachment folders. Use lowercase, hyphenated file
    names that name the feature, e.g. `assets/login-required-tabs-alert.png`.
- Diagrams are welcome: Mermaid blocks in the Markdown, and optionally an SVG copy in `assets/`.

### Comments on public API

Every comment on public API, one line or several, is a documentation block written on its own lines above the
declaration (Objective-C: `/*!`, ` * text`, ` */`), never `/*! text */` on one line and never a trailing `/**< */`,
`/*!< */`, `///<` or `//`. One format per public file. Forms: Objective-C headers `/*! … */`; Swift `/** … */`; Kotlin,
Java, TypeScript, JavaScript `/** … */`; Python a docstring on its own lines; Go `/* */`, C# `/** */` with XML tags, Rust
`/** */`; a language without a block form uses its only doc form. The official documentation rules of each language are
the reference and win where they name one form (Dart `///`; Go `//`, C# and Rust `///`). Check with
`python3 scripts/check-public-api-comments.py` (`--fix` rewrites). AGENTS.md, "Comments on public API".

### Commit message author line

Every commit message carries the line `By  @ChenYilong <luohanchenyilong@163.com>` (exactly as written, two spaces after
`By`) in its body, after the description and before trailers such as `Claude-Session:`. Check it before every push
(`git log -1 --format=%B`); amend a commit that lacks it. AGENTS.md, "Commit messages".

### Commit message style: `git cz`, English only

Every commit uses the `git cz` (Commitizen) style and is written entirely in English: no Chinese (and no other non-English text) anywhere in the subject, the body or the trailers. A user's prompt in another language is quoted in the task's document in `docs/`, never in the commit message.
Before pushing: `git log -1 --format=%B | python3 -c "import re,sys; sys.exit(1 if re.search('[\u4e00-\u9fff]', sys.stdin.read()) else 0)"` prints nothing. AGENTS.md, "Git and pull requests".

### Swift migration of the core layer

- **Swift for the iOS core layer (added 2026-11-12)**: the core layer (`Core`, `CYLUtils`, `CYLBadgeView` subspecs) is being translated from Objective-C to Swift, bottom-up, keeping every Objective-C name (`@objc(name)`); third-party adapters and the examples stay unless a change is needed. Follow [docs/Swift-Coding-Style.md](docs/Swift-Coding-Style.md); record each step and the score of `python3 scripts/swift-migration-score.py` in [docs/Swift-Migration.md](docs/Swift-Migration.md) and in the commit body; continue until the score is 100 (no Objective-C left; macro-only headers count as compatible). **Examples bend, the core does not (added 2026-11-13)**: when the migration breaks an example's build, fix the example first; examples have the lowest priority and their code may change freely. Never keep a workaround, overload, kept name or shim in the core only because an example uses it; the Swift coding style decides. The public API rule and kept Objective-C selectors still apply, for apps. Details: [docs/Swift-Coding-Style.md](../../../docs/Swift-Coding-Style.md).

### Upstream projects used for translation

- **Upstream projects used for translation (added 2026-11-12)**: when a document of this project links to another project's GitHub repository that is the source of a translation or port (for example the projects ported to Kotlin in the Android folder), do not translate only its default branch. (1) Pull requests: visit the upstream's open pull requests and bring them in. If the translation has not started, merge the open pull requests into the source first; if it is already done, translate each open pull request's change and merge it into our port. (2) Issues: list the upstream's open issues in a table in the related document in `docs/` (create one when none fits): column 1 the issue link, column 2 its description, column 3 the fix status (`TODO` by default). Find each issue's counterpart in our code and try to fix it. (3) Score: 100 means every listed issue is resolved; give a score after each fix and continue until 100. (4) Order: for a translation not started yet, merge the open pull requests, fix issues until the score reaches 60, translate, then fix the remaining issues up to 100; for a finished translation, translate and merge the open pull requests, then fix the issues on the translated code up to 100. The same rule applies to every platform.

### Record every task before starting it

- **Record every task in `docs/` before starting it (added 2026-11-12)**: before any task, find the most relevant existing document in `docs/` (create one only when none fits) and add a `TODO` entry with the task's full context, the user's requirements, and the user's prompt quoted verbatim. Then start the work. When the task is finished, change that entry to `DONE` with the result and its evidence (commits, tests, screenshots). Purpose: if the work is interrupted, the next session can find the context again.

### Pull request for every new branch

- **Every new branch gets a pull request, automatically (added 2026-11-12)**: after creating a branch and pushing its first commit, open a pull request right away, without asking. Target branch: the branch it was created from (preferred); otherwise `main` or `master`.
- **Every commit on a branch goes through an open pull request (added 2026-11-16)**: once a branch is created, every commit on it must reach a pull request. Never create a branch and keep committing to it without a pull request: the commits of a branch without a pull request are all ignored. Before every commit, check that the branch has an open pull request (`gh pr list --head <branch> --state open`); if it has none, open one right away. Target branch: the pull request that was active before this one was created (its head branch) first; only when there is none, `master`. If more than two pull requests are already open, stop and ask the maintainer whether to create a new branch with its own pull request or to keep committing to the current branch: more than two open pull requests make merging hard and leave no sound choice of target branch for each. AGENTS.md, "Git and pull requests".
- **Commit and push at the end of every turn (added 2026-11-16)**: when a question-and-answer turn ends and the current branch is not `master` or `main`, commit and push the work of that turn, without asking. This is always safe: the code stays on a branch and is never pushed to `master` or `main`, so pushing carries no risk to worry about. The open pull request rule still applies to every such commit (check for an open pull request first, open one if missing). On `master` or `main`, ask first. AGENTS.md, "Git and pull requests".

### Fix bugs in the core first

- **Fix bugs in the core first, not in the examples (added 2026-11-17)**: when an issue or a bug comes up, fix it first in the core code, so the same kind of problem goes away for every app, instead of working around it in the example layer. The core is the code published to a package registry: CocoaPods (and Swift Package Manager), Maven / Gradle (the Android library), npm (the React Native component), pub.dev (the Flutter component), ohpm (the HarmonyOS `cyltabbar` module) and the WeChat Mini Program component. A fix in the example layer is the worst option. If a bug cannot be fixed in the core, stop and ask the maintainer first, and say why. When the maintainer agrees to an example-layer fix, explain in the related document in `docs/` and in `docs/Example-Layer-Fixes.md` why the core could not solve it and why the example does. AGENTS.md, "Code rules".

### Badge debugging: animations off

- **Badge debugging: turn badge animations off with the build option (added 2026-11-17)**: while checking badge positions (coordinates, offsets, alignment with the icon), build with the badge-animation build option `CYL_BADGE_ANIMATION_DISABLED` on, so an animation (Bounce, Shake, Scale, Breathe, the one-shot types) never moves a badge while a screenshot or a layout dump is taken: an animated badge is drawn away from its laid-out place, and the measured coordinates are wrong. It exists in the core of each platform: iOS, the Swift compilation condition `CYL_BADGE_ANIMATION_DISABLED` on the CYLTabBarController target (Podfile `post_install`: `SWIFT_ACTIVE_COMPILATION_CONDITIONS = '$(inherited) CYL_BADGE_ANIMATION_DISABLED'`); Android (and the React Native and Flutter components, which use its host view), the Gradle property `-PcylBadgeAnimationDisabled=true` (`BuildConfig.CYL_BADGE_ANIMATION_DISABLED`); HarmonyOS, `CYL_BADGE_ANIMATION_DISABLED: true` in `buildProfileFields` of `CrossPlatform/harmonyos-cyltabbar/cyltabbar/build-profile.json5`; WeChat Mini Program (no compile-time defines), the constant `CYL_BADGE_ANIMATION_DISABLED = true` in `CrossPlatform/wechat-miniprogram-cyltabbar/src/cyl-tab-bar/cyl_debug.js`, then `npm run setup` in the example and recompile in DevTools. Turn it off again before committing (never commit it on, never ship it): after the positions are right, take one more check with animations on, because an animation's own offsets can still be wrong. Say in the report and in the screenshot label that the build option was on. Details: `docs/Badge-Debugging.md`. AGENTS.md, "Code rules".

- **Badge animation build controls default to NO (added 2026-11-17)**: every build control that turns badge animations off, including but not limited to the iOS Swift compilation condition `CYL_BADGE_ANIMATION_DISABLED`, the Android Gradle property `-PcylBadgeAnimationDisabled` (`BuildConfig.CYL_BADGE_ANIMATION_DISABLED`, also in the React Native and Flutter Android builds), the HarmonyOS `buildProfileFields` entry `CYL_BADGE_ANIMATION_DISABLED` in `cyltabbar/build-profile.json5`, the WeChat Mini Program constant `CYL_BADGE_ANIMATION_DISABLED` in `src/cyl-tab-bar/cyl_debug.js`, and any badge animation switch added later, defaults to NO (not set, `false`): badges animate as the app asks. Set one to YES (`true`) only while debugging badges: badge coordinates, offsets and alignment with the icon or other views. Set it on locally only; never commit, merge, release or publish it as YES (no Podfile, Xcode project, `gradle.properties`, CI setting or package with it on), and set it back to NO when the debugging is done, then check once more with animations on. Details: `docs/Badge-Debugging.md`.

### Stale notes before every commit

Before every commit, search every document in `docs/` and `README.md` for the keywords **`TODO`** and **`Linux`**, and
for other notes written where the code could not run (no Xcode, no simulator, no screenshots):

```sh
grep -rn -i -E "TODO|Linux|without Xcode|no (iOS )?simulator|no screenshots?|无法(编译|运行)|没有截图|暂无(测试)?截图" docs README.md
```

- Test each feature such a note is about: build it, run its unit tests, and run its demo on the simulator or emulator
  (`scripts/free-ram.sh` first; drive the UI through accessibility labels, see the `cyl-verify` skill).
- Replace the note with what was verified (device, OS, tool versions, the checks done) and the bug-free test
  screenshots, saved in `docs/assets/` and laid out as "Screenshot layout" above. Update the `README.md` section too
  when the feature appears there.
- A finished TODO becomes DONE with its evidence. A TODO only the maintainer can do (a repository setting, a release)
  stays, stating what was checked and when.
- A bug found while testing is fixed in the same change, and its document says so.
- Notes that are true where they are (a Linux CI job, GNUstep tests of the parser) stay.

## 2. Navigation is generated — keep it up to date

The navigation of the documentation is generated by `scripts/update-docs-navigation.py` (Python 3, standard library
only). Everything between `<!-- navigation:start -->` and `<!-- navigation:end -->` is generated: never edit it by
hand. The script writes:

- **Page contents**: a bilingual contents table in `README.md` and in every `docs/*.md` file, one row per heading,
  linking to the Chinese and the English heading. A new document gets its contents section automatically, right
  before its first level-2 heading.
- **Documentation index**: every `docs/*.md` file with its Chinese and English title, in `README.md` and in
  `docs/README.md`.
- **Folder layout**: the tree of files and folders under `docs/` (attachments included), in `docs/README.md`.

**Run it after any change** to `README.md` or `docs/`: a Markdown edit, a heading added or renamed, or a file or
folder added, renamed, moved or removed:

```sh
python3 scripts/update-docs-navigation.py          # rewrite the navigation
python3 scripts/update-docs-navigation.py --check  # exit 1 if it is out of date
```

- AI agents run it themselves after every such change, before committing.
- The `Docs navigation` GitHub Actions workflow runs `--check` on pull requests and fails when the navigation is
  stale.
- Links: README anchors include the `[CN]` / `[EN]` prefixes. After the script runs, every in-page link it writes
  points to an existing heading; check hand-written in-page links too when you rename headings.

## 3. Every document is bound to its code classes

Each `docs/*.md` file (except the generated `docs/README.md`) is bound to the code classes it documents, and those
classes link back to it:

- **In the document**: right under its title, declare the classes on one line (or `none` for a document about no code):

  ```markdown
  <!-- bound-classes: CYLPlusButton, CYLTabBarController -->
  ```

  The script writes a bilingual table below it (between `<!-- binding:start -->` and `<!-- binding:end -->`) that
  lists each bound class with the path of its header.
- **In each bound header**: right below the copyright comment, the script writes a bilingual `[EN]` / `[CN]` comment
  between `// docs-binding:start` and `// docs-binding:end` with the GitHub link of every document bound to that class
  (`https://github.com/ChenYilong/CYLTabBarController/blob/master/docs/<name>.md`).
- **Keep it current**: whenever a document is added, renamed or removed, a declaration changes, or a class header is
  moved or renamed, run `python3 scripts/update-docs-navigation.py`. It finds every class by its
  `@interface Name :` declaration under `CYLTabBarController/`, so moved headers and renamed documents are updated
  automatically. A declared class that cannot be found, or a document without a declaration, is an error, and the
  `Docs navigation` workflow fails.
- Never edit the generated binding blocks by hand; change the declaration instead.
