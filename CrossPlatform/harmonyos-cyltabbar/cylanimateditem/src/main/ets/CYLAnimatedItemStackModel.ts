/**
 * [EN] The state of a `CYLAnimatedItemStackView` (HarmonyOS counterpart of iOS `CYLAnimatedItemStackView.swift`): its items
 *      top to bottom, the action of each item, the handlers run by action name and the background action. Plain TypeScript
 *      with no ArkUI import, so the rules are unit tested with Node (cylanimateditem/test); the component draws it.
 * [CN] `CYLAnimatedItemStackView` 的状态（对应 iOS `CYLAnimatedItemStackView.swift`）：自上而下的条目、每个条目的动作、按动作名执行的处理以及背景动作。
 *      不导入 ArkUI 的纯 TypeScript，因此规则可用 Node 做单元测试（cylanimateditem/test）；由组件负责绘制。
 */

import { cylAnimatedItemEffective } from './CYLAnimatedItemColors';

/**
 * [EN] Runs when an action is performed: a tap on an item, a tap on the background, or `performAction`.
 * [CN] 执行动作时调用：点击条目、点击背景或调用 `performAction`。
 */
export type CYLAnimatedItemStackActionHandler = (stack: CYLAnimatedItemStackModel, action: string) => void;

/** [EN] The default space between items and between the items and the view's edges. [CN] 条目之间以及条目与视图边缘的默认间距。 */
export const CYLAnimatedItemStackDefaultSpacing: number = 16;

/** [EN] The default divider length in vp. [CN] 分隔线的默认长度（vp）。 */
export const CYLAnimatedItemDividerLength: number = 20;

/** [EN] The thickness of a divider line in vp. [CN] 分隔线的粗细（vp）。 */
export const CYLAnimatedItemDividerThickness: number = 1;

/**
 * [EN] The divider of the gap after one item (the item owns it: it moves and goes with the item). `shown` false is the "no divider
 *      here" override that wins over `showsDividers`; the spacings are undefined when not set (the stack defaults, then the item
 *      spacing apply: see `CYLAnimatedItemStackModel.gapAfter`).
 * [CN] 某个条目之后间隙的分隔线（归该条目所有：随条目移动、随条目移除）。`shown` 为 false 是「此处没有分隔线」，优先于 `showsDividers`；
 *      未设置的间距为 undefined（依次使用堆叠默认值与条目间距：见 `CYLAnimatedItemStackModel.gapAfter`）。
 */
export class CYLAnimatedItemDividerSpec {
  shown: boolean = true;
  spacingBefore: number | undefined = undefined;
  spacingAfter: number | undefined = undefined;
}

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
  /**
   * [EN] The space before the item (above it, or on its leading side in a horizontal stack), in vp; ignored for the first
   *      item; negative (the default, -1) uses the stack's `spacing`.
   * [CN] 条目之前的间距（上方，水平堆叠时为前侧），单位 vp；第一个条目忽略；负数（默认 -1）使用堆叠的 `spacing`。
   */
  spacingBefore: number = -1;
  /** [EN] The icon color of the item (a template / symbol image takes it); '' uses the stack's `iconColor`. [CN] 条目的图标颜色（模板 / 符号图片按此着色）；'' 时使用堆叠的 `iconColor`。 */
  iconColor: string = '';
  /** [EN] The icon color while the item view is selected; '' uses the stack's `selectedIconColor`, then `iconColor`. [CN] 条目视图选中时的图标颜色；'' 时依次使用堆叠的 `selectedIconColor` 与 `iconColor`。 */
  selectedIconColor: string = '';
  /**
   * [EN] Whether the item is enabled (true by default). A disabled item is drawn dimmed and, by default, is not interactive
   *      (`CYLAnimatedItemStackModel.isItemInteractive`): its action does not run and a tap on it reaches the background.
   * [CN] 条目是否可用（默认 true）。不可用的条目变暗显示，默认也不可交互（`CYLAnimatedItemStackModel.isItemInteractive`）：不执行其动作，点击会到达背景。
   */
  enabled: boolean = true;
  /** [EN] The animation tint of this item; '' inherits the stack's `animationTint`. [CN] 该条目的动画着色；'' 时继承堆叠的 `animationTint`。 */
  animationTint: string = '';
  /** [EN] The dark animation tint of this item; '' inherits the stack's `animationDarkTint`. [CN] 该条目的深色动画着色；'' 时继承堆叠的 `animationDarkTint`。 */
  animationDarkTint: string = '';
  /** [EN] Hidden items are not drawn and leave no spacing (the next visible one is the first). [CN] 隐藏的条目不绘制，也不留间距（下一个可见条目成为第一个）。 */
  isHidden: boolean = false;
  /** [EN] The opacity 0...1 (a faded item keeps its place). [CN] 不透明度 0...1（变淡的条目保留位置）。 */
  alpha: number = 1;

  constructor(title: string = '', image: Object | string = '', animationUrl: string = '') {
    cylNextStackItemNumber += 1;
    this.id = `cyl-stack-item-${cylNextStackItemNumber}`;
    this.title = title;
    this.image = image;
    this.animationUrl = animationUrl;
  }
}

/**
 * [EN] One drawn element of the stack: an item, or the divider right after `item` (`isDivider`). Internal to the component.
 * [CN] 堆叠中绘制的一个元素：一个条目，或 `item` 之后紧邻的分隔线（`isDivider`）。组件内部使用。
 */
export class CYLAnimatedItemStackElement {
  readonly item: CYLAnimatedItemStackItem;
  readonly isDivider: boolean;
  /** [EN] The vp before the element (0 for the first): a divider's `dividerGapBefore`, an item after a divider the divider's `dividerGapAfter`. [CN] 元素之前的间距（第一个为 0）。 */
  readonly spacingBefore: number;

  constructor(item: CYLAnimatedItemStackItem, isDivider: boolean, spacingBefore: number = 0) {
    this.item = item;
    this.isDivider = isDivider;
    this.spacingBefore = spacingBefore;
  }

  /** [EN] A key unique among the elements. [CN] 元素间唯一的键。 */
  get key(): string {
    return this.isDivider ? `${this.item.id}-divider` : this.item.id;
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
  private readonly entries: CYLAnimatedItemStackItem[] = [];
  private readonly actions: Map<CYLAnimatedItemStackItem, string> = new Map();
  private readonly handlers: Map<string, CYLAnimatedItemStackActionHandler> = new Map();
  private readonly listeners: (() => void)[] = [];
  private margin: number = CYLAnimatedItemStackDefaultSpacing;
  private stackAxis: string = 'vertical';
  private stackSpacing: number = CYLAnimatedItemStackDefaultSpacing;
  private stackIconColor: string = '';
  private stackSelectedIconColor: string = '';
  private stackAnimationTint: string = '';
  private stackAnimationDarkTint: string = '';
  private stackDividerColor: string = '';
  private stackDividerLength: number = CYLAnimatedItemDividerLength;
  private dividersShown: boolean = false;
  private readonly dividerOverrides: Map<CYLAnimatedItemStackItem, CYLAnimatedItemDividerSpec> = new Map();
  private stackDividerSpacingBefore: number | undefined = undefined;
  private stackDividerSpacingAfter: number | undefined = undefined;
  private taps: boolean = true;
  private hugs: boolean = false;
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
    items.forEach((item: CYLAnimatedItemStackItem) => this.append(item));
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
   * [EN] Appends `item` after the last one, `spacingBefore` vp from it (ignored for the first item, negative counts as 0;
   *      undefined keeps the item's own `spacingBefore`, by default the stack's `spacing`);
   *      a tap on it performs `action` when that is not undefined or ''. An item already in the stack is left where it is.
   * [CN] 在最后一个条目下方 `spacingBefore` vp 处追加 `item`（第一个条目忽略，负数按 0）；`action` 不为 undefined 或 '' 时点击它执行该动作。
   *      已在堆叠中的条目保持原位。
   */
  append(item: CYLAnimatedItemStackItem, action?: string, spacingBefore?: number): void {
    if (this.entries.includes(item)) {
      return;
    }
    if (spacingBefore !== undefined) {
      item.spacingBefore = Math.max(0, spacingBefore);
    }
    this.entries.push(item);
    this.storeAction(action, item);
    this.update();
  }

  /**
   * [EN] Makes, appends and returns an item (icon above the title, the title wrapped to the width).
   * [CN] 创建、追加并返回一个条目（图标在标题上方，标题按宽度换行）。
   */
  appendItem(title: string, image: Object | string = '', animationUrl: string = '', action?: string,
    spacingBefore?: number): CYLAnimatedItemStackItem {
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
    this.dividerOverrides.delete(item);
    this.update();
  }

  /**
   * [EN] Inserts `item` at `index` (clamped to 0...count; an item already in the stack is moved there instead).
   * [CN] 在 `index`（限制在 0...数量）处插入 `item`；已在堆叠中的条目改为移到该位置。
   */
  insert(item: CYLAnimatedItemStackItem, index: number, action?: string, spacingBefore?: number): void {
    if (this.entries.includes(item)) {
      this.move(item, index);
      return;
    }
    if (spacingBefore !== undefined) {
      item.spacingBefore = Math.max(0, spacingBefore);
    }
    this.entries.splice(Math.max(0, Math.min(this.entries.length, index)), 0, item);
    this.storeAction(action, item);
    this.update();
  }

  /** [EN] Moves an item of the stack to `index` (clamped); its action goes with it. [CN] 把堆叠中的条目移到 `index`（限制范围）；动作随之移动。 */
  move(item: CYLAnimatedItemStackItem, index: number): void {
    const from = this.entries.indexOf(item);
    if (from < 0) {
      return;
    }
    this.entries.splice(from, 1);
    this.entries.splice(Math.max(0, Math.min(this.entries.length, index)), 0, item);
    this.update();
  }

  /**
   * [EN] Replaces the order with `items` (the items already in the stack, in the new order; the ones left out are removed, new ones appended).
   * [CN] 以 `items` 替换顺序（已在堆叠中的条目按新顺序排列；未包含的被移除，新的被追加）。
   */
  setItems(items: CYLAnimatedItemStackItem[]): void {
    this.entries.slice().forEach((item: CYLAnimatedItemStackItem) => {
      if (!items.includes(item)) {
        this.actions.delete(item);
        this.dividerOverrides.delete(item);
      }
    });
    this.entries.length = 0;
    items.forEach((item: CYLAnimatedItemStackItem) => {
      if (!this.entries.includes(item)) {
        this.entries.push(item);
      }
    });
    this.update();
  }

  /** [EN] The items that are drawn (not hidden), top to bottom. [CN] 绘制的（未隐藏的）条目，自上而下。 */
  get visibleItems(): CYLAnimatedItemStackItem[] {
    return this.entries.filter((item: CYLAnimatedItemStackItem) => !item.isHidden);
  }

  /** [EN] Sets or, with undefined or '', removes the action of an item in the stack. [CN] 设置堆叠中条目的动作；传 undefined 或 '' 移除。 */
  setAction(action: string | undefined, item: CYLAnimatedItemStackItem): void {
    if (!this.entries.includes(item)) {
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
    if (!this.taps) {
      return false;
    }
    const action = this.actions.get(item);
    if (action !== undefined && this.isItemInteractive(item)) {
      return this.performAction(action);
    }
    return this.actsOnBackground(item) ? this.tapBackground() : false;
  }

  /** [EN] A tap on the background (the view calls it). [CN] 点击背景（由视图调用）。 */
  tapBackground(): boolean {
    if (!this.taps) {
      return false;
    }
    return this.background !== undefined ? this.performAction(this.background) : false;
  }

  // [EN] Touches and the screen reader. [CN] 触摸与读屏。

  /**
   * [EN] Whether an item is interactive: its tap performs its action, a tap on it is not a background tap, and a screen
   *      reader reads it as a button. By default: it has an action and it is `enabled`. Override in a subclass for items
   *      with their own switch (CYLTableViewPlaceHolder's tap interaction), then call `updateInteractionOfItemViews()` after
   *      that switch changes. The same check as iOS `isItemViewInteractive(_:)` and Android `isItemInteractive`.
   * [CN] 条目是否可交互：点击执行其动作，点击它不算背景点击，读屏把它作为按钮朗读。默认：有动作且 `enabled`。条目有自己的开关时（CYLTableViewPlaceHolder
   *      的点击交互）在子类中重写，并在开关变化后调用 `updateInteractionOfItemViews()`。与 iOS `isItemViewInteractive(_:)`、Android `isItemInteractive` 相同。
   */
  isItemInteractive(item: CYLAnimatedItemStackItem): boolean {
    return this.taps && this.actions.has(item) && item.enabled && !item.isHidden;
  }

  /**
   * [EN] Applies `isItemInteractive` again to every item (the view redraws), after a change the stack cannot see.
   * [CN] 在堆叠无法感知的变化之后，对所有条目重新应用 `isItemInteractive`（视图重绘）。
   */
  updateInteractionOfItemViews(): void {
    this.update();
  }

  /**
   * [EN] Whether the item takes taps: an interactive item, and the first item while it stands for the background. Any other
   *      item lets a tap through to the background (`HitTestMode.None`).
   * [CN] 条目是否接收点击：可交互的条目，以及代表背景的第一个条目。其他条目让点击穿透到背景（`HitTestMode.None`）。
   */
  takesTaps(item: CYLAnimatedItemStackItem): boolean {
    return this.isItemInteractive(item) || this.actsOnBackground(item);
  }

  /**
   * [EN] The first item, while it is not interactive and there is a background action: it reads as a button for it.
   * [CN] 存在背景动作时、自身不可交互的第一个条目：它作为该动作的按钮朗读。
   */
  actsOnBackground(item: CYLAnimatedItemStackItem): boolean {
    return this.taps && !this.isItemInteractive(item) && this.background !== undefined && this.visibleItems[0] === item;
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
    return item.isHidden || (!this.takesTaps(item) && this.accessibilityTextOf(item).length === 0);
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

  /**
   * [EN] The direction of the stack (iOS `axis`): 'vertical' (default, one item under the other) or 'horizontal' (one
   *      row); anything else counts as 'vertical'.
   * [CN] 堆叠方向（iOS `axis`）：'vertical'（默认，上下排列）或 'horizontal'（一行）；其他值按 'vertical'。
   */
  get axis(): string {
    return this.stackAxis;
  }

  set axis(axis: string) {
    this.stackAxis = axis === 'horizontal' ? 'horizontal' : 'vertical';
    this.update();
  }

  /** [EN] Whether the items are in one row. [CN] 条目是否排成一行。 */
  get isHorizontal(): boolean {
    return this.stackAxis === 'horizontal';
  }

  /** [EN] The space between items without their own `spacingBefore` (iOS `spacing`; 16 by default, never negative). [CN] 没有自己 `spacingBefore` 的条目之间的间距（iOS `spacing`；默认 16，不为负）。 */
  get spacing(): number {
    return this.stackSpacing;
  }

  set spacing(spacing: number) {
    this.stackSpacing = Math.max(0, spacing);
    this.update();
  }

  /** [EN] The space before an item: 0 for the first, else its `spacingBefore` or the stack's `spacing`. [CN] 条目之前的间距：第一个为 0，否则为其 `spacingBefore` 或堆叠的 `spacing`。 */
  spacingBeforeOf(item: CYLAnimatedItemStackItem): number {
    if (!this.entries.includes(item) || item.isHidden || this.visibleItems[0] === item) {
      return 0;
    }
    const visible = this.visibleItems;
    const index = visible.indexOf(item);
    if (index > 0 && this.showsDividerAfter(visible[index - 1])) {
      return this.dividerGapAfter(visible[index - 1]);
    }
    return item.spacingBefore >= 0 ? item.spacingBefore : this.stackSpacing;
  }

  /**
   * [EN] The default icon color of the items (iOS `itemAppearance` of the stack): an item's own `iconColor` wins; '' for none.
   * [CN] 条目的默认图标颜色（iOS 堆叠的 `itemAppearance`）：条目自己的 `iconColor` 优先；'' 表示没有。
   */
  get iconColor(): string {
    return this.stackIconColor;
  }

  set iconColor(color: string) {
    this.stackIconColor = color;
    this.update();
  }

  /** [EN] The default icon color of selected item views; '' uses `iconColor`. [CN] 选中的条目视图的默认图标颜色；'' 时使用 `iconColor`。 */
  get selectedIconColor(): string {
    return this.stackSelectedIconColor;
  }

  set selectedIconColor(color: string) {
    this.stackSelectedIconColor = color;
    this.update();
  }

  /** [EN] Whether the stack handles taps itself (iOS `dispatchesItemTaps`, true by default). false: no item or background action runs and the component takes no touches, so the host row gets them. [CN] 堆叠是否自己处理点击（iOS `dispatchesItemTaps`，默认 true）。false：不执行任何条目或背景动作，组件不接收触摸，由宿主行处理。 */
  get dispatchesItemTaps(): boolean {
    return this.taps;
  }

  set dispatchesItemTaps(value: boolean) {
    this.taps = value;
    this.update();
  }

  /** [EN] Whether the stack is only as large as its items plus `contentMargin` (false by default: it fills its parent and centers the items). [CN] 堆叠是否只有条目加 `contentMargin` 那么大（默认 false：填满父组件并居中条目）。 */
  get hugsContent(): boolean {
    return this.hugs;
  }

  set hugsContent(value: boolean) {
    this.hugs = value;
    this.update();
  }

  /** [EN] The default `animationTint` of the items that set none; '' for none. [CN] 未设置者的默认 `animationTint`；'' 表示没有。 */
  get animationTint(): string {
    return this.stackAnimationTint;
  }

  set animationTint(value: string) {
    this.stackAnimationTint = value;
    this.update();
  }

  /** [EN] The default `animationDarkTint`. [CN] 默认的 `animationDarkTint`。 */
  get animationDarkTint(): string {
    return this.stackAnimationDarkTint;
  }

  set animationDarkTint(value: string) {
    this.stackAnimationDarkTint = value;
    this.update();
  }

  /**
   * [EN] The color of the dividers the stack draws (`showsDividers`, `setDivider`, `appendDivider`); '' (default) derives it: the stack's normal
   *      icon color (`iconColor`) at alpha 0.3, else the separator color of the color mode (`cylAnimatedItemDividerColor`).
   * [CN] 堆叠绘制的分隔线（`showsDividers`、`setDividerAfter`）的颜色；''（默认）时推导：堆叠的普通图标颜色（`iconColor`）加透明度 0.3，否则为当前颜色模式的分隔色。
   */
  get dividerColor(): string {
    return this.stackDividerColor;
  }

  set dividerColor(value: string) {
    this.stackDividerColor = value;
    this.update();
  }

  /** [EN] The effective animation tint of an item: its own, else the stack's. [CN] 条目生效的动画着色：自有，否则堆叠的。 */
  animationTintOf(item: CYLAnimatedItemStackItem): string {
    return cylAnimatedItemEffective(item.animationTint, this.stackAnimationTint);
  }

  /** [EN] The effective dark animation tint. [CN] 生效的深色动画着色。 */
  animationDarkTintOf(item: CYLAnimatedItemStackItem): string {
    return cylAnimatedItemEffective(item.animationDarkTint, this.stackAnimationDarkTint);
  }

  /** [EN] The length of a divider line in vp (default `CYLAnimatedItemDividerLength` = 20; never negative); it is 1 vp thick. [CN] 分隔线长度（vp，默认 20，不为负）；粗 1 vp。 */
  get dividerLength(): number {
    return this.stackDividerLength;
  }

  set dividerLength(value: number) {
    this.stackDividerLength = Math.max(0, value);
    this.update();
  }

  /** [EN] A divider between every two visible items (default false); `setDividerAfter` overrides single gaps. [CN] 每两个可见条目之间一条分隔线（默认 false）；`setDividerAfter` 可覆盖单个间隙。 */
  get showsDividers(): boolean {
    return this.dividersShown;
  }

  set showsDividers(value: boolean) {
    this.dividersShown = value;
    this.update();
  }

  /**
   * [EN] Puts a divider in the gap after `item` (the item owns it: it moves and goes with the item), `spacingBefore` vp after the item
   *      and `spacingAfter` vp before the next visible one; undefined falls back (see `gapAfter`). Replaces an earlier divider or "no
   *      divider" of that gap. Ignored for an item not in the stack.
   * [CN] 在 `item` 之后的间隙放一条分隔线（归该条目所有：随条目移动、随条目移除），距条目 `spacingBefore` vp、距下一个可见条目 `spacingAfter` vp；
   *      undefined 时使用后备值（见 `gapAfter`）。替换该间隙之前的分隔线或「无分隔线」。不在堆叠中的条目被忽略。
   */
  setDivider(item: CYLAnimatedItemStackItem, spacingBefore?: number, spacingAfter?: number): void {
    if (!this.entries.includes(item)) {
      return;
    }
    const spec = new CYLAnimatedItemDividerSpec();
    spec.spacingBefore = spacingBefore === undefined ? undefined : Math.max(0, spacingBefore);
    spec.spacingAfter = spacingAfter === undefined ? undefined : Math.max(0, spacingAfter);
    this.dividerOverrides.set(item, spec);
    this.update();
  }

  /**
   * [EN] Attaches a divider after the CURRENT LAST item (append flow: `append(a); appendDivider(8, 8); append(b)`); nothing on an empty stack.
   * [CN] 在当前最后一个条目之后附加分隔线（追加流程：`append(a); appendDivider(8, 8); append(b)`）；堆叠为空时什么都不做。
   */
  appendDivider(spacingBefore?: number, spacingAfter?: number): void {
    if (this.entries.length > 0) {
      this.setDivider(this.entries[this.entries.length - 1], spacingBefore, spacingAfter);
    }
  }

  /** [EN] Turns the gap after `item` off, even when `showsDividers` is true. [CN] 关闭 `item` 之后的间隙分隔线，即使 `showsDividers` 为 true。 */
  removeDivider(item: CYLAnimatedItemStackItem): void {
    if (!this.entries.includes(item)) {
      return;
    }
    const spec = new CYLAnimatedItemDividerSpec();
    spec.shown = false;
    this.dividerOverrides.set(item, spec);
    this.update();
  }

  /** [EN] Whether the gap after `item` is set to have a divider: its own, else `showsDividers` (visibility rules: `showsDividerAfter`). [CN] `item` 之后的间隙是否设置了分隔线：自己的，否则为 `showsDividers`（可见性规则见 `showsDividerAfter`）。 */
  hasDivider(item: CYLAnimatedItemStackItem): boolean {
    const spec = this.dividerOverrides.get(item);
    return spec !== undefined ? spec.shown : this.dividersShown;
  }

  /** [EN] Alias: true is `setDivider(item)`, false `removeDivider(item)`, undefined forgets the item's own setting (`showsDividers` decides). [CN] 别名：true 为 `setDivider(item)`，false 为 `removeDivider(item)`，undefined 忘记该条目自己的设置（由 `showsDividers` 决定）。 */
  setDividerAfter(item: CYLAnimatedItemStackItem, shown: boolean | undefined): void {
    if (shown === true) {
      this.setDivider(item);
    } else if (shown === false) {
      this.removeDivider(item);
    } else if (this.dividerOverrides.delete(item)) {
      this.update();
    }
  }

  /** [EN] Alias of `hasDivider`. [CN] `hasDivider` 的别名。 */
  dividerAfter(item: CYLAnimatedItemStackItem): boolean {
    return this.hasDivider(item);
  }

  /** [EN] The next visible item after `item`; undefined for none. [CN] `item` 之后的下一个可见条目；没有时为 undefined。 */
  private nextVisible(item: CYLAnimatedItemStackItem): CYLAnimatedItemStackItem | undefined {
    const index = this.entries.indexOf(item);
    for (let i = index + 1; i < this.entries.length; i++) {
      if (!this.entries[i].isHidden) {
        return this.entries[i];
      }
    }
    return undefined;
  }

  /** [EN] Whether a divider is drawn after `item`: the item is visible, a visible item follows and `hasDivider`. [CN] `item` 之后是否绘制分隔线：条目可见、其后有可见条目，且 `hasDivider`。 */
  showsDividerAfter(item: CYLAnimatedItemStackItem): boolean {
    return this.entries.includes(item) && !item.isHidden && this.hasDivider(item) && this.nextVisible(item) !== undefined;
  }

  /** [EN] Whether a divider is drawn right before `item`. [CN] `item` 之前是否绘制分隔线。 */
  showsDividerBefore(item: CYLAnimatedItemStackItem): boolean {
    const visible = this.visibleItems;
    const index = visible.indexOf(item);
    return index > 0 && this.showsDividerAfter(visible[index - 1]);
  }

  /** [EN] The space from the owner to its divider: the divider's own, else the stack's `dividerSpacingBefore`, else `spacing`. [CN] 条目到其分隔线的间距：分隔线自己的，否则堆叠的 `dividerSpacingBefore`，否则 `spacing`。 */
  dividerGapBefore(item: CYLAnimatedItemStackItem): number {
    return this.dividerOverrides.get(item)?.spacingBefore ?? this.stackDividerSpacingBefore ?? this.stackSpacing;
  }

  /**
   * [EN] The space from the divider to the next visible item: the divider's own, else the stack's `dividerSpacingAfter`, else that item's
   *      `spacingBefore`, else `spacing`. The next item's own spacing is only this fallback, never added on top.
   * [CN] 分隔线到下一个可见条目的间距：分隔线自己的，否则堆叠的 `dividerSpacingAfter`，否则该条目的 `spacingBefore`，否则 `spacing`。
   *      下一个条目自己的间距只作为这个后备值，绝不叠加。
   */
  dividerGapAfter(item: CYLAnimatedItemStackItem): number {
    const next = this.nextVisible(item);
    const fallback = next !== undefined && next.spacingBefore >= 0 ? next.spacingBefore : this.stackSpacing;
    return this.dividerOverrides.get(item)?.spacingAfter ?? this.stackDividerSpacingAfter ?? fallback;
  }

  /**
   * [EN] The whole gap between `item` and the next visible item, undefined when there is none: with a divider before + thickness (1) +
   *      after (spacing 12, divider(8, 8): 8 + 1 + 8 = 17); without one the next item's `spacingBefore` or `spacing`.
   * [CN] `item` 与下一个可见条目之间的整个间隙，没有下一个时为 undefined：有分隔线时为 之前 + 粗细（1）+ 之后（spacing 12、divider(8, 8)：
   *      8 + 1 + 8 = 17）；没有时为下一个条目的 `spacingBefore` 或 `spacing`。
   */
  gapAfter(item: CYLAnimatedItemStackItem): number | undefined {
    const next = this.nextVisible(item);
    if (!this.entries.includes(item) || item.isHidden || next === undefined) {
      return undefined;
    }
    if (this.showsDividerAfter(item)) {
      return this.dividerGapBefore(item) + CYLAnimatedItemDividerThickness + this.dividerGapAfter(item);
    }
    return next.spacingBefore >= 0 ? next.spacingBefore : this.stackSpacing;
  }

  /** [EN] The stack default of the space before a divider; undefined (default) uses `spacing`. [CN] 分隔线之前间距的堆叠默认值；undefined（默认）使用 `spacing`。 */
  get dividerSpacingBefore(): number | undefined {
    return this.stackDividerSpacingBefore;
  }

  set dividerSpacingBefore(value: number | undefined) {
    this.stackDividerSpacingBefore = value === undefined ? undefined : Math.max(0, value);
    this.update();
  }

  /** [EN] The stack default of the space after a divider; undefined (default) uses the next item's `spacingBefore`, else `spacing`. [CN] 分隔线之后间距的堆叠默认值；undefined（默认）使用下一个条目的 `spacingBefore`，否则 `spacing`。 */
  get dividerSpacingAfter(): number | undefined {
    return this.stackDividerSpacingAfter;
  }

  set dividerSpacingAfter(value: number | undefined) {
    this.stackDividerSpacingAfter = value === undefined ? undefined : Math.max(0, value);
    this.update();
  }

  /**
   * [EN] What the component draws, top to bottom: the visible items with the dividers between them. The items list (`items`) never
   *      holds dividers; they follow the items by themselves when items are appended, removed, moved or hidden.
   * [CN] 组件绘制的内容，自上而下：可见条目及其间的分隔线。条目列表（`items`）不含分隔线；追加、移除、移动或隐藏条目时分隔线自动跟随。
   */
  get elements(): CYLAnimatedItemStackElement[] {
    const result: CYLAnimatedItemStackElement[] = [];
    this.visibleItems.forEach((item: CYLAnimatedItemStackItem) => {
      result.push(new CYLAnimatedItemStackElement(item, false, this.spacingBeforeOf(item)));
      if (this.showsDividerAfter(item)) {
        result.push(new CYLAnimatedItemStackElement(item, true, this.dividerGapBefore(item)));
      }
    });
    return result;
  }

  /** [EN] The icon color an item view draws with ('' leaves the image as it is). [CN] 条目视图绘制时使用的图标颜色（'' 表示保持图片原样）。 */
  iconColorOf(item: CYLAnimatedItemStackItem, selected: boolean = false): string {
    if (selected) {
      const color = item.selectedIconColor || this.stackSelectedIconColor;
      if (color) {
        return color;
      }
    }
    return item.iconColor || this.stackIconColor;
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
    const index = this.listeners.indexOf(listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }
}
