import { CYLTabBarItemAttributes } from './CYLTabBarItem';
import { CYLPlusButton } from './CYLPlusButton';

/**
 * [EN] One place of the bar: a tab (tabIndex >= 0) or the plus button (tabIndex -1).
 * [CN] TabBar 中的一个位置：Tab（tabIndex >= 0）或加号按钮（tabIndex 为 -1）。
 */
class CYLSlot {
  tabIndex: number = -1;
  key: string = '';

  constructor(tabIndex: number, key: string) {
    this.tabIndex = tabIndex;
    this.key = key;
  }
}

/**
 * [EN] The plus button's place among the selectable pages (its page comes after the tabs). [CN] 加号页面的索引（排在所有 Tab 之后）。
 */
export const CYLPlusButtonPageIndex: number = -1;

/**
 * [EN] CYLTabBarController for HarmonyOS: the tab bar and the pages of the tabs. Pages are built by `pageBuilder`
 *      (index, identifier) the first time their tab is selected, then kept (as iOS keeps its view controllers).
 *      Properties map the iOS library: tabBarItemsAttributes (CYLTabBarControllerTabBarItemsAttributes), plusButton
 *      (CYLTabBarControllerPlusButton), selectedIndex, badgeValues (-cyl_setBadgeValue: of each tab), tintColor
 *      (CYLTabBarItemSelectedTitleColor), unselectedColor, tabBarHeight, tabBarHidden (-setTabBarHidden:animated:),
 *      shouldSelect (-tabBarController:shouldSelectViewController:), didSelect (-tabBarController:didSelectViewController:),
 *      plusButtonAction (CYLTabBarControllerPlusButtonAction).
 * [CN] 鸿蒙版 CYLTabBarController：TabBar 与各 Tab 的页面。页面在其 Tab 第一次被选中时由 `pageBuilder`（index, identifier）
 *      创建，之后保留（与 iOS 保留视图控制器相同）。属性与 iOS 库对应，见上。
 */
@Component
export struct CYLTabBarController {
  tabBarItemsAttributes: CYLTabBarItemAttributes[] = [];
  plusButton?: CYLPlusButton;
  @Link selectedIndex: number;
  @Prop badgeValues: string[] = [];
  @Prop plusButtonBadgeValue: string = '';
  @Prop tabBarHidden: boolean = false;
  tintColor: ResourceColor = '#FF8000';
  unselectedColor: ResourceColor = '#808080';
  plusButtonTitleSelectedColor?: ResourceColor;
  tabBarBackgroundColor: ResourceColor = '#F8F8F8';
  tabBarHeight: number = 49;
  imageSize: number = 26;
  shouldSelect?: (index: number, identifier: string) => boolean;
  didSelect?: (index: number, identifier: string) => void;
  plusButtonAction?: () => void;
  @BuilderParam pageBuilder: (index: number, identifier: string) => void = this.cylEmptyPage;
  @State private loaded: number[] = [];
  @State private plusPressed: boolean = false;

  @Builder
  cylEmptyPage(index: number, identifier: string) {
  }

  aboutToAppear(): void {
    this.loaded = [this.selectedIndex];
  }

  /**
   * [EN] -setSelectedIndex: through the delegate: shouldSelect may refuse; didSelect follows.
   * [CN] 经过代理设置选中索引：shouldSelect 可拒绝；随后调用 didSelect。
   */
  cylSelect(index: number): void {
    const identifier = this.cylIdentifier(index);
    if (this.shouldSelect !== undefined && !this.shouldSelect(index, identifier)) {
      return;
    }
    if (this.loaded.indexOf(index) < 0) {
      this.loaded = this.loaded.concat([index]);
    }
    this.selectedIndex = index;
    if (this.didSelect !== undefined) {
      this.didSelect(index, identifier);
    }
  }

  cylIdentifier(index: number): string {
    if (index === CYLPlusButtonPageIndex) {
      return this.plusButton?.identifier ?? 'plus';
    }
    const item = this.tabBarItemsAttributes[index];
    return item?.identifier ?? `${index}`;
  }

  cylSlots(): CYLSlot[] {
    const slots: CYLSlot[] = this.tabBarItemsAttributes.map((item: CYLTabBarItemAttributes, i: number) => new CYLSlot(i, `tab-${i}`));
    if (this.plusButton !== undefined) {
      const at = this.plusButton.index ?? Math.floor(slots.length / 2);
      slots.splice(Math.max(0, Math.min(at, slots.length)), 0, new CYLSlot(-1, 'plus'));
    }
    return slots;
  }

  cylPages(): number[] {
    const pages: number[] = this.tabBarItemsAttributes.map((item: CYLTabBarItemAttributes, i: number) => i);
    if (this.plusButton?.selectable) {
      pages.push(CYLPlusButtonPageIndex);
    }
    return pages;
  }

  @Builder
  cylBadge(value: string) {
    if (value.length > 0) {
      Text(value === '•' ? '' : value)
        .fontSize(11)
        .fontColor(Color.White)
        .backgroundColor('#FF3B30')
        .borderRadius(9)
        .constraintSize({ minWidth: value === '•' ? 8 : 18 })
        .height(value === '•' ? 8 : 18)
        .padding({ left: value === '•' ? 0 : 5, right: value === '•' ? 0 : 5 })
        .textAlign(TextAlign.Center)
        .position({ x: '55%', y: value === '•' ? 2 : -2 })
        .id(`cyl-badge-${value}`)
    }
  }

  @Builder
  cylTab(index: number) {
    Column() {
      Stack() {
        Image(this.selectedIndex === index
          ? (this.tabBarItemsAttributes[index].selectedImage ?? this.tabBarItemsAttributes[index].image)
          : this.tabBarItemsAttributes[index].image)
          .width(this.imageSize)
          .height(this.imageSize)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .height(this.imageSize)

      if (this.tabBarItemsAttributes[index].title !== undefined) {
        Text(this.selectedIndex === index
          ? (this.tabBarItemsAttributes[index].selectedTitle ?? this.tabBarItemsAttributes[index].title)
          : this.tabBarItemsAttributes[index].title)
          .fontSize(10)
          .margin({ top: 3 })
          .fontColor(this.selectedIndex === index ? this.tintColor : this.unselectedColor)
      }
      this.cylBadge(this.badgeValues[index] ?? '')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .id(`cyl-tab-${this.cylIdentifier(index)}`)
    .onClick(() => this.cylSelect(index))
  }

  @Builder
  cylPlus() {
    Column() {
      Stack() {
        Image(this.plusPressed || this.selectedIndex === CYLPlusButtonPageIndex
          ? (this.plusButton?.selectedImage ?? this.plusButton?.image) : this.plusButton?.image)
          .width(this.plusButton?.imageSize ?? 54)
          .height(this.plusButton?.imageSize ?? 54)
          .objectFit(ImageFit.Contain)
        this.cylBadge(this.plusButtonBadgeValue)
      }
      .offset({ y: this.plusButton?.centerYOffset ?? 0 })

      if (this.plusButton?.title !== undefined) {
        Text(this.plusButton.title)
          .fontSize(10)
          .fontColor(this.selectedIndex === CYLPlusButtonPageIndex
            ? (this.plusButtonTitleSelectedColor ?? this.tintColor) : this.unselectedColor)
          .position(this.plusButton?.alignsTitle === false ? undefined : { x: 0, y: this.tabBarHeight - 17 })
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .id('cyl-plus-button')
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.plusPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.plusPressed = false;
      }
    })
    .onClick(() => {
      if (this.plusButton?.selectable) {
        this.cylSelect(CYLPlusButtonPageIndex);
      }
      if (this.plusButtonAction !== undefined) {
        this.plusButtonAction();
      }
    })
  }

  build() {
    Column() {
      Stack() {
        ForEach(this.cylPages(), (index: number) => {
          if (this.loaded.indexOf(index) >= 0) {
            Column() {
              this.pageBuilder(index, this.cylIdentifier(index))
            }
            .width('100%')
            .height('100%')
            .visibility(this.selectedIndex === index ? Visibility.Visible : Visibility.Hidden)
          }
        }, (index: number) => `page-${index}`)
      }
      .layoutWeight(1)
      .width('100%')

      if (!this.tabBarHidden) {
        Row() {
          ForEach(this.cylSlots(), (slot: CYLSlot) => {
            if (slot.tabIndex >= 0) {
              this.cylTab(slot.tabIndex)
            } else {
              this.cylPlus()
            }
          }, (slot: CYLSlot) => slot.key)
        }
        .width('100%')
        .height(this.tabBarHeight)
        .backgroundColor(this.tabBarBackgroundColor)
        .border({ width: { top: 0.5 }, color: { top: '#1F000000' } })
        .padding({ bottom: 0 })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .id('cyl-tab-bar')
      }
    }
    .width('100%')
    .height('100%')
  }
}
