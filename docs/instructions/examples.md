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
