//
//  OCTDefaultSettingsStorageTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 07.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTDefaultSettingsStorage.h"

static NSString *const kDictionaryKey = @"kDictionaryKey";

@interface OCTDefaultSettingsStorageTests : XCTestCase

@property (strong, nonatomic) OCTDefaultSettingsStorage *storage;

@end

@implementation OCTDefaultSettingsStorageTests

- (void)setUp
{
    self.storage = [[OCTDefaultSettingsStorage alloc] initWithUserDefaultsKey:kDictionaryKey];
    [super setUp];
}

- (void)tearDown
{
    self.storage = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.storage, @"Storage should be not nil");
    XCTAssertEqualObjects(self.storage.userDefaultsKey, kDictionaryKey, @"userDefaultsKey should be set to key specified in init");
}

- (void)testSetObjectForKey
{
    NSString *object = @"object";
    NSString *forKey = @"forKey";

    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);

    id objectArg = [OCMArg checkWithBlock:^BOOL (id value) {
        if (! [value isKindOfClass:[NSDictionary class]]) {
            return NO;
        }

        NSDictionary *dict = value;

        if (dict.count != 1) {
            return NO;
        }

        if (! [dict[forKey] isEqualToString:object]) {
            return NO;
        }

        return YES;
    }];

    OCMExpect([userDefaultsMock setObject:objectArg forKey:kDictionaryKey]);
    OCMExpect([userDefaultsMock synchronize]);

    [self.storage setObject:object forKey:forKey];

    OCMVerifyAll(userDefaultsMock);
}

- (void)testSetObjectForKey2
{
    NSString *object = @"object";
    NSString *forKey = @"forKey";

    NSString *object2 = @"object2";
    NSString *forKey2 = @"forKey2";

    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);

    id objectArg = [OCMArg checkWithBlock:^BOOL (id value) {
        if (! [value isKindOfClass:[NSDictionary class]]) {
            return NO;
        }

        NSDictionary *dict = value;

        if (dict.count != 2) {
            return NO;
        }

        if (! [dict[forKey] isEqualToString:object]) {
            return NO;
        }

        if (! [dict[forKey2] isEqualToString:object2]) {
            return NO;
        }

        return YES;
    }];

    NSDictionary *dict = @{ forKey2 : object2 };
    OCMStub([userDefaultsMock objectForKey:kDictionaryKey]).andReturn(dict);
    OCMExpect([userDefaultsMock setObject:objectArg forKey:kDictionaryKey]);
    OCMExpect([userDefaultsMock synchronize]);

    [self.storage setObject:object forKey:forKey];

    OCMVerifyAll(userDefaultsMock);
}

- (void)testObjectForKey
{
    NSString *object = @"object";
    NSString *forKey = @"forKey";
    NSDictionary *dict = @{ forKey : object };

    id userDefaultsMock = OCMClassMock([NSUserDefaults class]);
    OCMStub([userDefaultsMock standardUserDefaults]).andReturn(userDefaultsMock);
    OCMStub([userDefaultsMock objectForKey:kDictionaryKey]).andReturn(dict);

    id result = [self.storage objectForKey:forKey];

    XCTAssertEqualObjects(result, object);
}

@end
