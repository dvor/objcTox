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

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_DEBUG

@interface OCTFileOutput ()

@property (copy, atomic)   NSString *_finalPathName;
@property (copy, atomic)   NSString *_temporaryPathName;
@property (strong, atomic) NSFileHandle *_writeHandle;

@end

@implementation OCTFileOutput

// Call this when the user asks OCTSubmanagerFiles for a default saver.
- (instancetype)initWithConfigurator:(id<OCTFileStorageProtocol>)cf
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
        self._finalPathName = [aDecoder decodeObjectForKey:@"_finalPathName"];
        self._temporaryPathName = [aDecoder decodeObjectForKey:@"_temporaryPathName"];
    }

    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [aCoder encodeObject:self._finalPathName forKey:@"_finalPathName"];
    [aCoder encodeObject:self._temporaryPathName forKey:@"_temporaryPathName"];
}

#pragma mark - <OCTFileConduit>

- (BOOL)transferWillBecomeActive:(nonnull OCTActiveFile *)file
{
    if (! [[NSFileManager defaultManager] fileExistsAtPath:self._temporaryPathName]) {
        [[NSFileManager defaultManager] createFileAtPath:self._temporaryPathName contents:nil
#if TARGET_OS_IPHONE
                                              attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}
#else
         attributes:nil
#endif
        ];
    }
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
    BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:self._temporaryPathName toPath:self._finalPathName error:&error];

    if (!ok) {
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

- (BOOL)canBeResumedNow
{
    // TODO: do something about crashes, etc. where it's not possible to determine the file's state.
    return YES;
}

#pragma mark - <OCTFileReceiving>

- (void)writeBytes:(OCTToxFileSize)chunk_size fromBuffer:(nonnull const uint8_t *)buffer
{
    // possible 32bit bug: we are forcibly truncating chunk_size.
    // The good news is, we're never going to encounter a chunk that big.
    write(self._writeHandle.fileDescriptor, buffer, (size_t)chunk_size);
}

- (NSString *)finalDestination
{
    return self._finalPathName;
}

@end
