//
//  OCTActiveFile.m
//  objcTox
//
//  Created by stal on 9/7/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import "DDLog.h"
#import "OCTTox.h"
#import "OCTActiveFile+Variants.h"
#import "OCTSubmanagerFiles.h"
#import "OCTMessageFile.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerObjects+Private.h"
#import "OCTRealmManager.h"
#include <sys/sysctl.h>

time_t _OCTGetSystemUptime(void)
{
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};

    size_t size = sizeof(boottime);
    struct timeval now;

    gettimeofday(&now, NULL);

    time_t uptime = -1;
    if ((sysctl(mib, 2, &boottime, &size, NULL, 0) != -1) && (boottime.tv_sec != 0)) {
        uptime = now.tv_sec - boottime.tv_sec;
    }

    return uptime;
}

@implementation OCTActiveFile

@dynamic estimatedTimeRemaining;
@dynamic progress;
@dynamic bytesPerSecond;

- (instancetype)init
{
    self = [super init];
    if (! self) {
        return nil;
    }

    self.transferRateCounters = calloc(sizeof(OCTToxFileSize), AVERAGE_SECONDS);
    for (int i = 0; i < AVERAGE_SECONDS; ++i) {
        self.transferRateCounters[i] = -1;
    }

    return self;
}

- (void)dealloc
{
    free(self.transferRateCounters);
}

#pragma mark - Speed counting stuff

- (void)_incrementRollingIndex:(long)n
{
    for (int i = 0; i < n; ++i) {
        self.rollingIndex = (self.rollingIndex + 1) % AVERAGE_SECONDS;
        self.transferRateCounters[self.rollingIndex] = 0;
    }
}

- (void)_countBytes:(NSUInteger)size
{
    self.bytesMoved += size;

    time_t now = _OCTGetSystemUptime();
    time_t delta = now - self.lastCountedTime;
    self.lastCountedTime = now;

    NSAssert(delta >= 0, @"Detected a temporal anomaly. objcTox currently does not support Tox FTL, nor phone-microwave-"
             "based time travel. Please file a bug.");

    if (delta != 0) {
        [self _incrementRollingIndex:delta];
    }

    self.transferRateCounters[self.rollingIndex] += size;
}

- (void)_wipeCounters
{
    for (int i = 0; i < AVERAGE_SECONDS; ++i) {
        self.transferRateCounters[i] = -1;
    }
    self.lastCountedTime = _OCTGetSystemUptime();
}

#pragma mark - Private API

- (id<OCTFileConduit>)_conduit
{
    @throw [NSException exceptionWithName:@"OCTFileException" reason:@"Only subclasses of OCTActiveFile can be used." userInfo:nil];
    return nil;
}

- (BOOL)_openConduitIfNeeded
{
    if (! self.isConduitOpen) {
        BOOL ret = [self._conduit transferWillBecomeActive:self];

        if ([self._conduit respondsToSelector:@selector(moveToPosition:)]) {
            [self._conduit moveToPosition:self.bytesMoved];
        }

        self.isConduitOpen = ret;
        return ret;
    }
    else {
        return YES;
    }
}

- (void)setBytesMoved:(OCTToxFileSize)bytesMoved
{
    _bytesMoved = bytesMoved;
}

- (void)_sendProgressUpdateNow
{
    if (self.notificationBlock) {
        self.notificationBlock(self);
    }
}

#pragma mark - Public API

#pragma mark - Public API - Counters

- (double)progress
{
    return (double)self.bytesMoved / self.fileSize;
}

- (NSTimeInterval)estimatedTimeRemaining
{
    // i'm not big on math, but this should be correct

    OCTToxFileSize bps = self.bytesPerSecond;
    if (bps != 0) {
        return (self.fileSize - self.bytesMoved) / bps;
    }
    else {
        return -1;
    }
}

- (OCTToxFileSize)bytesPerSecond
{
    OCTToxFileSize accumulator = 0;
    OCTToxFileSize divisor = 0;

    for (int i = 0; i < AVERAGE_SECONDS; ++i) {
        if (self.transferRateCounters[i] != -1) {
            accumulator += self.transferRateCounters[i];
            divisor++;
        }
    }

    if (divisor == 0) {
        return 0;
    }
    else {
        return accumulator / divisor;
    }
}

- (void)beginReceivingLiveUpdatesWithBlock:(void (^)(OCTActiveFile *))blk
{
    self.notificationBlock = blk;
}

#pragma mark - Public API - Controls

- (BOOL)resumeWithError:(NSError *__autoreleasing *)error
{
    BOOL hasError = NO;
    if (error && *error) {
        *error = nil;
    }

    if ((self.fileMessage.fileState != OCTMessageFileStatePaused) &&
        (self.fileMessage.fileState != OCTMessageFileStateWaitingConfirmation) ) {
        @throw [NSException exceptionWithName:@"OCTFileException" reason:@"You cannot resume a file in this state." userInfo:nil];
        return 0;
    }

    if (! [self _openConduitIfNeeded]) {
        DDLogWarn(@"OCTActiveFile WARNING: Couldn't prepare the conduit. The file transfer will be cancelled.");
        [[self.fileManager.dataSource managerGetRealmManager] updateObject:self.fileMessage withBlock:^(OCTMessageFile *theObject) {
            theObject.fileState = OCTMessageFileStateCanceled;
            theObject.filePosition = 0;
            theObject.restorationTag = nil;
        }];
        [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:self.fileMessage];

        [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:nil];
        return NO;
    }

    [self _wipeCounters];
    [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlResume error:error];

    if (error && *error) {
        hasError = YES;
        NSAssert(*error == nil, @"Describe this later");
    }
    else {
        [[self.fileManager.dataSource managerGetRealmManager] updateObject:self.fileMessage withBlock:^(OCTMessageFile *theObject) {
            theObject.fileState = OCTMessageFileStateLoading;
            theObject.filePosition = self.bytesMoved;

            if ([self._conduit conformsToProtocol:@protocol(NSCoding)]) {
                theObject.restorationTag = [NSKeyedArchiver archivedDataWithRootObject:self._conduit];
            }
            else {
                theObject.restorationTag = nil;
            }
        }];
        [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:self.fileMessage];
        DDLogInfo(@"OCTActiveFile: state changed to .Loading");
    }

    return hasError;
}

- (BOOL)pauseWithError:(NSError *__autoreleasing *)error
{
    BOOL hasError = NO;

    [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlPause error:error];

    [self._conduit transferWillBecomeInactive:self];
    self.isConduitOpen = NO;

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:self.fileMessage withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStatePaused;
        theObject.filePosition = self.bytesMoved;

        if ([self._conduit conformsToProtocol:@protocol(NSCoding)]) {
            theObject.restorationTag = [NSKeyedArchiver archivedDataWithRootObject:self._conduit];
        }
        else {
            theObject.restorationTag = nil;
        }
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:self.fileMessage];

    return hasError;
}

- (BOOL)cancelWithError:(NSError *__autoreleasing *)error
{
    return 0;
}

@end

@implementation OCTActiveInboundFile

- (id<OCTFileConduit>)_conduit
{
    return self.receiver;
}

- (void)_completeFileTransferAndClose
{
    [self.receiver transferWillBecomeInactive:self];
    [self.receiver transferWillComplete:self];

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:self.fileMessage withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStateReady;
        theObject.restorationTag = nil;
        theObject.fileTag = nil;
        theObject.fileNumber = 0;
        theObject.filePosition = 0;
        theObject.filePath = [self.receiver finalDestination];
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:self.fileMessage];
}

- (void)_receiveChunkNow:(NSData *)chunk atPosition:(OCTToxFileSize)p
{
    // NSLog(@"_receiveChunkNow at %ld", _OCTGetSystemUptime());
    if (p != self.bytesMoved + 1) {
        if ([self.receiver respondsToSelector:@selector(moveToPosition:)]) {
            [self.receiver moveToPosition:p];
        }
        else {
            DDLogWarn(@"OCTActiveInBoundFile WARNING: receiver %@ does not support seeking, but we received out of order file chunk for position %llu."
                      "(I think the file position is %llu.) The file transfer will be corrupted.", self.receiver, p, self.bytesMoved + 1);
        }
    }

    [self _countBytes:chunk.length];
    [self.receiver writeBytes:chunk.length fromBuffer:chunk.bytes];
    [self _sendProgressUpdateNow];
}

@end

@implementation OCTActiveOutboundFile

- (id<OCTFileConduit>)_conduit
{
    return self.sender;
}

@end
