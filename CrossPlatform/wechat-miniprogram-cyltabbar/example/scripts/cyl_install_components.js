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
const { CYL_ANIMATIONS, CYL_EXAMPLE, cylChosenAnimation, cylAnimationComponents } = require('./cyl_animation_choice')

const CYL_TARGET = path.join(CYL_EXAMPLE, 'miniprogram', 'miniprogram_npm')

/**
 * [EN] The pages whose usingComponents name animation components (cyl-lottie, cyl-pag, cyl-rive).
 * [CN] usingComponents 中包含动画组件（cyl-lottie、cyl-pag、cyl-rive）的页面。
 */
const CYL_COMPONENT_PAGES = ['custom-tab-bar/index.json', 'pages/lottie/index.json']

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
function cylPackages(packageFolder, found = {}, extra = {}) {
  const manifest = JSON.parse(fs.readFileSync(path.join(packageFolder, 'package.json'), 'utf8'))
  Object.entries(Object.assign({}, manifest.dependencies, extra)).forEach(([name, spec]) => {
    if (!String(spec).startsWith('file:') || found[name]) {
      return
    }
    const folder = path.resolve(packageFolder, String(spec).slice('file:'.length))
    const dependency = JSON.parse(fs.readFileSync(path.join(folder, 'package.json'), 'utf8'))
    const distFolder = path.join(folder, dependency.miniprogram || 'miniprogram_dist')
    if (!fs.existsSync(distFolder)) {
      throw new Error(`${name}: ${path.relative(CYL_EXAMPLE, distFolder)} is missing; build the package first.`)
    }
    found[name] = {folder, distFolder, assets: dependency.cylMiniprogramAssets || []}
    cylPackages(folder, found)
  })
  return found
}

/**
 * [EN] Removes the folders left empty (or holding only AppleDouble files) under a folder, e.g. an uninstalled package.
 * [CN] 删除文件夹下变空（或只剩 AppleDouble 文件）的子文件夹，例如已卸载的包。
 */
function cylRemoveEmptyFolders(folder) {
  fs.readdirSync(folder, {withFileTypes: true}).filter((entry) => entry.isDirectory()).forEach((entry) => {
    const child = path.join(folder, entry.name)
    cylRemoveEmptyFolders(child)
    if (fs.readdirSync(child).every((name) => name.startsWith('._') || name === '.DS_Store')) {
      fs.rmSync(child, {recursive: true, force: true})
    }
  })
}

function cylMain() {
  const check = process.argv.includes('--check')
  // [EN] The example's one animation package (scripts/cyl_animation_choice.js) joins its dependencies.
  // [CN] 示例的唯一动画包（scripts/cyl_animation_choice.js）加入其依赖。
  const choice = cylChosenAnimation(process.argv, !check)
  const animation = CYL_ANIMATIONS[choice]
  const packages = cylPackages(CYL_EXAMPLE, {}, { [animation.name]: `file:${animation.folder}` })
  const expected = {}
  // [EN] Assets (below) are left out of miniprogram_npm: the mini program cannot read them there, and a second copy of
  //      each WebAssembly (about 0.6 MB) counts toward the 2 MB main package.
  // [CN] 资源文件（见下）不复制到 miniprogram_npm：小程序在那里读取不到，而每个 WebAssembly 的第二份副本（约 0.6 MB）
  //      会计入 2 MB 的主包。
  Object.entries(packages).forEach(([name, {folder, distFolder, assets}]) => {
    const skipped = assets.map((file) => path.resolve(folder, file))
    cylFiles(distFolder).filter((file) => !skipped.includes(path.join(distFolder, file))).forEach((file) => {
      expected[path.join(name, file)] = path.join(distFolder, file)
    })
  })
  // [EN] Files a package lists in "cylMiniprogramAssets" also go to miniprogram/<package>/: a mini program cannot read
  //      files under miniprogram_npm (readFileSync and WXWebAssembly answer "permission denied"), e.g. Rive's WebAssembly.
  // [CN] 包在 "cylMiniprogramAssets" 中列出的文件同时复制到 miniprogram/<包名>/：小程序不能读取 miniprogram_npm 下的
  //      文件（readFileSync 与 WXWebAssembly 返回 "permission denied"），例如 Rive 的 WebAssembly。
  const assets = {}
  Object.entries(packages).forEach(([name, {folder, assets: list}]) => {
    list.forEach((file) => {
      assets[path.join(CYL_EXAMPLE, 'miniprogram', name, path.basename(file))] = path.join(folder, file)
    })
  })
  const staleAssets = Object.keys(assets).filter((target) => !fs.existsSync(target)
    || !fs.readFileSync(target).equals(fs.readFileSync(assets[target])))
  // [EN] Asset folders of the animation packages not chosen are removed. [CN] 删除未选择的动画包的资源目录。
  const unusedAssetFolders = Object.values(CYL_ANIMATIONS)
    .filter(({ name }) => !packages[name])
    .map(({ name }) => path.join(CYL_EXAMPLE, 'miniprogram', name))
    .filter((folder) => fs.existsSync(folder))
  // [EN] The pages that use animation components get the chosen package's component, the placeholder for the others.
  // [CN] 使用动画组件的页面：选择的包使用其组件，其他使用占位组件。
  const components = cylAnimationComponents(choice)
  const pageFiles = {}
  CYL_COMPONENT_PAGES.forEach((file) => {
    const target = path.join(CYL_EXAMPLE, 'miniprogram', file)
    const json = JSON.parse(fs.readFileSync(target, 'utf8'))
    Object.keys(components).filter((tag) => tag in json.usingComponents).forEach((tag) => {
      json.usingComponents[tag] = components[tag]
    })
    const text = `${JSON.stringify(json, null, 2)}\n`
    if (fs.readFileSync(target, 'utf8') !== text) {
      pageFiles[target] = text
    }
  })
  const existing = fs.existsSync(CYL_TARGET) ? cylFiles(CYL_TARGET) : []
  const stale = existing.filter((file) => !expected[file])
  const changed = Object.keys(expected).filter((file) => {
    const target = path.join(CYL_TARGET, file)
    return !fs.existsSync(target) || !fs.readFileSync(target).equals(fs.readFileSync(expected[file]))
  })
  if (check) {
    const outdated = staleAssets.concat(unusedAssetFolders, Object.keys(pageFiles))
    if (stale.length + changed.length + outdated.length > 0) {
      const names = stale.concat(changed, outdated.map((target) => path.relative(CYL_EXAMPLE, target)))
      console.error(`miniprogram_npm is out of date, run node scripts/cyl_install_components.js:\n  ${names.join('\n  ')}`)
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
  staleAssets.forEach((target) => {
    fs.mkdirSync(path.dirname(target), {recursive: true})
    fs.copyFileSync(assets[target], target)
  })
  unusedAssetFolders.forEach((folder) => fs.rmSync(folder, {recursive: true, force: true}))
  cylRemoveEmptyFolders(CYL_TARGET)
  Object.entries(pageFiles).forEach(([target, text]) => fs.writeFileSync(target, text))
  console.log(`Animation: ${choice}. Installed ${Object.keys(packages).join(', ')} into miniprogram/miniprogram_npm (${changed.length} file(s) updated, ${stale.length} removed).`)
}

cylMain()
