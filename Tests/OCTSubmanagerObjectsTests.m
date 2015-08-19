//
//  OCTSubmanagerObjectsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTSubmanagerObjects+Private.h"
#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"
#import "RBQFetchRequest.h"

@interface OCTSubmanagerObjectsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerObjects *submanager;
@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id realmManager;

@end

@implementation OCTSubmanagerObjectsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    self.realmManager = OCMClassMock([OCTRealmManager class]);
    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    self.submanager = [OCTSubmanagerObjects new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.realmManager = nil;
    self.submanager = nil;

    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFetchRequestByType
{
    id predicate = OCMClassMock([NSPredicate class]);

    id fetchRequest1 = OCMClassMock([RBQFetchRequest class]);
    id fetchRequest2 = OCMClassMock([RBQFetchRequest class]);
    id fetchRequest3 = OCMClassMock([RBQFetchRequest class]);
    id fetchRequest4 = OCMClassMock([RBQFetchRequest class]);

    OCMStub([self.realmManager fetchRequestForClass:[OCTFriend class]
                                      withPredicate:predicate]).andReturn(fetchRequest1);
    OCMStub([self.realmManager fetchRequestForClass:[OCTFriendRequest class]
                                      withPredicate:predicate]).andReturn(fetchRequest2);
    OCMStub([self.realmManager fetchRequestForClass:[OCTChat class]
                                      withPredicate:predicate]).andReturn(fetchRequest3);
    OCMStub([self.realmManager fetchRequestForClass:[OCTMessageAbstract class]
                                      withPredicate:predicate]).andReturn(fetchRequest4);

    XCTAssertEqual(fetchRequest1, [self.submanager fetchRequestForType:OCTFetchRequestTypeFriend
                                                         withPredicate:predicate]);
    XCTAssertEqual(fetchRequest2, [self.submanager fetchRequestForType:OCTFetchRequestTypeFriendRequest
                                                         withPredicate:predicate]);
    XCTAssertEqual(fetchRequest3, [self.submanager fetchRequestForType:OCTFetchRequestTypeChat
                                                         withPredicate:predicate]);
    XCTAssertEqual(fetchRequest4, [self.submanager fetchRequestForType:OCTFetchRequestTypeMessageAbstract
                                                         withPredicate:predicate]);
}

- (void)testObjectWithUniqueIdentifier
{
    NSString *identifier = @"identifier";

    id object1 = OCMClassMock([OCTObject class]);
    id object2 = OCMClassMock([OCTObject class]);
    id object3 = OCMClassMock([OCTObject class]);
    id object4 = OCMClassMock([OCTObject class]);

    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTFriend class]]).andReturn(object1);
    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTFriendRequest class]]).andReturn(object2);
    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTChat class]]).andReturn(object3);
    OCMStub([self.realmManager objectWithUniqueIdentifier:identifier class:[OCTMessageAbstract class]]).andReturn(object4);

    XCTAssertEqual(object1, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeFriend]);
    XCTAssertEqual(object2, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeFriendRequest]);
    XCTAssertEqual(object3, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeChat]);
    XCTAssertEqual(object4, [self.submanager objectWithUniqueIdentifier:identifier forType:OCTFetchRequestTypeMessageAbstract]);
}

- (void)testChangeFriendNickname
{
    OCTFriend *friend = [OCTFriend new];

    OCMStub([self.realmManager updateObject:friend withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(friend);
        return YES;
    }]]);

    [self.submanager changeFriend:friend nickname:@"new"];

    XCTAssertEqualObjects(friend.nickname, @"new");
}

- (void)testChangeChatEnteredText
{
    OCTChat *chat = [OCTChat new];

    OCMStub([self.realmManager updateObject:chat withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(chat);
        return YES;
    }]]);

    [self.submanager changeChat:chat enteredText:@"text"];

    XCTAssertEqualObjects(chat.enteredText, @"text");
}

- (void)testChangeChatEnteredLastReadDateInterval
{
    OCTChat *chat = [OCTChat new];

    OCMStub([self.realmManager updateObject:chat withBlock:[OCMArg checkWithBlock:^BOOL (id obj) {
        void (^block)(id) = obj;
        block(chat);
        return YES;
    }]]);

    [self.submanager changeChat:chat lastReadDateInterval:17];

    XCTAssertEqual(chat.lastReadDateInterval, 17);
}

@end
