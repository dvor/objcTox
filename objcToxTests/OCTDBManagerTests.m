//
//  OCTDBManagerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <Realm/Realm.h>
#import <XCTest/XCTest.h>

#import "OCTDBManager.h"
#import "OCTDBFriendRequest.h"
#import "OCTDBChat.h"

@interface OCTDBManager ()

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) RLMRealm *realm;

@end

@interface OCTDBManagerTests : XCTestCase

@property (strong, nonatomic) OCTDBManager *manager;
@property (strong, nonatomic) NSNotificationCenter *mockedNotificationCenter;

@end

@implementation OCTDBManagerTests

- (NSString *)realmPath
{
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];

    return [directory stringByAppendingPathComponent:@"test.realm"];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    NSString *realmPath = [self realmPath];
    NSString *directory = [realmPath stringByDeletingLastPathComponent];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (! [fileManager fileExistsAtPath:directory]) {
        // This is hack to fix xctool issue on Travis CI.
        // For some reason it don't create documents directory.
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    self.manager = [[OCTDBManager alloc] initWithDatabasePath:realmPath];

    self.mockedNotificationCenter = OCMClassMock([NSNotificationCenter class]);
    OCMStub([(id)self.mockedNotificationCenter defaultCenter]).andReturn(self.mockedNotificationCenter);
}

- (void)tearDown
{
    OCMVerifyAll((id)self.mockedNotificationCenter);

    NSString *realmPath = [self realmPath];
    NSString *lockPath = [realmPath stringByAppendingString:@".lock"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:realmPath error:nil];
    [fileManager removeItemAtPath:lockPath error:nil];

    self.manager = nil;
    self.mockedNotificationCenter = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.manager);
    XCTAssertNotNil(self.manager.queue);
    XCTAssertNotNil(self.manager.realm);
    XCTAssertEqualObjects(self.manager.realm.path, [self realmPath]);
}

- (void)testUpdateDBObjectWithBlock
{
    [self expectUpdateNotificationWithClass:[OCTDBFriendRequest class]];

    OCTDBFriendRequest *db = [OCTDBFriendRequest new];
    db.publicKey = @"key";
    db.message = @"message";

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db];
    [self.manager.realm commitWriteTransaction];

    [self.manager updateDBObjectInBlock:^{
        db.message = @"updated message";
    } objectClass:[OCTDBFriendRequest class]];

    OCTDBFriendRequest *updated = [OCTDBFriendRequest objectInRealm:self.manager.realm forPrimaryKey:db.publicKey];

    XCTAssertEqualObjects(updated.message, @"updated message");
}

#pragma mark -  Friends

- (void)testAllFriendRequests
{
    OCTDBFriendRequest *db1 = [OCTDBFriendRequest new];
    db1.publicKey = @"key1";
    db1.message = @"message1";

    OCTDBFriendRequest *db2 = [OCTDBFriendRequest new];
    db2.publicKey = @"key2";
    db2.message = @"message2";

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm commitWriteTransaction];

    RLMResults *results = [self.manager allFriendRequests];

    XCTAssertEqual(results.count, 2);

    XCTAssertEqualObjects(db1.publicKey, [results[0] publicKey]);
    XCTAssertEqualObjects(db1.message, [results[0] message]);
    XCTAssertEqualObjects(db2.publicKey, [results[1] publicKey]);
    XCTAssertEqualObjects(db2.message, [results[1] message]);
}

- (void)testAddFriendRequest
{
    [self expectUpdateNotificationWithClass:[OCTDBFriendRequest class]];

    OCTDBFriendRequest *request = [OCTDBFriendRequest new];
    request.publicKey = @"key";
    request.message = @"message";

    [self.manager addFriendRequest:request];

    OCTDBFriendRequest *db = [OCTDBFriendRequest objectInRealm:self.manager.realm forPrimaryKey:request.publicKey];

    XCTAssertNotNil(db);
    XCTAssertEqualObjects(request.publicKey, db.publicKey);
    XCTAssertEqualObjects(request.message, db.message);
}

- (void)testRemoveFriendRequestWithPublicKey
{
    [self expectUpdateNotificationWithClass:[OCTDBFriendRequest class]];

    OCTDBFriendRequest *request = [OCTDBFriendRequest new];
    request.publicKey = @"key";
    request.message = @"message";

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:request];
    [self.manager.realm commitWriteTransaction];

    [self.manager removeFriendRequestWithPublicKey:@"key"];

    RLMResults *results = [OCTDBFriendRequest allObjectsInRealm:self.manager.realm];
    XCTAssertEqual(results.count, 0);
}

- (void)testGetOrCreateFriendWithFriendNumber
{
    [self expectUpdateNotificationWithClass:[OCTDBFriend class]];

    OCTDBFriend *friend = [self.manager getOrCreateFriendWithFriendNumber:7];
    XCTAssertNotNil(friend);
    XCTAssertEqual(friend.friendNumber, 7);

    OCTDBFriend *friend2 = [self.manager getOrCreateFriendWithFriendNumber:7];
    XCTAssertNotNil(friend2);
    XCTAssertEqual(friend2.friendNumber, 7);

    XCTAssertEqualObjects(friend, friend2);
}

- (void)testAllChats
{
    OCTDBChat *db1 = [OCTDBChat new];
    db1.enteredText = @"";
    db1.lastReadDateInterval = 5;

    OCTDBChat *db2 = [OCTDBChat new];
    db2.enteredText = @"";
    db2.lastReadDateInterval = 10;

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm commitWriteTransaction];

    RLMResults *results = [self.manager allChats];

    XCTAssertEqual(results.count, 2);

    XCTAssertEqualObjects(db1.enteredText, [results[0] enteredText]);
    XCTAssertEqual(db1.lastReadDateInterval, [results[0] lastReadDateInterval]);
    XCTAssertEqualObjects(db2.enteredText, [results[1] enteredText]);
    XCTAssertEqual(db2.lastReadDateInterval, [results[1] lastReadDateInterval]);
}

- (void)testChatsWithPredicate
{
    OCTDBChat *db1 = [OCTDBChat new];
    db1.enteredText = @"";
    db1.lastReadDateInterval = 5;

    OCTDBChat *db2 = [OCTDBChat new];
    db2.enteredText = @"";
    db2.lastReadDateInterval = 10;

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm commitWriteTransaction];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastReadDateInterval == 5"];
    RLMResults *results = [self.manager chatsWithPredicate:predicate];

    XCTAssertEqual(results.count, 1);

    XCTAssertEqualObjects(db1.enteredText, [results[0] enteredText]);
    XCTAssertEqual(db1.lastReadDateInterval, [results[0] lastReadDateInterval]);
}

- (void)testGetOrCreateChatWithFriendNumber
{
    [self expectUpdateNotificationWithClass:[OCTDBChat class]];

    // create friend
    OCTDBFriend *friend = [self.manager getOrCreateFriendWithFriendNumber:7];

    OCTDBChat *chat = [self.manager getOrCreateChatWithFriendNumber:7];
    XCTAssertNotNil(chat);
    XCTAssertEqual(chat.friends.count, 1);
    XCTAssertEqualObjects([chat.friends lastObject], friend);

    [self.manager.realm beginWriteTransaction];
    chat.enteredText = @"text";
    chat.lastReadDateInterval = 50;
    [self.manager.realm commitWriteTransaction];

    OCTDBChat *chat2 = [self.manager getOrCreateChatWithFriendNumber:7];
    XCTAssertNotNil(chat2);
    XCTAssertEqualObjects(chat.enteredText, chat2.enteredText);
    XCTAssertEqual(chat.lastReadDateInterval, chat2.lastReadDateInterval);
}

- (void)testChatWithUniqueIdentifier
{
    OCTDBChat *chat = [OCTDBChat new];
    chat.uniqueIdentifier = @"identifier";
    chat.enteredText = @"text";

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:chat];
    [self.manager.realm commitWriteTransaction];

    OCTDBChat *chat1 = [self.manager chatWithUniqueIdentifier:@"identifier"];
    OCTDBChat *chat2 = [self.manager chatWithUniqueIdentifier:@"another identifier"];

    XCTAssertNotNil(chat1);
    XCTAssertNil(chat2);
    XCTAssertEqualObjects(chat, chat1);
}

- (void)testRemoveChatWithAllMessages
{
    [self expectUpdateNotificationWithClass:[OCTDBChat class]];
    [self expectUpdateNotificationWithClass:[OCTDBMessageAbstract class]];

    OCTDBChat *chat = [OCTDBChat new];
    OCTDBChat *anotherChat = [OCTDBChat new];

    OCTDBMessageAbstract *db1 = [OCTDBMessageAbstract new];
    db1.dateInterval = 50;
    db1.chat = chat;
    db1.textMessage = [OCTDBMessageText new];
    db1.textMessage.text = @"text";

    OCTDBMessageAbstract *db2 = [OCTDBMessageAbstract new];
    db2.dateInterval = 70;
    db2.chat = chat;
    db2.fileMessage = [OCTDBMessageFile new];
    db2.fileMessage.fileName = @"name2";
    db2.fileMessage.filePath = @"path2";
    db2.fileMessage.fileUTI = @"uti2";

    OCTDBMessageAbstract *db3 = [OCTDBMessageAbstract new];
    db3.dateInterval = 80;
    db3.chat = chat;
    db3.callMessage = [OCTDBMessageCall new];

    OCTDBMessageAbstract *nonDelete = [OCTDBMessageAbstract new];
    nonDelete.dateInterval = 1;
    nonDelete.fileMessage = [OCTDBMessageFile new];
    nonDelete.fileMessage.fileName = @"name3";
    nonDelete.fileMessage.filePath = @"path3";
    nonDelete.fileMessage.fileUTI = @"uti3";
    // no chat

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:anotherChat];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm addObject:db3];
    [self.manager.realm addObject:nonDelete];
    [self.manager.realm commitWriteTransaction];

    [self.manager removeChatWithAllMessages:chat];

    RLMResults *results = [OCTDBMessageAbstract allObjectsInRealm:self.manager.realm];
    XCTAssertEqual(results.count, 1);
    XCTAssertEqual(nonDelete.dateInterval, [results[0] dateInterval]);

    results = [OCTDBMessageText allObjectsInRealm:self.manager.realm];
    XCTAssertEqual(results.count, 0);

    results = [OCTDBMessageFile allObjectsInRealm:self.manager.realm];
    XCTAssertEqual(results.count, 1);
    XCTAssertEqualObjects(nonDelete.fileMessage.fileName, [results[0] fileName]);

    results = [OCTDBMessageCall allObjectsInRealm:self.manager.realm];
    XCTAssertEqual(results.count, 0);

    results = [OCTDBChat allObjectsInRealm:self.manager.realm];
    XCTAssertEqual(results.count, 1);
    XCTAssertEqualObjects(anotherChat, results[0]);
}

- (void)testAllMessagesInChat
{
    OCTDBChat *chat = [OCTDBChat new];

    OCTDBMessageAbstract *db1 = [OCTDBMessageAbstract new];
    db1.dateInterval = 50;
    db1.chat = chat;

    OCTDBMessageAbstract *db2 = [OCTDBMessageAbstract new];
    db2.dateInterval = 70;
    db2.chat = chat;

    OCTDBMessageAbstract *db3 = [OCTDBMessageAbstract new];
    db3.dateInterval = 90;
    // no chat

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm addObject:db3];
    [self.manager.realm commitWriteTransaction];

    RLMResults *results = [self.manager allMessagesInChat:chat];

    XCTAssertEqual(results.count, 2);

    XCTAssertEqual(db1.dateInterval, [results[0] dateInterval]);
    XCTAssertEqual(db2.dateInterval, [results[1] dateInterval]);
}

- (void)addMessageWithText
{
    [self expectUpdateNotificationWithClass:[OCTDBMessageAbstract class]];

    OCTDBChat *chat = [OCTDBChat new];
    OCTDBFriend *sender = [OCTDBFriend new];
    NSDate *date = [NSDate date];

    [self.manager addMessageWithText:@"text" type:OCTToxMessageTypeAction chat:chat sender:sender messageId:4];

    RLMResults *results = [OCTDBMessageAbstract allObjectsInRealm:self.manager.realm];

    XCTAssertEqual(results.count, 1);

    OCTDBMessageAbstract *message = [results lastObject];

    XCTAssertEqual(message.dateInterval, [date timeIntervalSince1970]);
    XCTAssertEqualObjects(message.sender, sender);
    XCTAssertEqualObjects(message.chat, chat);
    XCTAssertNotNil(message.textMessage);
    XCTAssertEqualObjects(message.textMessage.text, @"text");
    XCTAssertFalse(message.textMessage.isDelivered);
    XCTAssertEqual(message.textMessage.type, OCTToxMessageTypeAction);
    XCTAssertEqual(message.textMessage.messageId, 4);
}

- (void)testTextMessageInChat
{
    OCTDBMessageAbstract *message = [OCTDBMessageAbstract new];
    message.chat = [OCTDBChat new];
    message.textMessage = [OCTDBMessageText new];
    message.textMessage.messageId = 7;
    message.textMessage.text = @"some text";

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:message];
    [self.manager.realm commitWriteTransaction];

    OCTDBMessageAbstract *db = [self.manager textMessageInChat:message.chat withMessageId:7];

    XCTAssertEqualObjects(message.textMessage.text, db.textMessage.text);
}

- (void)testAllCalls
{
    OCTDBCall *db1 = [OCTDBCall new];
    OCTDBMessageCall *dbMessageCall = [OCTDBMessageCall new];
    dbMessageCall.callDuration = 99;

    OCTDBMessageAbstract *messageAbstract = [OCTDBMessageAbstract new];
    messageAbstract.callMessage = dbMessageCall;

    db1.lastCall = messageAbstract;

    OCTDBCall *db2 = [OCTDBCall new];

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm commitWriteTransaction];

    RLMResults *results = [self.manager allCalls];

    XCTAssertEqual(results.count, 2);
    XCTAssertEqual([results[0] lastCall].callMessage.callDuration, db1.lastCall.callMessage.callDuration);
}

- (void)testCallsWithPredicate
{
    OCTDBCall *db1 = [OCTDBCall new];
    OCTDBMessageCall *dbMessageCall = [OCTDBMessageCall new];
    dbMessageCall.callDuration = 99;
    OCTDBMessageAbstract *messageAbstract = [OCTDBMessageAbstract new];
    messageAbstract.callMessage = dbMessageCall;
    db1.lastCall = messageAbstract;

    OCTDBCall *db2 = [OCTDBCall new];
    OCTDBMessageCall *dbMessageCall2 = [OCTDBMessageCall new];
    dbMessageCall2.callDuration = 101;
    OCTDBMessageAbstract *messageAbstract2 = [OCTDBMessageAbstract new];
    messageAbstract2.callMessage = dbMessageCall2;
    db2.lastCall = messageAbstract2;

    [self.manager.realm beginWriteTransaction];
    [self.manager.realm addObject:db1];
    [self.manager.realm addObject:db2];
    [self.manager.realm commitWriteTransaction];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastCall.callMessage.callDuration < 100"];
    RLMResults *results = [self.manager callsWithPredicate:predicate];

    XCTAssertEqual(results.count, 1);

    XCTAssertEqual(db1.lastCall.callMessage.callDuration, [[[results[0] lastCall] callMessage] callDuration]);
}

- (void)testGetOrCreateCallWithFriendNumber
{
    [self expectUpdateNotificationWithClass:[OCTDBCall class]];

    // create friend
    OCTDBFriend *friend = [self.manager getOrCreateFriendWithFriendNumber:7];

    OCTDBCall *call = [self.manager getOrCreateCallWithFriendNumber:7];
    XCTAssertNotNil(call);
    XCTAssertEqual(call.friends.count, 1);
    XCTAssertEqualObjects([call.friends lastObject], friend);

    [self.manager.realm beginWriteTransaction];
    call.lastCall.callMessage.callDuration = 99;
    [self.manager.realm commitWriteTransaction];

    OCTDBCall *call2 = [self.manager getOrCreateCallWithFriendNumber:7];
    XCTAssertNotNil(call2);
    XCTAssertEqual(call.lastCall.callMessage.callDuration, call2.lastCall.callMessage.callDuration);
}

#pragma mark -  Supporting methods

- (void)expectUpdateNotificationWithClass:(Class)class
{
    BOOL (^block)(NSDictionary *) = ^(NSDictionary *dict) {
        if (! [dict isKindOfClass:[NSDictionary class]]) {
            return NO;
        }

        return (BOOL) (dict[kOCTDBManagerObjectClassKey] == class);
    };

    OCMExpect([self.mockedNotificationCenter postNotificationName:kOCTDBManagerUpdateNotification
                                                           object:nil
                                                         userInfo:[OCMArg checkWithBlock:block]]);
}

@end
