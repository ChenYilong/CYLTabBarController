import { CYLPlusButton, CYLTabBarAppearance, CYLTabBarItem } from './CYLTabBarItem';
import { CYLSVGAView } from '../svga/CYLSVGAView';
import {
  cylBadgeAccessibilityDescription, cylJoinAccessibilityParts, cylPlusButtonDefaultAccessibilityLabel, cylResolveText
} from './CYLTabBarAccessibility';

/**
 * [EN] One place of the bar: a tab, or the plus button. [CN] TabBar 中的一个位置：一个 Tab，或 PlusButton。
 */
class CYLTabBarSlot {
  tabIndex: number = -1;
  isPlusButton: boolean = false;
  key: string = '';
}

/**
 * [EN] The tab bar: iOS `CYLTabBar` with its tab buttons, badges and plus button. Accessible: each tab is one element for the
 *      screen reader (`accessibilityGroup`), reads its title and badge ("Messages, 3 new messages") with its selected state,
 *      and has the id "CYLTabBarItem_<identifier>" for UI tests; the plus button has the id of its identifier. Titles use
 *      `fp`, so large-text settings apply.
 * [CN] TabBar：对应 iOS 的 `CYLTabBar` 及其 Tab 按钮、角标与 PlusButton。支持无障碍：每个 Tab 对屏幕阅读器是一个元素（`accessibilityGroup`），
 *      朗读标题与角标（“消息、3 条新消息”）及选中状态，并带有供 UI 测试使用的 id "CYLTabBarItem_<identifier>"；PlusButton 的 id 为其标识。
 *      标题使用 `fp`，跟随大字体设置。
 */
@Component
export struct CYLTabBar {
  @Prop items: CYLTabBarItem[] = [];
  @Prop selectedIndex: number = 0;
  @Prop plusButton: CYLPlusButton | undefined = undefined;
  @Prop appearance: CYLTabBarAppearance = new CYLTabBarAppearance();
  /**
   * [EN] A tab was tapped: its index among the tabs and its identifier. [CN] 点击了一个 Tab：它在 Tab 中的下标与标识。
   */
  onSelect: (index: number, identifier: string) => void = (_index: number, _identifier: string) => {
  };
  onPlusButtonTap: () => void = () => {
  };
  /**
   * [EN] The identifiers of the tabs whose SVGA icon failed to load: they show their image. [CN] SVGA 图标加载失败的 Tab 标识：它们显示图片。
   */
  @State private svgaFailures: string[] = [];

  private svgaPath(item: CYLTabBarItem): string | undefined {
    if (this.svgaFailures.includes(item.identifier)) {
      return undefined;
    }
    return item.svgaURL ?? item.svgaFilePath;
  }

  private slots(): CYLTabBarSlot[] {
    const slots: CYLTabBarSlot[] = this.items.map((item: CYLTabBarItem, index: number) => {
      const slot = new CYLTabBarSlot();
      slot.tabIndex = index;
      slot.key = item.identifier;
      return slot;
    });
    if (this.plusButton !== undefined) {
      const plus = new CYLTabBarSlot();
      plus.isPlusButton = true;
      plus.key = this.plusButton.identifier;
      const index = this.plusButton.index >= 0 ? Math.min(this.plusButton.index, slots.length) : Math.floor(slots.length / 2);
      slots.splice(index, 0, plus);
    }
    return slots;
  }

  private tabAccessibilityText(item: CYLTabBarItem): string {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return '';
    }
    const label = cylResolveText(context, item.accessibilityLabel ?? item.title);
    return cylJoinAccessibilityParts(context, [label, cylBadgeAccessibilityDescription(context, item.badgeValue)]);
  }

  private plusButtonAccessibilityText(plus: CYLPlusButton): string {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      return '';
    }
    const label = cylResolveText(context, plus.accessibilityLabel ?? plus.title);
    return label.length > 0 ? label : cylPlusButtonDefaultAccessibilityLabel(context);
  }

  @Builder
  badge(value: string) {
    if (value.length === 0) {
      Circle({ width: 8, height: 8 })
        .fill(this.appearance.badgeColor)
        .accessibilityLevel('no')
    } else {
      Text(value)
        .fontSize(10)
        .fontColor(Color.White)
        .padding({ left: 4, right: 4 })
        .constraintSize({ minWidth: 16 })
        .height(16)
        .textAlign(TextAlign.Center)
        .borderRadius(8)
        .backgroundColor(this.appearance.badgeColor)
        .accessibilityLevel('no')
    }
  }

  @Builder
  tabButton(item: CYLTabBarItem, index: number) {
    Column({ space: 2 }) {
      Stack({ alignContent: Alignment.TopEnd }) {
        if (this.svgaPath(item) !== undefined) {
          CYLSVGAView({
            path: this.svgaPath(item),
            selected: index === this.selectedIndex,
            iconSize: item.svgaSize,
            onLoadError: (_message: string) => {
              this.svgaFailures = this.svgaFailures.concat([item.identifier]);
            }
          })
        } else if (item.symbol !== undefined) {
          SymbolGlyph(index === this.selectedIndex ? (item.selectedSymbol ?? item.symbol) : item.symbol)
            .fontSize(24)
            .fontColor([index === this.selectedIndex ? this.appearance.tintColor : this.appearance.unselectedItemTintColor])
            .accessibilityLevel('no')
        } else if (item.image !== undefined) {
          Image(index === this.selectedIndex ? (item.selectedImage ?? item.image) : item.image)
            .width(24)
            .height(24)
            .fillColor(index === this.selectedIndex ? this.appearance.tintColor : this.appearance.unselectedItemTintColor)
            .accessibilityLevel('no')
        }
        if (item.badgeValue !== undefined) {
          this.badge(item.badgeValue)
        }
      }
      .width(36)
      .height(Math.max(26, item.svgaSize))

      Text(item.title)
        .fontSize(10)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor(index === this.selectedIndex ? this.appearance.tintColor : this.appearance.unselectedItemTintColor)
        .accessibilityLevel('no')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .id(`CYLTabBarItem_${item.identifier}`)
    .accessibilityGroup(true)
    .accessibilityText(this.tabAccessibilityText(item))
    .accessibilitySelected(index === this.selectedIndex)
    .onClick(() => {
      this.onSelect(index, item.identifier);
    })
  }

  @Builder
  plusButtonView(plus: CYLPlusButton) {
    Column({ space: 2 }) {
      if (plus.symbol !== undefined) {
        SymbolGlyph(plus.symbol)
          .fontSize(40)
          .fontColor([this.appearance.plusButtonColor])
          .accessibilityLevel('no')
      } else if (plus.image !== undefined) {
        Image(plus.image)
          .width(44)
          .height(44)
          .fillColor(this.appearance.plusButtonColor)
          .accessibilityLevel('no')
      }
      if (plus.title !== undefined) {
        Text(plus.title)
          .fontSize(10)
          .fontColor(this.appearance.unselectedItemTintColor)
          .accessibilityLevel('no')
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .id(plus.identifier)
    .accessibilityGroup(true)
    .accessibilityText(this.plusButtonAccessibilityText(plus))
    .onClick(() => {
      this.onPlusButtonTap();
    })
  }

  build() {
    Row() {
      ForEach(this.slots(), (slot: CYLTabBarSlot) => {
        if (slot.isPlusButton && this.plusButton !== undefined) {
          this.plusButtonView(this.plusButton)
        } else {
          this.tabButton(this.items[slot.tabIndex], slot.tabIndex)
        }
        // [EN] The key is the tab only: a selection or a badge updates the tab in place, so its SVGA icon keeps its view and
        //      plays (a key with the selection would rebuild every tab).
        // [CN] key 只包含 Tab 本身：选中或角标变化时原地更新 Tab，其 SVGA 图标保留视图并播放（key 若包含选中状态会重建所有 Tab）。
      }, (slot: CYLTabBarSlot) => `${slot.key}-${slot.tabIndex}`)
    }
    .width('100%')
    .height(56)
    .backgroundColor(this.appearance.backgroundColor)
  }
}
