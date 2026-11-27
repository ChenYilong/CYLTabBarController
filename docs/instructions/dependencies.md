# Dependencies and Integration [`dependencies`]

## Depending on CYLTabBarController

A project always integrates CYLTabBarController through CocoaPods. The version it depends on is always the **latest commit of CYLTabBarController**, which can be on any branch, not only `master` or `main`.

1. **Find the latest commit before every build.** Never reuse a commit you found earlier. Run `scripts/latest-cyl-commit.sh` (from any folder, with the absolute path outside this repository): it fetches every branch of `https://github.com/ChenYilong/CYLTabBarController.git` and prints the newest commit by **commit timestamp** (`<sha> <date> <branch>`); `--sha` prints the SHA only and `--podfile` prints the Podfile line.
2. **A project whose name is not CYLTabBarController depends on that commit**:
   `pod 'CYLTabBarController', :git => 'https://github.com/ChenYilong/CYLTabBarController.git', :commit => '<sha>'`
   (a subspec the same way: `pod 'CYLTabBarController/PAG', :git => …, :commit => '<sha>'`). Never a version number (`'~> 1.99'`), a branch, or a tag. Put the new SHA into the Podfile, run `pod install`, then build.
3. **A project whose name is CYLTabBarController (this repository, and the demos in it) depends on it locally**, by a relative path to the folder that holds `CYLTabBarController.podspec`: from a demo folder `pod 'CYLTabBarController', :path => '../'`; from `CrossPlatform/<component>/example/ios` count the folders up to the repository root. Never an absolute path, a commit, or a version.
4. Say in the reply which commit (SHA, date, branch) a build used. If the commit cannot be fetched (offline), say so and do not guess: keep the SHA already in the Podfile and report that it may not be the latest.

## Depending on CYLTableViewPlaceHolder (every example)

Every example, existing and new, also integrates **CYLTableViewPlaceHolder** through CocoaPods at its **latest commit on any branch**, found by commit timestamp before every build, exactly as for CYLTabBarController above:

`CYL_REPO_URL=https://github.com/ChenYilong/CYLTableViewPlaceHolder.git CYL_COMMIT_CACHE=$TMPDIR/cyl-placeholder-latest.git scripts/latest-cyl-commit.sh --sha`

Then: `pod 'CYLTableViewPlaceHolder', :git => 'https://github.com/ChenYilong/CYLTableViewPlaceHolder.git', :commit => '<sha>'` (with the `LottieSwift` subspec for animated placeholders, the same `:git` and `:commit`). Never a version, a branch, or a tag.

Then, in the iOS examples:

- **Every scroll view** (table, collection, plain `UIScrollView`) supports pull to refresh (`cyl_header`, for example `CYLRefreshNormalHeader`) and shows a placeholder when it has no data (`cyl_placeholderViewBlock:`), a no-network placeholder when the device is offline, and a red bar at the top while offline. Prefer animated icons (the Lottie files in `CYLTableViewPlaceHolder.bundle/Animations/`). Follow the scenario example of CYLTableViewPlaceHolder (`Examples/Example-Scenarios`) for the code.
- **No MJRefresh.** Its pod is not used; its API maps to CYLTableViewPlaceHolder's refresh component by renaming `mj_` to `cyl_` and the `MJRefresh` class prefix to `CYLRefresh`.
- A build error that CYLTableViewPlaceHolder causes is not worked around silently: it is listed with its cause in [../CYLTableViewPlaceHolder-Integration-Issues.md](../CYLTableViewPlaceHolder-Integration-Issues.md), so it can be fixed in that library.
