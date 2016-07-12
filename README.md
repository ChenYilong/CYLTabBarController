# CYLTabBarController【低耦合集成TabBarController】


<p align="center">
![enter image description here](https://img.shields.io/badge/pod-v1.5.6-brightgreen.svg)
![enter image description here](https://img.shields.io/badge/Swift-compatible-orange.svg)   ![enter image description here](https://img.shields.io/badge/platform-iOS%207.0%2B-ff69b5297537064.svg) 
<a href="https://github.com/ChenYilong/CYLTabBarController/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>
</a>

<p align="center">[![https://twitter.com/stevechen1010](https://img.shields.io/twitter/url/http/shields.io.svg?style=social&maxAge=2592000)](https://twitter.com/stevechen1010)[![bitHound](http://i67.tinypic.com/wbulbr.jpg)](http://weibo.com/luohanchenyilong)
[![Gitter](https://badges.gitter.im/ChenYilong/CYLTabBarController.svg)](https://gitter.im/ChenYilong/CYLTabBarController?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
</a>



## 导航

 1.  [与其他自定义TabBarController的区别](https://github.com/ChenYilong/CYLTabBarController#与其他自定义tabbarcontroller的区别) 
 2.  [集成后的效果](https://github.com/ChenYilong/CYLTabBarController#集成后的效果) 
 3.  [项目结构](https://github.com/ChenYilong/CYLTabBarController#项目结构) 
 4.  [使用CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController#使用cyltabbarcontroller) 
  1.  [ 第一步：使用CocoaPods导入CYLTabBarController ](https://github.com/ChenYilong/CYLTabBarController#第一步使用cocoapods导入cyltabbarcontroller) 
  2.  [第二步：设置CYLTabBarController的两个数组：控制器数组和TabBar属性数组](https://github.com/ChenYilong/CYLTabBarController#第二步设置cyltabbarcontroller的两个数组控制器数组和tabbar属性数组) 
  3.  [第三步：将CYLTabBarController设置为window的RootViewController](https://github.com/ChenYilong/CYLTabBarController#第三步将cyltabbarcontroller设置为window的rootviewcontroller) 
  4.  [第四步（可选）：创建自定义的形状不规则加号按钮](https://github.com/ChenYilong/CYLTabBarController#第四步可选创建自定义的形状不规则加号按钮) 
 5.  [补充说明](https://github.com/ChenYilong/CYLTabBarController#补充说明) 
  1.  [自定义 TabBar 样式](https://github.com/ChenYilong/CYLTabBarController#自定义-tabbar-样式) 
  2.  [横竖屏适配](https://github.com/ChenYilong/CYLTabBarController#横竖屏适配) 
  3.  [访问初始化好的 CYLTabBarController 对象](https://github.com/ChenYilong/CYLTabBarController#访问初始化好的-cyltabbarcontroller-对象) 
  4.  [点击 PlusButton 跳转到指定 UIViewController](https://github.com/ChenYilong/CYLTabBarController#点击-plusbutton-跳转到指定-uiviewcontroller) 
  5.  [让TabBarItem仅显示图标，并使图标垂直居中](https://github.com/ChenYilong/CYLTabBarController#让tabbaritem仅显示图标并使图标垂直居中) 
  6.  [在 Swift 项目中使用 CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController#在-swift-项目中使用-cyltabbarcontroller) 
  7.  [源码实现原理](https://github.com/ChenYilong/CYLTabBarController#源码实现原理) 
 6.  [Q-A](https://github.com/ChenYilong/CYLTabBarController#q-a) 



## 与其他自定义TabBarController的区别

 -| 特点 |解释
-------------|-------------|-------------
1| 低耦合，易删除 | 1、TabBar设置与业务完全分离，最低只需传两个数组即可完成主流App框架搭建。</p> 2、 PlusButton 的所有设置都在单独的一个类（ `CYLPlusButton` 的子类）中实现：删除该特定的类，就能完全将 PlusButton 从项目中删除掉。
2 | `TabBar` 以及 `TabBar` 内的 `TabBarItem` 均使用系统原生的控件 | 因为使用原生的控件，并非 `UIButton` 或 `UIView` 。好处如下：</p> 1. 无需反复调“间距位置等”来接近系统效果。</p> 2. 在push到下一页时 `TabBar`  的隐藏和显示之间的过渡效果跟系统一致（详见“ [集成后的效果](https://github.com/ChenYilong/CYLTabBarController#集成后的效果) ”部分，给出了效果图） </p> 3. 原生控件，所以可以使用诸多系统API，比如：可以使用 ` [UITabBar appearance];` 、` [UITabBarItem appearance];` 设置样式。（详见“[补充说明](https://github.com/ChenYilong/CYLTabBarController#补充说明) ”部分，给出了响应代码示例）
3 | 自动监测是否需要添加“加号”按钮，</p>并能自动设置位置 |[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController) 既支持类似微信的“中规中矩”的 `TabBarController` 样式，并且默认就是微信这种样式，同时又支持类似“微博”或“淘宝闲鱼”这种具有不规则加号按钮的 `TabBarController` 。想支持这种样式，只需自定义一个加号按钮，[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController) 能检测到它的存在并自动将 `tabBar` 排序好，无需多余操作，并且也预留了一定接口来满足自定义需求。</p>“加号”按钮的样式、frame均在自定义的类中独立实现，不会涉及tabbar相关设置。
4|即使加号按钮超出了tabbar的区域，</p>超出部分依然能响应点击事件 | 红线内的区域均能响应tabbar相关的点击事件，</p>![enter image description here](http://i57.tinypic.com/2r7ndzk.jpg)
5 | 允许指定加号按钮位置 | 效果如下：</p>![enter image description here](http://a64.tinypic.com/2mo0h.jpg) </p>Airbnb-app效果：</p>![enter image description here](http://a63.tinypic.com/2mgk02v.gif)
6| 支持让 `TabBarItem` 仅显示图标，并自动使图标垂直居中，支持自定义TabBar高度 | 效果可见Airbnb-app效果，或者下图</p>![enter image description here](https://cloud.githubusercontent.com/assets/7238866/10777333/5d7811c8-7d55-11e5-88be-8cb11bbeaf90.png)
7 |支持CocoaPods |容易集成
8 |支持Swift项目导入 | 兼容
9 |支持横竖屏 | －－




（学习交流群：529753706）



## 集成后的效果：
既支持默认样式 | 同时也支持创建自定义的形状不规则加号按钮 
-------------|------------
![enter image description here](http://i62.tinypic.com/rvcbit.jpg?192x251_130)| ![enter image description here](http://i58.tinypic.com/24d4t3p.jpg?192x251_130)

 支持横竖屏
 ![enter image description here](http://i67.tinypic.com/2u4snk7.jpg)


本仓库配套Demo的效果：| [另一个Demo](https://github.com/ChenYilong/CYLTabBarControllerDemoForWeib) 使用CYLTabBarController实现了微博Tabbar框架，效果如下
-------------|-------------
![enter image description here](http://i59.tinypic.com/wvxutv.jpg)|![enter image description here](http://i62.tinypic.com/6ru269.jpg)

## 项目结构


![enter image description here](http://i66.tinypic.com/1zwzdc.jpg)

做下说明：

 ```Objective-C

├── CYLTabBarController  ＃核心库文件夹，如果不使用 CocoaPods 集成，请直接将这个文件夹拖拽带你的项目中
└── Example
    └── Classes
        ├── Module       #模块类文件夹
        │   ├── Home
        │   ├── Message
        │   ├── Mine
        │   └── SameCity
        └── View         #这里放着 CYLPlusButton 的子类 CYLPlusButtonSubclass，演示了如何创建自定义的形状不规则加号按钮
        
        
 ```


## 使用[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController)
四步完成主流App框架搭建：

  1.  [ 第一步：使用CocoaPods导入CYLTabBarController ](https://github.com/ChenYilong/CYLTabBarController#第一步使用cocoapods导入cyltabbarcontroller) 
  2.  [第二步：设置CYLTabBarController的两个数组：控制器数组和TabBar属性数组](https://github.com/ChenYilong/CYLTabBarController#第二步设置cyltabbarcontroller的两个数组控制器数组和tabbar属性数组) 
  3.  [第三步：将CYLTabBarController设置为window的RootViewController](https://github.com/ChenYilong/CYLTabBarController#第三步将cyltabbarcontroller设置为window的rootviewcontroller) 
  4.  [第四步（可选）：创建自定义的形状不规则加号按钮](https://github.com/ChenYilong/CYLTabBarController#第四步可选创建自定义的形状不规则加号按钮) 


### 第一步：使用CocoaPods导入CYLTabBarController


在 `Podfile` 中进行如下导入：


 ```Objective-C
pod 'CYLTabBarController'
 ```



然后使用 `cocoaPods` 进行安装：

如果尚未安装 CocoaPods, 运行以下命令进行安装:


 ```Objective-C
gem install cocoapods
 ```


安装成功后就可以安装依赖了：

建议使用如下方式：


 ```Objective-C
 # 禁止升级CocoaPods的spec仓库，否则会卡在 Analyzing dependencies ，非常慢 
 pod update --verbose --no-repo-update
 ```


如果提示找不到库，则可去掉 --no-repo-update


 ```Objective-C
pod update
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

 2. 子类将自身类型进行注册，一般可在 `application` 的 `applicationDelegate` 方法里面调用 `[YourClass registerPlusButton]` 或者在子类的 `+load` 方法中调用：

 ```Objective-C
 +(void)load {
    [super registerPlusButton];
}
 ```

协议提供了可选方法：

 ```Objective-C
+ (NSUInteger)indexOfPlusButtonInTabBar;
+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight;
+ (UIViewController *)plusChildViewController;
 ```

作用分别是：

 ```Objective-C
 + (NSUInteger)indexOfPlusButtonInTabBar;
 ```
用来自定义加号按钮的位置，如果不实现默认居中，但是如果 `tabbar` 的个数是奇数则必须实现该方法，否则 `CYLTabBarController` 会抛出 `exception` 来进行提示。

主要适用于如下情景：

![enter image description here](http://a64.tinypic.com/2mo0h.jpg)

Airbnb-app效果：

![enter image description here](http://a63.tinypic.com/2mgk02v.gif)

 ```Objective-C
+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight;
 ```

该方法是为了调整自定义按钮中心点Y轴方向的位置，建议在按钮超出了 `tabbar` 的边界时实现该方法。返回值是自定义按钮中心点Y轴方向的坐标除以 `tabbar` 的高度，如果不实现，会自动进行比对，预设一个较为合适的位置，如果实现了该方法，预设的逻辑将失效。

内部实现时，会使用该返回值来设置 PlusButton 的 centerY 坐标，公式如下：
              
`PlusButtonCenterY = multiplierOfTabBarHeight * taBarHeight + constantOfPlusButtonCenterYOffset;`

也就是说：如果 constantOfPlusButtonCenterYOffset 为0，同时 multiplierOfTabBarHeight 的值是0.5，表示 PlusButton 居中，小于0.5表示 PlusButton 偏上，大于0.5则表示偏下。


 ```Objective-C
+ (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight;
 ```

参考 `+multiplierOfTabBarHeight:` 中的公式：

`PlusButtonCenterY = multiplierOfTabBarHeight * taBarHeight + constantOfPlusButtonCenterYOffset;`

也就是说： constantOfPlusButtonCenterYOffset 大于0会向下偏移，小于0会向上偏移。

注意：实现了该方法，但没有实现 `+multiplierOfTabBarHeight:` 方法，在这种情况下，会在预设逻辑的基础上进行偏移。

详见Demo中的 `CYLPlusButtonSubclass` 类的实现。

 ```Objective-C
+ (UIViewController *)plusChildViewController;
 ```

详见： [点击 PlusButton 跳转到指定 UIViewController](https://github.com/ChenYilong/CYLTabBarController#点击-plusbutton-跳转到指定-uiviewcontroller) 


另外，如果加号按钮超出了边界，一般需要手动调用如下代码取消 tabbar 顶部默认的阴影，可在 AppDelegate 类中调用：


 ```Objective-C
    //去除 TabBar 自带的顶部阴影
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
 ```

如何调整、自定义 `PlusButton` 与其它 `TabBarItem` 的宽度？

`CYLTabBarController` 规定：

 ```Objective-C
 TabBarItem 宽度 ＝  ( TabBar 总宽度 －  PlusButton 宽度  ) / (TabBarItem 个数)
 ```

所以想自定义宽度，只需要修改 `PlusButton` 的宽度即可。

比如你就可以在 Demo中的 `CYLPlusButtonSubclass.m` 类里：
   
把

 ```Objective-C
 [button sizeToFit]; 
 ```

改为

 ```Objective-C
 button.frame = CGRectMake(0.0, 0.0, 250, 100);
 button.backgroundColor = [UIColor redColor];
 ```

效果如下，

![enter image description here](http://i64.tinypic.com/vx16r5.jpg)

同时你也可以顺便测试下 `CYLTabBarController` 的这一个特性：

 > 即使加号按钮超出了tabbar的区域，超出部分依然能响应点击事件

并且你可以在项目中的任意位置读取到 `PlusButton` 的宽度，借助 `CYLTabBarController.h` 定义的 `CYLPlusButtonWidth` 这个extern。可参考 `+[CYLTabBarControllerConfig customizeTabBarAppearance:]` 里的用法。

### 补充说明

#### 自定义 `TabBar` 样式

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
    [tabBar setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    
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

#### 横竖屏适配

`TabBar` 横竖屏适配时，如果你添加了 `PlusButton`，且适配时用到了 `TabBarItem` 的宽度, 不建议使用系统的`UIDeviceOrientationDidChangeNotification` , 请使用库里的 `CYLTabBarItemWidthDidChangeNotification` 来更新 `TabBar` 布局，最典型的场景就是，根据 `TabBarItem` 在不同横竖屏状态下的宽度变化来切换选中的`TabBarItem` 的背景图片。Demo 里 `CYLTabBarControllerConfig.m` 给出了这一场景的用法:


 `CYLTabBarController.h`  中提供了 `CYLTabBarItemWidth` 这一extern常量，并且会在 `TabBarItem` 的宽度发生变化时，及时更新该值，所以用法就如下所示：

 ```Objective-C
- (void)updateTabBarCustomizationWhenTabBarItemWidthDidUpdate {
    void (^deviceOrientationDidChangeBlock)(NSNotification *) = ^(NSNotification *notification) {
        [self tabBarItemWidthDidUpdate];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemWidthDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:deviceOrientationDidChangeBlock];
}

- (void)tabBarItemWidthDidUpdate {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if ((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight)) {
        NSLog(@"Landscape Left or Right !");
    } else if (orientation == UIDeviceOrientationPortrait){
        NSLog(@"Landscape portrait!");
    }
    CGSize selectionIndicatorImageSize = CGSizeMake(CYLTabBarItemWidth, [self cyl_tabBarController].tabBar.bounds.size.height);
    [[self cyl_tabBarController].tabBar setSelectionIndicatorImage:[[self class]
                                                                    imageFromColor:[UIColor yellowColor]
                                                                    forSize:selectionIndicatorImageSize
                                                                    withCornerRadius:0]];
}
 ```

![enter image description here](http://i67.tinypic.com/2u4snk7.jpg)

#### 访问初始化好的 CYLTabBarController 对象

对于任意 `NSObject` 对象：

 `CYLTabBarController.h`  中为 `NSObject` 提供了分类方法 `-cyl_tabBarController` ，所以在任意对象中，一行代码就可以访问到一个初始化好的  `CYLTabBarController`  对象，`-cyl_tabBarController` 的作用你可以这样理解：与获取单例对象的  `+shareInstance` 方法作用一样。

接口如下：

 ```Objective-C
// CYLTabBarController.h

@interface NSObject (CYLTabBarController)

/**
 * If `self` is kind of `UIViewController`, this method will return the nearest ancestor in the view controller hierarchy that is a tab bar controller. If `self` is not kind of `UIViewController`, it will return the `rootViewController` of the `rootWindow` as long as you have set the `CYLTabBarController` as the  `rootViewController`. Otherwise return nil. (read-only)
 */
@property (nonatomic, readonly) CYLTabBarController *cyl_tabBarController;

@end
 ```

用法：


 ```Objective-C
//导入 CYLTabBarController.h
#import "CYLTabBarController.h"

- (void)viewDidLoad {
    [super viewDidLoad];
    CYLTabBarController *tabbarController = [self cyl_tabBarController];
    /*...*/
}
 ```

##  点击 PlusButton 跳转到指定 UIViewController

提供了一个协议方法来完成本功能：

![enter image description here](http://i68.tinypic.com/2who9rs.jpg)

实现该方法后，能让 PlusButton 的点击效果与跟点击其他 UITabBarButton 效果一样，跳转到该方法指定的 UIViewController 。

注意：必须同时实现 `+indexOfPlusButtonInTabBar` 来指定 PlusButton 的位置。

遵循两个协议：

![enter image description here](http://i64.tinypic.com/14jw5zt.jpg)

## 让TabBarItem仅显示图标，并使图标垂直居中 

要想实现该效果，只需要在设置 `tabBarItemsAttributes`该属性时不传 title 即可。

比如：在Demo的基础上，注释掉图中红框部分：
![enter image description here](http://i64.tinypic.com/2cwu8ok.jpg)

注释前 | 注释后
-------------|-------------
![enter image description here](http://i66.tinypic.com/2z3rj0z.jpg)|![enter image description here](http://i65.tinypic.com/29cp1r9.jpg)

可以通过这种方式来达到 Airbnb-app 的效果：

![enter image description here](http://a63.tinypic.com/2mgk02v.gif)

如果想手动设置偏移量来达到该效果：
可以在 `-setViewControllers:` 方法前设置 `CYLTabBarController` 的 `imageInsets` 和 `titlePositionAdjustment` 属性

这里注意：设置这两个属性后，`TabBar` 中所有的 `TabBarItem` 都将被设置。并且第一种做法的逻辑将不会执行，也就是说该做法优先级要高于第一种做法。

做法如下：
![enter image description here](http://i66.tinypic.com/4rq8ap.jpg)

但是想达到Airbnb-app的效果只有这个接口是不行的，还需要自定义下 `TabBar` 的高度，你需要设置 `CYLTabBarController` 的 `tabBarHeight` 属性。你可以在Demo的 `CYLTabBarControllerConfig.m` 中的 `-customizeTabBarAppearance:` 方法中设置。

注：“仅显示图标，并使图标垂直居中”这里所指的“图标”，其所属的类是私有类： `UITabBarSwappableImageView`，所以 `CYLTabBarController` 在相关的接口命名时会包含 `SwappableImageView` 字样。另外，使用该特性需要 `pod update` 到 1.5.5以上的版本。

#### 在 Swift 项目中使用 CYLTabBarController

参考： [《从头开始swift2.1 仿搜材通项目（三） 主流框架Tabbed的搭建》]( http://www.jianshu.com/p/c5bc2eae0f55?nomobile=yes ) 

这里注意，文章的示例代码有问题，少了设置 PlusButton 大小的代码：
这将导致 PlusButton 点击事件失效，具体修改代码如下：
![enter image description here](http://i67.tinypic.com/118ottv.jpg)


### 源码实现原理

参考： [《[Note] CYLTabBarController》]( http://www.jianshu.com/p/8758d8014f86 ) 

更多文档信息可查看 [ ***CocoaDocs：CYLTabBarController*** ](http://cocoadocs.org/docsets/CYLTabBarController/1.2.1/index.html) 。

## Q-A

Q：为什么放置6个TabBarItem会显示异常？

A：

Apple 规定：

 >  一个 `TabBar` 上只能出现最多5个 `TabBarItem` ，第六个及更多的将不被显示。


另外注意，Apple检测的是 `UITabBarItem` 及其子类，所以放置“加号按钮”，这是 `UIButton` 不在“5个”里面。

最多只能添加5个 `TabBarItem` ，也就是说加上“加号按钮”，一共最多在一个 `TabBar` 上放置6个控件。否则第6个及之后出现 `TabBarItem` 会被自动屏蔽掉。而且就Apple的审核机制来说，超过5个也会被直接拒绝上架。

Q：我把 demo 两侧的 item 各去掉一个后，按钮的响应区域就变成下图的样子了：
 ![wechat_1445851872](https://cloud.githubusercontent.com/assets/12152553/10725491/62600172-7c07-11e5-9e0a-0ec7d795d1e3.jpeg)
  		  
 A：v1.5.5 版本已经修复了该问题，现在不会出现类似的问题了：点击按钮区域却不响应，响应区域有偏移。

Q： 如何实现添加选中背景色的功能 ，像下面这样：
<img width="409" alt="screen shot 2015-10-28 at 9 21 56 am" src="https://cloud.githubusercontent.com/assets/7238866/10777333/5d7811c8-7d55-11e5-88be-8cb11bbeaf90.png">

A：我已经在 Demo 中添加了如何实现该功能的代码：
详情见 `CYLTabBarControllerConfig`  类中下面方法的实现：

 ```Objective-C
/**
 *  更多TabBar自定义设置：比如：tabBarItem 的选中和不选中文字和背景图片属性、tabbar 背景图片属性
 */
- (void)customizeTabBarAppearance:(CYLTabBarController *)tabBarController;

 ```

效果如下：
![simulator screen shot 2015 10 28 11 44 32](https://cloud.githubusercontent.com/assets/2911921/10779397/34956b0a-7d6b-11e5-82d9-fa75aa34e8d0.png)


Q: 当 `ViewController` 设置的 `self.title` 和 `tabBarItemsAttributes` 中对应的 `title` 不一致的时候，会出现如图的错误，排序不对了

A：在 v1.0.7 版本中已经修复了该 bug，但是也需要注意：

请勿使用 `self.title = @"同城";  ` 这种方式，请使用 `self.navigationItem.title = @"同城"; ` 

`self.title = @"同城";  ` 这种方式，如果和 `tabBarItemsAttributes` 中对应的 `title` 不一致的时候可能会导致如下现象（不算 bug，但看起来也很奇怪）：

![enter image description here](http://i68.tinypic.com/282l3x4.jpg )



规则如下：

 ```Objective-C

    self.navigationItem.title = @"同城";    //✅sets navigation bar title.The right way to set the title of the navigation
    self.tabBarItem.title = @"同城23333";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in  tabbar.
    self.title = @"同城1";                  //❌sets both of these. Do not do this‼️‼️ This may cause something strange like this : http://i68.tinypic.com/282l3x4.jpg 

 ```

 Q :  当使用这个方法时 `-[UIViewController cyl_popSelectTabBarChildViewControllerAtIndex:]` 系列方法时，会出现如下的黑边问题。

![enter image description here](http://i63.tinypic.com/bg766g.jpg)

A： 这个是 iOS 系统的BUG，经测试iOS9.3已经修复了，如果在更早起版本中出现了，可以通过下面将 `rootWindow` 的背景色改为白色来避免：比如你可以 `Appdelegate` 类里这样设置：


 ```Objective-C
//#import "CYLTabBarController.h"
    [[self cyl_tabBarController] rootWindow].backgroundColor = [UIColor whiteColor];
 ```
Q:我现在已经做好了一个比较简单的中间凸起的 icon 但是超过了49这个高度的位置是不能效应的  我想请问你的demo哪个功能是可以使我超出的范围也可以响应的呢?

A: 这个是自动做的，但是 `CYLTabBarController` 只能保证的是：只要是 `UIButton` 的 frame 区域内就能响应。

请把 button 的背景颜色设置为显眼的颜色，比如红色，比如像下面的plus按钮，红色部分是能接收点击事件的，但是超出了红色按钮的，黄色的图片区域，依然是无法响应点击事件的。

![enter image description here](http://i64.tinypic.com/vx16r5.jpg)

这是因为，在响应链上，`UIControl` 能响应点击事件， `UIImage` 无法响应。



（更多iOS开发干货，欢迎关注  [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/) ）

----------
Posted by [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/)  
原创文章，版权声明：自由转载-非商用-非衍生-保持署名 | [Creative Commons BY-NC-ND 3.0](http://creativecommons.org/licenses/by-nc-nd/3.0/deed.zh)
<p align="center"><a href="http://weibo.com/u/1692391497?s=6uyXnP" target="_blank"><img border="0" src="http://service.t.sina.com.cn/widget/qmd/1692391497/b46c844b/1.png"/></a></a>
