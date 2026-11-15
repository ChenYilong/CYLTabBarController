import { CYLPlusButton, CYLTabBarAppearance, CYLTabBarItem } from './CYLTabBarItem';
import { CYLTabBar } from './CYLTabBar';

/**
 * [EN] The tab bar controller: iOS `CYLTabBarController` with `selectedIndex`, the tabs (`tabBarItemsAttributes`), their
 *      pages (`viewControllers`, here `pageBuilder` for each index), the plus button and the appearance. Pages keep their
 *      state when another tab is selected, as UIKit keeps its view controllers.
 * [CN] TabBarController：对应 iOS 的 `CYLTabBarController`，包括 `selectedIndex`、Tab（`tabBarItemsAttributes`）、页面（`viewControllers`，
 *      这里为每个下标调用 `pageBuilder`）、PlusButton 与外观。切换到其他 Tab 时页面保留状态，与 UIKit 保留视图控制器相同。
 */
@Component
export struct CYLTabBarController {
  @Prop items: CYLTabBarItem[] = [];
  @Prop plusButton: CYLPlusButton | undefined = undefined;
  @Prop appearance: CYLTabBarAppearance = new CYLTabBarAppearance();
  @Link selectedIndex: number;
  @BuilderParam pageBuilder: (index: number) => void = this.emptyPage;
  /**
   * [EN] A tab was selected by a tap, as `-tabBarController:didSelectViewController:`. [CN] 点击选中了一个 Tab。
   */
  onSelect: (index: number, identifier: string) => void = (_index: number, _identifier: string) => {
  };
  /**
   * [EN] The plus button was tapped, as `CYLPlusButton`'s action. [CN] 点击了 PlusButton。
   */
  onPlusButtonTap: () => void = () => {
  };
  private controller: TabsController = new TabsController();

  @Builder
  emptyPage(_index: number) {
  }

  build() {
    Column() {
      Tabs({ index: this.selectedIndex, controller: this.controller }) {
        ForEach(this.items, (item: CYLTabBarItem, index: number) => {
          TabContent() {
            this.pageBuilder(index)
          }
        }, (item: CYLTabBarItem) => item.identifier)
      }
      .barHeight(0)
      .scrollable(false)
      .animationDuration(0)
      .layoutWeight(1)

      CYLTabBar({
        items: this.items,
        selectedIndex: this.selectedIndex,
        plusButton: this.plusButton,
        appearance: this.appearance,
        onSelect: (index: number, identifier: string) => {
          this.selectedIndex = index;
          this.onSelect(index, identifier);
        },
        onPlusButtonTap: () => {
          this.onPlusButtonTap();
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
