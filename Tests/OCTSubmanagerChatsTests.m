//
//  OCTSubmanagerChatsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 10.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "OCTRealmTests.h"

#import "OCTSubmanagerChats+Private.h"
#import "OCTRealmManager.h"
#import "OCTTox.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageText.h"

@interface OCTSubmanagerChatsTests : OCTRealmTests

@property (strong, nonatomic) OCTSubmanagerChats *submanager;
@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id tox;

@end

@implementation OCTSubmanagerChatsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    self.tox = OCMClassMock([OCTTox class]);
    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);

    self.submanager = [OCTSubmanagerChats new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.dataSource = nil;
    self.tox = nil;
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGetOrCreateChatWithFriend
{
    OCTFriend *friend = [self createFriend];

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTChat *first = [self.realmManager getOrCreateChatWithFriend:friend];
    OCTChat *second = [self.realmManager getOrCreateChatWithFriend:friend];

    XCTAssertEqualObjects(first, second);
    XCTAssertEqualObjects([first.friends firstObject], friend);
}

- (void)testRemoveChatWithAllMessages
{
    OCTChat *chat = [OCTChat new];

    OCMExpect([self.realmManager removeChatWithAllMessages:chat]);

    [self.submanager removeChatWithAllMessages:chat];

    OCMVerifyAll((id)self.realmManager);
}

- (void)testSendMessageToChatSuccess
{
    id message = OCMClassMock([OCTMessageAbstract class]);

    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(5);
    NSArray *friends = @[friend];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(friends);

    NSError *error;

    OCMStub([self.tox sendMessageWithFriendNumber:5
                                             type:OCTToxMessageTypeAction
                                          message:@"text"
                                            error:[OCMArg anyObjectRef]]).andReturn(7);
    OCMExpect([self.realmManager addMessageWithText:@"text"
                                               type:OCTToxMessageTypeAction
                                               chat:chat
                                             sender:nil
                                          messageId:7]).andReturn(message);

    id theMessage = [self.submanager sendMessageToChat:chat text:@"text" type:OCTToxMessageTypeAction error:&error];

    OCMVerifyAll((id)self.realmManager);
    XCTAssertEqualObjects(message, theMessage);
    XCTAssertNil(error);
}

- (void)testSendMessageToChatFailure
{
    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(5);
    NSArray *friends = @[friend];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(friends);

    NSError *error;
    NSError *error2 = OCMClassMock([NSError class]);

    OCMStub([self.tox sendMessageWithFriendNumber:5
                                             type:OCTToxMessageTypeAction
                                          message:@"text"
                                            error:[OCMArg setTo:error2]]).andReturn(0);
    id theMessage = [self.submanager sendMessageToChat:chat text:@"text" type:OCTToxMessageTypeAction error:&error];

    OCMVerifyAll((id)self.realmManager);
    XCTAssertNil(theMessage);
    XCTAssertEqualObjects(error, error2);
}

- (void)testSetIsTyping
{
    id friend = OCMClassMock([OCTFriend class]);
    OCMStub([friend friendNumber]).andReturn(5);
    NSArray *friends = @[friend];

    id chat = OCMClassMock([OCTChat class]);
    OCMStub([chat friends]).andReturn(friends);

    NSError *error;
    NSError *error2 = OCMClassMock([NSError class]);

    OCMExpect([self.tox setUserIsTyping:YES forFriendNumber:5 error:[OCMArg setTo:error2]]).andReturn(NO);

    XCTAssertFalse([self.submanager setIsTyping:YES inChat:chat error:&error]);

    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
}

#pragma mark -  OCTToxDelegate

- (void)testFriendMessage
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 5;

    OCTChat *chat = [OCTChat new];
    [chat.friends addObject:friend];

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:chat];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:nil friendMessage:@"message" type:OCTToxMessageTypeAction friendNumber:5];

    RLMResults *results = [OCTMessageAbstract allObjectsInRealm:self.realmManager.realm];
    XCTAssertEqual(results.count, 1);

    OCTMessageAbstract *message = [results firstObject];
    XCTAssertEqualObjects(message.sender, friend);
    XCTAssertEqualObjects(message.chat, chat);
    XCTAssertNotNil(message.messageText);
    XCTAssertEqualObjects(message.messageText.text, @"message");
    XCTAssertEqual(message.messageText.type, OCTToxMessageTypeAction);
}

- (void)testMessageDelivered
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 5;

    OCTMessageAbstract *message = [OCTMessageAbstract new];
    message.chat = [OCTChat new];
    [message.chat.friends addObject:friend];
    message.messageText = [OCTMessageText new];
    message.messageText.text = @"";
    message.messageText.messageId = 10;
    message.messageText.isDelivered = NO;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:message];
    [self.realmManager.realm commitWriteTransaction];

    [self.submanager tox:nil messageDelivered:10 friendNumber:5];

    XCTAssertTrue(message.messageText.isDelivered);
}

@end
