# Git, commits and pull requests (tag: `git`)

Full text of the `git` rules. [AGENTS.md](../../AGENTS.md#git-commits-and-pull-requests-tag-git) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

## Git and pull requests

- **Before every Commitizen-style (`git cz`) commit**, run this first in the repository root, so the vault's auto sync does not commit or push in the middle of it:

  ```sh
  touch .git/hooks/NO_AUTO_SYNC
  ```

- **`git cz` style commits, English only (added 2026-11-16)**: Every commit is a Commitizen (`git cz`) style commit (`{type}{scope}: {emoji}{subject}`, see the Commitizen rules below), and the whole commit message is written in English: subject, body, TODO notes and trailers. No Chinese characters are allowed anywhere in a commit message. When a commit refers to Chinese text (a user prompt, a document, a string), give its English translation or link the document instead. Check before every push: `git log -1 --format=%B | python3 -c "import re,sys; sys.exit(1 if re.search('[\u4e00-\u9fff]', sys.stdin.read()) else 0)"` must print nothing; reword a commit that fails.

- **On any branch other than `master` or `main`, commit and push as soon as the work is written, without asking
  for confirmation.** On `master` or `main`, ask first.
- **Commit and push at the end of every turn (added 2026-11-16)**: when a question-and-answer turn ends and the current branch is not `master` or `main`, commit and push the work of that turn, without asking. This is always safe: the code stays on a branch and is never pushed to `master` or `main`, so pushing carries no risk to worry about. The open pull request rule still applies to every such commit (check for an open pull request first, open one if missing). On `master` or `main`, ask first.

- **Never commit `._*` files.** macOS writes these AppleDouble metadata files next to every file on an external volume
  (e.g. `._.claude`, `._.git`, `._.github`, `._.gitignore`, `._.pullapprove.yml`, `._ChatKit`). `.gitignore` excludes
  `._*`. Before git commands, delete them, including the ones in `.git/objects` (`._pack-*.idx` makes git report
  `non-monotonic index`):

  ```sh
  find . -name '._*' -not -path './.git/*' -delete
  find .git/objects -type f -name '._*' -delete
  git fsck --full
  ```

  Some were committed anyway: take them out of the repository with `git rm --cached` in a new commit; an unpushed commit
  that holds only them is undone instead. Rewriting pushed history needs a force push: ask first.
- **Never commit `*.lock` files** (`Podfile.lock`, `yarn.lock`, `pubspec.lock`, `Gemfile.lock`): `.gitignore` excludes
  `*.lock`. Gradle's `gradle.lockfile` (and `settings-gradle.lockfile`) does not end in `.lock` and stays committed.
  SonarCloud's "lock file is missing" findings (`text:S8564` package.json, `text:S8568` Gemfile, `text:S8571`
  pubspec.yaml) are therefore avoided by excluding those manifests in `.sonarcloud.properties` (`sonar.exclusions`;
  automatic analysis ignores `sonar.issue.ignore.*` there), never by committing a lock file.
- **Before every commit, check `docs/` for stale notes**: search every document in `docs/` (and `README.md`) for the
  keywords **`TODO`** and **`Linux`**, and for other notes left by an environment that could not run the code
  ("without Xcode", "no simulator", "no screenshots", `无法运行`, `没有截图`):

  ```sh
  grep -rn -i -E "TODO|Linux|without Xcode|no (iOS )?simulator|no screenshots?|无法(编译|运行)|没有截图|暂无(测试)?截图" docs README.md
  ```

  For each hit about a feature: test it (build, unit tests, run it on the simulator or emulator), then update the
  document with what was verified and the test screenshots (`docs/assets/`, layout as the `cyl-docs` skill says), and
  `README.md` when its section is affected. A finished TODO becomes DONE with its evidence; a TODO that only the
  maintainer can do (a repository setting, a release) stays, with what was checked and when. A bug found while testing
  is fixed in the same change. Details: the `cyl-docs` skill, "Stale notes before every commit".
- **Push over SSH first**: `git push origin <branch>` (`origin` is `git@github.com:ChenYilong/CYLTabBarController.git`).
  Use HTTPS with the `gh` credential helper only when SSH fails: its token has no `workflow` scope, so GitHub rejects
  any push that changes `.github/workflows/*` ("refusing to allow an OAuth App to create or update workflow").
- Branch from the latest `master` for each issue or feature.
- **Every new branch gets a pull request, automatically (added 2026-11-12)**: after creating a branch and pushing its first commit, open a pull request right away, without asking. Target branch: the branch it was created from (preferred); otherwise `main` or `master`.
- **Every commit message carries the author line** `By  @ChenYilong <luohanchenyilong@163.com>` (exactly as written,
  two spaces after `By`) on its own line in the body, after the description and before any trailers such as
  `Claude-Session:` or `Co-authored-by:`. A commit without it is incomplete: amend it before pushing.
- Commit messages are in English, Conventional Commits as configured for commitizen in `package.json`
  (`feat: ✨ …`, `fix: 🐛 …`, `docs: 📝 …`).
- Follow the Commitizen defaults: emojis are enabled and the format is
  `{type}{scope}: {emoji}{subject}`. Scope is optional and there are no
  predefined scopes. The configured message length is 3–64 characters. The
  examples use a space between the emoji and subject. The
  interactive types, in order, are `test`, `feat`, `fix`, `chore`, `docs`,
  `refactor`, `style`, `ci`, and `perf`; `release` is defined but not listed.
- Default type meanings and emojis: `chore` (build or auxiliary tools, 🤖),
  `ci` (CI changes, 🎡), `docs` (documentation only, ✏️), `feat` (new feature,
  🎸), `fix` (bug fix, 🐛), `perf` (performance improvement, ⚡️), `refactor`
  (neither a feature nor fix, 💡), `style` (markup or formatting only, 💄),
  `test` (adding missing tests, 💍), and `release` (release commit, 🏹).
- The question sequence is `type`, `scope`, `subject`, `body`, `breaking`,
  `issues`, and `lerna`. Prompts request a change type, optional scope, a short
  imperative subject, longer description, breaking changes, issues closed (for
  example `#123`), and affected packages. Use this repository's established
  emoji mappings when they differ from defaults: `feat: ✨`, `fix: 🐛`,
  `docs: 📝`, `chore: 🔧`, and `refactor: ♻️`. Keep commit text in English.
- Before every commit, review the changed scope and its issue, comparison, and implementation-status documents.
  Record each incomplete or unverified item in the commit under a `TODO` heading in the most relevant existing
  `docs/` document. State the current score or status, remaining work, implementation constraints, known defects,
  API design and compatibility risks, optimization opportunities, and verification required for completion.
  Reserved keys, stubs, and successful compilation alone are not completion evidence.
- The Conventional Commit subject summarizes completed work in English; put details and pending tasks in the body.
  If the detailed description exceeds 50 characters, create or update a suitable `docs/` note and link it in the
  commit body. Reuse existing trackers and avoid duplicate documents.
- Push early and open the pull request once the change is substantial; the PR body closes the issue (`Closes #N`).
- Before merging, squash the PR into a single commit and push with `--force-with-lease` (never a plain force push).
  On someone else's branch, merge `master` in instead of rebasing.
- After opening the PR, comment on the issue (in the issue's language) with the changes, the commit link, and an
  invitation to try the latest version.
- **Every branch with commits has an open pull request (added 2026-11-16).** After creating a branch, any commit on it
  must be in a pull request. Never create a branch and keep committing to it without one: commits on a branch with no
  pull request are ignored, because nothing ever merges them.
  - **Before every commit**, check that the current branch has an open pull request
    (`gh pr list --state open --head <branch>`). If it has none (never opened, closed or merged), open a new one right
    after pushing (`gh pr create --base <target> --head <branch>`).
  - **Target branch**: the branch of the pull request that was active (open) before this one was created; only when
    there is none, `master` (or `main`).
  - **More than two open pull requests: ask first.** When the repository already has more than two open pull requests,
    do not open another one on your own: ask the owner whether to create a new branch and pull request or to keep
    committing on the current branch. More than two open branches make merging hard and leave no sensible target for
    each branch.
  - Push only to branches that have an open pull request; do not recreate a branch that was deleted after its pull
    request was closed or merged.
