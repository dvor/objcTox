//
//  OCTFileOutput.m
//  objcTox
//
//  Created by stal on 11/7/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import "DDLog.h"
#import "OCTSubmanagerFiles.h"
#import "OCTFileStorageProtocol.h"

@interface OCTFileOutput ()

@property (copy)   NSString *_finalPathName;
@property (copy)   NSString *_temporaryPathName;
@property (strong) NSFileHandle *_writeHandle;

@end

@implementation OCTFileOutput

// Call this when the user asks OCTSubmanagerFiles for a default saver.
- (instancetype)_initWithConfigurator:(id<OCTFileStorageProtocol>)cf
{
    self = [super init];

    if (self) {
        NSString *uuid = [NSUUID UUID].UUIDString;
        self._finalPathName = [[cf pathForDownloadedFilesDirectory] stringByAppendingPathComponent:uuid];
        self._temporaryPathName = [self._finalPathName stringByAppendingPathExtension:@"partial"];
        DDLogDebug(@"OCTFileOutput writing to %@ using partial %@", self._finalPathName, self._temporaryPathName);
    }

    return self;
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];

    if (self) {
        self._finalPathName = path;
        self._temporaryPathName = [self._finalPathName stringByAppendingPathExtension:@"partial"];
    }

    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super init];

    if (self) {
        self._finalPathName = [aDecoder valueForKey:@"_finalPathName"];
        self._temporaryPathName = [aDecoder valueForKey:@"_temporaryPathName"];
    }

    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [aCoder encodeObject:self._finalPathName forKey:@"_finalPathName"];
    [aCoder encodeObject:self._temporaryPathName forKey:@"_temporaryPathName"];
}

#pragma mark - <OCTFileReceiving>

- (BOOL)transferWillBecomeActive:(nonnull OCTActiveFile *)file
{
    [[NSFileManager defaultManager] createFileAtPath:self._temporaryPathName contents:nil
#if TARGET_OS_IPHONE
                                          attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}
#else
     attributes:nil
#endif
    ];
    self._writeHandle = [NSFileHandle fileHandleForUpdatingAtPath:self._temporaryPathName];
    DDLogDebug(@"OCTFileOutput transferWillBecomeActive...");

    if (! self._writeHandle) {
        return NO;
    }

    return YES;
}

- (void)transferWillBecomeInactive:(nonnull OCTActiveFile *)file
{
    [self._writeHandle closeFile];
    self._writeHandle = nil;
    DDLogDebug(@"OCTFileOutput %@ closed.", self);
}

- (void)transferWillComplete:(nonnull OCTActiveFile *)file
{
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:self._temporaryPathName toPath:self._finalPathName error:&error];

    if (error) {
        DDLogError(@"OCTFileOutput ERROR: failed to move file to finalDestination. Error follows...");
        DDLogError(@"%@", error);
    }
    else {
        DDLogDebug(@"OCTFileOutput: File is now ready at %@. Thank you and come again", self._finalPathName);
    }
}

- (BOOL)moveToPosition:(OCTToxFileSize)offset
{
    @try {
        [self._writeHandle seekToFileOffset:offset];
    }
    @catch (NSException *exception) {
        DDLogWarn(@"OCTFileOutput WARNING: failed to seek to position %lu in file %@ [%@]. The file transfer will be aborted.",
                  (unsigned long)offset, self._writeHandle, self._temporaryPathName);
        return NO;
    }
    return YES;
}

- (void)writeBytes:(OCTToxFileSize)chunk_size fromBuffer:(nonnull const uint8_t *)buffer
{
    // possible 32bit bug: we are forcibly truncating chunk_size.
    // The good news is, we're never going to encounter a chunk that big.
    write(self._writeHandle.fileDescriptor, buffer, chunk_size);
    // [self._writeHandle writeData:[NSData dataWithBytesNoCopy:(uint8_t *)buffer length:(NSUInteger)chunk_size freeWhenDone:NO]];
}

- (NSString *)finalDestination
{
    return self._finalPathName;
}

@end
