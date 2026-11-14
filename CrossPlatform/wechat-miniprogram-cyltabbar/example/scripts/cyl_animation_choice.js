/**
 * [EN] The one animation package the example installs: `node scripts/cyl_install_components.js --animation=pag` (or
 *      `npm run setup -- --animation=pag`) chooses it and remembers it in `.cyl-animation` (ignored by git); without a
 *      choice the example uses "cylExampleAnimation" of package.json (Lottie). Each animation lives in its own package,
 *      so the main code package holds one runtime and its icons only.
 * [CN] 示例安装的唯一动画包：`node scripts/cyl_install_components.js --animation=pag`（或
 *      `npm run setup -- --animation=pag`）选择它，并记在 `.cyl-animation`（git 忽略）中；没有选择时使用 package.json
 *      的 "cylExampleAnimation"（Lottie）。每种动画都在自己的包中，因此主包只包含一个运行时及其图标。
 */
const fs = require('fs')
const path = require('path')

const CYL_EXAMPLE = path.resolve(__dirname, '..')
const CYL_CHOICE_FILE = path.join(CYL_EXAMPLE, '.cyl-animation')
const CYL_PLACEHOLDER = 'cyl-tabbar-miniprogram/cyl-animation-placeholder/index'

/**
 * [EN] The animation packages: folder (relative to the example) and the component the tab bar's abstract node takes.
 * [CN] 动画包：目录（相对示例）以及 TabBar 抽象节点使用的组件。
 */
const CYL_ANIMATIONS = {
  lottie: { name: 'cyl-lottie-miniprogram', folder: '../../lottie-miniprogram', tag: 'cyl-lottie', component: 'cyl-lottie/index' },
  pag: { name: 'cyl-pag-miniprogram', folder: '../../pag-miniprogram', tag: 'cyl-pag', component: 'cyl-pag/index' },
  rive: { name: 'cyl-rive-miniprogram', folder: '../../rive-miniprogram', tag: 'cyl-rive', component: 'cyl-rive/index' },
  gif: { name: 'cyl-gif-miniprogram', folder: '../../gif-miniprogram', tag: null, component: null },
}

/**
 * [EN] The chosen animation: --animation=<name>, else .cyl-animation, else package.json. A new choice is saved unless
 *      `save` is false (--check never saves).
 * [CN] 选择的动画：--animation=<名称>，否则 .cyl-animation，否则 package.json。除非 `save` 为 false（--check 从不保存），
 *      新的选择会被保存。
 */
function cylChosenAnimation(argv, save) {
  const flag = argv.find((argument) => argument.startsWith('--animation='))
  let choice = flag ? flag.slice('--animation='.length) : ''
  if (!choice && fs.existsSync(CYL_CHOICE_FILE)) {
    choice = fs.readFileSync(CYL_CHOICE_FILE, 'utf8').trim()
  }
  if (!choice) {
    choice = JSON.parse(fs.readFileSync(path.join(CYL_EXAMPLE, 'package.json'), 'utf8')).cylExampleAnimation || 'lottie'
  }
  if (!CYL_ANIMATIONS[choice]) {
    throw new Error(`Unknown animation '${choice}': use one of ${Object.keys(CYL_ANIMATIONS).join(', ')}.`)
  }
  if (flag && save) {
    fs.writeFileSync(CYL_CHOICE_FILE, `${choice}\n`)
  }
  return choice
}

/**
 * [EN] The usingComponents entries of the animation tags: the chosen package's component, the placeholder for the others.
 * [CN] 动画标签的 usingComponents 条目：选择的包使用其组件，其他使用占位组件。
 */
function cylAnimationComponents(choice) {
  const components = {}
  Object.entries(CYL_ANIMATIONS).forEach(([key, animation]) => {
    if (animation.tag) {
      components[animation.tag] = key === choice ? `${animation.name}/${animation.component}` : CYL_PLACEHOLDER
    }
  })
  return components
}

module.exports = { CYL_ANIMATIONS, CYL_EXAMPLE, cylChosenAnimation, cylAnimationComponents }
