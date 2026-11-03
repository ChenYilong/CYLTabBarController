//
//  CYLUtils.m
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLUtils.h"

@implementation CYLUtils

+ (BOOL)isLiquidGlassActive {
    static BOOL result = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 27.0, *)) {
            result = YES;
        } else if (@available(iOS 26.0, *)) {
            result = ![[NSBundle.mainBundle objectForInfoDictionaryKey:@"UIDesignRequiresCompatibility"] boolValue];
        } else {
            result = NO;
        }
    });
    return result;
}

@end
