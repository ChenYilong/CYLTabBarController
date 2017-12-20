//
//  CYLPlusDemoChildViewController.m
//  CYLTabBarController
//
//  Created by chenyilong on 19/12/2017.
//  Copyright © 2017 微博@iOS程序犭袁. All rights reserved.
//

#import "CYLPlusDemoChildViewController.h"

@interface CYLPlusDemoChildViewController ()

@end

@implementation CYLPlusDemoChildViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"");
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
