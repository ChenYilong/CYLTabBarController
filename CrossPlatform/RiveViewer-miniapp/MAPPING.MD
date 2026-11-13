# 元素映射

当前发布版本为 `1.0.7`；下表补充统一渲染档位、性能状态、H5 缩略图、双栏布局与 Gentle 手柄反馈。

| 俗称 | 学名 | 代码名称 |
| --- | --- | --- |
| 文件操作快捷键 | Platform file shortcuts | `file-shortcuts.ts` 解析 Mac Command / Windows Ctrl；`handleFileShortcut` 捕获阶段分派；`ActionTooltip.tsx` 通过 Portal + Popover 顶层显示 `data-shortcut-tip`；复制键为单按 L；`ShortcutHelp` 详情右上角说明 |
| 文件右键菜单与归档 | Shared file actions | `FileActionsMenu.tsx` 的 `FileMenuActions` / `FileContextMenu`；`RiveViewerApp.tsx` 详情归档入口与快捷键 |
| 文件重命名 | Hosted share custom name | `HostedFileName.tsx`、`hosted-share-name.ts`、`renameHostedShare`、`POST /api/v1/shares/:code/rename`；`customName: null` 跟随上传名，非空时跨版本保留；标题只改名，评论区 `.comment-version-heading` 切换版本 |
| JOJO 品牌标记 | Edition-specific brand signature | `Brand hosted={isHostedPlatform}`；`.brand-signature` 仅在托管模式渲染 |
| H5 本地版 | Local-only H5 viewer | `https://mikeywa.site/rive-viewer/`、`mode: local`；文件只存当前浏览器，不生成公开链接 |
| JOJO 版 / 叫叫版 | Hosted H5 collaboration edition | `https://rive.mikeywa.site/`、`mode: hosted`、`.brand-signature`、`for JOJO`；上传、三位短链接、评论、归档与恢复 |
| README 版本说明 | Product edition overview | `README.MD` 的“版本说明”表格；统一说明入口、文件保存与适用场景 |
| 黑客松包装文案 | Hackathon messaging pack | `HACKATHON-2026.MD`；作品名、卖点、报名简介、路演与拉票文案 |
| 黑客松宣传封面 | Hackathon campaign posters | `h5/assets/hackathon/posters/01-stop-recording.png` 至 `06-understand-interaction.png`；`1536×1024`、`3:2`、居中 `86%` 安全区 |
| 黑客松真实页面参考 | Hackathon live-page references | `h5/assets/hackathon/references/vgd-desktop.png`、`vgd-mobile.png`、`https://rive.mikeywa.site/vGd` |
| 首页导入框 | Import dropzone | `.import-dropzone`、`showImportMenu` |
| 底部网页版单行 | External viewer footer row | `.web-link-footer`、`padding: 28rpx 20px 0`、`.web-link-footer__label`、`margin-right: 10rpx`、`.web-link-footer__url-wrap`、`.web-link-footer__url`、`.web-link-footer__url-fade`、`WEB_VIEW_URL` |
| 复制网页版地址 | User-triggered clipboard write | 可见文案 `mikeywa.site/rive-viewer/`、复制值 `WEB_VIEW_URL`、`copyWebViewerUrl`、`wx.setClipboardData`、`已复制网址`、`/assets/icons/copy-simple.svg` |
| 全站功能图标 | Phosphor Icons Bold system | `scripts/vendor-phosphor-icons.mjs` 同时生成小程序 `assets/icons/*.svg` 与 H5 `public/rive-viewer/icons/*.svg`；H5 使用 `.app-icon` CSS Mask |
| 首页 Rive 预热 | Runtime idle prewarm | `startRivePrewarm`、`prewarmRuntime`、`runtimePromise` |
| 次级页顶部导航 | Custom preview navigation bar | `components/navigation-bar/navigation-layout.js`、`calculateNavigationLayout`、`topInset`、`edgeWidth`、`wx.getMenuButtonBoundingClientRect`、`wx.onWindowResize` |
| 电脑端返回修复 | Desktop navigation and route fallback | `.weui-navigation-bar__left` 垂直居中、返回热区 `44×44px`、`getCurrentPages`、`wx.navigateBack`、单页栈 `wx.reLaunch` 首页 |
| 导入方式菜单 | Import action sheet | `showImportMenu`、`chooseMessageFile`、`chooseSystemFile` |
| 最近文件列表 | Local library list | `.file-list`、`files`、`getAllFiles` |
| 文件卡 / 文件行 | File row | `.file-row`、`.file-open` |
| 倾斜文件图标 | File cover | `.file-cover`、`.file-cover__fallback` |
| 文件右侧箭头 | File menu toggle | `.file-menu-toggle`、`toggleFileMenu` |
| 两项操作菜单 | File action menu | `.file-menu`、`shareFile`、`deleteFile`；只保留发送与删除，示例和用户文件都可删除 |
| 首页按下回弹 | Home press spring feedback | `hover-class="is-pressed"`、`file-row--pressed`、`hover-start-time="0"`；小按钮 `scale(1.25)`，大面积入口 `scale(1.025)` |
| 已删除示例 | Hidden built-in tombstone | `HIDDEN_BUILTIN_STORAGE_KEY`、`readHiddenBuiltinIds`、`writeHiddenBuiltinIds`、`visibleBuiltins` |
| 联系作者反馈 | Author contact modal | `.author-contact`、`font-size: 24rpx`、`showAuthorWechat`；仅展示微信号，不访问剪贴板 |
| 预览画布 | Rive Canvas stage | `.canvas-card`、`#riveCanvas`、`NativeRivePlayer` |
| 画布 Loading | Loading overlay | `.canvas-state--loading`、`loadingProgress`、`loadingPhase` |
| 详情首帧封面 | First-frame cover capture | `scheduleCoverCapture`、`captureCover`、`saveCover` |
| 画布拖动手柄 | Stage resize handle | `.stage-resizer`、`stageResizeStart/Move/End/Cancel`、`catchtouchstart/move/end/cancel` |
| 手柄原位缩放快捷行 | Inline resize-handle fit row | `stageResizeMenuActive`、`stageResizeTapOpen`、`stageResizePressActive`、`stageResizeEnd`、`stageResizeHoverFit`、`stageResizeLongPress`、`.stage-resizer.is-selecting`、`.stage-resizer.is-tap-open`、`.stage-resizer.is-press-active` |
| 手柄 Gentle 展开/收起 | Gentle handle spring | `.stage-resizer__modes`、`.stage-resizer__grip view`、`420ms cubic-bezier(.22, 1.22, .36, 1)`、H5 `--spring-gentle`；默认粗、展开细，节点常驻以保留反向退场 |
| 手柄黄色悬停反馈 | Yellow fit hover feedback | `.stage-resizer__mode.is-hovered`、`.stage-resizer__mode-icon-wrap`、`.stage-resizer__mode-icon--active`、`stageResizeHoverFit`、`rgba(242, 201, 76, .14)` |
| 预览按钮按下回弹 | Preview press spring feedback | `hover-class="is-pressed"`、`hover-start-time="0"`、`scale(1.25)`、`cubic-bezier(.34, 1.56, .64, 1)` |
| 快速菜单空白取消层 | Native menu backdrop dismiss | `.native-menu-backdrop`、`dismissNativeMenus`、`showSpeedMenu`、`showFileMenu` |
| 文件菜单按住滑选 | File menu press-drag selection | `fileNavigationTouchMove`、`fileMenuOptionRects`、`fileHoverId`、`fileNavigationGestureMovedIntoMenu`、`.file-popover__option.is-hovered` |
| 预览背景色块 | Canvas tone swatch | `.tone`、`.tone-options`、`canvasTone`、`setCanvasTone` |
| 手柄单击三秒收起 | Stage fit menu auto dismiss | `stageResizeMenuDismissTimer`、`scheduleStageResizeMenuDismiss`、`clearStageResizeMenuDismiss`、H5 `stageResizeMenuDismissTimerRef` |
| 手柄双击切换完整/铺满 | Stage fit double-tap toggle | 小程序 `stageResizeEnd`、`STAGE_RESIZE_DOUBLE_TAP_DELAY`、`lastStageTapAt`、`toggleStageFit`、`fit`；H5 `handleStageTap` |
| 重置按钮 | Reset playback action | `.transport__primary`、`resetAnimation` |
| 播放 / 暂停 | Playback toggle | `.transport__secondary`、`togglePlay` |
| 画布下方五个按钮平分 | Equal five-column transport | 小程序 `.transport` 使用 Flex 且五项 `width: 0; flex: 1 1 0`；H5 `.transport` 使用五列 Grid |
| 小程序五格一级布局 | Flat Mini Program transport | 五个非原生 `view role="button"`：`.transport__primary`、`.transport__secondary`、`.speed-menu`、两个 `.transport__file-button`；倍速不使用 `.speed-menu-shell` 包裹 |
| 播放速度 | Speed selector | `.speed-menu`、`.speed-popover`、`speedValue` |
| 上一个 / 下一个 | File navigation | 两个 `.transport__file-button`、`fileNavigationTouchStart/End`、`openFileById`；长按菜单锚点为 `.transport` |
| 长按文件列表 | File navigation popover | `.file-popover`、`showFileMenu` |
| 画板标签 | Artboard choice tag | `artboardNames`、`selectArtboardTag` |
| 状态机标签 | State machine choice tag | `stateMachineNames`、`selectStateMachineTag` |
| 时间轴 | Animation timeline tags | `.timeline-actions`、`.timeline-tag`、`animationNames`、`playAnimation`；H5 左右 `25px` 内边距 |
| 播放进度背景 | Timeline progress fill | 小程序 `.parameter-tag__progress`、`animationProgress`；H5 `.timeline-progress`、`getAnimationDuration`、`getTimelinePosition`、`animationDuration`、`animationElapsed`、`animationLoopValue`、`publishProgress` |
| 状态机输入 | State machine inputs | `inputs`、`handleInputTag` |
| 标签点击反馈 | Parameter tag feedback | `parameter-tag`、`is-pressed`、`is-feedback` |
| 完整 / 铺满 | Fit control | `.compact-switch`、`fit`、`selectFit`、`applyFit`、`arrows-in-simple.svg`、`arrows-out-simple.svg` |
| 渲染质量 | Render quality selector | `qualityOptions`、`qualityMode`、`selectQuality`、`setQualityMode` |
| 播放帧数 | Inline playback FPS | `.file-heading__fps`、`fps`；位于 `timelineTimecode` 右侧 |
| 播放按钮下方状态小字（已移除） | Removed playback subline | H5 `.playback-status` 与小程序 `.playback-status` 均不再渲染 |
| 背景色圆圈 | Canvas tone swatches | `.tone-options`、`.tone`、`canvasTone` |
| 右上角下载按钮 | File export menu | `.file-heading__save`、`showSaveMenu` |
| 右上角分享 / 转发 | WeChat share menu | `enableShareMenu`、`onShareAppMessage`、`onShareTimeline`、`showShareMenu.object.menus`；原生项目不使用 Taro 的 `enableShare*` 编译提示 |
| 分享缩略图 | WeChat share-card image | `FRIEND_SHARE_IMAGE`、`/share-friend.jpg`、`onShareAppMessage.imageUrl`；5:4、约 37 KB |
| 朋友圈圆形缩略图 | WeChat timeline image | `TIMELINE_SHARE_IMAGE`、`/share-timeline.png`、`onShareTimeline.imageUrl`；1:1 |
| 文件本地仓库 | Mini Program user data storage | `rive-library`、`utils/library.js` |
| 兼容版运行时 | Fallback Rive WASM | `rive_fallback.wasm.br`、`instantiateRiveWasm` |
| 复杂度画像 | Rive complexity profile | `artboardCount`、`animationCount`、`stateMachineCount`、`isComplexFile` |
| 活动画板检查 | Active artboard inspection | `inspectArtboard`；首帧只检查并复用默认画板 |
| 复杂文件性能档 | Mobile complex-file profile | `configurePerformanceProfile`、`IOS_COMPLEX_FRAME_INTERVAL`、`IOS_COMPLEX_PIXEL_RATIO_LIMIT` |
| 画板列表展开 | Lazy artboard selector | `loadArtboardCatalog`、`expandArtboardCatalog`、`parameter-disclosure` |
| 暂停按需绘制 | Draw-on-demand while paused | `scheduleRender`、`requestRedraw`、`needsRedraw` |
| 嵌入图片兼容 | Embedded image shim | `detectEmbeddedImageExtension`、`MiniProgramDOMMatrix`、`Image.onerror` |
| 声音开关 | Rive audio toggle | `audioEnabled`、`toggleAudio`、`Artboard.volume`、`riveAudioEnabled` |
| 微信声音桥接 | WebAudio compatibility bridge | `wx.createWebAudioContext`、`MiniProgramAudioContext`、`runtimeAudioWindow` |
| iPhone 钢琴直播 | Low-latency Piano cue player | `MiniProgramCueAudio`、`createPianoCueBindings`、`collectPianoCueChanges` |
| 钢琴音符防积压 | Latest-wins audio resume queue | `pendingCue`、`resumeTask`、`resumeGeneration`、`wantsRunning` |
| iOS 音频性能档 | Mobile audio render profile | `IOS_AUDIO_FRAME_INTERVAL`、`IOS_AUDIO_PIXEL_RATIO_LIMIT`、`getPlaybackPerformanceProfile` |
| 状态文案合并更新 | Active-state update throttle | `queueActiveState`、`activeStateTimer` |
| 大文件声音保护 | Audio performance guard | `MAX_AUDIO_SOURCE_BYTES`、`audioBlockedReason`、`shouldBypassEmbeddedAudio` |
| 音频生命周期 | Audio context lifecycle | `resumeRuntimeAudio`、`suspendRuntimeAudio`、`dispose` |
| 剪贴板范围检查 | Clipboard privacy guard | `scripts/check-project.mjs`；禁止 `wx.getClipboardData`，仅允许首页用户点击后调用一次 `wx.setClipboardData` |
| 剪贴板用途说明 | Clipboard privacy purpose | “用于用户主动复制网页版预览地址；仅向剪切板写入固定网址，不读取剪切板已有内容” |
| 小程序上传包预算 | Mini Program source package budget | `scripts/check-package-budget.mjs`、`npm run check:package`；Canvas 源包 `1,666,466 B`，上限 `1,700,000 B` |
| WebGL2 试验预览包（已停用） | Archived WebGL2 preview | `dist/wechat-preview-webgl2-2026-08-25/preview-qr.png`、`preview-info.json`；真机无法正常加载，不再作为测试或发布基线 |
| 预览组件查询域 | Component-scoped SelectorQuery | `createPreviewSelectorQuery`、`query.in(this)`；手机全页与桌面分栏都必须绑定 `preview-panel` 实例 |
| 预览组件样式域 | Component WXSS selector policy | `components/preview-panel/preview-panel.wxss`；只用 `:host` 与类选择器，原生标签补语义类 |
| 发布版本号 | Release version | `1.0.7`、`package.json.version`、`package-lock.json.version`、开发者工具上传版本 |
| 独立 H5 | Standalone web viewer | `h5/`、`/rive-viewer`、`RiveViewerApp` |
| H5 本地文件库 | Browser local library | `IndexedDB`、`listLocalFiles`、`saveLocalFile` |
| H5 浏览器运行时 | Browser Rive runtime | `WebRivePlayer`、`rive-player.ts`、动态 `import()`、`rive-webgl2-2.39.1.wasm`、`rive-2.39.1.wasm` |
| H5 单页参数面板 | Unified preview controls | `.control-panel`、`.parameter-row`；不使用 `activeTab` / `.primary-tabs` |
| H5 画布对齐 | Rive renderer alignment | `WrappedRenderer.align`、`updateViewMatrix`、`Fit.contain` / `Fit.cover` |
| H5 点击坐标换算 | Canvas-to-artboard pointer mapping | `canvasPointToBacking`、`backingPointToArtboard`、`canvas-space.ts` |
| H5 点击优先级 | Interaction-first state restore | `ensureStateMachine`、`selectedStateMachineName`、`pointerDown` |
| H5 性能数据 | Runtime FPS metric | `fps`、`onPerformance`、`.file-fps` |
| H5 渲染质量 | Browser quality profile | `DEFAULT_RENDER_QUALITY = 2`、`DEFAULT_HOSTED_RENDER_QUALITY = 1`、`quality`、`requestedQuality`、`effectiveQuality`、`frameInterval`；普通 H5 默认高清，JOJO 保持平衡，复杂文件仍自动限为最高 DPR `1.25` / `30fps` |
| H5 默认渲染器 | Browser WebGL2 Rive Renderer | `renderEngine = "webgl2"`、`@rive-app/webgl2-advanced@2.39.1`、`runtime.makeRenderer(canvas)`、`renderer.flush()`；支持 Vector Feathering |
| H5 兼容模式 | Browser Canvas2D fallback renderer | `renderEngine = "canvas2d"`、`@rive-app/canvas-advanced@2.39.1`；保留播放与交互，不保证 Vector Feathering |
| 普通 H5 正式渲染器 | Legacy H5 production renderer | `mikeywa.site/rive-viewer/` 默认 WebGL2，HTML 预加载 `rive-webgl2-2.39.1.wasm`；失败时保留 Canvas2D 兼容模式 |
| 小程序当前渲染器 | Mini Program Canvas2D renderer | `type="2d"`、`@rive-app/canvas-advanced@2.39.1`、`vendor/rive/canvas_advanced.js`、`WXWebAssembly` |
| 小程序双 WASM 回退 | Mini Program Canvas WASM fallback | `vendor/rive/rive.wasm.br`、`vendor/rive/rive_fallback.wasm.br`、`RIVE_WASM_FILES`；主运行时失败后尝试兼容 WASM |
| WebGL2 小程序试验（已停用） | Archived Mini Program WebGL2 experiment | `dist/mini-webgl2-experiment-archive-20260825/`；因真机无法正常加载，不进入小程序包 |
| 渲染引擎选择 | Render engine selector | 参数区最后一项“渲染引擎”、`RenderEngine`、`selectRenderEngine`、`WebGL2`、`兼容模式` |
| WebGL2 自动降级 | WebGL2 runtime fallback | `onRuntimeFailure`、`webglcontextlost`、`engineFallbackBusyRef`、`canvasGeneration`、`reloadActiveFileRef` |
| 渲染降级提示 | Render fallback toast | `EngineToast`、`.engine-toast`、`engineToast`；“WebGL2 不可用，已切换到兼容模式” |
| RIV 内阴影 / 虚化 / 柔边 | Vector Feathering visual effects | 素材层效果；需 WebGL2 / Rive Renderer 呈现，不等同于页面 CSS 阴影，也不能靠“高清”档恢复 |
| H5 低清缩略图 | Local WebP cover | `saveLibraryCover`、`attachLibraryCovers`、`LocalCoverImage`；本机文件与公开最近文件共用 `160×120 WebP` |
| H5 右侧预览 | Desktop preview side panel | `.drawer-workspace`、`.drawer-home-pane`、`.drawer-preview-panel`、`@media (min-width: 860px)` |
| Mac 双页中缝 | Custom desktop split workspace | `.desktop-workspace`、`.desktop-home-pane`、`.desktop-preview-pane`、`desktopSplitEnabled`、`desktopPreviewFileId` |
| 小程序统一预览模板 | Canonical native preview component | `components/preview-panel`、`preview-definition.js`；`embedded` 属性区分手机全页与桌面分栏，页面壳只负责路由/分享 |
| 桌面分栏阈值 | Desktop split logical-pixel breakpoint | `DESKTOP_SPLIT_MIN_WIDTH = 960`、`windowInfo.windowWidth`、`supportsDesktopSplit`、`getDesktopSplitUrl` |
| Mac 分栏重编译包 | Desktop split DevTools rebuild archive | `dist/RiveViewer-miniapp-1.0.4-mac-split-devtools-rebuild.zip` |
| REV 编辑器备份文件 | Rive editor backup file | `.rev`；不交给 Runtime，需在 Rive 编辑器中转存为 `.riv` |
| H5 分栏过渡 | Responsive split transition | `.drawer-workspace`、`.drawer-workspace.is-open`、`grid-template-columns`、`260ms cubic-bezier(.16, 1, .3, 1)` |
| H5 详情返回文件列表 | Preview-to-library navigation | `.topbar-back`、`.drawer-close`、`arrow-left.svg`、`Escape`、`closeActiveFile`、`Brand href` |
| H5 快捷键帮助 | Keyboard shortcut popover | `ShortcutHelp`、`.shortcut-button`、`.shortcut-popover`、`.shortcut-help:hover`、`:focus-within`、`.is-open`；桌面悬停/聚焦与触屏点击共用 |
| H5 事件控制台 | Runtime event console | `RuntimeEventConsole`、`.runtime-event-console`、`.runtime-event-summary`、`.runtime-event-history`；第一栏最新事件与展开历史 |
| H5 事件采集 | Advance-and-drain event capture | `advanceStateMachineAndReadReports`、`readStateMachineReports`、`reportedEventCount`、`reportedEventAt`、`stateChangedCount`、`onEvent` |
| H5 事件历史 | Session event ring buffer | `RuntimeEventLog`、`webEventLogEntries = 200`、`useSyncExternalStore`；当前文件会话内存数据，不上传、不持久化 |
| H5 顶层浮窗 | Page-level overlay stacking | `--z-header`、`--z-popover`、`.topbar` |
| H5 意见反馈 | Static feedback credit | `FeedbackContact`、`.feedback-credit`、可见纯文本“反馈意见：杨皓棱”；无按钮、图标或复制行为 |
| H5 平台标签（已移除） | Removed platform badge | 不再渲染 `.platform-label` 或右上角 `H5` 文案 |
| H5 标题品牌图标 | Header brand mark | `Brand`、`.brand-mark`、`.brand-title`、`.brand-signature`、`favicon.webp?v=3`；署名小字为 `for JOJO` |
| H5 文件操作箭头 | Hover file action toggle | `.file-action`、`.file-row:hover`、`.file-row:focus-within`、`.is-menu-open` |
| H5 Rive 完整比例画布 | Proportional Rive contain canvas | `stageKeepsSourceAspect`、`hasStageAspect`、`stageAspect`、`stageStyle`、`.canvas-card.is-proportional`；只对 Rive 外框锁原比例 |
| H5 整行悬停背景 | Full-row file hover fill | `.file-row:hover`、`.file-row:focus-within`、`.file-row.is-menu-open` |
| H5 右上角下载 | Preview top-right download | 手机 `.topbar-download`、宽屏 `.file-heading-download`、`downloadFile`；参数区不再渲染“文件操作” |
| H5 详情复制按钮 | Direct hosted detail copy | 手机 `.topbar-copy-link`、宽屏 `.file-heading-copy-link`、`copyActiveHostedLink`、`detailCopyFeedback`、`.is-copied`、`check.svg`；下载旁直接复制，成功原位变为普通深色的“已复制” |
| JOJO 默认完整模式 | Hosted default contain fit | `isHostedPlatform ? "contain" : "cover"`、`fit`、`fitRef`、`WebRivePlayer.setFit`、`.canvas-card.is-proportional`；托管首开完整，旧本地版首开铺满 |
| 公开文件下载进度 | Streamed public-file download | `getHostedFile`、`HostedFileDownloadOptions`、`ReadableStream.getReader`、`RESPONSE_TIMEOUT_MS`、`DOWNLOAD_STALL_TIMEOUT_MS`、`.public-download-progress`；真实百分比、断流报错与重试 |
| 公网下载速度 / 服务器限速 | Cloud egress throughput | Node/Nginx/`tc` 均无 GET 带宽整形；腾讯云公网实测约 `1–2 Mbps`，精确套餐字段为 `InternetAccessible.InternetMaxBandwidthOut`，需控制台或只读云 API 确认 |
| H5 分享弹层 | Hosted publish result dialog | `ShareActionsDialog`、`.share-action-stack`、`.share-link-row`、`.share-link-value`、`.share-copy-action`、`.share-download-action`；只用于上传完成或文件菜单生成链接后的结果，不用于详情右上角 |
| H5 通用复制方法 | Clipboard write helper | `h5/lib/clipboard.ts`、`copyText`、`navigator.clipboard.writeText`、`document.execCommand("copy")` 回退 |
| H5 底部并排入口 | Inline H5 footer content | `.library-footer-actions`、`MiniProgramEntry`、`FeedbackContact`、`.feedback-credit`、`wechat-logo.svg`；小程序入口与反馈纯文本并排 |
| H5 小程序入口 | Mini Program access entry | `MiniProgramEntry`、`.mini-program-entry`、`.mini-program-popover`、`mini-program-code.webp`、文案“小程序” |
| H5 发送文件 | Web Share with download fallback | `shareFile`、`navigator.share`、`navigator.canShare`、`downloadFile` |
| H5 本地文件保留 | Non-destructive local library | `LibraryList` 不展示删除或移除入口；本机 IndexedDB 文件保持可用，H5 不再预置示例 |
| H5 页签与 iOS 主屏图标 | Favicon and Apple touch icon | `favicon.webp`、`favicon-source.png`、`apple-touch-icon.png`、`?v=3`；圆角矩形页签图标与 `180×180` 不透明 iOS 方形源图 |
| H5 公网测试入口 | Temporary production URL | `rive-viewer-miniapp.muhualei.chatgpt.site/rive-viewer` |
| H5 正式入口 | Custom-domain route | `https://mikeywa.site/rive-viewer/`、`/etc/nginx/snippets/rive-viewer.conf` |
| H5 小程序包排除 | Mini Program pack ignore | `project.config.json` 的 `packOptions.ignore: h5` |
| H5 静态发布包 | Nginx static bundle | `npm run build` / `build:static`、`h5/dist-static/`、`vite.config.ts`、`scripts/compress-static.mjs` |
| H5 根应用 | Browser application root | `RiveViewerApp`；文件库和低频控制状态留在根组件，播放遥测由独立 store 承载 |
| H5 逐帧热循环 | Browser render hot loop | `WebRivePlayer.frame`、`emitProgress`、`emitPerformance`、`emitMetadata` |
| H5 实时指标层 | Playback telemetry layer | `PlaybackTelemetry`、`useSyncExternalStore`、`PlaybackMeta`、`TimelineControl`；时间轴/FPS 不触发根组件更新 |
| H5 正式构建链 | Canonical static build pipeline | 单一 Vite、`dist-static`、预压缩、Nginx；不再包含 Next/Vinext/Cloudflare/Drizzle/Tailwind |
| 双端共享性能策略 | Cross-platform Rive policy | `shared/rive-policy.json` 是唯一真源，`shared/rive-policy.js` 是微信生成物；集中倍速、手势、遥测节流和复杂文件阈值 |
| H5 本地生产预览 | Local production preview | `npm run preview -- --host 127.0.0.1 --port 4173`；端口占用时 Vite 自动顺延，本轮为 `4174` |
| H5 大文件切换保护 | Stale-load session guard | `activeLoadSessionRef`、session token；旧文件异步读取完成后不能覆盖当前文件 |
| 正式服务器 SSH | Deployment SSH alias | `ssh mikeywa-rive`、`~/.ssh/mikeywa_rive_deploy`、用户 `ubuntu` |
| H5 版本切换 | Atomic release symlink | `/var/www/rive-viewer/releases/<时间戳>`、`/var/www/rive-viewer/current` |
| H5 当前正式版本 | Current production release | `/var/www/rive-viewer/releases/20260818-093940`；`current` 已指向该目录 |
| H5 回滚版本 | Production rollback release | `/var/www/rive-viewer/releases/20260813-215427`、`/etc/nginx/snippets/rive-viewer.conf.bak-20260818-093940-retry` |
| H5 发布权限 | Static file permissions | `root:root`；发布目录 `755`、静态文件 `644` |
| 生成公开链接 | Publish hosted share | `requestPublishFile`、`uploadSavedFiles`、`createHostedShare`、`XMLHttpRequest.upload.onprogress`、`POST /api/v1/shares`；自动上传和历史本地文件补传共用同一链路 |
| 托管上传框 | Hosted upload dropzone | `.import-dropzone`、`handleIncomingFiles`、`enterDropTarget`、`showDropTarget`、`dropFiles`；整页接收拖入，首文件本地打开与上传并行，旧入口仅本地保存 |
| 侧栏加号 | Detail file picker | `.preview-file-add`、`fileInputRef`、`aria-label="选择并上传 Rive 文件"`；黄色按钮内图标为 `#0b0f14` 近黑色，首页上传框和详情侧栏共用隐藏文件输入 |
| 文件上云图标 | Non-interactive per-file cloud state | `FileUploadStatus`、`.file-sync-status`、`cloud-check / desktop / cloud-arrow-up / cloud-x`；位于文件体积之后，只展示状态，点击由外层 `.file-open` / `.preview-file-row-open` 统一打开文件 |
| 行内上传状态栏 | Per-file upload detail | `uploadStates: Record<fileId, FileUploadState>`、`FileUploadDetail`、`.file-upload-progress`、`uploadRetryFilesRef`；逐文件百分比、失败和重试，不再使用独立完成卡片 |
| 上传完成链接 | Per-file hosted result | `PUBLISHED_CODES_STORAGE_KEY`、`HostedShare.code`、`ShareActionsDialog`；完成后文件行只留云勾，菜单打开统一分享弹层 |
| H5 运行模式 | Hosted versus local build mode | `ViewerMode`、`mode: hosted/local`、`import.meta.env.BASE_URL`；仅根路径构建启用托管 API、托管列表和公开链接入口 |
| 已生成入口 | Remembered publish action | `PUBLISHED_CODES_STORAGE_KEY`、`publishedCodes`、可见文案“复制公开链接” |
| 复制公开链接 | Copy hosted share URL | `copyActiveHostedLink`、`ShareActionsDialog`、`ArchivedLibraryDialog.copyShare`、`copyText(hostedShareUrl(code))`；详情原位反馈，结果弹层保留可选中链接 |
| Rive 分享页 | Hosted Rive share page | `/:code`、旧 `/s/:code` 308 跳转、3 位 Base62 大小写敏感短码、保留码 `api`、`shareCodeFromPath`、`getHostedShare`、`getHostedFile` |
| Beta 版 | Versioning preview deployment | `/beta/`、`RIVE_VIEWER_BASE=/beta/`、`/var/www/rive-host-beta/current`；正式根路径静态版本不变 |
| 上传新版本 | Append hosted file version | `versionInputRef`、`updateHostedVersion`、`createHostedVersion`、`POST /api/v1/shares/:code/versions` |
| 文件版本下拉 | Hosted version listbox | `.file-version-picker`、`.file-version-menu`、`activeHostedVersion`；按新到旧显示版本名、文件名和上传日期 |
| 指定版本下载 | Version-scoped Rive download | `hostedFileUrl(code, versionId)`、`GET /api/v1/shares/:code/file?versionId=<UUID>` |
| 版本评论分组 | Version-scoped comment groups | `HostedComment.versionId`、`.comment-version-heading`、`.comment-version-group`；仅两个及以上版本启用，单版本仍为普通评论列表；当前版本展开，标题点击切换预览 |
| 低亮参数选中态 | Subtle parameter selection | `Tag.subtleSelected`、`.parameter-tag.is-selected.is-subtle-selected`；与时间轴深底淡黄边框一致 |
| 公开最近文件 | Browser recent hosted library | IndexedDB `recent-hosted`、`listRecentHostedFiles`、`rememberRecentHostedFile`、`RECENT_HOSTED_LIMIT = 20`、按短码去重 |
| 统一最近文件 | Unified recent and hosted list | `mergeUnifiedFiles`、`UnifiedFileItem`、`unifiedFiles`；服务端公开中、本机与最近公开按短码 / 本地映射去重，按最近打开、评论或上传时间倒序 |
| 最近交互时间 | Last file activity timestamp | `ActivityPolicy`、`touchLocalFile`、`rememberRecentHostedFile`、`FileUploadState.updatedAt`；首页打开、评论和上传推动排序，详情侧栏使用 `preserve` |
| 侧栏保持顺序 | Stable detail rail selection | `ActivityPolicy = "record" | "preserve"`、`RAIL_ACTIVITY_STATE_KEY`、`openHostedShareWithActivity`、`preserveExistingActivity`；跨三位路由切换也只更新选中态 |
| 公开缩略图缓存 | Hosted local cover cache | `hosted-<code>`、IndexedDB `covers`、`saveLibraryCover`；只缓存元信息与 WebP，不缓存远端 `.riv` |
| 托管平台域名 | Hosted platform domain | `rive.mikeywa.site`、A 记录 `115.159.25.169`、TTL 600、独立 Nginx 与 Let's Encrypt、根路径 `/` |
| 详情文件窄栏 | Desktop preview file rail | `PreviewFileRail`、`.preview-file-rail`、`FILE_RAIL_DEFAULT_WIDTH`、`FILE_RAIL_MIN_WIDTH`、`FILE_RAIL_MAX_WIDTH`、桌面 `min-width: 860px`；默认 `184px`，可在 `160–360px` 间调整，显示统一文件列表与顶部加号 |
| 文件栏调整线 | Accessible file rail separator | `.preview-file-rail-resizer`、`applyFileRailWidth`、`role="separator"`；支持指针拖动、方向键、Home 和 End，Hover/聚焦/拖动时变黄 |
| 完整文件名浮层 | File name hover tooltip | `.preview-file-rail-name-tooltip`、`data-full-name`；文件名 Hover 或聚焦时在文件栏外显示完整名称 |
| 当前文件黄线 | Rounded current-file marker | `.preview-file-rail-row.is-current::before`、`3px`、`border-radius: 999px`、`aria-current`；独立竖线，不使用黄色内阴影 |
| 公开评论栏 | File-scoped forest comment thread | `ShareCommentsPanel`、`CommentThreadState.code`、`.public-comments-inline`、`GET/POST /api/v1/shares/:code/comments`；按三位短码隔离，事件控制台后的唯一正文输入区，聚焦后显示可点击的本机头像和昵称 |
| JOJO 可调工作台 | Resizable preview workbench | `.preview-workbench`、`.preview-main-column`、`.is-stage-height-customized`、`--manual-stage-height`、`.stage-resizer`、`.preview-inspector`、`1194px`；Rive 完整模式外框保持文件比例，Lottie/PAG 使用可调窗口并在内部保持比例；桌面优先给预览约 `800px`，右栏最小 `360px` |
| 可调中缝 | Accessible column separator | `.preview-column-resizer`、`WIDE_COLUMN_RESIZER_WIDTH`、`applyInspectorWidth`、`role="separator"`；支持拖动、方向键、Home 和 End |
| 时间轴整理 | Grouped timeline organizer | `TimelineControl`、`hasOrganizableTimelineGroups`、`getDefaultTimelineLayout`、`organizeTimelines`、`.timeline-group-title`；无重复下划线前缀时不显示展开/整理；可分组且超过 `10` 条默认整理，无前缀项目排最前，标签显示后缀但评论引用完整名 |
| 时间轴三层置顶 | Stacked timeline sticky headers | `.inspector-section-events`、`.timeline-section-header`、`.timeline-group-title`、`0 / 56 / 88px`；滚动时依次固定，Hover 标签高亮对应组标题 |
| 评论时间轴引用 | Inline comment timeline link | `CommentTimelineInsertion`、`formatCommentTimelineMarker`、`parseCommentTimelineSegments`、`serializeCommentDraft`、`CommentBody`、`.comment-draft-timeline`、`.comment-timeline-link`、`selectTimelineFromControl`；点击时间轴按光标插入，同一评论可含多个标记；底层仍以 `【时间轴：idol】` 纯文本存储，发布前后只内联显示下划线名称；Hover 变黄，点击切换后不保留选中色 |
| 评论相对时间 | Relative comment timestamp | `formatCommentDate`、`formatCommentAbsoluteDate`、`.comment-meta-row time`；一周内显示刚刚、几分钟前、几小时前或几天前，满一周显示绝对日期 |
| 紧凑评论列表 | Compact comment list | `article.comment-item`、`.comment-avatar`、`.comment-content`、`.comment-nickname`；头像左列，昵称和正文右列紧凑对齐 |
| 紧凑评论输入 | Inline compact comment composer | `.comment-form`、`.comment-editor[contentEditable]`、`.comment-hover-caret`、`.comment-submit-row`；默认 `46px` 单行高度，按钮内置，Hover 黄色闪动光标，聚焦后真实 caret 为黄色 |
| 评论回车快捷键 | Comment submit shortcut | `getCommentKeyboardAction`、`requestSubmit`、`insertLineBreak`、`nativeEvent.isComposing`；普通 Enter 发表，Shift / Command + Enter 显式换行，IME 组字期间不发表 |
| 评论动画占位 | Animated comment placeholder | `Calligraph`、`COMMENT_PROMPT_LINES`、`.comment-placeholder-calligraph`；输入为空时轮换评论提示，减少动态模式下退化为静态文字 |
| 评论归档操作 | Hover archive action | `.comment-archive-action`；无边框无背景，Hover/聚焦显示，触屏常驻 |
| 萌萌森林身份 | Stable and locally customizable commenter identity | `getCommentVisitorId`、`getHostedCommentIdentity`、`getLocalCommentAuthor`、`rive-host-comment-author-v1`、`pickForestIdentity`；默认稳定分配，本机昵称最多 `12` 字，发表时携带身份快照 |
| 评论动物头像 | Circular forest or custom comment avatar | `compressCommentAvatar`、`COMMENT_AVATAR_EDGE = 64`、`avatarDataUrl`、`.comment-identity-avatar`、`.comment-author img`；自定义原图只在内存解码，居中裁切为 `64×64 WebP`，列表按 `32×32px` 圆形展示 |
| 归档评论 | Collapsed archived comment | `archiveHostedComment`、`.comment-item-archived`、`POST /comments/:commentId/archive`；默认折叠，保留身份与状态摘要 |
| 恢复评论 | Restore archived comment | `restoreHostedComment`、`POST /comments/:commentId/restore`、`X-Rive-Action: restore`；展开归档评论后恢复原文与顺序 |
| 托管文件库 | Server-side animation storage | `ShareStore.createFromStaged`、`/var/lib/rive-host/files`、`state.json` 原子更新、发布目录外持久化；每次上传生成新短码和独立评论线程，不按内容哈希复用 |
| 归档文件 | Soft archive hosted file | `archiveHostedShare`、`X-Rive-Action: archive`、`archivedAt`、`.archive-confirm`、二次确认 |
| 已归档入口 | Archived library trigger | `.archived-library-trigger`、`.archived-library-count`、`archivedDialogOpen`、`aria-controls="archived-library-dialog"`；位于首页“最近文件”标题右侧，数量是无底色的普通灰字 |
| 已归档文件 | Archived file dialog | `ArchivedLibraryDialog`、`.archived-library-dialog`、`.archived-dialog-body`、`ArchiveConfirmDialog`；默认不占首页高度，弹窗内复制、恢复、刷新 |
| 恢复文件 | Restore archived file | `restoreHostedShare`、`X-Rive-Action: restore`、清空 `archivedAt`、保留原短码和评论 |
| 详情内文件加载 | Inline hosted-file loading | `navigateHostedShare`、`shareCode`内部路由状态、`history.pushState`、`.canvas-card .loading-state`；切换云端文件不刷新全页，Loading 只位于预览画布 |
| 播放速度菜单 | Custom playback speed listbox | `.speed-select`、`.speed-menu`、`.speed-option`、`speedMenuOpen`；向上展开的自定义 `listbox`，不使用浏览器原生下拉控件 |
| Rive 音频暂停 | Synchronized Rive audio suspension | `suspendRiveAudio`、`resumeRiveAudio`、`AudioContext.suspend/resume`；暂停画面时同步暂停内部声音 |
| 动效文件格式 | Hosted animation format | `AnimationFormat`、`animationFormatFromFilename`、`normalizeAnimationFormat`；`rive / lottie / pag` |
| 格式画布代次 | Format-scoped canvas generation | ``key={`${activeFile.file.format}-${canvasGeneration}`}``；跨格式切换创建新 Canvas，同格式与 Rive 引擎降级继续使用 `canvasGeneration` |
| 统一播放器 | Animation player adapter | `AnimationPlayer`、`createAnimationPlayer`；按格式动态加载 Rive、Lottie 或 PAG 实现 |
| Lottie 播放器 | Lottie canvas player | `WebLottiePlayer`、`lottie_canvas`、`progressiveLoad: false`；完整 Canvas 运行时，仅接受无外链资源的自包含 JSON |
| PAG 播放器 | libpag WebAssembly player | `WebPagPlayer`、`libpag@4.5.85`、`.canvas-card canvas { width/height: 100% !important; }`；按需加载并禁止 Canvas 越过父容器 |
| PAG 十兆限制 | PAG 10 MiB hard limit | `MAX_PAG_FILE_BYTES`、`maxFileBytesForFormat`；浏览器预检与服务端流式读取双重限制，`10 MiB` 可接受、再多 `1 B` 拒绝 |
| Beta 本地库隔离 | Beta IndexedDB isolation | `rive-viewer-h5-beta`；正式页继续使用 `rive-viewer-h5`，多格式最近记录不串入正式页 |
| 托管格式筛选 | Hosted format filter | `GET /api/v1/shares?formats=rive,lottie,pag`；未传参数时兼容正式旧前端，仅返回 Rive |
| 托管 API 服务 | Animation host service | `server/src/server.mjs`、`127.0.0.1:8097`、`rive-host.service`、`DynamicUser` |
| 托管原子发布 | Hosted atomic release | `/opt/rive-host/releases/<时间戳>`、`/var/www/rive-host/releases/<时间戳>`、两个 `current` 软链接 |
| 当前正式 JOJO 前端 | Active formal frontend | `/var/www/rive-host/releases/20260826-170259`；Safari 已验证 Rive → PAG → Rive 页内切换 |
| 当前 Beta 前后端 | Active Beta release | `/var/www/rive-host-beta/releases/20260826-132255`、`/opt/rive-host/releases/20260826-132255`；兼容正式与 Beta 三格式列表 |
