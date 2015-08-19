//
//  OCTManagerTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTManager.h"
#import "OCTTox.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTManagerConfiguration.h"
#import "OCTSubmanagerAvatars+Private.h"
#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerUser+Private.h"
#import "OCTSubmanagerObjects+Private.h"
#import "OCTRealmManager.h"

@interface OCTManager (Tests) <OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (copy, nonatomic, readonly) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerAvatars *avatars;
@property (strong, nonatomic, readwrite) OCTSubmanagerBootstrap *bootstrap;
@property (strong, nonatomic, readwrite) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerFiles *files;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerObjects *objects;
@property (strong, nonatomic, readwrite) OCTSubmanagerUser *user;

@property (strong, nonatomic) OCTRealmManager *realmManager;
@property (strong, nonatomic) NSNotificationCenter *notificationCenter;

- (id)forwardingTargetForSelector:(SEL)aSelector;

@end


@interface FakeSubmanager : NSObject <OCTToxDelegate>
@property (weak, nonatomic) id dataSource;
@end
@implementation FakeSubmanager
- (void)tox:(OCTTox *)tox connectionStatus:(OCTToxConnectionStatus)status
{}
@end

@interface OCTManagerTests : XCTestCase

@property (strong, nonatomic) OCTManager *manager;
@property (strong, nonatomic) id tox;

@end

@implementation OCTManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    self.tox = OCMClassMock([OCTTox class]);
    OCMStub([self.tox alloc]).andReturn(self.tox);
    OCMStub([self.tox initWithOptions:[OCMArg any] savedData:[OCMArg any] error:[OCMArg anyObjectRef]]).andReturn(self.tox);

    id data = OCMClassMock([NSData class]);

    OCMStub([data writeToFile:[OCMArg any] options:NSDataWritingAtomic error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.tox save]).andReturn(data);
}

- (void)tearDown
{
    [self.tox stopMocking];
    self.tox = nil;

    self.manager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit
{
    [self createManager];

    XCTAssertNotNil(self.manager);

    XCTAssertNotNil(self.manager.avatars);
    XCTAssertEqual(self.manager.avatars.dataSource, self.manager);
    XCTAssertNotNil(self.manager.bootstrap);
    XCTAssertEqual(self.manager.bootstrap.dataSource, self.manager);
    XCTAssertNotNil(self.manager.chats);
    XCTAssertEqual(self.manager.chats.dataSource, self.manager);
    XCTAssertNotNil(self.manager.files);
    XCTAssertEqual(self.manager.files.dataSource, self.manager);
    XCTAssertNotNil(self.manager.friends);
    XCTAssertEqual(self.manager.friends.dataSource, self.manager);
    XCTAssertNotNil(self.manager.objects);
    XCTAssertEqual(self.manager.objects.dataSource, self.manager);
    XCTAssertNotNil(self.manager.user);
    XCTAssertEqual(self.manager.user.dataSource, self.manager);

    XCTAssertNotNil(self.manager.tox);
    XCTAssertNotNil(self.manager.configuration);
    XCTAssertNotNil(self.manager.realmManager);
    XCTAssertEqualObjects(self.manager.realmManager.path, self.manager.configuration.fileStorage.pathForDatabase);

    XCTAssertNotNil(self.manager.notificationCenter);
}

- (void)testBootstrap
{
    NSError *error, *error2;

    OCMExpect([self.tox bootstrapFromHost:@"host" port:10 publicKey:@"publicKey" error:[OCMArg setTo:error2]]).andReturn(YES);

    [self createManager];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    BOOL result = [self.manager bootstrapFromHost:@"host" port:10 publicKey:@"publicKey" error:&error];
#pragma clang diagnostic pop

    XCTAssertTrue(result);
    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
}

- (void)testAddTCPRelay
{
    NSError *error, *error2;

    OCMExpect([self.tox addTCPRelayWithHost:@"host" port:10 publicKey:@"publicKey" error:[OCMArg setTo:error2]]).andReturn(YES);

    [self createManager];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    BOOL result = [self.manager addTCPRelayWithHost:@"host" port:10 publicKey:@"publicKey" error:&error];
#pragma clang diagnostic pop

    XCTAssertTrue(result);
    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
}

- (void)testSubmanagerDataSource
{
    [self createManager];

    XCTAssertEqual([self.manager managerGetTox], self.manager.tox);
    XCTAssertEqual([self.manager managerGetRealmManager], self.manager.realmManager);
    XCTAssertEqual([self.manager managerGetSettingsStorage], self.manager.configuration.settingsStorage);
    XCTAssertEqual([self.manager managerGetFileStorage], self.manager.configuration.fileStorage);
    XCTAssertEqual([self.manager managerGetNotificationCenter], self.manager.notificationCenter);
}

- (void)testForwardTargetForSelector
{
    [self createManager];

    id submanager = [FakeSubmanager new];
    self.manager.avatars = submanager;
    self.manager.bootstrap = submanager;
    self.manager.chats = submanager;
    self.manager.files = submanager;
    self.manager.friends = submanager;
    self.manager.objects = submanager;
    self.manager.user = submanager;

    // test non protocol selector
    XCTAssertNil([self.manager forwardingTargetForSelector:@selector(dataSource)]);

    // test for protocol non-implemented selector
    XCTAssertNil([self.manager forwardingTargetForSelector:@selector(tox:friendRequestWithMessage:publicKey:)]);

    // test for protocol implemented selector
    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);
}

- (void)testForwardTargetForSelector2
{
    [self createManager];

    id submanager = [FakeSubmanager new];
    id dummy = [NSObject new];

    self.manager.avatars = submanager;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = submanager;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = submanager;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.files = submanager;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.friends = submanager;
    self.manager.objects = dummy;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = submanager;
    self.manager.user = dummy;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);

    self.manager.avatars = dummy;
    self.manager.bootstrap = dummy;
    self.manager.chats = dummy;
    self.manager.files = dummy;
    self.manager.friends = dummy;
    self.manager.objects = dummy;
    self.manager.user = submanager;

    XCTAssertEqual([self.manager forwardingTargetForSelector:@selector(tox:connectionStatus:)], submanager);
}

- (void)createManager
{
    OCTManagerConfiguration *configuration = [OCTManagerConfiguration defaultConfiguration];
    self.manager = [[OCTManager alloc] initWithConfiguration:configuration error:nil];
}

@end
