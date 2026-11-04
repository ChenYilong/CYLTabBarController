//
//  CYLGalleryProvider.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// [EN] Builds the view controller a gallery row presents. [CN] 创建图库中一行要展示的控制器。
typedef UIViewController *_Nonnull (^CYLGallerySceneBuilder)(void);
/// [EN] Runs after the scene was presented (e.g. to change the selected tab, as code would). [CN] 场景展示后执行（例如像代码一样切换选中的 Tab）。
typedef void (^CYLGallerySceneDidPresent)(UIViewController *presentedViewController);

/*!
 * [EN] One row of the tab bar gallery: a tab bar built with the library's public API, presented when the row is tapped.
 * [CN] TabBar 图库中的一行：用本库公开 API 构建的 TabBar，点击该行时展示。
 */
@interface CYLGalleryScene : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
@property (nonatomic, copy, readonly) CYLGallerySceneBuilder builder;
@property (nonatomic, copy, readonly, nullable) CYLGallerySceneDidPresent didPresent;
@end

/// [EN] A section of the gallery. [CN] 图库中的一个分组。
@interface CYLGallerySection : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSArray<CYLGalleryScene *> *scenes;
@end

/*!
 * [EN] The scenes of the tab bar gallery: the system baselines, embedding, animations, an irregular center button,
 *      custom clicks, reminders, Lottie, and the newer tab APIs (reselect behavior, press animations, hijacked tabs,
 *      per-tab colors and fonts, accessibility identifiers, positioning). See docs/Tab-Bar-Gallery.md.
 * [CN] TabBar 图库中的场景：系统样式对照、嵌套、动画、不规则中间按钮、自定义点击、提醒、Lottie，以及新增的 Tab 接口（重复点击操作、
 *      按下动画、劫持 Tab、单个 Tab 的颜色与字体、无障碍标识、排列方式）。见 docs/Tab-Bar-Gallery.md。
 */
@interface CYLGalleryProvider : NSObject

+ (NSArray<CYLGallerySection *> *)sections;

@end

NS_ASSUME_NONNULL_END
