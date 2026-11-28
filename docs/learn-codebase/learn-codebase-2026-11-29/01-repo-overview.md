# Repository overview and agent rules

> **UNVERIFIED.** Notes from a partial static reading on 2026-11-29; they were not re-checked against the code, and coverage is
> incomplete (see this folder's `README.md`). Later commits may have changed what is described, including the badge task's state.

Project: CYLTabBarController · exported 2026-11-29 for `claude-mem:learn-codebase`


## Agent rules (my summary after reading the root AGENTS.md in full)

I read all of the root `AGENTS.md` a moment ago. It's the short index of rules for any tool working in this repo, and the full text for each tag is in `docs/instructions/<tag>.md`.

**Always required**
- **`behavioral`:** read it in full before any task. Think first, keep it simple, change only what's needed and check the result.
- **`git`:** read it in full before any git operation.
- **`reply-greeting`:** start every reply with `Hi, <OS>/<folder>:`.

**How to work**
- **`task-workflow`:**
  - Check other sessions first and tell them which files you'll change. `Mac*` sessions take iOS; `Win*` sessions take the other platforms.
  - Start with a TODO list and the branch.
  - Save your prompt verbatim to memory with a 100 / 60 scoring rubric. Don't stop below 60, and say `DONE` only at 100.
- **`git`:**
  - Run `touch .git/hooks/NO_AUTO_SYNC` before each commit.
  - Write Commitizen messages in English with your author line.
  - On branches other than `master` or `main`, commit and push at the end of every turn without asking. Each branch needs an open pull request, but ask before opening another if more than two are already open.
  - Never commit `._*` or `*.lock` files.
- **`testing`:** verify before pushing and say what couldn't be verified.
- **`docs-lookup`:** don't scan the contents of every file in `docs/`. Read a document there in full only if you name it and ask, or authorize it.

**Code and docs**
- **`code`:** fix bugs in the core library, not just the example. Don't remove or change public APIs, don't introduce warnings, and write comments in English and Chinese. The iOS core is Swift first.
- **`documentation`:** new APIs, features, limits and demos must update `docs/`, `README.md` and the `cyl-*` skills in the same change.
- **`accessibility-localization`:** accessibility is required, and code can't contain Chinese string literals.
- **When they disagree:** code wins over `docs/`. Fix whichever is wrong in the same change.

**Topic rules** cover animated items, the plus button, badges, examples, React Native and Flutter, dependencies, macOS, Windows and HarmonyOS, and screenshots. The ones most relevant on Windows:
- Keep the HarmonyOS component and its example buildable, and build from an ASCII path.
- The local x86_64 emulator can't run Rive or PAG, which are arm64-only.

**One thing that differs:** some lines in the `git` doc can pull against each other. It says to commit and push at the end of every turn, but also to check `docs/` for stale notes and record unfinished work under a `TODO` heading before each commit. A small commit can therefore require documentation updates too.

I haven't opened the other tag docs apart from `behavioral` and `git`; I'll read them when a task calls for them. I didn't commit anything, since I haven't changed any files.

## State of the main checkout when first read

I'm now in the repo, on `feat/cross-platform-components`. I didn't fetch, so it's only level with `origin` as of the last fetch. I didn't change, commit or push anything.

**Latest commits:**
- `05448162` docs: tag-format `AGENTS.md`, docs-lookup and reply-greeting rules
- `e274dd7a` docs: progress 3 of the all-platform API score task
- `21b239ce` fix: define `CYL_ANIMATEDITEM_NOEXCEPT` before its use

**Uncommitted files (these were there before this request):**
- **Modified:** `package.json` and `package-lock.json` in `CrossPlatform/wechat-miniprogram-cyltabbar/example/`
- **Untracked:**
  - `CrossPlatform/harmonyos-cyltabbar/C`: the name looks like it was created by accident, but I haven't opened it
  - `CrossPlatform/react-native-cyltabbar/example/android/app/.cxx.longpath-old/`
  - `index.wxss` under `pages/message/` and `pages/publish/` in the Mini Program example

**Worktrees:** there are 29 besides this one. `C:/w/tbc-824` is on `feat/harmony-animated-item-engines-win` at `5958f8a3`, the merge that session notes list as pushed for the Android tag icon tint fix.

**Open to-do:** the saved `learn-codebase` task still shows as in progress. Its note says it's read-only: don't touch the modified files or commit. It mentions 4 modified files, but only 2 show as modified now, so the note may be out of date.

I've now read the `behavioral` and `git` docs in full, as the repo requires. I ran my first `git status` and `git log` before reading them; both commands only read the repo.

What would you like to do here?

## Observations (6)

> The entries under "Observations" are copied verbatim from claude-mem. They are its automatic summaries of what was read; I have not re-checked each one against the source. No build or test was run during the learn-codebase read.

### #200 — Mac CYLTabBarController session notified of pushed merge 5958f8a3 (GitHub)
change · 2026-11-27 12:15 UTC
The Windows side told the Mac session that 5958f8a3 merges its 6baaf74e and c5996d7a and asked it to merge origin before its next push.

The Mac-side CYLTabBarController session was notified that the Windows side pushed a merge commit, 5958f8a3, which incorporates its two recent commits, 6baaf74e and c5996d7a. The message explains that the only doc conflicts were table rows and that they were resolved by keeping rows from both branches. It also records that the iOS parity work was queued and that the Android and HarmonyOS batches are now on the shared branch. Because the Remote Control route reports no read receipt, the Mac session may not have seen the message yet.

- Commit 5958f8a3 on feat/harmony-animated-item-engines merges Mac-side commits 6baaf74e and c5996d7a.
- Two docs table conflicts were resolved by keeping rows from both sides, plus the newer HarmonyOS GIF row.
- No iOS files were touched in the Windows merge.
- The Mac session was told that e13c9023 holds the Android static-image automatic tint, which is the iOS parity request queued for after its badge groups.
- The Mac session was told that 8f461edd holds the HarmonyOS, mini program, and API-map batch.
- The Mac session was asked to merge origin/feat/harmony-animated-item-engines before its next push to avoid a non-fast-forward conflict.
- The message was sent with a message id over Remote Control, and the route gives no read receipt, so delivery is unconfirmed.

Concepts: what-changed, trade-off

---

### #205 — CYLTabBarController core branch carries 20 commits and 40 changed files since d5f1b436 (GitHub)
discovery · 2026-11-27 12:15 UTC
Fetching feat/harmony-animated-item-engines shows the new pin 5958f8a3 bundles static-image tint, Harmony colour roles, badge docs and API maps.

The session fetched the Harmony animated-item engines branch of CYLTabBarController and listed everything between the currently pinned d5f1b436 and the candidate 5958f8a3. The new commit range is large: it mixes code fixes for static-image tint and icon alignment with a set of CYLBadge design and naming documents. The Android consumer currently pins d5f1b436 through gradle.properties, so the repin will pull in all 40 changed files, not only the tint fix. This scope matters for the all-platform repin.

- origin/feat/harmony-animated-item-engines resolves to commit 5958f8a3df75f1c3af34fc72e7849e76e9a07eb3 in the CYLTabBarController checkout at C:\w\CYLTabBarController.
- Commits from d5f1b436..5958f8a3 include e13c9023 (one-colour static images follow automatic tint) and 8f461edd (HarmonyOS colour roles, GIF tab kind, flat D2, API maps).
- The range also includes CYLBadge design and documentation commits (dc1e4c11, 7dd1b817, 3cb33902, 80ed54dd, 26ab64a2, d1c4a1a8), the CYLUtils lifecycle decision (4ee6e49e), and naming decisions (25fffb3d, dd97b824, b3cfda27).
- Functional commits include 6cba553b (animated item icon aligns by the icon, not its badge), 0844babf (noteAnimationRestart() raises the restart token for subclasses), and 6baaf74e (badge tag icon centred; FlatDesign normal title follows dark mode).
- The diff from d5f1b436 to 5958f8a3 touches 40 files: 2275 insertions and 147 deletions.
- Android changes include CYLAnimatedItemView.kt, the new CYLAnimationColorCount.kt, and CYLAnimatedItemStaticImageTintTest.kt (122 added lines).
- Harmony changes include CYLAnimatedItemColorResolver.ets, CYLAnimatedItemView.ets, CYLTabBarController.ets, and the CYLAnimatedItemFlatContrast.test.ets rewrite.
- The Android consumer pin lives in android/merged/gradle.properties as cyl.tabbar.commit=d5f1b436e112fb88761d99177f294e2155be98ea, with cyl.tabbar.localPath=../../../CYLTabBarController.

Files read: CYLTabBarController/.agents/skills/cyl-naming/SKILL.md, CYLTabBarController/docs/Animated-Item-Badge.md, CYLTabBarController/docs/Animated-Item-Badge-CrossPlatform.md, android/merged/gradle.properties

Concepts: what-changed, trade-off

---

### #219 — CYLTabBarController main checkout state and worktree layout inventoried (GitHub)
discovery · 2026-11-28 11:38 UTC
Git status and worktree list were read for the CYLTabBarController repo on Windows, showing the active branch, uncommitted edits, and about 30 worktrees.

The git status, recent log, and worktree list were read for the CYLTabBarController repository on Windows. The main checkout sits on feat/cross-platform-components with uncommitted edits to the WeChat miniprogram example package files and several untracked artifacts, including a truncated HarmonyOS path and an old Android .cxx build directory. The repository uses many parallel worktrees, mostly detached, which hold per-task branches for Android, HarmonyOS, miniprogram, and React Native work. The tbc-824 worktree at 5958f8a3 is the one carrying the merged harmony animated-item engines used for the Android tag icon fix. This state matters for later work because pins and merges in other worktrees depend on these commits and branches.

- The CYLTabBarController main checkout at <repository root> is on branch feat/cross-platform-components, tracking origin/feat/cross-platform-components, at commit 05448162.
- The main checkout has uncommitted modifications to CrossPlatform/wechat-miniprogram-cyltabbar/example/package-lock.json and CrossPlatform/wechat-miniprogram-cyltabbar/example/package.json.
- The main checkout has untracked paths: CrossPlatform/harmonyos-cyltabbar/C (output truncated), CrossPlatform/react-native-cyltabbar/example/android/app/.cxx.longpath-old/, and two WeChat miniprogram example wxss files under pages/message and pages/publish.
- Most recent commits on feat/cross-platform-components are 05448162 (tag-format AGENTS.md, docs-lookup and reply-greeting rules), e274dd7a (progress on the all-platform API score task), and 21b239ce (fix: define CYL_ANIMATEDITEM_NOEXCEPT before its use).
- Git worktree list shows about 30 worktrees under C:/w/, C:/cyl-*, and C:/cylsync/, mostly in detached HEAD state, with the tbc-824 worktree on feat/harmony-animated-item-engines-win at 5958f8a3.
- Named worktree branches include fix/animated-item-item-style, win-mp-guard, win-content-inset, win-arkts-fix, win-arkts-223, fix/android-animated-playback, feat/glass-backdrop-source, and feat/android-rive-dark.

Files read: CrossPlatform/wechat-miniprogram-cyltabbar/example/package.json, CrossPlatform/wechat-miniprogram-cyltabbar/example/package-lock.json

Concepts: how-it-works, pattern

---

### #230 — CYLTabBarController source layout and largest files inventoried (GitHub)
discovery · 2026-11-28 11:41 UTC
Line and byte counts across tracked source files show where the animation, badge, and flat-design logic concentrates.

This inventory of tracked source files in the CYLTabBarController repository shows the codebase's shape. The Swift animated-item view and the main Objective-C header are the largest single files, and flat-design and animation engine logic are each split across several files. Animation backends are isolated per library, and badge support has its own Swift and deprecated-name layers. Nine GitHub workflows cover Android, iOS, docs, release, and miniprogram checks. The repo also carries local agent skill scripts. No files were modified.

- CYLTabBarController/CYLAnimatedItem/Swift/CYLAnimatedItemView.swift is the largest tracked source file at 1478 lines and 82254 bytes.
- CYLTabBarController/CYLTabBarController.h is 1185 lines and 85035 bytes, the largest Objective-C header.
- CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationEngine.m is 769 lines, the largest animation engine implementation.
- Flat-design tab bar logic is concentrated in CYLFlatDesignTabBar+CYLImplementation.swift at 854 lines and CYLTabBarController+CYLFlatDesign.swift at 905 lines.
- Tab animation backends are split into per-library directories: GIF, Lottie, PAG, Rive, and SVGA, each with an Objective-C or Swift animator pair.
- Badge support lives in CYLTabBarController/CYLBadgeView with Objective-C headers and Swift extensions, plus a Deprecated/ subfolder that maps old API names.
- Repository CI is defined by nine root .github/workflows files: android, animation-tests, docs-navigation, ios, plus-child-theme-test, release, scroll-hide-self-test, theme-screenshots, and wechat-miniprogram.
- The repo also vendors .agents/skills and an ios-simulator-skill directory of Python and shell scripts, including hang_watcher.py at 1533 lines.

Files read: CYLTabBarController/CYLAnimatedItem/Swift/CYLAnimatedItemView.swift, CYLTabBarController/CYLTabBarController.h, CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationEngine.m, CYLTabBarController/CYLFlatDesignTabBar/Swift/CYLFlatDesignTabBar+CYLImplementation.swift, .github/workflows/ios.yml

Concepts: how-it-works, pattern

---

### #231 — CYLTabBarController tracked-source size totals by directory (GitHub)
discovery · 2026-11-28 11:41 UTC
Aggregated line and byte counts show .agents/skills holds the most tracked source bytes, ahead of the tab bar library directories.

An aggregation script grouped the CYLTabBarController repository's tracked source files by top-level directory and summed their line and byte counts. The first pass of the script failed on a regex mismatch, and a second pass that skipped unmatched lines completed. The listing was capped at 200 results, so the totals are a partial view. Within the capped set, the bundled agent skill scripts take the most bytes, while the flat-design, animation, and badge library directories are the largest product-code groups. No files were modified.

- The size aggregate covers 200 tracked source files totaling 39779 lines and about 1.82 MB, but the listing was capped at 200 results, so the totals may be incomplete.
- The .agents/skills directory holds 49 files, 17670 lines, and 618840 bytes, making it the largest tracked area by bytes.
- CYLTabBarController/CYLUtils holds 36 files with 3267 lines and 177100 bytes.
- CYLTabBarController/CYLBadgeView holds 22 files with 4048 lines and 198156 bytes.
- CYLTabBarController/CYLFlatDesignTabBar holds 26 files with 4385 lines and 237613 bytes.
- CYLTabBarController/CYLTabBarItemAnimation holds 26 files with 4404 lines and 231151 bytes.
- CYLTabBarController/CYLAnimatedItem holds 6 files with 2275 lines and 126125 bytes.
- The .github/workflows directory holds 9 files with 833 lines and 38808 bytes.

Files read: .agents/skills, CYLTabBarController/CYLFlatDesignTabBar, CYLTabBarController/CYLTabBarItemAnimation, CYLTabBarController/CYLBadgeView, .github/workflows

Concepts: how-it-works, gotcha

---

### #307 — learn-codebase CYLTabBarController pass scoped to read-only with a 60/100 rubric and checkpointed (GitHub)
decision · 2026-11-28 11:53 UTC
The learn-codebase work state for CYLTabBarController records the scoring rubric, read-only rule, remaining size estimates, and a paused checkpoint.

The learn-codebase pass over CYLTabBarController is structured as a read-only survey with a numeric rubric: 60 points for reading all library source, 100 for also covering tests, examples, scripts, workflows, and the report. The work state records the size of each remaining group so the remaining effort can be planned by character count. The pass has been paused after the public headers so the owner can review the size estimates before the larger ios-core and android-libs groups are queued. The next step is to queue ios-core in roughly 28k-character chunks, adding the missing config and manifest files to the inventory first.

- The learn-codebase-cyltabbar work state targets repo CYLTabBarController on branch feat/cross-platform-components at commit 05448162.
- The rubric scores 60 when all library source is read in full (iOS core, Android libs, HarmonyOS libs, miniprogram source, RN and Flutter wrappers) and 100 when tests, examples, scripts, workflows, and the report are also covered.
- The rule for this pass is read-only: no edits and no commits, and dirty files are left in place.
- Excluded from reading are miniprogram_dist bundles, third-party .agents skill scripts, docs/*.md under the docs-lookup rule, and assets, lockfiles, JSON data, strings, and pbxproj files.
- Remaining estimates by group are tests-examples-scripts at 2,749,446 chars, ios-core at 2,433,181 chars, android-libs at 1,213,001 chars, harmony-libs at 451,299 chars, miniprogram-src at 238,916 chars, and rn-flutter at 129,059 chars.
- Reading is chunked at about 28k characters per call, with [CN] comment lines and docs-binding blocks stripped first.
- Before queuing ios-core, the plan adds files missing from the first inventory: json5, AndroidManifest, CMake, modulemap, library package.json, MP component json, gradle properties and toml, proguard, and attrs.xml.
- The plan drops mode 120000 symlinks and duplicate blob SHAs, and it checks whether lottie-miniprogram and similar packages are vendored upstream.
- The pass is checkpointed as paused after public headers so the size could be reported to the owner, and the 60-point line has not been reached.

Concepts: trade-off
