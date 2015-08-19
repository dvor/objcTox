//
//  OCTBasicContainerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTBasicContainer.h"
#import "OCTManagerConstants.h"

@interface OCTBasicContainer (Tests)
@property (strong, nonatomic) NSMutableArray *array;
@end

@interface OCTBasicContainerTests : XCTestCase

@property (strong, nonatomic) OCTBasicContainer *container;

@end

@implementation OCTBasicContainerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.container = [[OCTBasicContainer alloc] initWithObjects:nil];
}

- (void)tearDown
{
    self.container = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    id object = @1;

    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ object ]];

    XCTAssertTrue(container.array.count == 1);

    id theFriend = [container.array lastObject];
    XCTAssertEqual(object, theFriend);
}

- (void)testSetComparator
{
    [self.container addObject:@4];
    [self.container addObject:@0];
    [self.container addObject:@1];
    [self.container addObject:@3];
    [self.container addObject:@2];
    [self.container addObject:@5];

    [self.container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return [first compare:second];
    }];

    XCTAssertEqual([self.container objectAtIndex:0], @0);
    XCTAssertEqual([self.container objectAtIndex:1], @1);
    XCTAssertEqual([self.container objectAtIndex:2], @2);
    XCTAssertEqual([self.container objectAtIndex:3], @3);
    XCTAssertEqual([self.container objectAtIndex:4], @4);
    XCTAssertEqual([self.container objectAtIndex:5], @5);
}

- (void)testCount
{
    XCTAssertEqual([self.container count], 0);

    [self.container addObject:@1];
    [self.container addObject:@2];

    XCTAssertEqual([self.container count], 2);
}

- (void)testObjectAtIndex
{
    self.container.array = [NSMutableArray arrayWithArray:@[ @0, @1 ]];

    XCTAssertEqual([self.container objectAtIndex:0], @0);
    XCTAssertEqual([self.container objectAtIndex:1], @1);
    XCTAssertNil([self.container objectAtIndex:2]);
}

- (void)testDelegateForSetComparator
{
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @1, @0 ]];

    id delegate = OCMProtocolMock(@protocol(OCTBasicContainerDelegate));
    container.delegate = delegate;
    [delegate basicContainerUpdate:container
                       insertedSet:nil
                        removedSet:nil
                        updatedSet:[OCMArg checkWithBlock:^BOOL (NSIndexSet *updated)
    {
        XCTAssertEqual(updated.count, 2);
        XCTAssertTrue([updated containsIndex:0]);
        XCTAssertTrue([updated containsIndex:1]);

        return YES;
    }]];

    [container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return [first compare:second];
    }];

    OCMVerifyAll(delegate);
}

- (void)testDelegateForAddObject
{
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @0 ]];

    id delegate = OCMProtocolMock(@protocol(OCTBasicContainerDelegate));
    container.delegate = delegate;
    OCMExpect([delegate basicContainerUpdate:container insertedSet:[OCMArg checkWithBlock:^BOOL (NSIndexSet *set) {
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    }] removedSet:nil updatedSet:nil]);

    [container addObject:@1];

    OCMVerifyAll(delegate);
}

- (void)testDelegateForAddObjectWithSort
{
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @1 ]];
    [container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return [first compare:second];
    }];

    id delegate = OCMProtocolMock(@protocol(OCTBasicContainerDelegate));
    container.delegate = delegate;
    OCMExpect([delegate basicContainerUpdate:container insertedSet:[OCMArg checkWithBlock:^BOOL (NSIndexSet *set) {
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:0]);

        return YES;
    }] removedSet:nil updatedSet:nil]);

    [container addObject:@0];

    OCMVerifyAll(delegate);
}

- (void)testDelegateForRemoveObject
{
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @0, @1 ]];

    id delegate = OCMProtocolMock(@protocol(OCTBasicContainerDelegate));
    container.delegate = delegate;
    OCMExpect([delegate basicContainerUpdate:container
                                 insertedSet:nil
                                  removedSet:[OCMArg checkWithBlock:^BOOL (NSIndexSet *set)
    {
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;
    }] updatedSet:nil]);

    [container removeObject:@1];

    OCMVerifyAll(delegate);
}

- (void)testUpdateFriendsCallbackForUpdateFriend
{
    __block BOOL reverseSort = NO;
    OCTBasicContainer *container = [[OCTBasicContainer alloc] initWithObjects:@[ @0, @1 ]];
    [container setComparatorForCurrentSort:^NSComparisonResult (NSNumber *first, NSNumber *second) {
        return reverseSort ? [second compare : first] :[first compare:second];
    }];

    id delegate = OCMProtocolMock(@protocol(OCTBasicContainerDelegate));
    container.delegate = delegate;
    OCMExpect([delegate basicContainerUpdate:container insertedSet:[OCMArg checkWithBlock:^BOOL (NSIndexSet *set) {
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:1]);

        return YES;

    }] removedSet:[OCMArg checkWithBlock:^BOOL (NSIndexSet *set) {
        XCTAssertEqual(set.count, 1);
        XCTAssertTrue([set containsIndex:0]);

        return YES;
    }] updatedSet:nil]);
    OCMExpect([delegate basicContainer:container objectUpdated:@0]);

    [container updateObjectPassingTest:^BOOL (NSNumber *obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToNumber:@0];
    } updateBlock:^(id obj) {
        reverseSort = YES;
    }];

    OCMVerifyAll(delegate);
}

- (void)testAddObject
{
    id object = @1;

    [self.container addObject:object];

    XCTAssertTrue(self.container.array.count == 1);

    id theObject = [self.container.array lastObject];
    XCTAssertEqual(object, theObject);
}

- (void)testRemoveObject
{
    id object = @1;

    [self.container addObject:object];
    [self.container removeObject:object];

    XCTAssertTrue(self.container.array.count == 0);
}

- (void)testUpdateObject
{
    id object = @1;

    [self.container addObject:object];

    id testBlock = ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
        return YES;
    };

    __block BOOL blockCalled = NO;
    [self.container updateObjectPassingTest:testBlock updateBlock:^(id obj) {
        blockCalled = YES;
        XCTAssertEqual(obj, object);
    }];

    XCTAssertTrue(blockCalled);
}

@end
