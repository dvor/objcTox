//
//  OCTDefaultFileStorageTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "OCTDefaultFileStorage.h"

@interface OCTDefaultFileStorageTests : XCTestCase

@end

@implementation OCTDefaultFileStorageTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testProperties
{
    OCTDefaultFileStorage *storage = [[OCTDefaultFileStorage alloc] initWithBaseDirectory:@"/base"
                                                                       temporaryDirectory:@"/temp"];

    XCTAssertEqualObjects(storage.pathForToxSaveFile, @"/base/save.tox");
    XCTAssertEqualObjects(storage.pathForDatabase, @"/base/database");
    XCTAssertEqualObjects(storage.pathForDownloadedFilesDirectory, @"/base/downloads");
    XCTAssertEqualObjects(storage.pathForUploadedFilesDirectory, @"/base/uploads");
    XCTAssertEqualObjects(storage.pathForTemporaryFilesDirectory, @"/temp");
    XCTAssertEqualObjects(storage.pathForAvatarsDirectory, @"/base/avatars");
}

- (void)testCustomToxSaveFileName
{
    OCTDefaultFileStorage *storage = [[OCTDefaultFileStorage alloc] initWithToxSaveFileName:@"filename"
                                                                              baseDirectory:@"/base"
                                                                         temporaryDirectory:@"/temp"];

    XCTAssertEqualObjects(storage.pathForToxSaveFile, @"/base/filename.tox");
}

@end
