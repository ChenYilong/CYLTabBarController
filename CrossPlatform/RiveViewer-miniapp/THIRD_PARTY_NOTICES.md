# 第三方许可说明

本项目自身原创源代码使用 `PolyForm-Noncommercial-1.0.0`。下列第三方组件和资源不适用该许可证，仍遵循各自的许可条款。

## Rive Canvas Advanced / WebGL2 Advanced 2.39.1

对应包：`@rive-app/canvas-advanced@2.39.1`、`@rive-app/webgl2-advanced@2.39.1`。

来源：<https://github.com/rive-app/rive-wasm/tree/a7629a91010ef99f05629f1fd1836a08afcf2cbd>

MIT License

Copyright (c) 2020-2021 Rive

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Phosphor Icons Core 2.1.1

来源：<https://github.com/phosphor-icons/core>

MIT License

Copyright (c) 2023 Phosphor Icons

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## 内置 Rive 示例资源

`assets/samples/` 下的 `.riv` 文件及其小程序数据模块只用于展示和测试本项目。它们不适用项目的 PolyForm 许可证，也不授予脱离本项目单独复用、再授权或商业使用的权利。

## H5 播放器与界面依赖

以下版本由 `h5/package-lock.json` 固定。完整发布包许可、版权声明及
libpag 的第三方组件通知保存在
[`h5/public/rive-viewer/THIRD_PARTY_NOTICES.txt`](h5/public/rive-viewer/THIRD_PARTY_NOTICES.txt)，
随 H5 静态构建一同复制。再分发相关运行库或 WASM 时应一并保留这些文本。

- `libpag@4.5.85`：主体为 Apache-2.0，其第三方组件遵循发布包中的各自条款。
  npm 发布元数据指向上游提交 `c62385ba661b7230bcdf09c28bd2347eea2854c1`；
  [上游完整许可](https://github.com/Tencent/libpag/blob/c62385ba661b7230bcdf09c28bd2347eea2854c1/LICENSE.txt)
  与该版本 npm 包中的 LICENSE.txt 一致。
- `lottie-web@5.13.0`：MIT，Copyright (c) 2015 Bodymovin。
  [上游许可](https://github.com/airbnb/lottie-web/blob/bede03d25d232826e0c9dca1733d542d8a7754fb/LICENSE.md)。
- `calligraph@1.4.1`：MIT，Copyright (c) 2026 Raphael Salaja。
  [上游许可](https://github.com/raphaelsalaja/calligraph/blob/c99497a440e280e8471f084db1173197ba0e255c/packages/calligraph/LICENSE)。
- `react@19.2.6`、`react-dom@19.2.6`、`scheduler@0.27.0`：MIT。
- `motion@13.1.1`、`framer-motion@13.1.1`、`motion-dom@13.1.1`、
  `motion-utils@13.0.0`：MIT；各发布包的版权声明分别保留。
- `tslib@2.8.1`：0BSD；同时保留发布包中的 CopyrightNotice.txt。

libpag 的完整上游通知包含多平台组件。保留原文不表示其中每个组件都
编入本项目的浏览器构建；实际分发范围仍需结合对应构建核验。

## 素材边界与待核实项目

运行库许可不等于 `.riv` 动画、头像或品牌图像的素材许可。除上面已有的
Rive 示例说明外，`h5/public/rive-viewer/avatars/` 下的头像、
`share-friend.png`、`share-timeline.png` 及品牌图像的来源和复用权限仍需分别核实。
本次补充只保留软件依赖原有的许可和通知，不为这些素材新增授权，
也不更改任何已有的单独许可。
