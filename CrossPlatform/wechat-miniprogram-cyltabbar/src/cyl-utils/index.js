/**
 * [EN] `cyl-utils`: the bottom layer of the mini program package (docs/Animated-Item-Badge-CrossPlatform.md, D8). The only
 *      module that requires the vendored lifecycle library (`../cyl-dealloc-block-executor`) and re-exports it; every other
 *      module (cyl-badge, cyl-animated-item, cyl-tab-bar) requires `../cyl-utils/index` instead. The lifecycle library
 *      requires nothing. Checked by `node --test`, not yet by the developer tools.
 * [CN] `cyl-utils`：小程序包的最底层（docs/Animated-Item-Badge-CrossPlatform.md，D8）。唯一引用内置生命周期库（`../cyl-dealloc-block-executor`）
 *      并重新导出它的模块；其他模块（cyl-badge、cyl-animated-item、cyl-tab-bar）改为引用 `../cyl-utils/index`。生命周期库不引用任何模块。
 *      由 `node --test` 检查，尚未在开发者工具中检查。
 */
module.exports = require('../cyl-dealloc-block-executor/index');
