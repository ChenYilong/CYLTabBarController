import { CYLAnimatedItemView, CYLAnimatedItemAxis, CYLAnimatedItemAnimationContext } from './CYLAnimatedItemView';
import { CYLAnimatedItemBackgroundStyle, CYLAnimatedItemBackgroundModifier } from './CYLAnimatedItemBackground';
import { CYLAnimatedItemStackModel, CYLAnimatedItemStackItem, CYLAnimatedItemStackElement } from './CYLAnimatedItemStackModel';
import { deviceInfo } from '@kit.BasicServicesKit';
import { LifecycleController } from 'cylutils';

/**
 * [EN] The screen reader role of a stack item: a button when it acts, text otherwise. `accessibilityRole` exists from API 18
 *      and this module supports API 12, so it is set only where the system has it.
 * [CN] 堆叠条目的读屏角色：可执行动作时为按钮，否则为文字。`accessibilityRole` 从 API 18 起提供，而本模块支持 API 12，因此只在系统提供时设置。
 */
class CYLStackItemRoleModifier implements AttributeModifier<ColumnAttribute> {
  isButton: boolean = false;

  constructor(isButton: boolean) {
    this.isButton = isButton;
  }

  applyNormalAttribute(instance: ColumnAttribute): void {
    if (deviceInfo.sdkApiVersion >= 18) {
      instance.accessibilityRole(this.isButton ? AccessibilityRoleType.BUTTON : AccessibilityRoleType.TEXT);
    }
  }
}

/**
 * [EN] A centered vertical stack whose every element is a `CYLAnimatedItemView` (an animated icon above a title): an empty
 *      state, a placeholder, an onboarding card. The HarmonyOS counterpart of iOS `CYLAnimatedItemStackView` (generic form
 *      of CYLTableViewPlaceHolder's `CYLPlaceholderStackView`). Its items, actions and handlers live in `model`
 *      (`CYLAnimatedItemStackModel`): a tap on an item with an action runs that action's handler; a tap anywhere else runs
 *      `backgroundAction` (an item without an action takes no taps, so the tap reaches the background). Titles wrap to the
 *      view's width minus `contentMargin` on each side. Screen reader: the items are read one by one, top to bottom; an item
 *      with an action is a button, decoration (no title, no accessibility text, no action) is hidden, and the first item
 *      reads as a button for the background action when it has no action of its own. `animationBuilder` is handed to every
 *      item, as `CYLAnimatedItemView.animationBuilder`.
 * [CN] 每个元素都是 `CYLAnimatedItemView`（动效图标在标题上方）的居中竖向堆叠：空状态、占位图、引导卡片。对应 iOS 的 `CYLAnimatedItemStackView`
 *      （CYLTableViewPlaceHolder `CYLPlaceholderStackView` 的通用形式）。条目、动作与处理保存在 `model`（`CYLAnimatedItemStackModel`）中：点击带动作的条目
 *      执行该动作的处理；点击其他位置执行 `backgroundAction`（没有动作的条目不接收点击，点击会到达背景）。标题按视图宽度减去两侧 `contentMargin` 换行。
 *      读屏：条目自上而下逐个朗读；带动作的条目是按钮，装饰条目（无标题、无无障碍文字、无动作）隐藏，第一个条目没有自己的动作时作为背景动作的按钮朗读。
 *      `animationBuilder` 传给每个条目，与 `CYLAnimatedItemView.animationBuilder` 相同。
 */
@Component
export struct CYLAnimatedItemStackView {
  /** [EN] The items, actions and handlers. [CN] 条目、动作与处理。 */
  model: CYLAnimatedItemStackModel = new CYLAnimatedItemStackModel();
  /** [EN] The title color of every item. [CN] 所有条目的标题颜色。 */
  /**
   * [EN] The background of the whole stack, the same rules as `CYLAnimatedItemView`: `flat` (default) fills it with `itemBackgroundColor`;
   *      `liquidGlass` draws the glass (a blur imitation) behind the items where `CYLLiquidGlass.isActive()`, flat elsewhere. Nothing
   *      is drawn until one of the `item…` background properties is set (the shared `CYLAnimatedItemBackgroundModifier`).
   * [CN] 整个堆叠的背景，规则与 `CYLAnimatedItemView` 相同：`flat`（默认）用 `itemBackgroundColor` 填充；`liquidGlass` 在 `CYLLiquidGlass.isActive()` 时于
   *      条目后面绘制玻璃（模糊仿制），否则为扁平。设置任一 `item…` 背景属性之前不绘制任何背景（共用 `CYLAnimatedItemBackgroundModifier`）。
   */
  @Prop itemBackgroundStyle: CYLAnimatedItemBackgroundStyle = CYLAnimatedItemBackgroundStyle.flat;
  /** [EN] The fill (flat) or the tint (glass); '' for none. [CN] 填充色（扁平）或着色（玻璃）；'' 表示无。 */
  @Prop itemBackgroundColor: ResourceColor = '';
  /**
   * [EN] The corner radius in vp: 0 is square, `CYLAnimatedItemCornerRadiusCapsule` a capsule, any other value vp (limited to half the
   *      height by the platform); -1 (the default) is a capsule for Liquid Glass and square for flat.
   * [CN] 圆角半径（vp）：0 为直角，`CYLAnimatedItemCornerRadiusCapsule` 为胶囊，其他值为 vp（平台会截断到半高）；-1（默认）时液态玻璃为胶囊、扁平为直角。
   */
  @Prop itemCornerRadius: number = -1;
  /**
   * [EN] The space between the stack's outer border and its items on the left and right, in vp, added to `contentMargin` horizontally only; -1 (the
   *      default) is `CYLAnimatedItemLiquidGlassContentInset` for the drawn Liquid Glass and 0 for flat, as `CYLAnimatedItemView.itemContentHorizontalInset`.
   * [CN] 堆叠外侧边框与条目之间左右的间距（vp），仅在水平方向叠加到 `contentMargin` 上；-1（默认）时绘制液态玻璃为 `CYLAnimatedItemLiquidGlassContentInset`、
   *      扁平为 0，与 `CYLAnimatedItemView.itemContentHorizontalInset` 相同。
   */
  @Prop itemContentHorizontalInset: number = -1;
  /** [EN] The border width in vp. [CN] 边框宽度（vp）。 */
  @Prop itemBorderWidth: number = 0;
  /** [EN] The border color. [CN] 边框颜色。 */
  @Prop itemBorderColor: ResourceColor = '';
  /** [EN] The share of the color's alpha that tints a Liquid Glass: -1 (the default) is 0.75, 1 the color as it is. [CN] 颜色透明度中用于给液态玻璃着色的比例：-1（默认）为 0.75，1 为原色。 */
  @Prop itemGlassTintAlpha: number = -1;
  @Prop titleColor: ResourceColor = '';
  /** [EN] The title font size of every item. [CN] 所有条目的标题字号。 */
  @Prop titleFontSize: number = 16;
  @BuilderParam animationBuilder: (context: CYLAnimatedItemAnimationContext) => void = this.cylNoAnimation;
  @State private revision: number = 0;
  @State private viewWidth: number = 0;
  private cylListener: () => void = () => {
    this.revision = this.model.revision;
  };

  @Builder
  cylNoAnimation(context: CYLAnimatedItemAnimationContext) {
  }

  private cylLifecycle: LifecycleController<CYLAnimatedItemStackView> | undefined = undefined;

  aboutToAppear(): void {
    this.cylLifecycle = new LifecycleController<CYLAnimatedItemStackView>(this);
    this.model.addListener(this.cylListener);
    // [EN] Paired with the listener above: the keyed teardown block removes it (CYLDeallocBlockExecutor). [CN] 与上面的监听配对：带 key 的销毁块移除它（CYLDeallocBlockExecutor）。
    const model = this.model;
    const listener = this.cylListener;
    this.cylLifecycle.registry.addDeallocCallback<CYLAnimatedItemStackView>(() => model.removeListener(listener), { key: 'cyl.stack.listener' });
    this.cylLifecycle.aboutToAppear();
    this.revision = this.model.revision;
  }

  aboutToDisappear(): void {
    this.cylLifecycle?.aboutToDisappear();
  }

  /** [EN] The items; reads `revision`, so every model change redraws the stack. [CN] 条目；读取 `revision`，模型每次变化都会重绘。 */
  private cylItems(): CYLAnimatedItemStackItem[] {
    return this.revision >= 0 ? this.model.items : [];
  }

  /** [EN] What is drawn: the visible items (a hidden item leaves no spacing) and the dividers between them. [CN] 绘制的内容：可见条目（隐藏的条目不留间距）及其间的分隔线。 */
  private cylElementList(): CYLAnimatedItemStackElement[] {
    return this.revision >= 0 ? this.model.elements : [];
  }

  /** [EN] The inset really applied (vp). [CN] 实际应用的间距（vp）。 */
  private cylContentInset(): number {
    return CYLAnimatedItemBackgroundModifier.resolvedContentInset(this.itemBackgroundStyle, this.itemContentHorizontalInset);
  }

  private cylMaxItemWidth(): number | undefined {
    return this.viewWidth > 0 && !this.model.hugsContent ? this.model.maxItemWidth(this.viewWidth - 2 * this.cylContentInset()) : undefined;
  }

  @Builder
  cylItemView(item: CYLAnimatedItemStackItem) {
    CYLAnimatedItemView({
      itemTitle: item.title,
      image: item.image as ResourceStr,
      animationUrl: item.animationUrl,
      axis: CYLAnimatedItemAxis.Vertical,
      iconSize: item.iconSize,
      titleLines: item.titleLines,
      titleColor: item.titleColor,
      selectedTitleColor: item.selectedTitleColor,
      stackTitleColor: this.titleColor !== '' ? this.titleColor : this.model.titleColor,
      stackSelectedTitleColor: this.model.selectedTitleColor,
      titleFontSize: this.titleFontSize,
      itemId: item.id,
      isItemEnabled: item.enabled,
      // [EN] The item's OWN explicit colors and the stack's explicit ones go separately: the item resolves item > stack > built-in with its own
      //      state and color mode. [CN] 条目自己的显式颜色与堆叠的显式颜色分开传入：条目按自己的状态与颜色模式解析 条目 > 堆叠 > 内置。
      iconColor: item.iconColor,
      selectedIconColor: item.selectedIconColor,
      disabledIconColor: item.disabledIconColor,
      stackIconColor: this.model.iconColor,
      stackSelectedIconColor: this.model.selectedIconColor,
      stackDisabledIconColor: this.model.disabledIconColor,
      animationRenderingMode: item.animationRenderingMode,
      stackAnimationRenderingMode: this.model.animationRenderingMode,
      animationTint: item.animationTint,
      animationDarkTint: item.animationDarkTint,
      stackAnimationTint: this.model.animationTint,
      stackAnimationDarkTint: this.model.animationDarkTint,
      isBare: true,
      sizesToContent: true,
      animationBuilder: this.animationBuilder,
    })
  }

  @Builder
  cylElements() {
        ForEach(this.cylElementList(), (element: CYLAnimatedItemStackElement) => {
          if (element.isDivider) {
            // [EN] The divider is an item view owned by the stack (internal divider mode), with the stack's effective icon color and
            //      tint inheritance, like every item. [CN] 分隔线是堆叠拥有的条目视图（内部分隔线模式），与所有条目一样使用堆叠生效的图标颜色与着色继承。
            CYLAnimatedItemView({
              cylInternalDivider: true,
              cylInternalDividerColor: this.model.dividerColor,
              cylInternalDividerLength: this.model.dividerLength,
              cylInternalDividerVertical: this.model.isHorizontal,
              stackIconColor: this.model.iconColor,
              stackAnimationTint: this.model.animationTint,
              stackAnimationDarkTint: this.model.animationDarkTint,
              isBare: true,
              sizesToContent: true,
              itemId: element.key
            })
              .margin(this.model.isHorizontal ? { left: element.spacingBefore } : { top: element.spacingBefore })
          } else {
            this.cylItemElement(element.item, element.spacingBefore)
          }
        }, (element: CYLAnimatedItemStackElement) => `${element.key}#${this.revision}`)
  }

  @Builder
  cylItemElement(item: CYLAnimatedItemStackItem, spacingBefore: number) {
          // [EN] Each element is a wrapper around a bare item view: the wrapper takes the tap and is what the screen reader
          //      reads; the item view only draws (`isBare`), sized by its content (B29). Only an element that acts gets a
          //      click, so the others are not announced as actionable and let a tap through to the background.
          // [CN] 每个元素是包裹纯绘制条目视图（`isBare`）的容器：容器接收点击并由读屏朗读，条目视图按内容决定尺寸（B29）。只有可执行动作的元素才有点击，
          //      其他元素不会被读作可操作，并让点击穿透到背景。
          if (this.model.takesTaps(item)) {
            Column() {
              this.cylItemView(item)
            }
            .margin(this.model.isHorizontal ? { left: spacingBefore } : { top: spacingBefore })
            .constraintSize({ maxWidth: this.cylMaxItemWidth() })
            .opacity(item.alpha)
            .id(`${item.id}-element`)
            .onClick(() => {
              this.model.tapItem(item);
            })
            .attributeModifier(new CYLStackItemRoleModifier(true))
            .accessibilityGroup(true)
            .accessibilityText(this.model.accessibilityTextOf(item))
            .accessibilityLevel('yes')
          } else {
            Column() {
              this.cylItemView(item)
            }
            .margin(this.model.isHorizontal ? { left: spacingBefore } : { top: spacingBefore })
            .constraintSize({ maxWidth: this.cylMaxItemWidth() })
            .opacity(item.alpha)
            .id(`${item.id}-element`)
            .hitTestBehavior(HitTestMode.None)
            .attributeModifier(new CYLStackItemRoleModifier(false))
            .accessibilityGroup(true)
            .accessibilityText(this.model.accessibilityTextOf(item))
            .accessibilityLevel(this.model.isAccessibilityHidden(item) ? 'no-hide-descendants' : 'yes')
          }
  }

  build() {
    Column() {
      // [EN] One column (default) or one row (`axis` 'horizontal', iOS `axis`). [CN] 一列（默认）或一行（`axis` 为 'horizontal'，iOS `axis`）。
      if (this.model.isHorizontal && this.revision >= 0) {
        Row() {
          this.cylElements()
        }
        .alignItems(VerticalAlign.Center)
      } else {
        Column() {
          this.cylElements()
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width(this.model.hugsContent ? undefined : '100%')
    .height(this.model.hugsContent ? undefined : '100%')
    // [EN] `dispatchesItemTaps` false: the stack takes no touches, the host row gets them. [CN] `dispatchesItemTaps` 为 false：堆叠不接收触摸，由宿主行处理。
    .hitTestBehavior(this.model.dispatchesItemTaps ? HitTestMode.Default : HitTestMode.None)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: this.model.contentMargin, bottom: this.model.contentMargin,
      left: this.model.contentMargin + this.cylContentInset(), right: this.model.contentMargin + this.cylContentInset() })
    .attributeModifier(new CYLAnimatedItemBackgroundModifier(this.itemBackgroundStyle, this.itemBackgroundColor !== '' ? this.itemBackgroundColor : Color.Transparent,
      this.itemCornerRadius, this.itemBorderWidth, this.itemBorderColor !== '' ? this.itemBorderColor : Color.Transparent, this.itemGlassTintAlpha))
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.viewWidth = Number(newValue.width);
    })
    .onClick(() => {
      this.model.tapBackground();
    })
  }
}
