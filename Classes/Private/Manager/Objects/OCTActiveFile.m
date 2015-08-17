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

NSString *const kOCTFileErrorDomain = @"me.dvor.objcTox.FileError";

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

static void OCTSetFileError(NSError **errorptr, NSInteger code, NSString *description)
{
    if (errorptr) {
        *errorptr = [NSError errorWithDomain:kOCTFileErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : description}];
    }
}

@interface OCTActiveFile ()

@property (assign, readwrite) OCTToxFileSize bytesMoved;
@property (assign, atomic)    BOOL isConduitOpen;

@property (assign, atomic)    unsigned long lastCountedTime;
@property (assign, atomic)    unsigned long lastProgressUpdateTime;
@property (assign, atomic)    OCTToxFileSize *transferRateCounters;
@property (assign, atomic)    long rollingIndex;

@property (copy, atomic)      OCTFileNotificationBlock notificationBlock;

@property (assign, atomic)    BOOL suppressNotifications;

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

    self.suppressNotifications = YES;
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
        [self sendProgressUpdateNow];
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

- (NSData *)archiveConduit
{
    if ([self.conduit conformsToProtocol:@protocol(NSCoding)]) {
        return [NSKeyedArchiver archivedDataWithRootObject:self.conduit];
    }
    return nil;
}

- (void)control:(OCTToxFileControl)ctl
{
    OCTMessageFile *mf = (OCTMessageFile *)[[self.fileManager.dataSource managerGetRealmManager] objectWithUniqueIdentifier:self.fileIdentifier class:[OCTMessageFile class]];

    switch (ctl) {
        case OCTToxFileControlCancel: {
            DDLogDebug(@"_control: obeying cancel message from remote.");
            [self stopFileNow];
            [self markFileAsCancelled:self];
            break;
        }
        case OCTToxFileControlPause:
            DDLogDebug(@"_control: obeying pause message from remote.");
            [self markFileAsPaused:self withFlags:mf.pauseFlags | OCTPauseFlagsFriend];
            break;
        case OCTToxFileControlResume: {
            DDLogDebug(@"_control: obeying resume message from remote.");
            if (mf.pauseFlags == OCTPauseFlagsFriend) {
                [self openConduitIfNeeded];
                [self resumeFile:self];
            }
            else {
                [self markFileAsPaused:self withFlags:OCTPauseFlagsSelf];
            }
            break;
        }
    }
}

- (void)interrupt
{
    [self stopFileNow];
    [self markFileAsInterrupted:self];
}

#pragma mark - Internal API

- (void)stopFileNow
{
    dispatch_async(self.fileManager.queue, ^{
        if (self.isConduitOpen) {
            [self.conduit transferWillBecomeInactive:self];
            self.isConduitOpen = NO;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fileManager removeFile:self];
        });
    });
}

- (id<OCTFileConduit>)conduit
{
    @throw [NSException exceptionWithName:@"OCTFileException" reason:@"Only subclasses of OCTActiveFile can be used." userInfo:nil];
    return nil;
}

- (BOOL)openConduitIfNeeded
{
    __block BOOL ret = YES;
    dispatch_sync(self.fileManager.queue, ^{
        if (! self.isConduitOpen) {
            ret = [self.conduit transferWillBecomeActive:self];

            if ([self.conduit respondsToSelector:@selector(moveToPosition:)]) {
                [self.conduit moveToPosition:self.bytesMoved];
            }

            self.isConduitOpen = ret;
            return;
        }
    });
    return ret;
}

- (void)sendProgressUpdateNow
{
    // don't post a notification if we're paused
    // (sometimes one manages to sneak in after we've updated the state in realm,
    //  and it messes up my client code...)
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.notificationBlock && ! self.suppressNotifications) {
            self.notificationBlock(self);
        }
    });
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

- (void)markFileAsCancelled:(OCTActiveFile *)file
{
    DDLogDebug(@"Cancelling file %@", file);
    self.suppressNotifications = YES;
    [self.fileManager setState:OCTMessageFileStateCanceled forFile:file cleanInternals:YES andRunBlock:nil];
}

- (void)markFileAsCompleted:(OCTActiveFile *)file withFinalDestination:(NSString *)fd
{
    DDLogDebug(@"Marking file %@ as COMPLETE.", file);
    self.suppressNotifications = YES;
    [self.fileManager setState:OCTMessageFileStateReady forFile:file cleanInternals:YES andRunBlock:^(OCTMessageFile *theObject) {
        theObject.filePath = fd;
    }];
}

- (void)markFileAsPaused:(OCTActiveFile *)file withFlags:(OCTPauseFlags)flags
{
    DDLogDebug(@"Pausing file %@", file);
    self.suppressNotifications = YES;
    [self.fileManager setState:OCTMessageFileStatePaused andArchiveConduitForFile:file withPauseFlags:flags];
}

- (void)markFileAsInterrupted:(OCTActiveFile *)file
{
    DDLogDebug(@"Marking file %@ as INTERRUPTED.", file);
    self.suppressNotifications = YES;
    [self.fileManager setState:OCTMessageFileStateInterrupted andArchiveConduitForFile:file withPauseFlags:OCTPauseFlagsNobody];
}

- (void)resumeFile:(OCTActiveFile *)file
{
    DDLogDebug(@"Resuming file %@", file);
    self.suppressNotifications = NO;
    [self.fileManager setState:OCTMessageFileStateLoading andArchiveConduitForFile:file withPauseFlags:OCTPauseFlagsNobody];
}

#pragma mark - Public API - Controls

- (BOOL)resumeWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    OCTMessageFile *mf = (OCTMessageFile *)[[self.fileManager.dataSource managerGetRealmManager] objectWithUniqueIdentifier:self.fileIdentifier class:[OCTMessageFile class]];

    ok = [self openConduitIfNeeded];

    if (! ok) {
        DDLogWarn(@"OCTActiveFile WARNING: Couldn't prepare the conduit. The file transfer will be cancelled.");

        [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:nil];

        [self markFileAsCancelled:self];

        OCTSetFileError(error, OCTFileErrorCodeBadConduit, @"The file data provider/receiver could not be opened.");
        return NO;
    }

    [self wipeCounters];

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlResume error:error];

    if (ok) {
        if ((mf.pauseFlags == OCTPauseFlagsSelf) || (mf.pauseFlags == OCTPauseFlagsNobody)) {
            [self resumeFile:self];
            DDLogInfo(@"OCTActiveFile: no further blocks on file so transitioning to Loading state.");
        }
        else {
            [self markFileAsPaused:self withFlags:OCTPauseFlagsFriend];
            DDLogInfo(@"OCTActiveFile: we're no longer pausing this file, but our friend still is.");
        }
    }

    return ok;
}

- (BOOL)pauseWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    OCTMessageFile *mf = (OCTMessageFile *)[[self.fileManager.dataSource managerGetRealmManager] objectWithUniqueIdentifier:self.fileIdentifier class:[OCTMessageFile class]];

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlPause error:error];

    if (ok) {
        [self markFileAsPaused:self withFlags:mf.pauseFlags | OCTPauseFlagsSelf];
    }

    return ok;
}

- (BOOL)cancelWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:error];

    if (ok) {
        [self stopFileNow];
        [self markFileAsCancelled:self];
        return YES;
    }

    return ok;
}

@end

@implementation OCTActiveIncomingFile

- (id<OCTFileConduit>)conduit
{
    return self.receiver;
}

- (void)completeFileTransferAndClose
{
    [self.receiver transferWillBecomeInactive:self];
    [self.receiver transferWillComplete:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self markFileAsCompleted:self withFinalDestination:[self.receiver finalDestination]];
        [self.fileManager removeFile:self];
    });
}

- (void)receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p
{
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
}

@end

@implementation OCTActiveOutgoingFile

- (id<OCTFileConduit>)conduit
{
    return self.sender;
}

- (void)completeFileTransferAndClose
{
    [self.sender transferWillBecomeInactive:self];
    [self.sender transferWillComplete:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self markFileAsCompleted:self withFinalDestination:[self.sender path]];
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
    [[self.fileManager.dataSource managerGetTox] fileSendChunk:buf forFileNumber:self.fileNumber friendNumber:self.friendNumber position:p length:actual error:nil];
    [self countBytes:actual];
}

@end

#pragma clang diagnostic pop
