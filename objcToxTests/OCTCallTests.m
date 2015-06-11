//
//  OCTCallTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/7/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCTCall+Private.h"

@interface OCTCallTests : XCTestCase

@end

@implementation OCTCallTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    OCTChat *chat = [OCTChat new];
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];


    XCTAssertNotNil(call);
    XCTAssertEqualObjects(call.chat, chat);
    XCTAssertEqual(call.status, OCTCallStatusInactive);

    OCTCall *call2 = [[OCTCall alloc] initCallWithChat:chat];
    XCTAssertEqualObjects(call2, call);

    OCTChat *chat2 = [OCTChat new];
    OCTCall *call3 = [[OCTCall alloc] initCallWithChat:chat2];

    XCTAssertFalse(call3 == call);
}

- (void)testTimer
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test Timer"];
    OCTChat *chat = [OCTChat new];
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    [call startTimer];

    NSInteger delayTime = dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC);

    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        if (call.callDuration > 1) {
            [expectation fulfill];
        }
    });

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        [call stopTimer];
    }];
}

@end
