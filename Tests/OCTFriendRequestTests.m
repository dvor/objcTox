//
//  OCTFriendRequestTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24/06/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTFriendRequest.h"

@interface OCTFriendRequestTests : XCTestCase

@end

@implementation OCTFriendRequestTests

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
    OCTFriendRequest *request = [OCTFriendRequest new];
    request.dateInterval = 12345;

    NSDate *date = [request date];

    XCTAssertEqual([date timeIntervalSince1970], 12345);
}

@end
