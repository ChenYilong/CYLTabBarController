#!/usr/bin/env node
/**
 * [EN] Builds miniprogram_dist/svga/fflate.js from fflate 0.8.2 (MIT, `npm install` first): its UMD build, with the
 *      optional Node `worker_threads` lookup of the asynchronous API removed (a mini program has no such module; the
 *      SVGA player only calls the synchronous unzlibSync).
 * [CN] 从 fflate 0.8.2（MIT，先执行 `npm install`）构建 miniprogram_dist/svga/fflate.js：使用其 UMD 版本，并去掉异步 API
 *      可选的 Node `worker_threads` 查找（小程序没有该模块；SVGA 播放器只调用同步的 unzlibSync）。
 */
const fs = require('fs')
const path = require('path')

const CYL_ROOT = path.resolve(__dirname, '..')
const CYL_SOURCE = path.join(CYL_ROOT, 'node_modules', 'fflate')
const CYL_TARGET = path.join(CYL_ROOT, 'miniprogram_dist', 'svga', 'fflate.js')

const version = require(path.join(CYL_SOURCE, 'package.json')).version
let code = fs.readFileSync(path.join(CYL_SOURCE, 'umd', 'index.js'), 'utf8')
const patched = code
  .replace('try{e=require("worker_threads").Worker}catch(e){}', 'e=undefined;')
  .replace("var __w=require('worker_threads');", 'var __w=undefined;')
if (patched === code || /require\(/.test(patched)) {
  throw new Error('cyl_build: the worker_threads lookup of fflate changed; update the patch.')
}
const header = `// Built by scripts/cyl_build.js from fflate ${version} (MIT, Copyright (c) 2023 Arjun Barrett); do not edit by hand.\n`
fs.writeFileSync(CYL_TARGET, header + patched)
console.log(`wrote ${path.relative(CYL_ROOT, CYL_TARGET)} (${patched.length} bytes)`)
