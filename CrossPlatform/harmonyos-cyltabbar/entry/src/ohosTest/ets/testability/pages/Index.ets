import { CYLAnimatedItemAnimationContext, CYLAnimatedItemEngines, CYLAnimatedItemView } from 'cyltabbar';

/**
 * [EN] One item of the system tab bar whose height CYLTabBarHeight.test measures (it fills the bar's height).
 * [CN] CYLTabBarHeight.test 测量其高度的系统 TabBar 的一项（填满 TabBar 的高度）。
 */
@Builder
function cylSystemTabBarItem(index: number) {
  Column() {
    Text(`${index}`)
  }
  .height('100%')
  .width('100%')
  .id(`cyl-test-system-bar-item-${index}`)
}

/**
 * [EN] The x86_64 fallback page (cylanimateditem/README.md, "x86_64 emulator"): a Rive item and a Lottie item with a still
 *      image. Their animation builder draws only a marker (id `cyl-test-engine-<type>`), never a real engine, so the UI test
 *      sees whether the component would create an engine view: on a device without arm64-v8a the Rive item must not (it
 *      shows its still image), the Lottie item must.
 * [CN] x86_64 回退页面：一个 Rive 条目与一个 Lottie 条目，都带静态图片。它们的动画 builder 只绘制一个标记（id `cyl-test-engine-<类型>`），
 *      不创建真正的引擎，UI 测试据此判断组件是否会创建引擎视图：在没有 arm64-v8a 的设备上 Rive 条目不得创建（显示静态图片），Lottie 条目必须创建。
 */
@Entry
@Component
struct Index {
  aboutToAppear(): void {
    CYLAnimatedItemEngines.register('Rive');
    CYLAnimatedItemEngines.register('Lottie');
    // [EN] The x86_64 debug engine kit marker is a rawfile of the app module (entry), not of this test module.
    // [CN] x86_64 调试引擎包的标记是 App 模块（entry）的 rawfile，而不是本测试模块的。
    try {
      CYLAnimatedItemEngines.loadX86_64DebugEngines(this.getUIContext().getHostContext()?.createModuleContext('entry'));
    } catch (e) {
      // [EN] No entry module context: the kit stays off. [CN] 没有 entry 模块 context：调试引擎包保持关闭。
    }
  }

  @Builder
  marker(type: string, context: CYLAnimatedItemAnimationContext) {
    Text(type)
      .id(`cyl-test-engine-${type}`)
      .onAppear(() => context.onLoaded())
  }

  build() {
    Column({ space: 24 }) {
      CYLAnimatedItemView({
        isBare: true,
        image: $r('app.media.startIcon'),
        animationUrl: 'rive/cyl_test.riv',
        iconSize: 48,
        isItemSelected: true,
        animationBuilder: (context: CYLAnimatedItemAnimationContext) => {
          this.marker('Rive', context)
        },
      })
        .id('cyl-test-rive-item')
      CYLAnimatedItemView({
        isBare: true,
        image: $r('app.media.startIcon'),
        animationUrl: 'lottie/cyl_test.json',
        iconSize: 48,
        isItemSelected: true,
        animationBuilder: (context: CYLAnimatedItemAnimationContext) => {
          this.marker('Lottie', context)
        },
      })
        .id('cyl-test-lottie-item')
      // [EN] A system tab bar (ArkUI Tabs, bottom bar, default barHeight) for the default height test.
      // [CN] 系统 TabBar（ArkUI Tabs，底部 TabBar，默认 barHeight），用于默认高度测试。
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() { Text('a') }.tabBar(cylSystemTabBarItem(0))
        TabContent() { Text('b') }.tabBar(cylSystemTabBarItem(1))
      }
      .height(240)
      .width('100%')
    }
    .padding(48)
  }
}
