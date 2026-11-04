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

/// [EN] URL (absolute string) -> identifier of the animator a tab's keys chose for it; under `@synchronized` on the class.
/// [CN] URL（absoluteString）-> Tab 的 key 为其选择的 animator 名称；在类对象上 `@synchronized` 读写。
static NSMutableDictionary<NSString *, NSString *> *CYLBoundTabBarItemAnimatorIdentifiers(void) {
    static NSMutableDictionary<NSString *, NSString *> *identifiers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        identifiers = [NSMutableDictionary dictionary];
    });
    return identifiers;
}

/// [EN] YES when `attributes` give a value for one of `animator`'s own keys. [CN] `attributes` 为 `animator` 自己的某个 key 提供了值时返回 YES。
static BOOL CYLTabBarItemAnimatorKeysHaveValue(id<CYLTabBarItemAnimator> animator, NSDictionary *attributes) {
    if (![animator respondsToSelector:@selector(attributeKeys)]) {
        return NO;
    }
    for (NSString *key in animator.attributeKeys.allValues) {
        if ([key isKindOfClass:[NSString class]] && key.length > 0 && attributes[key] != nil) {
            return YES;
        }
    }
    return NO;
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
    // [EN] First: the library a tab's keys chose for this URL, if it is still registered.
    // [CN] 首先：Tab 的 key 为该 URL 选择的动画库（仍已注册时）。
    NSString *boundIdentifier;
    @synchronized (self) {
        boundIdentifier = CYLBoundTabBarItemAnimatorIdentifiers()[URL.absoluteString];
    }
    id<CYLTabBarItemAnimator> boundAnimator = boundIdentifier ? [self animatorWithIdentifier:boundIdentifier] : nil;
    if (boundAnimator) {
        return boundAnimator;
    }
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if ([animator canAnimateFileAtURL:URL]) {
            return animator;
        }
    }
    return nil;
}

+ (id<CYLTabBarItemAnimator>)animatorForAttributes:(NSDictionary *)attributes {
    if (![attributes isKindOfClass:[NSDictionary class]] || attributes.count == 0) {
        return nil;
    }
    id<CYLTabBarItemAnimator> chosen = nil;
    for (id<CYLTabBarItemAnimator> animator in [self animators]) {
        if (!CYLTabBarItemAnimatorKeysHaveValue(animator, attributes)) {
            continue;
        }
        if (!chosen) {
            chosen = animator;
            continue;
        }
#if defined(DEBUG)
        NSLog(@"[CYLTabBarController] A tab item uses the keys of both %@ and %@; %@ is used.", chosen.identifier, animator.identifier, chosen.identifier);
#endif
        break;
    }
    return chosen;
}

+ (NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes {
    id<CYLTabBarItemAnimator> animator = [self animatorForAttributes:attributes];
    if (genericKey.length == 0 || ![animator respondsToSelector:@selector(attributeKeys)]) {
        return nil;
    }
    NSString *key = animator.attributeKeys[genericKey];
    return ([key isKindOfClass:[NSString class]] && key.length > 0) ? key : nil;
}

+ (void)bindURL:(NSURL *)URL toAnimator:(id<CYLTabBarItemAnimator>)animator {
    NSString *key = [URL isKindOfClass:[NSURL class]] ? URL.absoluteString : nil;
    if (key.length == 0) {
        return;
    }
    @synchronized (self) {
        CYLBoundTabBarItemAnimatorIdentifiers()[key] = animator.identifier.length > 0 ? animator.identifier : nil;
    }
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
