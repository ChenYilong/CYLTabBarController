import assert from "node:assert/strict";
import { access, readFile, readdir } from "node:fs/promises";
import test from "node:test";

function normalizedBuildBase() {
  const configured = process.env.RIVE_VIEWER_BASE || "/rive-viewer/";
  if (configured === "/") return "/";
  return `/${configured.replace(/^\/+|\/+$/g, "")}/`;
}

test("builds the viewer at the configured public base", async () => {
  const base = normalizedBuildBase();
  const nginxConfig = base === "/"
    ? "../deploy/nginx-rive-host.conf"
    : base === "/beta/"
      ? "../deploy/nginx-rive-host-beta.conf"
      : "../deploy/nginx-rive-viewer.conf";
  const [html, nginx, hostedNginx] = await Promise.all([
    readFile(new URL("../dist-static/index.html", import.meta.url), "utf8"),
    readFile(new URL(nginxConfig, import.meta.url), "utf8"),
    readFile(new URL("../deploy/nginx-rive-host.conf", import.meta.url), "utf8"),
  ]);

  assert.match(html, /<title>Rive 预览台 H5<\/title>/i);
  const escapedBase = base.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  assert.match(html, new RegExp(`${escapedBase}assets/index-[^"']+\\.js`));
  assert.match(html, /<div id="root"><\/div>/);
  assert.match(hostedNginx, /POST:\/api\/v1\/shares\(\?:\/\[0-9A-Za-z\]\{3\}\/versions\)\?\$/);
  if (base === "/") {
    assert.match(nginx, /server_name rive\.mikeywa\.site/);
    assert.match(nginx, /location \^~ \/api\//);
    assert.match(nginx, /location ~ "\^\/s\/\(\[0-9A-Za-z\]\{3\}\)\/\?\$"/);
    assert.match(nginx, /return 308 \/\$1\$is_args\$args/);
    assert.match(nginx, /location ~ "\^\/\[0-9A-Za-z\]\{3\}\/\?\$"/);
    assert.match(nginx, /location \^~ \/samples\/\s*\{\s*return 404;/);
    assert.match(nginx, /location = \/samples\s*\{\s*return 404;/);
  } else if (base === "/beta/") {
    assert.match(nginx, /location = \/beta/);
    assert.match(nginx, /\/var\/www\/rive-host-beta\/current/);
    assert.match(nginx, /location \^~ \/beta\/assets\//);
    assert.match(nginx, /try_files \$uri \$uri\/ \/beta\/index\.html/);
  } else {
    assert.match(nginx, /location = \/rive-viewer/);
    assert.match(nginx, /return 308 \/rive-viewer\//);
  }
});

test("splits Rive, Lottie, and PAG runtimes from the initial application chunk", async () => {
  const assetNames = await readdir(new URL("../dist-static/assets/", import.meta.url));
  const appChunk = assetNames.find((name) => /^index-.*\.js$/.test(name));
  const riveChunk = assetNames.find((name) => /^rive-player-.*\.js$/.test(name));
  const canvasRuntimeChunk = assetNames.find((name) => /^canvas_advanced-.*\.js$/.test(name));
  const webglRuntimeChunk = assetNames.find((name) => /^webgl2_advanced-.*\.js$/.test(name));
  const lottieChunk = assetNames.find((name) => /^lottie_canvas-.*\.js$/.test(name));
  const pagChunk = assetNames.find((name) => /^pag-player-.*\.js$/.test(name));
  const pagWasm = assetNames.find((name) => /^libpag-.*\.wasm$/.test(name));

  assert.ok(appChunk, "缺少应用入口 chunk");
  assert.ok(riveChunk, "Rive 播放器没有独立拆包");
  assert.ok(canvasRuntimeChunk, "Canvas2D 兼容运行时没有独立拆包");
  assert.ok(webglRuntimeChunk, "WebGL2 运行时没有独立拆包");
  assert.ok(lottieChunk, "Lottie 运行时没有独立拆包");
  assert.ok(pagChunk, "PAG 播放器没有独立拆包");
  assert.ok(pagWasm, "PAG WASM 没有独立拆包");
  await access(new URL("../dist-static/rive-2.39.1.wasm.gz", import.meta.url));
  await access(new URL("../dist-static/rive-2.39.1.wasm.br", import.meta.url));
  await access(new URL("../dist-static/rive-webgl2-2.39.1.wasm.gz", import.meta.url));
  await access(new URL("../dist-static/rive-webgl2-2.39.1.wasm.br", import.meta.url));
});

test("ships the browser runtime and browser-persisted library without default examples", async () => {
  const [wasm, webglWasm, miniProgramCode, librarySource] = await Promise.all([
    readFile(new URL("../public/rive-viewer/rive-2.39.1.wasm", import.meta.url)),
    readFile(new URL("../public/rive-viewer/rive-webgl2-2.39.1.wasm", import.meta.url)),
    readFile(new URL("../public/rive-viewer/mini-program-code.webp", import.meta.url)),
    readFile(new URL("../lib/library.ts", import.meta.url), "utf8"),
  ]);

  assert.ok(wasm.byteLength > 1_000_000);
  assert.ok(webglWasm.byteLength > wasm.byteLength);
  assert.ok(miniProgramCode.byteLength < 50_000);
  assert.match(librarySource, /indexedDB/);
  assert.match(librarySource, /recent-hosted/);
  assert.doesNotMatch(librarySource, /fetch\(["'`]https?:|fetch\(["'`]\/api|XMLHttpRequest|FormData/);
  await assert.rejects(access(new URL("../public/rive-viewer/samples/guide.riv", import.meta.url)));
  await assert.rejects(access(new URL("../public/rive-viewer/samples/question.riv", import.meta.url)));
  await assert.rejects(access(new URL("../dist-static/samples/guide.riv", import.meta.url)));
  await assert.rejects(access(new URL("../dist-static/samples/question.riv", import.meta.url)));
  await access(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url));
});

test("keeps high-frequency playback state outside the page component", async () => {
  const [appSource, playerSource, telemetrySource, styleSource] = await Promise.all([
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
    readFile(new URL("../lib/rive-player.ts", import.meta.url), "utf8"),
    readFile(new URL("../lib/playback-telemetry.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
  ]);

  assert.doesNotMatch(appSource, /@phosphor-icons\/react/);
  assert.match(appSource, /await import\("\.\.\/\.\.\/lib\/animation-player"\)/);
  assert.match(appSource, /<PlaybackMeta telemetry=\{telemetry\} \/>/);
  assert.match(appSource, /<TimelineControl/);
  assert.doesNotMatch(appSource, /const \[timeline, setTimeline\]/);
  assert.doesNotMatch(appSource, /const \[fps, setFps\]/);
  assert.match(telemetrySource, /useSyncExternalStore|class PlaybackTelemetry/);
  assert.match(playerSource, /policy\.telemetry\.webMetadataMs/);
  assert.match(playerSource, /this\.emitMetadata\(false, timestamp\)/);
  assert.match(styleSource, /\.app-icon\s*\{[\s\S]{0,220}mask:/);
});

test("defaults to WebGL2, exposes the engine selector last, and keeps automatic fallback visible", async () => {
  const [appSource, playerSource, html, styleSource] = await Promise.all([
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
    readFile(new URL("../lib/rive-player.ts", import.meta.url), "utf8"),
    readFile(new URL("../static/index.html", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
  ]);

  assert.match(playerSource, /DEFAULT_RENDER_ENGINE: RenderEngine = "webgl2"/);
  assert.match(playerSource, /import\("@rive-app\/webgl2-advanced"\)/);
  assert.match(playerSource, /import\("@rive-app\/canvas-advanced"\)/);
  assert.match(playerSource, /this\.renderer\.flush\(\)/);
  assert.match(appSource, /WebGL2 不可用，已切换到兼容模式/);
  assert.match(appSource, /<EngineToast message=\{engineToast\} \/>/);
  assert.match(styleSource, /\.engine-toast\s*\{/);
  assert.ok(
    appSource.indexOf('<ParameterRow label="渲染引擎">')
      > appSource.indexOf('<ParameterRow label="缩放方式">'),
    "渲染引擎必须是文件预览选项的最后一项",
  );
  assert.doesNotMatch(html, /\.wasm/);
});

test("batches stage resizing and delays backing-canvas allocation", async () => {
  const [appSource, lottieSource, pagSource, styleSource] = await Promise.all([
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
    readFile(new URL("../lib/lottie-player.ts", import.meta.url), "utf8"),
    readFile(new URL("../lib/pag-player.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
  ]);
  const moveBody = appSource.slice(
    appSource.indexOf("const moveStageResize"),
    appSource.indexOf("const endStageResize"),
  );

  assert.match(moveBody, /requestAnimationFrame/);
  assert.doesNotMatch(moveBody, /setStageHeight\(/);
  assert.match(
    appSource,
    /if \(draggingStageRef\.current \|\| draggingInspectorRef\.current\)[\s\S]{0,180}pendingPlayerSizeRef/,
  );
  assert.match(appSource, /stageKeepsSourceAspect = activeFile\?\.file\.format === "rive"/);
  assert.match(appSource, /keepSourceAspect = activeFile\?\.file\.format === "rive"[\s\S]{0,180}fitRef\.current === "contain"/);
  assert.match(appSource, /className=\{`canvas-card[\s\S]{0,100}stageKeepsSourceAspect/);
  assert.match(lottieSource, /lottie-web\/build\/player\/lottie_canvas/);
  assert.match(lottieSource, /progressiveLoad:\s*false/);
  assert.doesNotMatch(lottieSource, /lottie_light_canvas/);
  assert.match(pagSource, /this\.view = view;\s*this\.resize\(this\.cssWidth, this\.cssHeight\);/);
  assert.match(styleSource, /\.canvas-card canvas\s*\{[\s\S]{0,100}width:\s*100% !important;[\s\S]{0,100}height:\s*100% !important;/);
});

test("recreates the canvas when switching animation formats", async () => {
  const appSource = await readFile(
    new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url),
    "utf8",
  );

  assert.match(appSource, /key=\{`\$\{activeFile\.file\.format\}-\$\{canvasGeneration\}`\}/);
  assert.doesNotMatch(appSource, /<canvas\s+key=\{canvasGeneration\}/);
});

test("uses a resizable inspector from iPad Pro landscape width", async () => {
  const [appSource, hostedPanelsSource, timelineSource, timelineHintSource, styleSource, packageJson] = await Promise.all([
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/HostedPanels.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/PlaybackTelemetryView.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/TimelineHint.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
  ]);

  assert.match(appSource, /WIDE_INSPECTOR_DEFAULT_WIDTH = 360/);
  assert.match(appSource, /WIDE_INSPECTOR_MIN_WIDTH = 360/);
  assert.match(appSource, /WIDE_PREVIEW_PREFERRED_WIDTH = 800/);
  assert.match(appSource, /STAGE_MIN_HEIGHT = 50/);
  assert.match(appSource, /clamp\([\s\S]{0,160}STAGE_MIN_HEIGHT,[\s\S]{0,80}maximum/);
  assert.match(appSource, /aria-valuemin=\{STAGE_MIN_HEIGHT\}/);
  assert.match(styleSource, /\.canvas-card\s*\{[\s\S]{0,100}min-height:\s*50px;/);
  assert.match(appSource, /workbench\.clientWidth - WIDE_COLUMN_RESIZER_WIDTH - WIDE_PREVIEW_PREFERRED_WIDTH/);
  assert.match(appSource, /FILE_RAIL_MIN_WIDTH = 160/);
  assert.match(appSource, /aria-label="调整最近文件栏宽度"/);
  assert.match(appSource, /className="preview-file-name-tooltip"/);
  assert.match(styleSource, /var\(--preview-file-rail-width, 184px\)/);
  assert.match(styleSource, /\.preview-file-rail-resizer:hover > span/);
  assert.match(appSource, /role="separator"/);
  assert.match(appSource, /requestAnimationFrame[\s\S]{0,220}applyInspectorWidth/);
  assert.match(appSource, /const handleShortcut = \(event: KeyboardEvent\) => \{\s*if \(event\.defaultPrevented\) return;/);
  assert.match(appSource, /resizeInspectorWithKeyboard[\s\S]{0,700}event\.preventDefault\(\);\s*event\.stopPropagation\(\);/);
  assert.match(appSource, /draggingStageRef\.current \|\| draggingInspectorRef\.current/);
  assert.match(styleSource, /@media \(min-width: 1194px\)/);
  assert.match(styleSource, /\.drawer-workspace\.is-open\s*\{[\s\S]{0,80}width:\s*100%;/);
  assert.match(styleSource, /\.preview-workbench[\s\S]{0,280}grid-template-columns/);
  assert.match(
    styleSource,
    /\.preview-main-column:not\(\.is-stage-height-customized\) \.canvas-card:not\(\.is-proportional\)[\s\S]{0,260}flex: 1;/,
  );
  assert.match(styleSource, /\.preview-main-column:not\(\.is-stage-height-customized\) \.canvas-card\.is-proportional[\s\S]{0,180}height: auto !important;[\s\S]{0,160}align-self: center;/);
  assert.doesNotMatch(styleSource, /\.preview-main-column \.stage-resizer\s*\{\s*display: none;/);
  assert.match(appSource, /is-stage-height-customized/);
  assert.match(styleSource, /\.preview-main-column\.is-stage-height-customized \.canvas-card:not\(\.is-proportional\)[\s\S]{0,220}height: var\(--manual-stage-height\) !important;/);
  assert.match(appSource, /stageSizingHeight[\s\S]{0,300}width: `min\(100%, \$\{Math\.round\(stageSizingHeight \* stageAspect\)\}px\)`/);
  assert.match(styleSource, /\.comment-item p\s*\{[\s\S]{0,120}margin: 8px 0 0 40px;[\s\S]{0,120}font-size: 14px;/);
  assert.match(styleSource, /\.file-sync-status\.is-ready\s*\{\s*color: var\(--quiet\);/);
  assert.match(appSource, /className="file-open press-feedback-large"[\s\S]{0,120}onClick=\{\(\) => onOpen\(item\)\}/);
  assert.match(appSource, /className="preview-file-row-open press-feedback-large"[\s\S]{0,120}onClick=\{\(\) => onOpen\(item\)\}/);
  assert.match(appSource, /className=\{`file-sync-status is-\$\{state\.phase\}`\}/);
  assert.doesNotMatch(appSource, /file-sync-toggle|onToggleUpload|FileUploadStatusButton/);
  assert.match(appSource, /<Icon name=\{icon\} size=\{13\} \/>/);
  assert.doesNotMatch(appSource, /Rive 公开预览/);
  assert.match(appSource, /aria-label="关闭文件详情"[\s\S]{0,150}<Icon name="x" size=\{21\}/);
  assert.match(styleSource, /\.preview-file-add\s*\{[\s\S]{0,180}background:\s*var\(--control\);/);
  assert.match(hostedPanelsSource, /contentEditable=\{!submitting\}/);
  assert.match(hostedPanelsSource, /<form className="comment-form"[\s\S]{0,120}\{!draftBody && <TimelineHint \/>\}/);
  assert.match(hostedPanelsSource, /getCommentKeyboardAction/);
  assert.match(hostedPanelsSource, /document\.execCommand\("insertLineBreak"\)/);
  assert.match(hostedPanelsSource, /closest\("form"\)\?\.requestSubmit\(\)/);
  assert.match(styleSource, /\.comment-submit-row\s*\{[\s\S]{0,120}z-index:\s*2;/);
  assert.match(hostedPanelsSource, /className="comment-hover-caret"/);
  assert.match(styleSource, /caret-color:\s*var\(--accent\)/);
  assert.match(styleSource, /\.comment-editor\[data-empty="true"\]:hover ~ \.comment-hover-caret/);
  assert.match(styleSource, /comment-hover-caret-blink 900ms/);
  assert.match(hostedPanelsSource, /className="comment-identity-row"/);
  assert.match(appSource, /const navigateHostedShare = useCallback/);
  assert.match(appSource, /window\.history\.pushState[\s\S]{0,900}setShareCode\(code\)/);
  assert.doesNotMatch(appSource, /window\.location\.reload\(\)/);
  assert.match(appSource, /publicShareState !== "ready" && !activeFile/);
  assert.doesNotMatch(timelineSource, /TimelineHint/);
  assert.match(hostedPanelsSource, /data-comment-timeline/);
  assert.match(hostedPanelsSource, /formatCommentTimelineMarker/);
  assert.match(hostedPanelsSource, /parseCommentTimelineSegments/);
  assert.match(hostedPanelsSource, /marker\.after\(spacer\)/);
  assert.match(hostedPanelsSource, /className = "comment-draft-timeline"/);
  assert.match(hostedPanelsSource, /className="comment-timeline-link"/);
  assert.match(hostedPanelsSource, /onPointerUp=\{\(event\) => event\.currentTarget\.blur\(\)\}/);
  assert.match(hostedPanelsSource, /onClick=\{\(\) => onSelectTimeline\(segment\.timelineName\)\}/);
  assert.doesNotMatch(hostedPanelsSource, /comment-timeline-link.*is-active/);
  assert.match(styleSource, /\.comment-timeline-link\s*\{[\s\S]{0,300}color: inherit;[\s\S]{0,300}text-decoration: underline;/);
  assert.match(styleSource, /\.comment-timeline-link:hover,[\s\S]{0,100}color: var\(--accent\);/);
  assert.match(appSource, /onSelectTimeline=\{selectTimeline\}/);
  assert.match(appSource, /<TimelineControl[\s\S]{0,220}onSelect=\{selectTimelineFromControl\}/);
  assert.match(timelineSource, />\s*展开\s*<\/button>/);
  assert.match(timelineSource, />\s*整理\s*<\/button>/);
  assert.match(timelineSource, /organizeTimelines\(animations\)/);
  assert.match(timelineSource, /hasOrganizableTimelineGroups\(organizedSections\)/);
  assert.match(timelineSource, /getDefaultTimelineLayout\(animations\.length, canOrganize\)/);
  assert.match(timelineSource, /\{canOrganize && <span className="timeline-layout-switch"/);
  assert.match(timelineSource, /layoutSelection\.animationSignature === animationSignature/);
  assert.match(appSource, /<TimelineControl\s+key=\{activeFile\.sessionId\}/);
  assert.match(timelineSource, /timelineButton\(item\.name, item\.label\)/);
  assert.match(timelineSource, /animations\.length > 10 \? "is-compact"/);
  assert.match(timelineHintSource, /import\("calligraph"\)/);
  assert.match(timelineHintSource, /prefers-reduced-motion: reduce/);
  assert.match(timelineHintSource, /点击时间轴，可以直接引用到评论/);
  assert.match(packageJson, /"calligraph": "\^1\.4\.1"/);
  assert.match(styleSource, /\.timeline-layout-switch button\s*\{[\s\S]{0,160}font-size:\s*12px;/);
  assert.match(styleSource, /\.timeline-group\s*\{[\s\S]{0,160}grid-template-columns:\s*max-content minmax\(0, 1fr\);/);
  assert.match(styleSource, /\.timeline-label\s*\{[\s\S]{0,180}position:\s*sticky;[\s\S]{0,80}top:\s*56px;/);
  assert.match(styleSource, /\.timeline-group-title\s*\{[\s\S]{0,180}padding:\s*9px 0 0 8px;[\s\S]{0,100}position:\s*sticky;[\s\S]{0,60}top:\s*88px;/);
  assert.match(styleSource, /\.timeline-group:has\(\.timeline-tag:hover\) \.timeline-group-title/);
  assert.match(styleSource, /\.timeline-parameter-row\.is-compact \.parameter-tag\.timeline-tag\s*\{[\s\S]{0,100}padding:\s*6px;/);
  assert.match(styleSource, /\.comment-meta-row \.comment-archive-action\s*\{[\s\S]{0,180}border: 0;[\s\S]{0,100}opacity: 0;/);
  assert.match(styleSource, /\.comment-item:hover \.comment-archive-action/);
  assert.doesNotMatch(hostedPanelsSource, /bodyLength|\/1000<\/span>/);
});
