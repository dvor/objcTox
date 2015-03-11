//
//  OCTSubmanagerAvatars.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 08.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerAvatars.h"
#import "OCTFileStorageProtocol.h"
#import "OCTTox.h"

static NSString *const kuserAvatarFileName = @"user_avatar";

@interface OCTSubmanagerAvatars()

@end

@implementation OCTSubmanagerAvatars

#pragma mark -  OCTManagerAvatarsProtocol

- (BOOL)setAvatar:(UIImage *)avatar error:(NSError **)error;
{
    id <OCTFileStorageProtocol> storage = [self.dataSource managerGetFileStorage];
    NSString *path = [storage.pathForAvatarsDirectory stringByAppendingPathComponent:kuserAvatarFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }

    OCTTox *tox = [self.dataSource managerGetTox];
    NSData *data = nil;

    BOOL success = false;
    if (avatar) {
        data = [self pngDataFromImage:avatar];
        [fileManager createDirectoryAtPath:[path stringByDeletingLastPathComponent]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:error];
        success = [data writeToFile:path atomically:NO];
    }
    
    [tox setAvatar:data];
    return success;
}

- (UIImage *)avatar
{
    id <OCTFileStorageProtocol> storage = [self.dataSource managerGetFileStorage];
    NSString *path = [storage.pathForAvatarsDirectory stringByAppendingPathComponent:kuserAvatarFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:path]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *avatar = [UIImage imageWithData:data];
        return avatar;
    }
    return nil;
}

- (BOOL)hasAvatar
{
    id <OCTFileStorageProtocol> storage = [self.dataSource managerGetFileStorage];
    NSString *path = [storage.pathForAvatarsDirectory stringByAppendingPathComponent:kuserAvatarFileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    return ([fileManager fileExistsAtPath:path]);
}

#pragma mark - Private Method

- (NSData *)pngDataFromImage:(UIImage *)image
{
    CGSize imageSize = image.size;

    // Maximum png size will be (4 * width * height)
    // * 1.5 to get as big avatar size as possible

    OCTTox *tox = [self.dataSource managerGetTox];
    NSUInteger maxDataLength = [tox maximumDataLengthForType:OCTToxDataLengthTypeAvatar];
    while (4 * imageSize.width * imageSize.height > maxDataLength * 1.5) {
        imageSize.width *= 0.9;
        imageSize.height *= 0.9;
    }

    imageSize.width = (int)imageSize.width;
    imageSize.height = (int)imageSize.height;
    NSData *data = nil;

    do {

        UIGraphicsBeginImageContext(imageSize);
        [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        data = UIImagePNGRepresentation(image);

        imageSize.width *= 0.9;
        imageSize.height *= 0.9;
    } while (data.length > maxDataLength);
    
    return data;
}

#pragma mark -  OCTToxDelegate

- (void)tox:(OCTTox *)tox friendAvatarHashUpdate:(NSData *)hash friendNumber:(int32_t)friendNumber
{
    // TODO
}

- (void)tox:(OCTTox *)tox friendAvatarUpdate:(NSData *)avatar hash:(NSData *)hash friendNumber:(int32_t)friendNumber
{
    // TODO
}

@end
