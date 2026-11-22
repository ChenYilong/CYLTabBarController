//
//  CYLSelectorDumpTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] Regression guard for renames (docs/Swift-Coding-Style.md, "Sonar naming rename"): lists the Objective-C runtime
//       selectors of every CYL class, of every class with `cyl…` / `swizzling_…` methods (categories on UIKit and
//       NSObject) and of every CYL protocol, sorted, one `class|+/-|selector` per line. Writes the list only when
//       the environment variable CYL_SELECTOR_DUMP_PATH is set (xcodebuild: TEST_RUNNER_CYL_SELECTOR_DUMP_PATH);
//       compare the file before and after a rename: it must be identical.
//  [CN] 重命名的回归保护（docs/Swift-Coding-Style.md，“Sonar naming rename”）：列出每个 CYL 类、每个带有 `cyl…` /
//       `swizzling_…` 方法的类（UIKit 与 NSObject 的分类）以及每个 CYL 协议的 Objective-C 运行时选择器，排序后每行一个
//       `类|+/-|选择器`。仅在设置了环境变量 CYL_SELECTOR_DUMP_PATH 时写文件（xcodebuild：TEST_RUNNER_CYL_SELECTOR_DUMP_PATH）；
//       重命名前后比较该文件，必须完全一致。
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
#import <objc/runtime.h>

@interface CYLSelectorDumpTests : XCTestCase
@end

@implementation CYLSelectorDumpTests

static void CYLSelectorDumpCollect(Class cls, const char *className, BOOL plus, BOOL all, NSMutableSet<NSString *> *lines) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    for (unsigned int index = 0; index < count; index++) {
        const char *selector = sel_getName(method_getName(methods[index]));
        if (all || strncmp(selector, "cyl", 3) == 0 || strncmp(selector, "swizzling_", 10) == 0) {
            [lines addObject:[NSString stringWithFormat:@"%s|%@|%s", className, plus ? @"+" : @"-", selector]];
        }
    }
    free(methods);
}

- (void)testDumpsRuntimeSelectors {
    const char *path = getenv("CYL_SELECTOR_DUMP_PATH");
    if (path == NULL || path[0] == '\0') {
        XCTSkip(@"CYL_SELECTOR_DUMP_PATH is not set");
        return;
    }
    NSMutableSet<NSString *> *lines = [NSMutableSet set];
    unsigned int classCount = 0;
    Class *classes = objc_copyClassList(&classCount);
    for (unsigned int index = 0; index < classCount; index++) {
        Class cls = classes[index];
        const char *name = class_getName(cls);
        if (strcmp(name, class_getName(self.class)) == 0 || strncmp(name, "NSKVONotifying_", 15) == 0 ||
            strncmp(name, "_NSZombie_", 10) == 0 || strncmp(name, "__NS", 4) == 0) {
            continue;
        }
        BOOL isCYLClass = strstr(name, "CYL") != NULL;
        CYLSelectorDumpCollect(cls, name, NO, isCYLClass, lines);
        CYLSelectorDumpCollect(object_getClass(cls), name, YES, isCYLClass, lines);
        if (isCYLClass) {
            unsigned int protocolCount = 0;
            Protocol *__unsafe_unretained *adopted = class_copyProtocolList(cls, &protocolCount);
            for (unsigned int protocolIndex = 0; protocolIndex < protocolCount; protocolIndex++) {
                [lines addObject:[NSString stringWithFormat:@"%s|conforms|%s", name, protocol_getName(adopted[protocolIndex])]];
            }
            free(adopted);
        }
    }
    free(classes);
    unsigned int protocolTotal = 0;
    Protocol *__unsafe_unretained *protocols = objc_copyProtocolList(&protocolTotal);
    for (unsigned int index = 0; index < protocolTotal; index++) {
        const char *name = protocol_getName(protocols[index]);
        if (strstr(name, "CYL") == NULL) {
            continue;
        }
        for (int required = 1; required >= 0; required--) {
            for (int instance = 1; instance >= 0; instance--) {
                unsigned int count = 0;
                struct objc_method_description *descriptions = protocol_copyMethodDescriptionList(protocols[index], required, instance, &count);
                for (unsigned int descriptionIndex = 0; descriptionIndex < count; descriptionIndex++) {
                    [lines addObject:[NSString stringWithFormat:@"@protocol %s|%@|%s|%@", name, instance ? @"-" : @"+",
                                      sel_getName(descriptions[descriptionIndex].name), required ? @"required" : @"optional"]];
                }
                free(descriptions);
            }
        }
    }
    free(protocols);
    NSArray<NSString *> *sorted = [lines.allObjects sortedArrayUsingSelector:@selector(compare:)];
    NSString *text = [[sorted componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
    NSError *error = nil;
    XCTAssertTrue([text writeToFile:[NSString stringWithUTF8String:path] atomically:YES encoding:NSUTF8StringEncoding error:&error], @"%@", error);
    XCTAssertGreaterThan(sorted.count, 0u);
}

@end
