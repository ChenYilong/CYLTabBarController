import { window } from '@kit.ArkUI';
import { LifecycleController, Rect } from './controller';
import { Insets } from './types';

/**
 * Feeds a `LifecycleController` from the real ArkUI window events and the ability callbacks.
 * The page forwards its own callbacks, one line each:
 *
 * ```ts
 * @Component struct Page {
 *   private bridge: CYLLifecycleBridge<Object> = new CYLLifecycleBridge<Object>(this);
 *   aboutToAppear() { this.bridge.aboutToAppear(); }
 *   onPageShow() { this.bridge.onPageShow(); }
 *   onPageHide() { this.bridge.onPageHide(); }
 *   aboutToDisappear() { this.bridge.aboutToDisappear(); }
 *   build() { Column() {}.onAreaChange((o: Area, n: Area) => this.bridge.onAreaChange(o, n)) }
 * }
 * ```
 *
 * `attachWindow(win)` subscribes the window size and avoid-area events (removed in
 * `aboutToDisappear`); the ability forwards `onConfigurationUpdate` (color mode) and
 * `onMemoryLevel`. Add blocks on `bridge.controller.registry`, before `aboutToAppear` for the
 * `viewDidLoad` blocks.
 */
export class CYLLifecycleBridge<T extends Object> {
  readonly controller: LifecycleController<T>;
  private win: window.Window | undefined = undefined;
  private sizeListener: ((size: window.Size) => void) | undefined = undefined;
  private avoidListener: ((data: window.AvoidAreaOptions) => void) | undefined = undefined;

  constructor(owner: T) {
    this.controller = new LifecycleController<T>(owner);
  }

  /**
   * `initialColorMode` (`ConfigurationConstant.ColorMode`, 0 dark, 1 light; for example `context.config.colorMode`) seeds the
   * color mode the page starts in. Without it the first `onConfigurationUpdate` only records a baseline, so the first
   * light-to-dark switch would fire no `traitCollectionDidChange`.
   */
  aboutToAppear(initialColorMode?: number): void {
    if (initialColorMode !== undefined) this.onConfigurationUpdate(initialColorMode);
    this.controller.aboutToAppear();
  }

  onPageShow(): void {
    this.controller.onPageShow();
  }

  onPageHide(): void {
    this.controller.onPageHide();
  }

  /** The root component's `onAreaChange(old, new)`. */
  onAreaChange(oldArea: Rect, area: Rect): void {
    this.controller.onAreaChange(oldArea, area);
  }

  /** The ability's `onMemoryLevel(level)`. */
  onMemoryLevel(level: number): void {
    this.controller.memoryLevel(level);
  }

  /** The ability's `onConfigurationUpdate`: `ConfigurationConstant.ColorMode` 0 is dark, 1 is light. */
  onConfigurationUpdate(colorMode: number): void {
    if (colorMode === 0 || colorMode === 1) {
      this.controller.colorModeChanged(colorMode === 0 ? 'dark' : 'light');
    }
  }

  /** Subscribes the window's size and avoid-area events, and reports the window move. */
  attachWindow(win: window.Window): void {
    this.detachWindow();
    this.win = win;
    this.controller.windowAttached(win);
    this.sizeListener = (size: window.Size): void => {
      const area: Rect = { width: size.width, height: size.height };
      this.controller.onAreaChange(area, area);
    };
    this.avoidListener = (_data: window.AvoidAreaOptions): void => {
      try {
        const area = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const insets: Insets = {
          top: area.topRect.height,
          left: area.leftRect.width,
          bottom: area.bottomRect.height,
          right: area.rightRect.width,
        };
        this.controller.avoidAreaChanged(insets);
      } catch (e) {
        // The avoid area could not be read: keep the previous insets.
      }
    };
    win.on('windowSizeChange', this.sizeListener);
    win.on('avoidAreaChange', this.avoidListener);
  }

  private detachWindow(): void {
    if (this.win !== undefined) {
      if (this.sizeListener !== undefined) this.win.off('windowSizeChange', this.sizeListener);
      if (this.avoidListener !== undefined) this.win.off('avoidAreaChange', this.avoidListener);
      this.controller.windowDetached();
    }
    this.win = undefined;
    this.sizeListener = undefined;
    this.avoidListener = undefined;
  }

  aboutToDisappear(): void {
    this.detachWindow();
    this.controller.aboutToDisappear();
  }
}
