import assert from "node:assert/strict";
import test from "node:test";
import { getCommentKeyboardAction } from "../lib/comment-shortcut.ts";

function shortcut(overrides: Partial<Parameters<typeof getCommentKeyboardAction>[0]> = {}) {
  return getCommentKeyboardAction({
    key: "Enter",
    metaKey: false,
    shiftKey: false,
    isComposing: false,
    ...overrides,
  });
}

test("plain Enter submits a comment", () => {
  assert.equal(shortcut(), "submit");
});

test("Command+Enter and Shift+Enter keep editing a multiline comment", () => {
  assert.equal(shortcut({ metaKey: true }), "line-break");
  assert.equal(shortcut({ shiftKey: true }), "line-break");
});

test("Enter never submits while an IME composition is active", () => {
  assert.equal(shortcut({ isComposing: true }), "none");
  assert.equal(shortcut({ key: " " }), "none");
});
