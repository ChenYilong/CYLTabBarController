---
title: XCTest
source: https://developer.apple.com/documentation/xctest
source_kind: apple-docc
source_json: https://developer.apple.com/tutorials/data/index/xctest
timestamp: 2026-04-14T13:14:57.179Z
---

**Navigation:** [XCTest](/documentation/xctest)

## Test cases and test methods

- [Defining Test Cases and Test Methods](/documentation/xctest/defining-test-cases-and-test-methods)
- [XCTestCase](/documentation/xctest/xctestcase)
### Customizing Test Setup and Teardown

- [Set Up and Tear Down State in Your Tests](/documentation/xctest/set-up-and-tear-down-state-in-your-tests)
- [class func setUp()](/documentation/xctest/xctestcase/setup())
- [func addTeardownBlock(() async throws -> Void)](/documentation/xctest/xctestcase/addteardownblock(_:)-2guon)
- [func addTeardownBlock(() throws -> Void)](/documentation/xctest/xctestcase/addteardownblock(_:)-5zw6c)
- [class func tearDown()](/documentation/xctest/xctestcase/teardown())
### Managing Test Case Execution

- [class var runsForEachTargetApplicationUIConfiguration: Bool](/documentation/xctest/xctestcase/runsforeachtargetapplicationuiconfiguration)
- [var continueAfterFailure: Bool](/documentation/xctest/xctestcase/continueafterfailure)
- [var executionTimeAllowance: TimeInterval](/documentation/xctest/xctestcase/executiontimeallowance)
### Measuring Performance

- [func measure(() -> Void)](/documentation/xctest/xctestcase/measure(_:))
- [func measureMetrics([XCTPerformanceMetric], automaticallyStartMeasuring: Bool, for: () -> Void)](/documentation/xctest/xctestcase/measuremetrics(_:automaticallystartmeasuring:for:))
- [func measure(metrics: [any XCTMetric], block: () -> Void)](/documentation/xctest/xctestcase/measure(metrics:block:))
- [func measure(metrics: [any XCTMetric], options: XCTMeasureOptions, block: () -> Void)](/documentation/xctest/xctestcase/measure(metrics:options:block:))
- [func measure(options: XCTMeasureOptions, block: () -> Void)](/documentation/xctest/xctestcase/measure(options:block:))
- [func startMeasuring()](/documentation/xctest/xctestcase/startmeasuring())
- [func stopMeasuring()](/documentation/xctest/xctestcase/stopmeasuring())
- [class var defaultPerformanceMetrics: [XCTPerformanceMetric]](/documentation/xctest/xctestcase/defaultperformancemetrics)
- [class var defaultMetrics: [any XCTMetric]](/documentation/xctest/xctestcase/defaultmetrics)
- [class var defaultMeasureOptions: XCTMeasureOptions](/documentation/xctest/xctestcase/defaultmeasureoptions)
- [XCTPerformanceMetric](/documentation/xctest/xctperformancemetric)
#### Measuring Elapsed Time

- [static let wallClockTime: XCTPerformanceMetric](/documentation/xctest/xctperformancemetric/wallclocktime)
#### Initializing an Item

- [init(String)](/documentation/xctest/xctperformancemetric/init(_:))
- [init(rawValue: String)](/documentation/xctest/xctperformancemetric/init(rawvalue:))

### Creating Asynchronous Test Expectations

- [func expectation(description: String) -> XCTestExpectation](/documentation/xctest/xctestcase/expectation(description:))
- [func expectation(for: NSPredicate, evaluatedWith: Any?, handler: XCTNSPredicateExpectation.Handler?) -> XCTestExpectation](/documentation/xctest/xctestcase/expectation(for:evaluatedwith:handler:))
- [func expectation(forNotification: NSNotification.Name, object: Any?, handler: XCTNSNotificationExpectation.Handler?) -> XCTestExpectation](/documentation/xctest/xctestcase/expectation(fornotification:object:handler:))
- [func expectation(forNotification: NSNotification.Name, object: Any?, notificationCenter: NotificationCenter, handler: XCTNSNotificationExpectation.Handler?) -> XCTestExpectation](/documentation/xctest/xctestcase/expectation(fornotification:object:notificationcenter:handler:))
- [func keyValueObservingExpectation(for: Any, keyPath: String, expectedValue: Any?) -> XCTestExpectation](/documentation/xctest/xctestcase/keyvalueobservingexpectation(for:keypath:expectedvalue:))
- [func expectation<T, V>(that: KeyPath<T, V>, on: T, options: NSKeyValueObservingOptions, willEqual: V) -> XCTKeyPathExpectation<T, V>](/documentation/xctest/xctestcase/expectation(that:on:options:willequal:))
- [func keyValueObservingExpectation(for: Any, keyPath: String, handler: XCTKVOExpectation.Handler?) -> XCTestExpectation](/documentation/xctest/xctestcase/keyvalueobservingexpectation(for:keypath:handler:))
- [func expectation<T, V>(that: KeyPath<T, V>, on: T, options: NSKeyValueObservingOptions, willSatisfy: XCTKeyPathExpectation<T, V>.Predicate?) -> XCTKeyPathExpectation<T, V>](/documentation/xctest/xctestcase/expectation(that:on:options:willsatisfy:)-6itb)
- [func expectation<T, V>(that: KeyPath<T, V>, on: T, options: NSKeyValueObservingOptions, willSatisfy: XCTKeyPathExpectation<T, V>.AsynchronousFilter?) -> XCTKeyPathExpectation<T, V>](/documentation/xctest/xctestcase/expectation(that:on:options:willsatisfy:)-292oj)
- [func expectation<T, V>(that: KeyPath<T, V>, on: T, options: NSKeyValueObservingOptions, willSatisfy: XCTKeyPathExpectation<T, V>.SynchronousFilter?) -> XCTKeyPathExpectation<T, V>](/documentation/xctest/xctestcase/expectation(that:on:options:willsatisfy:)-85or0)
### Waiting for Expectations

- [func fulfillment(of: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool) async](/documentation/xctest/xctestcase/fulfillment(of:timeout:enforceorder:))
- [func wait(for: [XCTestExpectation])](/documentation/xctest/xctestcase/wait(for:))
- [func wait(for: [XCTestExpectation], enforceOrder: Bool)](/documentation/xctest/xctestcase/wait(for:enforceorder:))
- [func wait(for: [XCTestExpectation], timeout: TimeInterval)](/documentation/xctest/xctestcase/wait(for:timeout:))
- [func wait(for: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool)](/documentation/xctest/xctestcase/wait(for:timeout:enforceorder:))
- [func waitForExpectations(timeout: TimeInterval, handler: (((any Error)?) -> Void)?)](/documentation/xctest/xctestcase/waitforexpectations(timeout:handler:))
- [XCWaitCompletionHandler](/documentation/xctest/xcwaitcompletionhandler)
- [XCTestError](/documentation/xctest/xctesterror)
#### Classifying Errors with Codes

- [static var timeoutWhileWaiting: XCTestError.Code](/documentation/xctest/xctesterror/timeoutwhilewaiting)
- [static var failureWhileWaiting: XCTestError.Code](/documentation/xctest/xctesterror/failurewhilewaiting)
- [XCTestError.Code](/documentation/xctest/xctesterror/code)
##### Error Codes

- [case timeoutWhileWaiting](/documentation/xctest/xctesterror/code/timeoutwhilewaiting)
- [case failureWhileWaiting](/documentation/xctest/xctesterror/code/failurewhilewaiting)
##### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctesterror/code/init(rawvalue:))

#### Classifying Errors by Domain

- [let XCTestErrorDomain: String](/documentation/xctest/xctesterrordomain)
#### Type Properties

- [static var errorDomain: String](/documentation/xctest/xctesterror/errordomain)

- [XCTestError.Code](/documentation/xctest/xctesterror/code)
#### Error Codes

- [case timeoutWhileWaiting](/documentation/xctest/xctesterror/code/timeoutwhilewaiting)
- [case failureWhileWaiting](/documentation/xctest/xctesterror/code/failurewhilewaiting)
#### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctesterror/code/init(rawvalue:))

- [let XCTestErrorDomain: String](/documentation/xctest/xctesterrordomain)
### Monitoring UI Interruptions

- [Handling UI Interruptions](/documentation/xctest/handling-ui-interruptions)
- [func addUIInterruptionMonitor(withDescription: String, handler: (XCUIElement) -> Bool) -> any NSObjectProtocol](/documentation/xctest/xctestcase/adduiinterruptionmonitor(withdescription:handler:))
- [func removeUIInterruptionMonitor(any NSObjectProtocol)](/documentation/xctest/xctestcase/removeuiinterruptionmonitor(_:))
### Creating Tests Programmatically

- [init(invocation: NSInvocation?)](/documentation/xctest/xctestcase/init(invocation:))
- [init(selector: Selector)](/documentation/xctest/xctestcase/init(selector:))
- [class var testInvocations: [NSInvocation]](/documentation/xctest/xctestcase/testinvocations)
- [var invocation: NSInvocation?](/documentation/xctest/xctestcase/invocation)
- [func invokeTest()](/documentation/xctest/xctestcase/invoketest())
- [func record(XCTIssue)](/documentation/xctest/xctestcase/record(_:))
- [func recordFailure(withDescription: String, inFile: String, atLine: Int, expected: Bool)](/documentation/xctest/xctestcase/recordfailure(withdescription:infile:atline:expected:))
- [class var defaultTestSuite: XCTestSuite](/documentation/xctest/xctestcase/defaulttestsuite)

- [XCTest](/documentation/xctest/xctest)
### Examining Test Properties

- [var name: String](/documentation/xctest/xctest/name)
- [var testCaseCount: Int](/documentation/xctest/xctest/testcasecount)
- [var testRun: XCTestRun?](/documentation/xctest/xctest/testrun)
- [var testRunClass: AnyClass?](/documentation/xctest/xctest/testrunclass)
### Setting Up and Tearing Down

- [func setUp(completion: ((any Error)?) -> Void)](/documentation/xctest/xctest/setup(completion:))
- [func setUpWithError() throws](/documentation/xctest/xctest/setupwitherror())
- [func setUp()](/documentation/xctest/xctest/setup())
- [func tearDown(completion: ((any Error)?) -> Void)](/documentation/xctest/xctest/teardown(completion:))
- [func tearDownWithError() throws](/documentation/xctest/xctest/teardownwitherror())
- [func tearDown()](/documentation/xctest/xctest/teardown())
### Running Tests

- [func perform(XCTestRun)](/documentation/xctest/xctest/perform(_:))
- [func run()](/documentation/xctest/xctest/run())

## Test assertions

- [Boolean Assertions](/documentation/xctest/boolean-assertions)
### Tests for True Conditions

- [func XCTAssert(@autoclosure () throws -> Bool, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassert(_:_:file:line:))
- [func XCTAssertTrue(@autoclosure () throws -> Bool, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctasserttrue(_:_:file:line:))
### Tests for False Conditions

- [func XCTAssertFalse(@autoclosure () throws -> Bool, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertfalse(_:_:file:line:))

- [Nil and Non-Nil Assertions](/documentation/xctest/nil-and-non-nil-assertions)
### Tests for a Nil Condition

- [func XCTAssertNil(@autoclosure () throws -> Any?, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnil(_:_:file:line:))
### Tests for a Non-Nil Condition

- [func XCTAssertNotNil(@autoclosure () throws -> Any?, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnotnil(_:_:file:line:))
- [func XCTUnwrap<T>(@autoclosure () throws -> T?, @autoclosure () -> String, file: StaticString, line: UInt) throws -> T](/documentation/xctest/xctunwrap(_:_:file:line:))

- [Equality and Inequality Assertions](/documentation/xctest/equality-and-inequality-assertions)
### Tests for Equality and Inequality

- [func XCTAssertEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertequal(_:_:_:file:line:))
- [func XCTAssertNotEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnotequal(_:_:_:file:line:))
### Tests for Identical Objects

- [func XCTAssertIdentical(@autoclosure () throws -> AnyObject?, @autoclosure () throws -> AnyObject?, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertidentical(_:_:_:file:line:))
- [func XCTAssertNotIdentical(@autoclosure () throws -> AnyObject?, @autoclosure () throws -> AnyObject?, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnotidentical(_:_:_:file:line:))
### Tests for Equality Within a Specified Accuracy

- [func XCTAssertEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, accuracy: T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertequal(_:_:accuracy:_:file:line:)-6frfw)
- [func XCTAssertEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, accuracy: T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertequal(_:_:accuracy:_:file:line:)-4epu5)
- [func XCTAssertNotEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, accuracy: T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnotequal(_:_:accuracy:_:file:line:)-7jcd6)
- [func XCTAssertNotEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, accuracy: T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnotequal(_:_:accuracy:_:file:line:)-326vc)

- [Comparable Value Assertions](/documentation/xctest/comparable-value-assertions)
### Tests for Comparable Values

- [func XCTAssertGreaterThan<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertgreaterthan(_:_:_:file:line:))
- [func XCTAssertGreaterThanOrEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertgreaterthanorequal(_:_:_:file:line:))
- [func XCTAssertLessThanOrEqual<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertlessthanorequal(_:_:_:file:line:))
- [func XCTAssertLessThan<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertlessthan(_:_:_:file:line:))

- [Error Assertions](/documentation/xctest/error-assertions)
### Tests for Errors

- [func XCTAssertThrowsError<T>(@autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt, (any Error) -> Void)](/documentation/xctest/xctassertthrowserror(_:_:file:line:_:))

- [NSException Assertions](/documentation/xctest/nsexception-assertions)
- [Unconditional Test Failures](/documentation/xctest/unconditional-test-failures)
### Unconditional Test Failures

- [func XCTFail(String, file: StaticString, line: UInt)](/documentation/xctest/xctfail(_:file:line:))

- [Expected Failures](/documentation/xctest/expected-failures)
### Expected Failures

- [XCTExpectedFailure](/documentation/xctest/xctexpectedfailure)
#### Detailing Expected Failure

- [var failureReason: String?](/documentation/xctest/xctexpectedfailure/failurereason)
- [var issue: XCTIssue](/documentation/xctest/xctexpectedfailure/issue)
#### Setting Options

- [XCTExpectedFailure.Options](/documentation/xctest/xctexpectedfailure/options)
##### Matching Failures

- [var issueMatcher: (XCTIssue) -> Bool](/documentation/xctest/xctexpectedfailure/options/issuematcher)
##### Specifying Options

- [class func nonStrict() -> XCTExpectedFailure.Options](/documentation/xctest/xctexpectedfailure/options/nonstrict())
- [var isEnabled: Bool](/documentation/xctest/xctexpectedfailure/options/isenabled)
- [var isStrict: Bool](/documentation/xctest/xctexpectedfailure/options/isstrict)


- [XCTExpectedFailure.Options](/documentation/xctest/xctexpectedfailure/options)
#### Matching Failures

- [var issueMatcher: (XCTIssue) -> Bool](/documentation/xctest/xctexpectedfailure/options/issuematcher)
#### Specifying Options

- [class func nonStrict() -> XCTExpectedFailure.Options](/documentation/xctest/xctexpectedfailure/options/nonstrict())
- [var isEnabled: Bool](/documentation/xctest/xctexpectedfailure/options/isenabled)
- [var isStrict: Bool](/documentation/xctest/xctexpectedfailure/options/isstrict)

- [func XCTExpectFailure(String?, options: XCTExpectedFailure.Options)](/documentation/xctest/xctexpectfailure(_:options:))
- [func XCTExpectFailure(String?, enabled: Bool?, strict: Bool?, issueMatcher: ((XCTIssue) -> Bool)?)](/documentation/xctest/xctexpectfailure(_:enabled:strict:issuematcher:))
- [func XCTExpectFailure<R>(String?, options: XCTExpectedFailure.Options, failingBlock: () throws -> R) rethrows -> R](/documentation/xctest/xctexpectfailure(_:options:failingblock:))
- [func XCTExpectFailure<R>(String?, enabled: Bool?, strict: Bool?, failingBlock: () throws -> R, issueMatcher: ((XCTIssue) -> Bool)?) rethrows -> R](/documentation/xctest/xctexpectfailure(_:enabled:strict:failingblock:issuematcher:))

- [Methods for Skipping Tests](/documentation/xctest/methods-for-skipping-tests)
### Methods for Skipping Tests

- [func XCTSkipIf(@autoclosure () throws -> Bool, @autoclosure () -> String?, file: StaticString, line: UInt) throws](/documentation/xctest/xctskipif(_:_:file:line:))
- [func XCTSkipUnless(@autoclosure () throws -> Bool, @autoclosure () -> String?, file: StaticString, line: UInt) throws](/documentation/xctest/xctskipunless(_:_:file:line:))
- [XCTSkip](/documentation/xctest/xctskip-swift.struct)
#### Skipping a Test

- [init(String?, file: StaticString, line: UInt)](/documentation/xctest/xctskip-swift.struct/init(_:file:line:))
#### Describing a Skipped Test

- [var message: String?](/documentation/xctest/xctskip-swift.struct/message)


## Asynchronous tests

- [Asynchronous Tests and Expectations](/documentation/xctest/asynchronous-tests-and-expectations)
### Expectations

- [XCTestExpectation](/documentation/xctest/xctestexpectation)
#### Creating Expectations

- [init(description: String)](/documentation/xctest/xctestexpectation/init(description:))
- [var expectationDescription: String](/documentation/xctest/xctestexpectation/expectationdescription)
#### Fulfilling Expectations

- [func fulfill()](/documentation/xctest/xctestexpectation/fulfill())
#### Fulfillment Count

- [var expectedFulfillmentCount: Int](/documentation/xctest/xctestexpectation/expectedfulfillmentcount)
- [var assertForOverFulfill: Bool](/documentation/xctest/xctestexpectation/assertforoverfulfill)
#### Unintended Expectations

- [var isInverted: Bool](/documentation/xctest/xctestexpectation/isinverted)

### Key Value Observing Expectations

- [XCTKVOExpectation](/documentation/xctest/xctkvoexpectation)
#### Creating KVO expectations

- [convenience init(keyPath: String, object: Any)](/documentation/xctest/xctkvoexpectation/init(keypath:object:))
- [convenience init(keyPath: String, object: Any, expectedValue: Any?)](/documentation/xctest/xctkvoexpectation/init(keypath:object:expectedvalue:))
- [init(keyPath: String, object: Any, expectedValue: Any?, options: NSKeyValueObservingOptions)](/documentation/xctest/xctkvoexpectation/init(keypath:object:expectedvalue:options:))
#### Expectation properties

- [var keyPath: String](/documentation/xctest/xctkvoexpectation/keypath)
- [var observedObject: Any](/documentation/xctest/xctkvoexpectation/observedobject)
- [var expectedValue: Any?](/documentation/xctest/xctkvoexpectation/expectedvalue)
- [var options: NSKeyValueObservingOptions](/documentation/xctest/xctkvoexpectation/options)
#### Custom KVO evaluation

- [var handler: XCTKVOExpectation.Handler?](/documentation/xctest/xctkvoexpectation/handler-swift.property)
- [XCTKVOExpectation.Handler](/documentation/xctest/xctkvoexpectation/handler-swift.typealias)

- [XCTKeyPathExpectation](/documentation/xctest/xctkeypathexpectation)
#### Creating key path expectations

- [convenience init(keyPath: KeyPath<T, V>, observedObject: T, options: NSKeyValueObservingOptions, expectedValue: V)](/documentation/xctest/xctkeypathexpectation/init(keypath:observedobject:options:expectedvalue:))
- [convenience init(keyPath: KeyPath<T, V>, observedObject: T, options: NSKeyValueObservingOptions, predicate: XCTKeyPathExpectation<T, V>.Predicate?)](/documentation/xctest/xctkeypathexpectation/init(keypath:observedobject:options:predicate:))
- [convenience init(keyPath: KeyPath<T, V>, observedObject: T, options: NSKeyValueObservingOptions, filter: XCTKeyPathExpectation<T, V>.SynchronousFilter?)](/documentation/xctest/xctkeypathexpectation/init(keypath:observedobject:options:filter:)-plka)
- [convenience init(keyPath: KeyPath<T, V>, observedObject: T, options: NSKeyValueObservingOptions, filter: XCTKeyPathExpectation<T, V>.AsynchronousFilter?)](/documentation/xctest/xctkeypathexpectation/init(keypath:observedobject:options:filter:)-8noag)
- [XCTKeyPathExpectation.AsynchronousFilter](/documentation/xctest/xctkeypathexpectation/asynchronousfilter)
- [XCTKeyPathExpectation.SynchronousFilter](/documentation/xctest/xctkeypathexpectation/synchronousfilter)
- [XCTKeyPathExpectation.Predicate](/documentation/xctest/xctkeypathexpectation/predicate)
#### Expectation properties

- [let keyPath: KeyPath<T, V>](/documentation/xctest/xctkeypathexpectation/keypath)
- [let observedObject: T](/documentation/xctest/xctkeypathexpectation/observedobject)
- [let options: NSKeyValueObservingOptions](/documentation/xctest/xctkeypathexpectation/options)
- [var expectedValue: V?](/documentation/xctest/xctkeypathexpectation/expectedvalue)

### Notification-Based Expectations

- [XCTNSNotificationExpectation](/documentation/xctest/xctnsnotificationexpectation)
#### Creating NSNotification Expectations

- [convenience init(name: NSNotification.Name)](/documentation/xctest/xctnsnotificationexpectation/init(name:))
- [convenience init(name: NSNotification.Name, object: Any?)](/documentation/xctest/xctnsnotificationexpectation/init(name:object:))
- [init(name: NSNotification.Name, object: Any?, notificationCenter: NotificationCenter)](/documentation/xctest/xctnsnotificationexpectation/init(name:object:notificationcenter:))
#### Expectation Properties

- [var notificationName: NSNotification.Name](/documentation/xctest/xctnsnotificationexpectation/notificationname)
- [var observedObject: Any?](/documentation/xctest/xctnsnotificationexpectation/observedobject)
- [var notificationCenter: NotificationCenter](/documentation/xctest/xctnsnotificationexpectation/notificationcenter)
#### Custom Notification Evaluation

- [var handler: XCTNSNotificationExpectation.Handler?](/documentation/xctest/xctnsnotificationexpectation/handler-swift.property)
- [XCTNSNotificationExpectation.Handler](/documentation/xctest/xctnsnotificationexpectation/handler-swift.typealias)

- [XCTDarwinNotificationExpectation](/documentation/xctest/xctdarwinnotificationexpectation)
#### Creating Darwin Notification Expectations

- [init(notificationName: String)](/documentation/xctest/xctdarwinnotificationexpectation/init(notificationname:))
#### Expectation Properties

- [var notificationName: String](/documentation/xctest/xctdarwinnotificationexpectation/notificationname)
#### Custom Notification Evaluation

- [var handler: XCTDarwinNotificationExpectation.Handler?](/documentation/xctest/xctdarwinnotificationexpectation/handler-swift.property)
- [XCTDarwinNotificationExpectation.Handler](/documentation/xctest/xctdarwinnotificationexpectation/handler-swift.typealias)

### Predicate-Based Expectations

- [XCTNSPredicateExpectation](/documentation/xctest/xctnspredicateexpectation)
#### Creating a Predicate-Based Expectation

- [init(predicate: NSPredicate, object: Any?)](/documentation/xctest/xctnspredicateexpectation/init(predicate:object:))
#### Expectation Properties

- [var predicate: NSPredicate](/documentation/xctest/xctnspredicateexpectation/predicate)
- [var object: Any?](/documentation/xctest/xctnspredicateexpectation/object)
#### Handling Predicate Resolution

- [var handler: XCTNSPredicateExpectation.Handler?](/documentation/xctest/xctnspredicateexpectation/handler-swift.property)
- [XCTNSPredicateExpectation.Handler](/documentation/xctest/xctnspredicateexpectation/handler-swift.typealias)

### Expectation Waiters

- [XCTWaiter](/documentation/xctest/xctwaiter)
#### Creating a Waiter

- [init(delegate: (any XCTWaiterDelegate)?)](/documentation/xctest/xctwaiter/init(delegate:))
#### Waiting for Expectations

- [func fulfillment(of: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool) async -> XCTWaiter.Result](/documentation/xctest/xctwaiter/fulfillment(of:timeout:enforceorder:)-swift.method)
- [func wait(for: [XCTestExpectation]) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:)-swift.method)
- [func wait(for: [XCTestExpectation], enforceOrder: Bool) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:enforceorder:)-swift.method)
- [func wait(for: [XCTestExpectation], timeout: TimeInterval) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:timeout:)-swift.method)
- [func wait(for: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:timeout:enforceorder:)-swift.method)
- [class func fulfillment(of: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool) async -> XCTWaiter.Result](/documentation/xctest/xctwaiter/fulfillment(of:timeout:enforceorder:)-swift.type.method)
- [class func wait(for: [XCTestExpectation]) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:)-swift.type.method)
- [class func wait(for: [XCTestExpectation], enforceOrder: Bool) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:enforceorder:)-swift.type.method)
- [class func wait(for: [XCTestExpectation], timeout: TimeInterval) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:timeout:)-swift.type.method)
- [class func wait(for: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool) -> XCTWaiter.Result](/documentation/xctest/xctwaiter/wait(for:timeout:enforceorder:)-swift.type.method)
- [XCTWaiter.Result](/documentation/xctest/xctwaiter/result)
##### Result States

- [case completed](/documentation/xctest/xctwaiter/result/completed)
- [case timedOut](/documentation/xctest/xctwaiter/result/timedout)
- [case incorrectOrder](/documentation/xctest/xctwaiter/result/incorrectorder)
- [case invertedFulfillment](/documentation/xctest/xctwaiter/result/invertedfulfillment)
- [case interrupted](/documentation/xctest/xctwaiter/result/interrupted)
##### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctwaiter/result/init(rawvalue:))

#### Responding to Expectation Fulfilment

- [var delegate: (any XCTWaiterDelegate)?](/documentation/xctest/xctwaiter/delegate)
- [XCTWaiterDelegate](/documentation/xctest/xctwaiterdelegate)
##### Timeout Events

- [func waiter(XCTWaiter, didTimeoutWithUnfulfilledExpectations: [XCTestExpectation])](/documentation/xctest/xctwaiterdelegate/waiter(_:didtimeoutwithunfulfilledexpectations:))
- [func nestedWaiter(XCTWaiter, wasInterruptedByTimedOutWaiter: XCTWaiter)](/documentation/xctest/xctwaiterdelegate/nestedwaiter(_:wasinterruptedbytimedoutwaiter:))
##### Order of Fulfillment Events

- [func waiter(XCTWaiter, fulfillmentDidViolateOrderingConstraintsFor: XCTestExpectation, requiredExpectation: XCTestExpectation)](/documentation/xctest/xctwaiterdelegate/waiter(_:fulfillmentdidviolateorderingconstraintsfor:requiredexpectation:))
##### Inverted Expectation Events

- [func waiter(XCTWaiter, didFulfillInvertedExpectation: XCTestExpectation)](/documentation/xctest/xctwaiterdelegate/waiter(_:didfulfillinvertedexpectation:))

- [var fulfilledExpectations: [XCTestExpectation]](/documentation/xctest/xctwaiter/fulfilledexpectations)


## UI tests

- [XCUIAutomation](/documentation/xcuiautomation)
## Performance tests

- [Performance Tests](/documentation/xctest/performance-tests)
### Measuring Performance

- [Writing and running performance tests](/documentation/xcode/writing-and-running-performance-tests)
### Measurement Options

- [XCTMeasureOptions](/documentation/xctest/xctmeasureoptions)
#### Getting Default Options

- [class var `default`: XCTMeasureOptions](/documentation/xctest/xctmeasureoptions/default)
#### Using Option Details

- [var invocationOptions: XCTMeasureOptions.InvocationOptions](/documentation/xctest/xctmeasureoptions/invocationoptions-swift.property)
- [XCTMeasureOptions.InvocationOptions](/documentation/xctest/xctmeasureoptions/invocationoptions-swift.struct)
##### Measurement Options

- [static var manuallyStart: XCTMeasureOptions.InvocationOptions](/documentation/xctest/xctmeasureoptions/invocationoptions-swift.struct/manuallystart)
- [static var manuallyStop: XCTMeasureOptions.InvocationOptions](/documentation/xctest/xctmeasureoptions/invocationoptions-swift.struct/manuallystop)
##### Initializers

- [init(rawValue: UInt)](/documentation/xctest/xctmeasureoptions/invocationoptions-swift.struct/init(rawvalue:))

- [var iterationCount: Int](/documentation/xctest/xctmeasureoptions/iterationcount)

### Measurement Metrics

- [XCTMetric](/documentation/xctest/xctmetric)
#### Recording Metrics

- [func willBeginMeasuring()](/documentation/xctest/xctmetric/willbeginmeasuring())
- [func didStopMeasuring()](/documentation/xctest/xctmetric/didstopmeasuring())
#### Reporting Gathered Metrics

- [func reportMeasurements(from: XCTPerformanceMeasurementTimestamp, to: XCTPerformanceMeasurementTimestamp) throws -> [XCTPerformanceMeasurement]](/documentation/xctest/xctmetric/reportmeasurements(from:to:))

- [XCTCPUMetric](/documentation/xctest/xctcpumetric)
#### Initializers

- [init()](/documentation/xctest/xctcpumetric/init())
- [init(application: XCUIApplication)](/documentation/xctest/xctcpumetric/init(application:))
- [init(limitingToCurrentThread: Bool)](/documentation/xctest/xctcpumetric/init(limitingtocurrentthread:))

- [XCTClockMetric](/documentation/xctest/xctclockmetric)
#### Initializing an Item

- [init()](/documentation/xctest/xctclockmetric/init())

- [XCTHitchMetric](/documentation/xctest/xcthitchmetric)
#### Creating a hitch metric

- [init(application: XCUIApplication)](/documentation/xctest/xcthitchmetric/init(application:))

- [XCTMemoryMetric](/documentation/xctest/xctmemorymetric)
#### Initializers

- [init()](/documentation/xctest/xctmemorymetric/init())
- [init(application: XCUIApplication)](/documentation/xctest/xctmemorymetric/init(application:))

- [XCTOSSignpostMetric](/documentation/xctest/xctossignpostmetric)
#### Measuring Specific Signposts

- [init(subsystem: String, category: String, name: String)](/documentation/xctest/xctossignpostmetric/init(subsystem:category:name:))
#### Measuring Navigation Transitions

- [class var customNavigationTransitionMetric: any XCTMetric](/documentation/xctest/xctossignpostmetric/customnavigationtransitionmetric)
- [class var navigationTransitionMetric: any XCTMetric](/documentation/xctest/xctossignpostmetric/navigationtransitionmetric)
#### Measuring Scrolling Properties

- [class var scrollingAndDecelerationMetric: any XCTMetric](/documentation/xctest/xctossignpostmetric/scrollinganddecelerationmetric)
#### Deprecated

- [class var applicationLaunch: XCTOSSignpostMetric](/documentation/xctest/xctossignpostmetric/applicationlaunch)
- [class var scrollDecelerationMetric: any XCTMetric](/documentation/xctest/xctossignpostmetric/scrolldecelerationmetric)
- [class var scrollDraggingMetric: any XCTMetric](/documentation/xctest/xctossignpostmetric/scrolldraggingmetric)

- [XCTStorageMetric](/documentation/xctest/xctstoragemetric)
#### Initializers

- [init()](/documentation/xctest/xctstoragemetric/init())
- [init(application: XCUIApplication)](/documentation/xctest/xctstoragemetric/init(application:))

- [XCTApplicationLaunchMetric](/documentation/xctest/xctapplicationlaunchmetric)
#### Initializers

- [init()](/documentation/xctest/xctapplicationlaunchmetric/init())
- [init(waitUntilResponsive: Bool)](/documentation/xctest/xctapplicationlaunchmetric/init(waituntilresponsive:))

### Measurements

- [XCTPerformanceMeasurement](/documentation/xctest/xctperformancemeasurement)
#### Initializing a Measurement

- [init(identifier: String, displayName: String, doubleValue: Double, unitSymbol: String)](/documentation/xctest/xctperformancemeasurement/init(identifier:displayname:doublevalue:unitsymbol:))
- [convenience init(identifier: String, displayName: String, doubleValue: Double, unitSymbol: String, polarity: XCTPerformanceMeasurement.Polarity)](/documentation/xctest/xctperformancemeasurement/init(identifier:displayname:doublevalue:unitsymbol:polarity:))
- [convenience init(identifier: String, displayName: String, value: Measurement<Unit>)](/documentation/xctest/xctperformancemeasurement/init(identifier:displayname:value:))
- [convenience init(identifier: String, displayName: String, value: Measurement<Unit>, polarity: XCTPerformanceMeasurement.Polarity)](/documentation/xctest/xctperformancemeasurement/init(identifier:displayname:value:polarity:))
#### Identifying Measurements

- [var displayName: String](/documentation/xctest/xctperformancemeasurement/displayname)
- [var identifier: String](/documentation/xctest/xctperformancemeasurement/identifier)
#### Accessing Measured Values

- [var doubleValue: Double](/documentation/xctest/xctperformancemeasurement/doublevalue)
- [var unitSymbol: String](/documentation/xctest/xctperformancemeasurement/unitsymbol)
- [var value: Measurement<Unit>](/documentation/xctest/xctperformancemeasurement/value)
- [var polarity: XCTPerformanceMeasurement.Polarity](/documentation/xctest/xctperformancemeasurement/polarity-swift.property)
- [XCTPerformanceMeasurement.Polarity](/documentation/xctest/xctperformancemeasurement/polarity-swift.enum)
##### Polarity Types

- [case prefersLarger](/documentation/xctest/xctperformancemeasurement/polarity-swift.enum/preferslarger)
- [case prefersSmaller](/documentation/xctest/xctperformancemeasurement/polarity-swift.enum/preferssmaller)
- [case unspecified](/documentation/xctest/xctperformancemeasurement/polarity-swift.enum/unspecified)
##### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctperformancemeasurement/polarity-swift.enum/init(rawvalue:))


- [XCTPerformanceMeasurementTimestamp](/documentation/xctest/xctperformancemeasurementtimestamp)
#### Initializers

- [convenience init()](/documentation/xctest/xctperformancemeasurementtimestamp/init())
- [init(absoluteTime: UInt64, date: Date)](/documentation/xctest/xctperformancemeasurementtimestamp/init(absolutetime:date:))
#### Mach Absolute Time

- [var absoluteTimeNanoSeconds: UInt64](/documentation/xctest/xctperformancemeasurementtimestamp/absolutetimenanoseconds)
- [var absoluteTime: UInt64](/documentation/xctest/xctperformancemeasurementtimestamp/absolutetime)
#### Date

- [var date: Date](/documentation/xctest/xctperformancemeasurementtimestamp/date)


## Activities and attachments

- [Activities and Attachments](/documentation/xctest/activities-and-attachments)
### Activities

- [Grouping Tests into Substeps with Activities](/documentation/xctest/grouping-tests-into-substeps-with-activities)
- [XCTContext](/documentation/xctest/xctcontext)
#### Running Activities

- [class func runActivity<Result>(named: String, block: (any XCTActivity) throws -> Result) rethrows -> Result](/documentation/xctest/xctcontext/runactivity(named:block:))

- [XCTActivity](/documentation/xctest/xctactivity)
#### Adding Attachments

- [func add(XCTAttachment)](/documentation/xctest/xctactivity/add(_:))
#### Activity Properties

- [var name: String](/documentation/xctest/xctactivity/name)

### Attachments

- [Adding Attachments to Tests, Activities, and Issues](/documentation/xctest/adding-attachments-to-tests-activities-and-issues)
- [XCTAttachment](/documentation/xctest/xctattachment)
#### Creating Attachments from Data

- [convenience init(data: Data)](/documentation/xctest/xctattachment/init(data:))
- [convenience init(data: Data, uniformTypeIdentifier: String)](/documentation/xctest/xctattachment/init(data:uniformtypeidentifier:))
- [init(uniformTypeIdentifier: String?, name: String?, payload: Data?, userInfo: [AnyHashable : Any]?)](/documentation/xctest/xctattachment/init(uniformtypeidentifier:name:payload:userinfo:))
#### Creating Attachments from Files and Folders

- [convenience init(contentsOfFileAtURL: URL)](/documentation/xctest/xctattachment/init(contentsoffileaturl:))
- [convenience init(contentsOfFileAtURL: URL, uniformTypeIdentifier: String)](/documentation/xctest/xctattachment/init(contentsoffileaturl:uniformtypeidentifier:))
- [convenience init(compressedContentsOfDirectoryAtURL: URL)](/documentation/xctest/xctattachment/init(compressedcontentsofdirectoryaturl:))
#### Creating Attachments from Images and Screenshots

- [convenience init(image: UIImage)](/documentation/xctest/xctattachment/init(image:))
- [convenience init(image: UIImage, quality: XCTAttachment.ImageQuality)](/documentation/xctest/xctattachment/init(image:quality:))
- [convenience init(screenshot: XCUIScreenshot)](/documentation/xctest/xctattachment/init(screenshot:))
- [convenience init(screenshot: XCUIScreenshot, quality: XCTAttachment.ImageQuality)](/documentation/xctest/xctattachment/init(screenshot:quality:))
- [XCUIScreenshot](/documentation/xcuiautomation/xcuiscreenshot)
- [XCTAttachment.ImageQuality](/documentation/xctest/xctattachment/imagequality)
##### Quality Settings

- [case original](/documentation/xctest/xctattachment/imagequality/original)
- [case medium](/documentation/xctest/xctattachment/imagequality/medium)
- [case low](/documentation/xctest/xctattachment/imagequality/low)
##### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctattachment/imagequality/init(rawvalue:))

#### Creating Attachments from Objects

- [convenience init(plistObject: Any)](/documentation/xctest/xctattachment/init(plistobject:))
- [convenience init(archivableObject: any NSSecureCoding)](/documentation/xctest/xctattachment/init(archivableobject:))
- [convenience init(archivableObject: any NSSecureCoding, uniformTypeIdentifier: String)](/documentation/xctest/xctattachment/init(archivableobject:uniformtypeidentifier:))
#### Creating Attachments from Strings

- [convenience init(string: String)](/documentation/xctest/xctattachment/init(string:))
#### Setting an Attachment’s Lifetime

- [var lifetime: XCTAttachment.Lifetime](/documentation/xctest/xctattachment/lifetime-swift.property)
- [XCTAttachment.Lifetime](/documentation/xctest/xctattachment/lifetime-swift.enum)
##### Attachment Lifetimes

- [case deleteOnSuccess](/documentation/xctest/xctattachment/lifetime-swift.enum/deleteonsuccess)
- [case keepAlways](/documentation/xctest/xctattachment/lifetime-swift.enum/keepalways)
##### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctattachment/lifetime-swift.enum/init(rawvalue:))

#### Attachment Metadata

- [var name: String?](/documentation/xctest/xctattachment/name)
- [var uniformTypeIdentifier: String](/documentation/xctest/xctattachment/uniformtypeidentifier)
- [var userInfo: [AnyHashable : Any]?](/documentation/xctest/xctattachment/userinfo)
#### Initializers

- [convenience init(compressedContentsOfDirectory: URL)](/documentation/xctest/xctattachment/init(compressedcontentsofdirectory:))
- [convenience init(contentsOfFile: URL)](/documentation/xctest/xctattachment/init(contentsoffile:))
- [convenience init(contentsOfFile: URL, uniformTypeIdentifier: String)](/documentation/xctest/xctattachment/init(contentsoffile:uniformtypeidentifier:))
#### Default Implementations

- [XCTAttachment Implementations](/documentation/xctest/xctattachment/xctattachment-implementations)
##### Initializers

- [convenience init(compressedContentsOfDirectoryAtURL: URL)](/documentation/xctest/xctattachment/init(compressedcontentsofdirectoryaturl:))
- [convenience init(contentsOfFileAtURL: URL)](/documentation/xctest/xctattachment/init(contentsoffileaturl:))
- [convenience init(contentsOfFileAtURL: URL, uniformTypeIdentifier: String)](/documentation/xctest/xctattachment/init(contentsoffileaturl:uniformtypeidentifier:))



## Test execution

- [Test Execution and Observation](/documentation/xctest/test-execution-and-observation)
### Test Failures

- [XCTIssue](/documentation/xctest/xctissue-swift.struct)
#### Issue Types

- [XCTIssue.IssueType](/documentation/xctest/xctissue-swift.struct/issuetype)
#### Issue Details

- [var type: XCTIssue.IssueType](/documentation/xctest/xctissue-swift.struct/type)
- [var compactDescription: String](/documentation/xctest/xctissue-swift.struct/compactdescription)
- [var detailedDescription: String?](/documentation/xctest/xctissue-swift.struct/detaileddescription)
- [var sourceCodeContext: XCTSourceCodeContext](/documentation/xctest/xctissue-swift.struct/sourcecodecontext)
- [var associatedError: (any Error)?](/documentation/xctest/xctissue-swift.struct/associatederror)
- [var attachments: [XCTAttachment]](/documentation/xctest/xctissue-swift.struct/attachments)
- [func add(XCTAttachment)](/documentation/xctest/xctissue-swift.struct/add(_:))
#### Initializers

- [init(type: XCTIssue.IssueType, compactDescription: String, detailedDescription: String?, sourceCodeContext: XCTSourceCodeContext, associatedError: (any Error)?, attachments: [XCTAttachment], severity: XCTIssue.Severity)](/documentation/xctest/xctissue-swift.struct/init(type:compactdescription:detaileddescription:sourcecodecontext:associatederror:attachments:severity:))
#### Instance Properties

- [var isFailure: Bool](/documentation/xctest/xctissue-swift.struct/isfailure)
- [var severity: XCTIssue.Severity](/documentation/xctest/xctissue-swift.struct/severity-swift.property)
#### Type Aliases

- [XCTIssue.Severity](/documentation/xctest/xctissue-swift.struct/severity-swift.typealias)

- [XCTIssueReference](/documentation/xctest/xctissuereference)
#### Initializers

- [convenience init(type: XCTIssueReference.IssueType, compactDescription: String)](/documentation/xctest/xctissuereference/init(type:compactdescription:))
- [init(type: XCTIssueReference.IssueType, compactDescription: String, detailedDescription: String?, sourceCodeContext: XCTSourceCodeContext, associatedError: (any Error)?, attachments: [XCTAttachment])](/documentation/xctest/xctissuereference/init(type:compactdescription:detaileddescription:sourcecodecontext:associatederror:attachments:))
- [init(type: XCTIssueReference.IssueType, compactDescription: String, detailedDescription: String?, sourceCodeContext: XCTSourceCodeContext, associatedError: (any Error)?, attachments: [XCTAttachment], severity: XCTIssueReference.Severity)](/documentation/xctest/xctissuereference/init(type:compactdescription:detaileddescription:sourcecodecontext:associatederror:attachments:severity:))
- [convenience init(type: XCTIssueReference.IssueType, compactDescription: String, severity: XCTIssueReference.Severity)](/documentation/xctest/xctissuereference/init(type:compactdescription:severity:))
#### Issue Types

- [XCTIssueReference.IssueType](/documentation/xctest/xctissuereference/issuetype)
##### Issue Types

- [case assertionFailure](/documentation/xctest/xctissuereference/issuetype/assertionfailure)
- [case performanceRegression](/documentation/xctest/xctissuereference/issuetype/performanceregression)
- [case system](/documentation/xctest/xctissuereference/issuetype/system)
- [case thrownError](/documentation/xctest/xctissuereference/issuetype/thrownerror)
- [case uncaughtException](/documentation/xctest/xctissuereference/issuetype/uncaughtexception)
- [case unmatchedExpectedFailure](/documentation/xctest/xctissuereference/issuetype/unmatchedexpectedfailure)
##### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctissuereference/issuetype/init(rawvalue:))

#### Issue Details

- [var type: XCTIssueReference.IssueType](/documentation/xctest/xctissuereference/type)
- [var compactDescription: String](/documentation/xctest/xctissuereference/compactdescription)
- [var detailedDescription: String?](/documentation/xctest/xctissuereference/detaileddescription)
- [var sourceCodeContext: XCTSourceCodeContext](/documentation/xctest/xctissuereference/sourcecodecontext)
- [var associatedError: (any Error)?](/documentation/xctest/xctissuereference/associatederror)
- [var attachments: [XCTAttachment]](/documentation/xctest/xctissuereference/attachments)
#### Instance Properties

- [var isFailure: Bool](/documentation/xctest/xctissuereference/isfailure)
- [var severity: XCTIssueReference.Severity](/documentation/xctest/xctissuereference/severity-swift.property)
#### Enumerations

- [XCTIssueReference.Severity](/documentation/xctest/xctissuereference/severity-swift.enum)
##### Enumeration Cases

- [case error](/documentation/xctest/xctissuereference/severity-swift.enum/error)
- [case warning](/documentation/xctest/xctissuereference/severity-swift.enum/warning)
##### Initializers

- [init?(rawValue: Int)](/documentation/xctest/xctissuereference/severity-swift.enum/init(rawvalue:))


- [XCTMutableIssue](/documentation/xctest/xctmutableissue)
#### Issue Details

- [var type: XCTIssueReference.IssueType](/documentation/xctest/xctmutableissue/type)
- [var compactDescription: String](/documentation/xctest/xctmutableissue/compactdescription)
- [var detailedDescription: String?](/documentation/xctest/xctmutableissue/detaileddescription)
- [var sourceCodeContext: XCTSourceCodeContext](/documentation/xctest/xctmutableissue/sourcecodecontext)
- [var associatedError: (any Error)?](/documentation/xctest/xctmutableissue/associatederror)
- [var attachments: [XCTAttachment]](/documentation/xctest/xctmutableissue/attachments)
- [func add(XCTAttachment)](/documentation/xctest/xctmutableissue/add(_:))
#### Instance Properties

- [var severity: XCTIssueReference.Severity](/documentation/xctest/xctmutableissue/severity)

- [XCTSourceCodeContext](/documentation/xctest/xctsourcecodecontext)
#### Initializers

- [init(callStack: [XCTSourceCodeFrame], location: XCTSourceCodeLocation?)](/documentation/xctest/xctsourcecodecontext/init(callstack:location:))
- [convenience init(callStackAddresses: [NSNumber], location: XCTSourceCodeLocation?)](/documentation/xctest/xctsourcecodecontext/init(callstackaddresses:location:))
- [convenience init(location: XCTSourceCodeLocation?)](/documentation/xctest/xctsourcecodecontext/init(location:))
- [convenience init()](/documentation/xctest/xctsourcecodecontext/init())
#### Context Information

- [var callStack: [XCTSourceCodeFrame]](/documentation/xctest/xctsourcecodecontext/callstack)
- [var location: XCTSourceCodeLocation?](/documentation/xctest/xctsourcecodecontext/location)

- [XCTSourceCodeFrame](/documentation/xctest/xctsourcecodeframe)
#### Initializers

- [init(address: UInt64, symbolInfo: XCTSourceCodeSymbolInfo?)](/documentation/xctest/xctsourcecodeframe/init(address:symbolinfo:))
- [convenience init(address: UInt64)](/documentation/xctest/xctsourcecodeframe/init(address:))
#### Frame Information

- [var address: UInt64](/documentation/xctest/xctsourcecodeframe/address)
- [var symbolInfo: XCTSourceCodeSymbolInfo?](/documentation/xctest/xctsourcecodeframe/symbolinfo)
- [var symbolicationError: (any Error)?](/documentation/xctest/xctsourcecodeframe/symbolicationerror)
- [func symbolInfo() throws -> XCTSourceCodeSymbolInfo](/documentation/xctest/xctsourcecodeframe/symbolinfo())

- [XCTSourceCodeLocation](/documentation/xctest/xctsourcecodelocation)
#### Initializers

- [init(fileURL: URL, lineNumber: Int)](/documentation/xctest/xctsourcecodelocation/init(fileurl:linenumber:))
- [convenience init(filePath: String, lineNumber: Int)](/documentation/xctest/xctsourcecodelocation/init(filepath:linenumber:)-3hzmr)
- [convenience init(filePath: StaticString, lineNumber: UInt)](/documentation/xctest/xctsourcecodelocation/init(filepath:linenumber:)-8qw52)
#### Source Location Information

- [var fileURL: URL](/documentation/xctest/xctsourcecodelocation/fileurl)
- [var lineNumber: Int](/documentation/xctest/xctsourcecodelocation/linenumber)

- [XCTSourceCodeSymbolInfo](/documentation/xctest/xctsourcecodesymbolinfo)
#### Initializers

- [init(imageName: String, symbolName: String, location: XCTSourceCodeLocation?)](/documentation/xctest/xctsourcecodesymbolinfo/init(imagename:symbolname:location:))
#### Symbol Information

- [var imageName: String](/documentation/xctest/xctsourcecodesymbolinfo/imagename)
- [var location: XCTSourceCodeLocation?](/documentation/xctest/xctsourcecodesymbolinfo/location)
- [var symbolName: String](/documentation/xctest/xctsourcecodesymbolinfo/symbolname)

### Test Runs

- [XCTestCaseRun](/documentation/xctest/xctestcaserun)
#### Deprecated

- [func recordFailure(inTest: XCTestCase, withDescription: String, inFile: String, atLine: Int, expected: Bool)](/documentation/xctest/xctestcaserun/recordfailure(intest:withdescription:infile:atline:expected:))

- [XCTestSuiteRun](/documentation/xctest/xctestsuiterun)
#### Managing Test Runs

- [func addTestRun(XCTestRun)](/documentation/xctest/xctestsuiterun/addtestrun(_:))
- [var testRuns: [XCTestRun]](/documentation/xctest/xctestsuiterun/testruns)

- [XCTestRun](/documentation/xctest/xctestrun)
#### Creating Test Runs

- [init(test: XCTest)](/documentation/xctest/xctestrun/init(test:))
#### Performing Test Runs

- [func start()](/documentation/xctest/xctestrun/start())
- [func stop()](/documentation/xctest/xctestrun/stop())
- [func record(XCTIssue)](/documentation/xctest/xctestrun/record(_:))
#### Tracking Test Durations

- [var startDate: Date?](/documentation/xctest/xctestrun/startdate)
- [var stopDate: Date?](/documentation/xctest/xctestrun/stopdate)
- [var testDuration: TimeInterval](/documentation/xctest/xctestrun/testduration)
- [var totalDuration: TimeInterval](/documentation/xctest/xctestrun/totalduration)
#### Gathering Test Outcomes

- [var hasSucceeded: Bool](/documentation/xctest/xctestrun/hassucceeded)
- [var hasBeenSkipped: Bool](/documentation/xctest/xctestrun/hasbeenskipped)
- [var executionCount: Int](/documentation/xctest/xctestrun/executioncount)
- [var failureCount: Int](/documentation/xctest/xctestrun/failurecount)
- [var skipCount: Int](/documentation/xctest/xctestrun/skipcount)
- [var test: XCTest](/documentation/xctest/xctestrun/test)
- [var testCaseCount: Int](/documentation/xctest/xctestrun/testcasecount)
- [var totalFailureCount: Int](/documentation/xctest/xctestrun/totalfailurecount)
- [var unexpectedExceptionCount: Int](/documentation/xctest/xctestrun/unexpectedexceptioncount)
#### Deprecated

- [func recordFailure(withDescription: String, inFile: String?, atLine: Int, expected: Bool)](/documentation/xctest/xctestrun/recordfailure(withdescription:infile:atline:expected:))

### Test Observation

- [XCTestObservation](/documentation/xctest/xctestobservation)
#### Observation Methods

- [func testBundleWillStart(Bundle)](/documentation/xctest/xctestobservation/testbundlewillstart(_:))
- [func testSuiteWillStart(XCTestSuite)](/documentation/xctest/xctestobservation/testsuitewillstart(_:))
- [func testCaseWillStart(XCTestCase)](/documentation/xctest/xctestobservation/testcasewillstart(_:))
- [func testCase(XCTestCase, didRecord: XCTIssue)](/documentation/xctest/xctestobservation/testcase(_:didrecord:)-4cou6)
- [func testCase(XCTestCase, didRecord: XCTExpectedFailure)](/documentation/xctest/xctestobservation/testcase(_:didrecord:)-8k955)
- [func testCase(XCTestCase, didFailWithDescription: String, inFile: String?, atLine: Int)](/documentation/xctest/xctestobservation/testcase(_:didfailwithdescription:infile:atline:))
- [func testCaseDidFinish(XCTestCase)](/documentation/xctest/xctestobservation/testcasedidfinish(_:))
- [func testSuite(XCTestSuite, didRecord: XCTIssue)](/documentation/xctest/xctestobservation/testsuite(_:didrecord:)-3rk9k)
- [func testSuite(XCTestSuite, didRecord: XCTExpectedFailure)](/documentation/xctest/xctestobservation/testsuite(_:didrecord:)-1xjkv)
- [func testSuite(XCTestSuite, didFailWithDescription: String, inFile: String?, atLine: Int)](/documentation/xctest/xctestobservation/testsuite(_:didfailwithdescription:infile:atline:))
- [func testSuiteDidFinish(XCTestSuite)](/documentation/xctest/xctestobservation/testsuitedidfinish(_:))
- [func testBundleDidFinish(Bundle)](/documentation/xctest/xctestobservation/testbundledidfinish(_:))

- [XCTestObservationCenter](/documentation/xctest/xctestobservationcenter)
#### Accessing the Shared Observation Center

- [class var shared: XCTestObservationCenter](/documentation/xctest/xctestobservationcenter/shared)
#### Managing Observers

- [func addTestObserver(any XCTestObservation)](/documentation/xctest/xctestobservationcenter/addtestobserver(_:))
- [func removeTestObserver(any XCTestObservation)](/documentation/xctest/xctestobservationcenter/removetestobserver(_:))

### Test Suites

- [XCTestSuite](/documentation/xctest/xctestsuite)
#### Creating Test Suites

- [class var `default`: XCTestSuite](/documentation/xctest/xctestsuite/default)
- [init(name: String)](/documentation/xctest/xctestsuite/init(name:))
- [convenience init(forBundlePath: String)](/documentation/xctest/xctestsuite/init(forbundlepath:))
- [convenience init(forTestCaseClass: AnyClass)](/documentation/xctest/xctestsuite/init(fortestcaseclass:))
- [convenience init(forTestCaseWithName: String)](/documentation/xctest/xctestsuite/init(fortestcasewithname:))
#### Managing Tests

- [func addTest(XCTest)](/documentation/xctest/xctestsuite/addtest(_:))
- [var tests: [XCTest]](/documentation/xctest/xctestsuite/tests)


## Deprecated

- [Deprecated Symbols](/documentation/xctest/deprecated-symbols)
### Deprecated Classes

- [XCTestLog](/documentation/xctest/xctestlog)
#### Logging Test Results

- [var logFileHandle: FileHandle!](/documentation/xctest/xctestlog/logfilehandle)
- [func testLog(withFormat: String!, arguments: CVaListPointer)](/documentation/xctest/xctestlog/testlog(withformat:arguments:))

- [XCTestObserver](/documentation/xctest/xctestobserver)
#### Starting and Stopping Test Observation

- [func startObserving()](/documentation/xctest/xctestobserver/startobserving())
- [func stopObserving()](/documentation/xctest/xctestobserver/stopobserving())
#### Monitoring Test Activity

- [func testCaseDidFail(XCTestRun!, withDescription: String!, inFile: String!, atLine: Int)](/documentation/xctest/xctestobserver/testcasedidfail(_:withdescription:infile:atline:))
- [func testCaseDidStart(XCTestRun!)](/documentation/xctest/xctestobserver/testcasedidstart(_:))
- [func testCaseDidStop(XCTestRun!)](/documentation/xctest/xctestobserver/testcasedidstop(_:))
- [func testSuiteDidStart(XCTestRun!)](/documentation/xctest/xctestobserver/testsuitedidstart(_:))
- [func testSuiteDidStop(XCTestRun!)](/documentation/xctest/xctestobserver/testsuitedidstop(_:))

- [XCTestProbe](/documentation/xctest/xctestprobe)
#### Inspecting a Test

- [class func isTesting() -> Bool](/documentation/xctest/xctestprobe/istesting())

### Deprecated Functions

- [func XCTSelfTestMain() -> Int32](/documentation/xctest/xctselftestmain())
- [func XCTAssertEqualWithAccuracy<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, accuracy: T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertequalwithaccuracy(_:_:accuracy:_:file:line:))
- [func XCTAssertNotEqualWithAccuracy<T>(@autoclosure () throws -> T, @autoclosure () throws -> T, T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnotequalwithaccuracy(_:_:_:_:file:line:))
### Deprecated Constants

- [let XCTestObserverClassKey: String](/documentation/xctest/xctestobserverclasskey)
- [let XCTestedUnitPath: String](/documentation/xctest/xctestedunitpath)
- [let XCTestScopeNone: String](/documentation/xctest/xctestscopenone)
- [let XCTestScopeAll: String](/documentation/xctest/xctestscopeall)
- [let XCTestScopeKey: String](/documentation/xctest/xctestscopekey)
- [let XCTestScopeSelf: String](/documentation/xctest/xctestscopeself)
- [let XCTestToolKey: String](/documentation/xctest/xctesttoolkey)

## Variables

- [var XCT_UI_TESTING_AVAILABLE: Int32](/documentation/xctest/xct_ui_testing_available)
## Functions

- [func XCTAssertNoThrow<T>(@autoclosure () throws -> T, @autoclosure () -> String, file: StaticString, line: UInt)](/documentation/xctest/xctassertnothrow(_:_:file:line:))

---

*Extracted from Apple DocC JSON by apple-skills tooling.*
*This is unofficial content. All documentation belongs to Apple Inc.*
