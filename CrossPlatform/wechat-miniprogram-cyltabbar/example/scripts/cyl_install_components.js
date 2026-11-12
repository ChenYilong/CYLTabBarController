#!/usr/bin/env node
/**
 * [EN] Installs the example's components from relative-path dependencies, the way WeChat DevTools' "Build npm" lays
 *      them out, without npm or the network: for every `file:` dependency in package.json, it copies the package's
 *      mini program folder (its "miniprogram" field, else miniprogram_dist) to miniprogram/miniprogram_npm/<name>/, then
 *      does the same for that package's own `file:` dependencies, resolved from the package's folder. So depending on
 *      cyl-tabbar-miniprogram brings in cyl-lottie-miniprogram, its sub-dependency. (npm links `file:` dependencies
 *      with symbolic links, which an exFAT drive cannot hold, and `--install-links` resolves nested relative paths
 *      from the wrong folder.) `--check` exits 1 when miniprogram_npm is out of date.
 * [CN] 按微信开发者工具「构建 npm」的目录结构，从相对路径依赖安装示例的组件，不需要 npm 或网络：对 package.json 中的
 *      每个 `file:` 依赖，把该包的小程序目录（"miniprogram" 字段，否则 miniprogram_dist）复制到
 *      miniprogram/miniprogram_npm/<包名>/，再对该包自己的 `file:` 依赖（相对该包的目录解析）做同样的事。因此依赖
 *      cyl-tabbar-miniprogram 时会自动带上它的子依赖 cyl-lottie-miniprogram。（npm 用符号链接安装 `file:` 依赖，
 *      exFAT 磁盘无法保存符号链接；`--install-links` 又会从错误的目录解析嵌套的相对路径。）`--check` 在
 *      miniprogram_npm 过期时以 1 退出。
 */
const fs = require('fs')
const path = require('path')

const CYL_EXAMPLE = path.resolve(__dirname, '..')
const CYL_TARGET = path.join(CYL_EXAMPLE, 'miniprogram', 'miniprogram_npm')

/**
 * [EN] Every file under a folder, as paths relative to it, skipping AppleDouble files (._*).
 * [CN] 文件夹下的所有文件（相对路径），跳过 AppleDouble 文件（._*）。
 */
function cylFiles(folder, prefix = '') {
  return fs.readdirSync(path.join(folder, prefix), {withFileTypes: true})
    .filter((entry) => !entry.name.startsWith('._') && entry.name !== '.DS_Store')
    .flatMap((entry) => {
      const relative = path.join(prefix, entry.name)
      return entry.isDirectory() ? cylFiles(folder, relative) : [relative]
    })
}

/**
 * [EN] The packages to install, sub-dependencies included: name -> {folder, distFolder}.
 * [CN] 需要安装的包（包括子依赖）：包名 -> {folder, distFolder}。
 */
function cylPackages(packageFolder, found = {}) {
  const manifest = JSON.parse(fs.readFileSync(path.join(packageFolder, 'package.json'), 'utf8'))
  Object.entries(manifest.dependencies || {}).forEach(([name, spec]) => {
    if (!String(spec).startsWith('file:') || found[name]) {
      return
    }
    const folder = path.resolve(packageFolder, String(spec).slice('file:'.length))
    const dependency = JSON.parse(fs.readFileSync(path.join(folder, 'package.json'), 'utf8'))
    const distFolder = path.join(folder, dependency.miniprogram || 'miniprogram_dist')
    if (!fs.existsSync(distFolder)) {
      throw new Error(`${name}: ${path.relative(CYL_EXAMPLE, distFolder)} is missing; build the package first.`)
    }
    found[name] = {folder, distFolder}
    cylPackages(folder, found)
  })
  return found
}

function cylMain() {
  const check = process.argv.includes('--check')
  const packages = cylPackages(CYL_EXAMPLE)
  const expected = {}
  Object.entries(packages).forEach(([name, {distFolder}]) => {
    cylFiles(distFolder).forEach((file) => {
      expected[path.join(name, file)] = path.join(distFolder, file)
    })
  })
  const existing = fs.existsSync(CYL_TARGET) ? cylFiles(CYL_TARGET) : []
  const stale = existing.filter((file) => !expected[file])
  const changed = Object.keys(expected).filter((file) => {
    const target = path.join(CYL_TARGET, file)
    return !fs.existsSync(target) || !fs.readFileSync(target).equals(fs.readFileSync(expected[file]))
  })
  if (check) {
    if (stale.length + changed.length > 0) {
      console.error(`miniprogram_npm is out of date, run node scripts/cyl_install_components.js:\n  ${stale.concat(changed).join('\n  ')}`)
      process.exit(1)
    }
    console.log('miniprogram_npm is up to date.')
    return
  }
  stale.forEach((file) => fs.unlinkSync(path.join(CYL_TARGET, file)))
  changed.forEach((file) => {
    const target = path.join(CYL_TARGET, file)
    fs.mkdirSync(path.dirname(target), {recursive: true})
    fs.copyFileSync(expected[file], target)
  })
  console.log(`Installed ${Object.keys(packages).join(', ')} into miniprogram/miniprogram_npm (${changed.length} file(s) updated, ${stale.length} removed).`)
}

cylMain()
