//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTabBarDemoViewController.h"
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
//#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#else
#endif
#import "CYLFlatDesignTableViewController.h"
#import "CYLTabBarController.h"
//#import "CYLFlatDesignUIViewController.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
@interface CYLFlatDesignTabBarDemoViewController ()<UITableViewDelegate, UITableViewDataSource, CYLFlatDesignTabBarDelegate>

#else
@interface CYLFlatDesignTabBarDemoViewController ()<UITableViewDelegate, UITableViewDataSource>

#endif
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *datas;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
@property (nonatomic, strong) CYLFlatDesignTabBar *tabBar;

#else
#endif
@property (nonatomic, strong) UITabBar *uitabBar;

@end

@implementation CYLFlatDesignTabBarDemoViewController

- (NSArray<NSString *> *)datas {
    if (!_datas) {
        _datas = @[
            @"设置 barTintColor",
            @"设置 backgroundImage",
            @"设置 shadowImage",
            @"设置 tintColor",
            @"设置 items",
            @"设置 清空",
        ];
    }
    return _datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initSubviews];
}

- (void)initSubviews {
    
    NSArray *titles = @[@"主页", @"同城", @"消息"];
    NSArray *images = @[@"home_normal", @"fishpond_normal", @"message_normal"];
    NSArray *selectedImages = @[@"home_highlight", @"fishpond_highlight", @"message_highlight"];
    NSMutableArray *items = [NSMutableArray array];
    for (NSInteger i = 0; i < titles.count; i++) {
        UIImage *selectedImage = [UIImage imageNamed:selectedImages[i]];
        UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:titles[i] image:[UIImage imageNamed:images[i]] selectedImage:selectedImage];
        [items addObject:item];
    }
    
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    _tabBar = [[CYLFlatDesignTabBar alloc] init];
    _tabBar.cyl_context = NSStringFromClass([self class]);

    _tabBar.delegate = self;
    _tabBar.items = [items copy];
    [self.view addSubview:_tabBar];
#else
#endif
    
    _uitabBar = [[UITabBar alloc] init];
    _uitabBar.items = [items copy];
    _uitabBar.cyl_context = NSStringFromClass([self class]);

    [self.view addSubview:_uitabBar];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 50;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.view insertSubview:_tableView atIndex:0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    _tabBar.frame = CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame) + 20, self.view.frame.size.width, 49);
    
    CGFloat uitabBarHeight = _tabBar.frame.size.height;
    if ([CYLConstants isLiquidGlassActive]) {
        uitabBarHeight = 91;
    }
    _uitabBar.frame = CGRectMake(0, CGRectGetMaxY(_tabBar.frame) + 10, self.view.frame.size.width, uitabBarHeight);
    _tableView.frame = CGRectMake(0, CGRectGetMaxY(_uitabBar.frame), self.view.frame.size.width, self.view.frame.size.height - (CGRectGetMaxY(_uitabBar.frame)+ 10));
    
#else
#endif
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    
    
    cell.textLabel.text = self.datas[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    if (indexPath.row == 0) {
        _tabBar.barTintColor = [self.cyl_randomColor colorWithAlphaComponent:0.5];
        _uitabBar.barTintColor = _tabBar.barTintColor;
    } else if (indexPath.row == 1) {
        _tabBar.backgroundImage = [UIImage cyl_imageWithColor:self.cyl_randomColor size:CGSizeMake(4, 4)];
        _uitabBar.backgroundImage = _tabBar.backgroundImage;
    } else if (indexPath.row == 2) {
        _tabBar.shadowImage = [UIImage cyl_imageWithColor:self.cyl_randomColor size:CGSizeMake(4, 1)];
        _uitabBar.shadowImage = _tabBar.shadowImage;
    } else if (indexPath.row == 3) {
        _tabBar.tintColor = self.cyl_randomColor;
        _uitabBar.tintColor = _tabBar.tintColor;
    } else if (indexPath.row == 4) {
        NSMutableArray *items = [_tabBar.items mutableCopy];
        [items removeLastObject];
        _tabBar.items = items;
        _uitabBar.items = items;
    } else if (indexPath.row == 5) {
        _tabBar.backgroundImage = nil;
        _tabBar.shadowImage = nil;
        _tabBar.tintColor = nil;
        _tabBar.barTintColor = nil;
        _tabBar.items = nil;
        
        _uitabBar.backgroundImage = nil;
        _uitabBar.shadowImage = nil;
        _uitabBar.tintColor = nil;
        _uitabBar.barTintColor = nil;
        _uitabBar.items = nil;
    }

#else
#endif
}

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItem:(CYLFlatDesignTabBarItem *)item {
    CYLTabBarController *tabBarController = (CYLTabBarController *)self.cylflatdesign_tabBarController;
    if (tabBarController) {
        if (tabBarController.isTabBarHidden) {
            [tabBarController setTabBarHidden:NO animated:YES];
        } else {
            [tabBarController setTabBarHidden:YES animated:YES];
        }
    }
    
    
    /*!
     * else {
            CYLFlatDesignUIViewController *tabBarController = self.cylflatdesign_tabBarController;
            if (tabBarController.isTabBarHidden) {
                [tabBarController setTabBarHidden:NO animated:YES];
            } else {
                [tabBarController setTabBarHidden:YES animated:YES];
            }
        }
     */
}
#else
#endif

#pragma mark - Helps
- (UIColor *)cyl_randomColor {
    CGFloat red = ( arc4random() % 255 / 255.0 );
    CGFloat green = ( arc4random() % 255 / 255.0 );
    CGFloat blue = ( arc4random() % 255 / 255.0 );
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end
