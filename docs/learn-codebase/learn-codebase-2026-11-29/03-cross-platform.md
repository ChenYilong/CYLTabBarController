# Android, HarmonyOS and WeChat Mini Program

> **UNVERIFIED.** Notes from a partial static reading on 2026-11-29; they were not re-checked against the code, and coverage is
> incomplete (see this folder's `README.md`). Later commits may have changed what is described, including the badge task's state.

Project: CYLTabBarController · exported 2026-11-29 for `claude-mem:learn-codebase`

**Coverage: not part of the systematic read.** These notes come from files seen in passing. The Android, HarmonyOS, Mini Program, React Native and Flutter library groups are still unread.


## Observations (17)

> The entries under "Observations" are copied verbatim from claude-mem. They are its automatic summaries of what was read; I have not re-checked each one against the source. No build or test was run during the learn-codebase read.

### #203 — HarmonyOS contrast lift only applies to dark glass or a static flat fill (GitHub)
discovery · 2026-11-27 12:15 UTC
The HarmonyOS adaptedForContrastState rule leaves a dark item unchanged unless it draws glass or has a static non-clear flat fill.

This is the HarmonyOS version of the contrast rule that the Android and iOS flat-fill logic mirrors. Dark-mode lifting happens only in two cases: the glass is drawn, or the item has a static, non-clear flat fill. An item with no fill, or with a resource or clear fill, is never adapted. This explains why the Harmony dark flat-fill test failed earlier: a flat item whose backgroundColor is unset gives an undefined reference, so the cross colour is never lifted. The lift is also lift-only, so light text on a light fill is kept.

- CYLAnimatedItemContrast.adaptedForContrastState in CrossPlatform/harmonyos-cyltabbar/cylanimateditem/src/main/ets/CYLAnimatedItemContrast.ets returns the colour unchanged when dark is false.
- When dark is true and drawsGlass is true, the function delegates to adaptedOnGlassState using the glass tint and tint alpha.
- When dark is true and drawsGlass is false, the function uses flatReferenceLuminance(flatFill) as the reference, and returns the colour unchanged if that reference is undefined.
- flatReferenceLuminance returns undefined for a fill that is a resource rather than a static colour, or whose alpha is 0, and it applies no luminance floor, which is glass-only.
- The flat reference is the fill's RGB multiplied by its alpha and then taken as relative luminance over black.
- The minimum contrast is minimumIconContrast for the icon kind and minimumTextContrast otherwise.
- adjustedToReference only lifts lightness in steps of 0.005 until contrast passes or reaches white, and if white cannot pass it keeps whichever of the original and lifted colours has more contrast.

Files read: CrossPlatform/harmonyos-cyltabbar/cylanimateditem/src/main/ets/CYLAnimatedItemContrast.ets

Concepts: how-it-works, gotcha

---

### #206 — HarmonyOS contrast lift rounds to bytes after the minimum-contrast check (GitHub)
discovery · 2026-11-27 12:15 UTC
Code inspection confirms the reported rounding gap in the HarmonyOS adjustedToReference path.

Inspected the colour rounding code paths in three platform implementations of the automatic contrast lift for tag and animated-item icons, to check the rounding issue reported in HarmonyOS d5f1b436. The HarmonyOS version lifts lightness in HSL, converts to RGB, rounds each channel to bytes, and returns without re-verifying the ratio, which is the root cause of a lifted colour landing just under the 3:1 floor. The Android version avoids this by iterating lightness in 0.005 steps and re-evaluating passes() each step, which suggests it is less exposed, though the passes() body was not visible in this output. The mini program has a rounding helper and a lift function but no visible step loop, so whether it shares the pattern is still open.

- CYLAnimatedItemContrast.adjustedToReference in the HarmonyOS cylanimateditem module checks ratio(hsl, lightness, reference) against minimumContrast on unrounded HSL values.
- After the check passes, the lifted colour is built with rgbFromHSL and each channel is converted to a byte with Math.round(clamped component * BYTE_MAX).
- No contrast re-check runs after the byte rounding, so rounding down can push the final colour below the minimum contrast ratio.
- The early-return guard in that function returns the original colour only when the original already exceeds the lifted ratio and the lift is still below the minimum.
- The same ratio helper is used for the check and calculates relative luminance from rgbFromHSL output, not from the rounded bytes.
- The Android CYLAnimatedItemContrast.kt adjusted() function uses a while loop that steps hsl[2] by LIGHTNESS_STEP (0.005 per the KDoc) until passes() succeeds or lightness reaches 1.
- The Android loop has a final !passes() branch at around line 112, which handles the case where no lightness step passes.
- In the WeChat mini program, cyl_animated_item_contrast.js defines cylAnimatedItemContrastLiftToReference at about line 155 and uses Math.round in a clamp helper at about line 123.
- A grep for lightness step terms in the mini program contrast file returned no matching step constant, so its lift loop structure is not yet confirmed.

Files read: CrossPlatform/harmonyos-cyltabbar/cylanimateditem/src/main/ets/CYLAnimatedItemContrast.ets, Example-Android/cylanimateditem/src/main/kotlin/com/cyl/animateditem/CYLAnimatedItemContrast.kt, CrossPlatform/wechat-miniprogram-cyltabbar/src/cyl-animated-item/cyl_animated_item_contrast.js

Concepts: problem-solution, gotcha

---

### #207 — Android and mini program lift loops differ on rounding and re-checking (GitHub)
discovery · 2026-11-27 12:15 UTC
The Android lift re-checks passes() each step, while the mini program re-checks on whole-byte ratios but returns bytes without a final guard.

Compared the lift loops for the rounding gap reported in HarmonyOS adjustedToReference. The Android version steps lightness against unrounded RGB and then rounds to bytes without re-running passes(), so a lifted colour can still land just under the minimum after rounding. It only has a fallback to the original colour, not a re-check. The mini program version is safer: its loop evaluates contrast on the byte-rounded colour that it returns, so the returned colour keeps the ratio it was judged by. The HarmonyOS version still needs the same re-check or byte-aware loop that the mini program already uses.

- Android CYLAnimatedItemContrast.adjusted() in CYLAnimatedItemContrast.kt runs passes() on unrounded HSL-derived RGB, stepping hsl[2] by LIGHTNESS_STEP (0.005) while below 1.
- Android adjusted() builds the returned colour with channel() = Math.round(value * 255).coerceIn(0, 255) after the loop, so the final bytes are not re-verified by passes().
- Android adjusted() has a fallback: if !passes() after rounding, it returns the original colour when its contrast is at least that of the lifted colour, otherwise the lifted colour.
- Mini program cylAnimatedItemContrastLiftToReference in cyl_animated_item_contrast.js uses ratioAt(lightness), which rounds each channel with byteOf() before computing relative luminance, so its loop tests the same bytes it returns.
- Mini program byteOf(x) clamps to 0..RGB_MAX with Math.round(x * RGB_MAX), and the returned hex or rgb() string is built from those same rounded bytes.
- Mini program has a final guard: if ratioAt(lightness) is below minimumContrast and the original ratio is at least ratioAt(lightness), it returns the original colour.
- The mini program's ratioAt loop tests whole-byte colours, so it does not share the HarmonyOS flaw of checking unrounded HSL and then rounding down below the floor.
- The Android loop checks unrounded values, so the same rounding-below-floor gap as HarmonyOS remains possible in Android's returned colour.

Files read: Example-Android/cylanimateditem/src/main/kotlin/com/cyl/animateditem/CYLAnimatedItemContrast.kt, CrossPlatform/wechat-miniprogram-cyltabbar/src/cyl-animated-item/cyl_animated_item_contrast.js

Concepts: problem-solution, gotcha

---

### #208 — Android CYLAnimatedItemView applies rendering-mode tint to one-colour static images (GitHub)
feature · 2026-11-27 12:15 UTC
Static icons now follow Automatic, AlwaysTemplate, and AlwaysOriginal rendering modes when no explicit icon colour is set.

The Android core CYLAnimatedItemView now tints one-colour static images the same way it tints animations, instead of ignoring tint for static icons. This fixes the ClassifyMenu tag icons that ignored dark-mode tint rules. Under Automatic, the image is tinted only when its colour kind is OneColor, so multi-colour images keep their colours. AlwaysTemplate tints any image and AlwaysOriginal never tints. An explicit iconColor still tints the whole image. The change follows the handover that the ClassifyMenu side should drop its line-444 filter and route static icons through this core rule.

- CYLAnimatedItemView gained `protected open val tintsStaticImageAutomatically` (default true); a subclass that tints its own icon, such as the tab bar button, returns false.
- `staticImageRenderingColor` resolves the static tint: AlwaysOriginal gives no tint, AlwaysTemplate tints any image, and Automatic tints only when `CYLAnimationColorCount.drawableKind` reports Kind.OneColor.
- The rendering mode is read from `animationRenderingMode`, falling back to `stackAnimationRenderingMode`, then to CYLAnimationRenderingMode.Automatic.
- A DisabledBuiltIn colour is used as-is; all other resolved colours pass through `adaptedIconColor` for the contrast rule.
- `staticImageKind` caches each drawable's colour kind in a WeakHashMap keyed by Drawable.
- `applyIconColor` uses an explicit effective icon colour first, then the rendering-mode colour, and skips the rendering-mode path when the host has set its own colorFilter on iconView.
- When the view clears a filter it set itself, it now tracks the applied filter in `appliedIconFilter` so host filters are not cleared.
- Setting a static image now calls `applyIconColor()` again when tintsStaticImageAutomatically is true, so a newly shown image gets the correct tint.
- Filter type changed from `setColorFilter(color, SRC_IN)` to a `PorterDuffColorFilter(color, SRC_IN)` assigned to iconView.colorFilter.
- The `applyIconTintColor` doc now says the built-in colour also tints one-colour static images under Automatic, where before it applied only to animations.
- The diff spans d5f1b436..5958f8a3 and changes 59 insertions and 5 deletions in Example-Android/cylanimateditem/src/main/kotlin/com/cyl/animateditem/CYLAnimatedItemView.kt.

Files read: Example-Android/cylanimateditem/src/main/kotlin/com/cyl/animateditem/CYLAnimatedItemView.kt

Concepts: what-changed, how-it-works, trade-off

---

### #210 — Android and HarmonyOS contrast checks now judge the byte-rounded colour (GitHub)
bugfix · 2026-11-27 12:15 UTC
The lift loop tests contrast on whole-byte channel values, so rounding can no longer drop a lifted colour below the minimum ratio.

Applied the requested fix for the rounding gap in contrast lifting. On HarmonyOS, the ratio helper now evaluates contrast on the same whole-byte colour that adjustedToReference writes, so the lifted result keeps the ratio it was judged by. On Android, passes() in the adjusted() loop now uses the same byte rounding before comparing against the minimum, which closes the equivalent gap that earlier inspection found. The mini program already tests byte-rounded colours, so it needed no change. The edits were made with a scripted replace that enforces a single match and preserves line endings.

- Android CYLAnimatedItemContrast.kt adjusted() gained a local byte(value) helper that rounds each channel to 0..255 and divides by 255 before computing relative luminance.
- Android passes() in CYLAnimatedItemContrast.kt now calls relativeLuminance(byte(rgb[0]), byte(rgb[1]), byte(rgb[2])) instead of the unrounded channel values.
- HarmonyOS CYLAnimatedItemContrast.ets private static ratio() now rounds each RGB component with Math.round(clamped value * BYTE_MAX) / BYTE_MAX before computing contrast.
- The HarmonyOS fix is documented in a bilingual comment citing the observed failure: #FF007373 on #FF1C1C1E measured 2.9977:1, below the 3:1 floor.
- BYTE_MAX is defined as 255 in CrossPlatform/harmonyos-cyltabbar/cylanimateditem/src/main/ets/CYLAnimatedItemContrast.ets at line 15.
- Both edits preserve CRLF line endings, detected from the existing file contents by a Python script that asserts each target string occurs exactly once.
- The mini program contrast file was not edited in this step because its ratioAt() already uses byte-rounded values.

Files read: CrossPlatform/harmonyos-cyltabbar/cylanimateditem/src/main/ets/CYLAnimatedItemContrast.ets, Example-Android/cylanimateditem/src/main/kotlin/com/cyl/animateditem/CYLAnimatedItemContrast.kt

Concepts: problem-solution, gotcha

---

### #267 — WeChat miniprogram Liquid Glass gallery page defines four panels driven by the core cyl-tab-bar (GitHub)
discovery · 2026-11-28 11:48 UTC
The glass example page under example/miniprogram/pages/glass shows checkin, feed, cards, and landing panels, switched by a cyl-tab-bar with item-style and glass-lens-style bindings.

Reading pages/glass/index.wxml shows the Liquid Glass example in the WeChat miniprogram port. One page holds four panels (check-in, feed, cards, landing) and the core cyl-tab-bar switches between them through the panel value, while item-style and glass-lens-style control the glass look. The landing panel is where the tab item styles and tap animations are demonstrated. Search and tag filtering appear only in the feed panel. Labels pass through a localization map, and interactive elements carry ARIA attributes.

- pages/glass/index.wxml is a 107-line WeChat miniprogram template in CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram.
- The page root view applies a class cyl-glass-page-{{panel}}, so the active panel name drives page-level styling.
- The page renders four panels conditionally by wx:if on panel: checkin, feed, cards, and landing.
- A cyl-tab-bar element with id cyl-gallery-tab-bar at the bottom takes configuration, symbols-by-theme, selected-identifier bound to panel, item-style, and glass-lens-style, and emits bind:select to cyl_onSelect.
- The landing panel renders cyl-tab-bar-item elements with animation-class bound to playing[item] and animation-duration 500, and a button that toggles item style between flat and liquidGlass.
- The feed panel has a search input shown only when panel is feed, bound to cyl_search, and a horizontally scrolling tag pill row bound to cyl_selectTag.
- Accessibility attributes such as aria-role, aria-label, and aria-selected are applied to interactive elements, and all visible labels come from a texts lookup.
- The page's visual structure comes from comments naming inspirations: mirror-landing for the landing and blobs, sports-checkin for check-in, and chatnote plus a community project for the feed.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\glass\index.wxml, CYLTabBarController/CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/glass/index.wxml

Concepts: how-it-works, pattern

---

### #270 — WeChat miniprogram glass gallery page styles defined in index.wxss (GitHub)
discovery · 2026-11-28 11:48 UTC
The gallery page's own stylesheet covers backgrounds, glass cards, nav, and tiles, while tab bar and lens styling come from the core.

The glass gallery page's index.wxss was read in the WeChat miniprogram example. It holds only the page-level look: gradient backgrounds, floating blobs, translucent nav and search, cards, grids, a check-in circle, feed pills, and a landing hero. The tab bar and its liquid glass lens are excluded and come from the core CYLTabBarItemStyle liquidGlass setting. The header documents inspiration from three other miniprogram projects with code written fresh.

- The glass gallery page stylesheet is example/miniprogram/pages/glass/index.wxss in the wechat-miniprogram-cyltabbar CrossPlatform package.
- The stylesheet states that the tab bar and its Liquid Glass lens are not styled there; they come from the core via CYLTabBarItemStyle liquidGlass.
- The page defines three gradient background variants: .cyl-glass-page (purple #667eea to #764ba2), .cyl-glass-page-feed (dark teal), .cyl-glass-page-cards (purple to orange), and .cyl-glass-page-landing (solid #0b0b14).
- Floating blur blobs (.cyl-glass-blob-1 to -3) animate through the cyl-glass-float keyframes over 18s, with blur(60px) and 0.55 opacity.
- Translucent cards (.cyl-glass-card) use a 20px radius, rgba white 0.15 background, backdrop-filter blur(16px), and an inset highlight shadow.
- The navigation bar and search box use backdrop-filter blur(20px) saturate(160%) with rgba white translucent fills.
- Entry animations use spring-like cubic-bezier(0.19, 1, 0.22, 1) easing for slide-up, scale-in, and check-in transitions.
- Feed pills, tiles (two-column grid), check-in circle (180px, gradient toggling to green when checked), and landing CTA are styled in the same file.
- The file header states that design ideas came from sports-checkin-miniprogram, chatnote-miniprogram, and mirror-landing, and that the code was written anew with no code copied.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\glass\index.wxss, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/glass/index.wxss

Concepts: how-it-works, pattern

---

### #271 — WeChat miniprogram home page mirrors the iOS Objective-C example's first tab (GitHub)
discovery · 2026-11-28 11:48 UTC
The home page's demo rows, badge rows, language switching, skin menu, and tab bar actions are driven by shared demo-list data and globalData tab bar state.

The home page of the WeChat miniprogram example was read in full. It reproduces the iOS Objective-C home table: shared demo sections, a Tab Bar Gallery row, and badge rows in matching order. Row data is sourced from the generated shared demo list. Rows the miniprogram supports (language, skins, selected index, login, swipe, touchable area, tab title and icon updates, scroll-hiding) act on the core tab bar through globalData.cylTabBarState via cyl_updateTabBarState. Other rows delegate to cylHomeAction. Language switching and skin selection both persist through the global state and, for language, relaunch the page. The file gives a complete map of which demo rows are functional in the miniprogram versus iOS-only.

- The miniprogram home page at example/miniprogram/pages/home/index.js mirrors the iOS Objective-C example's CYLHomeViewController table, following the AGENTS.md "Demo table rows" rule.
- Demo rows come from Example-Shared/DemoList/demo-list.json, surfaced through shared/demo_list.js, which is generated by scripts/cyl_sync_shared.js.
- Rows the miniprogram supports act on the app's TabBar state; unsupported rows state they are only in the iOS example.
- Supported languages are en, zh-Hans, hi, es, and ar; Arabic is treated as RTL, and unknown languages fall back to a "🌐 language" label.
- Navigation frame is computed from wx.getWindowInfo and wx.getMenuButtonBoundingClientRect, with a fallback of top 20, height 44, right 100, menuHeight 400.
- Badge rows use five animation names (scale, shake, bounce, breathe, rotation), with only the first five CSS-animated and others static; badge text clamps to "${maximum}+" when value exceeds maximum, default 99.
- Badge styling converts sample fields to inline CSS, mapping radius to width and height at 2× radius and borderColor 'dynamic' to var(--cyl-background, #ffffff).
- The skin menu lists each CYL_DEMO_SKINS entry plus a "Follow the system Dark Mode" option; selecting the system option toggles cyl_setSkinFollowsSystem, otherwise cyl_setSkin(id) is called.
- Changing language calls cylSetLanguage, writes globalData.cylLanguage, and relaunches the page via wx.reLaunch to /pages/home/index.
- The selectedIndex row advances to the next non-plus tab with wrap-around, computed as (current+1) % count, and calls bar.cyl_onTap.
- onPageScroll hides or shows the tab bar under OnScrollDown or OnScrollUp behavior when scroll delta is at least 8px and top exceeds 60px; Automatic and Never do nothing.
- The touchableArea row toggles overrides.cylDemoTouchableArea.shows and sets a scale from 1 to 3 in 0.1 steps.
- The page's cyl_values builds status labels for tap-animation step, sound step, login state, and login-required tab titles from CYLTabBarController attributes.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\home\index.js, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/home/index.js

Concepts: how-it-works, pattern

---

### #272 — WeChat miniprogram home page template structure and nav controls (GitHub)
discovery · 2026-11-28 11:48 UTC
The home page WXML lays out a custom nav with flat-design, skin, and liquid-glass buttons, a skin menu, and section rows with switch, slider, arrow, and badge accessories.

The home page WXML was read in full. It implements the miniprogram version of the iOS CYLHomeViewController navigation bar, with the flat-design and liquid-glass buttons carrying animated colored dots and a skin button opening a popup theme menu. Section rows are generic and render accessories conditionally by row.accessory value. Switches and sliders suppress row taps with catchtap, and arrows drive adjacent tab switching. Badge rows reuse the same row layout with the badge positioned at the right. RTL layout is handled through a page-meta page-style binding.

- The home page template at example/miniprogram/pages/home/index.wxml sets page-style direction to rtl when cylRTL is true, supporting Arabic layout.
- The custom nav bar has a "Flat Design" button with a breathing dot, and "Skin" and "Liquid Glass" buttons, with the Liquid Glass button carrying a shaking dot; dot colors come from nav.dots.
- The nav buttons bind to cyl_onFlatDesign, cyl_onSkinButton, and cyl_onLiquidGlass, and the nav container uses nav.top, nav.height, and nav.right for padding to clear the WeChat capsule.
- The skin menu renders only when skinMenu is non-null, as a backdrop with a scroll-view capped at nav.menuHeight, listing rows with a ✓ check on the current skin and a "system" row preceded by a separator.
- Each skin row shows either an icon image or a colored swatch with a glyph, and binds cyl_onSkinMenuRow with data-id.
- The large navigation title element with id cyl-navigation-title displays navigationTitle, because the capsule leaves no room for it between the nav buttons.
- Section rows support five accessory types: switch (cyl_onSwitch), chevron, check, arrows (cyl_onArrow with step -1 and 1), and a slider with min 1, max 3, step 0.1 (cyl_onTouchSlider).
- Switches and sliders use catchtap="cyl_noop" so taps on them do not propagate to the parent row's cyl_onRow handler.
- Badge rows bind cyl_onBadge with data-index, and render a badge element with position class, animation class, and inline style, showing no text when the badge is a dot.
- The page header text references Example-Shared/Configurations/cyl_tabbar_configuration.json and a raised plus button, and all user-facing strings resolve through the texts map.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\home\index.wxml, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/home/index.wxml

Concepts: how-it-works, pattern

---

### #284 — WeChat miniprogram home page stylesheet defines badge, nav bar, and skin menu styling (GitHub)
discovery · 2026-11-28 11:48 UTC
The home page index.wxss mirrors the iOS Objective-C table's subtitle rows, badge animations, nav bar, and skin menu.

The WeChat miniprogram home page styles are a direct port of the iOS Objective-C example's first tab. The stylesheet reproduces subtitle table rows, corner badges with five animation variants, a custom Liquid Glass-style navigation bar drawn by the page, and a skin menu opened under the Skin button. Dark mode is handled through prefers-color-scheme media queries that override the row separator, badge host, nav background, and menu colors. Comments reference the exact iOS symbols (CYLBadgeAppearance defaults, UITableViewCell+CYLBadgeExtention, -cyl_themeMenuWithCompletion:), so the miniprogram defaults stay traceable to the native implementation.

- The miniprogram home page stylesheet at example/miniprogram/pages/home/index.wxss is 288 lines and mirrors the iOS Objective-C example's table cells and controls.
- Subtitle rows (.cyl-home-row) use a 44px minimum height, 10px/16px padding, and a 1rpx top border that turns rgba(255,255,255,0.15) in prefers-color-scheme: dark.
- Badges (.cyl-home-badge) default to red #ff3b30, 9px bold white text, 16px height, and 8px radius, positioned at one of four corners with offsets of -8px vertically and 22px horizontally.
- Badge animation classes cover scale (0.8s), shake (0.6s), bounce (0.8s), breathe (1.6s), and rotation (1.2s) using shared @keyframes cyl-badge-*.
- The custom navigation bar (.cyl-nav) is fixed at the top with z-index 10, a rgba(242,242,247,0.92) background, and a dark-mode background of rgba(0,0,0,0.88).
- Navigation bar buttons (.cyl-nav-button) are 30px tall with a 15px radius and a rgba(120,120,128,0.16) background, and nav dots (.cyl-nav-dot) are 8px circles.
- The skin menu (.cyl-menu) is absolutely positioned 260px wide at right 12px with a 14px radius, a 0.98-opacity background, and a dark-mode background of rgba(44,44,46,0.98).
- Each stylesheet rule carries bilingual [EN] and [CN] comments that name the iOS source symbol it reproduces, such as CYLBadgeAppearance defaults and UITableViewCell+CYLBadgeExtention.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\home\index.wxss, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/home/index.wxss

Concepts: how-it-works, pattern

---

### #285 — WeChat miniprogram item playground exercises every cyl-tab-bar-item API group in one page (GitHub)
discovery · 2026-11-28 11:48 UTC
The item/index.js page renders eleven tiles, one per CYLFlatDesignTabBarItem API group, and toggles selection on tap.

The item playground is the miniprogram counterpart of the iOS CYLFlatDesignTabBarItem API. Each tile isolates one property group so the cyl-tab-bar-item component can be verified without a full tab bar. Tapping a tile flips its selected state, mirroring how a real tab behaves, and disabled tiles are inert. The page documents its own mapping to the iOS docs in bilingual comments, which keeps the WeChat port traceable to the native API surface.

- The item playground page at example/miniprogram/pages/item/index.js defines 11 tiles in data.tiles, each with a caption naming the API properties it demonstrates.
- Tile captions cover title/image/selectedImage, lottieFilePath/lottieSizeValue, badgeValue/badgeColor, badgeSize/badgePositionAdjustment, badgeContentInset/badgeTextAttributes, titleTextAttributes, titlePositionAdjustment/imagePositionAdjustment, imageInsets, layoutCentered, backgroundColor/selectedBackgroundColor, standardAppearance, and enabled.
- Badge tile values are badgeValue '8' with badgeColor '#34C759', a dot badge with badgeSize '{10, 10}', and an inset badge with badgeValue 'NEW' and badgeContentInset '{2, 8, 2, 8}'.
- The standardAppearance tile sets stackedLayoutAppearance.selected with iconColor, titleTextAttributes, and badgeBackgroundColor all '#AF52DE'.
- The cyl_itemTap handler ignores taps on tiles whose props.enabled is false, toggles props.selected through setData on the tapped index, and shows a wx.showToast reading "itemtap <index>".
- Image and Lottie assets load from the /shared/skins/2.1.0/light/ and /shared/lottie/ paths.
- The page file is 38 lines and its comments cite docs/WeChat-Mini-Program.md, section "cyl-tab-bar-item and CYLFlatDesignTabBarItem".

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\item\index.js, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/item/index.js

Concepts: how-it-works, pattern

---

### #286 — Item playground template binds each tile's props to cyl-tab-bar-item attributes via kebab-case (GitHub)
discovery · 2026-11-28 11:48 UTC
The item/index.wxml template renders one cyl-tab-bar-item per tile, wiring 22 props and the itemtap event to the page's data.

The item playground template is a thin renderer over the tiles data defined in pages/item/index.js. It passes every CYLFlatDesignTabBarItem property through as a kebab-case component attribute, so the same prop names documented for iOS work in the WeChat component. Enabled state is normalized in the template rather than in data, and accessibility labeling is handled at the tile wrapper level to avoid duplicate announcements from the caption.

- The item playground template at example/miniprogram/pages/item/index.wxml loops over {{tiles}} with wx:for and keys each tile by caption.
- Each tile renders one cyl-tab-bar-item with id "cyl-demo-item-{{index}}" and class "cyl-item-demo", and passes index and 21 other props bound from item.props.
- Camel-case props map to kebab-case attributes, for example selectedImage to selected-image, badgeContentInset to badge-content-inset, and standardAppearance to standard-appearance.
- The enabled attribute is bound as {{item.props.enabled !== false}}, so tiles without an explicit enabled value default to enabled.
- The itemtap event is bound with bind:itemtap="cyl_itemTap", which the page's handler in pages/item/index.js consumes.
- Each tile has an aria-label set to its caption, and a visible caption text element is marked aria-hidden="true", so screen readers get the label from the tile wrapper.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\item\index.wxml, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/item/index.wxml

Concepts: how-it-works, pattern

---

### #288 — WeChat miniprogram lottie playground switches between Lottie, PAG, and Rive assets at runtime (GitHub)
discovery · 2026-11-28 11:48 UTC
The lottie/index.js page selects its animation backend from the installed package and, for Rive, advances house.riv's Rooms number input on each play.

The lottie playground is a single page that exercises one cyl-lottie-miniprogram component across three animation backends. The backend is chosen at load time from the installed package, so the same controls drive Lottie JSON, PAG binaries, or Rive state machines. The Rive path needs special handling: cyl-rive's play only resumes, so the page calls cyl_playFromStart to actually trigger house.riv's Rooms transition, cycling through 3 to 6. The page also localizes its labels from the shared demo string table and wires end-of-animation, recolor, and event-logging demos into the same view.

- The lottie playground at example/miniprogram/pages/lottie/index.js targets the cyl-lottie-miniprogram component, a sub-dependency of cyl-tabbar-miniprogram.
- onLoad branches on cylInstalledAnimation(): 'pag' loads PAG icon files from cylAvailableAnimationFiles(), and 'rive' maps CYL_RIVE_FILES onto installed .riv.bin files.
- CYL_RIVE_FILES defines icons.riv (artboard CHAT, state machine CHAT_Interactivity, boolean input active) and house.riv (state machine "State Machine 1", NUMBER input Rooms, values 3,4,5,6).
- Rive entries are skipped when their file is not among the installed animation files, and the page only switches to Rive mode when at least one entry matches.
- cyl_play calls cyl_playFromStart on the cyl-playground component when isRive is set, because cyl-rive's cyl_play only resumes playback and does not set the next Rooms value.
- The default Lottie files are green_lottie_tab_home, green_lottie_tab_discover, and green_lottie_tab_mine, loaded from /shared/lottie/<name>.json.
- The end-of-animation demo uses the #cyl-end-item component's playAnimation, tracks completed passes in endCount, and toggles endImage for showsImageWhenAnimationEnds.
- The event log keeps the four most recent events, and tapping an event row copies its text via wx.setClipboardData.
- Recolor sets colors to {'**': '#FF3B30'} when toggled on and to null when toggled off.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\lottie\index.js, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/lottie/index.js

Concepts: how-it-works, gotcha, pattern

---

### #289 — Lottie playground template selects cyl-pag, cyl-rive, or cyl-lottie by wx:if branch and reuses one playground id (GitHub)
discovery · 2026-11-28 11:48 UTC
The lottie/index.wxml template renders exactly one animation backend per load, all bound to the same #cyl-playground id that the page's JS calls.

The lottie playground template uses a three-way conditional so one page can host the PAG, Rive, or Lottie backend without duplicating controls. Because every branch reuses id="cyl-playground", the page logic can call the same methods regardless of backend. The Recolor and speed attributes exist only on some branches, so those controls are effectively Lottie-only. The showsImageWhenAnimationEnds demo is also gated to Lottie, since PAG and Rive files do not use that option. Accessibility is handled by aria-label on interactive rows and aria-hidden on the visible text inside them.

- The lottie playground template at example/miniprogram/pages/lottie/index.wxml chooses one of three components with wx:if="{{isPAG}}", wx:elif="{{isRive}}", and wx:else.
- All three playground components share id="cyl-playground", which matches the selectComponent('#cyl-playground') lookup in pages/lottie/index.js.
- The cyl-lottie branch is the only one that binds colors="{{colors}}", so the Recolor switch has no effect in PAG or Rive mode.
- The cyl-rive and cyl-pag branches omit the speed and colors attributes, while cyl-pag also omits speed.
- The showsImageWhenAnimationEnds section renders only when !isPAG && !isRive, using a cyl-animated-item with id="cyl-end-item" and generic:cyl-lottie-view="cyl-lottie".
- The end-item demo uses animation-url /shared/lottie/green_lottie_tab_home.json, a static image /shared/objc/home_highlight.png, and icon-size 72.
- Each animation view binds bind:ready, bind:complete, bind:loopcomplete, and bind:error to the cyl_event handler, while the end item binds bind:animationcomplete to cyl_endItemComplete.
- Rows for files, speeds, and fits use aria-role="button" with aria-selected, and labels use texts from the localization map.

Files read: CrossPlatform\wechat-miniprogram-cyltabbar\example\miniprogram\pages\lottie\index.wxml, CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/lottie/index.wxml

Concepts: how-it-works, gotcha, pattern

---

### #300 — Android CYLTabBar "More" tab behavior pinned by Robolectric tests (GitHub)
discovery · 2026-11-28 11:48 UTC
CYLTabBarMoreTest.kt defines how the Android tab bar overflows extra view controllers into a "More" list, matching iOS.

The Android test class CYLTabBarMoreTest specifies the "More" overflow tab behavior for CYLTabBarController. The rule mirrors iOS: with more than five view controllers, the bar shows the first four tabs (three when a plus button has its own page) and a More button, which opens a scrollable list of the hidden tabs. The tests cover selection and delegate callbacks (shouldSelect can veto More), row selection with badge text in the content description, highlight state of More for hidden tabs, and opt-out paths through cyl_showsAllTabs, the configuration key CYLTabBarControllerShowsAllTabs, and the Scrollable scroll mode. Together these tests define the intended contract for Android overflow navigation.

- Android CYLTabBarController shows the first four tabs and a "More" button when it has more than five view controllers, matching the iOS behavior.
- When a plus button has its own page, the overflow rule shows only three regular tabs plus "More" (five tabs plus the plus page equals six, so the count is three).
- Exactly five tabs produce no More button and all five tab buttons are visible.
- With seven tabs, the hidden tab buttons are set to View.GONE, the More button has the same width as the other tab buttons, and every tab keeps its button in tabBarButtonArray.
- Selecting More calls the delegate's shouldSelect and didSelect with the More view controller, and the More list shows the three hidden tabs as rows.
- The delegate can refuse selection of the More view controller, in which case the selected index stays at 0 and More is not selected.
- Tapping a hidden-tab row selects that tab, keeps the More button highlighted while that tab is active, and clears the highlight when a visible tab is selected.
- A badge on a hidden tab is read into its More row's contentDescription, which begins with the tab title and includes the badge value.
- Setting cyl_showsAllTabs to true, or the CYLTabBarControllerShowsAllTabs configuration key, removes the More button and shows all seven tabs. Setting it back to false restores More.
- Switching cyl_scrollMode to Scrollable also removes the More button and shows all tabs.
- Selecting a hidden tab in code via selectedIndex shows its page and highlights More.
- The test suite is a Robolectric RobolectricTestRunner class configured with sdk 34.

Files read: Example-Android\cyltabbar\src\test\kotlin\com\cyl\tabbar\CYLTabBarMoreTest.kt, Example-Android/cyltabbar/src/test/kotlin/com/cyl/tabbar/CYLTabBarMoreTest.kt

Concepts: how-it-works, pattern

---

### #306 — Android demokit DemoInteractions exercises the CYLTabBarController API surface (GitHub)
discovery · 2026-11-28 11:49 UTC
DemoInteractions.kt mirrors the iOS settings and tab-item update demos, covering tab icons, animations, feedback, plus-button variants, and gesture settings.

DemoInteractions.kt is the Android counterpart of the iOS settings demos in the example app. It is organized into sections: in-place tab updates (titles, icons, network and local icons, GIFs), page replacement and selection, login gating, PlusButton variants, tap animations and feedback, long-press and swipe gestures, slide transitions, and helper utilities. Each section maps to a numbered issue in the CYLTabBarController tracker, such as #481, #515, #535, and #202. The file therefore serves as a manual integration catalog of the Android API, and it is the place to look when checking which features Android exposes and how they are configured.

- DemoInteractions.kt is a 449-line Kotlin object in the Android demokit module that mirrors iOS UIViewController+CYLSettingsSection and UIViewController+CYLTabBarItemUpdate.
- Tab updates in place are tracked in a WeakHashMap keyed by CYLTabBarController, and each toggle applies a change on first tap and restores the original on second tap.
- The demo downloads four pairs of flaticon PNGs for network tab icons and uses setTabBarItemIconWithURL with CYLSize(24,24).
- The "Use local icons for every tab" option cycles index % 3 across android.R.drawable.star_big_on, the asset cyl_tab_sample_animated.gif, and a 48x48 green oval.
- The GIF icon option sets CYLTabBarGIFFilePath to file:///android_asset/cyl_tab_sample_animated.gif.
- Tab tap animation choices include None, Scale, ZoomIn, Bounce, BounceWithFireworks, Rotation, Flip, Fume, slow Scale and ZoomIn at 1.2 s, Star fireworks, Curl up, and a single-tab rotation.
- Tap feedback choices are Off, default tap sound, custom notification sound, light, medium, or heavy haptic, and tap sound plus medium haptic.
- Long-press duration options are 0.3, 0.5, and 1.0 s, crossed with double-tap intervals of 0.2, 0.3, and 0.5 s.
- Login-state demo sets cyl_loginRequiredTabBarItemIdentifiers to DemoCatalog.ME and "me", and shows an AlertDialog that completes with true or false.
- The PlusButton touchable-area demo uses a SeekBar with max 20 and scale 1 + progress/10, and shows a message when the tab bar has no plus button.
- LateImagePlusButton delays its image by 2000 ms and swaps to a large image after a further 1000 ms.
- CloseSubviewPlusButton draws a red close control at the top right that clears to a random color instead of triggering the plus action, with multiplierOfTabBarHeight set to 0.3f.
- NavigationBarHiddenPage hides supportActionBar in onResume and restores it in onPause.

Files read: Example-Android\demokit\src\main\kotlin\com\cyl\tabbar\demo\DemoInteractions.kt, Example-Android/demokit/src/main/kotlin/com/cyl/tabbar/demo/DemoInteractions.kt

Concepts: how-it-works, pattern

---

### #308 — CYLTabBarController working tree has uncommitted miniprogram edits and stray untracked artifacts (GitHub)
discovery · 2026-11-28 11:53 UTC
git status on feat/cross-platform-components shows two modified miniprogram example files plus untracked pages, a stray HarmonyOS "C" entry, and a React Native build cache.

A short git status on CYLTabBarController shows the working tree is dirty. The miniprogram example has modified package files and two new page stylesheets that have not been committed. A stray untracked entry named "C" appeared under the HarmonyOS package, and a .cxx.longpath-old build cache sits under the React Native Android example. The learn-codebase rule keeps dirty files in place and excludes them from commits, so these are noted as state to preserve, not cleanup targets.

- CrossPlatform/wechat-miniprogram-cyltabbar/example/package-lock.json and example/package.json have uncommitted modifications.
- CrossPlatform/wechat-miniprogram-cyltabbar/example/miniprogram/pages/message/index.wxss and pages/publish/index.wxss are untracked files.
- An untracked entry named "C" exists under CrossPlatform/harmonyos-cyltabbar/, which looks like a stray file or a path created by a shell mistake.
- CrossPlatform/react-native-cyltabbar/example/android/app/.cxx.longpath-old/ is an untracked native build cache directory.
- The status check used rtk git status --short and made no changes to the repository.

Concepts: problem-solution, gotcha
