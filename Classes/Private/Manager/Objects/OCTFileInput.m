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

@property (copy)   NSString *path;
@property (strong) NSFileHandle *readHandle;
@property OCTToxFileSize knownFileSize;

@end

@implementation OCTFileInput

- (instancetype)initWithPath:(nonnull NSString *)path
{
    self = [super init];

    if (self) {
        self.path = path;
    }

    return self;
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super init];

    if (self) {
        self.path = [aDecoder decodeObjectForKey:@"_filePath"];
    }

    return self;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [aCoder encodeObject:self.path forKey:@"_filePath"];
}

#pragma mark - OCTFileSending

- (BOOL)transferWillBecomeActive:(nonnull OCTActiveFile *)file
{
    DDLogDebug(@"Opening %@", self.path);
    return [self openFileIfNeeded];
}

- (OCTToxFileSize)fileSize
{
    [self openFileIfNeeded];
    NSAssert(self.readHandle, @"File could not be opened.");

    int fd = self.readHandle.fileDescriptor;
    off_t currentPos = lseek(fd, 0, SEEK_CUR);
    self.knownFileSize = lseek(fd, 0, SEEK_END);
    lseek(fd, currentPos, SEEK_SET);

    return self.knownFileSize;
}

- (BOOL)moveToPosition:(OCTToxFileSize)offset
{
    @try {
        [self.readHandle seekToFileOffset:offset];
    }
    @catch (NSException *e) {
        DDLogError(@"OCTFileInput: seek failed... %@", e);
        return NO;
    }
    return YES;
}

- (size_t)readBytes:(OCTToxFileSize)chunk_size intoBuffer:(nonnull uint8_t *)buffer
{
    size_t actual = read(self.readHandle.fileDescriptor, buffer, chunk_size);
    return actual;
}

- (void)transferWillBecomeInactive:(nonnull OCTActiveFile *)file
{
    NSFileHandle *rh = self.readHandle;
    self.readHandle = nil;
    [rh closeFile];
}

- (void)transferWillComplete:(nonnull OCTActiveFile *)file
{
    // nothing!
}

#pragma mark - Private

- (BOOL)openFileIfNeeded
{
    if (self.readHandle) {
        return YES;
    }

    self.readHandle = [NSFileHandle fileHandleForReadingAtPath:self.path];

    if (! self.readHandle) {
        return NO;
    }

    struct stat info;
    if (fstat(self.readHandle.fileDescriptor, &info) == -1) {
        DDLogError(@"OCTFileInput: fstat() failed: %s", strerror(errno));
        [self.readHandle closeFile];
        return NO;
    }

    if ((info.st_mode & S_IFMT) != S_IFREG) {
        DDLogError(@"OCTFileInput: %@ is not a regular file", self.path);
        [self.readHandle closeFile];
        return NO;
    }

    return YES;
}

@end
