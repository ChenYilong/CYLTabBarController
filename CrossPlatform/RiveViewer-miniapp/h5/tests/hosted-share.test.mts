import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import test from "node:test";
import {
  hostedSharePath,
  shareCodeFromPath,
  viewerHomePath,
} from "../lib/viewer-route.ts";
import {
  createHostedComment,
  getHostedCommentIdentity,
  getHostedFile,
  HostedApiError,
} from "../lib/hosted-api.ts";
import { limitCommentNickname } from "../lib/comment-identity.ts";
import { hostedVersions, selectedHostedVersion } from "../lib/file-versions.ts";
import { mergeRecentHostedRecords } from "../lib/library.ts";
import { hostedShareName } from "../lib/hosted-share-name.ts";
import { mergeUnifiedFiles } from "../lib/unified-library.ts";
import {
  MAX_PAG_FILE_BYTES,
  validateAnimationFile,
} from "../lib/animation-format.ts";

function share(
  code: string,
  filename: string,
  createdAt: string,
  status: "active" | "archived" = "active",
) {
  return {
    code,
    filename,
    format: "rive" as const,
    size: 24,
    sha256: "0".repeat(64),
    etag: `"${code}"`,
    isExample: false,
    status,
    createdAt,
    archivedAt: status === "archived" ? createdAt : null,
    commentCount: 0,
  };
}

test("recognizes public share routes at both deployment bases", () => {
  assert.equal(shareCodeFromPath("/A1b", "/"), "A1b");
  assert.equal(shareCodeFromPath("/7XZ/", "/"), "7XZ");
  assert.equal(shareCodeFromPath("/s/A1b", "/"), "A1b");
  assert.equal(shareCodeFromPath("/rive-viewer/7XZ", "/rive-viewer/"), "7XZ");
  assert.equal(shareCodeFromPath("/rive-viewer/s/7XZ", "/rive-viewer/"), "7XZ");
  assert.equal(shareCodeFromPath("/beta/A1b", "/beta/"), "A1b");
  assert.equal(shareCodeFromPath("/s/too-long", "/"), null);
  assert.equal(shareCodeFromPath("/api", "/"), null);
  assert.equal(shareCodeFromPath("/API", "/"), null);
  assert.equal(shareCodeFromPath("/rive-viewer/", "/rive-viewer/"), null);
  assert.equal(hostedSharePath("A1b"), "/A1b");
  assert.equal(hostedSharePath("A1b", "/beta/"), "/beta/A1b");
  assert.throws(() => hostedSharePath("api"), /保留码/);
  assert.throws(() => hostedSharePath("A 1"), /三位 Base62/);
  assert.equal(viewerHomePath("rive-viewer"), "/rive-viewer/");
});

test("recognizes all preview formats and rejects PAG above 10 MiB", () => {
  assert.equal(validateAnimationFile({ name: "motion.riv", size: 4 }), "rive");
  assert.equal(validateAnimationFile({ name: "motion.json", size: 4 }), "lottie");
  assert.equal(validateAnimationFile({ name: "motion.pag", size: MAX_PAG_FILE_BYTES }), "pag");
  assert.throws(
    () => validateAnimationFile({ name: "motion.pag", size: MAX_PAG_FILE_BYTES + 1 }),
    /超过 10 MiB/,
  );
  assert.throws(() => validateAnimationFile({ name: "motion.zip", size: 4 }), /只接受/);
});

test("版本目录默认选中最新版本并兼容单文件数据", () => {
  const legacy = share("A1b", "legacy.riv", "2026-08-26T01:00:00.000Z");
  assert.equal(hostedVersions(legacy).length, 1);
  assert.equal(selectedHostedVersion(legacy)?.filename, "legacy.riv");

  const versioned = {
    ...legacy,
    currentVersionId: "v2",
    versions: [
      { id: "v1", name: "版本 1", filename: "one.riv", format: "rive" as const, size: 4, sha256: "1".repeat(64), etag: "one", createdAt: legacy.createdAt },
      { id: "v2", name: "版本 2", filename: "two.riv", format: "rive" as const, size: 8, sha256: "2".repeat(64), etag: "two", createdAt: "2026-08-26T02:00:00.000Z" },
    ],
  };
  assert.equal(selectedHostedVersion(versioned)?.id, "v2");
  assert.equal(selectedHostedVersion(versioned, "v1")?.filename, "one.riv");
});

test("keeps recently viewed hosted files deduplicated, ordered, and bounded", () => {
  const existing = [
    { id: "hosted-Ab1", hostedCode: "Ab1", name: "旧名称.riv", size: 10, updatedAt: 10 },
    { id: "hosted-XyZ", hostedCode: "XyZ", name: "另一个.riv", size: 12, updatedAt: 20 },
  ];
  const updated = mergeRecentHostedRecords(
    existing,
    { code: "Ab1", filename: "新名称.riv", size: 14 },
    30,
  );
  assert.equal(updated.length, 2);
  assert.deepEqual(updated.map((item) => item.hostedCode), ["Ab1", "XyZ"]);
  assert.equal(updated[0].name, "新名称.riv");
  assert.equal(updated[0].updatedAt, 30);

  const preserved = mergeRecentHostedRecords(
    updated,
    { code: "XyZ", filename: "更新名称.riv", size: 18 },
    50,
    20,
    true,
  );
  assert.deepEqual(preserved.map((item) => item.hostedCode), ["Ab1", "XyZ"]);
  assert.equal(preserved[1].name, "更新名称.riv");
  assert.equal(preserved[1].updatedAt, 20);

  const bounded = mergeRecentHostedRecords(
    updated,
    { code: "Q2w", filename: "第三个.riv", size: 16 },
    40,
    2,
  );
  assert.deepEqual(bounded.map((item) => item.hostedCode), ["Q2w", "Ab1"]);
});

test("merges local, recent, and active hosted files into one activity-sorted list", () => {
  const local = { id: "local-one", name: "同名.riv", size: 24, format: "rive" as const, updatedAt: 200 };
  const recent = {
    id: "hosted-Ab1",
    hostedCode: "Ab1",
    name: "同名.riv",
    size: 24,
    format: "rive" as const,
    updatedAt: 300,
  };
  const otherRecent = {
    id: "hosted-Xy2",
    hostedCode: "Xy2",
    name: "同名.riv",
    size: 24,
    format: "rive" as const,
    updatedAt: 100,
  };
  const items = mergeUnifiedFiles(
    [local, recent, otherRecent],
    [
      share("Ab1", "同名.riv", "1970-01-01T00:00:00.150Z"),
      share("Xy2", "同名.riv", "1970-01-01T00:00:00.100Z"),
    ],
    [],
    { "local-one": "Ab1" },
  );

  assert.deepEqual(items.map((item) => item.hostedCode), ["Ab1", "Xy2"]);
  assert.equal(items[0].localFile?.id, "local-one");
  assert.equal(items[0].activityAt, 300);
  assert.equal(items[1].file.name, "同名.riv");
});

test("keeps a known published code ready during refresh and removes archived shares from active rows", () => {
  const local = { id: "local-one", name: "local.riv", size: 24, format: "rive" as const, updatedAt: 200 };
  const publishedWithoutFreshList = mergeUnifiedFiles([local], [], [], { "local-one": "A1b" });
  assert.equal(publishedWithoutFreshList[0].hostedCode, "A1b");

  const archived = share("A1b", "local.riv", "2026-08-22T00:00:00.000Z", "archived");
  const afterArchive = mergeUnifiedFiles(
    [local, { id: "hosted-A1b", hostedCode: "A1b", name: "local.riv", size: 24, format: "rive" as const, updatedAt: 300 }],
    [],
    [archived],
    { "local-one": "A1b" },
  );
  assert.equal(afterArchive.length, 1);
  assert.equal(afterArchive[0].localFile?.id, "local-one");
  assert.equal(afterArchive[0].hostedCode, undefined);
});

test("streams hosted file bytes with honest download progress", async () => {
  const originalFetch = globalThis.fetch;
  const progress: number[] = [];
  try {
    globalThis.fetch = async () => new Response(new ReadableStream<Uint8Array>({
      start(controller) {
        controller.enqueue(new Uint8Array([1, 2]));
        controller.enqueue(new Uint8Array([3, 4]));
        controller.close();
      },
    }), { headers: { "Content-Length": "4" } });

    const data = await getHostedFile("A1b", {
      expectedBytes: 4,
      onProgress: (percent) => progress.push(percent),
    });
    assert.deepEqual(Array.from(new Uint8Array(data)), [1, 2, 3, 4]);
    assert.deepEqual(progress, [0, 50, 99, 100]);

    globalThis.fetch = async () => new Response(new Uint8Array([1, 2]), {
      headers: { "Content-Length": "2" },
    });
    await assert.rejects(
      getHostedFile("A1b", { expectedBytes: 4 }),
      (error) => error instanceof HostedApiError && error.code === "download_incomplete",
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("reads the assigned identity and submits local comment customization", async () => {
  const originalFetch = globalThis.fetch;
  let requestUrl = "";
  let requestInit: RequestInit | undefined;
  try {
    globalThis.fetch = async (input, init) => {
      requestUrl = String(input);
      requestInit = init;
      if (requestUrl.includes("comment-identity")) {
        return new Response(JSON.stringify({
          item: { nickname: "松果松鼠", avatar: "pinecone-squirrel" },
        }), { headers: { "Content-Type": "application/json" } });
      }
      return new Response(JSON.stringify({
        item: {
          id: "comment-1",
          nickname: "杨总的松鼠",
          avatar: "pinecone-squirrel",
          avatarDataUrl: "data:image/webp;base64,AAAA",
          body: "按钮可以再大一点，杨皓棱",
          createdAt: "2026-08-24T04:00:00.000Z",
          status: "active",
          archivedAt: null,
        },
      }), {
        status: 201,
        headers: { "Content-Type": "application/json" },
      });
    };

    const identity = await getHostedCommentIdentity("visitor-stable-forest-0001");
    assert.equal(requestUrl, "/api/v1/comment-identity?visitorId=visitor-stable-forest-0001");
    assert.deepEqual(identity, { nickname: "松果松鼠", avatar: "pinecone-squirrel" });

    const comment = await createHostedComment("A1b", {
      visitorId: "visitor-stable-forest-0001",
      body: "按钮可以再大一点，杨皓棱",
      nickname: "杨总的松鼠",
      avatarDataUrl: "data:image/webp;base64,AAAA",
    });

    assert.equal(requestUrl, "/api/v1/shares/A1b/comments");
    assert.equal(requestInit?.method, "POST");
    assert.deepEqual(JSON.parse(String(requestInit?.body)), {
      visitorId: "visitor-stable-forest-0001",
      body: "按钮可以再大一点，杨皓棱",
      nickname: "杨总的松鼠",
      avatarDataUrl: "data:image/webp;base64,AAAA",
    });
    assert.equal(comment.nickname, "杨总的松鼠");
    assert.equal(comment.avatar, "pinecone-squirrel");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("昵称以 Unicode 字符限制为 12 个", () => {
  assert.equal(
    limitCommentNickname("一二三四五六七八九十✨🐿多余"),
    "一二三四五六七八九十✨🐿",
  );
});

test("keeps hosted API and file upload contracts explicit", async () => {
  const [apiSource, appSource, mainSource, panelSource, styleSource, clipboardSource, identitySource] = await Promise.all([
    readFile(new URL("../lib/hosted-api.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
    readFile(new URL("../static/main.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/HostedPanels.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../lib/clipboard.ts", import.meta.url), "utf8"),
    readFile(new URL("../lib/comment-identity.ts", import.meta.url), "utf8"),
  ]);

  assert.match(apiSource, /const API_ROOT = "\/api\/v1"/);
  assert.match(apiSource, /setRequestHeader\("X-Animation-Filename", encodeURIComponent\(filename\)\)/);
  assert.doesNotMatch(apiSource, /X-Rive-Example/);
  assert.match(apiSource, /request\.send\(data\)/);
  assert.match(apiSource, /new XMLHttpRequest\(\)/);
  assert.match(apiSource, /request\.upload\.onprogress/);
  assert.match(apiSource, /request\.timeout = 120_000/);
  assert.match(apiSource, /RESPONSE_TIMEOUT_MS = 20_000/);
  assert.match(apiSource, /DOWNLOAD_STALL_TIMEOUT_MS = 30_000/);
  assert.match(apiSource, /response\.body\.getReader\(\)/);
  assert.match(apiSource, /download_incomplete/);
  assert.match(apiSource, /\/shares\?status=/);
  assert.match(apiSource, /\/comments/);
  assert.match(apiSource, /updateHostedCommentStatus/);
  assert.match(apiSource, /"archive" \| "restore"/);
  assert.match(apiSource, /"X-Rive-Action": action/);
  assert.match(appSource, /PUBLISHED_CODES_STORAGE_KEY/);
  assert.doesNotMatch(appSource, /PublishConfirmDialog/);
  assert.match(appSource, /getHostedFile\(share\.code/);
  assert.match(appSource, /expectedBytes: openedSize/);
  assert.match(appSource, /onProgress: \(progress\)/);
  assert.match(appSource, /setPublicShareState\("ready"\);[\s\S]{0,100}if \(!share\.isExample\)/);
  assert.match(appSource, /if \(!shareCode \|\| publicShare\?\.status !== "active"\) return/);
  assert.match(appSource, /visitorId: getCommentVisitorId\(\)/);
  assert.match(appSource, /archiveHostedComment\(targetCode, comment\.id\)/);
  assert.match(appSource, /restoreHostedComment\(targetCode, comment\.id\)/);
  assert.match(appSource, /hostedShare: share/);
  assert.match(appSource, /rememberRecentHostedFile\(/);
  assert.match(appSource, /if \(!share\.isExample\)/);
  assert.match(appSource, /aria-label="返回文件列表"/);
  assert.match(appSource, /document\.querySelector\('\[aria-modal="true"\]'\)/);
  assert.match(appSource, /onDragEnter=\{enterDropTarget\}/);
  assert.match(appSource, /onDrop=\{dropFiles\}/);
  assert.match(appSource, /<PreviewFileRail/);
  assert.match(appSource, /<FileUploadDetail/);
  assert.match(appSource, /Record<string, FileUploadState>/);
  assert.doesNotMatch(appSource, /<CloudUploadStatusBar/);
  assert.match(appSource, /phase: "uploading"/);
  assert.match(appSource, /openPromise = openFile\(savedFile\)/);
  assert.match(appSource, /Promise\.all\(\[openPromise, refreshLibrary\(\), uploadPromise\]\)/);
  assert.match(appSource, /window\.history\.replaceState/);
  assert.match(appSource, /支持 Rive \/ Lottie \/ PAG，PAG 不超过 10 MiB/);
  assert.match(appSource, /const activeHostedCode = isHostedPlatform && activeFile/);
  assert.match(appSource, /activeFile\.hostedShare\?\.code/);
  assert.match(appSource, /uploadStates\[activeFile\.file\.id\]\?\.share\?\.code/);
  assert.match(appSource, /publishedCodes\[activeFile\.file\.id\]/);
  assert.match(appSource, /type ActivityPolicy = "record" \| "preserve"/);
  assert.match(appSource, /RAIL_ACTIVITY_STATE_KEY = "riveRailPreserveActivity"/);
  assert.match(appSource, /openUnifiedFile\(item, "preserve"\)/);
  assert.match(appSource, /openUnifiedFile\(next, "preserve"\)/);
  assert.match(appSource, /type CommentThreadState = \{[\s\S]{0,120}code: string \| null;[\s\S]{0,120}items: HostedComment\[\]/);
  assert.match(appSource, /if \(isHostedPlatform && item\.hostedCode\) \{[\s\S]{0,120}navigateHostedShare\(item\.hostedCode, activityPolicy\)/);
  assert.match(appSource, /if \(current\.code !== targetCode\) return current/);
  assert.equal((appSource.match(/"复制当前文件链接"/g) || []).length, 2);
  assert.match(appSource, /copyActiveHostedLink/);
  assert.match(appSource, /copyText\(hostedShareUrl\(code, import\.meta\.env\.BASE_URL\)\)/);
  assert.match(appSource, /detailCopyFeedback/);
  assert.match(appSource, /detailCopyIcon/);
  assert.match(appSource, /"check"/);
  assert.match(appSource, /"已复制"/);
  assert.match(appSource, /isHostedPlatform \? "contain" : "cover"/);
  assert.match(appSource, /className="topbar-action-label">下载/);
  assert.doesNotMatch(appSource, /detailShareCode/);
  assert.equal((appSource.match(/<ShareActionsDialog/g) || []).length, 1);
  assert.match(appSource, /className="brand-signature">for JOJO/);
  assert.match(appSource, /反馈意见：杨皓棱/);
  assert.doesNotMatch(appSource, /AUTHOR_WECHAT|联系作者反馈意见/);
  assert.match(appSource, /className="archived-library-trigger press-feedback"/);
  assert.match(appSource, /className="archived-library-count"/);
  assert.match(appSource, /aria-controls="archived-library-dialog"/);
  assert.match(appSource, /<ArchivedLibraryDialog/);
  assert.doesNotMatch(appSource, /<ArchivedLibrarySection/);
  assert.match(mainSource, /\["\/", "\/beta\/"\]\.includes\(import\.meta\.env\.BASE_URL\) \? "hosted" : "local"/);
  assert.match(mainSource, /mode === "hosted"/);
  assert.match(panelSource, /已归档文件/);
  assert.match(panelSource, /复制 .*公开链接/);
  assert.match(panelSource, /export function ArchivedLibraryDialog/);
  assert.match(panelSource, /id="archived-library-dialog"/);
  assert.match(panelSource, /aria-modal="true"/);
  assert.match(panelSource, /event\.key === "Escape"/);
  assert.match(panelSource, /export function ShareActionsDialog/);
  assert.match(panelSource, /copyText\(url\)/);
  assert.match(panelSource, /await onDownload\(\)/);
  assert.match(panelSource, /aria-label="复制公开链接"/);
  assert.match(panelSource, /className="public-download-progress"/);
  assert.match(appSource, /createHostedVersion/);
  assert.doesNotMatch(appSource, /className="file-version-(?:menu|trigger|picker)"/);
  assert.match(appSource, /onSelectVersion=\{selectHostedVersion\}/);
  assert.match(appSource, /className="file-heading-version-update press-feedback"/);
  assert.match(appSource, /"上传新版本"/);
  assert.match(appSource, /const hostedVersioningEnabled = isHostedPlatform;/);
  assert.match(appSource, /listHostedShares\("active", undefined, hostedVersioningEnabled \? \["rive", "lottie", "pag"\]/);
  assert.doesNotMatch(appSource, /isBetaVersioning/);
  assert.match(appSource, /subtleSelected selected=\{quality === 1\}/);
  assert.match(panelSource, /className="comment-version-heading"/);
  assert.match(panelSource, /loadError \? null : versions\.length > 1/);
  assert.match(styleSource, /\.file-heading-version-update\s*\{[\s\S]{0,180}min-width:\s*118px/);
  assert.match(styleSource, /\.parameter-tag\.is-selected\.is-subtle-selected\s*\{[\s\S]{0,160}border-color:\s*#735f26/);
  assert.match(panelSource, /role={kind === "error" \? "alert" : "status"}/);
  const commentPanelSource = panelSource.slice(
    panelSource.indexOf("function CommentList"),
    panelSource.indexOf("export function PublicShareState"),
  );
  assert.equal((commentPanelSource.match(/className="comment-editor"/g) || []).length, 1);
  assert.match(commentPanelSource, /contentEditable=\{!submitting\}/);
  assert.doesNotMatch(commentPanelSource, /<textarea/);
  assert.match(commentPanelSource, /className="comment-identity-row"/);
  assert.match(commentPanelSource, /accept="image\/\*"/);
  assert.match(commentPanelSource, /COMMENT_NICKNAME_LIMIT/);
  assert.match(commentPanelSource, /compressCommentAvatar/);
  assert.match(commentPanelSource, /\{!draftBody && <TimelineHint \/>\}/);
  assert.doesNotMatch(commentPanelSource, /placeholder="写下评论或备注"/);
  assert.match(panelSource, /commentAvatarUrl\(comment\)/);
  assert.match(panelSource, /width="32"/);
  assert.match(commentPanelSource, /评论已归档/);
  assert.match(commentPanelSource, /onArchive\(comment\)/);
  assert.match(commentPanelSource, /onRestore\(comment\)/);
  assert.match(commentPanelSource, /loadError \? null : versions\.length/);
  assert.doesNotMatch(commentPanelSource, /comments-share-card/);
  assert.equal((appSource.match(/className="public-comments-inline"/g) || []).length, 1);
  assert.match(
    appSource,
    /<RuntimeEventConsole log=\{runtimeEventLog\} \/>[\s\S]{0,240}className="public-comments-inline"/,
  );
  assert.match(appSource, /commentSubmitBusyRef\.current/);
  assert.match(panelSource, />分享文件</);
  assert.match(panelSource, />下载</);
  assert.match(styleSource, /\.import-dropzone\.is-dragging/);
  assert.match(styleSource, /\.file-upload-progress/);
  assert.match(styleSource, /\.preview-file-add[\s\S]{0,260}color:\s*var\(--text\);[\s\S]{0,80}background:\s*var\(--control\)/);
  assert.match(styleSource, /\.preview-file-rail-row\.is-current::before/);
  assert.match(styleSource, /\.archived-library-trigger \.archived-library-count[\s\S]{0,320}background:\s*transparent/);
  assert.match(styleSource, /\.topbar-copy-link\.is-copied,[\s\S]{0,240}background:\s*var\(--control\)/);
  assert.doesNotMatch(styleSource, /#f6d76b/);
  assert.match(styleSource, /\.public-download-progress/);
  assert.match(styleSource, /var\(--preview-file-rail-width, 184px\)/);
  assert.match(styleSource, /grid-template-columns:\s*40px minmax\(0, 1fr\) max-content/);
  assert.match(styleSource, /\.file-heading-copy-link[\s\S]{0,520}background:\s*var\(--accent\)/);
  assert.match(styleSource, /\.topbar-copy-link[\s\S]{0,220}min-width:\s*122px/);
  assert.match(styleSource, /\.topbar-download > \.topbar-action-label/);
  assert.doesNotMatch(styleSource, /\.topbar-download > span/);
  assert.match(styleSource, /\.archived-library-dialog[\s\S]{0,420}max-height:\s*calc\(100dvh - 40px\)/);
  assert.match(styleSource, /\.archived-dialog-body[\s\S]{0,220}overflow-y:\s*auto/);
  assert.match(styleSource, /\.brand-signature/);
  assert.match(styleSource, /\.feedback-credit/);
  assert.match(styleSource, /\.share-action-stack[\s\S]{0,120}display:\s*grid/);
  assert.match(styleSource, /\.share-link-value[\s\S]{0,220}overflow-wrap:\s*anywhere/);
  assert.match(styleSource, /@media \(any-hover: hover\) and \(any-pointer: fine\)/);
  assert.match(styleSource, /textarea:focus-visible/);
  assert.match(styleSource, /\.comment-author img[\s\S]{0,180}width:\s*32px[\s\S]{0,80}height:\s*32px[\s\S]{0,100}border-radius:\s*50%[\s\S]{0,80}object-fit:\s*cover/);
  assert.match(styleSource, /\.comment-item-archived summary/);
  assert.match(styleSource, /@media \(max-width: 520px\)[\s\S]*\.comment-editor[\s\S]*font-size:\s*16px/);
  assert.match(clipboardSource, /navigator\.clipboard\?\.writeText/);
  assert.match(clipboardSource, /document\.execCommand\("copy"\)/);
  assert.match(identitySource, /rive-host-comment-visitor-v1/);
  assert.match(identitySource, /window\.localStorage\.getItem/);
  assert.match(identitySource, /window\.localStorage\.setItem/);
  assert.match(identitySource, /COMMENT_AVATAR_EDGE = 64/);
  assert.match(identitySource, /canvas\.toBlob/);
  assert.match(identitySource, /"image\/webp"/);
  assert.doesNotMatch(identitySource, /navigator\.|screen\.|fingerprint/i);
});

test("resolves static assets from Vite's configured public base", async () => {
  const [viteSource, html, playerSource, librarySource, iconSource] = await Promise.all([
    readFile(new URL("../vite.config.ts", import.meta.url), "utf8"),
    readFile(new URL("../static/index.html", import.meta.url), "utf8"),
    readFile(new URL("../lib/rive-player.ts", import.meta.url), "utf8"),
    readFile(new URL("../lib/library.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/Icon.tsx", import.meta.url), "utf8"),
  ]);

  assert.match(viteSource, /process\.env\.RIVE_VIEWER_BASE/);
  assert.match(html, /%BASE_URL%favicon\.webp\?v=3/);
  assert.match(html, /rel="apple-touch-icon" sizes="180x180" href="%BASE_URL%apple-touch-icon\.png\?v=3"/);
  assert.doesNotMatch(html, /\.wasm/);
  assert.match(playerSource, /publicAssetUrl\(runtimeWasmFile\(renderEngine\)\)/);
  assert.match(librarySource, /RECENT_HOSTED_STORE_NAME = "recent-hosted"/);
  assert.match(iconSource, /publicAssetUrl\(`icons\/\$\{name\}\.svg`\)/);
  const avatarFiles = (await readdir(new URL("../public/rive-viewer/avatars", import.meta.url)))
    .filter((name) => name.endsWith(".webp"));
  assert.equal(avatarFiles.length, 32);
});

test("uses a bounded custom speed menu instead of a native select", async () => {
  const [styleSource, appSource] = await Promise.all([
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
  ]);
  const speedRules = styleSource.slice(
    styleSource.indexOf(".speed-menu"),
    styleSource.indexOf(".fit-group"),
  );

  assert.match(speedRules, /overflow:\s*hidden/);
  assert.match(speedRules, /\.speed-menu \.speed-gauge\s*\{[\s\S]*width:\s*18px/);
  assert.match(speedRules, /\.speed-menu \.speed-gauge\s*\{[\s\S]*height:\s*18px/);
  assert.match(speedRules, /transform:\s*none/);
  assert.match(appSource, /className="speed-menu-popover" role="listbox"/);
  assert.match(appSource, /role="option"/);
  assert.doesNotMatch(appSource, /<select value=\{speed\}/);
});

test("defaults local previews to high quality while hosted previews stay balanced", async () => {
  const [appSource, playerSource] = await Promise.all([
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
    readFile(new URL("../lib/rive-player.ts", import.meta.url), "utf8"),
  ]);
  const playerCreation = appSource.slice(
    appSource.indexOf("player = await createAnimationPlayer"),
    appSource.indexOf("await player.load(sourceData)"),
  );

  assert.match(appSource, /const DEFAULT_RENDER_QUALITY = 2;/);
  assert.match(appSource, /const DEFAULT_HOSTED_RENDER_QUALITY = 1;/);
  assert.match(appSource, /isHostedPlatform \? DEFAULT_HOSTED_RENDER_QUALITY : DEFAULT_RENDER_QUALITY/);
  assert.match(playerCreation, /player\.setQuality\(qualityRef\.current\);/);
  assert.match(playerSource, /safetyPixelRatio = this\.complexFile \? 1\.25 : 2;/);
  assert.match(playerSource, /safetyFps = this\.complexFile \? 30 : 60;/);
});


test("uses each uploaded version name until a custom name is saved", () => {
  const original = share("Nm0", "最新文件.riv", "2026-09-09T00:00:00.000Z");
  const oldVersion = { filename: "原始文件.riv" };
  assert.equal(hostedShareName(original), "最新文件.riv");
  assert.equal(hostedShareName(original, oldVersion), "原始文件.riv");
  const renamed = { ...original, customName: "叫叫欢迎动画" };
  assert.equal(hostedShareName(renamed), "叫叫欢迎动画");
  assert.equal(hostedShareName(renamed, oldVersion), "叫叫欢迎动画");
});

test("fresh hosted names override stale local and recent names without losing covers or activity", () => {
  const current = share("Nm0", "新版.riv", "2026-09-09T00:00:00.000Z");
  const cover = new Blob(["cover"]);
  const local = { id: "local-one", name: "旧文件.riv", size: 24, format: "rive" as const, updatedAt: 9999999999999, cover };
  const recent = { ...local, id: "hosted-Nm0", hostedCode: "Nm0", updatedAt: 200 };
  for (const hosted of [current, { ...current, customName: "自定义名称" }]) {
    const [item] = mergeUnifiedFiles([local, recent], [hosted], [], { "local-one": "Nm0" });
    assert.equal(item.file.name, hostedShareName(hosted));
    assert.equal(item.file.cover, cover);
    assert.equal(item.localFile, local);
    assert.equal(item.activityAt, local.updatedAt);
    const [stored] = mergeRecentHostedRecords([recent], hosted, 300, 20, true);
    assert.equal(stored.name, hostedShareName(hosted));
    assert.equal(stored.updatedAt, 200);
  }
});
