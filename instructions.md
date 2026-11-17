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
- The stitched image is portrait. Two columns with several rows by default; one column when each cell is wider than
  tall (a tab bar strip); a matrix stays a grid; a single horizontal row only as the last resort (at most three).
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
- Build it with `python3 scripts/stitch-screenshots.py` (ffmpeg only). Save it in `docs/assets/`, embed it in the
  related document and repeat the header as its text label.
