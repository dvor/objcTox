//
//  OCTRealmTests.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "OCTRealmManager.h"
#import "OCTFriend.h"
#import "OCTChat.h"

@interface OCTRealmManager (Tests)

@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) RLMRealm *realm;

@end

@interface OCTRealmTests : XCTestCase

/**
 * Partially mocked realm manager with in memory realm, which is reset after each test.
 */
@property (strong, nonatomic) OCTRealmManager *realmManager;

- (OCTFriend *)createFriend;

@end
