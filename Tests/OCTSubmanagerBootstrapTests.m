//
//  OCTSubmanagerBootstrapTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 06/08/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTSettingsStorageProtocol.h"
#import "OCTTox.h"

@interface OCTSubmanagerBootstrap (Tests)

@property (assign, nonatomic) NSTimeInterval didConnectDelay;
@property (assign, nonatomic) NSTimeInterval iterationTime;

@end

@interface OCTSubmanagerBootstrapTests : XCTestCase

@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id tox;
@property (strong, nonatomic) id settingsStorage;
@property (strong, nonatomic) OCTSubmanagerBootstrap *submanager;

@end

@implementation OCTSubmanagerBootstrapTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    self.tox = OCMClassMock([OCTTox class]);
    self.settingsStorage = OCMProtocolMock(@protocol(OCTSettingsStorageProtocol));

    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);
    OCMStub([self.dataSource managerGetSettingsStorage]).andReturn(self.settingsStorage);

    self.submanager = [OCTSubmanagerBootstrap new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.tox = nil;
    self.settingsStorage = nil;
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBootstrapCustomNodes
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];

    self.submanager.didConnectDelay = 0.0;
    self.submanager.iterationTime = 0.05;

    [self.submanager addNodeWithHost:@"one" port:1 publicKey:@"1"];
    [self.submanager addNodeWithHost:@"two" port:2 publicKey:@"2"];
    [self.submanager addNodeWithHost:@"three" port:3 publicKey:@"3"];
    [self.submanager addNodeWithHost:@"four" port:4 publicKey:@"4"];

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.1];
    [self waitForExpectationsWithTimeout:0.3 handler:nil];

    OCMVerify([self.tox bootstrapFromHost:@"one" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"two" port:2 publicKey:@"2" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"three" port:3 publicKey:@"3" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"four" port:4 publicKey:@"4" error:[OCMArg anyObjectRef]]);
}

- (void)testBootstrapSeveralPortions
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];

    self.submanager.didConnectDelay = 0.0;
    self.submanager.iterationTime = 0.05;

    [self.submanager addNodeWithHost:@"h1" port:1 publicKey:@"1"];
    [self.submanager addNodeWithHost:@"h2" port:2 publicKey:@"2"];
    [self.submanager addNodeWithHost:@"h3" port:3 publicKey:@"3"];
    [self.submanager addNodeWithHost:@"h4" port:4 publicKey:@"4"];
    [self.submanager addNodeWithHost:@"h5" port:5 publicKey:@"5"];
    [self.submanager addNodeWithHost:@"h6" port:6 publicKey:@"6"];
    [self.submanager addNodeWithHost:@"h7" port:7 publicKey:@"7"];
    [self.submanager addNodeWithHost:@"h8" port:8 publicKey:@"8"];
    [self.submanager addNodeWithHost:@"h9" port:9 publicKey:@"9"];
    [self.submanager addNodeWithHost:@"h10" port:10 publicKey:@"10"];

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.5];
    [self waitForExpectationsWithTimeout:1.2 handler:nil];

    OCMVerify([self.tox bootstrapFromHost:@"h1" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h2" port:2 publicKey:@"2" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h3" port:3 publicKey:@"3" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h4" port:4 publicKey:@"4" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h5" port:5 publicKey:@"5" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h6" port:6 publicKey:@"6" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h7" port:7 publicKey:@"7" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h8" port:8 publicKey:@"8" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h9" port:9 publicKey:@"9" error:[OCMArg anyObjectRef]]);
    OCMVerify([self.tox bootstrapFromHost:@"h10" port:10 publicKey:@"10" error:[OCMArg anyObjectRef]]);
}

- (void)testBootstrapDidConnectVerify
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];

    OCMStub([self.settingsStorage objectForKey:[OCMArg any]]).andReturn(@(YES));

    self.submanager.didConnectDelay = 0.1;
    self.submanager.iterationTime = 0.05;

    [self.submanager addNodeWithHost:@"one" port:1 publicKey:@"1"];

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.15];
    [self waitForExpectationsWithTimeout:0.3 handler:nil];

    OCMVerify([self.tox bootstrapFromHost:@"one" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]]);
}

- (void)testBootstrapDidConnectReject
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];

    OCMStub([self.settingsStorage objectForKey:[OCMArg any]]).andReturn(@(YES));
    [[self.tox reject] bootstrapFromHost:@"one" port:1 publicKey:@"1" error:[OCMArg anyObjectRef]];

    self.submanager.didConnectDelay = 0.2;
    self.submanager.iterationTime = 0.05;

    [self.submanager addNodeWithHost:@"one" port:1 publicKey:@"1"];

    [self.submanager bootstrap];

    [self performBlock:^{
        [expectation fulfill];
    } afterDelay:0.1];
    [self waitForExpectationsWithTimeout:0.15 handler:nil];
}

- (void)testAddTCPRelay
{
    NSError *error, *error2;

    OCMExpect([self.tox addTCPRelayWithHost:@"host" port:10 publicKey:@"publicKey" error:[OCMArg setTo:error2]]).andReturn(YES);

    BOOL result = [self.submanager addTCPRelayWithHost:@"host" port:10 publicKey:@"publicKey" error:&error];

    XCTAssertTrue(result);
    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
}

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(runBlock:) withObject:block afterDelay:delay];
}

- (void)runBlock:(void (^)())block
{
    block();
}

@end
