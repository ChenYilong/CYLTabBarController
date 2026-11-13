"use client";

import type {
  ChangeEvent,
  CSSProperties,
  DragEvent as ReactDragEvent,
  MouseEvent as ReactMouseEvent,
  PointerEvent as ReactPointerEvent,
} from "react";
import { useCallback, useEffect, useId, useLayoutEffect, useMemo, useRef, useState } from "react";
import policy from "../../../shared/rive-policy.json";
import {
  animationFormatLabel,
  SUPPORTED_ANIMATION_ACCEPT,
  validateAnimationFile,
  type AnimationFormat,
} from "../../lib/animation-format";
import type {
  AnimationInput,
  AnimationMetadata,
  AnimationPlayer,
} from "../../lib/animation-player";
import {
  archiveHostedComment,
  archiveHostedShare,
  createHostedComment,
  createHostedShare,
  createHostedVersion,
  getHostedFile,
  getHostedShare,
  hostedFileUrl,
  HostedApiError,
  listHostedComments,
  listHostedShares,
  renameHostedShare,
  restoreHostedComment,
  restoreHostedShare,
  type HostedComment,
  type HostedCommentAuthorInput,
  type HostedShare,
} from "../../lib/hosted-api";
import {
  hostedVersions,
  selectedHostedVersion,
} from "../../lib/file-versions";
import { ActionTooltip } from "./ActionTooltip";
import { fileShortcutModifier, getFileShortcut } from "../../lib/file-shortcuts";
import { copyText } from "../../lib/clipboard";
import { hostedShareName } from "../../lib/hosted-share-name";
import { getCommentVisitorId } from "../../lib/comment-identity";
import {
  attachLibraryCovers,
  formatBytes,
  formatDate,
  listLocalFiles,
  listRecentHostedFiles,
  readLibraryFile,
  rememberRecentHostedFile,
  saveLocalFile,
  saveLibraryCover,
  touchLocalFile,
  type LibraryFile,
} from "../../lib/library";
import type { RenderEngine } from "../../lib/rive-player";
import { PlaybackTelemetry } from "../../lib/playback-telemetry";
import { publicAssetUrl } from "../../lib/public-base";
import { RuntimeEventLog } from "../../lib/runtime-event-log";
import { mergeUnifiedFiles, type UnifiedFileItem } from "../../lib/unified-library";
import {
  hostedSharePath,
  hostedShareUrl,
  shareCodeFromPath,
  viewerHomePath,
} from "../../lib/viewer-route";
import {
  ArchiveConfirmDialog,
  ArchivedLibraryDialog,
  PublicShareState,
  ShareActionsDialog,
  ShareCommentsPanel,
} from "./HostedPanels";
import { Icon, type IconName } from "./Icon";
import { FileContextMenu, FileMenuActions, type FileActionsProps, type FileContextTarget } from "./FileActionsMenu";
import { HostedFileName } from "./HostedFileName";
import { PlaybackMeta, TimelineControl } from "./PlaybackTelemetryView";
import { RuntimeEventConsole } from "./RuntimeEventConsole";

type ActiveFile = {
  file: LibraryFile;
  sessionId: number;
  hostedShare?: HostedShare;
};

type LoadingState = {
  active: boolean;
  progress: number;
  phase: string;
};

const EMPTY_METADATA: AnimationMetadata = {
  artboardNames: [],
  artboardCount: 0,
  artboardCatalogLoaded: false,
  activeArtboard: "",
  stateMachines: [],
  activeStateMachine: "",
  animations: [],
  activeAnimation: "",
  inputs: [],
  width: 0,
  height: 0,
  hasAudio: false,
  audioEnabled: true,
};

const SPEEDS = policy.speeds;
const CANVAS_TONES = policy.canvasTones;
const DEFAULT_RENDER_QUALITY = 2;
const DEFAULT_HOSTED_RENDER_QUALITY = 1;
const PUBLISHED_CODES_STORAGE_KEY = "rive-host-published-codes-v1";
const FILE_RAIL_MIN_WIDTH = 160;
const FILE_RAIL_DEFAULT_WIDTH = 184;
const FILE_RAIL_MAX_WIDTH = 360;
const FILE_RAIL_PREVIEW_MIN_WIDTH = 620;
const WIDE_INSPECTOR_MIN_WIDTH = 360;
const WIDE_INSPECTOR_DEFAULT_WIDTH = 360;
const WIDE_INSPECTOR_FALLBACK_MAX_WIDTH = 680;
const WIDE_PREVIEW_MIN_WIDTH = 520;
const WIDE_PREVIEW_PREFERRED_WIDTH = 800;
const WIDE_COLUMN_RESIZER_WIDTH = 13;
const WIDE_LAYOUT_MIN_WIDTH = 1194;
const STAGE_MIN_HEIGHT = 50;
const RAIL_ACTIVITY_STATE_KEY = "riveRailPreserveActivity";

type ActivityPolicy = "record" | "preserve";

type FileUploadPhase = "local" | "uploading" | "ready" | "error";

type FileUploadState = {
  phase: FileUploadPhase;
  progress: number;
  error: string;
  retryable: boolean;
  share?: HostedShare;
  updatedAt: number;
};

type DetailCopyFeedback = {
  code: string;
  status: "copied" | "error";
};

function uploadStateForItem(
  item: UnifiedFileItem,
  uploadStates: Record<string, FileUploadState>,
): FileUploadState {
  const localState = item.localFile ? uploadStates[item.localFile.id] : undefined;
  if (localState) return localState;
  if (item.hostedCode) {
    return {
      phase: "ready",
      progress: 100,
      error: "",
      retryable: false,
      share: item.share,
      updatedAt: item.activityAt,
    };
  }
  return {
    phase: "local",
    progress: 0,
    error: "",
    retryable: false,
    updatedAt: item.activityAt,
  };
}

function readPublishedCodes(): Record<string, string> {
  if (typeof window === "undefined") return {};
  try {
    const value = JSON.parse(window.localStorage.getItem(PUBLISHED_CODES_STORAGE_KEY) || "{}");
    if (!value || typeof value !== "object" || Array.isArray(value)) return {};
    return Object.fromEntries(Object.entries(value).filter((entry): entry is [string, string] => (
      typeof entry[1] === "string" && /^[0-9A-Za-z]{3}$/.test(entry[1])
    )));
  } catch {
    return {};
  }
}

function historyStateRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function hasRailActivityMarker(code: string | null): boolean {
  if (!code || typeof window === "undefined") return false;
  const current = historyStateRecord(window.history.state);
  return current[RAIL_ACTIVITY_STATE_KEY] === code;
}

function clearRailActivityMarker(code: string | null): void {
  if (!code || typeof window === "undefined") return;
  const current = historyStateRecord(window.history.state);
  if (current[RAIL_ACTIVITY_STATE_KEY] !== code) return;
  const next = { ...current };
  delete next[RAIL_ACTIVITY_STATE_KEY];
  window.history.replaceState(Object.keys(next).length ? next : null, "", window.location.href);
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}

function errorMessage(value: unknown, fallback: string): string {
  return value instanceof Error ? value.message : fallback;
}

type HostedLibraryState = {
  activeItems: HostedShare[];
  archivedItems: HostedShare[];
  loading: boolean;
  error: string;
};

type PublicShareStateName = "idle" | "loading" | "ready" | "archived" | "error";
type CommentThreadState = {
  code: string | null;
  items: HostedComment[];
};
export type ViewerMode = "hosted" | "local";

export function RiveViewerApp({
  mode,
  shareCode: initialShareCode,
}: {
  mode: ViewerMode;
  shareCode: string | null;
}) {
  const isHostedPlatform = mode === "hosted";
  const hostedVersioningEnabled = isHostedPlatform;
  const [shareCode, setShareCode] = useState(initialShareCode);
  const [preservePublicActivity, setPreservePublicActivity] = useState(
    () => hasRailActivityMarker(initialShareCode),
  );
  const [files, setFiles] = useState<LibraryFile[]>([]);
  const [expandedFileId, setExpandedFileId] = useState("");
  const [activeFile, setActiveFile] = useState<ActiveFile | null>(null);
  const [metadata, setMetadata] = useState<AnimationMetadata>(EMPTY_METADATA);
  const [loading, setLoading] = useState<LoadingState>({
    active: false,
    progress: 0,
    phase: "正在准备文件",
  });
  const [error, setError] = useState("");
  const [playing, setPlaying] = useState(true);
  const [speed, setSpeed] = useState(1);
  const [fit, setFit] = useState<"contain" | "cover">(() => (
    isHostedPlatform ? "contain" : "cover"
  ));
  const [quality, setQuality] = useState(
    isHostedPlatform ? DEFAULT_HOSTED_RENDER_QUALITY : DEFAULT_RENDER_QUALITY,
  );
  const [renderEngine, setRenderEngine] = useState<RenderEngine>("webgl2");
  const [canvasGeneration, setCanvasGeneration] = useState(0);
  const [engineToast, setEngineToast] = useState("");
  const [canvasTone, setCanvasTone] = useState("mist");
  const [stageHeight, setStageHeight] = useState(460);
  const [stageHeightCustomized, setStageHeightCustomized] = useState(false);
  const [draggingStage, setDraggingStage] = useState(false);
  const [inspectorWidth, setInspectorWidth] = useState(WIDE_INSPECTOR_DEFAULT_WIDTH);
  const [inspectorWidthMaximum, setInspectorWidthMaximum] = useState(WIDE_INSPECTOR_FALLBACK_MAX_WIDTH);
  const [inspectorWidthCustomized, setInspectorWidthCustomized] = useState(false);
  const [draggingInspector, setDraggingInspector] = useState(false);
  const [stageResizeMenuActive, setStageResizeMenuActive] = useState(false);
  const [stageResizeTapOpen, setStageResizeTapOpen] = useState(false);
  const [stageResizePressActive, setStageResizePressActive] = useState(false);
  const [stageResizeHoverFit, setStageResizeHoverFit] = useState<"contain" | "cover" | "">("");
  const [catalogLoading, setCatalogLoading] = useState(false);
  const [catalogProgress, setCatalogProgress] = useState(0);
  const [hostedLibrary, setHostedLibrary] = useState<HostedLibraryState>({
    activeItems: [],
    archivedItems: [],
    loading: false,
    error: "",
  });
  const [hostingError, setHostingError] = useState("");
  const [dropActive, setDropActive] = useState(false);
  const [importBusy, setImportBusy] = useState(false);
  const [importError, setImportError] = useState("");
  const [uploadStates, setUploadStates] = useState<Record<string, FileUploadState>>({});
  const [pendingArchiveShare, setPendingArchiveShare] = useState<HostedShare | null>(null);
  const [archivedDialogOpen, setArchivedDialogOpen] = useState(false);
  const [publishedCodes, setPublishedCodes] = useState<Record<string, string>>(readPublishedCodes);
  const [publishedShare, setPublishedShare] = useState<HostedShare | null>(null);
  const [detailCopyFeedback, setDetailCopyFeedback] = useState<DetailCopyFeedback | null>(null);
  const [hostedBusyCode, setHostedBusyCode] = useState("");
  const [publicShare, setPublicShare] = useState<HostedShare | null>(null);
  const [publicShareState, setPublicShareState] = useState<PublicShareStateName>(
    shareCode ? "loading" : "idle",
  );
  const [publicShareError, setPublicShareError] = useState("");
  const [publicShareReload, setPublicShareReload] = useState(0);
  const [selectedVersionId, setSelectedVersionId] = useState("");
  const [versionUploading, setVersionUploading] = useState(false);
  const [versionUploadProgress, setVersionUploadProgress] = useState(0);
  const [versionUploadError, setVersionUploadError] = useState("");
  const [commentThread, setCommentThread] = useState<CommentThreadState>({
    code: shareCode,
    items: [],
  });
  const [commentsLoading, setCommentsLoading] = useState(false);
  const [commentsLoadError, setCommentsLoadError] = useState("");
  const [commentSubmitError, setCommentSubmitError] = useState("");
  const [commentSubmitting, setCommentSubmitting] = useState(false);
  const [commentActionBusyId, setCommentActionBusyId] = useState("");
  const [commentActionError, setCommentActionError] = useState("");
  const [commentsReload, setCommentsReload] = useState(0);
  const [commentTimelineInsertion, setCommentTimelineInsertion] = useState<{ id: number; name: string } | null>(null);
  const [publicRouteDetached, setPublicRouteDetached] = useState(false);
  const comments = commentThread.code === shareCode ? commentThread.items : [];
  const telemetry = useMemo(() => new PlaybackTelemetry(), []);
  const runtimeEventLog = useMemo(() => new RuntimeEventLog(), []);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const versionInputRef = useRef<HTMLInputElement>(null);
  const versionTargetRef = useRef<{ code: string; format: AnimationFormat } | null>(null);
  const [fileContextTarget, setFileContextTarget] = useState<FileContextTarget | null>(null);
  const closeFileContextMenu = useCallback(() => setFileContextTarget(null), []);
  const openFileContextMenu = (event: ReactMouseEvent<HTMLElement>, item: UnifiedFileItem) => {
    if (!isHostedPlatform) return;
    event.preventDefault();
    setExpandedFileId("");
    setFileContextTarget({ item, x: event.clientX, y: event.clientY, trigger: event.currentTarget });
  };
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const lottieContainerRef = useRef<HTMLDivElement>(null);
  const stageRef = useRef<HTMLDivElement>(null);
  const previewWorkbenchRef = useRef<HTMLDivElement>(null);
  const previewInspectorRef = useRef<HTMLElement>(null);
  const previewColumnResizerRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<AnimationPlayer | null>(null);
  const activeSourceRef = useRef<{ sessionId: number; data: ArrayBuffer } | null>(null);
  const openRequestRef = useRef(0);
  const pendingStageHeightRef = useRef<number | null>(null);
  const stageResizeFrameRef = useRef<number | null>(null);
  const pendingPlayerSizeRef = useRef<{ width: number; height: number } | null>(null);
  const resizeStartRef = useRef({ x: 0, y: 0, height: 0 });
  const draggingStageRef = useRef(false);
  const inspectorResizeStartRef = useRef({ x: 0, width: WIDE_INSPECTOR_DEFAULT_WIDTH });
  const pendingInspectorWidthRef = useRef<number | null>(null);
  const inspectorResizeFrameRef = useRef<number | null>(null);
  const currentInspectorWidthRef = useRef(WIDE_INSPECTOR_DEFAULT_WIDTH);
  const draggingInspectorRef = useRef(false);
  const stageResizeMovedRef = useRef(false);
  const stageResizeStartedOpenRef = useRef(false);
  const stageResizeLongPressTimerRef = useRef<number | null>(null);
  const stageResizeMenuDismissTimerRef = useRef<number | null>(null);
  const lastStageTapRef = useRef(0);
  const speedRef = useRef(speed);
  const fitRef = useRef(fit);
  const qualityRef = useRef(quality);
  const renderEngineRef = useRef<RenderEngine>("webgl2");
  const engineFallbackBusyRef = useRef(false);
  const reloadActiveFileRef = useRef<() => void>(() => {});
  const capturedCoverIdsRef = useRef(new Set<string>());
  const cloudUploadBusyRef = useRef(false);
  const commentSubmitBusyRef = useRef(false);
  const commentTimelineInsertionIdRef = useRef(0);
  const uploadRetryFilesRef = useRef(new Map<string, LibraryFile>());
  const dragDepthRef = useRef(0);
  const hostedLibraryRequestRef = useRef(0);
  const detailCopyTimerRef = useRef<number | null>(null);
  const engineToastTimerRef = useRef<number | null>(null);
  const selectedVersionIdRef = useRef("");

  const navigateHostedShare = useCallback((code: string, activityPolicy: ActivityPolicy) => {
    const nextState = historyStateRecord(window.history.state);
    if (activityPolicy === "preserve") nextState[RAIL_ACTIVITY_STATE_KEY] = code;
    else delete nextState[RAIL_ACTIVITY_STATE_KEY];
    window.history.pushState(
      Object.keys(nextState).length ? nextState : null,
      "",
      hostedSharePath(code, import.meta.env.BASE_URL),
    );
    playerRef.current?.pause();
    selectedVersionIdRef.current = "";
    setSelectedVersionId("");
    setVersionUploadError("");
    setPreservePublicActivity(activityPolicy === "preserve");
    setPublicRouteDetached(false);
    setPublicShare(null);
    setPublicShareState("loading");
    setLoading({ active: true, progress: 0, phase: "正在读取公开文件信息" });
    setShareCode(code);
  }, []);

  useEffect(() => {
    const syncRouteFromHistory = () => {
      const nextCode = shareCodeFromPath(window.location.pathname, import.meta.env.BASE_URL);
      setPreservePublicActivity(hasRailActivityMarker(nextCode));
      setPublicRouteDetached(false);
      selectedVersionIdRef.current = "";
      setSelectedVersionId("");
      setShareCode(nextCode);
      if (nextCode) return;
      openRequestRef.current += 1;
      activeSourceRef.current = null;
      playerRef.current?.pause();
      telemetry.reset();
      runtimeEventLog.reset();
      setActiveFile(null);
      setPublicShare(null);
      setPublicShareState("idle");
      setCommentThread({ code: null, items: [] });
      setLoading({ active: false, progress: 0, phase: "已返回文件列表" });
    };
    window.addEventListener("popstate", syncRouteFromHistory);
    return () => window.removeEventListener("popstate", syncRouteFromHistory);
  }, [runtimeEventLog, telemetry]);

  const showEngineToast = useCallback((message: string) => {
    if (engineToastTimerRef.current !== null) {
      window.clearTimeout(engineToastTimerRef.current);
    }
    setEngineToast(message);
    engineToastTimerRef.current = window.setTimeout(() => {
      setEngineToast("");
      engineToastTimerRef.current = null;
    }, 4200);
  }, []);

  useEffect(() => {
    if (preservePublicActivity) clearRailActivityMarker(shareCode);
  }, [preservePublicActivity, shareCode]);

  useEffect(() => () => {
    if (detailCopyTimerRef.current !== null) window.clearTimeout(detailCopyTimerRef.current);
    if (engineToastTimerRef.current !== null) window.clearTimeout(engineToastTimerRef.current);
    if (inspectorResizeFrameRef.current !== null) {
      window.cancelAnimationFrame(inspectorResizeFrameRef.current);
    }
  }, []);

  const refreshLibrary = useCallback(async () => {
    try {
      const [recentHostedFiles, localFiles] = await Promise.all([
        isHostedPlatform ? listRecentHostedFiles() : Promise.resolve([]),
        listLocalFiles(),
      ]);
      const nextFiles = await attachLibraryCovers(
        [...recentHostedFiles, ...localFiles].sort((left, right) => right.updatedAt - left.updatedAt),
      );
      nextFiles.forEach((file) => {
        if (file.cover) capturedCoverIdsRef.current.add(file.id);
      });
      setFiles(nextFiles);
    } catch (libraryError) {
      console.warn("读取本地文件库失败", libraryError);
    }
  }, [isHostedPlatform]);

  useEffect(() => {
    queueMicrotask(() => refreshLibrary());
  }, [refreshLibrary]);

  const refreshHostedLibrary = useCallback(async () => {
    if (!isHostedPlatform) {
      setHostedLibrary({ activeItems: [], archivedItems: [], loading: false, error: "" });
      return;
    }
    const requestId = ++hostedLibraryRequestRef.current;
    setHostedLibrary((current) => ({ ...current, loading: true, error: "" }));
    try {
      const [activeItems, archivedItems] = await Promise.all([
        listHostedShares("active", undefined, hostedVersioningEnabled ? ["rive", "lottie", "pag"] : undefined),
        listHostedShares("archived", undefined, hostedVersioningEnabled ? ["rive", "lottie", "pag"] : undefined),
      ]);
      if (requestId === hostedLibraryRequestRef.current) {
        setHostedLibrary({ activeItems, archivedItems, loading: false, error: "" });
      }
    } catch (hostedError) {
      if (requestId !== hostedLibraryRequestRef.current) return;
      setHostedLibrary((current) => ({
        ...current,
        loading: false,
        error: errorMessage(hostedError, "托管文件读取失败"),
      }));
    }
  }, [hostedVersioningEnabled, isHostedPlatform]);

  useEffect(() => {
    if (!isHostedPlatform) return;
    queueMicrotask(() => refreshHostedLibrary());
  }, [isHostedPlatform, refreshHostedLibrary]);

  useEffect(() => {
    if (!shareCode) return;
    const controller = new AbortController();
    const sessionId = ++openRequestRef.current;
    playerRef.current?.pause();
    setMetadata(EMPTY_METADATA);
    telemetry.reset();
    runtimeEventLog.reset();
    setPublicShareState("loading");
    setPublicShareError("");
    setPublicShare(null);
    setCommentThread({ code: shareCode, items: [] });
    setCommentsLoadError("");
    setCommentSubmitError("");
    setError("");
    setLoading({ active: true, progress: 0, phase: "正在读取公开文件信息" });

    const loadPublicShare = async () => {
      try {
        const share = await getHostedShare(shareCode, controller.signal);
        if (sessionId !== openRequestRef.current) return;
        const selectedVersion = hostedVersioningEnabled
          ? selectedHostedVersion(share, selectedVersionIdRef.current)
          : null;
        if (selectedVersion) {
          selectedVersionIdRef.current = selectedVersion.id;
          setSelectedVersionId(selectedVersion.id);
        }
        const openedFilename = selectedVersion?.filename || share.filename;
        const openedSize = selectedVersion?.size || share.size;
        const openedAt = selectedVersion?.createdAt || share.createdAt;
        setPublicShare(share);
        const openedFormat = selectedVersion?.format || share.format;
        document.title = `${hostedShareName(share, selectedVersion)} - 动效预览`;
        if (share.status === "archived") {
          activeSourceRef.current = null;
          telemetry.reset();
          setActiveFile(null);
          setLoading({ active: false, progress: 0, phase: "文件已归档" });
          setPublicShareState("archived");
          return;
        }

        setActiveFile({
          file: {
            id: `hosted-${share.code}`,
            name: openedFilename,
            size: openedSize,
            format: openedFormat,
            updatedAt: Date.parse(openedAt) || Date.now(),
            hostedCode: share.code,
          },
          sessionId,
          hostedShare: share,
        });
        setLoading({ active: true, progress: 0, phase: "正在下载公开文件" });
        const data = await getHostedFile(share.code, {
          signal: controller.signal,
          expectedBytes: openedSize,
          versionId: selectedVersion?.id,
          onProgress: (progress) => {
            if (sessionId !== openRequestRef.current) return;
            setLoading({ active: true, progress, phase: "正在下载公开文件" });
          },
        });
        if (sessionId !== openRequestRef.current) return;
        activeSourceRef.current = { sessionId, data };
        telemetry.reset();
        setActiveFile({
          file: {
            id: `hosted-${share.code}`,
            name: openedFilename,
            size: openedSize || data.byteLength,
            format: openedFormat,
            updatedAt: Date.parse(openedAt) || Date.now(),
            hostedCode: share.code,
          },
          sessionId,
          hostedShare: share,
        });
        setPublicShareState("ready");
        if (!share.isExample) {
          void (async () => {
            try {
              await rememberRecentHostedFile(
                share,
                preservePublicActivity ? Date.parse(share.createdAt) || Date.now() : Date.now(),
                preservePublicActivity,
              );
              if (sessionId === openRequestRef.current) await refreshLibrary();
            } catch (recentError) {
              console.warn("保存最近查看记录失败", recentError);
            }
          })();
        }
      } catch (loadError) {
        if (controller.signal.aborted || sessionId !== openRequestRef.current) return;
        activeSourceRef.current = null;
        setActiveFile(null);
        setLoading({ active: false, progress: 0, phase: "公开文件读取失败" });
        setPublicShareError(errorMessage(loadError, "公开链接无法打开"));
        setPublicShareState("error");
      }
    };
    loadPublicShare();

    return () => {
      controller.abort();
      if (sessionId === openRequestRef.current) {
        openRequestRef.current += 1;
        activeSourceRef.current = null;
      }
    };
  }, [hostedVersioningEnabled, preservePublicActivity, publicShareReload, refreshLibrary, runtimeEventLog, shareCode, telemetry]);

  useEffect(() => {
    if (!shareCode || publicShare?.status !== "active") return;
    const controller = new AbortController();
    const targetCode = shareCode;
    setCommentsLoading(true);
    setCommentsLoadError("");
    setCommentActionError("");
    setCommentThread((current) => current.code === targetCode
      ? current
      : { code: targetCode, items: [] });
    listHostedComments(targetCode, controller.signal)
      .then((items) => {
        if (!controller.signal.aborted) {
          setCommentThread((current) => {
            if (current.code !== targetCode) return current;
            const incomingIds = new Set(items.map((item) => item.id));
            return {
              code: targetCode,
              items: [...items, ...current.items.filter((item) => !incomingIds.has(item.id))]
                .sort((left, right) => Date.parse(left.createdAt) - Date.parse(right.createdAt)),
            };
          });
        }
      })
      .catch((commentsLoadError) => {
        if (!controller.signal.aborted) {
          setCommentsLoadError(errorMessage(commentsLoadError, "评论读取失败"));
        }
      })
      .finally(() => {
        if (!controller.signal.aborted) setCommentsLoading(false);
      });
    return () => controller.abort();
  }, [commentsReload, publicShare?.status, shareCode]);

  useEffect(() => () => {
    if (shareCode) document.title = "动效预览台 H5";
  }, [shareCode]);

  useEffect(() => {
    speedRef.current = speed;
    fitRef.current = fit;
    qualityRef.current = quality;
  }, [fit, quality, speed]);

  useEffect(() => {
    const canvas = canvasRef.current;
    const lottieContainer = lottieContainerRef.current;
    const stage = stageRef.current;
    if (!activeFile || !canvas || !lottieContainer || !stage) return;
    const source = activeSourceRef.current;
    if (!source || source.sessionId !== activeFile.sessionId) return;
    activeSourceRef.current = null;
    let sourceData: ArrayBuffer | null = source.data;
    source.data = new ArrayBuffer(0);
    let cancelled = false;
    let player: AnimationPlayer | null = null;
    let observer: ResizeObserver | null = null;
    let loadReady = false;
    let pendingRuntimeFailure: Error | null = null;

    const load = async () => {
      try {
        setError("");
        setMetadata(EMPTY_METADATA);
        telemetry.reset();
        runtimeEventLog.reset();
        const format = activeFile.file.format;
        const formatLabel = animationFormatLabel(format);
        setLoading({ active: true, progress: 28, phase: `正在初始化 ${formatLabel}` });
        await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
        if (cancelled) return;
        const { createAnimationPlayer } = await import("../../lib/animation-player");
        if (cancelled) return;
        const selectedEngine = renderEngineRef.current;
        player = await createAnimationPlayer(format, canvas, lottieContainer, {
          onMetadata: (nextMetadata) => !cancelled && setMetadata(nextMetadata),
          onPlayback: (nextPlaying) => {
            if (!cancelled) setPlaying(nextPlaying);
          },
          onProgress: (progress) => !cancelled && telemetry.updateTimeline(progress),
          onPerformance: (nextFps) => !cancelled && telemetry.updateFps(nextFps),
          onEvent: (event) => {
            if (!cancelled) runtimeEventLog.append(event);
          },
          onRuntimeFailure: (runtimeError) => {
            if (format !== "rive" || cancelled || selectedEngine !== "webgl2" || engineFallbackBusyRef.current) return;
            if (!loadReady) {
              pendingRuntimeFailure = runtimeError;
              return;
            }
            engineFallbackBusyRef.current = true;
            console.warn("WebGL2 运行失败，切换到兼容模式", runtimeError);
            renderEngineRef.current = "canvas2d";
            setRenderEngine("canvas2d");
            setCanvasGeneration((current) => current + 1);
            showEngineToast("WebGL2 不可用，已切换到兼容模式");
            queueMicrotask(() => reloadActiveFileRef.current());
          },
        }, selectedEngine);
        playerRef.current = player;
        player.setQuality(qualityRef.current);
        observer = new ResizeObserver(([entry]) => {
          if (!player) return;
          const box = entry.contentRect;
          if (draggingStageRef.current || draggingInspectorRef.current) {
            pendingPlayerSizeRef.current = { width: box.width, height: box.height };
            return;
          }
          player.resize(box.width, box.height);
        });
        observer.observe(stage);
        setLoading({ active: true, progress: 56, phase: "正在解析文件" });
        if (!sourceData) return;
        try {
          await player.load(sourceData);
          if (pendingRuntimeFailure) throw pendingRuntimeFailure;
        } catch (engineError) {
          if (format !== "rive" || selectedEngine !== "webgl2" || engineFallbackBusyRef.current || cancelled) {
            throw engineError;
          }
          engineFallbackBusyRef.current = true;
          console.warn("WebGL2 初始化失败，切换到兼容模式", engineError);
          activeSourceRef.current = { sessionId: activeFile.sessionId, data: sourceData };
          sourceData = null;
          renderEngineRef.current = "canvas2d";
          setRenderEngine("canvas2d");
          setCanvasGeneration((current) => current + 1);
          showEngineToast("WebGL2 不可用，已切换到兼容模式");
          setLoading({ active: true, progress: 34, phase: "正在切换兼容模式" });
          return;
        }
        sourceData = null;
        if (cancelled) return;
        loadReady = true;
        engineFallbackBusyRef.current = false;
        player.setSpeed(speedRef.current);
        player.setFit(fitRef.current);
        player.setQuality(qualityRef.current);
        setLoading({ active: true, progress: 94, phase: "正在绘制首帧" });
        await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
        if (cancelled) return;
        setLoading({ active: false, progress: 100, phase: "加载完成" });
        if (!capturedCoverIdsRef.current.has(activeFile.file.id)) {
          capturedCoverIdsRef.current.add(activeFile.file.id);
          window.setTimeout(async () => {
            const captureCanvas = format === "lottie"
              ? lottieContainer.querySelector("canvas")
              : canvas;
            if (cancelled || !captureCanvas?.width || !captureCanvas.height) return;
            const thumbnail = document.createElement("canvas");
            thumbnail.width = 160;
            thumbnail.height = 120;
            const context = thumbnail.getContext("2d", { alpha: false });
            if (!context) return;
            context.fillStyle = "#1b2632";
            context.fillRect(0, 0, thumbnail.width, thumbnail.height);
            context.drawImage(captureCanvas, 0, 0, thumbnail.width, thumbnail.height);
            const blob = await new Promise<Blob | null>((resolve) => (
              thumbnail.toBlob(resolve, "image/webp", 0.58)
            ));
            if (!blob || cancelled) return;
            await saveLibraryCover(activeFile.file.id, blob);
            if (!cancelled) await refreshLibrary();
          }, 180);
        }
      } catch (loadError) {
        if (cancelled) return;
        setLoading({ active: false, progress: 0, phase: "加载失败" });
        setError(loadError instanceof Error ? loadError.message : "动效文件无法打开");
      } finally {
        sourceData = null;
      }
    };
    load();

    return () => {
      cancelled = true;
      sourceData = null;
      if (stageResizeLongPressTimerRef.current !== null) {
        window.clearTimeout(stageResizeLongPressTimerRef.current);
        stageResizeLongPressTimerRef.current = null;
      }
      if (stageResizeMenuDismissTimerRef.current !== null) {
        window.clearTimeout(stageResizeMenuDismissTimerRef.current);
        stageResizeMenuDismissTimerRef.current = null;
      }
      if (stageResizeFrameRef.current !== null) {
        cancelAnimationFrame(stageResizeFrameRef.current);
        stageResizeFrameRef.current = null;
      }
      observer?.disconnect();
      player?.dispose();
      if (playerRef.current === player) playerRef.current = null;
    };
  }, [activeFile, canvasGeneration, refreshLibrary, runtimeEventLog, showEngineToast, telemetry]);

  useEffect(() => {
    playerRef.current?.setSpeed(speed);
  }, [speed]);

  useEffect(() => {
    playerRef.current?.setFit(fit);
  }, [fit]);

  useEffect(() => {
    playerRef.current?.setQuality(quality);
  }, [quality]);

  const unifiedFiles = useMemo(() => mergeUnifiedFiles(
    activeFile ? [...files, activeFile.file] : files,
    hostedLibrary.activeItems,
    hostedLibrary.archivedItems,
    publishedCodes,
  ).map((item) => {
    const uploadState = item.localFile ? uploadStates[item.localFile.id] : undefined;
    const activityAt = Math.max(item.activityAt, uploadState?.updatedAt || 0);
    return activityAt === item.activityAt
      ? item
      : { ...item, activityAt, file: { ...item.file, updatedAt: activityAt } };
  }).sort((left, right) => right.activityAt - left.activityAt), [
    activeFile,
    files,
    hostedLibrary.activeItems,
    hostedLibrary.archivedItems,
    publishedCodes,
    uploadStates,
  ]);
  const activeIndex = useMemo(() => unifiedFiles.findIndex((item) => (
    item.localFile?.id === activeFile?.file.id
    || item.file.id === activeFile?.file.id
    || Boolean(activeFile?.hostedShare?.code && item.hostedCode === activeFile.hostedShare.code)
  )), [activeFile, unifiedFiles]);
  const activeHostedCode = isHostedPlatform && activeFile
    ? activeFile.hostedShare?.code
      || activeFile.file.hostedCode
      || uploadStates[activeFile.file.id]?.share?.code
      || publishedCodes[activeFile.file.id]
      || ""
    : "";
  const activeHostedShare = publicShare?.code === activeHostedCode
    ? publicShare
    : hostedLibrary.activeItems.find((share) => share.code === activeHostedCode)
      || (activeFile ? uploadStates[activeFile.file.id]?.share : undefined)
      || activeFile?.hostedShare
      || null;
  const activeHostedVersions = useMemo(
    () => hostedVersioningEnabled ? hostedVersions(activeHostedShare) : [],
    [hostedVersioningEnabled, activeHostedShare],
  );
  const activeHostedVersion = useMemo(
    () => hostedVersioningEnabled ? selectedHostedVersion(activeHostedShare, selectedVersionId) : null,
    [hostedVersioningEnabled, activeHostedShare, selectedVersionId],
  );
  const activeDisplayName = activeHostedShare
    ? hostedShareName(activeHostedShare, activeHostedVersion)
    : activeFile?.file.name || "";

  useEffect(() => {
    if (activeHostedCode && activeDisplayName) document.title = `${activeDisplayName} - 动效预览`;
  }, [activeDisplayName, activeHostedCode]);

  const renameActiveHostedFile = useCallback(async (name: string) => {
    if (!activeHostedCode) return;
    const updatedShare = await renameHostedShare(activeHostedCode, name);
    setPublicShare((current) => current?.code === updatedShare.code
      ? { ...current, customName: updatedShare.customName }
      : current);
    setHostedLibrary((current) => ({
      ...current,
      activeItems: current.activeItems.map((share) => share.code === updatedShare.code
        ? { ...share, customName: updatedShare.customName } : share),
    }));
    setUploadStates((current) => Object.fromEntries(Object.entries(current).map(([id, state]) => [
      id,
      state.share?.code === updatedShare.code
        ? { ...state, share: { ...state.share, customName: updatedShare.customName } } : state,
    ])));
    await refreshHostedLibrary();
    if (!updatedShare.isExample) {
      void rememberRecentHostedFile(updatedShare, Date.now(), true).catch(() => {});
    }
  }, [activeHostedCode, refreshHostedLibrary]);
  const activeDetailCopyStatus = detailCopyFeedback?.code === activeHostedCode
    ? detailCopyFeedback.status
    : "";
  const detailCopyLabel = activeDetailCopyStatus === "copied"
    ? "已复制"
    : activeDetailCopyStatus === "error"
      ? "复制失败"
      : "复制分享链接";
  const detailCopyIcon: IconName = activeDetailCopyStatus === "copied"
    ? "check"
    : activeDetailCopyStatus === "error"
      ? "x"
      : "copy-simple";

  const copyActiveHostedLink = useCallback(async () => {
    const code = activeHostedCode;
    if (!code) return;
    let status: DetailCopyFeedback["status"] = "copied";
    try {
      await copyText(hostedShareUrl(code, import.meta.env.BASE_URL));
    } catch {
      status = "error";
    }
    setDetailCopyFeedback({ code, status });
    if (detailCopyTimerRef.current !== null) window.clearTimeout(detailCopyTimerRef.current);
    detailCopyTimerRef.current = window.setTimeout(() => {
      setDetailCopyFeedback((current) => current?.code === code ? null : current);
      detailCopyTimerRef.current = null;
    }, 2200);
  }, [activeHostedCode]);

  const selectHostedVersion = useCallback((versionId: string) => {
    if (!hostedVersioningEnabled || versionId === selectedVersionIdRef.current) {
      return;
    }
    if (!hostedVersions(publicShare).some((version) => version.id === versionId)) return;
    selectedVersionIdRef.current = versionId;
    setSelectedVersionId(versionId);
    setVersionUploadError("");
    setPublicShareReload((current) => current + 1);
  }, [hostedVersioningEnabled, publicShare]);

  const requestVersionUpload = useCallback((target: { code: string; format: AnimationFormat }) => {
    if (!hostedVersioningEnabled || versionUploading) return;
    versionTargetRef.current = target;
    setVersionUploadError("");
    versionInputRef.current?.click();
  }, [hostedVersioningEnabled, versionUploading]);

  const updateHostedVersion = useCallback(async (event: ChangeEvent<HTMLInputElement>) => {
    const input = event.currentTarget;
    const file = input.files?.[0];
    input.value = "";
    const target = versionTargetRef.current;
    versionTargetRef.current = null;
    if (!file || !hostedVersioningEnabled || !target || versionUploading) return;
    const requestSessionId = openRequestRef.current;
    let format: AnimationFormat;
    try {
      format = validateAnimationFile(file);
    } catch (validationError) {
      setVersionUploadError(errorMessage(validationError, "文件不受支持"));
      return;
    }
    if (format !== target.format) {
      setVersionUploadError(`新版本必须仍是 ${animationFormatLabel(target.format || "rive")} 文件`);
      return;
    }
    setVersionUploading(true);
    setVersionUploadProgress(0);
    setVersionUploadError("");
    try {
      const data = await file.arrayBuffer();
      const updatedShare = await createHostedVersion(
        target.code,
        data,
        file.name,
        setVersionUploadProgress,
      );
      if (requestSessionId !== openRequestRef.current) {
        await refreshHostedLibrary();
        return;
      }
      if (shareCode !== target.code || publicRouteDetached) {
        navigateHostedShare(target.code, "preserve");
        await refreshHostedLibrary();
        return;
      }
      const nextVersion = selectedHostedVersion(updatedShare, updatedShare.currentVersionId);
      setPublicShare(updatedShare);
      if (nextVersion) {
        selectedVersionIdRef.current = nextVersion.id;
        setSelectedVersionId(nextVersion.id);
      }
      await refreshHostedLibrary();
      setPublicShareReload((current) => current + 1);
    } catch (uploadError) {
      setVersionUploadError(errorMessage(uploadError, "版本更新失败"));
    } finally {
      setVersionUploading(false);
    }
  }, [hostedVersioningEnabled, navigateHostedShare,
    publicRouteDetached, refreshHostedLibrary, shareCode, versionUploading]);
  const coverUrls = useMemo(() => new Map(
    [...files, ...(activeFile?.file.cover ? [activeFile.file] : [])]
      .filter((file, index, values) => file.cover && values.findIndex((item) => item.id === file.id) === index)
      .map((file) => [file.id, URL.createObjectURL(file.cover!)]),
  ), [activeFile, files]);

  useEffect(() => () => {
    coverUrls.forEach((url) => URL.revokeObjectURL(url));
  }, [coverUrls]);

  useEffect(() => {
    if (!expandedFileId) return;
    const closeFileMenu = (event: PointerEvent) => {
      const target = event.target as HTMLElement | null;
      if (!target?.closest(".file-row.is-menu-open")) setExpandedFileId("");
    };
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      event.stopImmediatePropagation();
      document.querySelector<HTMLButtonElement>(".file-row.is-menu-open .square-button")?.focus();
      setExpandedFileId("");
    };
    document.addEventListener("pointerdown", closeFileMenu);
    window.addEventListener("keydown", closeOnEscape, true);
    return () => {
      document.removeEventListener("pointerdown", closeFileMenu);
      window.removeEventListener("keydown", closeOnEscape, true);
    };
  }, [expandedFileId]);

  const closeActiveFile = useCallback(() => {
    if (shareCode && !publicRouteDetached) {
      window.location.assign(viewerHomePath(import.meta.env.BASE_URL));
      return;
    }
    openRequestRef.current += 1;
    activeSourceRef.current = null;
    pendingPlayerSizeRef.current = null;
    telemetry.reset();
    runtimeEventLog.reset();
    setActiveFile(null);
    setLoading({ active: false, progress: 0, phase: "已关闭" });
  }, [publicRouteDetached, runtimeEventLog, shareCode, telemetry]);

  useEffect(() => {
    if (!activeFile && (!shareCode || publicRouteDetached)) return;
    const returnHomeOnEscape = (event: KeyboardEvent) => {
      if (event.key !== "Escape" || event.defaultPrevented) return;
      if (document.querySelector('[aria-modal="true"]')) return;
      event.preventDefault();
      closeActiveFile();
    };
    window.addEventListener("keydown", returnHomeOnEscape);
    return () => window.removeEventListener("keydown", returnHomeOnEscape);
  }, [activeFile, closeActiveFile, publicRouteDetached, shareCode]);

  const openFile = useCallback(async (
    file: LibraryFile,
    activityPolicy: ActivityPolicy = "record",
  ) => {
    if (file.hostedCode) {
      navigateHostedShare(file.hostedCode, activityPolicy);
      return;
    }
    const sessionId = ++openRequestRef.current;
    try {
      setExpandedFileId("");
      setError("");
      setLoading({ active: true, progress: 8, phase: "正在读取本地文件" });
      const data = await readLibraryFile(file);
      if (sessionId !== openRequestRef.current) return;
      const updatedAt = activityPolicy === "record" ? Date.now() : file.updatedAt;
      const openedFile = { ...file, size: file.size || data.byteLength, updatedAt };
      setFiles((current) => {
        if (activityPolicy === "record") {
          return [
            openedFile,
            ...current.filter((item) => item.id !== openedFile.id),
          ].sort((left, right) => right.updatedAt - left.updatedAt);
        }
        const exists = current.some((item) => item.id === openedFile.id);
        if (!exists) return [openedFile, ...current];
        return current.map((item) => item.id === openedFile.id ? { ...item, ...openedFile } : item);
      });
      activeSourceRef.current = { sessionId, data };
      telemetry.reset();
      setActiveFile({ file: openedFile, sessionId });
      document.title = `${openedFile.name} - 动效预览`;
      if (activityPolicy === "record") {
        void touchLocalFile(file.id, updatedAt).catch((touchError) => {
          console.warn("更新最近打开时间失败", touchError);
        });
      }
    } catch (openError) {
      if (sessionId !== openRequestRef.current) return;
      setLoading({ active: false, progress: 0, phase: "读取失败" });
      setError(openError instanceof Error ? openError.message : "无法读取文件");
    }
  }, [navigateHostedShare, telemetry]);

  const openUnifiedFile = useCallback((
    item: UnifiedFileItem,
    activityPolicy: ActivityPolicy = "record",
  ) => {
    if (isHostedPlatform && item.hostedCode) {
      navigateHostedShare(item.hostedCode, activityPolicy);
      return;
    }
    if (item.localFile) {
      void openFile(item.localFile, activityPolicy);
      return;
    }
    if (item.hostedCode) {
      navigateHostedShare(item.hostedCode, activityPolicy);
      return;
    }
    void openFile(item.file, activityPolicy);
  }, [isHostedPlatform, navigateHostedShare, openFile]);

  const rememberPublishedCode = useCallback((fileId: string, code: string) => {
    setPublishedCodes((current) => {
      const next = { ...current, [fileId]: code };
      try {
        window.localStorage.setItem(PUBLISHED_CODES_STORAGE_KEY, JSON.stringify(next));
      } catch {
        // 禁用站点存储时仍保留当前页面的复制入口。
      }
      return next;
    });
  }, []);

  const uploadSavedFiles = useCallback(async (savedFiles: LibraryFile[]) => {
    const uploadedShares: HostedShare[] = [];
    for (const file of savedFiles) {
      setUploadStates((current) => ({
        ...current,
        [file.id]: {
          phase: "uploading",
          progress: 0,
          error: "",
          retryable: false,
          updatedAt: Date.now(),
        },
      }));
      try {
        const data = await readLibraryFile(file);
        const share = await createHostedShare(data, file.name, (progress) => {
          setUploadStates((current) => {
            const state = current[file.id];
            if (!state || state.phase !== "uploading") return current;
            return { ...current, [file.id]: { ...state, progress } };
          });
        });
        uploadRetryFilesRef.current.delete(file.id);
        uploadedShares.push(share);
        rememberPublishedCode(file.id, share.code);
        setHostedLibrary((current) => ({
          ...current,
          activeItems: [share, ...current.activeItems.filter((item) => item.code !== share.code)],
        }));
        setUploadStates((current) => ({
          ...current,
          [file.id]: {
            phase: "ready",
            progress: 100,
            error: "",
            retryable: false,
            share,
            updatedAt: Date.now(),
          },
        }));
      } catch (uploadError) {
        const retryable = !(uploadError instanceof HostedApiError
          && uploadError.status >= 400
          && uploadError.status < 500
          && uploadError.status !== 429);
        if (retryable) uploadRetryFilesRef.current.set(file.id, file);
        else uploadRetryFilesRef.current.delete(file.id);
        setUploadStates((current) => ({
          ...current,
          [file.id]: {
            phase: "error",
            progress: current[file.id]?.progress || 0,
            error: errorMessage(uploadError, "云端上传失败"),
            retryable,
            updatedAt: Date.now(),
          },
        }));
      }
    }
    await refreshHostedLibrary();
    return uploadedShares;
  }, [refreshHostedLibrary, rememberPublishedCode]);

  const handleIncomingFiles = useCallback(async (values: File[] | FileList) => {
    if (cloudUploadBusyRef.current) {
      setImportError("当前文件仍在上传，请完成后再选择下一批文件。");
      return;
    }
    const selected = Array.from(values);
    if (!selected.length) return;
    try {
      selected.forEach(validateAnimationFile);
    } catch (validationError) {
      setImportError(errorMessage(validationError, "文件不受支持，请重新选择。"));
      return;
    }

    cloudUploadBusyRef.current = true;
    setImportBusy(true);
    setImportError("");
    const saved: LibraryFile[] = [];
    let openPromise: Promise<void> | null = null;
    try {
      for (const file of selected) {
        const savedFile = await saveLocalFile(file);
        saved.push(savedFile);
        setUploadStates((current) => ({
          ...current,
          [savedFile.id]: {
            phase: "local",
            progress: 0,
            error: "",
            retryable: false,
            updatedAt: Date.now(),
          },
        }));
        setFiles((current) => [savedFile, ...current.filter((item) => item.id !== savedFile.id)]);
        if (saved.length === 1) {
          if (shareCode && !publicRouteDetached) {
            window.history.replaceState({}, "", viewerHomePath(import.meta.env.BASE_URL));
            setPublicRouteDetached(true);
            setPublicShare(null);
            setCommentThread({ code: null, items: [] });
            setCommentsLoadError("");
            setCommentSubmitError("");
          }
          openPromise = openFile(savedFile);
        }
      }
      const uploadPromise = isHostedPlatform
        ? uploadSavedFiles(saved)
        : Promise.resolve([] as HostedShare[]);
      await Promise.all([openPromise, refreshLibrary(), uploadPromise]);
    } catch (incomingError) {
      setImportError(errorMessage(incomingError, "文件保存失败，请重新选择"));
    } finally {
      cloudUploadBusyRef.current = false;
      setImportBusy(false);
    }
  }, [isHostedPlatform, openFile, publicRouteDetached, refreshLibrary, shareCode, uploadSavedFiles]);

  const importFiles = (event: ChangeEvent<HTMLInputElement>) => {
    const selected = Array.from(event.target.files || []);
    event.target.value = "";
    if (selected.length) void handleIncomingFiles(selected);
  };

  const dropFiles = (event: ReactDragEvent<HTMLElement>) => {
    event.preventDefault();
    event.stopPropagation();
    dragDepthRef.current = 0;
    setDropActive(false);
    void handleIncomingFiles(event.dataTransfer.files);
  };

  const enterDropTarget = (event: ReactDragEvent<HTMLElement>) => {
    if (!Array.from(event.dataTransfer.types).includes("Files")) return;
    event.preventDefault();
    dragDepthRef.current += 1;
    setDropActive(true);
  };

  const showDropTarget = (event: ReactDragEvent<HTMLElement>) => {
    if (!Array.from(event.dataTransfer.types).includes("Files")) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "copy";
    setDropActive(true);
  };

  const hideDropTarget = (event: ReactDragEvent<HTMLElement>) => {
    event.preventDefault();
    dragDepthRef.current = Math.max(0, dragDepthRef.current - 1);
    if (dragDepthRef.current === 0) setDropActive(false);
  };

  const retryFileUpload = useCallback(async (fileId: string) => {
    const retryFile = uploadRetryFilesRef.current.get(fileId);
    if (!retryFile || cloudUploadBusyRef.current) return;
    cloudUploadBusyRef.current = true;
    setImportBusy(true);
    try {
      await uploadSavedFiles([retryFile]);
    } finally {
      cloudUploadBusyRef.current = false;
      setImportBusy(false);
    }
  }, [uploadSavedFiles]);

  const downloadFile = useCallback(async (
    file: LibraryFile,
    hostedCode?: string,
    versionId?: string,
  ) => {
    if (hostedCode) {
      const anchor = document.createElement("a");
      anchor.href = hostedFileUrl(hostedCode, versionId);
      anchor.download = file.name;
      anchor.click();
      return;
    }
    const data = await readLibraryFile(file);
    const blob = new Blob([data], { type: "application/octet-stream" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = file.name;
    anchor.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }, []);

  const shareFile = useCallback(async (file: LibraryFile, hostedCode?: string) => {
    if (hostedCode || file.hostedCode) {
      await downloadFile(file, hostedCode || file.hostedCode);
      return;
    }
    const data = await readLibraryFile(file);
    const sharedFile = new File([data], file.name, { type: "application/octet-stream" });
    const payload = { files: [sharedFile], title: file.name };
    if (navigator.share && (!navigator.canShare || navigator.canShare(payload))) {
      try {
        await navigator.share(payload);
        return;
      } catch (shareError) {
        if (shareError instanceof DOMException && shareError.name === "AbortError") return;
      }
    }
    await downloadFile(file);
  }, [downloadFile]);

  const requestPublishFile = useCallback(async (file: LibraryFile) => {
    const code = file.hostedCode || publishedCodes[file.id];
    if (code) {
      const knownShare = [...hostedLibrary.activeItems, ...hostedLibrary.archivedItems]
        .find((share) => share.code === code);
      setExpandedFileId("");
      setHostingError("");
      if (knownShare) {
        setPublishedShare(knownShare);
        return;
      }
      try {
        setPublishedShare(await getHostedShare(code));
      } catch (shareError) {
        setHostingError(errorMessage(shareError, "这个公开链接暂时无法读取"));
      }
      return;
    }
    if (cloudUploadBusyRef.current) {
      setImportError("当前文件仍在上传，请稍后重试。");
      return;
    }
    setExpandedFileId("");
    setHostingError("");
    cloudUploadBusyRef.current = true;
    setImportBusy(true);
    try {
      const shares = await uploadSavedFiles([file]);
      if (shares[0]) setPublishedShare(shares[0]);
    } finally {
      cloudUploadBusyRef.current = false;
      setImportBusy(false);
    }
  }, [hostedLibrary.activeItems, hostedLibrary.archivedItems, publishedCodes, uploadSavedFiles]);

  const archiveShare = useCallback(async (share: HostedShare) => {
    if (hostedBusyCode) return;
    setHostedBusyCode(share.code);
    setHostedLibrary((current) => ({ ...current, error: "" }));
    try {
      await archiveHostedShare(share.code);
      setUploadStates((current) => Object.fromEntries(Object.entries(current).map(([fileId, state]) => (
        state.share?.code === share.code
          ? [fileId, { ...state, phase: "local", progress: 0, share: undefined }]
          : [fileId, state]
      ))));
      await refreshHostedLibrary();
    } catch (archiveError) {
      setHostedLibrary((current) => ({
        ...current,
        error: errorMessage(archiveError, "文件归档失败"),
      }));
      throw archiveError;
    } finally {
      setHostedBusyCode("");
    }
  }, [hostedBusyCode, refreshHostedLibrary]);

  const confirmPendingArchive = useCallback(async () => {
    if (!pendingArchiveShare) return;
    try {
      await archiveShare(pendingArchiveShare);
      setPendingArchiveShare(null);
      if (pendingArchiveShare.code === activeHostedCode) closeActiveFile();
    } catch {
      // 列表区域保留服务端错误，确认框继续打开便于重试或取消。
    }
  }, [activeHostedCode, archiveShare, closeActiveFile, pendingArchiveShare]);

  const restoreShare = useCallback(async (share: HostedShare) => {
    if (hostedBusyCode) return;
    setHostedBusyCode(share.code);
    setHostedLibrary((current) => ({ ...current, error: "" }));
    try {
      const restoredShare = await restoreHostedShare(share.code);
      setUploadStates((current) => Object.fromEntries(Object.entries(current).map(([fileId, state]) => (
        publishedCodes[fileId] === share.code
          ? [fileId, { ...state, phase: "ready", progress: 100, share: restoredShare }]
          : [fileId, state]
      ))));
      await refreshHostedLibrary();
    } catch (restoreError) {
      setHostedLibrary((current) => ({
        ...current,
        error: errorMessage(restoreError, "文件恢复失败"),
      }));
    } finally {
      setHostedBusyCode("");
    }
  }, [hostedBusyCode, publishedCodes, refreshHostedLibrary]);

  const submitComment = useCallback(async (body: string, author: HostedCommentAuthorInput) => {
    if (!shareCode || commentSubmitBusyRef.current) return false;
    const targetCode = shareCode;
    commentSubmitBusyRef.current = true;
    setCommentSubmitting(true);
    setCommentSubmitError("");
    try {
      const comment = await createHostedComment(targetCode, {
        visitorId: getCommentVisitorId(),
        body,
        ...(hostedVersioningEnabled && selectedVersionIdRef.current
          ? { versionId: selectedVersionIdRef.current }
          : {}),
        ...author,
      });
      setCommentThread((current) => {
        if (current.code !== targetCode || current.items.some((item) => item.id === comment.id)) {
          return current;
        }
        return { code: targetCode, items: [...current.items, comment] };
      });
      const nextShare = publicShare?.code === targetCode
        ? { ...publicShare, commentCount: publicShare.commentCount + 1 }
        : null;
      setPublicShare((current) => current?.code === targetCode ? nextShare : current);
      if (nextShare && !nextShare.isExample) {
        try {
          await rememberRecentHostedFile(nextShare);
          await refreshLibrary();
        } catch (recentError) {
          console.warn("更新最近评论记录失败", recentError);
        }
      }
      return true;
    } catch (commentError) {
      if (commentError instanceof HostedApiError && commentError.code === "share_archived") {
        playerRef.current?.pause();
        setActiveFile(null);
        setPublicShare((current) => current ? { ...current, status: "archived" } : current);
        setPublicShareState("archived");
        setCommentsLoadError("");
        setCommentSubmitError("");
        return false;
      }
      setCommentSubmitError(errorMessage(commentError, "评论提交失败"));
      return false;
    } finally {
      commentSubmitBusyRef.current = false;
      setCommentSubmitting(false);
    }
  }, [hostedVersioningEnabled, publicShare, refreshLibrary, shareCode]);

  const changeCommentStatus = useCallback(async (
    comment: HostedComment,
    action: "archive" | "restore",
  ) => {
    if (!shareCode || commentActionBusyId) return;
    const targetCode = shareCode;
    setCommentActionBusyId(comment.id);
    setCommentActionError("");
    try {
      const updated = action === "archive"
        ? await archiveHostedComment(targetCode, comment.id)
        : await restoreHostedComment(targetCode, comment.id);
      setCommentThread((current) => current.code === targetCode
        ? {
            code: targetCode,
            items: current.items.map((item) => item.id === updated.id ? updated : item),
          }
        : current);
    } catch (commentActionFailure) {
      setCommentActionError(errorMessage(
        commentActionFailure,
        action === "archive" ? "评论归档失败" : "评论恢复失败",
      ));
    } finally {
      setCommentActionBusyId("");
    }
  }, [commentActionBusyId, shareCode]);

  const reloadActiveFile = useCallback(() => {
    if (activeFile?.hostedShare) {
      setPublicShareReload((current) => current + 1);
      return;
    }
    if (activeFile) openFile(activeFile.file, "preserve");
  }, [activeFile, openFile]);

  useEffect(() => {
    reloadActiveFileRef.current = reloadActiveFile;
  }, [reloadActiveFile]);

  const selectRenderEngine = useCallback((nextEngine: RenderEngine) => {
    if (renderEngineRef.current === nextEngine) return;
    engineFallbackBusyRef.current = false;
    renderEngineRef.current = nextEngine;
    setRenderEngine(nextEngine);
    setCanvasGeneration((current) => current + 1);
    if (activeFile) reloadActiveFile();
  }, [activeFile, reloadActiveFile]);

  const togglePlayback = useCallback(() => {
    const player = playerRef.current;
    if (!player) return;
    if (playing) player.pause();
    else player.play();
  }, [playing]);

  const navigateFile = useCallback((offset: number) => {
    const next = unifiedFiles[activeIndex + offset];
    if (next) openUnifiedFile(next, "preserve");
  }, [activeIndex, openUnifiedFile, unifiedFiles]);

  const resetPlayback = useCallback(() => {
    playerRef.current?.reset();
  }, []);

  const adjustSpeed = useCallback((offset: number) => {
    setSpeed((current) => {
      const currentIndex = SPEEDS.indexOf(current);
      const nextIndex = clamp(currentIndex + offset, 0, SPEEDS.length - 1);
      return SPEEDS[nextIndex];
    });
  }, []);

  useEffect(() => {
    if (!activeFile) return;
    const handleShortcut = (event: KeyboardEvent) => {
      if (event.defaultPrevented) return;
      if (event.isComposing || document.querySelector('[aria-modal="true"], [role="menu"]')) return;
      const target = event.target as HTMLElement | null;
      const tagName = target?.tagName;
      if (
        target?.isContentEditable
        || tagName === "INPUT"
        || tagName === "TEXTAREA"
        || tagName === "SELECT"
      ) return;
      if (event.metaKey || event.ctrlKey || event.altKey) return;

      const key = event.key.toLowerCase();
      if (key === " " && target?.closest(".shortcut-button")) return;

      if (key === "delete" || key === "backspace") {
        if (event.repeat || !isHostedPlatform || activeHostedShare?.status !== "active" || hostedBusyCode || versionUploading) return;
        setPendingArchiveShare(activeHostedShare);
      }
      else if (key === "r") resetPlayback();
      else if (key === " ") togglePlayback();
      else if (key === "arrowleft" || key === "arrowup") navigateFile(-1);
      else if (key === "arrowright" || key === "arrowdown") navigateFile(1);
      else if (key === "+" || key === "=") adjustSpeed(1);
      else if (key === "-" || key === "_") adjustSpeed(-1);
      else return;

      event.preventDefault();
    };
    window.addEventListener("keydown", handleShortcut);
    return () => window.removeEventListener("keydown", handleShortcut);
  }, [activeFile, activeHostedShare, adjustSpeed, hostedBusyCode, isHostedPlatform, navigateFile, resetPlayback, togglePlayback, versionUploading]);

  useEffect(() => {
    if (!activeFile) return;
    const handleFileShortcut = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (event.defaultPrevented || event.isComposing
        || target?.isContentEditable || target?.closest("input, textarea, select")
        || document.querySelector('[aria-modal="true"], [role="menu"]')) return;
      const fileAction = getFileShortcut(event, navigator.platform);
      if (fileAction && (fileAction === "download" || activeHostedCode)) {
        // Cancel the browser action before starting asynchronous file work.
        event.preventDefault();
        event.stopPropagation();
        if (event.repeat) return;
        if (fileAction === "copy") void copyActiveHostedLink();
        else if (fileAction === "download") void downloadFile(activeFile.file, activeHostedCode || undefined, activeHostedVersion?.id);
        else if (hostedVersioningEnabled && activeHostedCode) {
          requestVersionUpload({ code: activeHostedCode, format: activeHostedShare?.format || activeFile.file.format || "rive" });
        }
        return;
      }
    };
    window.addEventListener("keydown", handleFileShortcut, true);
    return () => window.removeEventListener("keydown", handleFileShortcut, true);
  }, [activeFile, activeHostedCode, activeHostedShare?.format, activeHostedVersion?.id, copyActiveHostedLink, downloadFile, hostedVersioningEnabled, requestVersionUpload]);

  const expandCatalog = async () => {
    if (catalogLoading) return;
    setCatalogLoading(true);
    setCatalogProgress(0);
    try {
      await playerRef.current?.loadArtboardCatalog(setCatalogProgress);
    } finally {
      setCatalogLoading(false);
    }
  };

  const handleInput = (input: AnimationInput, value?: boolean | number) => {
    if (input.type === "trigger") playerRef.current?.fireInput(input.index);
    else playerRef.current?.setInput(input.index, value ?? !input.value);
  };

  const canvasPointer = (
    type: "down" | "move" | "up" | "exit",
    event: ReactPointerEvent<HTMLCanvasElement>,
  ) => {
    event.preventDefault();
    const canvas = event.currentTarget;
    const rect = canvas.getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;
    if (type === "down") {
      canvas.setPointerCapture(event.pointerId);
      playerRef.current?.pointer("down", x, y, event.pointerId);
      return;
    }
    if (type === "up") {
      playerRef.current?.pointer("up", x, y, event.pointerId);
      playerRef.current?.pointer("exit", x, y, event.pointerId);
      if (canvas.hasPointerCapture(event.pointerId)) canvas.releasePointerCapture(event.pointerId);
      return;
    }
    if (type === "exit") {
      if (event.type === "pointerleave" && canvas.hasPointerCapture(event.pointerId)) return;
      playerRef.current?.pointer("exit", x, y, event.pointerId);
      if (canvas.hasPointerCapture(event.pointerId)) canvas.releasePointerCapture(event.pointerId);
      return;
    }
    playerRef.current?.pointer("move", x, y, event.pointerId);
  };

  const clearStageResizeTimer = () => {
    if (stageResizeLongPressTimerRef.current !== null) {
      window.clearTimeout(stageResizeLongPressTimerRef.current);
      stageResizeLongPressTimerRef.current = null;
    }
  };

  const clearStageResizeMenuDismiss = () => {
    if (stageResizeMenuDismissTimerRef.current !== null) {
      window.clearTimeout(stageResizeMenuDismissTimerRef.current);
      stageResizeMenuDismissTimerRef.current = null;
    }
  };

  const closeStageResizeTapMenu = () => {
    clearStageResizeMenuDismiss();
    lastStageTapRef.current = 0;
    setStageResizeMenuActive(false);
    setStageResizeTapOpen(false);
    setStageResizePressActive(false);
    setStageResizeHoverFit("");
  };

  const scheduleStageResizeMenuDismiss = () => {
    clearStageResizeMenuDismiss();
    stageResizeMenuDismissTimerRef.current = window.setTimeout(() => {
      stageResizeMenuDismissTimerRef.current = null;
      if (draggingStageRef.current) return;
      lastStageTapRef.current = 0;
      setStageResizeMenuActive(false);
      setStageResizeTapOpen(false);
      setStageResizePressActive(false);
      setStageResizeHoverFit("");
    }, policy.gesture.menuDismissMs);
  };

  const stageFitAtPointer = (clientX: number): "contain" | "cover" | "" => {
    const bounds = eventTargetStageResizerRef.current?.getBoundingClientRect();
    if (!bounds?.width) return "";
    const ratio = (clientX - bounds.left) / bounds.width;
    if (ratio < 0 || ratio > 1) return "";
    if (ratio < 1 / 3) return "contain";
    if (ratio > 2 / 3) return "cover";
    return "";
  };

  const eventTargetStageResizerRef = useRef<HTMLDivElement>(null);

  const maximumStageHeight = () => {
    if (typeof window !== "undefined" && window.innerWidth >= WIDE_LAYOUT_MIN_WIDTH) {
      const workbenchHeight = previewWorkbenchRef.current?.clientHeight || window.innerHeight;
      return Math.max(320, workbenchHeight - 80);
    }
    return Math.max(320, typeof window === "undefined" ? 620 : window.innerHeight * 0.66);
  };

  const applyStageHeight = useCallback((height: number) => {
    const stage = stageRef.current;
    if (!stage) return;
    const keepSourceAspect = activeFile?.file.format === "rive"
      && fitRef.current === "contain"
      && metadata.width > 0
      && metadata.height > 0;
    if (window.innerWidth >= WIDE_LAYOUT_MIN_WIDTH) {
      stage.style.setProperty("--manual-stage-height", `${height}px`);
      if (keepSourceAspect) {
        stage.style.width = `min(100%, ${Math.round(height * (metadata.width / metadata.height))}px)`;
        stage.style.height = "";
        return;
      }
      stage.style.width = "100%";
      stage.style.height = `${height}px`;
      return;
    }
    if (keepSourceAspect) {
      stage.style.width = `min(100%, ${Math.round(height * (metadata.width / metadata.height))}px)`;
      stage.style.height = "";
      return;
    }
    stage.style.width = "100%";
    stage.style.height = `${height}px`;
  }, [activeFile?.file.format, metadata.height, metadata.width]);

  const beginStageResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if ((event.target as HTMLElement).closest(".stage-resizer-mode")) return;
    const currentHeight = stageRef.current?.getBoundingClientRect().height || stageHeight;
    resizeStartRef.current = { x: event.clientX, y: event.clientY, height: currentHeight };
    applyStageHeight(currentHeight);
    setStageHeight(currentHeight);
    setStageHeightCustomized(true);
    event.currentTarget.setPointerCapture(event.pointerId);
    draggingStageRef.current = true;
    pendingStageHeightRef.current = null;
    stageResizeMovedRef.current = false;
    stageResizeStartedOpenRef.current = stageResizeTapOpen;
    setStageResizeMenuActive(true);
    setStageResizeTapOpen(false);
    setStageResizePressActive(false);
    setStageResizeHoverFit("");
    clearStageResizeTimer();
    clearStageResizeMenuDismiss();
    stageResizeLongPressTimerRef.current = window.setTimeout(() => {
      setStageResizePressActive(true);
    }, 150);
  };

  const moveStageResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!draggingStageRef.current) return;
    const deltaX = event.clientX - resizeStartRef.current.x;
    const deltaY = event.clientY - resizeStartRef.current.y;
    const hoverFit = stageFitAtPointer(event.clientX);
    setStageResizeHoverFit((current) => current === hoverFit ? current : hoverFit);
    if (Math.abs(deltaY) > policy.gesture.webSlopPx || Math.abs(deltaX) > policy.gesture.webSlopPx) {
      const wasMoved = stageResizeMovedRef.current;
      stageResizeMovedRef.current = true;
      if (!wasMoved) {
        setDraggingStage(true);
        setStageResizePressActive(true);
      }
    }
    const maximum = maximumStageHeight();
    if (Math.abs(deltaY) >= Math.abs(deltaX)) {
      pendingStageHeightRef.current = clamp(
        resizeStartRef.current.height + deltaY,
        STAGE_MIN_HEIGHT,
        maximum,
      );
      if (stageResizeFrameRef.current === null) {
        stageResizeFrameRef.current = requestAnimationFrame(() => {
          stageResizeFrameRef.current = null;
          if (pendingStageHeightRef.current !== null) {
            applyStageHeight(pendingStageHeightRef.current);
          }
        });
      }
    }
  };

  const endStageResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!draggingStageRef.current) return;
    clearStageResizeTimer();
    if (stageResizeFrameRef.current !== null) {
      cancelAnimationFrame(stageResizeFrameRef.current);
      stageResizeFrameRef.current = null;
    }
    if (pendingStageHeightRef.current !== null) {
      applyStageHeight(pendingStageHeightRef.current);
      setStageHeight(pendingStageHeightRef.current);
      pendingStageHeightRef.current = null;
    }
    const selectedFit = stageResizeStartedOpenRef.current ? "" : stageFitAtPointer(event.clientX);
    draggingStageRef.current = false;
    const stageBounds = stageRef.current?.getBoundingClientRect();
    pendingPlayerSizeRef.current = null;
    if (stageBounds) playerRef.current?.resize(stageBounds.width, stageBounds.height);
    setDraggingStage(false);
    setStageResizePressActive(false);
    setStageResizeHoverFit("");
    if ((stageResizeMovedRef.current || selectedFit) && selectedFit) {
      selectFit(selectedFit);
      closeStageResizeTapMenu();
      return;
    }
    if (stageResizeMovedRef.current) {
      closeStageResizeTapMenu();
      return;
    }
    setStageResizeMenuActive(true);
    setStageResizeTapOpen(true);
    scheduleStageResizeMenuDismiss();
  };

  const selectFit = (nextFit: "contain" | "cover") => {
    clearStageResizeMenuDismiss();
    setFit(nextFit);
    playerRef.current?.setFit(nextFit);
  };

  const toggleStageFit = () => {
    selectFit(fitRef.current === "contain" ? "cover" : "contain");
  };

  const inspectorWidthBounds = useCallback(() => {
    const workbenchWidth = previewWorkbenchRef.current?.clientWidth || 0;
    const availableMaximum = workbenchWidth
      ? workbenchWidth - WIDE_COLUMN_RESIZER_WIDTH - WIDE_PREVIEW_MIN_WIDTH
      : WIDE_INSPECTOR_FALLBACK_MAX_WIDTH;
    return {
      minimum: WIDE_INSPECTOR_MIN_WIDTH,
      maximum: Math.max(WIDE_INSPECTOR_MIN_WIDTH, availableMaximum),
    };
  }, []);

  useLayoutEffect(() => {
    const workbench = previewWorkbenchRef.current;
    if (!activeFile || !workbench) return undefined;

    const syncInspectorWidth = () => {
      const bounds = inspectorWidthBounds();
      setInspectorWidthMaximum(Math.round(bounds.maximum));
      const preferredWidth = window.innerWidth >= WIDE_LAYOUT_MIN_WIDTH && !inspectorWidthCustomized
        ? workbench.clientWidth - WIDE_COLUMN_RESIZER_WIDTH - WIDE_PREVIEW_PREFERRED_WIDTH
        : currentInspectorWidthRef.current;
      const nextWidth = Math.round(clamp(preferredWidth, bounds.minimum, bounds.maximum));
      if (nextWidth === currentInspectorWidthRef.current) return;
      currentInspectorWidthRef.current = nextWidth;
      workbench.style.setProperty("--preview-inspector-width", `${nextWidth}px`);
      setInspectorWidth(nextWidth);
    };

    syncInspectorWidth();
    const observer = new ResizeObserver(syncInspectorWidth);
    observer.observe(workbench);
    return () => observer.disconnect();
  }, [activeFile, inspectorWidthBounds, inspectorWidthCustomized]);

  const applyInspectorWidth = useCallback((width: number) => {
    const bounds = inspectorWidthBounds();
    const nextWidth = Math.round(clamp(width, bounds.minimum, bounds.maximum));
    currentInspectorWidthRef.current = nextWidth;
    previewWorkbenchRef.current?.style.setProperty(
      "--preview-inspector-width",
      `${nextWidth}px`,
    );
    previewColumnResizerRef.current?.setAttribute("aria-valuenow", String(nextWidth));
    previewColumnResizerRef.current?.setAttribute(
      "aria-valuetext",
      `右侧栏宽度 ${nextWidth} 像素`,
    );
    return nextWidth;
  }, [inspectorWidthBounds]);

  const beginInspectorResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (event.pointerType === "mouse" && event.button !== 0) return;
    const currentWidth = previewInspectorRef.current?.getBoundingClientRect().width
      || currentInspectorWidthRef.current;
    inspectorResizeStartRef.current = { x: event.clientX, width: currentWidth };
    pendingInspectorWidthRef.current = currentWidth;
    draggingInspectorRef.current = true;
    setInspectorWidthCustomized(true);
    event.currentTarget.setPointerCapture(event.pointerId);
    setDraggingInspector(true);
    event.preventDefault();
  };

  const moveInspectorResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!draggingInspectorRef.current) return;
    pendingInspectorWidthRef.current = inspectorResizeStartRef.current.width
      - (event.clientX - inspectorResizeStartRef.current.x);
    if (inspectorResizeFrameRef.current === null) {
      inspectorResizeFrameRef.current = window.requestAnimationFrame(() => {
        inspectorResizeFrameRef.current = null;
        if (pendingInspectorWidthRef.current !== null) {
          applyInspectorWidth(pendingInspectorWidthRef.current);
        }
      });
    }
    event.preventDefault();
  };

  const endInspectorResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!draggingInspectorRef.current) return;
    if (inspectorResizeFrameRef.current !== null) {
      window.cancelAnimationFrame(inspectorResizeFrameRef.current);
      inspectorResizeFrameRef.current = null;
    }
    const finalWidth = applyInspectorWidth(
      pendingInspectorWidthRef.current ?? currentInspectorWidthRef.current,
    );
    pendingInspectorWidthRef.current = null;
    draggingInspectorRef.current = false;
    setInspectorWidth(finalWidth);
    setDraggingInspector(false);
    pendingPlayerSizeRef.current = null;
    const stageBounds = stageRef.current?.getBoundingClientRect();
    if (stageBounds) playerRef.current?.resize(stageBounds.width, stageBounds.height);
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  };

  const resizeInspectorWithKeyboard = (event: React.KeyboardEvent<HTMLDivElement>) => {
    const bounds = inspectorWidthBounds();
    const step = event.shiftKey ? 48 : 24;
    let nextWidth = currentInspectorWidthRef.current;
    if (event.key === "ArrowLeft") nextWidth += step;
    else if (event.key === "ArrowRight") nextWidth -= step;
    else if (event.key === "Home") nextWidth = bounds.minimum;
    else if (event.key === "End") nextWidth = bounds.maximum;
    else return;
    event.preventDefault();
    event.stopPropagation();
    setInspectorWidthCustomized(true);
    const appliedWidth = applyInspectorWidth(nextWidth);
    setInspectorWidth(appliedWidth);
  };

  const handleStageTap = (event: ReactMouseEvent<HTMLDivElement>) => {
    if (stageResizeMovedRef.current) {
      stageResizeMovedRef.current = false;
      lastStageTapRef.current = 0;
      return;
    }
    if (event.detail === 0) {
      setStageResizeMenuActive(true);
      setStageResizeTapOpen(true);
      scheduleStageResizeMenuDismiss();
      return;
    }
    const now = performance.now();
    if (lastStageTapRef.current > 0 && now - lastStageTapRef.current <= policy.gesture.webDoubleClickMs) {
      closeStageResizeTapMenu();
      toggleStageFit();
      return;
    }
    lastStageTapRef.current = now;
  };

  const remainingArtboards = Math.max(0, metadata.artboardCount - metadata.artboardNames.length);
  const hasStageAspect = metadata.width > 0 && metadata.height > 0;
  const stageKeepsSourceAspect = activeFile?.file.format === "rive" && fit === "contain" && hasStageAspect;
  const stageAspect = hasStageAspect ? metadata.width / metadata.height : 1;
  const stageSizingHeight = !stageHeightCustomized
    && typeof window !== "undefined"
    && window.innerWidth >= WIDE_LAYOUT_MIN_WIDTH
    ? maximumStageHeight()
    : stageHeight;
  const stageStyle = {
    ...(stageKeepsSourceAspect ? {
        width: `min(100%, ${Math.round(stageSizingHeight * stageAspect)}px)`,
        aspectRatio: `${metadata.width} / ${metadata.height}`,
      }
      : { width: "100%", height: `${stageHeight}px` }),
    "--manual-stage-height": `${stageSizingHeight}px`,
  } as CSSProperties & { "--manual-stage-height": string };
  const previewWorkbenchStyle = {
    "--preview-inspector-width": `${inspectorWidth}px`,
  } as CSSProperties;
  const isPublicRoute = Boolean(shareCode && !publicRouteDetached);
  const uploadBusy = importBusy;
  const homeHref = viewerHomePath(import.meta.env.BASE_URL);
  const selectTimeline = useCallback((name: string) => {
    playerRef.current?.selectAnimation(name);
  }, []);
  const selectTimelineFromControl = useCallback((name: string) => {
    playerRef.current?.selectAnimation(name);
    commentTimelineInsertionIdRef.current += 1;
    setCommentTimelineInsertion({ id: commentTimelineInsertionIdRef.current, name });
  }, []);
  const commentsPanel = publicShare && publicShare.status === "active" ? (
    <ShareCommentsPanel
      comments={comments}
      loading={commentsLoading}
      loadError={commentsLoadError}
      submitError={commentSubmitError}
      submitting={commentSubmitting}
      actionBusyId={commentActionBusyId}
      actionError={commentActionError}
      timelines={metadata.animations}
      timelineInsertion={commentTimelineInsertion}
      versions={activeHostedVersions}
      activeVersionId={activeHostedVersion?.id || ""}
      onRetry={() => setCommentsReload((current) => current + 1)}
      onSubmit={submitComment}
      onArchive={(comment) => changeCommentStatus(comment, "archive")}
      onRestore={(comment) => changeCommentStatus(comment, "restore")}
      onSelectTimeline={selectTimeline}
      onSelectVersion={selectHostedVersion}
    />
  ) : null;

  const fileActions: FileActionsProps = {
    hostedMode: isHostedPlatform,
    uploadBusy,
    versionUploading,
    archiveBusy: Boolean(hostedBusyCode),
    onShare: shareFile,
    onPublish: requestPublishFile,
    onArchive: setPendingArchiveShare,
    onUploadVersion: (item) => {
      if (item.hostedCode) requestVersionUpload({ code: item.hostedCode, format: item.share?.format || item.file.format || "rive" });
    },
  };

  if (isPublicRoute && publicShareState !== "ready" && !activeFile) {
    const kind = publicShareState === "archived" ? "archived" : publicShareState === "error" ? "error" : "loading";
    return (
      <main className="app-shell public-state-shell">
        <header className="topbar">
          <Brand hosted={isHostedPlatform} label="Rive 预览台" href={homeHref} />
        </header>
        <PublicShareState
          kind={kind}
          title={kind === "archived" ? "文件已归档" : kind === "error" ? "公开链接无法打开" : "正在打开公开文件"}
          message={kind === "archived"
            ? `${publicShare ? hostedShareName(publicShare) : "这个文件"} 已停止播放和评论，恢复后原链接仍可使用。`
            : kind === "error"
              ? publicShareError || "请检查链接后重试。"
              : publicShare
                ? `${hostedShareName(publicShare)} · ${formatBytes(publicShare.size)}`
                : "正在读取文件信息。"}
          progress={kind === "loading" ? loading.progress : undefined}
          progressLabel={kind === "loading" ? loading.phase : undefined}
          onRetry={kind === "error" ? () => setPublicShareReload((current) => current + 1) : undefined}
          homeHref={homeHref}
        />
        {engineToast && <EngineToast message={engineToast} />}
      </main>
    );
  }

  return (
    <main
      className={`app-shell ${activeFile ? "preview-shell" : ""} ${isPublicRoute ? "public-share-shell" : ""}`}
      onDragEnter={enterDropTarget}
      onDragOver={showDropTarget}
      onDragLeave={hideDropTarget}
      onDrop={dropFiles}
    >
      <input
        ref={fileInputRef}
        className="sr-only"
        type="file"
        accept={SUPPORTED_ANIMATION_ACCEPT}
        multiple
        disabled={uploadBusy}
        onChange={importFiles}
      />
      {hostedVersioningEnabled && (
        <input
          ref={versionInputRef}
          className="sr-only"
          type="file"
          accept={SUPPORTED_ANIMATION_ACCEPT}
          disabled={versionUploading}
          onChange={(event) => void updateHostedVersion(event)}
        />
      )}
      {activeFile && dropActive && (
        <div className="detail-drop-overlay" role="status" aria-live="polite">
          <span><Icon name="cloud-arrow-up" size={24} /></span>
          <strong>松开后立即打开并上传</strong>
          <small>支持 Rive、Lottie JSON、PAG（PAG ≤ 10 MiB）</small>
        </div>
      )}
      {activeFile ? (
        <>
          <header className="topbar preview-topbar">
            <button
              className="topbar-back"
              onClick={closeActiveFile}
              aria-label="返回文件列表"
              aria-keyshortcuts="Escape"
              title="返回文件列表 (Esc)"
            >
              <Icon name="arrow-left" size={21} />
            </button>
            <Brand hosted={isHostedPlatform} label="Rive 预览台" />
            <div className="topbar-actions preview-actions">
              {isHostedPlatform && activeHostedShare?.status === "active" && (
                <button
                  className="topbar-action topbar-archive press-feedback"
                  type="button"
                  onClick={() => setPendingArchiveShare(activeHostedShare)}
                  disabled={Boolean(hostedBusyCode) || versionUploading}
                  aria-label="归档当前文件"
                  aria-keyshortcuts="Delete Backspace"
                  data-shortcut-tip="归档文件 · Delete"
                >
                  <Icon name="archive" size={18} /><span className="topbar-action-label">归档</span>
                </button>
              )}
              <button
                className="topbar-action topbar-download press-feedback"
                onClick={() => downloadFile(activeFile.file, activeHostedCode || undefined, activeHostedVersion?.id)}
                aria-label="下载当前文件"
                data-shortcut-tip={`下载文件 · ${fileShortcutModifier()} E`}
                aria-keyshortcuts="Meta+E Control+E"
              >
                <Icon name="download-simple" size={18} /><span className="topbar-action-label">下载</span>
              </button>
              {hostedVersioningEnabled && activeHostedCode && (
                <button
                  className="topbar-action topbar-version-update press-feedback"
                  type="button"
                  onClick={() => requestVersionUpload({ code: activeHostedCode, format: activeHostedShare?.format || activeFile.file.format || "rive" })}
                  disabled={versionUploading}
                  aria-label="更新文件版本"
                  data-shortcut-tip={`上传新版本 · ${fileShortcutModifier()} U`}
                  aria-keyshortcuts="Meta+U Control+U"
                >
                  <Icon name="cloud-arrow-up" size={18} />
                  <span className="topbar-action-label">
                    {versionUploading ? `${versionUploadProgress}%` : "上传新版本"}
                  </span>
                </button>
              )}
              {activeHostedCode && (
                <button
                  className={`topbar-action topbar-copy-link press-feedback ${activeDetailCopyStatus === "copied" ? "is-copied" : ""}`}
                  onClick={() => void copyActiveHostedLink()}
                  aria-label={activeDetailCopyStatus === "copied" ? "链接已复制" : "复制当前文件链接"}
                  data-shortcut-tip="复制链接 · L"
                  aria-keyshortcuts="L"
                >
                  <Icon name={detailCopyIcon} size={18} />
                  <span aria-live="polite">{detailCopyLabel}</span>
                </button>
              )}
              <ShortcutHelp hosted={isHostedPlatform} />
            </div>
          </header>
          <header className="topbar drawer-home-topbar">
            <Brand hosted={isHostedPlatform} label="Rive 预览台" href={homeHref} />
            <div className="topbar-actions"><ShortcutHelp hosted={isHostedPlatform} /></div>
          </header>
        </>
      ) : (
        <header className="topbar">
          <Brand hosted={isHostedPlatform} label="Rive 预览台" />
          <div className="topbar-actions">
            <ShortcutHelp hosted={isHostedPlatform} />
          </div>
        </header>
      )}

      <div className={`drawer-workspace ${activeFile ? "is-open" : ""} ${isPublicRoute ? "is-public" : ""}`}>
        <div className="drawer-home-pane">
          {activeFile ? (
            <PreviewFileRail
              items={unifiedFiles}
              activeFile={activeFile}
              coverUrls={coverUrls}
              uploadStates={uploadStates}
              uploadBusy={uploadBusy}
              importError={importError}
              onContextMenu={openFileContextMenu}
              onAdd={() => fileInputRef.current?.click()}
              onOpen={(item) => openUnifiedFile(item, "preserve")}
              onRetry={(fileId) => void retryFileUpload(fileId)}
            />
          ) : <section className="library-page">
            <button
              type="button"
              className={`import-dropzone press-feedback-large ${dropActive ? "is-dragging" : ""} ${uploadBusy ? "is-busy" : ""}`}
              aria-disabled={uploadBusy}
              onClick={() => {
                if (!uploadBusy) fileInputRef.current?.click();
              }}
            >
              <span className="import-mark"><Icon name="plus" size={24} /></span>
              <span>{isHostedPlatform ? "上传动效文件" : "导入动效文件"}</span>
              <small>{isHostedPlatform
                ? "支持 Rive / Lottie / PAG，PAG 不超过 10 MiB"
                : "支持 Rive / Lottie / PAG，只保存在当前浏览器"}</small>
            </button>
            {importError && <div className="inline-error import-error" role="alert">{importError}</div>}
            {versionUploading && <div className="version-upload-status" role="status">正在上传新版本 {versionUploadProgress}%</div>}
            {versionUploadError && <div className="version-upload-error" role="alert">{versionUploadError}</div>}

            {error && !activeFile && <div className="inline-error">{error}</div>}

            <div className="section-heading">
              <h1>最近文件</h1>
              <div className="section-heading-actions">
                <span>{unifiedFiles.length} 个</span>
                {isHostedPlatform && (
                  <button
                    className="archived-library-trigger press-feedback"
                    type="button"
                    onClick={() => {
                      setArchivedDialogOpen(true);
                      void refreshHostedLibrary();
                    }}
                    aria-haspopup="dialog"
                    aria-expanded={archivedDialogOpen}
                    aria-controls="archived-library-dialog"
                  >
                    <Icon name="archive" size={15} />
                    <span>已归档</span>
                    <span className="archived-library-count">{hostedLibrary.archivedItems.length}</span>
                  </button>
                )}
              </div>
            </div>
            <LibraryList
              items={unifiedFiles}
              coverUrls={coverUrls}
              expandedFileId={expandedFileId}
              activeFile={activeFile}
              actions={fileActions}
              onContextMenu={openFileContextMenu}
              uploadStates={uploadStates}
              uploadBusy={uploadBusy}
              onOpen={openUnifiedFile}
              onRetry={(fileId) => void retryFileUpload(fileId)}
              onToggleMenu={(id) => { closeFileContextMenu(); setExpandedFileId(expandedFileId === id ? "" : id); }}
            />
            {hostingError && <div className="inline-error hosting-error" role="alert">{hostingError}</div>}
            <div className="library-footer-actions">
              <MiniProgramEntry />
              <FeedbackContact />
            </div>
          </section>}
        </div>

      {activeFile && <section className="preview-page drawer-preview-panel">
        <div className="file-heading">
          <button
            className="drawer-close"
            onClick={closeActiveFile}
            aria-label="关闭文件详情"
            aria-keyshortcuts="Escape"
            title="关闭文件详情 (Esc)"
          >
            <Icon name="x" size={21} />
          </button>
          <div className="file-heading-copy">
            <HostedFileName
              key={`${activeHostedCode}-${activeFile.sessionId}`}
              name={activeDisplayName}
              editable={Boolean(activeHostedCode && activeHostedShare?.status === "active"
                && !versionUploading && !loading.active)}
              onRename={renameActiveHostedFile}
            />
            <div className="file-heading-meta">
              <span>{formatBytes(activeFile.file.size)}</span>
              {metadata.width > 0 && <span>{Math.round(metadata.width)} × {Math.round(metadata.height)}</span>}
              <PlaybackMeta telemetry={telemetry} />
            </div>
            {versionUploading && (
              <div className="version-upload-status" role="status">正在上传新版本 {versionUploadProgress}%</div>
            )}
            {versionUploadError && <div className="version-upload-error" role="alert">{versionUploadError}</div>}
          </div>
          <div className="file-heading-actions">
            {isHostedPlatform && activeHostedShare?.status === "active" && (
              <button className="file-heading-archive press-feedback" type="button"
                onClick={() => setPendingArchiveShare(activeHostedShare)}
                disabled={Boolean(hostedBusyCode) || versionUploading}
                aria-label="归档当前文件" aria-keyshortcuts="Delete Backspace" data-shortcut-tip="归档文件 · Delete">
                <Icon name="archive" size={18} />
              </button>
            )}
            <button
              className="file-heading-download press-feedback"
              onClick={() => downloadFile(activeFile.file, activeHostedCode || undefined, activeHostedVersion?.id)}
              aria-label="下载当前文件"
              data-shortcut-tip={`下载文件 · ${fileShortcutModifier()} E`}
              aria-keyshortcuts="Meta+E Control+E"
            >
              <Icon name="download-simple" size={18} />
            </button>
            {hostedVersioningEnabled && activeHostedCode && (
              <button
                className="file-heading-version-update press-feedback"
                type="button"
                onClick={() => requestVersionUpload({ code: activeHostedCode, format: activeHostedShare?.format || activeFile.file.format || "rive" })}
                disabled={versionUploading}
                aria-label="更新文件版本"
                data-shortcut-tip={`上传新版本 · ${fileShortcutModifier()} U`}
                aria-keyshortcuts="Meta+U Control+U"
              >
                <Icon name="cloud-arrow-up" size={18} />
                <span>{versionUploading ? `${versionUploadProgress}%` : "上传新版本"}</span>
              </button>
            )}
            {activeHostedCode && (
              <button
                className={`file-heading-copy-link press-feedback ${activeDetailCopyStatus === "copied" ? "is-copied" : ""}`}
                onClick={() => void copyActiveHostedLink()}
                aria-label={activeDetailCopyStatus === "copied" ? "链接已复制" : "复制当前文件链接"}
                data-shortcut-tip="复制链接 · L"
                aria-keyshortcuts="L"
              >
                <Icon name={detailCopyIcon} size={18} />
                <span aria-live="polite">{detailCopyLabel}</span>
              </button>
            )}
          </div>
        </div>

        <div
          ref={previewWorkbenchRef}
          className={`preview-workbench ${draggingInspector ? "is-resizing-columns" : ""}`}
          style={previewWorkbenchStyle}
        >
          <div className={`preview-main-column ${stageHeightCustomized ? "is-stage-height-customized" : ""}`}>
            <div
              ref={stageRef}
              className={`canvas-card tone-${canvasTone} ${stageKeepsSourceAspect ? "is-proportional" : ""}`}
              style={stageStyle}
            >
              <canvas
                key={`${activeFile.file.format}-${canvasGeneration}`}
                ref={canvasRef}
                className={activeFile.file.format === "lottie" ? "is-surface-hidden" : ""}
                aria-label={`${animationFormatLabel(activeFile.file.format)} 动效画布`}
                onPointerDown={(event) => canvasPointer("down", event)}
                onPointerMove={(event) => canvasPointer("move", event)}
                onPointerUp={(event) => canvasPointer("up", event)}
                onPointerCancel={(event) => canvasPointer("exit", event)}
                onPointerLeave={(event) => canvasPointer("exit", event)}
              />
              <div
                ref={lottieContainerRef}
                className={`lottie-surface ${activeFile.file.format === "lottie" ? "is-active" : ""}`}
                aria-hidden={activeFile.file.format !== "lottie"}
              />
              {loading.active && (
                <div className="canvas-state loading-state">
                  <div className="loading-ring">
                    <span>{loading.progress}%</span>
                  </div>
                  <p>{loading.phase}</p>
                  <div className="loading-track"><i style={{ width: `${loading.progress}%` }} /></div>
                </div>
              )}
              {error && (
                <div className="canvas-state error-state">
                  <strong>动效文件未能加载</strong>
                  <p>{error}</p>
                  <button onClick={reloadActiveFile}>重新加载</button>
                </div>
              )}
            </div>

            <div
              ref={eventTargetStageResizerRef}
              className={`stage-resizer ${draggingStage ? "is-dragging" : ""} ${stageResizeMenuActive ? "is-selecting" : ""} ${stageResizeTapOpen ? "is-tap-open" : ""} ${stageResizePressActive ? "is-press-active" : ""}`}
              onPointerDown={beginStageResize}
              onPointerMove={moveStageResize}
              onPointerUp={endStageResize}
              onPointerCancel={endStageResize}
              onClick={handleStageTap}
              role="slider"
              tabIndex={0}
              aria-label="单击展开完整或铺满并在三秒后收起，上下拖动画布高度，按住后左右滑动选择，双击切换完整或铺满"
              aria-valuemin={STAGE_MIN_HEIGHT}
              aria-valuemax={Math.round(maximumStageHeight())}
              aria-valuenow={Math.round(stageSizingHeight)}
            >
              <span className="stage-resizer-grip" />
              <div className="stage-resizer-modes" aria-hidden={!stageResizeMenuActive}>
                  <button
                    className={`stage-resizer-mode mode-contain ${fit === "contain" ? "is-current" : ""} ${stageResizeHoverFit === "contain" ? "is-hovered" : ""}`}
                    tabIndex={stageResizeMenuActive ? 0 : -1}
                    onPointerDown={(event) => event.stopPropagation()}
                    onClick={(event) => { event.stopPropagation(); selectFit("contain"); closeStageResizeTapMenu(); }}
                  >
                    <Icon name="arrows-in-simple" size={18} /><span>完整</span>
                  </button>
                  <button
                    className={`stage-resizer-mode mode-cover ${fit === "cover" ? "is-current" : ""} ${stageResizeHoverFit === "cover" ? "is-hovered" : ""}`}
                    tabIndex={stageResizeMenuActive ? 0 : -1}
                    onPointerDown={(event) => event.stopPropagation()}
                    onClick={(event) => { event.stopPropagation(); selectFit("cover"); closeStageResizeTapMenu(); }}
                  >
                    <Icon name="arrows-out-simple" size={18} /><span>铺满</span>
                  </button>
              </div>
            </div>

            <div className="transport">
              <div className="transport-playback">
                <button className="icon-button press-feedback" onClick={resetPlayback} aria-label="重播" aria-keyshortcuts="R" title="重播 (R)">
                  <Icon name="arrow-counter-clockwise" size={20} />
                </button>
                <button className="icon-button press-feedback" onClick={togglePlayback} aria-label={playing ? "暂停" : "播放"} aria-keyshortcuts="Space" title={`${playing ? "暂停" : "播放"} (空格)`}>
                  {playing ? <Icon name="pause" size={20} /> : <Icon name="play" size={20} />}
                </button>
              </div>
              <PlaybackSpeedMenu value={speed} onChange={setSpeed} />
              <div className="transport-files">
                <button className="press-feedback" disabled={activeIndex <= 0} onClick={() => navigateFile(-1)} aria-label="上一个文件" aria-keyshortcuts="ArrowLeft ArrowUp" title="上一个文件 (← / ↑)">
                  <Icon name="arrow-left" size={18} />
                </button>
                <button className="press-feedback" disabled={activeIndex < 0 || activeIndex >= unifiedFiles.length - 1} onClick={() => navigateFile(1)} aria-label="下一个文件" aria-keyshortcuts="ArrowRight ArrowDown" title="下一个文件 (→ / ↓)">
                  <Icon name="arrow-right" size={18} />
                </button>
              </div>
            </div>
          </div>

          <div
            ref={previewColumnResizerRef}
            className="preview-column-resizer"
            role="separator"
            tabIndex={0}
            aria-label="调整画面与右侧栏的宽度"
            aria-controls="preview-inspector"
            aria-orientation="vertical"
            aria-valuemin={WIDE_INSPECTOR_MIN_WIDTH}
            aria-valuemax={inspectorWidthMaximum}
            aria-valuenow={inspectorWidth}
            aria-valuetext={`右侧栏宽度 ${inspectorWidth} 像素`}
            title="左右拖动调整两栏比例"
            onPointerDown={beginInspectorResize}
            onPointerMove={moveInspectorResize}
            onPointerUp={endInspectorResize}
            onPointerCancel={endInspectorResize}
            onKeyDown={resizeInspectorWithKeyboard}
          >
            <span />
          </div>

          <aside ref={previewInspectorRef} id="preview-inspector" className="preview-inspector" aria-label="评论与预览参数">
            <div className="control-panel">
          {activeFile.file.format === "rive" && <RuntimeEventConsole log={runtimeEventLog} />}
          {isPublicRoute && commentsPanel && (
            <div className="public-comments-inline">{commentsPanel}</div>
          )}

          {activeFile.file.format === "rive" && <ParameterRow label="画板">
            {metadata.artboardNames.map((name) => (
              <Tag key={name} selected={metadata.activeArtboard === name} onClick={() => playerRef.current?.selectArtboard(name)}>{name}</Tag>
            ))}
            {!metadata.artboardCatalogLoaded && remainingArtboards > 0 && (
              <button className="disclosure-tag" onClick={expandCatalog} disabled={catalogLoading}>
                {catalogLoading && <i style={{ width: `${catalogProgress}%` }} />}
                <span>{catalogLoading ? `正在解析 ${catalogProgress}%` : `展开其余 ${remainingArtboards} 个`}</span>
              </button>
            )}
          </ParameterRow>}

          {activeFile.file.format === "rive" && <ParameterRow label="状态机">
            {metadata.stateMachines.length ? metadata.stateMachines.map((name) => (
              <Tag key={name} selected={metadata.activeStateMachine === name} onClick={() => playerRef.current?.selectStateMachine(name)}>{name}</Tag>
            )) : <EmptyTag>无状态机</EmptyTag>}
          </ParameterRow>}

          <TimelineControl
            key={activeFile.sessionId}
            telemetry={telemetry}
            animations={metadata.animations}
            activeAnimation={metadata.activeAnimation}
            onSelect={selectTimelineFromControl}
          />

          {activeFile.file.format === "rive" && <ParameterRow label="状态机输入">
            {metadata.inputs.length ? metadata.inputs.map((input) => (
              input.type === "number" ? (
                <label className="number-tag" key={`${input.name}-${input.index}`}>
                  <span>{input.name}</span>
                  <input
                    aria-label={`${input.name} 数值`}
                    type="number"
                    step="0.1"
                    value={Number(input.value || 0)}
                    onChange={(event) => handleInput(input, Number(event.target.value))}
                  />
                </label>
              ) : (
                <Tag
                  key={`${input.name}-${input.index}`}
                  selected={input.type === "boolean" && Boolean(input.value)}
                  onClick={() => handleInput(input)}
                >
                  {input.name}{input.type === "boolean" ? ` ${input.value ? "开" : "关"}` : ""}
                </Tag>
              )
            )) : <EmptyTag>无输入</EmptyTag>}
          </ParameterRow>}

          <ParameterRow label="预览背景">
            {CANVAS_TONES.map((tone) => (
              <button
                key={tone.key}
                className={`tone-button press-feedback tone-${tone.key} ${canvasTone === tone.key ? "is-active" : ""}`}
                aria-label={`${tone.label}背景`}
                aria-pressed={canvasTone === tone.key}
                onClick={() => setCanvasTone(tone.key)}
              />
            ))}
          </ParameterRow>

          {metadata.hasAudio && (
            <ParameterRow label="声音">
              <Tag
                selected={metadata.audioEnabled}
                onClick={() => playerRef.current?.setAudioEnabled(!metadata.audioEnabled)}
              >
                {metadata.audioEnabled ? <Icon name="speaker-high" size={16} /> : <Icon name="speaker-slash" size={16} />}
                {metadata.audioEnabled ? "开启" : "静音"}
              </Tag>
            </ParameterRow>
          )}

          {activeFile.file.format !== "lottie" && <ParameterRow label="渲染质量">
            <Tag subtleSelected selected={quality === 1} onClick={() => setQuality(1)}>性能</Tag>
            <Tag subtleSelected selected={quality === 1.5} onClick={() => setQuality(1.5)}>平衡</Tag>
            <Tag subtleSelected selected={quality === 2} onClick={() => setQuality(2)}>高清</Tag>
          </ParameterRow>}
          <ParameterRow label="缩放方式">
            <Tag subtleSelected selected={fit === "contain"} onClick={() => selectFit("contain")}>完整</Tag>
            <Tag subtleSelected selected={fit === "cover"} onClick={() => selectFit("cover")}>铺满</Tag>
          </ParameterRow>
          {activeFile.file.format === "rive" && <ParameterRow label="渲染引擎">
            <Tag subtleSelected selected={renderEngine === "webgl2"} onClick={() => selectRenderEngine("webgl2")}>WebGL2</Tag>
            <Tag subtleSelected selected={renderEngine === "canvas2d"} onClick={() => selectRenderEngine("canvas2d")}>兼容模式</Tag>
          </ParameterRow>}
            </div>
          </aside>
        </div>

      </section>}
      </div>
      {fileContextTarget && <FileContextMenu target={fileContextTarget} actions={fileActions} onClose={closeFileContextMenu} />}
      {isHostedPlatform && pendingArchiveShare && (
        <ArchiveConfirmDialog
          share={pendingArchiveShare}
          busy={hostedBusyCode === pendingArchiveShare.code}
          error={hostedLibrary.error}
          onCancel={() => setPendingArchiveShare(null)}
          onConfirm={() => void confirmPendingArchive()}
        />
      )}
      {isHostedPlatform && !activeFile && archivedDialogOpen && (
        <ArchivedLibraryDialog
          archivedItems={hostedLibrary.archivedItems}
          loading={hostedLibrary.loading}
          error={hostedLibrary.error}
          busyCode={hostedBusyCode}
          onRefresh={refreshHostedLibrary}
          onRestore={restoreShare}
          onClose={() => setArchivedDialogOpen(false)}
        />
      )}
      {isHostedPlatform && publishedShare && (
        <ShareActionsDialog
          dialogId="published-share-actions-dialog"
          share={publishedShare}
          onDownload={() => downloadFile({
            id: `hosted-${publishedShare.code}`,
            name: publishedShare.filename,
            size: publishedShare.size,
            format: publishedShare.format,
            updatedAt: Date.parse(publishedShare.createdAt) || Date.now(),
            hostedCode: publishedShare.code,
          }, publishedShare.code)}
          onClose={() => setPublishedShare(null)}
        />
      )}
      {engineToast && <EngineToast message={engineToast} />}
      <ActionTooltip />
    </main>
  );
}

function EngineToast({ message }: { message: string }) {
  return (
    <div className="engine-toast" role="status" aria-live="polite">
      {message}
    </div>
  );
}

function Brand({ label, href, hosted }: { label: string; href?: string; hosted: boolean }) {
  const content = (
    <>
      {/* 与浏览器页签复用同一份本地图标，避免品牌图形分叉。 */}
      <img className="brand-mark" src={`${publicAssetUrl("favicon.webp")}?v=3`} alt="" />
      <span className="brand-title">{label}</span>
      {hosted && <small className="brand-signature">for JOJO</small>}
    </>
  );
  if (href) {
    return <a className="brand brand-link" href={href} title="返回文件列表">{content}</a>;
  }
  return <div className="brand">{content}</div>;
}

function FeedbackContact() {
  return <p className="feedback-credit">反馈意见：杨皓棱</p>;
}

function MiniProgramEntry() {
  const [open, setOpen] = useState(false);
  const entryRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const closeOutside = (event: PointerEvent) => {
      if (entryRef.current?.contains(event.target as Node)) return;
      setOpen(false);
      entryRef.current?.querySelector("button")?.blur();
    };
    document.addEventListener("pointerdown", closeOutside);
    return () => document.removeEventListener("pointerdown", closeOutside);
  }, [open]);

  return (
    <div
      ref={entryRef}
      className={`mini-program-entry ${open ? "is-open" : ""}`}
      onKeyDown={(event) => {
        if (event.key !== "Escape") return;
        setOpen(false);
        (event.currentTarget.querySelector("button") as HTMLButtonElement | null)?.blur();
      }}
    >
      <button
        className="mini-program-trigger press-feedback"
        aria-expanded={open}
        aria-controls="mini-program-card"
        aria-label="查看 Rive 预览台小程序码"
        onClick={() => setOpen((current) => !current)}
      >
        <Icon name="wechat-logo" size={16} />
        <span>小程序</span>
      </button>
      <div id="mini-program-card" className="mini-program-popover" role="group" aria-label="Rive 预览台小程序码">
        <strong>Rive 预览台</strong>
        <span>微信扫码打开小程序</span>
        {/* 小程序码由杨总提供，转为本地 WebP 后随静态站点发布。 */}
        <img src={publicAssetUrl("mini-program-code.webp")} alt="Rive 预览台小程序码" />
      </div>
    </div>
  );
}

function PlaybackSpeedMenu({
  value,
  onChange,
}: {
  value: number;
  onChange: (value: number) => void;
}) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return undefined;
    const closeOnOutsidePointer = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    };
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      setOpen(false);
      triggerRef.current?.focus();
    };
    document.addEventListener("pointerdown", closeOnOutsidePointer);
    document.addEventListener("keydown", closeOnEscape);
    const focusFrame = window.requestAnimationFrame(() => {
      rootRef.current?.querySelector<HTMLButtonElement>('[role="option"][aria-selected="true"]')?.focus();
    });
    return () => {
      window.cancelAnimationFrame(focusFrame);
      document.removeEventListener("pointerdown", closeOnOutsidePointer);
      document.removeEventListener("keydown", closeOnEscape);
    };
  }, [open]);

  const selectSpeed = (nextSpeed: number) => {
    onChange(nextSpeed);
    setOpen(false);
    window.requestAnimationFrame(() => triggerRef.current?.focus());
  };

  return (
    <div ref={rootRef} className={`speed-menu ${open ? "is-open" : ""}`}>
      <button
        ref={triggerRef}
        type="button"
        className="speed-menu-trigger press-feedback"
        aria-label={`播放速度 ${value} 倍`}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-keyshortcuts="+ -"
        title="调整播放速度 (+ / -)"
        onClick={() => setOpen((current) => !current)}
        onKeyDown={(event) => {
          if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return;
          event.preventDefault();
          setOpen(true);
        }}
      >
        <Icon name="gauge" size={18} className="speed-gauge" />
        <span className="speed-menu-value">{value}x</span>
        <Icon name="caret-down" size={13} className="speed-menu-caret" />
      </button>
      {open && (
        <div className="speed-menu-popover" role="listbox" aria-label="选择播放速度">
          {SPEEDS.map((speedOption, optionIndex) => (
            <button
              key={speedOption}
              type="button"
              className="speed-menu-option"
              role="option"
              aria-selected={speedOption === value}
              onClick={() => selectSpeed(speedOption)}
              onKeyDown={(event) => {
                if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) return;
                event.preventDefault();
                const options = Array.from(
                  rootRef.current?.querySelectorAll<HTMLButtonElement>('[role="option"]') || [],
                );
                const nextIndex = event.key === "Home"
                  ? 0
                  : event.key === "End"
                    ? options.length - 1
                    : (optionIndex + (event.key === "ArrowDown" ? 1 : -1) + options.length) % options.length;
                options[nextIndex]?.focus();
              }}
            >
              <span>{speedOption}x</span>
              {speedOption === value && <Icon name="check" size={14} />}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function ShortcutHelp({ hosted }: { hosted: boolean }) {
  const [open, setOpen] = useState(false);
  const popoverId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    const closeOutside = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    };
    const closeOnEscape = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      event.preventDefault();
      event.stopImmediatePropagation();
      setOpen(false);
      buttonRef.current?.blur();
    };
    document.addEventListener("pointerdown", closeOutside);
    window.addEventListener("keydown", closeOnEscape, true);
    return () => {
      document.removeEventListener("pointerdown", closeOutside);
      window.removeEventListener("keydown", closeOnEscape, true);
    };
  }, [open]);

  return (
    <div ref={rootRef} className={`shortcut-help ${open ? "is-open" : ""}`}>
      <button
        ref={buttonRef}
        className={`shortcut-button ${open ? "is-active" : ""}`}
        onClick={() => setOpen((current) => !current)}
        aria-label="查看快捷键"
        aria-expanded={open}
        aria-haspopup="dialog"
        aria-controls={popoverId}
      >
        <Icon name="keyboard" size={19} />
      </button>
      <div id={popoverId} className="shortcut-popover" role="dialog" aria-label="快捷键说明">
        <strong>快捷键</strong>
        <div><span>重播</span><kbd>R</kbd></div>
        <div><span>播放 / 暂停</span><kbd>空格</kbd></div>
        <div><span>上一个文件</span><span className="key-group"><kbd>↑</kbd><kbd>←</kbd></span></div>
        <div><span>下一个文件</span><span className="key-group"><kbd>↓</kbd><kbd>→</kbd></span></div>
        <div><span>播放速度</span><span className="key-group"><kbd>-</kbd><kbd>+</kbd></span></div>
        <div><span>返回文件列表</span><kbd>Esc</kbd></div>
        <div><span>下载文件</span><kbd>{fileShortcutModifier()} E</kbd></div>
        {hosted && <>
          <div><span>上传新版本</span><kbd>{fileShortcutModifier()} U</kbd></div>
          <div><span>复制链接</span><kbd>L</kbd></div>
          <div><span>归档当前文件</span><kbd>Delete</kbd></div>
        </>}
      </div>
    </div>
  );
}

function ParameterRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="parameter-row">
      <span className="parameter-label">{label}</span>
      <div className="parameter-actions">{children}</div>
    </div>
  );
}

function Tag({
  selected,
  subtleSelected = false,
  children,
  onClick,
}: {
  selected?: boolean;
  subtleSelected?: boolean;
  children: React.ReactNode;
  onClick: () => void;
}) {
  return (
    <button
      className={`parameter-tag press-feedback ${selected ? "is-selected" : ""} ${subtleSelected ? "is-subtle-selected" : ""}`}
      aria-pressed={selected}
      onClick={onClick}
    >
      <span>{children}</span>
    </button>
  );
}

function EmptyTag({ children }: { children: React.ReactNode }) {
  return <span className="empty-tag">{children}</span>;
}

function isCurrentItem(item: UnifiedFileItem, activeFile: ActiveFile | null): boolean {
  return Boolean(
    activeFile
    && (
      item.localFile?.id === activeFile.file.id
      || item.file.id === activeFile.file.id
      || (activeFile.hostedShare?.code && item.hostedCode === activeFile.hostedShare.code)
    )
  );
}

function FileUploadStatus({
  state,
}: {
  state: FileUploadState;
}) {
  const title = state.phase === "ready"
    ? "已上传到云端"
    : state.phase === "uploading"
      ? `正在上传 ${state.progress}%`
      : state.phase === "error"
        ? "上传失败，查看详情"
        : "只保存在本机";
  const icon: IconName = state.phase === "ready"
    ? "cloud-check"
    : state.phase === "uploading"
      ? "cloud-arrow-up"
      : state.phase === "error"
        ? "cloud-x"
        : "desktop";
  return (
    <span
      className={`file-sync-status is-${state.phase}`}
      role="img"
      aria-label={title}
      title={title}
    >
      <Icon name={icon} size={13} />
    </span>
  );
}

function FileUploadDetail({
  state,
  hostedCode,
  visible,
  retryDisabled,
  onRetry,
}: {
  state: FileUploadState;
  hostedCode?: string;
  visible: boolean;
  retryDisabled: boolean;
  onRetry: () => void;
}) {
  if (!visible) return null;
  if (state.phase === "ready") {
    return (
      <div className="file-upload-detail is-ready" role="status">
        <span>云端已就绪{hostedCode ? ` / ${hostedCode}` : ""}</span>
      </div>
    );
  }
  if (state.phase === "local") {
    return (
      <div className="file-upload-detail is-local" role="status">
        <span>只保存在当前浏览器</span>
      </div>
    );
  }
  const failed = state.phase === "error";
  return (
    <div className={`file-upload-detail ${failed ? "is-error" : "is-uploading"}`} aria-live="polite">
      <div className="file-upload-detail-heading">
        <span>{failed ? state.error || "上传失败" : "正在上传到云端"}</span>
        <b>{state.progress}%</b>
      </div>
      <div className="file-upload-progress-row">
        <span
          className="file-upload-progress"
          role="progressbar"
          aria-label={failed ? "上传失败，等待重试" : "上传进度"}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={state.progress}
        >
          <i style={{ width: `${state.progress}%` }} />
        </span>
        {failed && state.retryable && (
          <button type="button" onClick={onRetry} disabled={retryDisabled}>重试</button>
        )}
      </div>
    </div>
  );
}

function PreviewFileRail({
  items,
  activeFile,
  coverUrls,
  uploadStates,
  uploadBusy,
  importError,
  onAdd,
  onOpen,
  onRetry,
  onContextMenu,
}: {
  items: UnifiedFileItem[];
  activeFile: ActiveFile;
  coverUrls: Map<string, string>;
  uploadStates: Record<string, FileUploadState>;
  uploadBusy: boolean;
  importError: string;
  onAdd: () => void;
  onOpen: (item: UnifiedFileItem) => void;
  onRetry: (fileId: string) => void;
  onContextMenu: (event: ReactMouseEvent<HTMLElement>, item: UnifiedFileItem) => void;
}) {
  const railRef = useRef<HTMLElement>(null);
  const resizeStartRef = useRef({ x: 0, width: FILE_RAIL_DEFAULT_WIDTH });
  const draggingRailRef = useRef(false);
  const [railWidth, setRailWidth] = useState(FILE_RAIL_DEFAULT_WIDTH);
  const [railWidthMaximum, setRailWidthMaximum] = useState(FILE_RAIL_MAX_WIDTH);
  const [draggingRail, setDraggingRail] = useState(false);
  const [fileNameTooltip, setFileNameTooltip] = useState<{ name: string; top: number } | null>(null);

  const railWidthBounds = () => {
    const workspace = railRef.current?.closest<HTMLElement>(".drawer-workspace");
    const availableMaximum = workspace
      ? workspace.clientWidth - FILE_RAIL_PREVIEW_MIN_WIDTH
      : FILE_RAIL_MAX_WIDTH;
    return {
      minimum: FILE_RAIL_MIN_WIDTH,
      maximum: Math.max(FILE_RAIL_MIN_WIDTH, Math.min(FILE_RAIL_MAX_WIDTH, availableMaximum)),
    };
  };

  const applyRailWidth = (width: number) => {
    const bounds = railWidthBounds();
    const nextWidth = Math.round(clamp(width, bounds.minimum, bounds.maximum));
    railRef.current?.closest<HTMLElement>(".drawer-workspace")?.style.setProperty(
      "--preview-file-rail-width",
      `${nextWidth}px`,
    );
    setRailWidthMaximum(Math.round(bounds.maximum));
    setRailWidth(nextWidth);
    return nextWidth;
  };

  const beginRailResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (event.pointerType === "mouse" && event.button !== 0) return;
    const currentWidth = railRef.current?.getBoundingClientRect().width || railWidth;
    resizeStartRef.current = { x: event.clientX, width: currentWidth };
    applyRailWidth(currentWidth);
    draggingRailRef.current = true;
    setDraggingRail(true);
    event.currentTarget.setPointerCapture(event.pointerId);
    event.preventDefault();
  };

  const moveRailResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!draggingRailRef.current) return;
    applyRailWidth(resizeStartRef.current.width + event.clientX - resizeStartRef.current.x);
    event.preventDefault();
  };

  const endRailResize = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (!draggingRailRef.current) return;
    draggingRailRef.current = false;
    setDraggingRail(false);
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  };

  const resizeRailWithKeyboard = (event: React.KeyboardEvent<HTMLDivElement>) => {
    const bounds = railWidthBounds();
    const step = event.shiftKey ? 40 : 20;
    let nextWidth = railWidth;
    if (event.key === "ArrowLeft") nextWidth -= step;
    else if (event.key === "ArrowRight") nextWidth += step;
    else if (event.key === "Home") nextWidth = bounds.minimum;
    else if (event.key === "End") nextWidth = bounds.maximum;
    else return;
    event.preventDefault();
    event.stopPropagation();
    applyRailWidth(nextWidth);
  };

  const showFileNameTooltip = (name: string, target: HTMLElement) => {
    const railBounds = railRef.current?.getBoundingClientRect();
    const targetBounds = target.getBoundingClientRect();
    if (!railBounds) return;
    setFileNameTooltip({
      name,
      top: clamp(
        targetBounds.top - railBounds.top + targetBounds.height / 2,
        24,
        railBounds.height - 24,
      ),
    });
  };

  return (
    <aside ref={railRef} className={`preview-file-rail ${draggingRail ? "is-resizing" : ""}`} aria-label="平台文件">
      <header className="preview-file-rail-header">
        <div><strong>最近文件</strong><span>{items.length}</span></div>
        <button
          type="button"
          className="preview-file-add press-feedback"
          onClick={onAdd}
          disabled={uploadBusy}
          aria-label="选择并上传动效文件"
          title="选择并上传动效文件"
        >
          <Icon name="plus" size={18} />
        </button>
      </header>
      {importError && <div className="rail-import-error" role="alert">{importError}</div>}
      <div className="preview-file-rail-list" onScroll={() => setFileNameTooltip(null)}>
        {items.map((item) => {
          const fileId = item.localFile?.id || item.file.id;
          const state = uploadStateForItem(item, uploadStates);
          const detailVisible = state.phase === "uploading" || state.phase === "error";
          const current = isCurrentItem(item, activeFile);
          return (
            <article
              key={item.key}
              className={`preview-file-rail-row ${current ? "is-current" : ""}`}
              onContextMenu={(event) => { setFileNameTooltip(null); onContextMenu(event, item); }}
              aria-current={current ? "true" : undefined}
            >
              <button
                className="preview-file-row-open press-feedback-large"
                onClick={() => onOpen(item)}
                onFocus={(event) => {
                  const title = event.currentTarget.querySelector<HTMLElement>(".preview-file-title");
                  if (title) showFileNameTooltip(item.file.name, title);
                }}
                onBlur={() => setFileNameTooltip(null)}
                aria-label={`打开 ${item.file.name}`}
              >
                <span className="preview-file-cover-trigger">
                  <span className={`preview-file-cover ${coverUrls.has(item.file.id) ? "has-image" : ""}`} aria-hidden="true">
                    {coverUrls.has(item.file.id)
                      ? <LocalCoverImage src={coverUrls.get(item.file.id)!} />
                      : "RIV"}
                  </span>
                </span>
                <span className="preview-file-rail-copy">
                  <span
                    className="preview-file-title"
                    onPointerEnter={(event) => showFileNameTooltip(item.file.name, event.currentTarget)}
                    onPointerLeave={() => setFileNameTooltip(null)}
                  >
                    {item.file.name}
                  </span>
                  <span className="preview-file-meta">
                    <span>{formatBytes(item.file.size)}</span>
                    <FileUploadStatus state={state} />
                  </span>
                </span>
              </button>
              <FileUploadDetail
                state={state}
                hostedCode={item.hostedCode}
                visible={detailVisible}
                retryDisabled={uploadBusy}
                onRetry={() => onRetry(fileId)}
              />
            </article>
          );
        })}
        {!items.length && <span className="preview-file-rail-empty">还没有文件</span>}
      </div>
      {fileNameTooltip && (
        <span
          className="preview-file-name-tooltip"
          style={{ top: `${fileNameTooltip.top}px` }}
          role="tooltip"
        >
          {fileNameTooltip.name}
        </span>
      )}
      <div
        className="preview-file-rail-resizer"
        role="separator"
        tabIndex={0}
        aria-label="调整最近文件栏宽度"
        aria-orientation="vertical"
        aria-valuemin={FILE_RAIL_MIN_WIDTH}
        aria-valuemax={railWidthMaximum}
        aria-valuenow={railWidth}
        aria-valuetext={`最近文件栏宽度 ${railWidth} 像素`}
        title="左右拖动调整最近文件栏宽度"
        onPointerDown={beginRailResize}
        onPointerMove={moveRailResize}
        onPointerUp={endRailResize}
        onPointerCancel={endRailResize}
        onKeyDown={resizeRailWithKeyboard}
        onClick={(event) => {
          event.stopPropagation();
          event.currentTarget.focus();
        }}
      >
        <span />
      </div>
    </aside>
  );
}

function LibraryList({
  items,
  coverUrls,
  expandedFileId,
  activeFile,
  actions,
  onContextMenu,
  uploadStates,
  uploadBusy,
  onOpen,
  onRetry,
  onToggleMenu,
}: {
  items: UnifiedFileItem[];
  coverUrls: Map<string, string>;
  expandedFileId: string;
  activeFile: ActiveFile | null;
  actions: FileActionsProps;
  onContextMenu: (event: ReactMouseEvent<HTMLElement>, item: UnifiedFileItem) => void;
  uploadStates: Record<string, FileUploadState>;
  uploadBusy: boolean;
  onOpen: (item: UnifiedFileItem) => void;
  onRetry: (fileId: string) => void;
  onToggleMenu: (id: string) => void;
}) {
  if (!items.length) {
    return (
      <div className="file-list recent-files-empty">
        <Icon name="link-simple" size={21} />
        <strong>还没有最近文件</strong>
        <span>查看公开链接或导入文件后会显示在这里。</span>
      </div>
    );
  }
  return (
    <div className="file-list">
      {items.map((item) => {
        const file = item.file;
        const fileId = item.localFile?.id || file.id;
        const state = uploadStateForItem(item, uploadStates);
        const detailVisible = state.phase === "uploading" || state.phase === "error";
        const current = isCurrentItem(item, activeFile);
        return <article
          className={`file-row ${current ? "is-current" : ""} ${expandedFileId === item.key ? "is-menu-open" : ""}`}
          key={item.key}
          onContextMenu={(event) => onContextMenu(event, item)}
          aria-current={current ? "true" : undefined}
        >
          <button className="file-open press-feedback-large" onClick={() => onOpen(item)} aria-label={`打开 ${file.name}`}>
            <span className="file-cover-trigger">
              <span className={`file-cover ${coverUrls.has(file.id) ? "has-image" : ""}`} aria-hidden="true">
                  {coverUrls.has(file.id)
                    ? <LocalCoverImage src={coverUrls.get(file.id)!} />
                    : "RIV"}
              </span>
            </span>
            <span className="file-copy">
              <span className="file-title-line"><strong>{file.name}</strong></span>
              <small className="file-meta-line">
                <span>{formatBytes(file.size)}</span>
                <FileUploadStatus state={state} />
                <span>/ {formatDate(item.activityAt)}</span>
              </small>
            </span>
          </button>
          <div className="file-action">
            <button
              className={`square-button press-feedback ${expandedFileId === item.key ? "is-active" : ""}`}
              aria-label={`操作 ${file.name}`}
              aria-haspopup="menu"
              aria-expanded={expandedFileId === item.key}
              onClick={() => onToggleMenu(item.key)}
            >
              <Icon name="caret-down" size={18} />
            </button>
          </div>
          {detailVisible && (
            <FileUploadDetail
              state={state}
              hostedCode={item.hostedCode}
              visible
              retryDisabled={uploadBusy}
              onRetry={() => onRetry(fileId)}
            />
          )}
          {expandedFileId === item.key && (
            <div className="file-menu" role="menu" aria-label={`${file.name} 的文件操作`}>
              <FileMenuActions item={item} actions={actions} onClose={() => onToggleMenu(item.key)} />
            </div>
          )}
        </article>;
      })}
    </div>
  );
}

function LocalCoverImage({ src }: { src: string }) {
  // Blob 地址完全在本机生成，不能交给远程图片优化服务处理。
  return <img src={src} alt="" />;
}
