import assert from "node:assert/strict";
import test from "node:test";
import { getFileShortcut } from "../lib/file-shortcuts.ts";

const event = { key: "u", metaKey: false, ctrlKey: false, altKey: false, shiftKey: false, isComposing: false };
test("file shortcuts map Command on Mac and Control on Windows", () => {
  for (const [key, action] of [["u", "upload"], ["e", "download"]]) {
    assert.equal(getFileShortcut({ ...event, key, metaKey: true }, "MacIntel"), action);
    assert.equal(getFileShortcut({ ...event, key: key.toUpperCase(), ctrlKey: true }, "Win32"), action);
    assert.equal(getFileShortcut({ ...event, key, ctrlKey: true }, "MacIntel"), null);
    assert.equal(getFileShortcut({ ...event, key, metaKey: true }, "Win32"), null);
  }
});
test("file shortcuts leave typing, composition and other modifier combinations alone", () => {
  assert.equal(getFileShortcut(event, "MacIntel"), null);
  for (const extra of [{ altKey: true }, { shiftKey: true }, { ctrlKey: true }, { isComposing: true }, { key: "c" }]) {
    assert.equal(getFileShortcut({ ...event, metaKey: true, ...extra }, "MacIntel"), null);
  }
});

test("plain L copies on either platform and leaves the address-bar shortcut alone", () => {
  for (const platform of ["MacIntel", "Win32"]) {
    assert.equal(getFileShortcut({ ...event, key: "l" }, platform), "copy");
    for (const modifiers of [{ metaKey: true }, { ctrlKey: true }, { altKey: true }, { shiftKey: true }, { isComposing: true }]) {
      assert.equal(getFileShortcut({ ...event, key: "l", ...modifiers }, platform), null);
    }
  }
});
