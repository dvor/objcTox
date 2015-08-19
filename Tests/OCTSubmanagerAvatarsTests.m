//
//  OCTSubmanagerAvatarsTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "OCTSubmanagerAvatars.h"
#import "OCTFileStorageProtocol.h"
#import "OCTTox.h"

static NSString *const kFilePath = @"/path/For/Avatars/";
static NSString *const kuserAvatarFileName = @"user_avatar";
// static NSInteger kMaxDataLength = 16384;

@interface OCTSubmanagerAvatars (Tests)


@end

@interface OCTSubmanagerAvatarsTests : XCTestCase

@property (strong, nonatomic) OCTSubmanagerAvatars *subManagerAvatar;
@property (strong, nonatomic) id fileManager;
@property (strong, nonatomic) id tox;

@end

@implementation OCTSubmanagerAvatarsTests

// - (void)setUp
// {
//     self.subManagerAvatar = [[OCTSubmanagerAvatars alloc] init];

//     //mock datasource
//     self.subManagerAvatar.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));

//     //mock file storage
//     id fileStorageMock = OCMProtocolMock(@protocol(OCTFileStorageProtocol));
//     OCMStub([fileStorageMock pathForAvatarsDirectory]).andReturn(kFilePath);
//     OCMStub([self.subManagerAvatar.dataSource managerGetFileStorage]).andReturn(fileStorageMock);

//     //mock NSFileManager
//     self.fileManager = OCMClassMock([NSFileManager class]);
//     OCMStub([self.fileManager defaultManager]).andReturn(self.fileManager);

//     //mock Tox
//     self.tox = OCMClassMock([OCTTox class]);
//     OCMStub([self.subManagerAvatar.dataSource managerGetTox]).andReturn(self.tox);
//     OCMStub([self.tox maximumDataLengthForType:OCTToxDataLengthTypeAvatar]).andReturn(kMaxDataLength);

//     [super setUp];
//     // Put setup code here. This method is called before the invocation of each test method in the class.
// }

// - (void)tearDown
// {
//     // Put teardown code here. This method is called after the invocation of each test method in the class.
//     self.subManagerAvatar = nil;
//     [super tearDown];
// }

// - (void)testSetAvatarWithImage
// {
//     NSString *path = [kFilePath stringByAppendingPathComponent:kuserAvatarFileName];
//     OCMStub([self.fileManager fileExistsAtPath:path]).andReturn(NO);
//     OCMExpect([self.fileManager createDirectoryAtPath:[path stringByDeletingLastPathComponent]
//                           withIntermediateDirectories:YES
//                                            attributes:nil
//                                                 error:[OCMArg anyObjectRef]]);
//     OCMExpect([(OCTTox *)self.tox setAvatar:[OCMArg isNotNil]]);

//     UIImage *image = [self createFakeImage];

//     [self.subManagerAvatar setAvatar:image error:nil];

//     OCMVerifyAll(self.fileManager);
//     OCMVerifyAll(self.tox);
// }

// - (void)testSetAvatarWithNil
// {
//     NSString *path = [kFilePath stringByAppendingPathComponent:kuserAvatarFileName];
//     OCMStub([self.fileManager fileExistsAtPath:path]).andReturn(NO);

//     //fileManager should not remove anything if file does not exist
//     [[self.fileManager reject] removeItemAtPath:[OCMArg any]
//                                           error:[OCMArg anyObjectRef]];

//     OCMExpect([(OCTTox *)self.tox setAvatar:[OCMArg isNil]]);

//     NSError *error;
//     [self.subManagerAvatar setAvatar:nil error:&error];

//     //Verify key objects were called
//     OCMVerifyAll(self.fileManager);
//     OCMVerifyAll(self.tox);
// }

// - (void)testGetAvatar
// {
//     NSString *path = [kFilePath stringByAppendingPathComponent:kuserAvatarFileName];
//     OCMStub([self.fileManager fileExistsAtPath:path]).andReturn(NO);

//     XCTAssertNil([self.subManagerAvatar avatarWithError:nil]);
// }

// - (void)testHasAvatarWhenAvatarPresent
// {
//     NSString *path = [kFilePath stringByAppendingPathComponent:kuserAvatarFileName];
//     OCMStub([self.fileManager fileExistsAtPath:path]).andReturn(YES);
//     XCTAssertTrue([self.subManagerAvatar hasAvatar]);
// }

// - (void)testHasAvatarWhenNoAvatar
// {
//     NSString *path = [kFilePath stringByAppendingPathComponent:kuserAvatarFileName];

//     OCMStub([self.fileManager fileExistsAtPath:path]).andReturn(NO);
//     XCTAssertFalse([self.subManagerAvatar hasAvatar]);
// }

// - (void)testPNGDataFromImage
// {
//     NSData *data = [self.subManagerAvatar pngDataFromImage:[self createFakeImage]];

//     NSUInteger dataLength = [data length];
//     XCTAssertNotNil(data);
//     XCTAssertLessThan(dataLength, kMaxDataLength);
// }

// - (UIImage *)createFakeImage
// {
//     UIColor *color = [UIColor blackColor];
//     CGRect rect = CGRectMake(0, 0, 300, 300);
//     UIGraphicsBeginImageContext(rect.size);
//     CGContextRef context = UIGraphicsGetCurrentContext();

//     CGContextSetFillColorWithColor(context, [color CGColor]);
//     CGContextFillRect(context, rect);

//     UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//     UIGraphicsEndImageContext();

//     return image;
// }

@end
