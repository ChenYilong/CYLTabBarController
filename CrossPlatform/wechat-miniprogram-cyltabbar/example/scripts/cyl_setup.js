#!/usr/bin/env node
/**
 * [EN] `npm run setup [-- --animation=lottie|pag|rive|gif]` and `npm run check`: runs the component installer, the
 *      shared-resource sync and the package size check (2 MB), all with the same arguments (npm passes extra arguments to the last command only).
 * [CN] `npm run setup [-- --animation=lottie|pag|rive|gif]` 与 `npm run check`：依次运行组件安装脚本、共用资源同步脚本
 *      与代码包大小检查（2 MB），使用相同的参数（npm 只把额外参数传给最后一个命令）。
 */
const { execFileSync } = require('child_process')
const path = require('path')

const argv = process.argv.slice(2)
for (const script of ['cyl_install_components.js', 'cyl_sync_shared.js', 'cyl_check_package_size.js']) {
  try {
    execFileSync(process.execPath, [path.join(__dirname, script), ...argv], { stdio: 'inherit' })
  } catch (error) {
    process.exit(error.status || 1)
  }
}
