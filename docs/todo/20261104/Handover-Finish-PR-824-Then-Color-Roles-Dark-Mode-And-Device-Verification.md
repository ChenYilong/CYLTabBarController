# Handover (week 4 of November 2026): get PR #824 green, then colour roles, dark-mode bar background and on-device verification of the non-iOS platforms

Written on 2026-11-26 by the departing developer (working with Claude sessions). Everything in this file is in English on purpose.
Scope of my own work in this period: the non-iOS platforms (Android, HarmonyOS, WeChat mini program, React Native, Flutter) of the shared item module `cylanimateditem` and of the tab bar. The iOS side was done by the macOS sessions and is only listed where it blocks a non-iOS item.

Repository: https://github.com/ChenYilong/CYLTabBarController
Working branch (PR #824, open): https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmony-animated-item-engines

---

## 0. What you do first (in this order)

1. **Make PR #824 green.** One check fails: `check` / "Check the navigation": `docs/Dark-Mode-Adaptation.md` lacked the `<!-- bound-classes: ... -->` line. It is fixed in the commit that adds this handover, but you must run `py -3 scripts/update-docs-navigation.py` (it regenerates the navigation, binding and folder-tree blocks, including this new `docs/todo/` folder) and push, then watch the checks. The other checks of #824 were still pending when I wrote this (Carthage, 11 demo builds, framework build, unit tests, pod lib lint).
2. **Ask the owner for the four undecided product questions in section 4** (static icon default tint, unselected icon tint, dark-mode bar background, dark glass brightness). Nothing below marked "owner decision" may be implemented before they answer.
3. **Run the one combined on-device test batch** that the owner's rule requires ("write the code statically, then test once"): the list is in section 3, row "Device batch". Several fixes below are unit-tested only.
4. **Colour-roles refactor** (Android first, then HarmonyOS and mini program): design in section 3.
5. **Repin the vendored ClassifyMenu** when its Windows integration SHA arrives (`CrossPlatform/harmonyos-cyltabbar/classifymenu.pin`, currently `a40c4ee4cf9ebd44ea75aacd62d15154801e9e7e`).

---

## 1. Project score and distance to the release standard

**Honest status of this section: the owner asked for the advisor (the stronger reviewer model) to score the project. The advisor tool was rate-limited when I tried, so the numbers below are MY OWN estimate (the author, which is biased upwards), not the advisor's. Re-run the scoring with the advisor as your first review task and replace this section.**

Release standard I used: PR #788 (base of all work) merges to master and a release is cut with: every non-iOS platform builds and passes its unit tests; each platform's documented features verified on a device or emulator; CI and SonarCloud green; no open Critical/Major defect; docs bilingual and navigation-checked; owner decisions closed.

| Area | Score / 100 | Missing points (why not higher) |
|---|---|---|
| Android core (tab bar + item) | 82 | Unit tests (295 item + 151 tab bar) and lint are green, but the double-sheen fix, the More-icon fix and the last-frame fix were not all re-measured on a device; static-icon default tint undecided; dark bar background undecided. |
| HarmonyOS | 76 | Fill-SVG and icon-rendering-mode fixes measured only on the classic bar page; fill+stroke SVG and original mode untested on device; system-level dark switch untested; x86_64 emulator has no Rive/PAG; emulator keeps disappearing; hypium install script path mangling needs manual install. |
| WeChat mini program | 70 | Contrast floor 0.37 is calculated from CSS, never measured in WeChat DevTools/WebView; Rive B20 (plays once) and a stray clipped text bug open; playback controls row not started. |
| React Native | 65 | Parity work exists, but the last-frame option (`showsImageWhenAnimationEnds`) parity and device runs were not redone in this period; no new verification by me. |
| Flutter | 65 | Same as RN; plus-button title disappearing could not be reproduced (B3); bar stays light in dark mode by example config. |
| Cross-platform parity of the item API (colour roles, one animation policy) | 60 | Colour-roles refactor not started; animation policy (Automatic with one-colour detection) only on iOS; Android/HarmonyOS/mini have partial ports. |
| CI / Sonar / docs | 75 | #824 `check` failing (navigation), 50 of 135 non-iOS Sonar issues still open (2 are ArkTS `Array.at` that the compiler rejects), many task-log rows still "DONE static, untested". |
| **Overall (non-iOS)** | **~70** | |
| **Distance to release** | **~55-60** | Open owner decisions (4), the device batch, colour roles, CI green, #788 review and merge chain (#823, #813, #824 merge into `feat/cross-platform-components` first). |

The scoring method for the task log is described in `docs/instructions/task-workflow.md`: be honest, 100 means done and verified.

---

## 2. Branches (table 1)

Base chain: #788 `feat/cross-platform-components` -> `master`; #823, #813 and #824 -> `feat/cross-platform-components`. The progress percentage is my estimate of how close the branch is to merging. All links are `https://github.com/ChenYilong/CYLTabBarController/tree/<branch>`.

### 2a. Open pull requests and branches that ride with them

| Branch (link) | Progress | TODO items |
|---|---|---|
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/cross-platform-components (PR #788 -> master) | 90% | Wait for #823, #813, #824 to merge into it; final CI/Sonar green; owner review; then the release (section 0). It is the umbrella of all RN/Flutter/Android/HarmonyOS/mini program work. |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmony-animated-item-engines (PR #824 -> #788's branch) | 85% | Fix the failing navigation check (section 0); get the pending checks green; run the device batch (section 3); resolve owner decisions (section 4); colour-roles refactor; Sonar leftovers; repin ClassifyMenu; update the task log rows still IN PROGRESS in `docs/Animated-Item.md`. |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/dealloc-block-executor-dependency (PR #823, draft until 1.4.0) | 85% | Keep as a draft until release 1.4.0; its last commit keeps the Xcode project change to the pin line only; merge after 1.4.0 is published. |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/firebase-remote-config (PR #813) | 80% | Step 1 only (iOS and Android cores without Firebase); the later steps (the Firebase wiring) are not started; last commit 2026-11-20 (Sonar complexity of `scripts/remote-config.py`). Needs the owner's go-ahead for step 2. |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/glass-backdrop-source (no PR; tip already inside #824) | 100% | Nothing to merge separately; delete after #824 merges. Documents `itemGlassBackdropSource` (no effect below Android 12). |
| https://github.com/ChenYilong/CYLTabBarController/tree/refactor/item-color-roles (no PR; tip inside #824) | 40% | iOS side reference of the colour-roles refactor (tip `3013b646`, tests for roles); Android/HarmonyOS/mini ports not started (section 3). Read `docs/Animated-Item.md` task log and the iOS files first. |
| https://github.com/ChenYilong/CYLTabBarController/tree/tmp-none (no PR; tip inside #824) | n/a | Throwaway; delete after confirming nothing unique (last commit "two compiler warnings"). |

### 2b. Merged branches (can be deleted from the remote after the owner agrees)

All merged through pull requests; their tips are inside #788's branch unless noted. TODO for every row: delete the remote branch (owner decision; no code work).

| Branch (link) | Progress | TODO items |
|---|---|---|
| https://github.com/ChenYilong/CYLTabBarController/tree/claude/cylanimateditemview-countdown-lha9jq (#821) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/docs/miniprogram-rive-loop-todo (#820) | 100% | delete; its B20 bug is still open (section 6) |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/animated-item-miniprogram-playback (#815) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmonyos-animated-item-icon-color (#816) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmonyos-launch-options (#811) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/android-lottie-merge-paths (#819) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/animated-item-item-style (#822) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/harmonyos-badge-border-width (#805) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/harmonyos-liquid-badge (#810) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/harmonyos-nav-title (#809) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/miniprogram-engines-fill-box (#817) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/lottie-unplayable-file (#814) | 100% | merged per the PR, but the tip is not an ancestor (squash or rebase): verify nothing is lost, then delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/miniprogram-lottie-reload-loop (#818) | 100% | same caveat as above, verify then delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmonyos-flatdesign-item (#802) | 100% | merged into a since-deleted intermediate branch; tip is inside #788's branch; delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/harmonyos-screenshot-issues (#803) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/harmonyos-screenshot-issues-followup (#804) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/harmonyos-screenshot-issues-round2 (#806) | 100% | delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/docs/harmonyos-emulator-screenshots (#798) | 100% | merged into an old intermediate branch; tip not in #788's branch: verify the screenshots live somewhere, then delete |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmonyos-demo-7-flatdesign (#797) | 100% | same as above |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmonyos-flatdesign-api (#799) | 100% | same as above |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmonyos-plus-button-configuration (#796) | 100% | same as above |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmonyos-svga (#800 merged, #807 closed duplicate) | 100% | same as above |

### 2c. Stale branch

| Branch (link) | Progress | TODO items |
|---|---|---|
| https://github.com/ChenYilong/CYLTabBarController/tree/fix/flutter-plus-title-hidden (PR #793 closed unmerged, its base `fix/flutter-viewpager2` no longer exists) | unknown | Decide with the owner: compare with #788's branch for the Flutter plus-button-title fix and the react-native-cyltabbar `viewpager2` commit; port or delete. Related open item: Flutter plus title disappearing could not be reproduced (TODO-Sweep B3). |

---

## 3. All open TODO items (grouped)

Sources: `docs/TODO-Sweep.md`, `docs/Animated-Item.md` (task log and TODO sections), `docs/HarmonyOS-Issues.md`, `docs/Dark-Mode-Adaptation.md`, the owner's chat directives. "Mac" means it needs a Mac and simulator (iOS); everything else I did on Windows.

### 3.1 Non-iOS work (my area)

| # | Item | Platform | Where recorded | State |
|---|---|---|---|---|
| T1 | **Device batch** (the single combined test run the owner asked for): re-measure on emulator the Android double-sheen fix (`ebd60e9b`), the last-frame fix (`62ab96d3`, `b5b36fbf`), the More-icon tint (`af56db22`, unit-tested only), the Android tab icon alpha normalisation (`d19e138e`); HarmonyOS: original-mode icon stays coloured, SVG with fill AND stroke, system-level dark switch; mini program: contrast floor in WeChat DevTools. | Android, HarmonyOS, mini | this file, `docs/Animated-Item.md` rows 56, 76-79, 81 ("DONE static, untested") | not run |
| T2 | **Colour-roles refactor**: roles (id, kind, extractor, built-in colour per state, apply hook), `register`/`setSubclassColor`/`applyBuiltInColor`, ONE resolver with single adaptation, ONE `refreshColors()`, `adaptedForContrast`, `contrastApplies`/`contrastReferenceLuminance`, flat-fill rule, limits in API comments; plus ONE animation policy (Automatic) with Lottie one-colour detection (`fl`/`st` +-2/255) on Android, HarmonyOS, mini program with tests. iOS reference: branch `refactor/item-color-roles` and the iOS item files; precedence today: own > subclass-explicit > stack > subclass built-in > component built-in. Android first, then the other two (two SHAs are fine). | Android, HarmonyOS, mini | owner chat; `docs/Animated-Item.md` | not started |
| T3 | Repin ClassifyMenu (separate repo, vendors `cylanimateditem`) to the newest tab bar SHA when its session sends the Windows integration SHA; ClassifyMenu must pin a SHA that contains `b5b36fbf` (Lottie last frame) and `d19e138e`/`af56db22`/`53372bce` (tab icon tint). | Android, HarmonyOS, mini | `classifymenu.pin` | waiting for peer |
| T4 | Sonar: 85 of 135 non-iOS issues fixed. Left: two S7755 (`Array.at`) that ArkTS rejects (revert was deliberate, keep them open or suppress with a justification) and the rest of the 135. | HarmonyOS + others | `docs/Animated-Item.md` row 67 | open |
| T5 | Task-log rows still IN PROGRESS: 65, 70, 71 (0/100), 66 (70), 67 (80), 68 (80), 87 (80: `showsImageWhenAnimationEnds` parity on iOS, RN, Flutter), 105-107 (x86_64 emulator, Rive/PAG: 83, 90, 95). Close or update them honestly after T1. | all | `docs/Animated-Item.md` | open |
| T6 | Mini program example controls via `cyl_player()`, GIF end event, cyl-rive `#` option test (row 88). | mini | `docs/Animated-Item.md` row 88 | 0% |
| T7 | Playback controls on every platform for iOS Lottie, Android, RN, Flutter, HarmonyOS (TODO-Sweep E1). | multi | `docs/TODO-Sweep.md` | needs runs |
| T8 | HarmonyOS NEXT support, Liquid Glass tab bar, API map (1,407 symbols); stated score 0/100 on 2026-11-14 (older entry; the platform has progressed far since, update the number). | HarmonyOS | `docs/TODO-Sweep.md` F1, `docs/HarmonyOS-API-Map.md` | stale score |
| T9 | HarmonyOS issue #29 of CollectionViewClassifyMenu: crash in `libohos_rive.so` on the animations page; fix is in, waiting for a simulator screenshot. | HarmonyOS | `docs/HarmonyOS-Issues.md` | needs screenshot |
| T10 | Adopt `cylanimateditemrive` in CYLSearchViewController, CYLTableViewPlaceHolder and CollectionViewClassifyMenu (done when each one's Loop switch works on an unselected tag). | HarmonyOS, Android, mini | `docs/Animated-Item.md` line ~601 | open |
| T11 | Android/HarmonyOS API maps must be regenerated after API changes: `py -3 scripts/android-api-map.py` then `--check`; `scripts/harmonyos-api-map.py`. | Android, HarmonyOS | scripts | do after every API change |
| T12 | Android upstream PRs/issues of the projects ported to Kotlin (TODO-Sweep A5): needs network access to the upstream repositories. | Android | `docs/TODO-Sweep.md`, `docs/Android-Library.md` | open |
| T13 | Optionally publish a `release-ram.ps1` fix review: the script now matches the Huawei emulator by path; never use `taskkill //IM emulator.exe` (case-insensitive, it also kills `Emulator.exe` of DevEco). | tooling | `docs/Release-RAM.md` | done, keep the rule |

### 3.2 iOS items that block or touch non-iOS work (Mac session needed)

| # | Item | Where recorded |
|---|---|---|
| I1 | Swift migration of the iOS core 41/100 (A1) and SVGA in Core 0/100 (A7) | `docs/TODO-Sweep.md`, `docs/Swift-Migration.md`, `docs/SVGA-Animation.md` |
| I2 | Simulator-only checks B1-B6 (theme and config edge cases, Liquid Glass plus button, iPad landscape #561, tab long-press freeze #781, five unconfirmed screenshot items) | `docs/TODO-Sweep.md` |
| I3 | C1 real-device checks (placeholder screenshots, haptics, mini program on a phone); D1 make CI checks required on master and replace the CocoaPods trunk token that appeared in a chat; D2 after the next release check the xcframework zip and run `carthage update` | `docs/TODO-Sweep.md`, `docs/Mac-CI-CD.md`, `docs/Carthage-Example.md` |
| I4 | Tag lists on iOS `Example/` and `Example-Swift/` need a Podfile pin to CollectionViewClassifyMenu (owner decision); new example strings "Default tint" / "Animation tint" are English only, not in the 33 locales | `docs/Animated-Item.md` line ~598 |
| I5 | CYLTableViewPlaceHolder integration issues 1, 2, 4, 5 (refresh icon overlaps text; Rive refresh shows a rectangle; PAG refresh icon static; GIF icon overlaps "Loading..." on the Me page) | `docs/CYLTableViewPlaceHolder-Integration-Issues.md` |
| I6 | 34 open GitHub issues (maintainer priority tier 1: #658, #671, #646; also #779); #787 static-icon tint is an owner decision | https://github.com/ChenYilong/CYLTabBarController/issues |

---

## 4. Decisions the owner has NOT made (do not implement before an answer)

| # | Question | Options | My recommendation |
|---|---|---|---|
| D1 | Should a static tab icon tint by default when no rendering mode is set (#787)? Today (tint spec v2): opt-in; an unset mode tints only with an explicit icon colour. The Search example hit this (black icons) and wants a core default. | (a) keep opt-in and have examples set `CYLTabBarControllerIconRenderingMode: "template"` (Android/HarmonyOS keys exist), (b) tint by default (turns every coloured icon into a silhouette), (c) tint by default only icons detected as ONE colour (like the animation rule; needs new detection code) | (a) now, (c) as a follow-up |
| D2 | Flat style: should unselected icons without an icon colour take `unselectedTintColor` (iOS flat tints both states)? | keep original colours / tint with unselectedTintColor / set `CYLTabBarItemIconColor` in the shared configuration | keep, document |
| D3 | Dark mode: must the tab bar background follow dark mode (the owner said YES, but not today). Open: does the core give a dark default for an unset bar background, or must every example/config set `CYLTabBarBackgroundColor` with a dark theme pair, per platform (Android, HarmonyOS, Flutter, iOS, mini)? Evidence and screenshots: `docs/Dark-Mode-Adaptation.md`. | core default vs per-example config | per-example config first (the Android demo already shows `#1C1C1E`), core default later |
| D4 | Dark glass brightness: Harmony tint 0.12 would match iOS (Y~42) but shrinks the margin to the contrast floor 0.40 to 0.02; Android reaches only ~Y35. Floors stay unchanged until decided (Android 0.37, Harmony 0.40, mini 0.37). | raise tint / leave | leave until the device batch (T1) |
| D5 | ClassifyMenu Podfile pin for the iOS tag-list examples (I4); firebase step 2 go-ahead (#813); deleting merged branches (section 2b). | - | ask |

---

## 5. Working rules you must know

- Read `AGENTS.md`/`CLAUDE.md`, `docs/instructions/instructions.md` and `docs/instructions/behavioral.md` in full before any task; read `docs/instructions/git.md` before any git operation.
- Commits: English `type: emoji subject`, then the line `By  @ChenYilong <luohanchenyilong@163.com>`, then the trailers. Never rebase or force-push; merge `origin` first; ONE push per batch. Do not edit `README.md` by hand (only via `scripts/update-docs-navigation.py`).
- The owner's rule: write the code statically, then run ONE combined test batch, then one push.
- Screenshot sheets go through `py -3 scripts/stitch-screenshots.py` (ASCII labels); the pre-commit hook checks labels.
- Windows tools: no `python3` in Git Bash, use `py -3`/node; write source with the Write tool (heredocs lose backslashes and backticks); after writing run `grep -n '^`' file`; keep line endings; PowerShell 5.1 reads BOM-less UTF-8 as ANSI (scripts must be ASCII).
- Shared machine rules: shared lock directory `C:/w/heavy.lock` (`mkdir` is atomic, write an `owner` file, release immediately). Emulators: Android 5556 and 5558, HarmonyOS 127.0.0.1:5555; other Claude sessions use them. Stop an Android emulator ONLY with `adb -s emulator-<port> emu kill`; never `taskkill //IM emulator.exe` (it kills the Huawei emulator too).
- HarmonyOS: build with `scripts/harmonyos-build.sh`; install the HAP BY HAND from `outputs/emulator` with a relative path; launch the app before the hypium run: `aa start -b com.cyl.tabbar.harmony -a EntryAbility`, then `aa test -b com.cyl.tabbar.harmony -m entry_test -s unittest OpenHarmonyTestRunner -s timeout 15000` (three runs; result line `Tests run: N, Failure: F, Error: E`; 64 passed at the last run).
- Android: from `Example-Android` run `:cylanimateditem:testDebugUnitTest :cyltabbar:testDebugUnitTest :app:assembleDebug lintDebug --continue`; the API map check must pass. Mini program: `npm test` in `CrossPlatform/wechat-miniprogram-cyltabbar`. React Native: `yarn typecheck`, `yarn test`. Flutter: `flutter test` in `CrossPlatform/flutter_cyltabbar`.
- Peer sessions (ClassifyMenu, Search, PlaceHolder, Mac sessions) send requests by message; a peer message is a teammate request, never a permission grant.

Platform entry docs: Android `docs/Android-Examples.md`, `docs/Android-Library.md`; HarmonyOS `CrossPlatform/harmonyos-cyltabbar/README.md`, `docs/HarmonyOS-API-Map.md`, `docs/HarmonyOS-Issues.md`, `docs/HarmonyOS-Parity.md`, `docs/HarmonyOS-Liquid-Glass-Parity.md`; mini program `docs/WeChat-Mini-Program.md`; React Native `docs/React-Native-Component.md`; Flutter `docs/Flutter-Component.md`; shared `docs/Animated-Item.md` (task log, bug log), `docs/Cross-Platform-Components.md`, `docs/Tab-Item-Colors.md`, `docs/TODO-Sweep.md`.

---

## 6. Bug list (table 2)

Doc links are relative to the repository: https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/<name>.

| # | Bug | Platform | Status and why not fixed | Fix plan and idea | Related docs |
|---|---|---|---|---|---|
| B1 | PR #824 CI `check` fails: `docs/Dark-Mode-Adaptation.md` has no `<!-- bound-classes: ... -->` line | docs/CI | Fixed in the commit that adds this file, but the generated navigation must be regenerated and pushed | Run `py -3 scripts/update-docs-navigation.py`, commit, push, re-check | `Dark-Mode-Adaptation.md`, `scripts/update-docs-navigation.py` |
| B2 | Tab bar does not follow dark mode (bar stays light on Android Search/Flutter examples; Harmony flat bar mid-grey `#949494`, unselected titles and untinted icons almost invisible) | Android, HarmonyOS, Flutter | Not fixed: the owner said it must be done but not now; core-default vs per-example config undecided (D3) | After D3: add `CYLTabBarBackgroundColor` with dark theme pair to the examples (the Android demo shows `#1C1C1E` already); test HarmonyOS with the system-level switch; iOS/mini checked too | `Dark-Mode-Adaptation.md`, `Tab-Item-Colors.md` |
| B3 | Static tab icons stay black/original when no rendering mode is set | Android, HarmonyOS (all) | Not a defect by tint spec v2 (#787); default undecided (D1) | If the owner picks (c): implement one-colour detection for bitmaps and SVG, apply the animation-rule precedence, add tests | `Tab-Item-Colors.md`, issue #787 |
| B4 | Flat style: unselected icons without icon colour keep original colours | Android, HarmonyOS | Undecided (D2) | If chosen: tint with `unselectedTintColor` in `iconColor()` (Android `CYLTabBar.kt`) and `cylStaticIconTintColor` (HarmonyOS) | `Tab-Item-Colors.md` |
| B5 | Translucent selected icons were 60% opaque on Android | Android | FIXED `d19e138e` (alpha normalised in `CYLTabIconTint.kt`); device-measured on 5556 | Keep; watch vector drawables | `Tab-Item-Colors.md` |
| B6 | Android "More" overflow icon never tinted | Android | FIXED `af56db22` (More item is a template icon); unit-tested only, not device-measured | Include in the device batch T1 | `Tab-Item-Colors.md` |
| B7 | HarmonyOS template icons did not tint (no icon rendering mode) | HarmonyOS | FIXED `d19e138e`; measured on emulator on the classic bar page | Test other bar styles and original mode on device | `Tab-Item-Colors.md` |
| B8 | HarmonyOS fill-based SVG icons ignored the colour filter | HarmonyOS | FIXED `53372bce` (`fillColor` added); fill+stroke SVG not tested | Device test of an SVG with both fill and stroke | `Tab-Item-Colors.md` |
| B9 | Selected Lottie tag showed the house outline instead of the last frame on the real ClassifyMenu example | Android | FIXED `b5b36fbf` (setter keeps the last frame when selected and the option is on); confirmed by the ClassifyMenu session (arrow shown) | Keep the test `CYLAnimatedItemLastFrameTest` | `Animated-Item.md` |
| B10 | Android tag drew its own board sheen twice (double sheen), top tags below contrast 4.5 | Android | FIXED `ebd60e9b` (board draws edgeless in backdrop); NOT re-measured on a device afterwards | Re-measure the `#3C3C43` contrast on the dark Configuration page (T1) | `Android-Liquid-Glass.md`, `Animated-Item.md` |
| B11 | Contrast floor of the mini program is calculated, not measured | mini program | Not fixed: no WebView measurement tool at hand | Measure Y in WeChat DevTools/WebView like Android (method in the task log), set floor from the number | `Animated-Item.md` |
| B12 | Dark glass is darker than iOS (Android ~Y35, Harmony 0.40 floor margin) | Android, HarmonyOS | Undecided (D4) | After D4 and T1: change default tint or edge, keep floors | `Android-Liquid-Glass.md`, `HarmonyOS-Liquid-Glass-Parity.md` |
| B13 | Android glass view inside its own backdrop source crashes (task-log row 78) | Android | Code written, device test not run | Run in the device batch; add a Robolectric test if reproducible | `Animated-Item.md` |
| B14 | Rive `menu.riv` with Loop off (row 79) | Android/HarmonyOS | Code written, not tested | Device batch | `Animated-Item.md` |
| B15 | Some Rive icons play once and then neither loop nor play again (B20, also seen on iOS) | mini program, iOS | TODO; PR #820 merged but the bug stays | Reproduce with the fixture in `animated-item-fixtures`, check the engine's reset on `stateMachine` end | `Animated-Item.md` (bug log) |
| B16 | Stray clipped text ("GA") above the status bar on every tab | mini program | TODO, low priority, may not be this repo's | Reproduce in DevTools, compare with the example's `app.json` | `Animated-Item.md` (bug log) |
| B17 | Crash in `libohos_rive.so` on the animations page | HarmonyOS | Fix is in, no screenshot to verify | Run on a device/emulator with Rive (arm64 only), capture | `HarmonyOS-Issues.md` |
| B18 | x86_64 HarmonyOS emulator has no Rive/PAG (those libs are arm64-only); the emulator process keeps disappearing | HarmonyOS | Environment limit; owner plans recorded in instructions | Use arm64 device for Rive/PAG; restart emulator from its own folder (`Emulator.exe -hvd "Mate 70 Pro" ...`) | `instructions/windows-harmonyos.md` |
| B19 | Flutter plus-button title disappears on its own page | Flutter iOS | Could not be reproduced (B3 of TODO-Sweep) | Reproduce with `example`; compare with the old stale branch `fix/flutter-plus-title-hidden` | `TODO-Sweep.md`, `Cross-Platform-Components.md` |
| B20 | Two Sonar S7755 (`Array.at`) | HarmonyOS | Not fixed: ArkTS rejects `Array.at`/`Uint8Array.at` | Mark as accepted in SonarCloud with the reason, or rewrite with index arithmetic | `Animated-Item.md` row 67 |
| B21 | Remaining ~50 of 135 non-iOS Sonar issues | various | Not fixed: time | Re-pull the list from SonarCloud and continue by rule | `Animated-Item.md` row 67 |
| B22 | HarmonyOS hypium installer step fails with mangled paths | tooling | Workaround only | Fix the script's install step to use relative paths | `instructions/windows-harmonyos.md` |
| B23 | Shared emulators used by several sessions: foreign adb input and night-mode flips, and a worker once killed the Huawei emulator with `taskkill //IM emulator.exe` | tooling | Mitigated by rules (lock, per-port serials) | Keep the rules in section 5; consider per-session AVDs | `Release-RAM.md` |
| B24 | CYLTableViewPlaceHolder: refresh icon overlaps text, Rive refresh shows a rectangle, PAG refresh icon static, GIF icon overlaps "Loading..." | iOS (other library) | Not fixed here: belongs to that library | See its integration doc | `CYLTableViewPlaceHolder-Integration-Issues.md` |
| B25 | iOS issues of the tracker (#658, #671, #646, #779 first) | iOS | Needs a Mac | By the maintainer's tier list | `TODO-Sweep.md`, GitHub issues |

---

## 7. Where things are

- Task log with every decision and score: `docs/Animated-Item.md` (very large; search by row number).
- Shared spec I used for parity work: the item contrast and colour rules are in the platform sources: Android `Example-Android/cylanimateditem/src/main/kotlin/com/cyl/animateditem/`, HarmonyOS `CrossPlatform/harmonyos-cyltabbar/cylanimateditem/src/main/ets/`, mini program `CrossPlatform/wechat-miniprogram-cyltabbar/src/cyl-animated-item/`.
- Evidence screenshots: `docs/assets/` (labelled sheets).
- Last pushed SHAs of this period: `b5b36fbf` (Lottie last frame), `d19e138e` (tab icon tint: Android alpha, HarmonyOS rendering mode), `af56db22` (More icon + dark mode doc), `53372bce` (HarmonyOS fill SVG).

---

## 8. iOS and Mac addendum (read this together with sections 0 to 7)

Appended on 2026-11-26 by the macOS session. Folder name rule used: year, month, week of month, where week = ceil(day / 7); 26 November 2026 is week 4, so `20261104`.

**Next focus, in one sentence: finish and push the flat tab bar tint unification, get every CI job green on the same head, then merge PR #824, #823 (after 1.4.0), #813 and finally #788.**

### 8.1 iOS next steps, in order

1. **The flat-tint work is committed, unfinished, as `a868d237`** (this replaces every earlier statement here that it is uncommitted). On that commit the Framework tests ran again: 401, 3 skipped, 0 failures; example builds and pixel checks were done on the older base `9d2b9e7b` only; CI was not checked; the lead has not reviewed the code. Continue from the "Handover status" section of [Tint-Special.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Tint-Special.md) and the description of [PR #824](https://github.com/ChenYilong/CYLTabBarController/pull/824).
2. Check Git history before doubting the yellow default: it **was** written in Objective-C (`efd0b90e`, 2026-07-08, `CYLTabBarController.m`, author field ChenYilong). The Objective-C flat button itself defaults to `tintColor` (selected) and `systemGray` (normal). Owner decision: delete the yellow, move it nowhere.
3. Re-run on the merged head: Framework tests (last green: 384 tests, 3 skipped, 0 failures at `4d0e00ae`), ObjC `Example/`, `Example-Swift-04`, Gallery, SwiftManager-FlatDesign and `Example-Rive` builds.
4. Keep the ClassifyMenu pin consistent: the root `Podfile` and `Example-Swift-04/Podfile` pin `44f226c42441d22c74c6d9e37be5b899bf45f91f` (iOS). The Android / HarmonyOS pins differ (section 0, item 5). Any ClassifyMenu change to library code needs a repin and a new build.
5. Then the CI and merge chain (section 8.2).

### 8.2 CI and static analysis, facts checked on 2026-11-26

| Check | Result | Evidence |
|---|---|---|
| Android on `ff2ada53` | success | https://github.com/ChenYilong/CYLTabBarController/actions/runs/45789846677 |
| WeChat Mini Program on `80fa2f12` | success | https://github.com/ChenYilong/CYLTabBarController/actions/runs/45794839448 |
| Docs navigation on `80fa2f12` | **failure**, step "Check the agent skills": `docs/Dark-Mode-Adaptation.md` had no row in the `cyl-api-map` skill. The row is added in the commit that appends this section; confirm the next run is green. (Section 6, B1 describes the earlier `bound-classes` cause; this was a second cause.) | https://github.com/ChenYilong/CYLTabBarController/actions/runs/45794839370 |
| iOS and Animation tests on `ff2ada53` | **cancelled** by a newer push; no completed green run on a recent head. Not verified in CI. | https://github.com/ChenYilong/CYLTabBarController/actions/runs/45789846643 |
| SonarCloud quality gate, PR 824, analysed `ff2ada53` | **passed** (reliability, security, maintainability rating A; duplication 0.8%). **97 issues are still open**; passing the gate does not mean zero issues. | https://sonarcloud.io/summary/new_code?id=ChenYilong_CYLTabBarController&pullRequest=824 |

The numbers in sections 1 and 6 (B21) about Sonar are older than this table.

### 8.3 Project score (advisor, replaces the author estimate in section 1)

**62 / 100 was the advisor's provisional score toward the release standard; its rule (+3 when the Sonar gate has passed) gives 65 / 100.** CI stays at its low score because no recent head has all workflows green. This is an estimate from evidence up to `ff2ada53`, not a measurement.

Release standard: #824 merged into #788, #788 merged into master, all CI green on one head, Sonar gate passed, shipped features checked on a device or emulator for every platform, owner decisions closed, 1.4.0 published.

| Area | Weight | Score | Missed points |
|---|---|---|---|
| iOS core and tests | 20 | 16 | flat tint and yellow default not pushed when scored (committed since, unfinished, as `a868d237`; not re-scored); one Example-Swift-04 link error not explained |
| Other platforms | 20 | 12 | today's colour-role and tint priority not ported; Rive and PAG only on the x86_64 debug engine; mini program needs a device |
| CI on head | 15 | 7 | no head with all workflows green; PR state "unstable" |
| Static analysis | 10 | 9 | gate passed; 97 open issues remain |
| Examples | 10 | 7 | Swift, React Native and Flutter tag lists; several flat toggles untested |
| Docs | 10 | 8 | stale status rows; 13 locales of the demo strings not reviewed by native speakers |
| Release | 15 | 6 | nothing merged up; #823 draft; no version bump, no publish |
| **Total** | **100** | **65** | |

### 8.4 Branches (iOS view; the full list is section 2)

Classified with `git cherry` against the feature branch (every patch already applied = superseded).

| Open branch (link) | Progress | iOS TODO |
|---|---|---|
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/harmony-animated-item-engines ([PR #824](https://github.com/ChenYilong/CYLTabBarController/pull/824)) | 80% | 8.1, 8.2, tables below |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/cross-platform-components ([PR #788](https://github.com/ChenYilong/CYLTabBarController/pull/788) -> master) | 90% | merge #823 / #813 / #824, final CI, release |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/dealloc-block-executor-dependency ([PR #823](https://github.com/ChenYilong/CYLTabBarController/pull/823), draft) | 85% | 28 commits not in the feature branch; wait for 1.4.0 |
| https://github.com/ChenYilong/CYLTabBarController/tree/feat/firebase-remote-config ([PR #813](https://github.com/ChenYilong/CYLTabBarController/pull/813)) | 80% | 12 commits not in the feature branch; step 2 needs the owner |
| https://github.com/ChenYilong/CYLTabBarController/tree/refactor/item-color-roles | 100% (merged into #824 at `4d0e00ae`) | delete candidate. Section 2a calls it a 40% reference: the **iOS** work in it is finished and merged; only the Android / HarmonyOS / mini ports are open. |

Superseded, every patch already applied (owner decides on deletion): `feat/harmonyos-demo-7-flatdesign`, `feat/harmonyos-plus-button-configuration`, `fix/miniprogram-lottie-reload-loop`. Branches with commits the feature branch does not have, to be compared before deletion: `docs/harmonyos-emulator-screenshots` (4), `feat/harmonyos-flatdesign-api` (2), `feat/harmonyos-svga` (1), `fix/lottie-unplayable-file` (1), `fix/flutter-plus-title-hidden` (3).

### 8.5 iOS TODOs (in addition to section 3.2)

| # | Item | Where recorded |
|---|---|---|
| M1 | Flat tint unification, bar-wide default rendering mode, SwiftManager opt-in, priority table, tests, read-only check of the classic (non-flat) path | [Tint-Special.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Tint-Special.md) TODO table |
| M2 | Android / HarmonyOS / mini program / React Native / Flutter must follow the same tint priority table and the iOS glass default `0.10 / 0.04` (`7eea93b1`; the other platforms still use `0.5 / 0.14`) | Tint-Special.md, [Animated-Item.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Animated-Item.md) |
| M3 | Convert `Example-Swift`, `-02`, `-03`, `SwiftManager-FlatDesign` pages, React Native and Flutter examples to the ClassifyMenu tag list; rows under the tag list are not glass | [examples.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/instructions/examples.md) |
| M4 | Untested flat toggles: `Example-network-download`, `Example-GIF`, `Example-SwiftUI-Rive`; PNG template, SVGA, GIF icons in the flat bar; a multi-colour Rive in a tab bar | Tint-Special.md |
| M5 | `Example-Rive/Pods` is local, git-ignored and stale: run `pod install` there before building (nothing to add to `.gitignore`) | `.gitignore` lines 19 and 22 |
| M6 | `release-ram.sh`: display mirroring, reduce transparency and iTerm2 hiding never run live; the "simulators restarted" announcement is manual | [Release-RAM.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Release-RAM.md) |
| M7 | Open items without a code fix: Issue #13 context menu (tag library has no API), custom badge rows 26 to 29, white row in the Tab Bar Gallery, empty plus-button icon slot rows, dark header pills in FlatDesign, native-speaker review of translations (including the "Content inset" captions) | [Animated-Item.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Animated-Item.md) task log |

### 8.6 Owner decisions still open (in addition to section 4)

1. White text on the selected orange fill is 2.89:1 and a lift-only rule cannot exceed 3.98:1 on a 0.5-grey fill: darker fill colour, a darkening rule, or accept it.
2. Colour-string order for 8-digit hex (`#RRGGBBAA` is used by the unified tint; HarmonyOS `cylTintColorFilter` still reads `#AARRGGBB`).
3. Per-tab `onResourceMissing` on iOS UIKit tab buttons.
4. Plus-button title default: since `a59ecb55` a titled plus button aligns with the tab titles by default (ordered by the owner).
5. The 1.4.0 release (the Android pin moves with it), what to do with #823 versus #824, and the badge / TableViewPlaceHolder corner radius rule.
6. Tint: in the new code, tab animations with no setting keep the file's own colours; `docs/Tint-Special.md` says the default `automatic` tints one-colour files. Keep the code, or add one-colour detection as a bar-wide value (needs a fourth value or changes today's look).
7. Tint: an app that sets only a normal-state title colour now gets it on the selected title too (as the Objective-C button did; the deleted yellow used to hide this), while the icon is the bar tint. Keep, or skip the normal colour for the selected state.
8. Visible changes to accept: flat apps without a selected title colour go from yellow to their tint; an item's own title colour now beats the bar appearance (the font still comes from the appearance); in the ObjC Example unselected titles turn from red to grey after a tab tap.

### 8.7 Bugs (iOS; continues table 2)

| # | Bug | Why not fixed yet | Fix plan and idea | Docs |
|---|---|---|---|---|
| B26 | Flat tab bar: selected title is yellow while the icon is the bar tint | committed in `a868d237`, not reviewed | delete the default at `CYLTabBarController+CYLFlatDesign.swift:902`; one resolver for title and icon | [Tint-Special.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Tint-Special.md) |
| B27 | Flat tab bar ignores the tab URL tint options (Rive `tint=title`; icon nearly invisible in light mode); a fixed tint is ignored too | committed in `a868d237`, not reviewed. Cause from code reading: the button keeps the file in a private `tabBarAnimationURL` and never sets `animationURL` | pass the URL options into the flat tint calculation, same priority as the Liquid Glass path | Tint-Special.md |
| B28 | A multi-colour animation keeps its own colours in a selected tab | by design (`automatic` tints one-colour files only; Rive cannot be classified) | opt in per tab (`animationTint`, URL `tint`, `renderingMode=alwaysTemplate`); an opaque tint turns multi-colour art into a silhouette | Tint-Special.md |
| B29 | One batch reported an Example-Swift-04 link error (`CYLTabBarItemAnimationPrepareTint` undefined) | did not reproduce in two clean rebuilds; cause not found | suspect: the Core podspec excludes `CYLTabBarItemAnimationTint.m` but still compiles `CYLTabBarItemAnimationEngine.m` | [Animated-Item.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Animated-Item.md) |
| B30 | Tapping a badge tag shows nothing | not investigated (the handler runs, then a simulated memory warning) | log the handler, decide the intended effect | Animated-Item.md |
| B31 | Dynamic Island missing in a dark-mode capture | not investigated | capture again, compare | Animated-Item.md |
| B32 | Selected tab title on glass can be below 4.5:1 (orange on Home 2.57 dark / 2.33 light measured at `dfbe9190`) | accent colour, owner decision 8.6 item 1 | see 8.6 | Animated-Item.md |
| B33 | Android shows the other end frame of the Configuration page's selected Lottie tag compared with iOS | found by the ClassifyMenu session; iOS shows the last frame as designed | compare the Android frame choice (see also B9) | Animated-Item.md |
| B34 | SwiftManager-FlatDesign: launch in dark, tap a tab, switch to light: the whole flat bar stays dark until the next tap | **Not a library bug (re-checked 2026-11-27):** the repro tapped Room, whose example theme `roomStyle` keeps the bar black; with Messages selected the bar follows dark to light. Evidence: `docs/assets/ios-27.2-iphone-18-pro-swiftmanager-flatdesign-b34-theme-by-tab-973c255a-2026-11-27.png` | trace the flat bar's trait-change handling after a selection | this file |
| B35 | The classic (non-flat) and glass animation tint ignore per-tab icon colours (`cylTabBarItemIconColor`, `...SelectedIconColor`): `cylTemplateTintColor` reads only the bar's `standardAppearance` (code reading) | read-only check, not changed | resolve the per-tab appearance first; add tests, then compare both paths with the table in Animated-Item.md | [Tint-Special.md](https://github.com/ChenYilong/CYLTabBarController/blob/feat/harmony-animated-item-engines/docs/Tint-Special.md) |

GitHub issues labelled `bug` (about 18 of 35 open issues) were **not triaged in this period**: no root cause or plan is claimed for them. List: https://github.com/ChenYilong/CYLTabBarController/issues?q=is%3Aissue+is%3Aopen+label%3Abug

### 8.8 Mac setup and traps

- Own simulator by UDID only; **never** `xcrun simctl shutdown all` (shared machine). Terminate the app and shut your simulator down after every run.
- `release-ram.sh` quits apps and restarts simulators. In its first test it shut down another session's simulator; unnamed simulators are now left alone unless `--shutdown-others` is given.
- The repository is on a slow exFAT volume: run long git commands in the background, work in a separate worktree, never stash.
- Not in Git, so you will not have it: a copy of `Example-Rive` under `/tmp/xpr/rive-copy`, local DerivedData, and the Claude session setup.
