//
//  CYLTabBarItemAnimationColorCount.m
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemAnimationColorCount.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>

static const NSInteger CYLColorCountTolerance = 2;
static const double CYLColorCountGIFShare = 0.98;
static const unsigned long long CYLColorCountMaxFileBytes = 8ull * 1024 * 1024;

#pragma mark - Lottie

/// [EN] One 8-bit color, or nil when it is fully transparent or malformed. [CN] 一个 8 位颜色；完全透明或格式错误时为 nil。
static NSArray<NSNumber *> *CYLColorCountBytes(id value) {
    if (![value isKindOfClass:[NSArray class]] || [(NSArray *)value count] < 3) {
        return nil;
    }
    NSArray *array = value;
    double c[3];
    double maxChannel = 0;
    for (NSUInteger i = 0; i < 3; i++) {
        if (![array[i] isKindOfClass:[NSNumber class]]) {
            return nil;
        }
        c[i] = [array[i] doubleValue];
        maxChannel = MAX(maxChannel, c[i]);
    }
    if (array.count >= 4 && [array[3] isKindOfClass:[NSNumber class]] && [array[3] doubleValue] <= 0) {
        return nil;
    }
    double scale = maxChannel > 1.0 ? 1.0 : 255.0;
    NSMutableArray<NSNumber *> *bytes = [NSMutableArray arrayWithCapacity:3];
    for (NSUInteger i = 0; i < 3; i++) {
        long v = lround(MIN(255.0, MAX(0.0, c[i] * scale)));
        [bytes addObject:@(v)];
    }
    return bytes;
}

/// [EN] The colors of an animatable color property: a static array, or keyframes (`s`, `e`). [CN] 可动画颜色属性的颜色：静态数组或关键帧（`s`、`e`）。
static void CYLColorCountCollectProperty(id property, NSMutableArray<NSArray<NSNumber *> *> *colors) {
    if (![property isKindOfClass:[NSDictionary class]]) {
        return;
    }
    id k = ((NSDictionary *)property)[@"k"];
    if (![k isKindOfClass:[NSArray class]] || [(NSArray *)k count] == 0) {
        return;
    }
    if ([[(NSArray *)k firstObject] isKindOfClass:[NSNumber class]]) {
        NSArray<NSNumber *> *bytes = CYLColorCountBytes(k);
        if (bytes) {
            [colors addObject:bytes];
        }
        return;
    }
    for (id keyframe in (NSArray *)k) {
        if (![keyframe isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        for (NSString *key in @[ @"s", @"e" ]) {
            NSArray<NSNumber *> *bytes = CYLColorCountBytes(keyframe[key]);
            if (bytes) {
                [colors addObject:bytes];
            }
        }
    }
}

static BOOL CYLColorCountOpacityIsStaticZero(id property) {
    if (![property isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    id k = ((NSDictionary *)property)[@"k"];
    return [k isKindOfClass:[NSNumber class]] && [k doubleValue] <= 0;
}

static void CYLColorCountWalk(id node, NSMutableArray<NSArray<NSNumber *> *> *colors, BOOL *multi) {
    if (*multi) {
        return;
    }
    if ([node isKindOfClass:[NSArray class]]) {
        for (id child in (NSArray *)node) {
            CYLColorCountWalk(child, colors, multi);
        }
        return;
    }
    if (![node isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *dict = node;
    id type = dict[@"ty"];
    if ([type isKindOfClass:[NSString class]]) {
        BOOL hidden = [dict[@"hd"] boolValue];
        if (!hidden) {
            if ([type isEqualToString:@"gf"] || [type isEqualToString:@"gs"]) {
                *multi = YES;
                return;
            }
            if ([type isEqualToString:@"fl"] || [type isEqualToString:@"st"]) {
                if (!CYLColorCountOpacityIsStaticZero(dict[@"o"])) {
                    CYLColorCountCollectProperty(dict[@"c"], colors);
                }
            }
        }
    } else if ([type isKindOfClass:[NSNumber class]] && [type integerValue] == 2
               && (dict[@"ind"] || dict[@"refId"] || dict[@"ip"])) {
        // [EN] An image layer. [CN] 图片图层。
        *multi = YES;
        return;
    }
    if ([dict[@"p"] isKindOfClass:[NSString class]] && [dict[@"p"] length] > 0 && (dict[@"u"] || dict[@"e"] || dict[@"w"])) {
        // [EN] An image asset. [CN] 图片资源。
        *multi = YES;
        return;
    }
    for (id child in dict.allValues) {
        if ([child isKindOfClass:[NSDictionary class]] || [child isKindOfClass:[NSArray class]]) {
            CYLColorCountWalk(child, colors, multi);
        }
    }
}

static CYLTabBarItemAnimationColorKind CYLColorCountKindOfLottie(NSData *data) {
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![root isKindOfClass:[NSDictionary class]]) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    NSMutableArray<NSArray<NSNumber *> *> *colors = [NSMutableArray array];
    BOOL multi = NO;
    CYLColorCountWalk(root, colors, &multi);
    if (multi) {
        return CYLTabBarItemAnimationColorKindMultiColor;
    }
    [colors sortUsingComparator:^NSComparisonResult(NSArray<NSNumber *> *a, NSArray<NSNumber *> *b) {
        for (NSUInteger i = 0; i < 3; i++) {
            NSComparisonResult result = [a[i] compare:b[i]];
            if (result != NSOrderedSame) {
                return result;
            }
        }
        return NSOrderedSame;
    }];
    NSMutableArray<NSArray<NSNumber *> *> *kept = [NSMutableArray array];
    for (NSArray<NSNumber *> *color in colors) {
        BOOL merged = NO;
        for (NSArray<NSNumber *> *existing in kept) {
            if (labs(existing[0].integerValue - color[0].integerValue) <= CYLColorCountTolerance
                && labs(existing[1].integerValue - color[1].integerValue) <= CYLColorCountTolerance
                && labs(existing[2].integerValue - color[2].integerValue) <= CYLColorCountTolerance) {
                merged = YES;
                break;
            }
        }
        if (!merged) {
            [kept addObject:color];
        }
    }
    if (kept.count == 0) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    return kept.count == 1 ? CYLTabBarItemAnimationColorKindOneColor : CYLTabBarItemAnimationColorKindMultiColor;
}

#pragma mark - GIF

static CYLTabBarItemAnimationColorKind CYLColorCountKindOfGIF(NSData *data) {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    if (!image) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    size_t width = CGImageGetWidth(image), height = CGImageGetHeight(image);
    if (width == 0 || height == 0 || width * height > 16u * 1024 * 1024) {
        CGImageRelease(image);
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    NSMutableData *pixels = [NSMutableData dataWithLength:width * height * 4];
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate(pixels.mutableBytes, width, height, 8, width * 4, space,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    if (!context) {
        CGImageRelease(image);
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
    CGImageRelease(image);
    NSUInteger buckets[4096] = { 0 };
    NSUInteger counted = 0;
    const uint8_t *bytes = pixels.bytes;
    for (size_t i = 0; i < width * height; i++) {
        uint8_t a = bytes[i * 4 + 3];
        if (a / 255.0 < 0.1) {
            continue;
        }
        unsigned r = MIN(255u, (unsigned)bytes[i * 4] * 255u / a);
        unsigned g = MIN(255u, (unsigned)bytes[i * 4 + 1] * 255u / a);
        unsigned b = MIN(255u, (unsigned)bytes[i * 4 + 2] * 255u / a);
        buckets[((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4)]++;
        counted++;
    }
    if (counted == 0) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    NSUInteger largest = 0;
    for (NSUInteger i = 0; i < 4096; i++) {
        largest = MAX(largest, buckets[i]);
    }
    return largest >= CYLColorCountGIFShare * counted ? CYLTabBarItemAnimationColorKindOneColor : CYLTabBarItemAnimationColorKindMultiColor;
}

#pragma mark - Entry points

CYLTabBarItemAnimationColorKind CYLTabBarItemAnimationColorKindOfData(NSData *data) {
    if (data.length < 4) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    const uint8_t *head = data.bytes;
    if (head[0] == 'G' && head[1] == 'I' && head[2] == 'F' && head[3] == '8') {
        return CYLColorCountKindOfGIF(data);
    }
    NSUInteger i = 0;
    while (i < data.length && (head[i] == ' ' || head[i] == '\n' || head[i] == '\r' || head[i] == '\t' || (i == 0 && head[0] == 0xEF))) {
        i++;
    }
    if (i < data.length && (head[i] == '{' || head[i] == 0xBB)) {
        return CYLColorCountKindOfLottie(data);
    }
    return CYLTabBarItemAnimationColorKindUndetectable;
}

CYLTabBarItemAnimationColorKind CYLTabBarItemAnimationColorKindOfURL(NSURL *url) {
    if (!url.isFileURL) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    NSString *path = url.path;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    unsigned long long size = [attributes fileSize];
    if (!attributes || size == 0 || size > CYLColorCountMaxFileBytes) {
        return CYLTabBarItemAnimationColorKindUndetectable;
    }
    NSString *key = [NSString stringWithFormat:@"%@|%llu|%f", path, size, [attributes.fileModificationDate timeIntervalSince1970]];
    static NSMutableDictionary<NSString *, NSNumber *> *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSMutableDictionary dictionary]; });
    @synchronized (cache) {
        NSNumber *cached = cache[key];
        if (cached) {
            return (CYLTabBarItemAnimationColorKind)cached.integerValue;
        }
    }
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    CYLTabBarItemAnimationColorKind kind = CYLTabBarItemAnimationColorKindOfData(data);
    @synchronized (cache) {
        cache[key] = @(kind);
    }
    return kind;
}
