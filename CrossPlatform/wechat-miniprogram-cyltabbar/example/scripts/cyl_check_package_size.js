#!/usr/bin/env node
/**
 * [EN] The size of the example's code package (miniprogram/, without AppleDouble `._` files and source maps), in bytes
 *      before DevTools minifies it: WeChat allows 2 MB for the main package. Prints it; with `--check` exits 1 above the
 *      limit. The example installs one animation library at a time (`npm run setup -- --animation=…`), so each library is
 *      measured on its own: `npm run check` after a setup checks the installed one.
 * [CN] 示例代码包（miniprogram/，不含 AppleDouble 的 `._` 文件与 source map）的大小（开发者工具压缩前的字节数）：微信允许主包
 *      2 MB。打印大小；带 `--check` 时超出限制则以 1 退出。示例一次只安装一个动画库（`npm run setup -- --animation=…`），
 *      因此每个库单独测量：setup 之后运行 `npm run check` 检查已安装的那个。
 */
const fs = require('fs')
const path = require('path')

const CYL_LIMIT = 2 * 1024 * 1024
const CYL_ROOT = path.resolve(__dirname, '..', 'miniprogram')

/**
 * [EN] The bytes of every file under `folder` that goes into the package. [CN] `folder` 下进入代码包的所有文件的字节数。
 */
function cylSize(folder) {
  let total = 0
  for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
    if (entry.name.startsWith('._') || entry.name.endsWith('.map')) {
      continue
    }
    const file = path.join(folder, entry.name)
    total += entry.isDirectory() ? cylSize(file) : fs.statSync(file).size
  }
  return total
}

const size = cylSize(CYL_ROOT)
const choice = (() => {
  try {
    return fs.readdirSync(CYL_ROOT).filter((name) => /^cyl-(pag|rive)-miniprogram$/.test(name)).join(', ') || 'lottie or gif'
  } catch (error) {
    return ''
  }
})()
const megabytes = (size / (1024 * 1024)).toFixed(2)
console.log(`Code package: ${megabytes} MB of 2 MB (${choice}).`)
if (process.argv.includes('--check') && size > CYL_LIMIT) {
  console.error(`The code package is ${megabytes} MB: above the 2 MB WeChat allows for the main package.`)
  process.exit(1)
}
