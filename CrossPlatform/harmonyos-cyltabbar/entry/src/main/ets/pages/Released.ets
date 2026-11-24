import { CYLLocalizedString } from 'cyltabbar';
import { DemoTeardown } from '../demo/DemoTeardown';

/**
 * [EN] What the window shows after the tab bar controller was released (iOS `CYLDemoReleasedViewController`): the dealloc callbacks
 *      that ran, refreshed as they run, because the old page disappears a moment after this one appears.
 * [CN] TabBarController 被释放后窗口显示的内容（对应 iOS 的 `CYLDemoReleasedViewController`）：已执行的 dealloc 回调，
 *      随执行刷新，因为旧页面在本页面出现之后才消失。
 */
@Entry
@Component
struct Released {
  @State text: string = '';
  private listener: () => void = (): void => {};

  private message(): string {
    return `${CYLLocalizedString('Tab bar controller released')}\n\n${DemoTeardown.summary()}`;
  }

  aboutToAppear(): void {
    this.text = this.message();
    this.listener = (): void => {
      this.text = this.message();
    };
    DemoTeardown.addListener(this.listener);
  }

  aboutToDisappear(): void {
    DemoTeardown.removeListener(this.listener);
  }

  build() {
    Column() {
      Text(this.text)
        .fontSize(17)
        .textAlign(TextAlign.Center)
        .id('cyl-released-status')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
    .backgroundColor(Color.White)
  }
}
