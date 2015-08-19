//
//  OCTRealmTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <OCMock/OCMock.h>

#import "OCTRealmTests.h"

@implementation OCTRealmTests

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

    self.realmManager = [[OCTRealmManager alloc] initWithDatabasePath:realmPath];
    self.realmManager = OCMPartialMock(self.realmManager);
}

- (void)tearDown
{
    NSString *realmPath = [self realmPath];
    NSString *lockPath = [realmPath stringByAppendingString:@".lock"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:realmPath error:nil];
    [fileManager removeItemAtPath:lockPath error:nil];

    self.realmManager = nil;
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (OCTFriend *)createFriend
{
    OCTFriend *friend = [OCTFriend new];
    friend.nickname = @"";
    friend.publicKey = @"";

    return friend;
}

@end
