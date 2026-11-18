/**
 * [EN] The state of a `CYLAnimatedItemStackView` (HarmonyOS counterpart of iOS `CYLAnimatedItemStackView.swift`): its items
 *      top to bottom, the action of each item, the handlers run by action name and the background action. Plain TypeScript
 *      with no ArkUI import, so the rules are unit tested with Node (cylanimateditem/test); the component draws it.
 * [CN] `CYLAnimatedItemStackView` 的状态（对应 iOS `CYLAnimatedItemStackView.swift`）：自上而下的条目、每个条目的动作、按动作名执行的处理以及背景动作。
 *      不导入 ArkUI 的纯 TypeScript，因此规则可用 Node 做单元测试（cylanimateditem/test）；由组件负责绘制。
 */

/**
 * [EN] Runs when an action is performed: a tap on an item, a tap on the background, or `performAction`.
 * [CN] 执行动作时调用：点击条目、点击背景或调用 `performAction`。
 */
export type CYLAnimatedItemStackActionHandler = (stack: CYLAnimatedItemStackModel, action: string) => void;

/** [EN] The default space between items and between the items and the view's edges. [CN] 条目之间以及条目与视图边缘的默认间距。 */
export const CYLAnimatedItemStackDefaultSpacing: number = 16;

let cylNextStackItemNumber: number = 0;

/**
 * [EN] One element of the stack, drawn as a vertical `CYLAnimatedItemView` (icon above the title). Change its fields, then
 *      call `CYLAnimatedItemStackModel.update` so the view redraws.
 * [CN] 堆叠中的一个元素，绘制为纵向的 `CYLAnimatedItemView`（图标在标题上方）。修改字段后调用 `CYLAnimatedItemStackModel.update` 使视图重绘。
 */
export class CYLAnimatedItemStackItem {
  /** [EN] The component id of the item view (unique by default). [CN] 条目视图的组件 id（默认唯一）。 */
  id: string;
  /** [EN] The title; '' for an icon-only item. [CN] 标题；'' 表示只有图标。 */
  title: string = '';
  /** [EN] The static icon (a `ResourceStr`: a `$r(...)` resource or a path); '' for none. [CN] 静态图标（`ResourceStr`）；'' 表示没有。 */
  image: Object | string = '';
  /** [EN] The animation file, played by the view's `animationBuilder`; '' for none. [CN] 动画文件，由视图的 `animationBuilder` 播放；'' 表示没有。 */
  animationUrl: string = '';
  /** [EN] The icon size in vp. [CN] 图标尺寸（vp）。 */
  iconSize: number = 48;
  /** [EN] The title's line limit; 0 (default) wraps to the width with no limit. [CN] 标题行数上限；0（默认）按宽度换行、不限行数。 */
  titleLines: number = 0;
  /** [EN] The text a screen reader reads instead of the title; '' reads the title. [CN] 读屏代替标题朗读的文字；'' 时朗读标题。 */
  accessibilityText: string = '';
  /** [EN] The space above the item, in vp (ignored for the first item). [CN] 条目上方的间距（vp，第一个条目忽略）。 */
  spacingBefore: number = CYLAnimatedItemStackDefaultSpacing;

  constructor(title: string = '', image: Object | string = '', animationUrl: string = '') {
    cylNextStackItemNumber += 1;
    this.id = `cyl-stack-item-${cylNextStackItemNumber}`;
    this.title = title;
    this.image = image;
    this.animationUrl = animationUrl;
  }
}

/**
 * [EN] The items, actions and handlers of a stack. The first item is the reserved one (the main icon and title); more items
 *      follow it: a hint, a button, a separator, an icon. A tap on an item with an action performs it; a tap anywhere else
 *      (an item without an action takes no taps) performs `backgroundAction`.
 * [CN] 堆叠视图的条目、动作与处理。第一个条目是保留条目（主图标与标题），其后可追加提示、按钮、分隔符、图标等条目。点击带动作的条目执行其动作；点击其他位置
 *      （没有动作的条目不接收点击）执行 `backgroundAction`。
 */
export class CYLAnimatedItemStackModel {
  private entries: CYLAnimatedItemStackItem[] = [];
  private actions: Map<CYLAnimatedItemStackItem, string> = new Map();
  private handlers: Map<string, CYLAnimatedItemStackActionHandler> = new Map();
  private listeners: (() => void)[] = [];
  private margin: number = CYLAnimatedItemStackDefaultSpacing;
  private background: string | undefined = undefined;
  /** [EN] Bumped on every change; the view redraws when it changes. [CN] 每次变化时递增；变化时视图重绘。 */
  revision: number = 0;

  /**
   * [EN] A stack of `items` (each with no action, the default spacing before) and the handlers of `actions`. An action
   *      without a handler does nothing.
   * [CN] 由 `items`（均无动作，使用默认间距）组成的堆叠，以及 `actions` 中的处理。没有处理的动作什么都不做。
   */
  constructor(items: CYLAnimatedItemStackItem[] = [], actions?: Map<string, CYLAnimatedItemStackActionHandler>) {
    if (actions !== undefined) {
      actions.forEach((handler: CYLAnimatedItemStackActionHandler, action: string) => this.handlers.set(action, handler));
    }
    items.forEach((item: CYLAnimatedItemStackItem) => this.append(item, undefined, item.spacingBefore));
  }

  // [EN] Items. [CN] 条目。

  /** [EN] Every item, top to bottom. [CN] 所有条目，自上而下。 */
  get items(): CYLAnimatedItemStackItem[] {
    return this.entries.slice();
  }

  /** [EN] The reserved first item; undefined while the stack is empty. [CN] 保留的第一个条目；堆叠为空时为 undefined。 */
  get firstItem(): CYLAnimatedItemStackItem | undefined {
    return this.entries.length > 0 ? this.entries[0] : undefined;
  }

  /**
   * [EN] Appends `item` under the last one, `spacingBefore` vp below it (ignored for the first item, negative counts as 0);
   *      a tap on it performs `action` when that is not undefined or ''. An item already in the stack is left where it is.
   * [CN] 在最后一个条目下方 `spacingBefore` vp 处追加 `item`（第一个条目忽略，负数按 0）；`action` 不为 undefined 或 '' 时点击它执行该动作。
   *      已在堆叠中的条目保持原位。
   */
  append(item: CYLAnimatedItemStackItem, action?: string, spacingBefore: number = CYLAnimatedItemStackDefaultSpacing): void {
    if (this.entries.indexOf(item) >= 0) {
      return;
    }
    item.spacingBefore = Math.max(0, spacingBefore);
    this.entries.push(item);
    this.storeAction(action, item);
    this.update();
  }

  /**
   * [EN] Makes, appends and returns an item (icon above the title, the title wrapped to the width).
   * [CN] 创建、追加并返回一个条目（图标在标题上方，标题按宽度换行）。
   */
  appendItem(title: string, image: Object | string = '', animationUrl: string = '', action?: string,
    spacingBefore: number = CYLAnimatedItemStackDefaultSpacing): CYLAnimatedItemStackItem {
    const item = new CYLAnimatedItemStackItem(title, image, animationUrl);
    this.append(item, action, spacingBefore);
    return item;
  }

  /** [EN] Removes an item from the stack. [CN] 从堆叠中移除条目。 */
  remove(item: CYLAnimatedItemStackItem): void {
    const index = this.entries.indexOf(item);
    if (index < 0) {
      return;
    }
    this.entries.splice(index, 1);
    this.actions.delete(item);
    this.update();
  }

  /** [EN] Sets or, with undefined or '', removes the action of an item in the stack. [CN] 设置堆叠中条目的动作；传 undefined 或 '' 移除。 */
  setAction(action: string | undefined, item: CYLAnimatedItemStackItem): void {
    if (this.entries.indexOf(item) < 0) {
      return;
    }
    this.storeAction(action, item);
    this.update();
  }

  /** [EN] The action of an item; undefined for none or an item not in the stack. [CN] 条目的动作；没有动作或不在堆叠中时为 undefined。 */
  actionFor(item: CYLAnimatedItemStackItem): string | undefined {
    return this.actions.get(item);
  }

  /** [EN] The first item whose tap performs `action`. [CN] 点击时执行 `action` 的第一个条目。 */
  itemFor(action: string): CYLAnimatedItemStackItem | undefined {
    return this.entries.find((item: CYLAnimatedItemStackItem) => this.actions.get(item) === action);
  }

  private storeAction(action: string | undefined, item: CYLAnimatedItemStackItem): void {
    if (action !== undefined && action.length > 0) {
      this.actions.set(item, action);
    } else {
      this.actions.delete(item);
    }
  }

  // [EN] Actions. [CN] 动作。

  /**
   * [EN] The action of a tap outside every item with an action; undefined (default) turns that off ('' too). A screen
   *      reader reaches it through the first item when that item has no action of its own.
   * [CN] 点击所有带动作条目以外位置时执行的动作；undefined（默认，'' 亦同）关闭。第一个条目没有自己的动作时，读屏通过它触发该动作。
   */
  get backgroundAction(): string | undefined {
    return this.background;
  }

  set backgroundAction(action: string | undefined) {
    this.background = action !== undefined && action.length > 0 ? action : undefined;
    this.update();
  }

  /** [EN] Sets or, with undefined, removes the handler of an action. [CN] 设置动作的处理；传 undefined 移除。 */
  setHandler(handler: CYLAnimatedItemStackActionHandler | undefined, action: string): void {
    if (handler !== undefined) {
      this.handlers.set(action, handler);
    } else {
      this.handlers.delete(action);
    }
  }

  /** [EN] Runs the handler of `action`; false when it has none. [CN] 执行 `action` 的处理；没有处理时返回 false。 */
  performAction(action: string): boolean {
    const handler = this.handlers.get(action);
    if (handler === undefined) {
      return false;
    }
    handler(this, action);
    return true;
  }

  /**
   * [EN] A tap on `item` (the view calls it): its action, or the background action for the first item without one (it
   *      stands for the background, see `actsOnBackground`). False when nothing ran.
   * [CN] 点击 `item`（由视图调用）：执行其动作；没有动作的第一个条目代表背景（见 `actsOnBackground`），执行背景动作。没有执行任何处理时返回 false。
   */
  tapItem(item: CYLAnimatedItemStackItem): boolean {
    const action = this.actions.get(item);
    if (action !== undefined) {
      return this.performAction(action);
    }
    return this.actsOnBackground(item) ? this.tapBackground() : false;
  }

  /** [EN] A tap on the background (the view calls it). [CN] 点击背景（由视图调用）。 */
  tapBackground(): boolean {
    return this.background !== undefined ? this.performAction(this.background) : false;
  }

  // [EN] Touches and the screen reader. [CN] 触摸与读屏。

  /**
   * [EN] Whether the item takes taps: one with an action, and the first item while it stands for the background. Any other
   *      item lets a tap through to the background.
   * [CN] 条目是否接收点击：带动作的条目，以及代表背景的第一个条目。其他条目让点击穿透到背景。
   */
  takesTaps(item: CYLAnimatedItemStackItem): boolean {
    return this.actions.has(item) || this.actsOnBackground(item);
  }

  /**
   * [EN] The first item without an action of its own while there is a background action: it reads as a button for it.
   * [CN] 存在背景动作时、自身没有动作的第一个条目：它作为该动作的按钮朗读。
   */
  actsOnBackground(item: CYLAnimatedItemStackItem): boolean {
    return !this.actions.has(item) && this.background !== undefined && this.firstItem === item;
  }

  /** [EN] What a screen reader reads: the accessibility text, else the title. [CN] 读屏朗读的内容：无障碍文字，否则为标题。 */
  accessibilityTextOf(item: CYLAnimatedItemStackItem): string {
    return item.accessibilityText.length > 0 ? item.accessibilityText : item.title;
  }

  /** [EN] Whether a screen reader reads the item as a button (it acts) rather than as text. [CN] 读屏是否把条目作为按钮（可执行动作）而不是文字朗读。 */
  readsAsButton(item: CYLAnimatedItemStackItem): boolean {
    return this.takesTaps(item);
  }

  /**
   * [EN] Decoration (nothing to read: no title, no accessibility text, no action) is hidden from the screen reader.
   * [CN] 装饰条目（没有可朗读内容：无标题、无无障碍文字、无动作）对读屏隐藏。
   */
  isAccessibilityHidden(item: CYLAnimatedItemStackItem): boolean {
    return !this.takesTaps(item) && this.accessibilityTextOf(item).length === 0;
  }

  // [EN] Layout. [CN] 布局。

  /** [EN] The smallest space between the items and the view's edges (16 by default, never negative). [CN] 条目与视图边缘之间的最小间距（默认 16，不为负）。 */
  get contentMargin(): number {
    return this.margin;
  }

  set contentMargin(margin: number) {
    this.margin = Math.max(0, margin);
    this.update();
  }

  /** [EN] The space above an item: 0 for the first. [CN] 条目上方的间距：第一个为 0。 */
  spacingBeforeOf(item: CYLAnimatedItemStackItem): number {
    return this.entries.indexOf(item) > 0 ? item.spacingBefore : 0;
  }

  /** [EN] The widest an item may be in a view `width` wide, so long titles wrap. [CN] 宽为 `width` 的视图中条目的最大宽度，使长标题换行。 */
  maxItemWidth(width: number): number {
    return Math.max(0, width - 2 * this.margin);
  }

  // [EN] Changes. [CN] 变化。

  /** [EN] Tells the view to redraw (after an item's fields changed). [CN] 通知视图重绘（修改条目字段之后）。 */
  update(): void {
    this.revision += 1;
    this.listeners.slice().forEach((listener: () => void) => listener());
  }

  /** [EN] Calls `listener` after every change. [CN] 每次变化后调用 `listener`。 */
  addListener(listener: () => void): void {
    this.listeners.push(listener);
  }

  /** [EN] Stops calling `listener`. [CN] 停止调用 `listener`。 */
  removeListener(listener: () => void): void {
    this.listeners = this.listeners.filter((each: () => void) => each !== listener);
  }
}
