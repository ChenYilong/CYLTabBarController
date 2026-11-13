export function usesCommandKey(platform: string): boolean {
  return /Mac|iPhone|iPad|iPod/i.test(platform);
}

export function fileShortcutModifier(): "⌘" | "Ctrl" {
  return typeof navigator !== "undefined" && usesCommandKey(navigator.platform) ? "⌘" : "Ctrl";
}

export function getFileShortcut(event: Pick<KeyboardEvent, "key" | "metaKey" | "ctrlKey" | "altKey" | "shiftKey" | "isComposing">, platform: string): "upload" | "copy" | "download" | null {
  if (event.isComposing || event.altKey || event.shiftKey) return null;
  if (event.key.toLowerCase() === "l" && !event.metaKey && !event.ctrlKey) return "copy";
  const modifier = usesCommandKey(platform)
    ? event.metaKey && !event.ctrlKey
    : event.ctrlKey && !event.metaKey;
  if (!modifier) return null;
  switch (event.key.toLowerCase()) {
    case "u": return "upload";
    case "e": return "download";
    default: return null;
  }
}
