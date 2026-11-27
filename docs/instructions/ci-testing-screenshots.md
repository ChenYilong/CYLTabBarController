# CI, Testing, and Screenshots [`ci-testing-screenshots`]

## CI/CD and where tests run

- **GitHub CI/CD for iOS runs on macOS 26 by default.** Before you rely on a CI environment, always read [`.github/workflows/ios.yml` on master](https://github.com/ChenYilong/CYLTabBarController/blob/master/.github/workflows/ios.yml) to confirm it: its macOS jobs use `runs-on: ${{ vars.MACOS_RUNNER || 'macos-26' }}`, so the repository variable `MACOS_RUNNER` (for example, `xcode-27`) can move them to another runner. Code that must pass CI builds with the Xcode of that runner (`xcodebuild -version` is printed in the job log).
- **Running locally ignores that limit.** "Local" means not going through GitHub CI/CD but testing directly on this Mac: the default local system is **macOS 27**, with **Xcode 27** (`/Applications/Xcode.app`, never Xcode-beta) and its simulators, which you can run directly (`xcrun simctl`, `scripts/unit-tests.sh`, the scripts under `scripts/`).
- **Before every local build, check the local environment comment** at the top of [`.github/workflows/ios.yml`](../../.github/workflows/ios.yml) (read that file first, as above): its first line records the local run environment, for example `# local-run-environment: macOS 27.3 (26C5035r), Xcode 27.2 (27B52)`. The local environment is agreed to stay the same: add the comment when it is missing, leave it when macOS and Xcode are unchanged, and rewrite it when either version differs. `scripts/local-run-environment.sh` does exactly that (`--check` only reports); it reads the Xcode of `/Applications/Xcode.app`, not the `xcode-select` default (which may be a beta). Commit a changed comment with the work it belongs to.
- Say in the report where a check ran: GitHub CI (which runner) or locally (macOS and Xcode version).

## Screenshots (added 2026-11-12)

Every screenshot, from CI/CD and from local builds, is saved in the repository with the related document in `docs/` (create the document when none fits; images in `docs/assets/`) and committed to git. Use clear original screenshots: never scaled down or recompressed; a crop that keeps the original resolution is allowed. When the result looks as expected, also update `README.md` with the latest screenshots, in the related section (create it when there is none).

Every screenshot, in the document and in the README, is labeled with: the platform (iOS, Android, Flutter, React Native, HarmonyOS, WeChat Mini Program); the environment: operating system version, simulator or emulator (device model and OS version), and the SDK version of that platform (iOS SDK / Xcode, Android SDK / API level, Flutter SDK, React Native, HarmonyOS SDK, WeChat Mini Program base library); this repository's version or commit (with its link); and the time it was taken.

## Screenshot moments and layout (added 2026-11-12)

Take and commit screenshots at key moments: when a TODO or Linux note can be removed, when a pull request can be merged, or when the result is judged as expected with no bug and no open issue. The README shows cropped key details, a full screen only when it is needed; several details go into one stitched image.

Stitching order of preference: a vertical stack (one column, top to bottom), easiest to read on a phone; then two columns with several rows; last, a single horizontal row, at most three images in a row. (Corrected by the maintainer on 2026-11-12: the original wording said both "prefer a horizontal arrangement" and "a horizontal row is the worst", which contradict each other; the rule is to prefer a vertical stack.)
