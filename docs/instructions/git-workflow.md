# Git and Pull Requests [`git-workflow`]

## Before Commitizen commits

Before every Commitizen-style (`git cz`) commit, run this first in the repository root, so the vault's auto sync does not commit or push in the middle of it:

```sh
touch .git/hooks/NO_AUTO_SYNC
```

## Commit message format

- **`git cz` style commits, English only (added 2026-11-16)**: Every commit is a Commitizen (`git cz`) style commit (`{type}{scope}: {emoji}{subject}`, see the Commitizen rules below), and the whole commit message is written in English: subject, body, TODO notes, and trailers. No Chinese characters are allowed anywhere in a commit message. When a commit refers to Chinese text (a user prompt, a document, a string), give its English translation or link the document instead. Check before every push: `git log -1 --format=%B | python3 -c "import re,sys; sys.exit(1 if re.search('[\u4e00-\u9fff]', sys.stdin.read()) else 0)"` must print nothing; reword a commit that fails.
- **Every commit message carries the author line** `By  @ChenYilong <luohanchenyilong@163.com>` (exactly as written, two spaces after `By`) on its own line in the body, after the description and before any trailers such as `Claude-Session:` or `Co-authored-by:`. A commit without it is incomplete: amend it before pushing.
- Commit messages are in English, Conventional Commits as configured for Commitizen in `package.json` (`feat: ✨ …`, `fix: 🐛 …`, `docs: 📝 …`).
- Follow the Commitizen defaults: emojis are enabled and the format is `{type}{scope}: {emoji}{subject}`. Scope is optional and there are no predefined scopes. The configured message length is 3–64 characters. The examples use a space between the emoji and subject. The interactive types, in order, are `test`, `feat`, `fix`, `chore`, `docs`, `refactor`, `style`, `ci`, and `perf`; `release` is defined but not listed.
- Default type meanings and emojis: `chore` (build or auxiliary tools, 🤖), `ci` (CI changes, 🎡), `docs` (documentation only, ✏️), `feat` (new feature, 🎸), `fix` (bug fix, 🐛), `perf` (performance improvement, ⚡️), `refactor` (neither a feature nor fix, 💡), `style` (markup or formatting only, 💄), `test` (adding missing tests, 💍), and `release` (release commit, 🏹).
- The question sequence is `type`, `scope`, `subject`, `body`, `breaking`, `issues`, and `lerna`. Prompts request a change type, optional scope, a short imperative subject, longer description, breaking changes, issues closed (for example `#123`), and affected packages. Use this repository's established emoji mappings when they differ from defaults: `feat: ✨`, `fix: 🐛`, `docs: 📝`, `chore: 🔧`, and `refactor: ♻️`. Keep commit text in English.

## Commit and push behavior

- **On any branch other than `master` or `main`, commit and push as soon as the work is written, without asking for confirmation.** On `master` or `main`, ask first.
- **Push over SSH first**: `git push origin <branch>` (`origin` is `git@github.com:ChenYilong/CYLTabBarController.git`). Use HTTPS with the `gh` credential helper only when SSH fails: its token has no `workflow` scope, so GitHub rejects any push that changes `.github/workflows/*` ("refusing to allow an OAuth App to create or update workflow").

## File hygiene before git commands

- **Never commit `._*` files.** macOS writes these AppleDouble metadata files next to every file on an external volume (for example, `._.claude`, `._.git`, `._.github`, `._.gitignore`, `._.pullapprove.yml`, `._ChatKit`). `.gitignore` excludes `._*`. Before git commands, delete them, including the ones in `.git/objects` (`._pack-*.idx` makes git report `non-monotonic index`):

  ```sh
  find . -name '._*' -not -path './.git/*' -delete
  find .git/objects -type f -name '._*' -delete
  git fsck --full
  ```

  Some were committed anyway: take them out of the repository with `git rm --cached` in a new commit; an unpushed commit that holds only them is undone instead. Rewriting pushed history needs a force push: ask first.

- **Never commit `*.lock` files** (`Podfile.lock`, `yarn.lock`, `pubspec.lock`, `Gemfile.lock`): `.gitignore` excludes `*.lock`. Gradle's `gradle.lockfile` (and `settings-gradle.lockfile`) does not end in `.lock` and stays committed. SonarCloud's "lock file is missing" findings (`text:S8564` package.json, `text:S8568` Gemfile, `text:S8571` pubspec.yaml) are therefore avoided by excluding those manifests in `.sonarcloud.properties` (`sonar.exclusions`; automatic analysis ignores `sonar.issue.ignore.*` there), never by committing a lock file.

## Before every commit: stale docs check

Before every commit, check `docs/` for stale notes: search every document in `docs/` (and `README.md`) for the keywords **`TODO`** and **`Linux`**, and for other notes left by an environment that could not run the code ("without Xcode", "no simulator", "no screenshots", `无法运行`, `没有截图`):

```sh
grep -rn -i -E "TODO|Linux|without Xcode|no (iOS )?simulator|no screenshots?|无法(编译|运行)|没有截图|暂无(测试)?截图" docs README.md
```

For each hit about a feature: test it (build, unit tests, run it on the simulator or emulator), then update the document with what was verified and the test screenshots (`docs/assets/`, layout as the `cyl-docs` skill says), and `README.md` when its section is affected. A finished TODO becomes DONE with its evidence; a TODO that only the maintainer can do (a repository setting, a release) stays, with what was checked and when. A bug found while testing is fixed in the same change. Details: the `cyl-docs` skill, "Stale notes before every commit".

## Branches, PRs, and merge

- Branch from the latest `master` for each issue or feature.
- **Every new branch gets a pull request, automatically (added 2026-11-12)**: after creating a branch and pushing its first commit, open a pull request right away, without asking. Target branch: the branch it was created from (preferred); otherwise `main` or `master`.
- Push early and open the pull request once the change is substantial; the PR body closes the issue (`Closes #N`).
- Before merging, squash the PR into a single commit and push with `--force-with-lease` (never a plain force push). On someone else's branch, merge `master` in instead of rebasing.
- After opening the PR, comment on the issue (in the issue's language) with the changes, the commit link, and an invitation to try the latest version.

## Commit body requirements

- Before every commit, review the changed scope and its issue, comparison, and implementation-status documents. Record each incomplete or unverified item in the commit under a `TODO` heading in the most relevant existing `docs/` document. State the current score or status, remaining work, implementation constraints, known defects, API design and compatibility risks, optimization opportunities, and verification required for completion. Reserved keys, stubs, and successful compilation alone are not completion evidence.
- The Conventional Commit subject summarizes completed work in English; put details and pending tasks in the body. If the detailed description exceeds 50 characters, create or update a suitable `docs/` note and link it in the commit body. Reuse existing trackers and avoid duplicate documents.

## Swift migration and translation work

- **Swift for the iOS core layer (added 2026-11-12)**: the core layer (`Core`, `CYLUtils`, `CYLBadgeView` subspecs) is being translated from Objective-C to Swift, bottom-up, keeping every Objective-C name (`@objc(name)`); third-party adapters and the examples stay unless a change is needed. Follow [../Swift-Coding-Style.md](../Swift-Coding-Style.md); record each step and the score of `python3 scripts/swift-migration-score.py` in [../Swift-Migration.md](../Swift-Migration.md) and in the commit body; continue until the score is 100 (no Objective-C left; macro-only headers count as compatible). **Examples bend, the core does not (added 2026-11-13)**: when the migration breaks an example's build, fix the example first; examples have the lowest priority and their code may change freely. Never keep a workaround, overload, kept name, or shim in the core only because an example uses it; the Swift coding style decides. The public API rule and kept Objective-C selectors still apply, for apps. Details: [../Swift-Coding-Style.md](../Swift-Coding-Style.md).
- **Upstream projects used for translation (added 2026-11-12)**: when a document of this project links to another project's GitHub repository that is the source of a translation or port (for example the projects ported to Kotlin in the Android folder), do not translate only its default branch. (1) Pull requests: visit the upstream's open pull requests and bring them in. If the translation has not started, merge the open pull requests into the source first; if it is already done, translate each open pull request's change and merge it into our port. (2) Issues: list the upstream's open issues in a table in the related document in `docs/` (create one when none fits): column 1 the issue link, column 2 its description, column 3 the fix status (`TODO` by default). Find each issue's counterpart in our code and try to fix it. (3) Score: 100 means every listed issue is resolved; give a score after each fix and continue until 100. (4) Order: for a translation not started yet, merge the open pull requests, fix issues until the score reaches 60, translate, then fix the remaining issues up to 100; for a finished translation, translate and merge the open pull requests, then fix the issues on the translated code up to 100. The same rule applies to every platform.

## Known risk areas and task tracking

- **`-[CYLPlusButton cyl_updateLiquidGlassMask]` is a known source of plus button bugs (added 2026-11-12)**: implement it only with great care. When any plus button bug shows up (missing, cut, offset, flickering), first disable this method (since step 52 of the Swift migration it is Swift and does nothing unless the Swift compilation condition `CYL_PLUS_BUTTON_LENS_MASK_ENABLED` is set; before, an Objective-C macro of that name set to 0 made its first line return) and test again, to rule it out before looking anywhere else. Known failure: on iOS 26 and later, Liquid Glass (not FlatDesign), with a plus button that has a plus child view controller, select the plus button, then drag the Liquid Glass lens to another item: the plus button is cut in two. The maintainer removed an earlier implementation because of this. Keep an implementation only after complete testing shows that dragging the lens never cuts the plus button (the drag UI tests in `Example-SwiftUI/HealthyHomeUITests`, recorded on video, raised and flat plus buttons), and that the plus button is never missing or offset on first display or when the plus tab is selected in code. **Same risk, to verify (added 2026-11-13, TODO)**: PR #793 keeps the Liquid Glass lens on the plus page when the plus button's title is drawn by its tab item (`-[CYLTabBarController cyl_plusButtonTitleIsDrawnByItsTabItem]`, switch `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_ENABLED`). The maintainer considers it as dangerous as the mask: verify it the same way, and on any plus button bug after selection turn both off first.
- **Record every task in `docs/` before starting it (added 2026-11-12)**: before any task, find the most relevant existing document in `docs/` (create one only when none fits) and add a `TODO` entry with the task's full context, the user's requirements, and the user's prompt quoted verbatim. Then start the work. When the task is finished, change that entry to `DONE` with the result and its evidence (commits, tests, screenshots). Purpose: if the work is interrupted, the next session can find the context again.
