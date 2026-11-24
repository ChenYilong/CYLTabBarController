/**
 * [EN] WeChat DevTools drops a JavaScript file it cannot compile WITHOUT an error at the file: the module is simply "not defined"
 *      and every component that requires it fails to load (2026-11-24: `this.onRegister?.(event)` in the vendored
 *      cyl-dealloc-block-executor/registry.js; the optional CALL `?.(` was the only one in the code base). Node accepts all of
 *      these, so no other test sees it. This guard fails on syntax the Mini Program compiler may not handle, in every source
 *      file of the library, its vendored copies and the example: `?.(`, `#private` fields, `??=`, `||=`, `&&=`.
 *      Comments and string literals are ignored. Run: `npm test` (no setup needed).
 *      KNOWN_EXCEPTIONS lists the violations that exist until a re-pin; the test fails both on a new violation and on an
 *      exception that no longer applies, so the list cannot go stale.
 * [CN] 微信开发者工具遇到无法编译的 JavaScript 文件时不会在该文件上报错：模块只是"未定义"，所有引用它的组件都加载失败（2026-11-24：
 *      内置的 cyl-dealloc-block-executor/registry.js 中的 `this.onRegister?.(event)`；可选调用 `?.(` 是代码库中唯一的一处）。Node
 *      全都接受这些写法，因此其他测试发现不了。本测试在库的所有源码、内置副本与示例中，遇到小程序编译器可能不支持的语法即失败：
 *      `?.(`、`#private` 字段、`??=`、`||=`、`&&=`。注释与字符串字面量被忽略。运行：`npm test`（无需准备）。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')

const ROOT = path.join(__dirname, '..')
const SCAN = ['src', 'example/miniprogram']
const SKIP = new Set(['node_modules', 'miniprogram_npm', 'cyl_components', 'engines', '.deps'])
// [EN] file:line of a violation that exists until the library fix is re-pinned (docs/WeChat-Mini-Program.md). Remove it then.
const KNOWN_EXCEPTIONS = ['src/cyl-dealloc-block-executor/registry.js:?.(', 'src/cyl-dealloc-block-executor/controller.js:??=']

const PATTERNS = [
  ['?.(', /\?\.\(/],
  ['#private', /(^|[^\w$'"`])#[A-Za-z_$][\w$]*/],
  ['??=', /\?\?=/],
  ['||=', /\|\|=/],
  ['&&=', /&&=/],
]

/** Code with comments and string / template literals blanked (same length lines), good enough for these tokens. */
function codeOnly(source) {
  let out = ''
  let i = 0
  while (i < source.length) {
    const c = source[i]
    const n = source[i + 1]
    if (c === '/' && n === '/') { while (i < source.length && source[i] !== '\n') i += 1; continue }
    if (c === '/' && n === '*') {
      i += 2
      while (i < source.length && !(source[i] === '*' && source[i + 1] === '/')) { out += source[i] === '\n' ? '\n' : ' '; i += 1 }
      i += 2
      continue
    }
    if (c === '"' || c === "'" || c === '`') {
      const quote = c
      out += ' '
      i += 1
      while (i < source.length && source[i] !== quote) {
        if (source[i] === String.fromCharCode(92)) { out += ' '; i += 1 }
        out += source[i] === '\n' ? '\n' : ' '
        i += 1
      }
      out += ' '
      i += 1
      continue
    }
    out += c
    i += 1
  }
  return out
}

function files(dir) {
  const result = []
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (SKIP.has(entry.name)) continue
    const full = path.join(dir, entry.name)
    if (entry.isDirectory()) result.push(...files(full))
    else if (entry.name.endsWith('.js')) result.push(full)
  }
  return result
}

test('no source file uses syntax that WeChat DevTools may fail to compile (a module that is silently "not defined")', () => {
  const found = new Set()
  for (const base of SCAN) {
    const dir = path.join(ROOT, base)
    if (!fs.existsSync(dir)) continue
    for (const file of files(dir)) {
      const relative = path.relative(ROOT, file).split(path.sep).join('/')
      codeOnly(fs.readFileSync(file, 'utf8')).split('\n').forEach((line) => {
        for (const [name, pattern] of PATTERNS) {
          if (pattern.test(line)) found.add(`${relative}:${name}`)
        }
      })
    }
  }
  const unexpected = [...found].filter((key) => !KNOWN_EXCEPTIONS.includes(key))
  const stale = KNOWN_EXCEPTIONS.filter((key) => !found.has(key))
  assert.deepEqual(unexpected, [], 'new syntax the Mini Program compiler may not handle')
  assert.deepEqual(stale, [], 'KNOWN_EXCEPTIONS entry no longer applies: remove it')
})

test('the guard detects each token (so it cannot pass vacuously)', () => {
  const samples = ['a.b?.(c)', 'class A { #x = 1 }', 'a ??= 1', 'a ||= 1', 'a &&= 1']
  samples.forEach((sample, index) => {
    assert.ok(PATTERNS[index][1].test(codeOnly(sample)), sample)
  })
  assert.equal(PATTERNS.some(([, p]) => p.test(codeOnly("// a?.(b)\nconst s = '?.(' /* #x */"))), false, 'comments and strings are ignored')
})
