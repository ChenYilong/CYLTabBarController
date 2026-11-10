//
//  CYLGalleryViewController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The tab bar gallery: one row per scene of `CYLGalleryProvider`; tapping a row presents that tab bar. See
 *      docs/Tab-Bar-Gallery.md.
 * [CN] TabBar 图库：`CYLGalleryProvider` 中的每个场景一行；点击某行展示对应的 TabBar。见 docs/Tab-Bar-Gallery.md。
 */
@interface CYLGalleryViewController : UITableViewController

/*!
 * [EN] The scene number given at launch with `-CYLDemoGalleryScene 8.1` (section.row, as the list shows it), for
 *      screenshots and checks; nil without it. The home page opens the gallery and the gallery opens that scene once.
 * [CN] 启动时以 `-CYLDemoGalleryScene 8.1` 指定的场景编号（分组.行，与列表显示一致），用于截图与检查；没有时为 nil。
 *      首页打开图库，图库打开该场景，各一次。
 */
+ (nullable NSString *)cyl_launchSceneNumber;

@end

NS_ASSUME_NONNULL_END
