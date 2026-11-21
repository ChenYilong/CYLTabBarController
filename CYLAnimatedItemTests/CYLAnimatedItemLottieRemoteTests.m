/*
 * [EN] Tests of the CYLAnimatedItem pod that need an animation library linked, run by `pod lib lint CYLAnimatedItem.podspec`
 *      (test spec `Tests`, with `CYLAnimatedItem/LottieObjectiveC`). They depend on the component only, never on
 *      CYLTabBarController. No network: CYLLottieStubURLProtocol serves the remote files.
 * [CN] 需要链接动画库的 CYLAnimatedItem pod 测试，由 `pod lib lint CYLAnimatedItem.podspec` 运行（test spec `Tests`，依赖
 *      `CYLAnimatedItem/LottieObjectiveC`）。只依赖组件本身，不依赖 CYLTabBarController。无需网络：远程文件由 CYLLottieStubURLProtocol 提供。
 */
#import <XCTest/XCTest.h>
#import <CYLAnimatedItem/CYLAnimatedItemView.h>
#import <CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>

@interface CYLLottieStubURLProtocol : NSURLProtocol
@end

@implementation CYLLottieStubURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.host isEqualToString:@"cyl-lottie.test"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSString *path = self.request.URL.path;
    NSString *body = [path isEqualToString:@"/home.json"]
        ? @"{\"v\": \"5.7.4\", \"fr\": 30, \"ip\": 0, \"op\": 30, \"w\": 24, \"h\": 24, \"layers\": []}"
        : ([path isEqualToString:@"/broken.json"] ? @"{\"v\": " : @"not found");
    NSInteger status = ([path isEqualToString:@"/home.json"] || [path isEqualToString:@"/broken.json"]) ? 200 : 404;
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:nil];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end

@interface CYLAnimatedItemLottieRemoteTests : XCTestCase
@end

@implementation CYLAnimatedItemLottieRemoteTests

- (UIImage *)icon {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(24, 24)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor redColor] setFill];
        [context fillRect:CGRectMake(0, 0, 24, 24)];
    }];
}

- (void)testARemoteLottieFileIsDownloadedThenPlaysOrFallsBack {
    // [EN] The test spec depends on CYLAnimatedItem/LottieObjectiveC; the check only guards against a changed podspec.
    // [CN] test spec 依赖 CYLAnimatedItem/LottieObjectiveC；此检查只防止 podspec 被修改。
    if (!NSClassFromString(@"LOTAnimationView") && !NSClassFromString(@"CYLCompatibleLOTAnimationView")
        && !NSClassFromString(@"CYLAnimatedItem.CYLCompatibleLOTAnimationView")
        && !NSClassFromString(@"CYLTabBarController.CYLCompatibleLOTAnimationView")) {
        XCTSkip(@"Lottie is not linked");
    }
    [NSURLProtocol registerClass:[CYLLottieStubURLProtocol class]];
    UIImage *image = [self icon];
    CYLAnimatedItemView * (^item)(NSString *) = ^CYLAnimatedItemView *(NSString *path) {
        CYLAnimatedItemView *view = [[CYLAnimatedItemView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        view.image = image;
        view.animationURL = [NSURL URLWithString:[@"https://cyl-lottie.test" stringByAppendingString:path]];
        return view;
    };
    BOOL (^wait)(BOOL (^)(void)) = ^BOOL(BOOL (^done)(void)) {
        NSDate *limit = [NSDate dateWithTimeIntervalSinceNow:5];
        while (!done() && [limit timeIntervalSinceNow] > 0) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        }
        return done();
    };

    CYLAnimatedItemView *loaded = item(@"/home.json");
    XCTAssertNotNil(loaded.animationView, @"the Lottie animator makes a view for a remote file");
    XCTAssertTrue(CYLTabBarItemAnimationIsLoading(loaded.animationView), @"marked as loading until downloaded");
    XCTAssertEqual(loaded.imageView.image, image);
    XCTAssertFalse(loaded.imageView.hidden, @"downloading: the static image");
    XCTAssertTrue(wait(^BOOL { return loaded.imageView.hidden; }), @"downloaded: the animation replaces the image");
    XCTAssertTrue(loaded.isAnimationReady);

    for (NSString *path in @[ @"/missing.json", @"/broken.json" ]) {
        CYLAnimatedItemView *failed = item(path);
        XCTAssertTrue(wait(^BOOL { return !failed.isAnimationReady; }), @"%@: the failure is reported", path);
        XCTAssertEqual(failed.imageView.image, image, @"%@: the static image again", path);
        XCTAssertFalse(failed.imageView.hidden, @"%@", path);
    }
    [NSURLProtocol unregisterClass:[CYLLottieStubURLProtocol class]];
}

@end
