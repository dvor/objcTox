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

#include <mach/clock.h>
#include <mach/mach_host.h>
#include <mach/mach_port.h>

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_DEBUG

/* these are annoying, and because we get all file numbers from toxcore,
 * casting will never truncate them because they were never longs to begin
 * with. */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

static const int kMillisecondsPerSecond = 1000;
// in milliseconds
static const int kProgressUpdateInterval = 100;
static const int kSecondsToAverage = 10;

/* returns milliseconds */
static unsigned long OCTGetMonotonicTime(void)
{
    clock_serv_t muhclock;
    mach_timespec_t machtime;

    host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &muhclock);
    clock_get_time(muhclock, &machtime);
    mach_port_deallocate(mach_task_self(), muhclock);

    return (machtime.tv_sec * kMillisecondsPerSecond) + (machtime.tv_nsec / NSEC_PER_MSEC);
}

@interface OCTActiveFile ()

@property (readwrite) OCTToxFileSize bytesMoved;
@property (atomic)    BOOL isConduitOpen;

@property (atomic)    unsigned long lastCountedTime;
@property (atomic)    unsigned long lastProgressUpdateTime;
@property (atomic)    OCTToxFileSize *transferRateCounters;
@property (atomic)    long rollingIndex;

@property (copy)      OCTFileNotificationBlock notificationBlock;

@end

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

    self.transferRateCounters = malloc(sizeof(OCTToxFileSize) * kSecondsToAverage);
    for (int i = 0; i < kSecondsToAverage; ++i) {
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

- (void)incrementRollingIndex:(long)n
{
    @synchronized(self) {
        for (int i = 0; i < n; ++i) {
            self.rollingIndex = (self.rollingIndex + 1) % kSecondsToAverage;
            self.transferRateCounters[self.rollingIndex] = 0;
        }
    }
}

- (void)countBytes:(NSUInteger)size
{
    unsigned long now = OCTGetMonotonicTime();
    unsigned long avgdelta = now - self.lastCountedTime;
    unsigned long progressdelta = now - self.lastProgressUpdateTime;

    NSAssert(avgdelta >= 0, @"Detected a temporal anomaly. objcTox currently does not support Tox FTL, nor phone-microwave-"
             "based time travel. Please file a bug.");

    if (avgdelta >= kMillisecondsPerSecond) {
        [self incrementRollingIndex:avgdelta / kMillisecondsPerSecond];
        self.lastCountedTime = now;
    }

    self.bytesMoved += size;
    self.transferRateCounters[self.rollingIndex] += size;

    if (progressdelta >= kProgressUpdateInterval) {
        self.lastProgressUpdateTime = now;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendProgressUpdateNow];
        });
    }
}

- (void)wipeCounters
{
    @synchronized(self) {
        for (int i = 0; i < kSecondsToAverage; ++i) {
            self.transferRateCounters[i] = -1;
        }
    }
    unsigned long t = OCTGetMonotonicTime();
    self.lastCountedTime = t;
    self.lastProgressUpdateTime = t;
}

#pragma mark - Private API

- (id<OCTFileConduit>)conduit
{
    @throw [NSException exceptionWithName:@"OCTFileException" reason:@"Only subclasses of OCTActiveFile can be used." userInfo:nil];
    return nil;
}

- (void)control:(OCTToxFileControl)ctl
{
    switch (ctl) {
        case OCTToxFileControlCancel: {
            DDLogDebug(@"_control: obeying cancel message from remote.");

            dispatch_async(self.fileManager.queue, ^{
                [self closeConduitIfNeeded];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.fileManager removeFile:self];
                });
            });
            [self markFileAsCancelled:self.fileMessage];
            break;
        }
        case OCTToxFileControlPause:
            DDLogDebug(@"_control: obeying pause message from remote.");
            [self markFileAsPaused:self.fileMessage withFlags:self.fileMessage.pauseFlags | OCTPauseFlagsOther];
            break;
        case OCTToxFileControlResume: {
            DDLogDebug(@"_control: obeying resume message from remote.");
            if (self.fileMessage.pauseFlags == OCTPauseFlagsOther) {
                dispatch_sync(self.fileManager.queue, ^{
                    [self openConduitIfNeeded];
                });
                [self resumeFile:self.fileMessage];
            }
            else {
                [self markFileAsPaused:self.fileMessage withFlags:OCTPauseFlagsSelf];
            }
            break;
        }
    }
}

- (void)interrupt
{
    dispatch_async(self.fileManager.queue, ^{
        [self closeConduitIfNeeded];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fileManager removeFile:self];
        });
    });

    [self markFileAsInterrupted:self.fileMessage];
}

- (BOOL)openConduitIfNeeded
{
    if (! self.isConduitOpen) {
        BOOL ret = [self.conduit transferWillBecomeActive:self];

        if ([self.conduit respondsToSelector:@selector(moveToPosition:)]) {
            [self.conduit moveToPosition:self.bytesMoved];
        }

        self.isConduitOpen = ret;
        return ret;
    }
    else {
        return YES;
    }
}

- (void)closeConduitIfNeeded
{
    if (! self.isConduitOpen) {
        return;
    }
    else {
        [self.conduit transferWillBecomeInactive:self];
        self.isConduitOpen = NO;
    }
}

- (void)sendProgressUpdateNow
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
        for (int i = 0; i < kSecondsToAverage; ++i) {
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

- (void)markFileAsCancelled:(OCTMessageFile *)file
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

- (void)markFileAsCompleted:(OCTMessageFile *)file withFinalDestination:(NSString *)fd
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

- (void)markFileAsPaused:(OCTMessageFile *)file withFlags:(OCTPauseFlags)flag
{
    DDLogDebug(@"Marking file %@ as PAUSED.", file);

    DDLogDebug(@"archiving resume data; if we die we're starting at offset %lld", self.bytesMoved);

    NSData *conduitData = nil;
    if ([self.conduit conformsToProtocol:@protocol(NSCoding)]) {
        conduitData = [NSKeyedArchiver archivedDataWithRootObject:self.conduit];
    }

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:file withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStatePaused;
        theObject.pauseFlags = flag;
        theObject.filePosition = self.bytesMoved;
        theObject.restorationTag = conduitData;
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
}

- (void)markFileAsInterrupted:(OCTMessageFile *)file
{
    DDLogDebug(@"Marking file %@ as INTERRUPTED.", file);
    DDLogDebug(@"archiving resume data; if we die we're starting at offset %lld", self.bytesMoved);

    NSData *conduitData = nil;
    if ([self.conduit conformsToProtocol:@protocol(NSCoding)]) {
        conduitData = [NSKeyedArchiver archivedDataWithRootObject:self.conduit];
    }

    [[self.fileManager.dataSource managerGetRealmManager] updateObject:file withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = OCTMessageFileStateInterrupted;
        theObject.filePosition = self.bytesMoved;
        theObject.restorationTag = conduitData;
    }];
    [[self.fileManager.dataSource managerGetRealmManager] noteMessageFileChanged:file];
}

- (void)resumeFile:(OCTMessageFile *)file
{
    DDLogDebug(@"archiving resume data; if we die we're starting at offset %lld", self.bytesMoved);

    NSData *conduitData = nil;
    if ([self.conduit conformsToProtocol:@protocol(NSCoding)]) {
        conduitData = [NSKeyedArchiver archivedDataWithRootObject:self.conduit];
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
        openOK = [self openConduitIfNeeded];
    });

    if (! openOK) {
        DDLogWarn(@"OCTActiveFile WARNING: Couldn't prepare the conduit. The file transfer will be cancelled.");

        [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:nil];

        [self markFileAsCancelled:self.fileMessage];

        if (error) {
            NSString *failureReason = @"The file data provider/receiver could not be opened.";
            *error = [NSError errorWithDomain:@"OCTFileError" code:-1 userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}];
        }
        return NO;
    }

    [self wipeCounters];

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlResume error:error];

    if (! ok) {
        return NO;
    }
    else {
        if ((self.fileMessage.pauseFlags == OCTPauseFlagsSelf) || (self.fileMessage.pauseFlags == OCTPauseFlagsNobody)) {
            [self resumeFile:self.fileMessage];
            DDLogInfo(@"OCTActiveFile: no further blocks on file so transitioning to Loading state.");
        }
        else {
            [self markFileAsPaused:self.fileMessage withFlags:OCTPauseFlagsOther];
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
        [self markFileAsPaused:self.fileMessage withFlags:self.fileMessage.pauseFlags | OCTPauseFlagsSelf];
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
            [self closeConduitIfNeeded];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.fileManager removeFile:self];
            });
        });
        [self markFileAsCancelled:self.fileMessage];
        return YES;
    }
}

@end

@implementation OCTActiveInboundFile

- (id<OCTFileConduit>)conduit
{
    return self.receiver;
}

- (void)completeFileTransferAndClose
{
    [self.receiver transferWillBecomeInactive:self];
    [self.receiver transferWillComplete:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self markFileAsCompleted:self.fileMessage withFinalDestination:[self.receiver finalDestination]];
        [self.fileManager removeFile:self];
    });
}

- (void)receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p
{
    // NSLog(@"_receiveChunkNow at %ld", OCTGetSystemUptime());
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
    [self countBytes:length];
    // [self.fileManager scheduleProgressNotificationForFile:self];
}

@end

@implementation OCTActiveOutboundFile

- (id<OCTFileConduit>)conduit
{
    return self.sender;
}

- (void)completeFileTransferAndClose
{
    [self.sender transferWillBecomeInactive:self];
    [self.sender transferWillComplete:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self markFileAsCompleted:self.fileMessage withFinalDestination:[self.sender path]];
        [self.fileManager removeFile:self];
    });
}

- (void)sendChunkForSize:(size_t)csize fromPosition:(OCTToxFileSize)p
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
    // DDLogDebug(@"_sendChunkForSize: %zu", actual);
    [[self.fileManager.dataSource managerGetTox] fileSendChunk:buf forFileNumber:self.fileMessage.fileNumber friendNumber:self.friendNumber position:p length:actual error:nil];
    [self countBytes:actual];
    // [self.fileManager scheduleProgressNotificationForFile:self];
}

@end

#pragma clang diagnostic pop
