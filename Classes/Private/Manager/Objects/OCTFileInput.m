//
//  OCTFileInput.m
//  objcTox
//
//  Created by stal on 5/8/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#include <sys/stat.h>
#import "DDLog.h"
#import "OCTSubmanagerFiles.h"

@interface OCTFileInput ()

@property (copy)   NSString *_filePath;
@property (strong) NSFileHandle *_readHandle;
@property OCTToxFileSize _knownFileSize;

@end

@implementation OCTFileInput

- (instancetype)initWithPath:(nonnull NSString *)path
{
    self = [super init];

    if (self) {
        self._filePath = path;
    }

    return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super init];

    if (self) {
        self._filePath = [aDecoder decodeObjectForKey:@"_filePath"];
    }

    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [aCoder encodeObject:self._filePath forKey:@"_filePath"];
}

#pragma mark - OCTFileSending

- (BOOL)transferWillBecomeActive:(nonnull OCTActiveFile *)file
{
    DDLogDebug(@"Opening %@", self._filePath);
    return [self openFileIfNeeded];
}

- (OCTToxFileSize)fileSize
{
    [self openFileIfNeeded];
    NSAssert(self._readHandle, @"File could not be opened.");

    int fd = self._readHandle.fileDescriptor;
    off_t currentPos = lseek(fd, 0, SEEK_CUR);
    self._knownFileSize = lseek(fd, 0, SEEK_END);
    lseek(fd, currentPos, SEEK_SET);

    return self._knownFileSize;
}

- (BOOL)moveToPosition:(OCTToxFileSize)offset
{
    @try {
        [self._readHandle seekToFileOffset:offset];
    }
    @catch (NSException *e) {
        DDLogError(@"OCTFileInput: seek failed... %@", e);
        return NO;
    }
    return YES;
}

- (size_t)readBytes:(OCTToxFileSize)chunk_size intoBuffer:(nonnull uint8_t *)buffer
{
    size_t actual = read(self._readHandle.fileDescriptor, buffer, chunk_size);
    return actual;
}

- (void)transferWillBecomeInactive:(nonnull OCTActiveFile *)file
{
    NSFileHandle *rh = self._readHandle;
    self._readHandle = nil;
    [rh closeFile];
}

- (void)transferWillComplete:(nonnull OCTActiveFile *)file
{
    // nothing!
}

#pragma mark - Private

- (BOOL)openFileIfNeeded
{
    if (self._readHandle) {
        return YES;
    }

    self._readHandle = [NSFileHandle fileHandleForReadingAtPath:self._filePath];

    if (! self._readHandle) {
        return NO;
    }

    struct stat info;
    if (fstat(self._readHandle.fileDescriptor, &info) == -1) {
        DDLogError(@"OCTFileInput: fstat() failed: %s", strerror(errno));
        [self._readHandle closeFile];
        return NO;
    }

    if ((info.st_mode & S_IFMT) != S_IFREG) {
        DDLogError(@"OCTFileInput: %@ is not a regular file", self._filePath);
        [self._readHandle closeFile];
        return NO;
    }

    return YES;
}

@end
