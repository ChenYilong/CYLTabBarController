export type CommentShortcutEvent = {
  key: string;
  metaKey: boolean;
  shiftKey: boolean;
  isComposing: boolean;
};

export type CommentKeyboardAction = "none" | "submit" | "line-break";

export function getCommentKeyboardAction(event: CommentShortcutEvent): CommentKeyboardAction {
  if (event.key !== "Enter" || event.isComposing) return "none";
  if (event.metaKey || event.shiftKey) return "line-break";
  return "submit";
}
