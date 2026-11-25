# Examples and demos (tag: `examples`)

Full text of the `examples` rules. [AGENTS.md](../../AGENTS.md#examples-and-demos-tag-examples) keeps the summary of this tag;
read this file when a task touches the tag. Moved verbatim from AGENTS.md on 2026-11-22 (instruction files are organized
by tag and kept under 200 lines: see [instructions.md](instructions.md)).

- **Example lists keep their rounded sections.** Every table in an example uses the inset grouped style
  (`UITableViewStyleInsetGrouped` / `.insetGrouped`), so each section has its own rounded background. In a
  `UITableViewController`, `self.view` is the table: never paint it `systemBackgroundColor` (white on white hides the
  sections); use `systemGroupedBackgroundColor` or leave the default. A library helper that adds a plain table (e.g.
  `cyl_addBadgeHelperTable`) is created by the example itself with `.insetGrouped`. Keep this when porting a demo.
- **Examples**: they import only `#import <CYLTabBarController/CYLTabBarController.h>` (Swift: `import CYLTabBarController`),
  and their Podfiles must not need changes.
- **Demo behavior: the first tab's cover is added by the demo, later.** In the Objective-C example the big icon over
  the first tab (the "淘" cover, `-setSelectedCoverShow:`) is put on by the example itself, 1.5 s after launch
  (`-cyl_demo_decorateTabBarController:`), not by the library. Icons are replaced the normal way (skins, network icons,
  `-setTabBarItemIcon:…`), and a cover added after them stays on top. Every example (iOS, Android, React Native,
  Flutter) does the same: when the tab icons change (a new skin, icons downloaded from the network), the example adds
  the cover again once the new icons are in. Do not change the library to keep a cover over icons that replace it later.
- **Demo table rows: never on the first tab, spread over the others.** In every example (Swift, SwiftUI, Android,
  React Native, Flutter), a new table-view demo row goes on a tab item **other than the first**, and each new one goes on
  the **next tab in turn** (the second, then the third, and so on, back to the second after the last), so the rows spread
  over the tabs instead of piling up on one. The **first tab item always imitates the Objective-C example's table view**
  (the sections and rows of `Example/Classes/Module/Home/CYLHomeViewController`): change it only to follow a change there.
- **Animated icon examples: Play all, speed slider, loop switch (added 2026-11-13, TODO)**: every example page that shows tab icon animations, on every platform (iOS, Android, React Native, Flutter, WeChat Mini Program, HarmonyOS), offers "Play all" (each animation restarts from progress 0), a speed slider and a loop switch, which combine into one playback policy applied live; change the core when needed. Details and status: [docs/Tab-Icon-Animation-Quick-Start.md](docs/Tab-Icon-Animation-Quick-Start.md#enplayback-controls-in-the-animation-examples).
- **New demos** follow the `cyl-new-project` skill. **PlusButton with forced title alignment**: give it a title; see `cyl-plus-button`.
### How the examples set CYLTabBarController up (the default)

Unless a task says otherwise, every CYLTabBarController in the example layer is integrated the same way:
1. **With a plus button that has its own page** (a `plusChildViewController`): the plus button selects a page, it is not
   only an action.
2. **Initialized from a local configuration file** in the app (`Example-Shared/Configurations/cyl_tabbar_configuration.*`
   or the example's own copy), with `+[CYLTabBarController tabBarControllerWithConfigurationFile:error:]`: the tabs come
   from `CYLTabBarControllerTabBarItemsAttributes`, the plus button from `CYLTabBarControllerPlusButton`, and the plus
   button's page from `CYLTabBarItemPageIdentifier` inside it (resolved like a tab's page: the configuration's resolver,
   the page registry or the global registry). See [docs/Configuration-File.md](docs/Configuration-File.md).
A demo that shows another setup on purpose (no plus button, a plus button without a page, attributes built in code, a
`CYLPlusButtonSubclassing` subclass) says so in its title or comment.
3. **A raised plus button (added 2026-11-12)**: when an example demonstrates the plus button, always prefer the raised look: the top of the plus button reaches above the top edge of the tab bar (an image taller than the bar, and/or `+multiplierOfTabBarHeight:` below 0.5 or a negative `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`), in every style (classic, Liquid Glass, FlatDesign). A demo that needs a flat plus button (inside the bar) says so in its title or comment.
- **Demo lists that need sections use a ClassifyMenu tag list (added 2026-11-25).** Where an example needs a table-view-like list
  with section grouping, use CollectionViewClassifyMenu's tag list instead of a table, taking the main title and the icon from each
  row. Rules, on every platform that has the library:
  - Sectioned layout: every section header **must have a title**. Tags are self-sized (adaptive width), so a line holds as many
    tags as fit.
  - Wrapping: the tag's title label may wrap (no one-line limit), using the library's wrapping API. An example sets the limit to
    **3 lines**; text beyond that is cut.
  - Folding: a section that needs more than the maximum number of rows shows a **More / Less** toggle with the library's built-in
    icon; More expands the section, Less folds it again.
  - Short titles: a tag's title is only the row's main title. What the row's title says in brackets, `(…)` or `（…）` (a parameter name, an issue
    number, a note), is moved out of the title and **appended to the subtitle** (after the row's own subtitle, joined by ` · `), so it shows only on a
    long press. A title that is only brackets stays as it is. Every example does this in the code that builds the tag list
    (HarmonyOS `demoTagText`, Android `DemoTagList.tagText`, mini program `cylTagText`), never in the library and never in the row data.
  - Fold control is a tail control: a section that folds (`defaultVisibleRows` 3) puts its expand / collapse button in the tag flow as the LAST tag,
    showing only the icon (a chevron, turned when expanded): `foldControl` position `tail`, content `icon`, on every platform. Never a header button and
    never a title on it. It is set in the same code that builds the tag list's configuration (HarmonyOS `demo/DemoTagList.ets`, Android `demo/DemoTagList.kt`,
    mini program `utils/cyl_demo_tags.js`).
  - Liquid Glass style: every tag list in an example uses the library's Liquid Glass tag style (`backgroundStyle` `liquidGlass`: a glass background
    behind each tag, with the library's own border, corner radius and content inset), never the flat style, on every platform. It is set in the code that
    builds the tag list's configuration (HarmonyOS `demo/DemoTagList.ets`, Android `demo/DemoTagList.kt`, mini program `utils/cyl_demo_tags.js`), together with
    `titleMaxLines`. Where the platform cannot draw glass (the mini program outside a glass-capable view), the library falls back to its flat look; do not
    add example-only drawing to imitate it.
  - Dark mode: an example's tag list is checked in light and dark mode, and a dark mode check always includes the built-in default tint (a one-color
    animated file takes the library's color of its state and mode, a multi-color file keeps its own colors). The list's own default background is a fixed
    white that does not follow dark mode, so an example sets the style `backgroundColor` to clear (`#00000000`) and lets the page's background show;
    otherwise the header texts, which do follow dark mode, are white on white. HarmonyOS: `--ps cylColorMode dark|light` on `aa start` switches the app's
    color mode, and the `Default tint` row of the second tab (`cylScreen default-tint`, `pages/DefaultTint.ets`) shows a one-color and a multi-color Lottie
    file, normal and selected. Android: `adb shell cmd uimode night yes|no` (restore it afterwards: emulators are shared). Mini program: no real dark switch in
    DevTools automation; override `wx.getAppBaseInfo` to return `theme: 'dark'` in the app service and open the page again (the page's own background stays light).
  - Tap: tapping a tag does exactly what tapping the old cell did.
  - Long press: shows the row's subtitle in a small floating callout with an arrow, built with the tag list's long-press
    custom API (never with example-only gesture code).
  - Pin the library by commit, not by copy: HarmonyOS pins it in `CrossPlatform/harmonyos-cyltabbar/classifymenu.pin` and
    `scripts/fetch-classifymenu.sh` fetches `harmony/classifymenu` into the git-ignored `cylclassifymenu/` (the build script runs it).
    Every tab of an example uses it, the first one too (it keeps the Objective-C example's sections and rows, see "Demo table rows" above).
    Exception: the badge sample rows stay rows, because a badge is drawn over a row's icon and a tag has no place for it.
  - Android pins it the same way (`scripts/fetch-classifymenu.sh android` fetches `android/merged/library` into the git-ignored
    `Example-Android/cylclassifymenu/`, built with `Example-Android/cylclassifymenu.build.gradle.kts`); the tag list is the header view of the demo `ListView`,
    so scroll hiding keeps working, and the badge rows follow as rows. The callout stays until the next touch, tap or scroll (pin b79d2031 or later).
  - The mini program pins it the same way (`scripts/fetch-classifymenu.sh miniprogram`, run by `npm run setup`, fetches `cyl-tag-list-miniprogram` into the git-ignored
    `example/cylclassifymenu-miniprogram/`, installed as a `file:` dependency). A section becomes a tag list when every row is a plain row (no slider, switch, arrows or
    color swatch); the other sections keep their rows (`example/miniprogram/utils/cyl_demo_tags.js`). The expanded control reads "Less" there.
  - Status (2026-11-25): HarmonyOS `entry` `Index.ets`, Android `DemoList.kt` and the mini program home page done; React Native and Flutter are not converted yet
    (each needs a native ClassifyMenu build chain; their demo rows also have switches, arrows and buttons).
