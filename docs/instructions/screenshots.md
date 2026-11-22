# Screenshots (tag: `screenshots`)

Full text of the `screenshots` rules. [AGENTS.md](../../AGENTS.md#screenshots-tag-screenshots) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

- **Screenshots (added 2026-11-12)**: every screenshot, from CI/CD and from local builds, is saved in the repository with the related document in `docs/` (create the document when none fits; images in `docs/assets/`) and committed to git. Use clear original screenshots: never scaled down or recompressed; a crop that keeps the original resolution is allowed. When the result looks as expected, also update `README.md` with the latest screenshots, in the related section (create it when there is none). Every screenshot, in the document and in the README, is labeled with: the platform (iOS, Android, Flutter, React Native, HarmonyOS, WeChat Mini Program); the environment: operating system version, simulator or emulator (device model and OS version), and the SDK version of that platform (iOS SDK / Xcode, Android SDK / API level, Flutter SDK, React Native, HarmonyOS SDK, WeChat Mini Program base library); this repository's version or commit (with its link); and the time it was taken.
- **Screenshot moments and layout (added 2026-11-12)**: take and commit screenshots at key moments: when a TODO or Linux note can be removed, when a pull request can be merged, or when the result is judged as expected with no bug and no open issue. The README shows cropped key details, a full screen only when it is needed; several details go into one stitched image. Stitching order of preference (updated by the maintainer on 2026-11-18, second time): one column with several rows (top to bottom) first; two columns with several rows only when the one-column image would be taller than one screen of a common phone (height above about 2.17 times the width, a 19.5:9 phone shown at phone width); a matrix stays a grid; last, a single horizontal row, at most three images. `scripts/stitch-screenshots.py` chooses the columns this way by default (`--columns auto`). (Replaced: 2026-11-12 "a vertical stack first, then two columns"; 2026-11-18 morning "two columns first".)
- **Screenshot header, captions and footer (added 2026-11-18)**: every stitched image (and every single screenshot committed) has a header band on top, a caption band above each cell and a footer band at the bottom, added around the screenshots and never overlapping or covering them; English only; white bands with bold red text (`#FF3B30`), about 2 % of the image width. Header, in order: platform and OS version, simulator / emulator / device model, host OS and version, IDE and version (build), SDK when not implied, app and repository commit (the change's commit in parentheses), branch, date, then `Purpose: …`. Captions: the state or step and its measurement (`launch, no play`; `11 s later, 0 changed pixels`). Footer: the result against the expectation and the method (`Result: … (expected: …). Method: …`), plus the test or document. Build it with `scripts/stitch-screenshots.py` (ffmpeg only; it marks the PNG), and run `python3 scripts/check-screenshot-labels.py` before every commit that adds a screenshot: it fails on any image added since 2026-11-18 without the marker. Enforced (added 2026-11-18): every clone runs `bash scripts/install-git-hooks.sh` once, so the pre-commit hook blocks a commit with an unlabeled screenshot (CI does not run it: removed by the maintainer on 2026-11-18). Never commit a screenshot made any other way, and never bypass the hook with `--no-verify`. Full rules and the reference example: [docs/Screenshot-Guidelines.md](docs/Screenshot-Guidelines.md); that document wins over any summary.

- Screenshots of a tab bar (added 2026-11-18, maintainer): crop with at least 24 pt (72 px at @3x) above the raised plus button (or the bar), measured on the image (the drawn plus button and its badge reach above its accessibility frame), so the plus button and badges are whole; the stitched image keeps a white gap (`scripts/stitch-screenshots.py --top-gap`, 24 px by default) between every header or caption band and the screenshot below. Full rule: docs/Screenshot-Guidelines.md, "Space above the tab bar and below the bands".

## From instructions.md (moved 2026-11-22)

### Screenshots (added 2026-11-18)

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
