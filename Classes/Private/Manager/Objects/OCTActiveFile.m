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

/* these are annoying, and because we get all file numbers from toxcore,
 * casting will never truncate them because they were never longs to begin
 * with. */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

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
    DDLogDebug(@"OCTActiveFile dealloc");
    free(self.transferRateCounters);
}

#pragma mark - Speed counting stuff

- (void)_incrementRollingIndex:(long)n
{
    @synchronized(self) {
        for (int i = 0; i < n; ++i) {
            self.rollingIndex = (self.rollingIndex + 1) % AVERAGE_SECONDS;
            self.transferRateCounters[self.rollingIndex] = 0;
        }
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
    @synchronized(self) {
        for (int i = 0; i < AVERAGE_SECONDS; ++i) {
            self.transferRateCounters[i] = -1;
        }
        self.lastCountedTime = _OCTGetSystemUptime();
    }
}

#pragma mark - Private API

- (id<OCTFileConduit>)_conduit
{
    @throw [NSException exceptionWithName:@"OCTFileException" reason:@"Only subclasses of OCTActiveFile can be used." userInfo:nil];
    return nil;
}

- (void)_control:(OCTToxFileControl)ctl
{
    switch (ctl) {
        case OCTToxFileControlCancel: {
            DDLogDebug(@"_control: obeying cancel message from remote.");

            dispatch_async(self.fileManager.queue, ^{
                [self _closeConduitIfNeeded];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.fileManager removeFile:self];
                });
            });
            [self _markFileAsCancelled:self.fileMessage];
            break;
        }
        case OCTToxFileControlPause:
            DDLogDebug(@"_control: obeying pause message from remote.");
            [self _markFileAsPaused:self.fileMessage withFlags:self.fileMessage.pauseFlags | OCTPauseFlagsOther];
            break;
        case OCTToxFileControlResume: {
            DDLogDebug(@"_control: obeying resume message from remote.");
            if (self.fileMessage.pauseFlags == OCTPauseFlagsOther) {
                dispatch_sync(self.fileManager.queue, ^{
                    [self _openConduitIfNeeded];
                });
                [self _resumeFile:self.fileMessage];
            }
            else {
                [self _markFileAsPaused:self.fileMessage withFlags:OCTPauseFlagsSelf];
            }
            break;
        }
    }
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

- (void)_sendProgressUpdateNow
{
    // don't post a notification if we're paused
    // (sometimes one manages to sneak in after we've updated the state in realm,
    //  and it messes up my client code...)
    if (self.notificationBlock && (self.fileMessage.fileState == OCTMessageFileStateLoading)) {
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

    @synchronized(self) {
        for (int i = 0; i < AVERAGE_SECONDS; ++i) {
            if ((self.transferRateCounters[i] != -1) && (i != self.rollingIndex)) {
                accumulator += self.transferRateCounters[i];
                divisor++;
            }
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
        // theObject.fileNumber = 0;
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
        // theObject.fileNumber = 0;
        theObject.filePosition = 0;
        theObject.filePath = fd;
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
}

- (void)_markFileAsPaused:(OCTMessageFile *)file withFlags:(OCTPauseFlags)flag
{
    DDLogDebug(@"Marking file %@ as PAUSED.", file);

    DDLogDebug(@"archiving resume data; if we die we're starting at offset %lld", self.bytesMoved);

    NSData *conduitData = nil;
    if ([self._conduit conformsToProtocol:@protocol(NSCoding)]) {
        conduitData = [NSKeyedArchiver archivedDataWithRootObject:self._conduit];
    }

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:file withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStatePaused;
        theObject.pauseFlags = flag;
        theObject.filePosition = self.bytesMoved;
        theObject.restorationTag = conduitData;
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
}

- (void)_resumeFile:(OCTMessageFile *)file
{
    DDLogDebug(@"archiving resume data; if we die we're starting at offset %lld", self.bytesMoved);

    NSData *conduitData = nil;
    if ([self._conduit conformsToProtocol:@protocol(NSCoding)]) {
        conduitData = [NSKeyedArchiver archivedDataWithRootObject:self._conduit];
    }

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:file withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStateLoading;
        theObject.pauseFlags = OCTPauseFlagsNobody;
        theObject.filePosition = self.bytesMoved;
        theObject.restorationTag = conduitData;
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
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
            NSString *failureReason = [NSString stringWithFormat:@"This file cannot be resumed while it is in this state. (Current state: %ld. Valid states: %ld.)", (long)self.fileMessage.fileState, (long)OCTMessageFileStatePaused];
            *error = [NSError errorWithDomain:@"OCTFileError" code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}];
        }

        return NO;
    }

    __block BOOL openOK = NO;
    dispatch_sync(self.fileManager.queue, ^{
        openOK = [self _openConduitIfNeeded];
    });

    if (! openOK) {
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
        if ((self.fileMessage.pauseFlags == OCTPauseFlagsSelf) || (self.fileMessage.pauseFlags == OCTPauseFlagsNobody)) {
            [self _resumeFile:self.fileMessage];
            DDLogInfo(@"OCTActiveFile: no further blocks on file so transitioning to Loading state.");
        }
        else {
            [self _markFileAsPaused:self.fileMessage withFlags:OCTPauseFlagsOther];
            DDLogInfo(@"OCTActiveFile: we're no longer pausing this file, but our friend still is.");
        }
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

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:error];

    if (! ok) {
        return NO;
    }
    else {
        dispatch_async(self.fileManager.queue, ^{
            [self _closeConduitIfNeeded];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.fileManager removeFile:self];
            });
        });
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

    dispatch_async(dispatch_get_main_queue(), ^{
        [self _markFileAsCompleted:self.fileMessage withFinalDestination:[self.receiver finalDestination]];
        [self.fileManager removeFile:self];
    });
}

- (void)_receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p
{
    // NSLog(@"_receiveChunkNow at %ld", _OCTGetSystemUptime());
    if (p != self.bytesMoved + 1) {
        if ([self.receiver respondsToSelector:@selector(moveToPosition:)]) {
            [self.receiver moveToPosition:p];
        }
        else {
            DDLogWarn(@"OCTActiveInBoundFile WARNING: receiver %@ does not support seeking, but we received out of order file chunk for position %llu."
                      "(I think the file position is %llu.) The file will be corrupted.", self.receiver, p, self.bytesMoved + 1);
        }
    }

    [self.receiver writeBytes:length fromBuffer:chunk];
    [self _countBytes:length];
    [self.fileManager scheduleProgressNotificationForFile:self];
}

@end

@implementation OCTActiveOutboundFile

- (id<OCTFileConduit>)_conduit
{
    return self.sender;
}

- (void)_completeFileTransferAndClose
{
    [self.sender transferWillBecomeInactive:self];
    [self.sender transferWillComplete:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self _markFileAsCompleted:self.fileMessage withFinalDestination:[self.sender path]];
        [self.fileManager removeFile:self];
    });
}

- (void)_sendChunkForSize:(size_t)csize fromPosition:(OCTToxFileSize)p
{
    if (p != self.bytesMoved + 1) {
        if ([self.sender respondsToSelector:@selector(moveToPosition:)]) {
            [self.sender moveToPosition:p];
        }
        else {
            DDLogWarn(@"OCTActiveInBoundFile WARNING: receiver %@ does not support seeking, but we received out of order file chunk for position %llu."
                      "(I think the file position is %llu.) The file will be corrupted.", self.sender, p, self.bytesMoved + 1);
        }
        self.bytesMoved = p;
    }

    /* The csize should be small enough that the risk of blowing the stack is
     * minimal however this is a toxcore implementation detail. */
    uint8_t buf[csize];

    size_t actual = [self.sender readBytes:csize intoBuffer:buf];
    DDLogDebug(@"_sendChunkForSize: %zu", actual);
    [[self.fileManager.dataSource managerGetTox] fileSendChunk:buf forFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber position:p length:actual error:nil];
    [self _countBytes:actual];
    [self.fileManager scheduleProgressNotificationForFile:self];
}

@end

#pragma clang diagnostic pop
