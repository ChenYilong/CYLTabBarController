//
//  CYLTabBarItemAnimatorRegistry.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemAnimatorRegistry.h"

/// [EN] The animators in registration order; read and written under `@synchronized` on the class.
/// [CN] 按注册顺序保存的 animator；在类对象上 `@synchronized` 读写。
static NSMutableArray<id<CYLTabBarItemAnimator>> *CYLRegisteredTabBarItemAnimators(void) {
    static NSMutableArray<id<CYLTabBarItemAnimator>> *animators;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animators = [NSMutableArray array];
    });
    return animators;
}

static CYLTabBarItemAnimatorPriority CYLTabBarItemAnimatorPriorityOf(id<CYLTabBarItemAnimator> animator) {
    return [animator respondsToSelector:@selector(priority)] ? animator.priority : CYLTabBarItemAnimatorPriorityDefault;
}

@implementation CYLTabBarItemAnimatorRegistry

+ (void)registerAnimator:(id<CYLTabBarItemAnimator>)animator {
    if (![animator conformsToProtocol:@protocol(CYLTabBarItemAnimator)] || animator.identifier.length == 0) {
        return;
    }
    @synchronized (self) {
        NSMutableArray<id<CYLTabBarItemAnimator>> *animators = CYLRegisteredTabBarItemAnimators();
        NSUInteger index = [animators indexOfObjectPassingTest:^BOOL(id<CYLTabBarItemAnimator> obj, NSUInteger idx, BOOL *stop) {
            return [obj.identifier isEqualToString:animator.identifier];
        }];
        if (index == NSNotFound) {
            [animators addObject:animator];
        } else {
            [animators replaceObjectAtIndex:index withObject:animator];
        }
    }
}

+ (void)unregisterAnimatorWithIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return;
    }
    @synchronized (self) {
        NSMutableArray<id<CYLTabBarItemAnimator>> *animators = CYLRegisteredTabBarItemAnimators();
        NSIndexSet *indexes = [animators indexesOfObjectsPassingTest:^BOOL(id<CYLTabBarItemAnimator> obj, NSUInteger idx, BOOL *stop) {
            return [obj.identifier isEqualToString:identifier];
        }];
        [animators removeObjectsAtIndexes:indexes];
    }
}

+ (NSArray<id<CYLTabBarItemAnimator>> *)animators {
    NSArray<id<CYLTabBarItemAnimator>> *animators;
    @synchronized (self) {
        animators = [CYLRegisteredTabBarItemAnimators() copy];
    }
    // A stable sort: equal priorities keep their registration order. 稳定排序：相同优先级保持注册顺序。
    return [animators sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id<CYLTabBarItemAnimator> a, id<CYLTabBarItemAnimator> b) {
        CYLTabBarItemAnimatorPriority priorityA = CYLTabBarItemAnimatorPriorityOf(a);
        CYLTabBarItemAnimatorPriority priorityB = CYLTabBarItemAnimatorPriorityOf(b);
        if (priorityA == priorityB) {
            return NSOrderedSame;
        }
        return priorityA > priorityB ? NSOrderedAscending : NSOrderedDescending;
    }];
}

+ (id<CYLTabBarItemAnimator>)animatorWithIdentifier:(NSString *)identifier {
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if ([animator.identifier isEqualToString:identifier]) {
            return animator;
        }
    }
    return nil;
}

+ (id<CYLTabBarItemAnimator>)animatorForURL:(NSURL *)URL {
    if (!URL) {
        return nil;
    }
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if ([animator canAnimateFileAtURL:URL]) {
            return animator;
        }
    }
    return nil;
}

+ (NSArray<NSString *> *)attributeKeysForGenericKey:(NSString *)genericKey {
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if (![animator respondsToSelector:@selector(attributeKeys)]) {
            continue;
        }
        NSString *key = animator.attributeKeys[genericKey];
        if ([key isKindOfClass:[NSString class]] && key.length > 0 && ![keys containsObject:key]) {
            [keys addObject:key];
        }
    }
    return [keys copy];
}

+ (NSArray<NSString *> *)fileExtensions {
    NSMutableArray<NSString *> *extensions = [NSMutableArray array];
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if (![animator respondsToSelector:@selector(fileExtensions)]) {
            continue;
        }
        for (NSString *extension in animator.fileExtensions) {
            NSString *lowercaseExtension = [extension isKindOfClass:[NSString class]] ? extension.lowercaseString : nil;
            if (lowercaseExtension.length > 0 && ![extensions containsObject:lowercaseExtension]) {
                [extensions addObject:lowercaseExtension];
            }
        }
    }
    return [extensions copy];
}

@end
