//
//  CYLGalleryViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLGalleryViewController.h"
#import "CYLGalleryProvider.h"

static NSString *const CYLGalleryCellIdentifier = @"CYLGalleryCell";

@interface CYLGalleryViewController ()
@property (nonatomic, copy) NSArray<CYLGallerySection *> *sections;
@end

@implementation CYLGalleryViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Tab Bar Gallery";
    self.sections = [CYLGalleryProvider sections];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[(NSUInteger)section].title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.sections[(NSUInteger)section].scenes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLGalleryCellIdentifier] ?:
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLGalleryCellIdentifier];
    CYLGalleryScene *scene = self.sections[(NSUInteger)indexPath.section].scenes[(NSUInteger)indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@.%@ %@", @(indexPath.section + 1), @(indexPath.row + 1), scene.title];
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.text = scene.subtitle;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.detailTextLabel.numberOfLines = 0;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CYLGalleryScene *scene = self.sections[(NSUInteger)indexPath.section].scenes[(NSUInteger)indexPath.row];
    UIViewController *viewController = scene.builder();
    CYLGallerySceneDidPresent didPresent = scene.didPresent;
    if (scene.pushes && self.navigationController) {
        viewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:viewController animated:YES];
        if (didPresent) {
            didPresent(viewController);
        }
        return;
    }
    [self presentViewController:viewController animated:YES completion:^{
        if (didPresent) {
            didPresent(viewController);
        }
    }];
}

@end
