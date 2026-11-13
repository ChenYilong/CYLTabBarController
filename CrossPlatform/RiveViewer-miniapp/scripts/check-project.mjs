import fs from 'node:fs/promises'
import crypto from 'node:crypto'
import path from 'node:path'
import { brotliDecompress } from 'node:zlib'
import { promisify } from 'node:util'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const requireModule = createRequire(import.meta.url)
const decompressBrotli = promisify(brotliDecompress)
const packageManifest = JSON.parse(
  await fs.readFile(path.join(root, 'package.json'), 'utf8')
)
const appManifest = JSON.parse(
  await fs.readFile(path.join(root, 'app.json'), 'utf8')
)
const projectManifest = JSON.parse(
  await fs.readFile(path.join(root, 'project.config.json'), 'utf8')
)
const requiredFiles = [
  'app.json',
  'project.config.json',
  'vendor/rive/canvas_advanced.js',
  'vendor/rive/rive.wasm.br',
  'vendor/rive/rive_fallback.wasm.br',
  'assets/samples/guide.riv',
  'assets/samples/question.riv',
  'assets/samples/guide.js',
  'assets/samples/question.js',
  'assets/icons/arrow-left.svg',
  'assets/icons/arrow-right.svg',
  'assets/icons/arrows-in-simple-active.svg',
  'assets/icons/arrows-in-simple.svg',
  'assets/icons/arrows-out-simple-active.svg',
  'assets/icons/arrows-out-simple.svg',
  'assets/icons/caret-left.svg',
  'assets/icons/chevron-down.svg',
  'assets/icons/circle-notch.svg',
  'assets/icons/copy-simple.svg',
  'assets/icons/download.svg',
  'assets/icons/gauge.svg',
  'assets/icons/house.svg',
  'assets/icons/player-pause.svg',
  'assets/icons/player-play.svg',
  'assets/icons/plus.svg',
  'assets/icons/restore.svg',
  'share-friend.png',
  'share-timeline.png',
  'pages/index/index.js',
  'pages/preview/index.js',
  'pages/preview/preview-definition.js',
  'components/preview-panel/preview-panel.js',
  'components/preview-panel/preview-panel.json',
  'components/preview-panel/preview-panel.wxml',
  'components/preview-panel/preview-panel.wxss',
  'utils/desktop-split.js',
  'components/navigation-bar/navigation-layout.js',
  'utils/share.js',
  'scripts/verify-rive-interactions.mjs'
]

if (
  packageManifest.dependencies?.['@rive-app/canvas-advanced'] !== '2.39.1'
  || packageManifest.dependencies?.['@rive-app/canvas-advanced-lite']
  || packageManifest.dependencies?.['@rive-app/webgl2-advanced']
) {
  throw new Error('微信小程序必须只使用完整 Canvas 运行时，Lite 缺少 Rive Layout 等能力')
}

for (const relativePath of requiredFiles) {
  await fs.access(path.join(root, relativePath))
}

const miniProgramIconFiles = (await fs.readdir(path.join(root, 'assets/icons')))
  .filter((fileName) => fileName.endsWith('.svg'))
for (const fileName of miniProgramIconFiles) {
  const iconSource = await fs.readFile(path.join(root, 'assets/icons', fileName), 'utf8')
  if (
    !/data-icon-family="phosphor"/.test(iconSource)
    || !/data-icon-weight="bold"/.test(iconSource)
    || !/data-icon-optical-stroke="8"/.test(iconSource)
  ) {
    throw new Error(`小程序图标必须来自 Phosphor Icons Bold 并保留小尺寸光学校正：${fileName}`)
  }
}

for (const relativePath of ['app.json', 'project.config.json']) {
  JSON.parse(await fs.readFile(path.join(root, relativePath), 'utf8'))
}

try {
  JSON.parse(await fs.readFile(path.join(root, 'project.private.config.json'), 'utf8'))
} catch (error) {
  if (error.code !== 'ENOENT') throw error
}

for (const relativePath of [
  'pages/h5-preview',
  'pages/web',
  'scripts/h5-server.mjs'
]) {
  try {
    await fs.access(path.join(root, relativePath))
    throw new Error(`${relativePath} 已废弃但仍存在`)
  } catch (error) {
    if (error.code !== 'ENOENT') throw error
  }
}

for (const relativePath of [
  'h5/package.json',
  'h5/app/rive-viewer/page.tsx',
  'h5/lib/rive-player.ts',
  'h5/public/rive-viewer/rive.wasm'
]) {
  await fs.access(path.join(root, relativePath))
}

const ignoredPackPaths = projectManifest.packOptions?.ignore || []
if (!ignoredPackPaths.some((item) => item.type === 'folder' && item.value === 'h5')) {
  throw new Error('独立 H5 目录必须从微信小程序上传包中排除')
}

for (const relativePath of ['assets/samples/guide.riv', 'assets/samples/question.riv']) {
  const bytes = await fs.readFile(path.join(root, relativePath))
  if (bytes.subarray(0, 4).toString('ascii') !== 'RIVE') {
    throw new Error(`${relativePath} 不是有效的 Rive 文件`)
  }
}

const visibleFiles = [
  'pages/index/index.wxml',
  'pages/preview/index.wxml'
]
for (const relativePath of visibleFiles) {
  const source = await fs.readFile(path.join(root, relativePath), 'utf8')
  if (/[\u2013\u2014]/.test(source)) {
    throw new Error(`${relativePath} 含有不允许的长破折号`)
  }
}

const previewMarkup = await fs.readFile(path.join(root, 'pages/preview/index.wxml'), 'utf8')
const homeMarkup = await fs.readFile(path.join(root, 'pages/index/index.wxml'), 'utf8')
const previewLogic = [
  await fs.readFile(path.join(root, 'pages/preview/index.js'), 'utf8'),
  await fs.readFile(path.join(root, 'pages/preview/preview-definition.js'), 'utf8')
].join('\n')
const embeddedPreviewLogic = await fs.readFile(
  path.join(root, 'components/preview-panel/preview-panel.js'),
  'utf8'
)
const embeddedPreviewMarkup = await fs.readFile(
  path.join(root, 'components/preview-panel/preview-panel.wxml'),
  'utf8'
)
const embeddedPreviewStyle = await fs.readFile(
  path.join(root, 'components/preview-panel/preview-panel.wxss'),
  'utf8'
)
const previewStyle = await fs.readFile(path.join(root, 'pages/preview/index.wxss'), 'utf8')
const h5AppSource = await fs.readFile(
  path.join(root, 'h5/app/rive-viewer/RiveViewerApp.tsx'),
  'utf8'
)
const h5StyleSource = await fs.readFile(path.join(root, 'h5/app/globals.css'), 'utf8')
const h5LibrarySource = await fs.readFile(path.join(root, 'h5/lib/library.ts'), 'utf8')
const homeLogic = await fs.readFile(path.join(root, 'pages/index/index.js'), 'utf8')
const appLogic = await fs.readFile(path.join(root, 'app.js'), 'utf8')
const libraryLogic = await fs.readFile(path.join(root, 'utils/library.js'), 'utf8')
const shareLogic = await fs.readFile(path.join(root, 'utils/share.js'), 'utf8')
const nativeRuntime = await fs.readFile(path.join(root, 'utils/rive-native.js'), 'utf8')
const nativeVendor = await fs.readFile(path.join(root, 'vendor/rive/canvas_advanced.js'), 'utf8')
const vendorScript = await fs.readFile(path.join(root, 'scripts/vendor-rive.mjs'), 'utf8')
const navigationLogic = await fs.readFile(path.join(root, 'components/navigation-bar/navigation-bar.js'), 'utf8')
const navigationMarkup = await fs.readFile(path.join(root, 'components/navigation-bar/navigation-bar.wxml'), 'utf8')
const navigationStyle = await fs.readFile(path.join(root, 'components/navigation-bar/navigation-bar.wxss'), 'utf8')
const desktopSplitLogic = await fs.readFile(path.join(root, 'utils/desktop-split.js'), 'utf8')
const { calculateNavigationLayout } = requireModule(
  path.join(root, 'components/navigation-bar/navigation-layout.js')
)
const {
  getDesktopSplitUrl,
  supportsDesktopSplit
} = requireModule(path.join(root, 'utils/desktop-split.js'))

const desktopNavigationLayout = calculateNavigationLayout({
  windowInfo: { windowWidth: 414, statusBarHeight: 0, safeArea: { top: 0 } },
  deviceInfo: { platform: 'mac' },
  menuRect: { left: 289, top: 26, width: 60, height: 32 }
})
const phoneNavigationLayout = calculateNavigationLayout({
  windowInfo: { windowWidth: 375, statusBarHeight: 47, safeArea: { top: 47 } },
  deviceInfo: { platform: 'ios' },
  menuRect: { left: 278, top: 51, width: 87, height: 32 }
})
const invalidDesktopNavigationLayout = calculateNavigationLayout({
  windowInfo: { windowWidth: 800 },
  deviceInfo: { platform: 'windows' },
  menuRect: {}
})
if (
  desktopNavigationLayout.topInset !== 20
  || desktopNavigationLayout.edgeWidth !== 125
  || phoneNavigationLayout.topInset !== 0
  || phoneNavigationLayout.edgeWidth !== 97
  || invalidDesktopNavigationLayout.edgeWidth !== 72
) {
  throw new Error('自定义导航栏的桌面胶囊对齐或异常坐标兜底失效')
}
if (
  !supportsDesktopSplit({ windowWidth: 1200 }, 'mac')
  || supportsDesktopSplit({ windowWidth: 900 }, 'mac')
  || supportsDesktopSplit({ windowWidth: 1200 }, 'ios')
  || getDesktopSplitUrl('a b') !== '/pages/index/index?preview=a%20b'
) {
  throw new Error('Mac 同页分栏的宽度阈值、平台边界或回流地址失效')
}
if (
  !/wx\.onWindowResize\s*\(/.test(navigationLogic)
  || !/wx\.offWindowResize\s*\(/.test(navigationLogic)
  || !/getCurrentPages\(\)/.test(navigationLogic)
  || !/wx\.reLaunch\(\{\s*url:\s*HOME_PATH/.test(navigationLogic)
  || /align-items:\s*flex-start/.test(navigationStyle)
  || !/\.weui-navigation-bar__left\s*\{[\s\S]{0,260}align-items:\s*center/.test(navigationStyle)
  || !/\.weui-navigation-bar__btn_goback_wrapper\s*\{[\s\S]{0,260}width:\s*44px[\s\S]{0,160}height:\s*44px/.test(navigationStyle)
  || /margin:\s*-11px/.test(navigationStyle)
  || /data:image\/svg\+xml/.test(navigationStyle)
  || !/\/assets\/icons\/caret-left\.svg/.test(navigationMarkup)
  || !/\/assets\/icons\/circle-notch\.svg/.test(navigationMarkup)
) {
  throw new Error('自定义导航栏缺少电脑端对齐、完整返回热区或单页栈回首页兜底')
}

const h5IconElements = h5AppSource.match(
  /<[A-Z][A-Za-z0-9]*\s+[^>]*\bsize=\{[^}]+\}[^>]*>/g
) || []
if (
  h5IconElements.length < 20
  || h5IconElements.some((element) => !/\bweight="bold"/.test(element))
  || /weight="(?:fill|regular|light|thin|duotone)"/.test(h5AppSource)
) {
  throw new Error('H5 功能图标必须全部显式使用 Phosphor Icons Bold')
}
if (
  !/DESKTOP_SPLIT_MIN_WIDTH\s*=\s*960/.test(desktopSplitLogic)
  || !/desktopSplitEnabled/.test(homeLogic + homeMarkup)
  || !/desktopPreviewFileId/.test(homeLogic + homeMarkup)
  || !/<preview-panel/.test(homeMarkup)
  || !/isEmbeddedPreview\s*=\s*true/.test(embeddedPreviewLogic)
  || !/createPreviewSelectorQuery/.test(previewLogic + embeddedPreviewLogic)
  || !/external-back="\{\{true\}\}"/.test(embeddedPreviewMarkup)
  || (embeddedPreviewMarkup.match(/compact="\{\{true\}\}"/g) || []).length !== 5
  || !/:host\s*\{[\s\S]{0,180}background:\s*#0b0f14/.test(embeddedPreviewStyle)
  || !/getDesktopSplitUrl/.test(previewLogic)
  || !/wx\.reLaunch\(\{[\s\S]{0,100}url:\s*getDesktopSplitUrl/.test(previewLogic)
) {
  throw new Error('Mac 宽屏缺少同页分栏、嵌入式预览或内部返回逻辑')
}
async function readJavaScriptTree(relativeDirectory) {
  const absoluteDirectory = path.join(root, relativeDirectory)
  let entries = []
  try {
    entries = await fs.readdir(absoluteDirectory, { withFileTypes: true })
  } catch (error) {
    if (error.code === 'ENOENT') return []
    throw error
  }
  const sources = await Promise.all(entries.map(async (entry) => {
    const relativePath = path.join(relativeDirectory, entry.name)
    if (entry.isDirectory()) return readJavaScriptTree(relativePath)
    if (!entry.isFile() || !entry.name.endsWith('.js')) return []
    return [await fs.readFile(path.join(root, relativePath), 'utf8')]
  }))
  return sources.flat()
}

const businessJavaScript = [
  appLogic,
  ...await readJavaScriptTree('pages'),
  ...await readJavaScriptTree('components'),
  ...await readJavaScriptTree('utils')
].join('\n')

function sha256(bytes) {
  return crypto.createHash('sha256').update(bytes).digest('hex')
}

const packageWasm = await fs.readFile(
  path.join(root, 'node_modules/@rive-app/canvas-advanced/rive.wasm')
)
const nativeCompressedWasm = await fs.readFile(path.join(root, 'vendor/rive/rive.wasm.br'))
const fallbackPackageWasm = await fs.readFile(
  path.join(root, 'node_modules/@rive-app/canvas-advanced/rive_fallback.wasm')
)
const fallbackCompressedWasm = await fs.readFile(
  path.join(root, 'vendor/rive/rive_fallback.wasm.br')
)

if (sha256(packageWasm) !== sha256(await decompressBrotli(nativeCompressedWasm))) {
  throw new Error('原生 Brotli WASM 与依赖中的 Rive 运行时未保持一致')
}
if (sha256(fallbackPackageWasm) !== sha256(await decompressBrotli(fallbackCompressedWasm))) {
  throw new Error('兼容版 Brotli WASM 与依赖中的 Rive 运行时未保持一致')
}

if (
  appManifest.pages.some((page) => /h5/i.test(page))
  || /h5Preview|switchToH5|retryWithH5|h5Origin|h5-preview/i.test(
    appLogic + previewLogic + previewMarkup
  )
) {
  throw new Error('小程序包中仍有废弃的旧 H5 预览入口或配置')
}
if (
  appManifest.pages.includes('pages/web/index')
  || /openWebViewer|web-view-entry|<web-view/.test(homeLogic + homeMarkup)
  || !/WEB_VIEW_URL\s*=\s*['"]https:\/\/mikeywa\.site\/rive-viewer\/['"]/.test(homeLogic)
  || !/bindtap="copyWebViewerUrl"/.test(homeMarkup)
  || !/复杂文件用网页版更流畅：/.test(homeMarkup)
  || !/web-link-footer__url-fade/.test(homeMarkup)
  || !/>mikeywa\.site\/rive-viewer\/<\/text>/.test(homeMarkup)
  || !/\/assets\/icons\/copy-simple\.svg/.test(homeMarkup)
) {
  throw new Error('首页网页版底部提示、复制入口或旧 web-view 清理不完整')
}

if (
  /saveToDevice|saveTargetLabel|保存到电脑|保存到手机/.test(homeLogic + homeMarkup)
  || !/catchtap="shareFile"[\s\S]{0,160}>发送文件<\/button>/.test(homeMarkup)
  || !/catchtap="deleteFile"[\s\S]{0,180}>删除文件<\/button>/.test(homeMarkup)
  || (homeMarkup.match(/class="file-menu__danger"/g) || []).length !== 1
) {
  throw new Error('首页文件操作菜单必须只保留发送文件和删除文件')
}
if (
  !/class="import-dropzone"[\s\S]{0,160}hover-class="is-pressed"/.test(homeMarkup)
  || !/class="file-menu-toggle[\s\S]{0,240}hover-class="is-pressed"/.test(homeMarkup)
  || !/class="web-link-footer__copy"[\s\S]{0,180}hover-class="is-pressed"/.test(homeMarkup)
  || !/class="author-contact"[\s\S]{0,180}hover-class="is-pressed"/.test(homeMarkup)
  || !/hover-class="file-row--pressed"[\s\S]{0,80}hover-start-time="0"/.test(homeMarkup)
) {
  throw new Error('首页主要点击入口缺少即时放大反馈')
}

if (/pageResize(Start|Move|End)/.test(previewMarkup + previewLogic)) {
  throw new Error('画布缩放仍绑定在页面手势上')
}
if (!/class="stage-resizer[\s\S]*catchtouchstart="stageResizeStart"/.test(previewMarkup)) {
  throw new Error('原生画布缩放手柄缺少拖动绑定')
}
if (
  ![previewMarkup, embeddedPreviewMarkup].every((markup) => (
    /stageResizeMenuActive \? 'is-selecting'/.test(markup)
    && /stageResizeHoverFit === 'contain'/.test(markup)
    && /stageResizeHoverFit === 'cover'/.test(markup)
    && /stageResizeTapOpen \? 'is-tap-open'/.test(markup)
    && /stageResizePressActive \? 'is-press-active'/.test(markup)
    && /stage-resizer__mode--contain/.test(markup)
    && /stage-resizer__mode--cover/.test(markup)
    && /data-fit="contain"/.test(markup)
    && /data-fit="cover"/.test(markup)
    && /catchtouchstart="stageResizeStart"/.test(markup)
    && /catchlongpress="stageResizeLongPress"/.test(markup)
    && /class="stage-resizer__modes" aria-hidden="\{\{!stageResizeMenuActive\}\}"/.test(markup)
    && /catchtouchcancel="stageResizeCancel"/.test(markup)
    && /arrows-in-simple(?:-active)?\.svg/.test(markup)
    && /arrows-out-simple(?:-active)?\.svg/.test(markup)
  ))
  || !/getStageResizeHoverFit/.test(previewLogic)
  || !/updateStageResizeHover/.test(previewLogic)
  || !/stageResizeLongPress/.test(previewLogic)
  || !/openStageResizeTapMenu\(\)[\s\S]{0,500}stageResizeTapOpen:\s*true/.test(previewLogic)
  || !/STAGE_RESIZE_MENU_DISMISS_DELAY\s*=\s*3000/.test(previewLogic)
  || !/STAGE_RESIZE_DOUBLE_TAP_DELAY\s*=\s*500/.test(previewLogic)
  || !/STAGE_RESIZE_GESTURE_SLOP_RPX\s*=\s*16/.test(previewLogic)
  || !/stageResizeMenuDismissTimer\s*=\s*setTimeout/.test(previewLogic)
  || !/clearTimeout\(this\.stageResizeMenuDismissTimer\)/.test(previewLogic)
  || !/stageResizeEnd\(event\)[\s\S]{0,1200}STAGE_RESIZE_DOUBLE_TAP_DELAY[\s\S]{0,300}closeStageResizeTapMenu\(\(\) => this\.applyFit\(nextFit, true\), nextFit\)/.test(previewLogic)
  || !/stageResizeEnd\(event\)[\s\S]{0,1600}openStageResizeTapMenu\(\)/.test(previewLogic)
  || !/const releaseFit = this\.getStageResizeHoverFit\(clientX\)[\s\S]{0,500}this\.stageResizePointerMoved[\s\S]{0,160}releaseFit/.test(previewLogic)
  || !/toggleStageFit\(\)[\s\S]{0,160}this\.data\.fit === 'contain'[\s\S]{0,100}this\.applyFit\(nextFit, true\)/.test(previewLogic)
  || !/ratio < 1 \/ 3[\s\S]{0,80}'contain'/.test(previewLogic)
  || !/ratio > 2 \/ 3[\s\S]{0,80}'cover'/.test(previewLogic)
  || !/applyFit\(selectedFit, true\)/.test(previewLogic)
  || !/grid-template-columns:\s*repeat\(3/.test(embeddedPreviewStyle)
  || !/is-selecting \.stage-resizer__grip\s*\{[\s\S]{0,100}width:\s*calc\(33\.333% - 16rpx\)/.test(embeddedPreviewStyle)
  || !/is-tap-open \.stage-resizer__grip\s*\{[\s\S]{0,80}color:\s*#687588/.test(embeddedPreviewStyle)
  || !/is-press-active \.stage-resizer__grip\s*\{[\s\S]{0,80}color:\s*#f2c94c/.test(embeddedPreviewStyle)
  || !/stage-resizer__mode\s*\{[\s\S]{0,220}flex-direction:\s*row/.test(embeddedPreviewStyle)
  || ![previewStyle, embeddedPreviewStyle].every((style) => /stage-resizer\.is-selecting \.stage-resizer__mode\s*\{[\s\S]{0,140}pointer-events:\s*auto/.test(style))
  || !/stage-resizer__grip view\s*\{[\s\S]{0,80}height:\s*4rpx[\s\S]{0,180}transition:\s*height 360ms cubic-bezier\(\.22, 1\.22, \.36, 1\)/.test(embeddedPreviewStyle)
  || !/is-selecting \.stage-resizer__grip view\s*\{[\s\S]{0,60}height:\s*2\.5rpx/.test(embeddedPreviewStyle)
  || !/stage-resizer__mode\.is-hovered\s*\{[\s\S]{0,100}background:\s*rgba\(242, 201, 76, \.14\)/.test(embeddedPreviewStyle)
  || !/stage-resizer-grip\s*\{[\s\S]{0,100}height:\s*5px[\s\S]{0,260}height 360ms var\(--spring-gentle\)/.test(h5StyleSource)
  || !/stage-resizer\.is-selecting \.stage-resizer-grip\s*\{[\s\S]{0,100}height:\s*3px/.test(h5StyleSource)
  || !/stage-resizer-mode:hover,[\s\S]{0,100}background:\s*rgb\(242 201 76 \/ \.14\)/.test(h5StyleSource)
  || /bindtap="stageResizerTap"/.test(previewMarkup + embeddedPreviewMarkup)
  || /ignoreNextStageTap|stageResizerTap\(\)|selectStageResizeFit\(event\)/.test(previewLogic)
  || /stage-resizer__mode\.is-hovered\s*\{[\s\S]{0,120}(?:box-shadow|border)/.test(embeddedPreviewStyle)
  || !/stage-resizer\.is-selecting\s*\{\s*height:\s*40rpx/.test(embeddedPreviewStyle)
  || !/stage-resizer__modes\s*\{[\s\S]{0,180}top:\s*8rpx;[\s\S]{0,40}bottom:\s*8rpx/.test(embeddedPreviewStyle)
  || !/stage-resizer__mode--contain[\s\S]{0,140}translateX\(calc\(100% \+ 8rpx\)\) scale\(\.94\)/.test(embeddedPreviewStyle)
  || !/stage-resizer__mode--cover[\s\S]{0,140}translateX\(calc\(-100% - 8rpx\)\) scale\(\.94\)/.test(embeddedPreviewStyle)
  || !/stage-resizer\.is-selecting \.stage-resizer__mode[\s\S]{0,140}translateX\(0\) scale\(1\)/.test(embeddedPreviewStyle)
  || !/stage-resizer__mode--contain[\s\S]{0,100}justify-content:\s*center/.test(embeddedPreviewStyle)
  || !/stage-resizer__mode\s*\{[\s\S]{0,420}border-radius:\s*5rpx/.test(embeddedPreviewStyle)
  || !/arrows-in-simple-active\.svg/.test(previewMarkup + embeddedPreviewMarkup)
  || !/arrows-out-simple-active\.svg/.test(previewMarkup + embeddedPreviewMarkup)
  || !/stage-resizer__mode\.is-hovered \.stage-resizer__mode-icon--active[\s\S]{0,60}opacity:\s*1/.test(embeddedPreviewStyle)
  || !/--spring-gentle:\s*cubic-bezier\(\.22, 1\.22, \.36, 1\)/.test(h5StyleSource)
) {
  throw new Error('缩放手柄缺少单击展开、按住高亮、横向悬停或完整/铺满切换')
}

if (
  ![previewMarkup, embeddedPreviewMarkup].every((markup) => (
    /bindtouchmove="fileNavigationTouchMove"/.test(markup)
    && /fileHoverId === item\.id \? 'is-hovered'/.test(markup)
    && /hover-class="is-hovered is-pressed"/.test(markup)
  ))
  || !/measureFileMenu\(\)/.test(previewLogic)
  || !/selectAll\('\.file-popover__option'\)/.test(previewLogic)
  || !/fileNavigationTouchMove\(event\)/.test(previewLogic)
  || !/fileNavigationGestureMovedIntoMenu/.test(previewLogic)
  || !/closeFileMenu\(\(\) => this\.openFileById\(hoveredFileId\)\)/.test(previewLogic)
) {
  throw new Error('文件快捷菜单缺少按住滑选、高亮或松手直接打开能力')
}

if (
  ![previewMarkup, embeddedPreviewMarkup].every((markup) => {
    const inputIndex = markup.indexOf('状态机输入')
    const toneIndex = markup.indexOf('预览背景')
    const qualityIndex = markup.indexOf('渲染质量')
    const fitIndex = markup.indexOf('缩放方式')
    return inputIndex >= 0
      && toneIndex > inputIndex
      && qualityIndex > toneIndex
      && fitIndex > qualityIndex
      && /parameter-row parameter-row--last[\s\S]{0,100}缩放方式/.test(markup)
  })
  || !/loading-ring__spinner\s*\{[\s\S]{0,260}border-radius:\s*50%/.test(embeddedPreviewStyle)
  || !/\.tone\s*\{[\s\S]{0,100}width:\s*30rpx;[\s\S]{0,100}height:\s*20rpx/.test(embeddedPreviewStyle)
) {
  throw new Error('参数顺序、Loading 圆环或 1.5 倍背景色块未按设计实现')
}

if (
  ![previewStyle, embeddedPreviewStyle].every((style) => (
    /\.transport\s*\{[\s\S]{0,180}display:\s*flex;/.test(style)
    && /\.transport__primary,\s*\.transport__secondary\s*\{[\s\S]{0,120}width:\s*0;[\s\S]{0,100}flex:\s*1 1 0;/.test(style)
    && /\.speed-menu\s*\{[\s\S]{0,80}width:\s*0;[\s\S]{0,100}flex:\s*1 1 0;/.test(style)
    && /\.transport__file-button\s*\{[\s\S]{0,80}width:\s*0;[\s\S]{0,100}flex:\s*1 1 0;/.test(style)
    && !/\.transport__primary,\s*\.transport__secondary\s*\{[\s\S]{0,120}width:\s*100%;/.test(style)
  ))
  || !/\.select\(["']\.transport["']\)/.test(previewLogic)
  || !/\.select\(["']\.speed-menu["']\)/.test(previewLogic)
  || ![previewMarkup, embeddedPreviewMarkup].every((markup) => (
    !/transport__left|transport__playback|transport__files/.test(markup)
    && (markup.match(/class="transport__(?:primary|secondary|file-button)/g) || []).length === 4
    && (markup.match(/class="speed-menu\b/g) || []).length === 1
    && (markup.match(/role="button"/g) || []).length >= 5
    && !/<button[^>]+class="(?:transport__|speed-menu)/.test(markup)
    && /transport__slot--replay/.test(markup)
    && /transport__slot--next/.test(markup)
    && !/speed-menu-shell/.test(markup)
  ))
  || !/\.transport\s*\{[\s\S]{0,180}grid-template-columns:\s*repeat\(5/.test(h5StyleSource)
  || !/stageResizeTapOpen/.test(h5AppSource)
  || !/stageResizePressActive/.test(h5AppSource)
  || !/className="stage-resizer-modes"/.test(h5AppSource)
  || !/ShareNetwork[\s\S]{0,160}发送文件/.test(h5AppSource)
  || /不能删除/.test(h5AppSource)
  || !/getVisibleBuiltinFiles/.test(h5LibrarySource)
  || !/hideBuiltinFile/.test(h5LibrarySource)
  || !/\.tone-button\s*\{[\s\S]{0,100}width:\s*45px;[\s\S]{0,80}height:\s*30px/.test(h5StyleSource)
  || /label="文件操作"|继续导入|下载文件/.test(h5AppSource)
  || !/className="topbar-download"/.test(h5AppSource)
  || !/className="file-heading-download press-feedback"/.test(h5AppSource)
  || !/className="timeline-tag"/.test(h5AppSource)
  || !/\.parameter-tag\.timeline-tag\s*\{[\s\S]{0,100}padding-right:\s*25px;[\s\S]{0,60}padding-left:\s*25px;/.test(h5StyleSource)
  || !/const timelineProgress = `\$\{clamp\(timeline\.progress, 0, 1\) \* 100\}%`/.test(h5AppSource)
  || !/progress=\{metadata\.activeAnimation === name \? timelineProgress : undefined\}/.test(h5AppSource)
  || !/<i className="timeline-progress" style=\{\{ width: progress \}\} aria-hidden="true" \/>/.test(h5AppSource)
  || !/\.timeline-progress\s*\{[\s\S]{0,120}position:\s*absolute;[\s\S]{0,160}background:\s*rgb\(242 201 76 \/ \.32\);[\s\S]{0,120}transition:\s*width 100ms linear/.test(h5StyleSource)
  || /var\(--timeline-progress\)/.test(h5StyleSource)
  || !/fit === "contain" && hasStageAspect/.test(h5AppSource)
  || !/\.canvas-card\.is-proportional\s*\{[\s\S]{0,120}height:\s*auto;[\s\S]{0,80}min-height:\s*0/.test(h5StyleSource)
  || !/\.file-row:hover,[\s\S]{0,120}\.file-row\.is-menu-open\s*\{[\s\S]{0,100}background:/.test(h5StyleSource)
  || !/<MiniProgramEntry \/>/.test(h5AppSource)
  || !/mini-program-code\.webp/.test(h5AppSource)
  || !/\.mini-program-entry:hover \.mini-program-popover,[\s\S]{0,180}opacity:\s*1/.test(h5StyleSource)
) {
  throw new Error('小程序与 H5 的五格播放区、首页菜单、手柄或背景色块未同步')
}

if (
  ![previewMarkup, embeddedPreviewMarkup].every((markup) => (
    /hover-class="is-pressed"[\s\S]{0,100}hover-start-time="0"/.test(markup)
    && /class="native-menu-backdrop"[\s\S]{0,80}catchtap="dismissNativeMenus"/.test(markup)
  ))
  || !/transform:\s*scale\(1\.25\)/.test(embeddedPreviewStyle)
  || !/cubic-bezier\(\.34, 1\.56, \.64, 1\)/.test(embeddedPreviewStyle)
  || !/fileNavigationLongPressTimer = setTimeout\([\s\S]{0,180}, 150\)/.test(previewLogic)
  || !/speedLongPressTimer = setTimeout\([\s\S]{0,180}, 150\)/.test(previewLogic)
  || !/dismissNativeMenus\(\)/.test(previewLogic)
) {
  throw new Error('预览控件缺少即时放大反馈、150ms 快捷菜单或点空白关闭能力')
}
if (
  !/toggleStageFit/.test(previewLogic)
  || !/双击切换完整或铺满/.test(previewMarkup)
  || !/三秒后收起/.test(previewMarkup)
) {
  throw new Error('画板手柄缺少单击三秒收起或双击完整/铺满切换')
}
if (!/count:\s*100/.test(homeLogic) || !/importSelectedFiles/.test(homeLogic)) {
  throw new Error('微信聊天文件多选导入未启用')
}
const clipboardReadCalls = businessJavaScript.match(/wx\.getClipboardData\s*\(/g) || []
const clipboardWriteCalls = businessJavaScript.match(/wx\.setClipboardData\s*\(/g) || []
if (
  clipboardReadCalls.length
  || clipboardWriteCalls.length !== 1
  || !/copyWebViewerUrl\(\)\s*\{[\s\S]{0,500}wx\.setClipboardData\(\{[\s\S]{0,160}data:\s*WEB_VIEW_URL/.test(homeLogic)
  || !/success:\s*\(\)\s*=>\s*\{[\s\S]{0,120}title:\s*['"]已复制网址['"]/.test(homeLogic)
) {
  throw new Error('剪贴板仅允许在用户点击后写入网页版地址，禁止读取或后台写入')
}
if (/thumbnailCanvas|generateMissingThumbnails|scheduleMissingThumbnails/.test(homeLogic + homeMarkup)) {
  throw new Error('首页仍在后台创建 Rive 缩略图画布')
}
if (
  !/showShareMenu/.test(shareLogic)
  || !/FRIEND_SHARE_IMAGE\s*=\s*['"]\/share-friend\.png['"]/.test(shareLogic)
  || !/TIMELINE_SHARE_IMAGE\s*=\s*['"]\/share-timeline\.png['"]/.test(shareLogic)
  || !/menus:\s*SHARE_MENUS/.test(shareLogic)
  || !/shareAppMessage/.test(shareLogic)
  || !/shareTimeline/.test(shareLogic)
  || !/showShareMenu\.object\.menus/.test(shareLogic)
  || /canIUse\(['"]showShareMenu\.menus['"]\)/.test(shareLogic)
  || ![homeLogic, previewLogic].every((source) => (
    /onShareAppMessage:\s*function\s*\(\)/.test(source)
    && /onShareTimeline:\s*function\s*\(\)/.test(source)
    && /imageUrl:\s*FRIEND_SHARE_IMAGE/.test(source)
    && /imageUrl:\s*TIMELINE_SHARE_IMAGE/.test(source)
    && /onShow\(\)\s*{[\s\S]{0,120}enableShareMenu\(\)/.test(source)
  ))
) {
  throw new Error('首页或原生预览没有完整开启微信分享菜单')
}

const friendShareBytes = (await fs.stat(path.join(root, 'share-friend.png'))).size
const timelineShareBytes = (await fs.stat(path.join(root, 'share-timeline.png'))).size
if (friendShareBytes > 140 * 1024 || timelineShareBytes > 40 * 1024) {
  throw new Error('分享缩略图体积过大，请先压缩再打包')
}
if (
  !/HIDDEN_BUILTIN_STORAGE_KEY/.test(libraryLogic)
  || !/writeHiddenBuiltinIds/.test(libraryLogic)
  || !/visibleBuiltins/.test(libraryLogic)
  || /disabled="\{\{item\.builtin\}\}"/.test(homeMarkup)
  || /file\.builtin\) return/.test(homeLogic)
) {
  throw new Error('示例文件仍不能从本地列表删除')
}
if (
  !/loadingProgress/.test(previewMarkup)
  || !/readFileWithProgress/.test(previewLogic + libraryLogic)
  || !/onFirstFrame/.test(previewLogic)
) {
  throw new Error('原生大文件加载进度或首帧完成反馈缺失')
}
if (
  !/type === 'down'[\s\S]*ensureStateMachine/.test(nativeRuntime)
  || !/getCanvasTouchPoint/.test(previewLogic)
) {
  throw new Error('画布首次点击未自动接管到 Rive 状态机')
}
if (
  !/node_modules\/@rive-app\/canvas-advanced['"]?\)/.test(vendorScript)
  || /canvas-advanced-lite/.test(vendorScript)
  || !/BROTLI_PARAM_QUALITY/.test(vendorScript)
  || !/rive\.wasm\.br/.test(nativeRuntime)
) {
  throw new Error('Rive vendor 脚本未固定到完整 Canvas 运行时')
}
const hasCorrectAdvanceOrder = (source) => (
  /stateMachine\.advance\(elapsed\)[\s\S]{0,100}artboard(?:\?\.|\.)advance\(elapsed\)/.test(source)
  && !/advanceAndApply/.test(source)
)
if (
  !/activeStateMachineHasListeners\(\)/.test(nativeRuntime)
  || !/runtime\.hasListeners\(this\.stateMachine\)/.test(nativeRuntime)
  || !hasCorrectAdvanceOrder(nativeRuntime)
  || !/advanceStateMachine\(0\)/.test(nativeRuntime)
  || !/pointerExit/.test(nativeRuntime)
) {
  throw new Error('含 Listener 的状态机未获得默认交互优先级')
}
if (
  !/defaultArtboardViewModel/.test(nativeRuntime)
  || !/setViewModelInstance/.test(nativeRuntime)
  || !/target\.bind\(\)/.test(nativeRuntime)
  || !/boundViewModelInstances/.test(nativeRuntime)
) {
  throw new Error('Rive View Model 默认实例未自动绑定')
}
if (
  /canvasX\s*=\s*x\s*\*\s*this\.pixelRatio/.test(nativeRuntime)
  || !/clientX\s*-\s*canvasLeft/.test(previewLogic)
) {
  throw new Error('真机触摸未使用逻辑画布坐标')
}
if (
  !/enteredOnlyUnnamedStates/.test(nativeRuntime)
  || !/fallbackAnimation/.test(nativeRuntime)
) {
  throw new Error('空状态 Trigger 缺少同名时间轴回退')
}
if (
  !/Image:\s*root\.Image/.test(nativeRuntime)
  || !/DOMMatrix:\s*root\.DOMMatrix/.test(nativeRuntime)
  || !/var Image = moduleArg\.Image/.test(nativeVendor)
  || !/var DOMMatrix = moduleArg\.DOMMatrix/.test(nativeVendor)
  || !/var URL = moduleArg\.URL/.test(nativeVendor)
  || !/I\.onerror = function\(\)/.test(nativeVendor)
  || !/this\.Oa && URL\.revokeObjectURL\(this\.Oa\)/.test(nativeVendor)
) {
  throw new Error('原生运行时缺少图片失败回退或 DOMMatrix 兼容层')
}
if (
  /return canvas\.createPath2D\(\)/.test(nativeRuntime)
  || !/return animationCanvas\.createPath2D\(\)/.test(nativeRuntime)
  || !/this\.runtime\.requestAnimationFrame\(callback\)/.test(nativeRuntime)
  || !/this\.runtime\.cancelAnimationFrame\(requestId\)/.test(nativeRuntime)
) {
  throw new Error('Rive 运行时仍可能绑定到已销毁的旧 Canvas')
}
if (
  projectManifest.setting?.babelSetting?.ignore?.includes('vendor/rive/canvas_advanced.js')
  || !projectManifest.packOptions?.ignore?.some((item) => (
    item.type === 'file' && item.value === 'project.private.config.json'
  ))
) {
  throw new Error('上传构建跳过了兼容编译或仍会打包本地私有配置')
}
if (
  !/rive_fallback\.wasm\.br/.test(nativeRuntime)
  || !/type="2d"/.test(previewMarkup)
  || !/loadPlayerWithTimeout/.test(previewLogic)
) {
  throw new Error('小程序 Canvas、真机 WASM 或加载超时回退不完整')
}
if (
  !/prewarmRuntime/.test(homeLogic)
  || !/setTimeout\(\(\) => this\.startRivePrewarm\(\), 600\)/.test(homeLogic)
  || !/installRuntimeShims\(null, \{ probeAudio: false \}\)/.test(nativeRuntime)
  || !/IOS_AUDIO_FRAME_INTERVAL/.test(nativeRuntime)
  || !/IOS_AUDIO_PIXEL_RATIO_LIMIT/.test(nativeRuntime)
  || !/audioResumeTasks/.test(nativeRuntime)
  || !/queueActiveState/.test(previewLogic)
) {
  throw new Error('Rive 首页预热或 iOS 音频性能档不完整')
}
if (
  !/loadArtboardCatalog/.test(nativeRuntime)
  || !/artboardCatalogLoaded/.test(nativeRuntime + previewLogic)
  || !/artboardCount/.test(nativeRuntime + previewLogic)
  || !/bindtap="expandArtboardCatalog"/.test(previewMarkup)
  || !/IOS_COMPLEX_FRAME_INTERVAL/.test(nativeRuntime)
  || !/IOS_COMPLEX_PIXEL_RATIO_LIMIT/.test(nativeRuntime)
  || !/cancelFrame\(this\.frameRequest\)/.test(nativeRuntime)
  || /artboards:\s*metadata\.artboards/.test(previewLogic)
) {
  throw new Error('复杂 Rive 首帧懒解析、画板按需展开或暂停绘制保护不完整')
}
if (
  !/class MiniProgramCueAudio/.test(nativeRuntime)
  || !/createBufferSource\(\)/.test(nativeRuntime)
  || !/isPianoAudioCandidate/.test(nativeRuntime)
  || !/nativePianoAudio && asset\?\.isAudio/.test(nativeRuntime)
  || !/nativePianoAudio\.capture\(asset, bytes\)[\s\S]{0,80}return true/.test(nativeRuntime)
  || !/collectPianoCueChanges/.test(nativeRuntime)
  || !/disableNativePianoAudio/.test(nativeRuntime)
  || !/hasRequiredPianoCues/.test(nativeRuntime)
  || !/PIANO_AUDIO_DECODE_TIMEOUT/.test(nativeRuntime)
  || !/MAX_ACTIVE_PIANO_SOURCES/.test(nativeRuntime)
  || !/fileName:\s*this\.data\.file\.name/.test(previewLogic)
) {
  throw new Error('iOS 钢琴低延迟音效通道不完整')
}
if (
  !/audioEnabled:\s*true/.test(previewLogic)
  || !/riveAudioEnabled/.test(previewLogic)
  || !/sourceSize:\s*fileSize/.test(previewLogic)
  || !/bind:select="toggleAudio"/.test(previewMarkup)
  || !/wx:if="\{\{hasAudio\}\}"/.test(previewMarkup)
  || !/wx\.createWebAudioContext/.test(nativeRuntime)
  || !/context\.createScriptProcessor/.test(nativeRuntime)
  || !/miniProgramAudioCapability === true/.test(nativeRuntime)
  || /miniProgramAudioCapability\s*=\s*false/.test(nativeRuntime)
  || !/shouldBypassEmbeddedAudio/.test(nativeRuntime)
  || !/artboard\.volume/.test(nativeRuntime)
  || !/suspendRuntimeAudio/.test(nativeRuntime)
  || !/MAX_AUDIO_SOURCE_BYTES/.test(nativeRuntime)
  || !/audioWindow:\s*runtimeAudioWindow/.test(nativeRuntime)
  || !/moduleArg\.audioWindow\.AudioContext/.test(nativeVendor)
  || !/moduleArg\.audioWindow\.miniaudio/.test(nativeVendor)
  || /window\.(?:AudioContext|webkitAudioContext|miniaudio)/.test(nativeVendor)
  || /getUserMedia/.test(nativeVendor)
  || !/replaceAll\('window\.AudioContext'/.test(vendorScript)
) {
  throw new Error('Rive 声音默认开启、切换、性能保护或微信 WebAudio 兼容层不完整')
}

console.log('项目结构、JSON、Rive 文件头与可见文案检查通过。')
