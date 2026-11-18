# CYLTabBarController folder instructions

Read this file before reading or writing files in this repository. It inherits the vault's root `instructions.md`.

## Where the rules are

- `AGENTS.md` (loaded through `CLAUDE.md`): the agent rules of this repository. Read it first.
- `docs/instructions.md`: the rules of the documentation folder.
- `.agents/skills/cyl-*` (linked from `.claude/skills`): the project skills; `cyl-docs` for documents and screenshots,
  `cyl-verify` for builds, tests, simulators and emulators.
- `docs/Screenshot-Guidelines.md`: the complete screenshot rules.

## Screenshots (added 2026-11-18)

- Original screenshots only (no scaling, no recompression), cropped to the same region and width, from real runs.
- One column with several rows (top to bottom) first. Two columns with several rows only when the one-column image
  would be taller than one screen of a common phone (height above about 2.17 times the width, 19.5:9). A matrix stays a
  grid; a single horizontal row only as the last resort (at most three). The script picks this by default.
- Every stitched image has a header band, a caption band above each cell and a footer band, added around the
  screenshots and never overlapping or covering them. English only; white bands, bold red text (`#FF3B30`), about 2 %
  of the image width.
- Header, in order: platform and OS version, simulator / emulator / device model, host OS and version, IDE and version
  (build), SDK when not implied by the IDE, app and repository commit (the change's commit in parentheses), branch,
  date, then `Purpose: ...`. Example: `iOS 27.2, iPhone 17 Pro simulator, macOS 27.3, Xcode 27.2 (27B52),
  CYLTabBarController dcbfdec6 (ef1d0313), feat/harmony, 2026-11-18. Purpose: Rive tags rest until played`.
- Captions: the state or step and its measurement (`launch, no play`; `11 s later, 0 changed pixels`).
- Footer: the result against the expectation and the method (`Result: ... (expected: ...). Method: ...`), plus the
  test or document.
- Build it with `python3 scripts/stitch-screenshots.py` (ffmpeg only; it marks the PNG). Before committing a screenshot,
  run `python3 scripts/check-screenshot-labels.py`: it fails on any image added since 2026-11-18 without the marker.
  Run `bash scripts/install-git-hooks.sh` once per clone: its pre-commit hook blocks an unlabeled screenshot (CI does
  not check it). Never bypass it with `--no-verify`. Save it in `docs/assets/`, embed it in the
  related document and repeat the header as its text label.

- Screenshots of a tab bar (added 2026-11-18, maintainer): crop with at least 24 pt (72 px at @3x) above the raised plus button (or the bar), measured on the image (the drawn plus button and its badge reach above its accessibility frame), so the plus button and badges are whole; the stitched image keeps a white gap (`scripts/stitch-screenshots.py --top-gap`, 24 px by default) between every header or caption band and the screenshot below. Full rule: docs/Screenshot-Guidelines.md, "Space above the tab bar and below the bands".

- **Session roles by name (added 2026-11-19).** Before starting a task, check the names of the active sessions (for example with `ListAgents`). A session whose name starts with `Mac` (case-insensitive) mainly develops and tests the iOS side; a session whose name starts with `Win` (case-insensitive) mainly develops the other platforms (Android, HarmonyOS, React Native, Flutter, WeChat Mini Program). When sessions of both kinds are active, prefer to assign each platform's tasks to the matching session (iOS work to a `Mac` session, other platforms to a `Win` session), by message, instead of doing all of it in one session. When no session follows this naming, skip this rule and finish the task on your own. Full steps: the `cyl-task-workflow` skill, "Check other sessions first".
