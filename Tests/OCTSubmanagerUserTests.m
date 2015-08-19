//
//  OCTSubmanagerUserTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTSubmanagerUser+Private.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTTox.h"

@interface OCTSubmanagerUserTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerUser *submanager;
@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) id tox;

@end

@implementation OCTSubmanagerUserTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.tox = OCMClassMock([OCTTox class]);

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    OCMStub([self.dataSource managerGetTox]).andReturn(self.tox);

    self.submanager = [OCTSubmanagerUser new];
    self.submanager.dataSource = self.dataSource;
}

- (void)tearDown
{
    self.tox = nil;
    self.dataSource = nil;
    self.submanager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConnectionStatus
{
    OCMStub([self.tox connectionStatus]).andReturn(OCTToxConnectionStatusTCP);
    XCTAssertEqual([self.submanager connectionStatus], OCTToxConnectionStatusTCP);
}

- (void)testUserAddress
{
    OCMStub([self.tox userAddress]).andReturn(@"address");
    XCTAssertEqualObjects([self.submanager userAddress], @"address");
}

- (void)testPublicKey
{
    OCMStub([self.tox publicKey]).andReturn(@"publicKey");
    XCTAssertEqualObjects([self.submanager publicKey], @"publicKey");
}

- (void)testNospam
{
    OCMStub([self.tox nospam]).andReturn(5);
    XCTAssertEqual([self.submanager nospam], 5);

    self.submanager.nospam = 7;
    OCMVerify([self.tox setNospam:7]);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testUserStatus
{
    OCMStub([self.tox userStatus]).andReturn(5);
    XCTAssertEqual([self.submanager userStatus], 5);

    self.submanager.userStatus = 7;
    OCMVerify([self.tox setUserStatus:7]);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testUserName
{
    OCMStub([self.tox userName]).andReturn(@"userName");
    XCTAssertEqualObjects([self.submanager userName], @"userName");

    NSError *error, *error2;
    OCMExpect([self.tox setNickname:@"name" error:[OCMArg setTo:error2]]).andReturn(YES);

    [self.submanager setUserName:@"name" error:&error];

    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
    OCMVerify([self.dataSource managerSaveTox]);
}

- (void)testUserStatusMessage
{
    OCMStub([self.tox userStatusMessage]).andReturn(@"userStatusMessage");
    XCTAssertEqualObjects([self.submanager userStatusMessage], @"userStatusMessage");

    NSError *error, *error2;
    OCMExpect([self.tox setUserStatusMessage:@"message" error:[OCMArg setTo:error2]]).andReturn(YES);

    [self.submanager setUserStatusMessage:@"message" error:&error];

    XCTAssertEqual(error, error2);
    OCMVerifyAll(self.tox);
    OCMVerify([self.dataSource managerSaveTox]);
}

@end
