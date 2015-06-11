//
//  OCTCallsContainerTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/10/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTCallsContainer+Private.h"
#import "OCTBasicContainer.h"
#import "OCTCall+Private.h"
#import "OCTChat+Private.h"
#import <OCMock/OCMock.h>

@interface OCTCallsContainer (Testing)

@property (strong, nonatomic) OCTBasicContainer *container;

@end

@interface OCTCallsContainerTests : XCTestCase

@property (strong, nonatomic) OCTCallsContainer *container;

@end

@implementation OCTCallsContainerTests

- (void)setUp
{
    [super setUp];
    self.container = [OCTCallsContainer new];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    self.container = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark - Public methods

- (void)testInit
{
    XCTAssertNotNil(self.container);
    XCTAssertNotNil(self.container.container);
}

- (void)testNumberOfCalls
{
    XCTAssertEqual(0, self.container.numberOfCalls);
    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"chat";
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    OCTChat *chat2 = [OCTChat new];
    chat.uniqueIdentifier = @"chat2";
    OCTCall *call2 = [[OCTCall alloc] initCallWithChat:chat2];

    [self.container addCall:call];
    [self.container addCall:call2];
    XCTAssertEqual(2, self.container.numberOfCalls);
}

- (void)testCallAtIndex
{
    id mockedContainer = OCMClassMock([OCTBasicContainer class]);
    self.container.container = mockedContainer;

    [self.container callAtIndex:5];

    OCMVerify([mockedContainer objectAtIndex:5]);
}

- (void)testCallWithFriend
{
    OCTFriend *friend = [OCTFriend new];
    OCTChat *chat = [OCTChat new];
    chat.friends = @[friend];
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    [self.container addCall:call];

    OCTCall *foundCall = [self.container callWithFriend:friend];

    XCTAssertNotNil(foundCall);
    XCTAssertEqualObjects(foundCall.chat.friends.firstObject, call.chat.friends.firstObject);
}

#pragma mark - Delegate

- (void)testDelegate
{
    id delegate = OCMProtocolMock(@protocol(OCTCallsContainerDelegate));
    self.container.delegate = delegate;

    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"test";
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    [self.container addCall:call];

    NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:0];
    OCMVerify([delegate callsContainerUpdate:self.container insertedSet:set removedSet:nil updatedSet:nil]);

    [self.container updateCallWithChat:chat updateBlock:^(OCTCall *call) {}];
    OCMVerify([delegate callsContainer:self.container callUpdated:call]);
}

#pragma mark - Private methods

- (void)testAddCall
{
    id mockedContainer = OCMClassMock([OCTBasicContainer class]);
    self.container.container = mockedContainer;

    OCTChat *chat = [OCTChat new];
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    [self.container addCall:call];

    OCMVerify([mockedContainer addObject:call]);
}

- (void)testRemoveCall
{
    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"chat";
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    OCTChat *chat1 = [OCTChat new];
    chat1.uniqueIdentifier = @"chat1";
    OCTCall *call1 = [[OCTCall alloc] initCallWithChat:chat1];

    OCTChat *chat2 = [OCTChat new];
    chat2.uniqueIdentifier = @"chat2";
    OCTCall *call2 = [[OCTCall alloc] initCallWithChat:chat2];

    OCTChat *chat3 = [OCTChat new];
    chat2.uniqueIdentifier = @"chat3";
    OCTCall *call3 = [[OCTCall alloc] initCallWithChat:chat3];

    [self.container addCall:call];
    [self.container addCall:call1];
    [self.container addCall:call2];
    [self.container addCall:call3];

    XCTAssertEqual(4, self.container.numberOfCalls);

    [self.container removeCall:call3];
    XCTAssertEqual(3, self.container.numberOfCalls);
}

- (void)testUpdateCallWithChat
{
    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"fail";
    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    [self.container addCall:call];

    [self.container updateCallWithChat:chat updateBlock:^(OCTCall *call) {
        call.chat.uniqueIdentifier = @"pass";
    }];

    OCTCall *callFound = [self.container callAtIndex:0];
    XCTAssertEqualObjects(callFound.chat.uniqueIdentifier, @"pass");
}
@end
