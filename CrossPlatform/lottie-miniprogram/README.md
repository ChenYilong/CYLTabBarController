# cyl-lottie-miniprogram

The CYLTabBarController fork of [wechat-miniprogram/lottie-miniprogram](https://github.com/wechat-miniprogram/lottie-miniprogram)
(MIT, imported at 49066a6): the library, with the upstream's open pull requests merged and its issues fixed (status
table: [docs/WeChat-Mini-Program.md](../../docs/WeChat-Mini-Program.md#enlottie-miniprogram-issues)), plus the
`cyl-lottie` component.

| Change | Upstream reference |
|:---|:---|
| lottie-web 5.13 light canvas build: no `eval` (animations with expressions play without them), 210 KB instead of 268 KB | PR #45, issues #2, #8, #40, #51, #56 |
| Frames from `canvas.requestAnimationFrame` of the latest live canvas; several canvases at once; load again after `destroy()` | PR #50, issues #16, #55, #58 |
| `destroy(name)` | PR #17, issues #1, #13 |
| `path`: network URL or a package / user data file, loaded before lottie starts; `DOMLoaded` / `data_failed`; zip / .lottie refused clearly | issues #15, #42, #47 |
| Offscreen canvas for image processing, base64 images written to files, images from the animation's own canvas | issues #4, #10, #29, #30, #36 |
| `setFrameInterval(ms)`, clear `setup()` errors, `XMLHttpRequest` declared in the module (mini games) | issues #28, #32, #53 |
| TypeScript types without DOM typings; default export | issues #18, #41 |

## cyl-lottie component

```json
{ "usingComponents": { "cyl-lottie": "cyl-lottie-miniprogram/cyl-lottie/index" } }
```

```xml
<cyl-lottie path="/assets/home.json" loop="{{false}}" autoplay colors="{{ {'**.Fill 1': '#FF0000'} }}" style="width: 60px; height: 60px" />
```

Properties: `path`, `animationData`, `loop`, `autoplay`, `speed`, `colors` (keypath -> color), `fit` (contain, cover,
fill), `restingFrame` (first, last), `label`. Events: `ready`, `complete`, `loopcomplete`, `error`. Methods:
`cyl_play`, `cyl_pause`, `cyl_stop`, `cyl_playFromStart`, `cyl_goToAndStop`, `cyl_goToAndPlay`, `cyl_playSegments`,
`cyl_setSpeed`, `cyl_refreshLayout`, `cyl_animation`. The canvas is sized for the pixel ratio, so animations stay sharp on devices
(issues #12, #23, #26).

Build: `npm install && npm run build` (writes `miniprogram_dist`, committed); test: `npm test`.

---

## Upstream README

### Lottie for MiniProgram

[![](https://img.shields.io/npm/v/lottie-miniprogram)](https://www.npmjs.com/package/lottie-miniprogram)
[![](https://img.shields.io/npm/l/lottie-miniprogram)](https://github.com/wechat-miniprogram/lottie-miniprogram)

lottie 动画库适配小程序的版本。

> lottie 的相关介绍与动画生成方法等请参考[官方说明](https://github.com/airbnb/lottie-web)

> 依赖小程序基础库版本 >= 2.8.0 的环境

## 使用

可参考该代码片段：[https://developers.weixin.qq.com/s/2TYvm9mJ75bF](https://developers.weixin.qq.com/s/2TYvm9mJ75bF)。大致步骤如下：

1. 通过 npm 安装：
```
npm install --save lottie-miniprogram
```

2. 传入 canvas 对象用于适配
```
<canvas id="canvas" type="2d"></canvas>
```
```
import lottie from 'lottie-miniprogram'

Page({
  onReady() {
    this.createSelectorQuery().select('#canvas').node(res => {
      const canvas = res.node
      lottie.setup(canvas)
    }).exec()
  }
})
```

3. 使用 lottie 接口
```
lottie.setup(canvas)
this.ani = lottie.loadAnimation({
  ...
})
this.ani.destroy() // 页面退出需销毁
```

## 接口

目前提供两个接口：

#### lottie.setup(canvas)
需要在任何 lottie 接口调用之前调用，传入 canvas 对象

#### lottie.loadAnimation(options)
与原来的 [loadAnimation](https://github.com/airbnb/lottie-web/wiki/loadAnimation-options) 有些不同，支持的参数有：
* loop
* autoplay
* animationData
* path （只支持网络地址）
* rendererSettings.context （必填）

## 说明
* 本项目是以 npm 的方式依赖原 lottie-web 项目，若原项目有新版本，可直接改变依赖的版本号。
* 本项目依赖小程序基础库 2.8.0 里性能更好的 canvas 实现，由于还有些小问题~~没有正式开放~~（2.9.0 已正式对外），但目前用在此处暂无发现问题。
* 由于小程序本身不支持动态执行脚本，因此 lottie 的 expression 功能也是不支持的。
