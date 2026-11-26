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
