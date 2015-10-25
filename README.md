# CYLTabBarController（学习交流群：498865024）
低耦合的TabBarController


四步完成主流App框架搭建：

下面是本仓库配套Demo的效果：

![enter image description here](http://i59.tinypic.com/wvxutv.jpg)

 [另一个Demo](https://github.com/ChenYilong/CYLTabBarControllerDemoForWeib) 使用CYLTabBarController实现了微博Tabbar框架，效果如下
![enter image description here](http://i62.tinypic.com/6ru269.jpg)


## 第一步：使用cocoaPods导入CYLTabBarController

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



## 第二步：设置CYLTabBarController的两个数组：控制器数组和TabBar属性数组

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


## 第三步：将CYLTabBarController设置为window的RootViewController

 ```Objective-C
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 /* *省略部分：   * */
    [self.window setRootViewController:self.tabBarController];
 /* *省略部分：   * */
    return YES;
}
 ```

## 第四步：创建自定义的形状不规则加号按钮

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



## 补充说明
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





（更多iOS开发干货，欢迎关注  [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/) ）

----------
Posted by [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/)  
原创文章，版权声明：自由转载-非商用-非衍生-保持署名 | [Creative Commons BY-NC-ND 3.0](http://creativecommons.org/licenses/by-nc-nd/3.0/deed.zh)

