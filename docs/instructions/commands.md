# Commands [`commands`]

Use these standard commands when verifying or maintaining the repository:

```sh
pod lib lint CYLTabBarController.podspec --quick
scripts/unit-tests.sh "iPhone 17 Pro Max"
scripts/ci-build-example.sh <demo folder>
python3 scripts/update-docs-navigation.py
python3 scripts/sync-agent-skills.py --check
scripts/publish-android.sh staging        # Android library: build and check the Maven bundle (local | staging | central | github)
```

## Run scripts with bash, not zsh (added 2026-11-16)

The interactive shell here is zsh, which does not split an unquoted variable into words: `for f in $list`, `cmd $args` or `sips $box` get one argument holding the whole string, where bash would pass several. A command that works in bash then fails or measures the wrong thing in zsh (seen: "zsh doesn't split $box into words either", and the measurement had to be run again as a bash script). So prefer bash for every script and every command with variables, loops or word lists:

- run a script file with `bash script.sh` (shebang `#!/usr/bin/env bash`), never `zsh` or `sh` when it relies on bash behavior; run a one-off multi-line command as `bash -c '…'` or a heredoc piped to `bash`;
- in zsh, when bash is not possible, use arrays (`files=(a b)`, `"${files[@]}"`) or `${=var}` to split on purpose;
- quote every expansion (`"$var"`) unless splitting is wanted.
