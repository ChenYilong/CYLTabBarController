#!/usr/bin/env node
/**
 * [EN] `npm run setup [-- --animation=lottie|pag|rive|gif]` and `npm run check`: runs the component installer, then the
 *      shared-resource sync, both with the same arguments (npm passes extra arguments to the last command only).
 * [CN] `npm run setup [-- --animation=lottie|pag|rive|gif]` 与 `npm run check`：先运行组件安装脚本，再运行共用资源
 *      同步脚本，两者使用相同的参数（npm 只把额外参数传给最后一个命令）。
 */
const { execFileSync } = require('child_process')
const path = require('path')

const argv = process.argv.slice(2)
for (const script of ['cyl_install_components.js', 'cyl_sync_shared.js']) {
  try {
    execFileSync(process.execPath, [path.join(__dirname, script), ...argv], { stdio: 'inherit' })
  } catch (error) {
    process.exit(error.status || 1)
  }
}
