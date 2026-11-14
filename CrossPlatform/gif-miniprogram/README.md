# cyl-gif-miniprogram

GIF tab icons for [cyl-tabbar-miniprogram](../wechat-miniprogram-cyltabbar), one of the four animation packages
(`cyl-lottie-miniprogram`, `cyl-pag-miniprogram`, `cyl-rive-miniprogram`, `cyl-gif-miniprogram`) that an app installs
as it needs. GIF needs no runtime: `cyl-tab-bar` shows a GIF with `<image>`, which plays it natively, so this package
has no component and adds nothing to the code package but the icons you copy.

```json
{ "CYLTabBarGIFFilePath": "/shared/gif/tab_rocket.gif", "CYLTabBarGIFSize": "{30, 30}" }
```

The keys: `CYLTabBarGIFFilePath`, `CYLTabBarGIFURL` and their `Dark` variants, or a `.gif` file in
`CYLTabBarAnimationFilePath`; the GIF shows while the tab is selected. The example's icons (`cylExampleResources` in
`package.json`) are the GIFs of the iOS `Example-GIF`, from Google's
[Noto Emoji Animation](https://googlefonts.github.io/noto-emoji-animation/) (CC BY 4.0, resized to 96 px).
See [docs/WeChat-Mini-Program.md](../../docs/WeChat-Mini-Program.md).
