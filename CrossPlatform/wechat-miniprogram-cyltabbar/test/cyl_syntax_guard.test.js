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
const KNOWN_EXCEPTIONS = [
  'src/cyl-dealloc-block-executor/registry.js:?.(',
  'src/cyl-dealloc-block-executor/controller.js:??=',
  'src/cyl-dealloc-block-executor/registry.js:class field',
  'src/cyl-dealloc-block-executor/center.js:class field',
  'src/cyl-dealloc-block-executor/log.js:class field',
]
const NL = String.fromCharCode(10)

const PATTERNS = [
  ['?.(', /\?\.\(/],
  ['#private', /(^|[^\w$'"`])#[A-Za-z_$][\w$]*/],
  ['??=', /\?\?=/],
  ['||=', /\|\|=/],
  ['&&=', /&&=/],
]

/**
 * Lines that declare a class field (`x = 1;`, `static y = 2;`, a bare `z;`): a statement directly inside a class body, which
 * TypeScript downlevels only with a target below ES2022 and which the Mini Program compiler may drop.
 */
function classFieldLines(code) {
  const stack = []
  const found = []
  const fieldLine = /^[ \t]+(static[ \t]+)?[A-Za-z_$][A-Za-z0-9_$]*[ \t]*(=[^=>].*)?;[ \t]*$/
  const classHead = /[^A-Za-z0-9_$]class[^A-Za-z0-9_$][^{};]*$/
  let lineStart = 0
  for (let i = 0; i < code.length; i += 1) {
    const c = code[i]
    if (c === '{') {
      const before = ' ' + code.slice(Math.max(0, lineStart - 200), i).split(NL).join(' ')
      stack.push(classHead.test(before))
    } else if (c === '}') {
      stack.pop()
    } else if (c === NL) {
      // [EN] The vendored copies have CRLF line ends. [CN] 内置副本使用 CRLF 换行。
      const line = code.slice(lineStart, i).split(String.fromCharCode(13)).join('')
      if (stack.length > 0 && stack[stack.length - 1] && fieldLine.test(line)) found.push(line.trim())
      lineStart = i + 1
    }
  }
  return found
}

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
      const code = codeOnly(fs.readFileSync(file, 'utf8'))
      if (classFieldLines(code).length > 0) found.add(`${relative}:class field`)
      code.split(NL).forEach((line) => {
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
  const withFields = ['class A {', '  x = 1;', '  static y = 2;', '  m() { const z = 1; }', '}'].join(NL)
  assert.equal(classFieldLines(codeOnly(withFields)).length, 2, 'class fields are detected, locals are not')
  const plain = ['function f() {', '  const a = 1;', '  a2 = 3;', '}'].join(NL)
  assert.equal(classFieldLines(codeOnly(plain)).length, 0, 'statements outside a class are not fields')
  assert.equal(PATTERNS.some(([, p]) => p.test(codeOnly("// a?.(b)\nconst s = '?.(' /* #x */"))), false, 'comments and strings are ignored')
})

/**
 * [EN] The vendored dealloc executor is reachable only from its index.js. The DevTools unused-file filter keeps a file only when
 *      a plain `require('./x')` chain from a used file reaches it; a require inside an object spread (`...require('./x')`) is not
 *      followed (2026-11-24: index.js `module.exports = { ...require('./registry.js'), ... }` left only index.js defined, every
 *      other module "not defined"; plain `const x = require('./x')` lines, with or without `.js`, fixed it). So every file of the
 *      folder must be reachable from index.js through plain requires. UNREACHABLE_UNTIL_REPIN lists the files that are not, until
 *      the library fix is re-pinned; the test fails when a listed file became reachable (remove it).
 * [CN] 内置的 dealloc 执行器只能从其 index.js 到达。开发者工具的「未使用文件」过滤只保留能通过普通 `require('./x')` 链到达的文件；
 *      对象展开中的 require（`...require('./x')`）不会被跟踪（2026-11-24）。因此该目录的每个文件都必须能从 index.js 通过普通 require 到达。
 */
const UNREACHABLE_UNTIL_REPIN = ['center.js', 'controller.js', 'log.js', 'registry.js', 'types.js']

function plainRequires(source) {
  const result = []
  const pattern = /(^|[^.A-Za-z0-9_$])require(s*'(.[^']*)'s*)/g
  let match = pattern.exec(source)
  while (match) { result.push(match[2]); match = pattern.exec(source) }
  return result
}

test('every file of the vendored dealloc executor is reachable from index.js by plain requires (the DevTools unused-file filter)', () => {
  const dir = path.join(ROOT, 'src', 'cyl-dealloc-block-executor')
  const all = fs.readdirSync(dir).filter((name) => name.endsWith('.js'))
  const seen = new Set(['index.js'])
  const queue = ['index.js']
  while (queue.length > 0) {
    const name = queue.shift()
    for (const target of plainRequires(fs.readFileSync(path.join(dir, name), 'utf8'))) {
      const resolved = path.basename(target).endsWith('.js') ? path.basename(target) : path.basename(target) + '.js'
      if (all.includes(resolved) && !seen.has(resolved)) { seen.add(resolved); queue.push(resolved) }
    }
  }
  const unreachable = all.filter((name) => !seen.has(name)).sort()
  assert.deepEqual(unreachable, UNREACHABLE_UNTIL_REPIN, 'files DevTools would drop (or a stale UNREACHABLE_UNTIL_REPIN entry)')
})
