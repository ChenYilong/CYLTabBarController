import { CYLAnimatedItemView, CYLAnimatedItemAxis, CYLAnimatedItemAnimationContext } from './CYLAnimatedItemView';
import { CYLAnimatedItemBackgroundStyle, CYLAnimatedItemBackgroundModifier } from './CYLAnimatedItemBackground';
import { CYLAnimatedItemStackModel, CYLAnimatedItemStackItem } from './CYLAnimatedItemStackModel';
import { deviceInfo } from '@kit.BasicServicesKit';
import { LifecycleController } from 'cyldeallocblockexecutor';

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
  /** [EN] The border width in vp. [CN] 边框宽度（vp）。 */
  @Prop itemBorderWidth: number = 0;
  /** [EN] The border color. [CN] 边框颜色。 */
  @Prop itemBorderColor: ResourceColor = '';
  @Prop titleColor: ResourceColor = '#333333';
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

  /** [EN] The key of an item for ForEach: its id and the revision, so a changed field redraws it. [CN] ForEach 的键：id 加修订号，字段变化后重绘。 */
  private cylKey(item: CYLAnimatedItemStackItem): string {
    return `${item.id}#${this.revision}`;
  }

  /** [EN] The items; reads `revision`, so every model change redraws the stack. [CN] 条目；读取 `revision`，模型每次变化都会重绘。 */
  private cylItems(): CYLAnimatedItemStackItem[] {
    return this.revision >= 0 ? this.model.items : [];
  }

  private cylMaxItemWidth(): number | undefined {
    return this.viewWidth > 0 ? this.model.maxItemWidth(this.viewWidth) : undefined;
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
      titleColor: this.titleColor,
      titleFontSize: this.titleFontSize,
      itemId: item.id,
      isItemEnabled: item.enabled,
      iconColor: this.model.iconColorOf(item),
      isBare: true,
      sizesToContent: true,
      animationBuilder: this.animationBuilder,
    })
  }

  /** [EN] The space before an element: above it, or on its leading side in a row. [CN] 元素之前的间距：上方，或在一行中的前侧。 */
  private cylMarginOf(item: CYLAnimatedItemStackItem): Margin {
    const spacing = this.model.spacingBeforeOf(item);
    return this.model.isHorizontal ? { left: spacing } : { top: spacing };
  }

  @Builder
  cylElements() {
        ForEach(this.cylItems(), (item: CYLAnimatedItemStackItem) => {
          // [EN] Each element is a wrapper around a bare item view: the wrapper takes the tap and is what the screen reader
          //      reads; the item view only draws (`isBare`), sized by its content (B29). Only an element that acts gets a
          //      click, so the others are not announced as actionable and let a tap through to the background.
          // [CN] 每个元素是包裹纯绘制条目视图（`isBare`）的容器：容器接收点击并由读屏朗读，条目视图按内容决定尺寸（B29）。只有可执行动作的元素才有点击，
          //      其他元素不会被读作可操作，并让点击穿透到背景。
          if (this.model.takesTaps(item)) {
            Column() {
              this.cylItemView(item)
            }
            .margin(this.cylMarginOf(item))
            .constraintSize({ maxWidth: this.cylMaxItemWidth() })
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
            .margin(this.cylMarginOf(item))
            .constraintSize({ maxWidth: this.cylMaxItemWidth() })
            .id(`${item.id}-element`)
            .hitTestBehavior(HitTestMode.None)
            .attributeModifier(new CYLStackItemRoleModifier(false))
            .accessibilityGroup(true)
            .accessibilityText(this.model.accessibilityTextOf(item))
            .accessibilityLevel(this.model.isAccessibilityHidden(item) ? 'no-hide-descendants' : 'yes')
          }
        }, (item: CYLAnimatedItemStackItem) => this.cylKey(item))
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
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(this.model.contentMargin)
    .attributeModifier(new CYLAnimatedItemBackgroundModifier(this.itemBackgroundStyle, this.itemBackgroundColor !== '' ? this.itemBackgroundColor : Color.Transparent,
      this.itemCornerRadius, this.itemBorderWidth, this.itemBorderColor !== '' ? this.itemBorderColor : Color.Transparent))
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.viewWidth = Number(newValue.width);
    })
    .onClick(() => {
      this.model.tapBackground();
    })
  }
}
