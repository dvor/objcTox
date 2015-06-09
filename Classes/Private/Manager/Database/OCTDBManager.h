//
//  OCTDBManager.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 19.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

#import "OCTDBFriendRequest.h"
#import "OCTDBChat.h"
#import "OCTDBCall.h"

/**
 * This notification is fired when some database object gets updated. Class of
 * updated object is passed in userInfo for kOCTDBManagerObjectClassKey.
 * Notification is send on main thread.
 *
 * Note: this is workaround for updating OCTArray. When Realm will support update
 * notification for RLMResults, this should be removed.
 *
 * See https://github.com/realm/realm-cocoa/issues/687
 */
extern NSString *const kOCTDBManagerUpdateNotification;
extern NSString *const kOCTDBManagerObjectClassKey;

@interface OCTDBManager : NSObject

- (instancetype)initWithDatabasePath:(NSString *)path;

- (NSString *)path;

- (void)updateDBObjectInBlock:(void (^)())updateBlock objectClass:(Class)class;

#pragma mark -  Friend requests

- (RLMResults *)allFriendRequests;
- (void)addFriendRequest:(OCTDBFriendRequest *)friendRequest;
- (void)removeFriendRequestWithPublicKey:(NSString *)publicKey;

#pragma mark -  Friends

- (OCTDBFriend *)getOrCreateFriendWithFriendNumber:(NSInteger)friendNumber;

#pragma mark -  Chats

- (RLMResults *)allChats;
- (RLMResults *)chatsWithPredicate:(NSPredicate *)predicate;
- (OCTDBChat *)getOrCreateChatWithFriendNumber:(NSInteger)friendNumber;
- (OCTDBChat *)chatWithUniqueIdentifier:(NSString *)uniqueIdentifier;
- (void)removeChatWithAllMessages:(OCTDBChat *)chat;

#pragma mark - Calls

- (RLMResults *)allCalls;
- (RLMResults *)callsWithPredicate:(NSPredicate *)predicate;
- (OCTDBCall *)getOrCreateCallWithFriendNumber:(NSInteger)friendNumber;
- (OCTDBCall *)callWithUniqueIdentifier:(NSString *)uniqueIdentifier;
- (void)removeCallWithAllMessages:(OCTDBCall *)call;

#pragma mark -  Messages

- (RLMResults *)allMessagesInChat:(OCTDBChat *)chat;

- (OCTDBMessageAbstract *)addMessageWithText:(NSString *)text
                                        type:(OCTToxMessageType)type
                                        chat:(OCTDBChat *)chat
                                      sender:(OCTDBFriend *)sender;

- (OCTDBMessageAbstract *)addMessageWithText:(NSString *)text
                                        type:(OCTToxMessageType)type
                                        chat:(OCTDBChat *)chat
                                      sender:(OCTDBFriend *)sender
                                   messageId:(int)messageId;

- (OCTDBMessageAbstract *)textMessageInChat:(OCTDBChat *)chat withMessageId:(int)messageId;

@end
