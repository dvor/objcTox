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

static NSString *const kPartialFileExtension = @"partial";
static NSString *const kTemporaryPathKey = @"temporaryPathName";
static NSString *const kFinalPathKey = @"finalPathName";

@interface OCTFileOutput ()

@property (copy, atomic)   NSString *finalPathName;
@property (copy, atomic)   NSString *temporaryPathName;
@property (strong, atomic) NSFileHandle *writeHandle;

@end

@implementation OCTFileOutput

// Call this when the user asks OCTSubmanagerFiles for a default saver.
- (instancetype)initWithConfigurator:(id<OCTFileStorageProtocol>)cf
{
    self = [super init];

    if (self) {
        NSString *uuid = [NSUUID UUID].UUIDString;
        self.finalPathName = [[cf pathForDownloadedFilesDirectory] stringByAppendingPathComponent:uuid];
        self.temporaryPathName = [self.finalPathName stringByAppendingPathExtension:kPartialFileExtension];
        DDLogDebug(@"OCTFileOutput writing to %@ using partial %@", self.finalPathName, self.temporaryPathName);
    }

    return self;
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];

    if (self) {
        self.finalPathName = path;
        self.temporaryPathName = [self.finalPathName stringByAppendingPathExtension:kPartialFileExtension];
    }

    return self;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super init];

    if (self) {
        self.finalPathName = [aDecoder decodeObjectForKey:kFinalPathKey];
        self.temporaryPathName = [aDecoder decodeObjectForKey:kTemporaryPathKey];
    }

    if (! self.finalPathName || ! self.temporaryPathName) {
        return nil;
    }

    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [aCoder encodeObject:self.finalPathName forKey:kFinalPathKey];
    [aCoder encodeObject:self.temporaryPathName forKey:kTemporaryPathKey];
}

#pragma mark - <OCTFileConduit>

- (BOOL)transferWillBecomeActive:(nonnull OCTActiveFile *)file
{
    if (! [[NSFileManager defaultManager] fileExistsAtPath:self.temporaryPathName]) {
        [[NSFileManager defaultManager] createFileAtPath:self.temporaryPathName contents:nil
#if TARGET_OS_IPHONE
                                              attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}
#else
         attributes:nil
#endif
        ];
    }
    self.writeHandle = [NSFileHandle fileHandleForUpdatingAtPath:self.temporaryPathName];
    DDLogDebug(@"OCTFileOutput transferWillBecomeActive...");

    if (! self.writeHandle) {
        return NO;
    }

    return YES;
}

- (void)transferWillBecomeInactive:(nonnull OCTActiveFile *)file
{
    [self.writeHandle closeFile];
    self.writeHandle = nil;
    DDLogDebug(@"OCTFileOutput %@ closed.", self);
}

- (void)transferWillComplete:(nonnull OCTActiveFile *)file
{
    NSError *error = nil;
    BOOL ok = [[NSFileManager defaultManager] moveItemAtPath:self.temporaryPathName toPath:self.finalPathName error:&error];

    if (! ok) {
        DDLogError(@"OCTFileOutput ERROR: failed to move file to finalDestination. Error follows...");
        DDLogError(@"%@", error);
    }
    else {
        DDLogDebug(@"OCTFileOutput: File is now ready at %@. Thank you and come again", self.finalPathName);
    }
}

- (BOOL)moveToPosition:(OCTToxFileSize)offset
{
    @try {
        [self.writeHandle seekToFileOffset:offset];
    }
    @catch (NSException *exception) {
        DDLogWarn(@"OCTFileOutput WARNING: failed to seek to position %lu in file %@ [%@]. The file transfer will be aborted.",
                  (unsigned long)offset, self.writeHandle, self.temporaryPathName);
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
    write(self.writeHandle.fileDescriptor, buffer, (size_t)chunk_size);
}

- (NSString *)finalDestination
{
    return self.finalPathName;
}

@end
