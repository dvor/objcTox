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

- (void)_closeConduitIfNeeded
{
    if (! self.isConduitOpen) {
        return;
    }
    else {
        [self._conduit transferWillBecomeInactive:self];
        self.isConduitOpen = NO;
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

#pragma mark - Realm update stuff

- (void)_markFileAsCancelled:(OCTMessageFile *)file
{
    DDLogDebug(@"Marking file %@ as CANCELLED.", file);

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:file withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStateCanceled;
        theObject.filePosition = 0;
        theObject.restorationTag = nil;
        theObject.fileTag = nil;
        theObject.fileNumber = 0;
        theObject.filePath = nil;
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
}

- (void)_markFileAsCompleted:(OCTMessageFile *)file withFinalDestination:(NSString *)fd
{
    DDLogDebug(@"Marking file %@ as COMPLETE.", file);

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:file withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStateReady;
        theObject.restorationTag = nil;
        theObject.fileTag = nil;
        theObject.fileNumber = 0;
        theObject.filePosition = 0;
        theObject.filePath = fd;
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
}

- (void)_markFileAsPaused:(OCTMessageFile *)file withFlags:(OCTPauseFlags)flag
{
    DDLogDebug(@"Marking file %@ as PAUSED.", file);

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:file withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStatePaused;
        theObject.pauseFlags = flag;
        theObject.filePosition = self.bytesMoved;

        DDLogDebug(@"archiving resume data; if we die we're starting at offset %lld", theObject.filePosition);

        if ([self._conduit conformsToProtocol:@protocol(NSCoding)]) {
            theObject.restorationTag = [NSKeyedArchiver archivedDataWithRootObject:self._conduit];
        }
        else {
            theObject.restorationTag = nil;
        }
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
}

- (void)_resumeFile:(OCTMessageFile *)file
{
    [[self.fileManager.dataSource managerGetRealmManager] updateObject:self.fileMessage withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStateLoading;
        theObject.pauseFlags = OCTPauseFlagsNobody;
        theObject.filePosition = self.bytesMoved;

        DDLogDebug(@"archiving resume data; if we die we're starting at offset %lld", theObject.filePosition);

        if ([self._conduit conformsToProtocol:@protocol(NSCoding)]) {
            theObject.restorationTag = [NSKeyedArchiver archivedDataWithRootObject:self._conduit];
        }
        else {
            theObject.restorationTag = nil;
        }
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:self.fileMessage];
}

#pragma mark - Public API - Controls

- (BOOL)resumeWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    if ((self.fileMessage.fileState != OCTMessageFileStatePaused) &&
        (self.fileMessage.fileState != OCTMessageFileStateWaitingConfirmation) ) {
        // TODO make OCTFileError a constant symbol

        if (error) {
            NSString *failureReason = [NSString stringWithFormat:@"This file cannot be resumed while it is in this state. (Current state: %u. Valid states: %u.)", self.fileMessage.fileState, OCTMessageFileStatePaused];
            *error = [NSError errorWithDomain:@"OCTFileError" code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}];
        }

        return NO;
    }

    if (! [self _openConduitIfNeeded]) {
        DDLogWarn(@"OCTActiveFile WARNING: Couldn't prepare the conduit. The file transfer will be cancelled.");

        [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:nil];

        [self _markFileAsCancelled:self.fileMessage];

        if (error) {
            NSString *failureReason = @"The file data provider/receiver could not be opened.";
            *error = [NSError errorWithDomain:@"OCTFileError" code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}];
        }
        return NO;
    }

    [self _wipeCounters];

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlResume error:error];

    if (! ok) {
        return NO;
    }
    else {
        [self _resumeFile:self.fileMessage];
        DDLogInfo(@"OCTActiveFile: state changed to .Loading");
    }

    return YES;
}

- (BOOL)pauseWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlPause error:error];

    if (! ok) {
        return NO;
    }
    else {
        [self _closeConduitIfNeeded];
        [self _markFileAsPaused:self.fileMessage withFlags:self.fileMessage.pauseFlags | OCTPauseFlagsSelf];
        return YES;
    }
}

- (BOOL)cancelWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:&error];

    if (! ok) {
        return NO;
    }
    else {
        [self _closeConduitIfNeeded];
        [self _markFileAsCancelled:self.fileMessage];
        return YES;
    }
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

    [self _markFileAsCompleted:self.fileMessage withFinalDestination:[self.receiver finalDestination]];
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

- (void)_control:(OCTToxFileControl)ctl
{
    switch (ctl) {
        case OCTToxFileControlCancel:
            DDLogDebug(@"_control: obeying cancel message from remote.");
            [self _closeConduitIfNeeded];
            [self _markFileAsCancelled:self.fileMessage];
            break;
        case OCTToxFileControlPause:
            DDLogDebug(@"_control: obeying pause message from remote.");
            [self _closeConduitIfNeeded];
            [self _markFileAsPaused:self.fileMessage withFlags:self.fileMessage.pauseFlags | OCTPauseFlagsOther];
            break;
        case OCTToxFileControlResume: {
            DDLogDebug(@"_control: obeying resume message from remote.");
            if (self.fileMessage.pauseFlags == OCTPauseFlagsOther) {
                [self _openConduitIfNeeded];
                [self _resumeFile:self.fileMessage];
            }
            else {
                [self _closeConduitIfNeeded];
                [self _markFileAsPaused:self.fileMessage withFlags:OCTPauseFlagsSelf];
            }
            break;
        }
    }
}

@end

@implementation OCTActiveOutboundFile

- (id<OCTFileConduit>)_conduit
{
    return self.sender;
}

@end
