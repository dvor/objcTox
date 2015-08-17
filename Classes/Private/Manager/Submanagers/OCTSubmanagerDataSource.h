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
@protocol OCTSettingsStorageProtocol;
@protocol OCTFileStorageProtocol;

@protocol OCTSubmanagerDataSource <NSObject>

- (OCTTox *)managerGetTox;
- (dispatch_queue_t)managerGetToxQueue;
- (BOOL)managerIsToxConnected;
- (void)managerSaveTox;
- (OCTRealmManager *)managerGetRealmManager;
- (id<OCTSettingsStorageProtocol>)managerGetSettingsStorage;
- (id<OCTFileStorageProtocol>)managerGetFileStorage;

@end
