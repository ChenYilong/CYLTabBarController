---
name: cyl-task-workflow
description: "How to start, score and finish every task in CYLTabBarController: check the other sessions first (Mac sessions take iOS, Win sessions the other platforms), put a TODO list and the current branch at the top, write the task and its scoring rubric (100 = full marks, 60 = pass) into docs/, keep working until the score passes, print the missing points as TODO at the end. Also: restart a hung or unopenable emulator after telling the other sessions. Use at the start of every task and whenever an emulator or simulator hangs."
---

# Task workflow (added 2026-11-18)

The same rules are in `AGENTS.md` ("Git and pull requests"). When they disagree, `AGENTS.md` wins; fix this file.

## 1. Check other sessions first

1. List the other agent sessions (for example with `ListAgents`) and read their current tasks. A session usually marks
   its task as `TODO` at the top of the session.
2. Is any of them editing the same branch (`git branch --show-current`)?
   - No: continue.
   - Yes: check whether its task duplicates yours. If it does, do not do the work twice: agree with that session who
     does what (split the items or hand them over). If it does not, continue, and tell that session which files you
     will change, so that the two of you do not edit the same lines.
3. **Session roles by name (added 2026-11-19).** Before starting a task, check the names of the active sessions (for example with `ListAgents`). A session whose name starts with `Mac` (case-insensitive) mainly develops and tests the iOS side; a session whose name starts with `Win` (case-insensitive) mainly develops the other platforms (Android, HarmonyOS, React Native, Flutter, WeChat Mini Program). When sessions of both kinds are active, prefer to assign each platform's tasks to the matching session (iOS work to a `Mac` session, other platforms to a `Win` session), by message, instead of doing all of it in one session. When no session follows this naming, skip this rule and finish the task on your own.

## 2. TODO and branch at the top

Your first message of the task starts with:

```
TODO (branch: feat/cross-platform-components)
- [ ] item 1
- [ ] item 2
```

## 3. Write the task into docs/, with a scoring rubric

Find the most relevant document in `docs/` (create one only when none fits) and add a `TODO` entry with:

- the context and the user's requirements, and the user's prompt quoted verbatim;
- the acceptance rubric, item by item: what scores **100** (full marks) and what scores **60** (pass). For example:
  100 = every platform built, tested and checked on a device with screenshots; 60 = the code and unit tests on every
  platform, with the device checks still open.

## 4. Score until it passes

- Score the work against the rubric after each step, and show the score.
- Below **60**, the task must not be stopped or handed back to the user: keep working and scoring until it reaches at
  least 60. A blocker you cannot remove yourself (a device you do not have, a decision only the user can make) is
  reported with what you tried, and you keep working on every other item meanwhile.

## 5. Explain the missing points

When the final score is below 100, say why it cannot reach 100, and print every missing point as a `TODO` at the very
end of the session's final message:

```
Score: 85/100
TODO (-10) HarmonyOS Rive on a device: only an x86_64 emulator here; @ohos/rive needs arm64.
TODO (-5)  Flutter Gradle lockfiles: not refreshed yet.
```

## 6. Update the task document

Update the entry written in step 3: the final score, the missing-point `TODO`s and the evidence (commits, tests,
screenshots). Mark it `DONE` only at 100.

## Hung emulator

An emulator or simulator that is hung (commands time out, the package manager does not answer, apps do not install or
launch) stays hung until it is restarted. When one does not open at all, restarting is also the first strategy.

1. Do not ask the user whether to restart.
2. First tell the other sessions that use it: one message to each, naming the device ("restarting emulator-5556, it
   is hung").
3. Restart it from the command line right away:
   - Android: `adb -s emulator-5556 emu kill`, then `emulator -avd <name> -no-snapshot-load &` (`emulator -list-avds`
     lists the names), then `adb -s emulator-5556 wait-for-device` and wait until
     `adb -s emulator-5556 shell getprop sys.boot_completed` prints `1`.
   - HarmonyOS: stop the emulator and start it again (DevEco Studio's Device Manager, or its emulator command line),
     then check it with `hdc list targets` (in Git Bash set `MSYS_NO_PATHCONV=1`).
   - iOS: `xcrun simctl shutdown <udid>` then `xcrun simctl boot <udid>`; `xcrun simctl list devices` lists them.
4. After every restart, tell **all active sessions** (list them with `ListAgents`; not only the ones that used the
   device) that the emulator is available again, naming the device, and ask each to resume any task it paused
   because the emulator could not start or was hung. For example: "emulator-5556 is restarted and available again;
   please resume any task you paused because it could not start."
5. If it hangs again after the restart, look for the cause, for example another process that polls `adb` in a loop
   (on Windows, `Get-CimInstance Win32_Process -Filter "name='adb.exe'"` shows each command line), and report it to
   the user and to that session.

## Swift first on iOS (added 2026-11-19)

- **The iOS core is Swift; every new piece of code is Swift first (added 2026-11-19, owner)**: the core code of this project on iOS (the CocoaPods / Swift Package Manager / Carthage sources under `CYLTabBarController/`, including the `CYLAnimatedItem` module) is Swift. Write every new class, extension, test and example in Swift. Use Objective-C only where Swift cannot do the job (a header that must stay importable from Objective-C without modules, a `+load`-time hook, a C macro), and give the reason in a comment and in the task's document in `docs/`. Keep the public API usable from Objective-C (`@objc`, `@objcMembers`, `NS_SWIFT_NAME` counterparts) so existing Objective-C callers keep working. When you touch Objective-C code for a new feature, prefer adding the feature in a Swift file over growing the Objective-C file. Migration log: `docs/Swift-Migration.md`. Details: `AGENTS.md`, "Code rules".

## Instruction files: tags and the 200-line limit (added 2026-11-22, owner)

The instruction files (`AGENTS.md`, `instructions.md`, `docs/instructions.md`, `CLAUDE.md`) are organized by tag: every rule has a tag (a keyword such as `testing`, `windows-harmonyos`, `macos`, `documentation`, `git`), each tag is a visible heading `## <Title> (tag: `<tag>`)` with a short summary, and no file goes above 200 lines; what does not fit moves verbatim to `docs/instructions/<tag>.md`, linked from the heading by a relative path, and is read only when a task touches the tag. A new rule goes under its tag (summary) and into the tag's file (full text). Full rule: `docs/instructions/instructions.md`.

## Read in full before any task (added 2026-11-22, owner)

Before any task in this repository, read `docs/instructions/behavioral.md` in full (tag `behavioral`, linked at the top of `AGENTS.md` and `instructions.md`). Files marked "read in full" are linked at the top of the root instruction files under their own tag heading: `docs/instructions/instructions.md`, rule 5.

## Read the git tag file before any git operation (added 2026-11-22, owner)

Before any git operation (commit, push, pull, rebase, merge, branch, tag, reset, pull request), read `docs/instructions/git.md` in full, every line, then run the git command (`docs/instructions/instructions.md`, rule 6).
