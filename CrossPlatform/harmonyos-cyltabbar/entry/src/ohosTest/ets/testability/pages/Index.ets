import { CYLAnimatedItemAnimationContext, CYLAnimatedItemEngines, CYLAnimatedItemView } from 'cyltabbar';

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
    }
    .padding(48)
  }
}
