//
//  OCTMessageAbstractTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24/06/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTMessageAbstract.h"
#import "OCTFriend.h"

@interface OCTMessageAbstractTests : XCTestCase

@end

@implementation OCTMessageAbstractTests

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

- (void)testDate
{
    OCTMessageAbstract *message = [OCTMessageAbstract new];

    message.dateInterval = 0;
    XCTAssertNil([message date]);

    message.dateInterval = 12345;
    XCTAssertEqual([[message date] timeIntervalSince1970], 12345);

    message.dateInterval = -12345;
    XCTAssertNil([message date]);
}

- (void)testIsOutgoing
{
    OCTMessageAbstract *message = [OCTMessageAbstract new];

    XCTAssertTrue([message isOutgoing]);

    message.sender = [OCTFriend new];
    XCTAssertFalse([message isOutgoing]);
}

@end
