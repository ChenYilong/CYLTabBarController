# CYLTabBarController【低耦合集成TabBarController】


<p align="center">
![enter image description here](https://img.shields.io/badge/pod-v1.0.3-brightgreen.svg)
![enter image description here](https://img.shields.io/badge/Objective--C-compatible-orange.svg)   ![enter image description here](https://img.shields.io/badge/platform-iOS%207.0%2B-ff69b4.svg)


</a>

## 导航
 1.  [与其他自定义TabBarController的区别](https://github.com/ChenYilong/CYLTabBarController#与其他自定义tabbarcontroller的区别) 
 2.  [集成后的效果](https://github.com/ChenYilong/CYLTabBarController#集成后的效果) 
 3.  [使用CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController#使用cyltabbarcontroller) 
  1.  [ 第一步：使用cocoaPods导入CYLTabBarController ](https://github.com/ChenYilong/CYLTabBarController#第一步使用cocoapods导入cyltabbarcontroller) 
  2.  [第二步：设置CYLTabBarController的两个数组：控制器数组和TabBar属性数组](https://github.com/ChenYilong/CYLTabBarController#第二步设置cyltabbarcontroller的两个数组控制器数组和tabbar属性数组) 
  3.  [第三步：将CYLTabBarController设置为window的RootViewController](https://github.com/ChenYilong/CYLTabBarController#第三步将cyltabbarcontroller设置为window的rootviewcontroller) 
  4.  [第四步（可选）：创建自定义的形状不规则加号按钮](https://github.com/ChenYilong/CYLTabBarController#第四步可选创建自定义的形状不规则加号按钮) 
 2.  [补充说明](https://github.com/ChenYilong/CYLTabBarController#补充说明) 
 2.  [Q-A](https://github.com/ChenYilong/CYLTabBarController#q-a) 



## 与其他自定义TabBarController的区别

 -| 特点 |解释
-------------|-------------|-------------
1| 低耦合 | 与业务完全分离，最低只需传两个数组即可完成主流App框架搭建
2 | `TabBar` 以及 `TabBar` 内的 `TabBarItem` 均使用系统原生的控件 | 因为使用原生的控件，并非 `UIButton` 或 `UIView` 。好处如下：</p> 1. 无需反复调“间距位置等”来接近系统效果。</p> 2. 在push到下一页时 `TabBar`  的隐藏和显示之间的过渡效果跟系统一致（详见“ [集成后的效果](https://github.com/ChenYilong/CYLTabBarController#集成后的效果) ”部分，给出了效果图） </p> 3. 原生控件，所以可以使用诸多系统API，比如：可以使用 ` [UITabBar appearance];` 、` [UITabBarItem appearance];` 设置样式。（详见“[补充说明](https://github.com/ChenYilong/CYLTabBarController#补充说明) ”部分，给出了响应代码示例）
3 | 自动监测是否需要添加“加号”按钮，</p>并能自动设置位置 |[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController) 既支持类似微信的“中规中矩”的 `TabBarController` 样式，并且默认就是微信这种样式，同时又支持类似“微博”或“淘宝闲鱼”这种具有不规则加号按钮的 `TabBarController` 。想支持这种样式，只需自定义一个加号按钮，[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController) 能检测到它的存在并自动将 `tabBar` 排序好，无需多余操作，并且也预留了一定接口来满足自定义需求。</p>“加号”按钮的样式、frame均在自定义的类中独立实现，不会涉及tabbar相关设置。
4|即使加号按钮超出了tabbar的区域，</p>超出部分依然能响应点击事件 | 红线内的区域均能响应tabbar相关的点击事件，</p>![enter image description here](http://i57.tinypic.com/2r7ndzk.jpg)
5 |支持CocoaPods |容易集成




（学习交流群：498865024）



## 集成后的效果：
既支持默认样式 | 同时也支持创建自定义的形状不规则加号按钮
-------------|-------------
![enter image description here](http://i62.tinypic.com/rvcbit.jpg?192x251_130)| ![enter image description here](http://i58.tinypic.com/24d4t3p.jpg?192x251_130)


本仓库配套Demo的效果：| [另一个Demo](https://github.com/ChenYilong/CYLTabBarControllerDemoForWeib) 使用CYLTabBarController实现了微博Tabbar框架，效果如下
-------------|-------------
![enter image description here](http://i59.tinypic.com/wvxutv.jpg)|![enter image description here](http://i62.tinypic.com/6ru269.jpg)


## 使用[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController)
四步完成主流App框架搭建：

  1.  [ 第一步：使用cocoaPods导入CYLTabBarController ](https://github.com/ChenYilong/CYLTabBarController#第一步使用cocoapods导入cyltabbarcontroller) 
  2.  [第二步：设置CYLTabBarController的两个数组：控制器数组和TabBar属性数组](https://github.com/ChenYilong/CYLTabBarController#第二步设置cyltabbarcontroller的两个数组控制器数组和tabbar属性数组) 
  3.  [第三步：将CYLTabBarController设置为window的RootViewController](https://github.com/ChenYilong/CYLTabBarController#第三步将cyltabbarcontroller设置为window的rootviewcontroller) 
  4.  [第四步（可选）：创建自定义的形状不规则加号按钮](https://github.com/ChenYilong/CYLTabBarController#第四步可选创建自定义的形状不规则加号按钮) 


### 第一步：使用cocoaPods导入CYLTabBarController

在 `Podfile` 中如下导入：


 ```Objective-C
 pod 'CYLTabBarController'
 ```

然后使用 `cocoaPods` 进行安装：

建议使用如下方式：

 ```Objective-C
 # 不升级CocoaPods的spec仓库
pod update --verbose 
 ```



### 第二步：设置CYLTabBarController的两个数组：控制器数组和TabBar属性数组

 ```Objective-C
 - (void)setupViewControllers {
    CYLHomeViewController *firstViewController = [[CYLHomeViewController alloc] init];
    UIViewController *firstNavigationController = [[UINavigationController alloc]
                                                   initWithRootViewController:firstViewController];
    
    CYLSameFityViewController *secondViewController = [[CYLSameFityViewController alloc] init];
    UIViewController *secondNavigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:secondViewController];
    

    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] init];
    [self customizeTabBarForController:tabBarController];
    
    [tabBarController setViewControllers:@[
                                           firstNavigationController,
                                           secondNavigationController,
                                           ]];
    self.tabBarController = tabBarController;
}

/*
 *
 在`-setViewControllers:`之前设置TabBar的属性，
 *
 */
- (void)customizeTabBarForController:(CYLTabBarController *)tabBarController {
    
    NSDictionary *dict1 = @{
                            CYLTabBarItemTitle : @"首页",
                            CYLTabBarItemImage : @"home_normal",
                            CYLTabBarItemSelectedImage : @"home_highlight",
                            };
    NSDictionary *dict2 = @{
                            CYLTabBarItemTitle : @"同城",
                            CYLTabBarItemImage : @"mycity_normal",
                            CYLTabBarItemSelectedImage : @"mycity_highlight",
                            };

    NSArray *tabBarItemsAttributes = @[ dict1, dict2 ];
    tabBarController.tabBarItemsAttributes = tabBarItemsAttributes;
}
 ```


### 第三步：将CYLTabBarController设置为window的RootViewController

 ```Objective-C
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 /* *省略部分：   * */
    [self.window setRootViewController:self.tabBarController];
 /* *省略部分：   * */
    return YES;
}
 ```

### 第四步（可选）：创建自定义的形状不规则加号按钮


创建一个继承于 CYLPlusButton 的类，要求和步骤：


 1. 实现  `CYLPlusButtonSubclassing`  协议 

 2. 子类将自身类型进行注册，一般可在 `application` 的 `applicationDelegate` 方法里面调用 `[YourClass registerSubClass]` 或者在子类的 `+load` 方法中调用：

 ```Objective-C
 +(void)load {
    [super registerSubclass];
}
 ```

协议提供了两个可选方法：

 ```Objective-C
+ (NSUInteger)indexOfPlusButtonInTabBar;
+ (CGFloat)multiplerInCenterY;
 ```

作用分别是：

 ```Objective-C
 + (NSUInteger)indexOfPlusButtonInTabBar;
 ```
用来自定义加号按钮的位置，如果不实现默认居中，但是如果 `tabbar` 的个数是奇数则必须实现该方法，否则 `CYLTabBarController` 会抛出 `exception` 来进行提示。


 ```Objective-C
 + (CGFloat)multiplerInCenterY;
 ```

该方法是为了调整自定义按钮中心点Y轴方向的位置，建议在按钮超出了 `tabbar` 的边界时实现该方法。返回值是自定义按钮中心点Y轴方向的坐标除以 `tabbar` 的高度，如果不实现，会自动进行比对，预设一个较为合适的位置，如果实现了该方法，预设的逻辑将失效。


详见Demo中的 `CYLPlusButtonSubclass` 类的实现。



### 补充说明
如果想更进一步的自定义 `TabBar` 样式可在 `-application:didFinishLaunchingWithOptions:` 方法中设置

 ```Objective-C
 /**
 *  tabBarItem 的选中和不选中文字属性、背景图片
 */
- (void)customizeInterface {
    
    // 普通状态下的文字属性
    NSMutableDictionary *normalAttrs = [NSMutableDictionary dictionary];
    normalAttrs[NSForegroundColorAttributeName] = [UIColor grayColor];
    
    // 选中状态下的文字属性
    NSMutableDictionary *selectedAttrs = [NSMutableDictionary dictionary];
    selectedAttrs[NSForegroundColorAttributeName] = [UIColor darkGrayColor];
    
    // 设置文字属性
    UITabBarItem *tabBar = [UITabBarItem appearance];
    [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
    [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateHighlighted];

    // 设置背景图片
    UITabBar *tabBarAppearance = [UITabBar appearance];
    [tabBarAppearance setBackgroundImage:[UIImage imageNamed:@"tabbar_background"]];
}

 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 /* *省略部分：   * */
    [self.window makeKeyAndVisible];
    [self customizeInterface];
    return YES;
}
 ```
## Q-A

Q：为什么放置6个TabBarItem会显示异常？

A：

Apple 规定：

 >  一个 `TabBar` 上只能出现最多5个 `TabBarItem` ，第六个及更多的将不被显示。


另外注意，Apple检测的是 `UITabBarItem` 及其子类，所以放置“加号按钮”，这是 `UIButton` 不在“5个”里面。

最多只能添加5个 `TabBarItem` ，也就是说加上“加号按钮”，一共最多在一个 `TabBar` 上放置6个控件。否则第6个及之后出现 `TabBarItem` 会被自动屏蔽掉。而且就Apple的审核机制来说，超过5个也会被直接拒绝上架。



Q：我把 demo 两侧的 item 各去掉一个后，按钮的响应区域就变成下图的样子了：
![wechat_1445851872](https://cloud.githubusercontent.com/assets/12152553/10725491/62600172-7c07-11e5-9e0a-0ec7d795d1e3.jpeg)

A：这个是iOS系统对 `tabBar` 做的优化，请在真机上进行右手体验。如果你将iPhone切换到左手模式，触摸区域将“反过来”，有兴趣可以试一下。


Q： 如何实现添加选中背景色的功能 ，像下面这样：
<img width="409" alt="screen shot 2015-10-28 at 9 21 56 am" src="https://cloud.githubusercontent.com/assets/7238866/10777333/5d7811c8-7d55-11e5-88be-8cb11bbeaf90.png">

A：我已经在 Demo 中添加了如何实现该功能的代码：
详情见appdelegate 类中下面方法的实现：

 ```Objective-C
    [self setUpTabBarItemTextAttributes];
 ```

效果如下：
![simulator screen shot 2015 10 28 11 44 32](https://cloud.githubusercontent.com/assets/2911921/10779397/34956b0a-7d6b-11e5-82d9-fa75aa34e8d0.png)

（更多iOS开发干货，欢迎关注  [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/) ）

----------
Posted by [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/)  
原创文章，版权声明：自由转载-非商用-非衍生-保持署名 | [Creative Commons BY-NC-ND 3.0](http://creativecommons.org/licenses/by-nc-nd/3.0/deed.zh)

