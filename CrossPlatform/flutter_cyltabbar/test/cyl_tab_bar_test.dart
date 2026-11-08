import 'package:flutter_cyltabbar/flutter_cyltabbar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the configuration keys of the native libraries', () {
    const bar = CYLTabBar(
      styleType: 'liquidGlass',
      items: [
        CYLTabBarItem(title: 'Home', identifier: 'home', image: CYLTabBarImage.asset('assets/home.png')),
        CYLTabBarItem(title: 'Me', image: CYLTabBarImage.name('system:person'), attributes: {'CYLTabBarItemTitleColor': '#333333'}),
      ],
      plusButton: CYLTabBarPlusButton(title: 'Post', image: CYLTabBarImage.name('post_normal')),
      configuration: {'CYLTabBarControllerStyleType': 'flatDesign'},
    );
    final configuration = bar.buildConfiguration();
    expect(configuration['CYLTabBarControllerStyleType'], 'flatDesign');
    final items = configuration['CYLTabBarControllerTabBarItemsAttributes'] as List;
    expect(items[0], {'CYLTabBarItemTitle': 'Home', 'CYLTabBarItemIdentifier': 'home', 'CYLTabBarItemImage': 'flutter-asset:assets/home.png'});
    expect(items[1], {'CYLTabBarItemTitleColor': '#333333', 'CYLTabBarItemTitle': 'Me', 'CYLTabBarItemImage': 'system:person'});
    expect(configuration['CYLTabBarControllerPlusButton'], {'CYLTabBarItemImage': 'post_normal', 'CYLTabBarItemTitle': 'Post'});
  });

  test('plus button layout and interaction keys', () {
    const bar = CYLTabBar(
      tapAnimation: 'bounce',
      swipeToSwitchTab: true,
      userInterfaceStyle: 'dark',
      animationSpeed: 1.5,
      plusButton: CYLTabBarPlusButton(
        backgroundImage: CYLTabBarImage.name('tabbar_database'),
        title: 'Menu',
        titleColor: '#FFFFFF',
        titleFont: 15,
        index: 2,
        centerYMultiplier: 0.3,
        centerYOffset: -30,
        keepsTitleVisible: true,
        identifier: 'plus',
        pageIdentifier: 'menu',
      ),
    );
    final configuration = bar.buildConfiguration();
    expect(configuration['CYLTabBarControllerTabButtonTapAnimation'], 'bounce');
    expect(configuration['CYLTabBarControllerSwipeToSwitchTab'], true);
    expect(configuration['CYLTabBarControllerUserInterfaceStyle'], 'dark');
    expect(configuration['CYLTabBarControllerTabBarItemAnimationSpeed'], 1.5);
    expect(configuration['CYLTabBarControllerPlusButton'], {
      'CYLPlusButtonBackgroundImage': 'tabbar_database',
      'CYLTabBarItemTitle': 'Menu',
      'CYLTabBarItemTitleColor': '#FFFFFF',
      'CYLTabBarItemTitleFont': 15,
      'CYLPlusButtonIndexInTabBar': 2,
      'CYLPlusButtonCenterYMultiplier': 0.3,
      'CYLPlusButtonCenterYOffset': -30.0,
      'CYLPlusButtonKeepsTitleVisible': true,
      'CYLTabBarItemIdentifier': 'plus',
      'CYLTabBarItemPageIdentifier': 'menu',
    });
  });
}
