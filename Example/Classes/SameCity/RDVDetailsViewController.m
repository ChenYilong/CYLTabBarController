//
//  RDVDetailsViewController.m
//  RDVTabBarController
//
//  Created by Robert Dimitrov on 11/8/14.
//  Copyright (c) 2014 Robert Dimitrov. All rights reserved.
//

#import "RDVDetailsViewController.h"
#import "CYLTabBarController.h"

@interface RDVDetailsViewController ()

@end

@implementation RDVDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"详情页";
    self.view.backgroundColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1.0];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"微博@iOS程序犭袁";
    label.frame = CGRectMake(20, 150, CGRectGetWidth(self.view.frame) - 2 * 20, 20);
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
}

@end
