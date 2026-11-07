//
//  UIImage+CYLTabBarControllerExtention.m
//  CYLTabBarController
//
//  Created by chenyilong on 18/4/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import "UIImage+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import <ImageIO/ImageIO.h>
#import <CommonCrypto/CommonDigest.h>

/// [EN] The cache key of a URL: its SHA-256.
/// [CN] URL 的缓存 key：其 SHA-256。
static NSString *CYLRemoteImageCacheKey(NSURL *URL) {
    NSData *data = [URL.absoluteString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *key = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [key appendFormat:@"%02x", digest[index]];
    }
    return key;
}

/// [EN] An image from downloaded data: animated for a GIF, at the screen scale otherwise.
/// [CN] 由数据生成图片：GIF 为动图，其他按屏幕倍数。
static UIImage *CYLRemoteImageWithData(NSData *data) {
    const char *bytes = data.bytes;
    if (data.length > 4 && memcmp(bytes, "GIF8", 4) == 0) {
        return [UIImage cyl_animatedImageWithGIFData:data];
    }
    return [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
}

#pragma mark - CYLImageCache

/// [EN] Bytes an image takes in memory: its pixels, 4 bytes each.
/// [CN] 图片在内存中占用的字节数：像素数 × 4。
static NSUInteger CYLRemoteImageCost(UIImage *image) {
    NSUInteger frames = MAX(image.images.count, 1);
    return (NSUInteger)(image.size.width * image.scale * image.size.height * image.scale * 4) * frames;
}

@interface CYLImageCache ()
@property (nonatomic, strong) NSCache<NSString *, UIImage *> *memoryCache;
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@end

@implementation CYLImageCache

+ (instancetype)sharedImageCache {
    static CYLImageCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[self alloc] init];
    });
    return cache;
}

- (instancetype)init {
    if (self = [super init]) {
        _memoryCache = [[NSCache alloc] init];
        _ioQueue = dispatch_queue_create("com.chenyilong.CYLTabBarController.CYLImageCache", DISPATCH_QUEUE_SERIAL);
        _shouldCacheImagesInMemory = YES;
        _shouldCacheImagesOnDisk = YES;
        self.maxMemoryCount = 100;
        _maxDiskAge = 7 * 24 * 60 * 60;
        _diskCacheExpireType = CYLImageCacheExpireTypeAccessDate;
        _downloadTimeout = 15;
        NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _diskCachePath = [caches stringByAppendingPathComponent:@"CYLTabBarController/RemoteImages"];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(clearMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [center addObserver:self selector:@selector(cyl_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [center addObserver:self selector:@selector(cyl_applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setMaxMemoryCount:(NSUInteger)maxMemoryCount {
    _maxMemoryCount = maxMemoryCount;
    self.memoryCache.countLimit = maxMemoryCount;
}

- (void)setMaxMemoryCost:(NSUInteger)maxMemoryCost {
    _maxMemoryCost = maxMemoryCost;
    self.memoryCache.totalCostLimit = maxMemoryCost;
}

- (NSString *)cyl_filePathForKey:(NSString *)key {
    return [self.diskCachePath stringByAppendingPathComponent:key];
}

- (nullable UIImage *)cyl_memoryImageForKey:(NSString *)key {
    return [self.memoryCache objectForKey:key];
}

- (void)cyl_storeImageInMemory:(UIImage *)image forKey:(NSString *)key {
    if (self.shouldCacheImagesInMemory) {
        [self.memoryCache setObject:image forKey:key cost:CYLRemoteImageCost(image)];
    }
}

/// [EN] Whether the file at `path` expired, by `diskCacheExpireType`.
/// [CN] 按 `diskCacheExpireType` 判断文件是否过期。
- (BOOL)cyl_isExpiredFileAtURL:(NSURL *)fileURL {
    if (self.maxDiskAge <= 0) {
        return NO;
    }
    NSURLResourceKey dateKey = (self.diskCacheExpireType == CYLImageCacheExpireTypeAccessDate) ?
        NSURLContentAccessDateKey : NSURLContentModificationDateKey;
    NSDate *date = nil;
    [fileURL getResourceValue:&date forKey:dateKey error:NULL];
    return !date || -[date timeIntervalSinceNow] > self.maxDiskAge;
}

/// [EN] Disk data of `key` when not expired; a hit renews its access date. Called on `ioQueue`.
/// [CN] 未过期的磁盘数据；命中时更新访问时间。
- (nullable NSData *)cyl_diskDataForKey:(NSString *)key {
    NSURL *fileURL = [NSURL fileURLWithPath:[self cyl_filePathForKey:key]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path] || [self cyl_isExpiredFileAtURL:fileURL]) {
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    if (data) {
        // The access date is not updated by every file system: set it, so `CYLImageCacheExpireTypeAccessDate` renews.
        [fileURL setResourceValue:[NSDate date] forKey:NSURLContentAccessDateKey error:NULL];
    }
    return data;
}

- (void)cyl_storeData:(NSData *)data forKey:(NSString *)key {
    if (!self.shouldCacheImagesOnDisk || data.length == 0) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        [data writeToFile:[self cyl_filePathForKey:key] atomically:YES];
    });
}

- (nullable UIImage *)imageFromCacheForURL:(NSURL *)URL {
    if (!URL) {
        return nil;
    }
    NSString *key = CYLRemoteImageCacheKey(URL);
    UIImage *image = [self cyl_memoryImageForKey:key];
    if (image) {
        return image;
    }
    __block NSData *data = nil;
    dispatch_sync(self.ioQueue, ^{
        data = [self cyl_diskDataForKey:key];
    });
    image = data ? CYLRemoteImageWithData(data) : nil;
    if (image) {
        [self cyl_storeImageInMemory:image forKey:key];
    }
    return image;
}

- (void)removeImageForURL:(NSURL *)URL {
    if (!URL) {
        return;
    }
    NSString *key = CYLRemoteImageCacheKey(URL);
    [self.memoryCache removeObjectForKey:key];
    dispatch_async(self.ioQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:[self cyl_filePathForKey:key] error:NULL];
    });
}

- (void)clearMemory {
    [self.memoryCache removeAllObjects];
}

- (void)clearDiskOnCompletion:(void (^)(void))completion {
    dispatch_async(self.ioQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:self.diskCachePath error:NULL];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    });
}

- (void)deleteOldFilesWithCompletion:(void (^)(void))completion {
    dispatch_async(self.ioQueue, ^{
        [self cyl_deleteOldFiles];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    });
}

/// [EN] Called on `ioQueue`, as SDWebImage's `-deleteOldFilesWithCompletionBlock:`.
/// [CN] 在 `ioQueue` 上执行。
- (void)cyl_deleteOldFiles {
    NSURL *directoryURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    NSArray<NSURLResourceKey> *keys = @[ NSURLIsDirectoryKey, NSURLContentAccessDateKey, NSURLContentModificationDateKey,
                                         NSURLTotalFileAllocatedSizeKey ];
    NSArray<NSURL *> *fileURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL
                                                                includingPropertiesForKeys:keys
                                                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                     error:NULL];
    NSURLResourceKey dateKey = (self.diskCacheExpireType == CYLImageCacheExpireTypeAccessDate) ?
        NSURLContentAccessDateKey : NSURLContentModificationDateKey;
    NSMutableDictionary<NSURL *, NSDictionary<NSURLResourceKey, id> *> *remainingFiles = [NSMutableDictionary dictionary];
    NSUInteger totalSize = 0;
    for (NSURL *fileURL in fileURLs) {
        NSDictionary<NSURLResourceKey, id> *values = [fileURL resourceValuesForKeys:keys error:NULL];
        if ([values[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        if ([self cyl_isExpiredFileAtURL:fileURL]) {
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
            continue;
        }
        totalSize += [values[NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
        remainingFiles[fileURL] = values;
    }
    if (self.maxDiskSize == 0 || totalSize <= self.maxDiskSize) {
        return;
    }
    // [EN] Least recently used first, down to half of the limit.
    // [CN] 先删除最久未用的文件，直到降到上限的一半。
    NSUInteger targetSize = self.maxDiskSize / 2;
    NSArray<NSURL *> *sortedFiles = [remainingFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                 usingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[dateKey] ?: [NSDate distantPast] compare:b[dateKey] ?: [NSDate distantPast]];
    }];
    for (NSURL *fileURL in sortedFiles) {
        if (totalSize <= targetSize) {
            break;
        }
        if ([[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL]) {
            totalSize -= MIN(totalSize, [remainingFiles[fileURL][NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue]);
        }
    }
}

- (NSUInteger)totalDiskSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in enumerator) {
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self cyl_filePathForKey:fileName] error:NULL];
            size += [attributes fileSize];
        }
    });
    return size;
}

- (void)cyl_applicationDidEnterBackground {
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier taskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:taskIdentifier];
        taskIdentifier = UIBackgroundTaskInvalid;
    }];
    [self deleteOldFilesWithCompletion:^{
        [application endBackgroundTask:taskIdentifier];
        taskIdentifier = UIBackgroundTaskInvalid;
    }];
}

- (void)cyl_applicationWillTerminate {
    [self deleteOldFilesWithCompletion:nil];
}

/// [EN] Loads `URL` with `options`; `finish` runs once, on any queue.
/// [CN] 按 `options` 加载 `URL`；`finish` 只调用一次，可在任意队列。
- (void)cyl_loadImageWithURL:(NSURL *)URL options:(CYLImageLoadOptions)options finish:(void (^)(UIImage *))finish {
    NSString *key = CYLRemoteImageCacheKey(URL);
    BOOL refreshes = (options & CYLImageLoadOptionsRefreshCached) != 0;
    BOOL keepsInMemory = (options & CYLImageLoadOptionsAvoidMemoryCache) == 0;
    UIImage *memoryImage = refreshes ? nil : [self cyl_memoryImageForKey:key];
    if (memoryImage) {
        finish(memoryImage);
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSData *diskData = refreshes ? nil : [self cyl_diskDataForKey:key];
        UIImage *diskImage = diskData ? CYLRemoteImageWithData(diskData) : nil;
        if (diskImage) {
            if (keepsInMemory) {
                [self cyl_storeImageInMemory:diskImage forKey:key];
            }
            finish(diskImage);
            return;
        }
        if (options & CYLImageLoadOptionsFromCacheOnly) {
            finish(nil);
            return;
        }
        NSURLRequestCachePolicy cachePolicy = refreshes ? NSURLRequestReloadIgnoringLocalCacheData : NSURLRequestUseProtocolCachePolicy;
        NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:cachePolicy timeoutInterval:self.downloadTimeout];
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 200;
            UIImage *image = (!error && data && statusCode / 100 == 2) ? CYLRemoteImageWithData(data) : nil;
            if (image) {
                if (keepsInMemory) {
                    [self cyl_storeImageInMemory:image forKey:key];
                }
                if ((options & CYLImageLoadOptionsMemoryCacheOnly) == 0) {
                    [self cyl_storeData:data forKey:key];
                }
            }
            finish(image);
        }] resume];
    });
}

@end

@implementation UIImage (CYLTabBarControllerExtention)

+ (void)cyl_loadImageWithURL:(NSURL *)URL completion:(void (^)(UIImage *))completion {
    [self cyl_loadImageWithURL:URL options:CYLImageLoadOptionsDefault completion:completion];
}

+ (void)cyl_loadImageWithURL:(NSURL *)URL options:(CYLImageLoadOptions)options completion:(void (^)(UIImage *))completion {
    void (^finish)(UIImage *) = ^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(image);
        });
    };
    if (!URL) {
        finish(nil);
        return;
    }
    [[CYLImageCache sharedImageCache] cyl_loadImageWithURL:URL options:options finish:finish];
}

+ (NSTimeInterval)cyl_GIFFrameDelayWithProperties:(NSDictionary *)properties {
    // [EN] The frame's delay, unclamped first; browsers treat very short delays as 0.1 s.
    // [CN] 帧时长，优先使用未修正值；与浏览器一致，过短的时长按 0.1 秒处理。
    NSDictionary *gifProperties = properties[(__bridge NSString *)kCGImagePropertyGIFDictionary];
    NSNumber *delay = gifProperties[(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delay.doubleValue <= 0) {
        delay = gifProperties[(__bridge NSString *)kCGImagePropertyGIFDelayTime];
    }
    return (delay.doubleValue < 0.011) ? 0.1 : delay.doubleValue;
}

+ (UIImage *)cyl_animatedImageWithGIFData:(NSData *)data {
    if (data.length == 0) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
    CGFloat scale = [UIScreen mainScreen].scale;
    NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0;
    for (size_t index = 0; index < count; index++) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, index, NULL);
        if (!imageRef) {
            continue;
        }
        [frames addObject:[UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp]];
        CGImageRelease(imageRef);
        NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
        duration += [self cyl_GIFFrameDelayWithProperties:properties];
    }
    CFRelease(source);
    if (frames.count <= 1) {
        return frames.firstObject;
    }
    return [UIImage animatedImageWithImages:frames duration:duration];
}

+ (nullable UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) { return nil; }
    return [self cyl_imageWithColor:color size:size cornerRadius:0 renderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - Dark Mode (#552, #620)

/// A copy of `image` that belongs to no image asset, so it can be registered in a new one. Images that are not
/// bitmap based (e.g. symbols) are returned as they are.
static UIImage *CYLImageForRegistering(UIImage *image) {
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        return image;
    }
    UIImage *copy = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:image.imageOrientation];
    return [copy imageWithRenderingMode:image.renderingMode];
}

/// The variant of `image` for `style` when it comes from an asset with appearances (e.g. an asset catalog image, or one
/// made by `+cyl_imageWithLightImage:darkImage:`), keeping its rendering mode; `image` itself otherwise. Without it, an
/// asset image passed while the app is dark would put its dark bitmap in the light slot.
static UIImage *CYLImageVariantForStyle(UIImage *image, UIUserInterfaceStyle style) API_AVAILABLE(ios(13.0)) {
    if (!image.imageAsset) {
        return image;
    }
    UITraitCollection *traits = [UITraitCollection traitCollectionWithTraitsFromCollections:@[
        [UITraitCollection traitCollectionWithDisplayScale:image.scale],
        [UITraitCollection traitCollectionWithUserInterfaceStyle:style],
    ]];
    UIImage *variant = [image.imageAsset imageWithTraitCollection:traits];
    return variant ? [variant imageWithRenderingMode:image.renderingMode] : image;
}

+ (nullable UIImage *)cyl_imageWithLightImage:(nullable UIImage *)lightImage darkImage:(nullable UIImage *)darkImage {
    if (!lightImage || !darkImage) {
        return lightImage ?: darkImage;
    }
    if (@available(iOS 13.0, *)) {
        lightImage = CYLImageVariantForStyle(lightImage, UIUserInterfaceStyleLight);
        darkImage = CYLImageVariantForStyle(darkImage, UIUserInterfaceStyleDark);
        // Registered like an asset catalog image with "Any" and "Dark" appearances: the light image for any style
        // (light and unspecified), the dark one for dark. UIKit resolves such an image against each view's traits.
        UITraitCollection *anyTraits = [UITraitCollection traitCollectionWithDisplayScale:lightImage.scale];
        UITraitCollection *darkTraits = [UITraitCollection traitCollectionWithTraitsFromCollections:@[
            [UITraitCollection traitCollectionWithDisplayScale:darkImage.scale],
            [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark],
        ]];
        UIImageAsset *imageAsset = [[UIImageAsset alloc] init];
        [imageAsset registerImage:CYLImageForRegistering(lightImage) withTraitCollection:anyTraits];
        [imageAsset registerImage:CYLImageForRegistering(darkImage) withTraitCollection:darkTraits];
        return [imageAsset imageWithTraitCollection:[UITraitCollection currentTraitCollection]];
    }
    return lightImage;
}

#pragma mark - Dark images by name

static NSString *CYLDarkImageNameSuffix = @"_dark";

+ (nullable NSString *)cyl_darkImageNameSuffix {
    return CYLDarkImageNameSuffix;
}

+ (void)cyl_setDarkImageNameSuffix:(nullable NSString *)darkImageNameSuffix {
    CYLDarkImageNameSuffix = darkImageNameSuffix.length > 0 ? [darkImageNameSuffix copy] : nil;
}

/// `name` with the dark suffix before its extension, if any: "home" → "home_dark", "home.png" → "home_dark.png".
/// nil when the convention is off or `name` already ends with the suffix.
static NSString *CYLDarkImageNameForName(NSString *name) {
    NSString *suffix = CYLDarkImageNameSuffix;
    NSString *baseName = name.stringByDeletingPathExtension;
    if (suffix.length == 0 || baseName.length == 0 || [baseName hasSuffix:suffix]) {
        return nil;
    }
    NSString *darkName = [baseName stringByAppendingString:suffix];
    return name.pathExtension.length > 0 ? [darkName stringByAppendingPathExtension:name.pathExtension] : darkName;
}

/// YES if `image` comes from an asset with its own Dark appearance, e.g. an asset catalog image set to "Any, Dark".
static BOOL CYLImageHasDarkAppearance(UIImage *image) {
    if (@available(iOS 13.0, *)) {
        UIImageAsset *imageAsset = image.imageAsset;
        if (!imageAsset) {
            return NO;
        }
        UIImage *lightImage = [imageAsset imageWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        UIImage *darkImage = [imageAsset imageWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        return lightImage && darkImage && lightImage != darkImage && lightImage.CGImage != darkImage.CGImage;
    }
    return NO;
}

/*!
 * [EN] The image named `name`, with its dark image when it has one: the asset's own Dark appearance (which wins, so one
 *      image never gets two dark sources), else the image named `name` + `cyl_darkImageNameSuffix`.
 * [CN] 名为 `name` 的图片，并带上它的深色图片（如果有）：优先使用 asset 自身的 Dark 外观（同一张图不会有两个深色来源），
 *      否则使用名为 `name` + `cyl_darkImageNameSuffix` 的图片。
 */
/*!
 * FIX: issue #535, #601
 * [EN] An image by name, or by the absolute path of a file anywhere (e.g. an icon downloaded to the Documents directory):
 *      a path is loaded with `+imageWithContentsOfFile:`, which does not keep it in the system image cache.
 * [CN] 按名称加载图片，或按任意位置文件的绝对路径加载（例如下载到 Documents 目录的图标）：路径使用 `+imageWithContentsOfFile:` 加载，
 *      不会进入系统图片缓存。
 */
static UIImage *CYLImageNamedOrAtPath(NSString *name) {
    if (name.isAbsolutePath) {
        return [UIImage imageWithContentsOfFile:name];
    }
    return [UIImage imageNamed:name];
}

+ (nullable UIImage *)cyl_imageNamedFollowingDarkMode:(NSString *)name renderingMode:(UIImageRenderingMode)renderingMode {
    UIImage *image = CYLImageNamedOrAtPath(name);
    if (!image || CYLImageHasDarkAppearance(image)) {
        return [image imageWithRenderingMode:renderingMode];
    }
    NSString *darkName = CYLDarkImageNameForName(name);
    UIImage *darkImage = darkName ? CYLImageNamedOrAtPath(darkName) : nil;
    image = [image imageWithRenderingMode:renderingMode];
    if (!darkImage) {
        return image;
    }
    return [self cyl_imageWithLightImage:image darkImage:[darkImage imageWithRenderingMode:renderingMode]];
}

+ (UIImage *)cyl_assetImageName:(NSString *)assetImageName
             userInterfaceStyle:(NSInteger)userInterfaceStyle  {
    // This used to load an image named "image" whatever the name passed.
    UIImage *image = [UIImage imageNamed:assetImageName];
    if (@available(iOS 13.0, *)) {
        if (image.imageAsset && userInterfaceStyle != UIUserInterfaceStyleUnspecified) {
            UITraitCollection *trait = [UITraitCollection traitCollectionWithUserInterfaceStyle:userInterfaceStyle];
            image = [image.imageAsset imageWithTraitCollection:trait] ?: image;
        }
    }
    return image;
}

+ (UIImage *)cyl_lightOrDarkModeImageWithLightImage:(UIImage *)lightImage
                                          darkImage:(UIImage *)darkImage  {
    return [self cyl_imageWithLightImage:lightImage darkImage:darkImage];
}

+ (UIImage *)cyl_lightOrDarkModeImageWithOwner:(id<UITraitEnvironment>)owner
                                lightImageName:(NSString *)lightImageName
                                 darkImageName:(NSString *)darkImageName {
    if (darkImageName.length == 0) {
        // No dark name: follow the asset's own Dark appearance or the naming convention.
        UIImage *image = lightImageName.length > 0 ? [self cyl_imageNamedFollowingDarkMode:lightImageName renderingMode:UIImageRenderingModeAutomatic] : nil;
        return [UIImage cyl_lightOrDarkModeImageWithOwner:owner lightImage:image darkImage:nil];
    }
    UIImage *lightImage = lightImageName.length > 0 ? [UIImage imageNamed:lightImageName] : nil;
    UIImage *darkImage = [UIImage imageNamed:darkImageName];
    return [UIImage cyl_lightOrDarkModeImageWithOwner:owner lightImage:lightImage darkImage:darkImage];
}

/*!
 * FIX: issue #620
 * [EN] This used to pick one of the two images once, by the window scene's style when `owner` was nil. A scene ignores
 *      `overrideUserInterfaceStyle` on its windows, so a window forced to light or dark still got the image of the
 *      system style, and the image never changed afterwards. It now returns an image that holds both and follows the
 *      style of whichever view shows it; `owner` only picks which one the returned object starts as.
 * [CN] 原先只选择一次，`owner` 为 nil 时依据 window scene 的风格。scene 不认其 window 上的 `overrideUserInterfaceStyle`，
 *      因此强制为浅色或深色的 window 仍得到系统风格的图片，之后也不再切换。现在返回同时包含两张图的图片，随显示它的视图的风格切换；
 *      `owner` 只决定返回对象的初始外观。
 */
+ (UIImage *)cyl_lightOrDarkModeImageWithOwner:(id<UITraitEnvironment>)owner
                                    lightImage:(UIImage *)lightImage
                                     darkImage:(UIImage *)darkImage {
    UIImage *image = [self cyl_imageWithLightImage:lightImage darkImage:darkImage];
    if (@available(iOS 13.0, *)) {
        if (owner && image.imageAsset) {
            image = [image.imageAsset imageWithTraitCollection:owner.traitCollection] ?: image;
        }
    }
    return image;
}

+ (nullable UIImage *)cyl_getImageFromImageInfo:(id)imageInfo {
    UIImage *image = nil;
    if ([imageInfo isKindOfClass:[NSString class]]) {
        // A name also brings its dark image: the asset's own Dark appearance, else "<name>_dark" (see
        // `cyl_darkImageNameSuffix`). Both keep the always-original rendering a name has always had.
        image = [self cyl_imageNamedFollowingDarkMode:imageInfo renderingMode:UIImageRenderingModeAlwaysOriginal];
    } else if ([imageInfo isKindOfClass:[UIImage class]]) {
        image = (UIImage *)imageInfo;
    }
    return image;
}

+ (nullable UIImage *)cyl_imageWithImageInfo:(nullable id)imageInfo darkImageInfo:(nullable id)darkImageInfo {
    UIImage *image = imageInfo ? [self cyl_getImageFromImageInfo:imageInfo] : nil;
    UIImage *darkImage = darkImageInfo ? [self cyl_getImageFromImageInfo:darkImageInfo] : nil;
    if (!darkImage) {
        return image;
    }
    // A dark image given explicitly replaces any the name brought (asset appearance or naming convention).
    return [self cyl_imageWithLightImage:image darkImage:darkImage];
}

+ (UIImage *)cyl_imageNamed:(nullable id)imageInfo {
    UIImage *image = nil;
    if (imageInfo) {
        image = [self cyl_getImageFromImageInfo:imageInfo];
    }
    else {
        image = [self cyl_tabItemPlaceholderImage];
    }
    return image;
}

+ (UIImage *)cyl_tabItemPlaceholderImage {
    // Transparent: it only keeps the item's layout. It used to be white, drawn as is (always original), so a tab
    // without an image showed a white dot, plain to see on a dark tab bar.
    // 透明：只用于保持布局。原先是白色且按原图绘制，没有图片的 Tab 会显示一个白点，在深色 TabBar 上尤其明显。
    CGSize placeholderSize = CGSizeMake(1, 1);
    UIImage *placeholderImage = [UIImage cyl_imageWithColor:[UIColor clearColor] size:placeholderSize];
    return placeholderImage;
}

+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    return [self cyl_imageWithColor:color size:size cornerRadius:cornerRadius renderingMode:UIImageRenderingModeAutomatic];
}

/*!
 * [EN] A dynamic color (e.g. `systemBackgroundColor`, `+cyl_colorWithLightColor:darkColor:`) is drawn twice, resolved
 *      for light and for dark, and returned as one image that follows Dark Mode. Drawing `color.CGColor` once froze it
 *      in the style current at that moment.
 * [CN] 动态颜色（如 `systemBackgroundColor`、`+cyl_colorWithLightColor:darkColor:`）分别按浅色和深色解析并绘制两次，
 *      合成一张跟随深色模式的图片。原先只用 `color.CGColor` 绘制一次，颜色被固定为当时的风格。
 */
+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius renderingMode:(UIImageRenderingMode)renderingMode {
    color = color ? color : [UIColor clearColor];
    if (@available(iOS 13.0, *)) {
        UIColor *lightColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        UIColor *darkColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        if (![lightColor isEqual:darkColor]) {
            UIImage *lightImage = [self cyl_staticImageWithColor:lightColor size:size cornerRadius:cornerRadius];
            UIImage *darkImage = [self cyl_staticImageWithColor:darkColor size:size cornerRadius:cornerRadius];
            return [self cyl_imageWithLightImage:[lightImage imageWithRenderingMode:renderingMode]
                                       darkImage:[darkImage imageWithRenderingMode:renderingMode]];
        }
    }
    return [[self cyl_staticImageWithColor:color size:size cornerRadius:cornerRadius] imageWithRenderingMode:renderingMode];
}

+ (UIImage *)cyl_staticImageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    // Not `-getRed:green:blue:alpha:`: it fails for grayscale colors such as `+whiteColor` and left the alpha at 0.
    BOOL opaque = (cornerRadius == 0.0 && CGColorGetAlpha(color.CGColor) == 1.0);
    return [self cyl_imageWithSize:size opaque:opaque scale:0 actions:^(CGContextRef contextRef) {
        CGContextSetFillColorWithColor(contextRef, color.CGColor);
        if (cornerRadius > 0) {
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:cornerRadius];
            [path addClip];
            [path fill];
        } else {
            CGContextFillRect(contextRef, CGRectMake(0, 0, size.width, size.height));
        }
    }];
}

+ (UIImage *)cyl_imageWithSize:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale actions:(void (^)(CGContextRef contextRef))actionBlock {
    if (!actionBlock || size.width <= 0 || size.height <= 0) {
        return nil;
    }
    // `UIGraphicsImageRenderer`: `UIGraphicsBeginImageContextWithOptions` is deprecated (iOS 17), and its early return
    // on a nil context left the image context pushed.
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.opaque = opaque;
    if (scale > 0) {
        format.scale = scale;   // 0 keeps the screen scale, as `UIGraphicsBeginImageContextWithOptions` did
    }
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        actionBlock(rendererContext.CGContext);
    }];
}

@end
