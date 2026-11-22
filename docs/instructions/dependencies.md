# Dependencies and upstream ports (tag: `dependencies`)

Full text of the `dependencies` rules. [AGENTS.md](../../AGENTS.md#dependencies-and-upstream-ports-tag-dependencies) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

## Depending on CYLTabBarController

A project always integrates CYLTabBarController through CocoaPods. The version it depends on is always the **latest commit
of CYLTabBarController**, which can sit on any branch, not only `master` or `main`.

1. **Find the latest commit before every build.** Never reuse a commit you found earlier. Run
   `scripts/latest-cyl-commit.sh` (from any folder, with the absolute path outside this repository): it fetches every
   branch of `https://github.com/ChenYilong/CYLTabBarController.git` and prints the newest commit by **commit
   timestamp** (`<sha> <date> <branch>`); `--sha` prints the sha only and `--podfile` prints the Podfile line.
2. **A project whose name is not CYLTabBarController depends on that commit:**
   `pod 'CYLTabBarController', :git => 'https://github.com/ChenYilong/CYLTabBarController.git', :commit => '<sha>'`
   (a subspec the same way: `pod 'CYLTabBarController/PAG', :git => …, :commit => '<sha>'`). Never a version number
   (`'~> 1.99'`), a branch or a tag. Put the new sha into the Podfile, run `pod install`, then build.
3. **A project whose name is CYLTabBarController (this repository, and the demos in it) depends on it locally**, by a
   relative path to the folder that holds `CYLTabBarController.podspec`: from a demo folder
   `pod 'CYLTabBarController', :path => '../'`; from `CrossPlatform/<component>/example/ios` count the folders up to the
   repository root. Never an absolute path, a commit or a version.
4. Say in the reply which commit (sha, date, branch) a build used. If the commit cannot be fetched (offline), say so and
   do not guess: keep the sha already in the Podfile and report that it may not be the latest.

### Depending on CYLTableViewPlaceHolder (every example)

Every example, existing and new, also integrates **CYLTableViewPlaceHolder** through CocoaPods at its **latest commit on
any branch**, found by commit timestamp before every build, exactly as for CYLTabBarController above:
`CYL_REPO_URL=https://github.com/ChenYilong/CYLTableViewPlaceHolder.git CYL_COMMIT_CACHE=$TMPDIR/cyl-placeholder-latest.git scripts/latest-cyl-commit.sh --sha`,
then `pod 'CYLTableViewPlaceHolder', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '<sha>'`
(with the `LottieSwift` subspec for animated placeholders, the same `:git` and `:commit`). Never a version, a branch or
a tag. Then, in the iOS examples:
- **Every scroll view** (table, collection, plain `UIScrollView`) supports pull to refresh (`cyl_header`, e.g.
  `CYLRefreshNormalHeader`) and shows a placeholder when it has no data (`cyl_placeholderViewBlock:`), a no-network
  placeholder when the device is offline, and a red bar at the top while offline. Prefer animated icons (the Lottie
  files in `CYLTableViewPlaceHolder.bundle/Animations/`). Follow the scenario example of CYLTableViewPlaceHolder
  (`Examples/Example-Scenarios`) for the code.
- **No MJRefresh.** Its pod is not used; its API maps to CYLTableViewPlaceHolder's refresh component by renaming
  `mj_` to `cyl_` and the `MJRefresh` class prefix to `CYLRefresh`.
- A build error that CYLTableViewPlaceHolder causes is not worked around silently: it is listed with its cause in
  `docs/CYLTableViewPlaceHolder-Integration-Issues.md`, so it can be fixed in that library.

- **Upstream projects used for translation (added 2026-11-12)**: when a document of this project links to another project's GitHub repository that is the source of a translation or port (for example the projects ported to Kotlin in the Android folder), do not translate only its default branch. (1) Pull requests: visit the upstream's open pull requests and bring them in. If the translation has not started, merge the open pull requests into the source first; if it is already done, translate each open pull request's change and merge it into our port. (2) Issues: list the upstream's open issues in a table in the related document in `docs/` (create one when none fits): column 1 the issue link, column 2 its description, column 3 the fix status (`TODO` by default). Find each issue's counterpart in our code and try to fix it. (3) Score: 100 means every listed issue is resolved; give a score after each fix and continue until 100. (4) Order: for a translation not started yet, merge the open pull requests, fix issues until the score reaches 60, translate, then fix the remaining issues up to 100; for a finished translation, translate and merge the open pull requests, then fix the issues on the translated code up to 100. The same rule applies to every platform.
