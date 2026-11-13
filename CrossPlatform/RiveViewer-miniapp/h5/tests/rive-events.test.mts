import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { after } from "node:test";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";

type RiveRuntimeEvent = {
  id: number;
  elapsedMs: number;
  kind: "info" | "event" | "play" | "state";
  label: string;
  detail: string;
};

const vite = await createServer({
  configFile: false,
  root: fileURLToPath(new URL("..", import.meta.url)),
  appType: "custom",
  server: { middlewareMode: true, hmr: false },
  optimizeDeps: { noDiscovery: true },
});
const playerModule = await vite.ssrLoadModule("/lib/rive-player.ts");
const logModule = await vite.ssrLoadModule("/lib/runtime-event-log.ts");
const {
  advanceStateMachineAndReadReports,
  readStateMachineReports,
  shouldAutoExpandArtboardCatalog,
} = playerModule;
const { RuntimeEventLog } = logModule;

after(async () => vite.close());

test("不超过八个画板时直接展开完整目录", () => {
  assert.equal(shouldAutoExpandArtboardCatalog(0), false);
  assert.equal(shouldAutoExpandArtboardCatalog(1), true);
  assert.equal(shouldAutoExpandArtboardCatalog(8), true);
  assert.equal(shouldAutoExpandArtboardCatalog(9), false);
});

function event(id: number, label: string): RiveRuntimeEvent {
  return { id, elapsedMs: id * 10, kind: "event", label, detail: "" };
}

test("snapshots every state change and Rive event after one advance", () => {
  let advancedBy = -1;
  const stateMachine = {
    advance(seconds: number) {
      advancedBy = seconds;
      return true;
    },
    stateChangedCount: () => 2,
    stateChangedNameByIndex: (index: number) => ["进入", "完成"][index],
    reportedEventCount: () => 3,
    reportedEventAt: (index: number) => [
      {
        name: "提交",
        type: 0,
        delay: 0,
        properties: { count: 0, enabled: false, note: "" },
      },
      undefined,
      { name: "官网", type: 1, url: "https://example.com", target: "_blank" },
    ][index],
  };

  const reports = advanceStateMachineAndReadReports(stateMachine, 0.25, 1234) as Array<Omit<RiveRuntimeEvent, "id">>;

  assert.equal(advancedBy, 0.25);
  assert.deepEqual(reports.map((item) => [item.kind, item.label]), [
    ["state", "进入"],
    ["state", "完成"],
    ["event", "提交"],
    ["event", "官网"],
  ]);
  assert.match(reports[2].detail, /type=0/);
  assert.match(reports[2].detail, /delay=0s/);
  assert.match(reports[2].detail, /count=0/);
  assert.match(reports[2].detail, /enabled=false/);
  assert.match(reports[2].detail, /note=""/);
  assert.match(reports[3].detail, /url=https:\/\/example\.com/);
  assert.match(reports[3].detail, /target=_blank/);
  assert.ok(reports.every((item) => item.elapsedMs === 1234));
});

test("keeps repeated events in order, bounds history, and clears between files", async () => {
  const log = new RuntimeEventLog(3);
  let notifications = 0;
  const unsubscribe = log.subscribe(() => {
    notifications += 1;
  });

  log.append(event(1, "A"));
  log.append(event(2, "A"));
  log.append(event(3, "B"));
  log.append(event(4, "C"));
  await Promise.resolve();

  assert.deepEqual(log.getSnapshot().map((item: RiveRuntimeEvent) => item.label), ["A", "B", "C"]);
  assert.equal(log.getSnapshot().at(-1)?.label, "C");
  assert.equal(notifications, 1, "同一批事件只通知一次视图");

  log.reset();
  await Promise.resolve();
  assert.deepEqual(log.getSnapshot(), []);
  assert.equal(notifications, 2);
  unsubscribe();
});

test("keeps event console and shortcut disclosure accessible without auto-opening URLs", async () => {
  const [appSource, playerSource, consoleSource, styleSource] = await Promise.all([
    readFile(new URL("../app/rive-viewer/RiveViewerApp.tsx", import.meta.url), "utf8"),
    readFile(new URL("../lib/rive-player.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/rive-viewer/RuntimeEventConsole.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
  ]);

  assert.match(appSource, /<RuntimeEventConsole log=\{runtimeEventLog\}/);
  assert.match(playerSource, /onEvent\?:/);
  assert.match(playerSource, /advanceStateMachineAndReadReports/);
  assert.doesNotMatch(playerSource, /window\.open|location\.assign/);
  assert.match(consoleSource, /aria-expanded=\{expanded\}/);
  assert.match(consoleSource, /aria-controls=\{listId\}/);
  assert.match(consoleSource, /等待 Rive 事件/);
  assert.doesNotMatch(consoleSource, /dangerouslySetInnerHTML/);
  assert.match(styleSource, /\.runtime-event-console\s*\{[\s\S]{0,180}position:\s*sticky;[\s\S]{0,80}top:\s*0;/);
  assert.match(styleSource, /\.runtime-event-summary\s*\{[\s\S]{0,180}grid-template-columns:[\s\S]{0,80}34px 18px;/);
  assert.match(styleSource, /\.runtime-event-summary \.runtime-event-message strong\s*\{[\s\S]{0,100}flex:\s*1 1 auto;/);
  assert.match(styleSource, /\.runtime-event-count\s*\{[\s\S]{0,100}font:\s*650 9px/);
  assert.match(styleSource, /@media \(any-hover: hover\) and \(any-pointer: fine\)/);
  assert.match(styleSource, /\.shortcut-help:hover \.shortcut-popover/);
  assert.match(styleSource, /\.shortcut-help:focus-within \.shortcut-popover/);
  assert.match(appSource, /aria-controls=\{popoverId\}/);
  assert.doesNotMatch(appSource, /title="查看快捷键"/);
});

test("reads an empty report batch without inventing events", () => {
  const reports = readStateMachineReports({
    stateChangedCount: () => 0,
    stateChangedNameByIndex: () => "",
    reportedEventCount: () => 0,
    reportedEventAt: () => undefined,
  }, 50);
  assert.deepEqual(reports, []);
});
