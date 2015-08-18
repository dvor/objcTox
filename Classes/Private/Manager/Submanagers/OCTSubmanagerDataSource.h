//
//  OCTSubmanagerDataSource.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCTTox;
@class OCTRealmManager;
@class OCTSubmanagerAvatars;
@class OCTSubmanagerBootstrap;
@class OCTSubmanagerChats;
@class OCTSubmanagerFiles;
@class OCTSubmanagerFriends;
@class OCTSubmanagerObjects;
@class OCTSubmanagerUser;
@protocol OCTSettingsStorageProtocol;
@protocol OCTFileStorageProtocol;

@protocol OCTSubmanagerDataSource <NSObject>

@property (strong, nonatomic, readonly) OCTSubmanagerAvatars *avatars;
@property (strong, nonatomic, readonly) OCTSubmanagerBootstrap *bootstrap;
@property (strong, nonatomic, readonly) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readonly) OCTSubmanagerFiles *files;
@property (strong, nonatomic, readonly) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readonly) OCTSubmanagerObjects *objects;
@property (strong, nonatomic, readonly) OCTSubmanagerUser *user;

- (OCTTox *)managerGetTox;
- (dispatch_queue_t)managerGetToxQueue;
- (BOOL)managerIsToxConnected;
- (void)managerSaveTox;
- (OCTRealmManager *)managerGetRealmManager;
- (id<OCTSettingsStorageProtocol>)managerGetSettingsStorage;
- (id<OCTFileStorageProtocol>)managerGetFileStorage;
- (NSNotificationCenter *)managerGetNotificationCenter;

@end
