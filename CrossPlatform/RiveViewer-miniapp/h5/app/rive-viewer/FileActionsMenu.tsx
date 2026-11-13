import { useEffect, useLayoutEffect, useRef } from "react";
import { createPortal } from "react-dom";
import type { HostedShare } from "../../lib/hosted-api";
import type { LibraryFile } from "../../lib/library";
import type { UnifiedFileItem } from "../../lib/unified-library";
import { Icon } from "./Icon";

export type FileActionsProps = {
  hostedMode: boolean;
  uploadBusy: boolean;
  versionUploading: boolean;
  archiveBusy: boolean;
  onShare: (file: LibraryFile, hostedCode?: string) => void;
  onPublish: (file: LibraryFile) => void;
  onArchive: (share: HostedShare) => void;
  onUploadVersion: (item: UnifiedFileItem) => void;
};

export function FileMenuActions({ item, actions, onClose }: {
  item: UnifiedFileItem;
  actions: FileActionsProps;
  onClose: () => void;
}) {
  const run = (action: () => void) => { onClose(); action(); };
  return <>
    {actions.hostedMode && (
      <button role="menuitem" className="press-feedback" disabled={actions.uploadBusy}
        onClick={() => run(() => actions.onPublish(item.localFile || item.file))}>
        <Icon name="link-simple" size={17} />
        {item.hostedCode ? "复制公开链接" : "上传并生成链接"}
      </button>
    )}
    <button role="menuitem" className="press-feedback"
      onClick={() => run(() => actions.onShare(item.localFile || item.file, item.hostedCode))}>
      <Icon name={item.hostedCode ? "download-simple" : "share-network"} size={17} />
      {item.hostedCode ? "下载文件" : "发送文件"}
    </button>
    {actions.hostedMode && item.hostedCode && (
      <button role="menuitem" className="press-feedback" disabled={actions.versionUploading || actions.uploadBusy || item.share?.status === "archived"}
        onClick={() => run(() => actions.onUploadVersion(item))}>
        <Icon name="cloud-arrow-up" size={17} />上传新版本
      </button>
    )}
    {actions.hostedMode && item.share?.status === "active" && (
      <button role="menuitem" className="press-feedback hosted-archive" disabled={actions.archiveBusy || actions.versionUploading}
        onClick={() => run(() => actions.onArchive(item.share!))}>
        <Icon name="archive" size={17} />归档文件
      </button>
    )}
  </>;
}

export type FileContextTarget = { item: UnifiedFileItem; x: number; y: number; trigger: HTMLElement };

export function FileContextMenu({ target, actions, onClose }: {
  target: FileContextTarget;
  actions: FileActionsProps;
  onClose: () => void;
}) {
  const menuRef = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    const menu = menuRef.current;
    if (!menu) return;
    const bounds = menu.getBoundingClientRect();
    menu.style.left = `${Math.max(8, Math.min(target.x, window.innerWidth - bounds.width - 8))}px`;
    menu.style.top = `${Math.max(8, Math.min(target.y, window.innerHeight - bounds.height - 8))}px`;
    menu.querySelector<HTMLButtonElement>("button:not(:disabled)")?.focus();
  }, [target]);

  useEffect(() => {
    const closeOutside = (event: PointerEvent) => {
      if (!menuRef.current?.contains(event.target as Node)) onClose();
    };
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape" || event.key === "Tab") {
        if (event.key === "Escape") event.preventDefault();
        event.stopImmediatePropagation();
        target.trigger.querySelector<HTMLButtonElement>("button")?.focus();
        onClose();
        return;
      }
      const buttons = Array.from(menuRef.current?.querySelectorAll<HTMLButtonElement>("button:not(:disabled)") || []);
      if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key) || !buttons.length) return;
      event.preventDefault();
      event.stopImmediatePropagation();
      const index = buttons.indexOf(document.activeElement as HTMLButtonElement);
      const next = event.key === "Home" ? 0 : event.key === "End" ? buttons.length - 1
        : (index + (event.key === "ArrowDown" ? 1 : -1) + buttons.length) % buttons.length;
      buttons[next]?.focus();
    };
    const closeOnScroll = (event: Event) => {
      if (!menuRef.current?.contains(event.target as Node)) onClose();
    };
    document.addEventListener("pointerdown", closeOutside);
    window.addEventListener("keydown", handleKey, true);
    window.addEventListener("resize", onClose);
    window.addEventListener("scroll", closeOnScroll, true);
    return () => {
      document.removeEventListener("pointerdown", closeOutside);
      window.removeEventListener("keydown", handleKey, true);
      window.removeEventListener("resize", onClose);
      window.removeEventListener("scroll", closeOnScroll, true);
    };
  }, [onClose, target]);

  return createPortal(
    <div ref={menuRef} className="file-menu file-context-menu" role="menu" aria-label={`${target.item.file.name} 的文件操作`}
      style={{ left: target.x, top: target.y }} onContextMenu={(event) => event.preventDefault()}>
      <FileMenuActions item={target.item} actions={actions} onClose={onClose} />
    </div>, document.body,
  );
}
