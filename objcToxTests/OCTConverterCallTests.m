//
//  OCTConverterCallTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "OCTConverterCall.h"
#import "OCTCall+Private.h"
#import "OCTMessageAbstract+Private.h"
#import "OCTMessageCall+Private.h"
#import "OCTDBCall.h"

@interface OCTConverterCallTests : XCTestCase

@property (strong, nonatomic) OCTConverterCall *converter;

@end

@implementation OCTConverterCallTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.converter = [OCTConverterCall new];
}

- (void)tearDown
{
    self.converter = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testObjectClassName
{
    XCTAssertEqualObjects([self.converter objectClassName], @"OCTCall");
}

- (void)testDBObjectClassName
{
    XCTAssertEqualObjects([self.converter dbObjectClassName], @"OCTDBCall");
}

- (void)testObjectFromRLMObject
{
    OCTDBFriend *dbFriend0 = [OCTDBFriend new];
    dbFriend0.friendNumber = 100;
    OCTDBFriend *dbFriend1 = [OCTDBFriend new];
    dbFriend0.friendNumber = 200;

    OCTDBMessageAbstract *dbLastCall = [OCTDBMessageAbstract new];

    OCTMessageCall *lastCall = [OCTMessageCall new];
    lastCall.callDuration = 99;

    id friend0 = OCMClassMock([OCTFriend class]);
    id friend1 = OCMClassMock([OCTFriend class]);

    id converterMessage = OCMClassMock([OCTConverterMessage class]);
    OCMStub([converterMessage objectFromRLMObjectWithoutChat:dbLastCall]).andReturn(lastCall);

    id converterFriend = OCMClassMock([OCTConverterFriend class]);
    OCMStub([converterFriend objectFromRLMObject:dbFriend0]).andReturn(friend0);
    OCMStub([converterFriend objectFromRLMObject:dbFriend1]).andReturn(friend1);

    OCTDBCall *db = [OCTDBCall new];
    db.uniqueIdentifier = @"identifier";
    db.friends = (RLMArray<OCTDBFriend> *) @[ dbFriend0, dbFriend1 ];
    db.lastCall = dbLastCall;

    self.converter.converterFriend = converterFriend;
    self.converter.converterMessage = converterMessage;

    OCTCall *call = (OCTCall *)[self.converter objectFromRLMObject:db];

    XCTAssertEqual(call.friends.count, 2);
    XCTAssertEqual(call.lastCall.callDuration, 99);
    XCTAssertEqual(call.uniqueIdentifier, db.uniqueIdentifier);

}
@end
