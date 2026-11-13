import assert from "node:assert/strict";
import { after } from "node:test";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { createServer } from "vite";
import { backingPointToArtboard, canvasPointToBacking } from "../lib/canvas-space.ts";

const vite = await createServer({
  configFile: false,
  root: fileURLToPath(new URL("..", import.meta.url)),
  appType: "custom",
  server: { middlewareMode: true, hmr: false },
  optimizeDeps: { noDiscovery: true },
});
const playerModule = await vite.ssrLoadModule("/lib/rive-player.ts");
const {
  DEFAULT_RENDER_ENGINE,
  WebRivePlayer,
  getTimelinePosition,
  runtimeWasmFile,
  setRiveAudioRegistryPaused,
} = playerModule;

after(async () => vite.close());

test("maps CSS pointer coordinates into the high-DPI backing canvas", () => {
  assert.deepEqual(
    canvasPointToBacking(120, 80, 360, 240, 720, 480),
    { x: 240, y: 160 },
  );
});

test("defaults to versioned WebGL2 and keeps the Canvas2D fallback asset", () => {
  assert.equal(DEFAULT_RENDER_ENGINE, "webgl2");
  assert.equal(runtimeWasmFile("webgl2"), "rive-webgl2-2.39.1.wasm");
  assert.equal(runtimeWasmFile("canvas2d"), "rive-2.39.1.wasm");
});

test("suspends and resumes the Rive audio device with playback", async () => {
  let suspended = 0;
  let resumed = 0;
  const device = {
    state: 1,
    H: {
      suspend: async () => { suspended += 1; },
      resume: async () => { resumed += 1; },
    },
  };
  const registry = {
    devices: [device],
    device_state: { stopped: 0, started: 1 },
  };

  setRiveAudioRegistryPaused(registry, true);
  await Promise.resolve();
  assert.equal(suspended, 1);
  assert.equal(device.state, 0);

  setRiveAudioRegistryPaused(registry, false);
  await Promise.resolve();
  assert.equal(resumed, 1);
  assert.equal(device.state, 1);
});

test("inverts the Rive alignment matrix into artboard coordinates", () => {
  assert.deepEqual(
    backingPointToArtboard({ xx: 2, xy: 0, yx: 0, yy: 2, tx: 40, ty: 20 }, 240, 160),
    { x: 100, y: 70 },
  );
});

test("ignores a non-invertible alignment matrix", () => {
  assert.equal(
    backingPointToArtboard({ xx: 0, xy: 0, yx: 0, yy: 0, tx: 0, ty: 0 }, 10, 10),
    null,
  );
});

test("maps Rive Loop and PingPong playback onto visible timeline progress", () => {
  assert.deepEqual(getTimelinePosition(1.25, 1, 1), { time: 0.25, progress: 0.25 });
  assert.deepEqual(getTimelinePosition(1.25, 1, 2), { time: 0.75, progress: 0.75 });
  assert.deepEqual(getTimelinePosition(2.25, 1, 2), { time: 0.25, progress: 0.25 });
  assert.deepEqual(getTimelinePosition(0.95, 1, 0, true), { time: 1, progress: 1 });
});

test("publishes an unthrottled 100 percent update when the final sequence animation completes", () => {
  const progressEvents: Array<{ name: string; time: number; duration: number; progress: number }> = [];
  const player = new WebRivePlayer({} as HTMLCanvasElement, {
    onMetadata() {},
    onPlayback() {},
    onProgress(progress: { name: string; time: number; duration: number; progress: number }) {
      progressEvents.push(progress);
    },
    onPerformance() {},
  }) as unknown as {
    animation: { didLoop: boolean };
    animationDuration: number;
    animationElapsed: number;
    animationLoopValue: number;
    activeAnimationName: string;
    sequenceIndex: number;
    sequenceNames: string[];
    sequenceElapsed: number;
    sequenceHasOut: boolean;
    playing: boolean;
    lastProgressAt: number;
    advanceSequence(delta: number): boolean;
  };

  player.animation = { didLoop: true };
  player.animationDuration = 1;
  player.animationElapsed = 0.95;
  player.animationLoopValue = 0;
  player.activeAnimationName = "out";
  player.sequenceIndex = 0;
  player.sequenceNames = ["out"];
  player.sequenceElapsed = 0.95;
  player.sequenceHasOut = true;
  player.playing = true;
  player.lastProgressAt = Number.MAX_SAFE_INTEGER;

  assert.equal(player.advanceSequence(0.05), true);
  assert.equal(player.playing, false);
  assert.deepEqual(progressEvents.at(-1), {
    name: "out",
    time: 1,
    duration: 1,
    progress: 1,
  });
});
