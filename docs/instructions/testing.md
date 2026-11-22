# Testing, CI and commands (tag: `testing`)

Full text of the `testing` rules. [AGENTS.md](../../AGENTS.md#testing-ci-and-commands-tag-testing) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

- **Verify** before pushing: `pod lib lint CYLTabBarController.podspec --quick`, plus a build or static check of the
  changed code. Say plainly what could not be verified.

## CI/CD and where tests run

- **GitHub CI/CD for iOS runs on macOS 26 by default.** Before you rely on a CI environment, always read
  [`.github/workflows/ios.yml` on master](https://github.com/ChenYilong/CYLTabBarController/blob/master/.github/workflows/ios.yml)
  to confirm it: its macOS jobs use `runs-on: ${{ vars.MACOS_RUNNER || 'macos-26' }}`, so the repository variable
  `MACOS_RUNNER` (e.g. `xcode-27`) can move them to another runner. Code that must pass CI builds with the Xcode of that
  runner (`xcodebuild -version` is printed in the job log).
- **Running locally ignores that limit.** "Local" means not going through GitHub CI/CD but testing directly on this Mac:
  the default local system is **macOS 27**, with **Xcode 27** (`/Applications/Xcode.app`, never Xcode-beta) and its
  simulators, which you can run directly (`xcrun simctl`, `scripts/unit-tests.sh`, the scripts under `scripts/`).
- **Before every local build, check the local environment comment** at the top of
  [`.github/workflows/ios.yml`](.github/workflows/ios.yml) (read that file first, as above): its first line records the local
  run environment, e.g. `# local-run-environment: macOS 27.3 (26C5035r), Xcode 27.2 (27B52)`. The local environment is
  agreed to stay the same: add the comment when it is missing, leave it when macOS and Xcode are unchanged, and rewrite it
  when either version differs. `scripts/local-run-environment.sh` does exactly that (`--check` only reports); it reads the
  Xcode of `/Applications/Xcode.app`, not the `xcode-select` default (which may be a beta). Commit a changed comment with
  the work it belongs to.
- Say in the report where a check ran: GitHub CI (which runner) or locally (macOS and Xcode version).

## Commands

```sh
pod lib lint CYLTabBarController.podspec --quick
scripts/unit-tests.sh "iPhone 17 Pro Max"
scripts/ci-build-example.sh <demo folder>
python3 scripts/update-docs-navigation.py
python3 scripts/sync-agent-skills.py --check
python3 scripts/check-license-notices.py
scripts/publish-android.sh staging        # Android library: build and check the Maven bundle (local | staging | central | github)
```

- **Run scripts with bash, not zsh (added 2026-11-16).** The interactive shell here is zsh, which does not split an
  unquoted variable into words: `for f in $list`, `cmd $args` or `sips $box` get one argument holding the whole
  string, where bash would pass several. A command that works in bash then fails or measures the wrong thing in zsh
  (seen: "zsh doesn't split $box into words either", and the measurement had to be run again as a bash script).
  So prefer bash for every script and every command with variables, loops or word lists:
  - run a script file with `bash script.sh` (shebang `#!/usr/bin/env bash`), never `zsh` or `sh` when it relies on
    bash behavior; run a one-off multi-line command as `bash -c '…'` or a heredoc piped to `bash`;
  - in zsh, when bash is not possible, use arrays (`files=(a b)`, `"${files[@]}"`) or `${=var}` to split on purpose;
  - quote every expansion (`"$var"`) unless splitting is wanted.
