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

@interface OCTBaseActiveFile ()

@property (assign, atomic)    BOOL isConduitOpen;

@property (assign, atomic)    unsigned long lastCountedTime;
@property (assign, atomic)    OCTToxFileSize *transferRateCounters;
@property (assign, atomic)    long rollingIndex;

@property (assign, nonatomic) OCTMessageFileState state;
@property (assign, nonatomic) OCTPauseFlags choke;

@property (assign, atomic)    unsigned long time;

@end

@implementation OCTBaseActiveFile

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

    NSAssert(avgdelta >= 0, @"Detected a temporal anomaly. objcTox currently does not support Tox FTL, nor phone-microwave-"
             "based time travel. Please file a bug.");

    if (avgdelta >= kMillisecondsPerSecond) {
        [self incrementRollingIndex:avgdelta / kMillisecondsPerSecond];
        self.lastCountedTime = now;
    }

    self.bytesMoved += size;
    self.transferRateCounters[self.rollingIndex] += size;
    self.time = now;
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
}

#pragma mark - Private API

- (NSData *)archiveConduit {
    return nil;
}

- (void)control:(OCTToxFileControl)ctl
{
    switch (ctl) {
        case OCTToxFileControlCancel: {
            DDLogDebug(@"_control: obeying cancel message from remote.");
            [self cancelControl];
            break;
        }
        case OCTToxFileControlPause:
            DDLogDebug(@"_control: obeying pause message from remote.");
            [self pauseControl];
            break;
        case OCTToxFileControlResume: {
            DDLogDebug(@"_control: obeying resume message from remote.");
            [self resumeControl];
            break;
        }
    }
}

- (void)resumeControl
{
    if ((self.choke == OCTPauseFlagsFriend) || (self.choke == OCTPauseFlagsNobody)) {
        self.state = OCTMessageFileStateLoading;

        BOOL ok = [self openConduitIfNeeded];
        if (! ok) {
            DDLogError(@"conduit failed to reopen when resuming file, cancelling it");
            [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:nil];
            self.state = OCTMessageFileStateCanceled;
        }
    }
    else {
        self.choke = OCTPauseFlagsSelf;
    }
}

- (void)pauseControl
{
    self.state = OCTMessageFileStatePaused;
    self.choke |= OCTPauseFlagsFriend;
}

- (void)cancelControl
{
    self.state = OCTMessageFileStateCanceled;
    self.choke = OCTPauseFlagsNobody;
    [self stopFileNow];
}

- (void)interrupt
{
    self.state = OCTMessageFileStateInterrupted;
    self.choke = OCTPauseFlagsNobody;
    [self stopFileNow];
}

- (void)completeFileTransferAndClose
{
    [self stopFileNow];
}

- (void)sendChunkForSize:(size_t)csize fromPosition:(OCTToxFileSize)p {}
- (void)receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p {}

#pragma mark - Internal API

- (void)stopFileNow
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.fileManager removeFile:self];
    });
}

- (BOOL)openConduitIfNeeded
{
    return NO;
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

@end

@interface OCTActiveFile ()
@property (assign, atomic) unsigned long lastProgressUpdateTime;
@property (assign, atomic) BOOL suppressNotifications;
@property (strong, nonatomic) id<OCTFileConduit> conduit;
@end

@implementation OCTActiveFile

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

- (void)markFileAsCompleted:(OCTActiveFile *)file withFinalDestination:(NSString *)fd
{
    DDLogDebug(@"Marking file %@ as COMPLETE.", file);
    self.suppressNotifications = YES;
    self.state = OCTMessageFileStateReady;
    [self.fileManager setState:OCTMessageFileStateReady forFile:file cleanInternals:YES andRunBlock:^(OCTMessageFile *theObject) {
        theObject.filePath = fd;
    }];
}

- (void)updateStateAndChokeFromMessage
{
    OCTMessageFile *file = (OCTMessageFile *)[[self.fileManager.dataSource managerGetRealmManager] objectWithUniqueIdentifier:self.fileIdentifier class:[OCTMessageFile class]];
    self.state = file.fileState;
    self.choke = file.pauseFlags;
}

- (void)updateState
{
    switch (self.state) {
        case OCTMessageFileStatePaused:
            self.suppressNotifications = YES;
            [self.fileManager setState:OCTMessageFileStatePaused andArchiveConduitForFile:self withPauseFlags:self.choke];
            break;
        case OCTMessageFileStateLoading:
            self.suppressNotifications = NO;
            [self.fileManager setState:OCTMessageFileStateLoading andArchiveConduitForFile:self withPauseFlags:OCTPauseFlagsNobody];
            break;
        case OCTMessageFileStateInterrupted:
            self.suppressNotifications = YES;
            [self.fileManager setState:OCTMessageFileStateInterrupted andArchiveConduitForFile:self withPauseFlags:OCTPauseFlagsNobody];
            break;
        case OCTMessageFileStateCanceled:
            self.suppressNotifications = YES;
            [self.fileManager setState:self.state forFile:self cleanInternals:YES andRunBlock:nil];
            break;
        default:
            break;
    }
}

#pragma mark - Overrides

- (NSData *)archiveConduit
{
    if ([self.conduit conformsToProtocol:@protocol(NSCoding)]) {
        return [NSKeyedArchiver archivedDataWithRootObject:self.conduit];
    }
    else {
        return nil;
    }
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

- (void)countBytes:(NSUInteger)bytes
{
    [super countBytes:bytes];

    if (self.time - self.lastProgressUpdateTime >= kProgressUpdateInterval) {
        [self sendProgressUpdateNow];
    }
}

- (void)pauseControl
{
    [super pauseControl];
    [self updateState];
}

- (void)resumeControl
{
    [super resumeControl];
    [self updateState];
}

- (void)cancelControl
{
    [super cancelControl];
    [self updateState];
}

- (void)interrupt
{
    [super interrupt];
    [self updateState];
}

- (void)stopFileNow
{
    dispatch_async(self.fileManager.queue, ^{
        if (self.isConduitOpen) {
            [self.conduit transferWillBecomeInactive:self];
            self.isConduitOpen = NO;
        }

        [super stopFileNow];
    });
}

#pragma mark - Public API

- (BOOL)resumeWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    ok = [self openConduitIfNeeded];

    if (! ok) {
        DDLogWarn(@"OCTActiveFile WARNING: Couldn't prepare the conduit. The file transfer will be cancelled.");

        [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlCancel error:nil];
        [self.fileManager setState:OCTMessageFileStateCanceled forFile:self cleanInternals:YES andRunBlock:nil];

        OCTSetFileError(error, OCTFileErrorCodeBadConduit, @"The file data provider/receiver could not be opened.");
        return NO;
    }

    [self wipeCounters];

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlResume error:error];

    if (ok) {
        if ((self.choke == OCTPauseFlagsSelf) || (self.choke == OCTPauseFlagsNobody)) {
            self.state = OCTMessageFileStateLoading;
            self.choke = OCTPauseFlagsNobody;
            DDLogInfo(@"OCTActiveFile: no further blocks on file so transitioning to Loading state.");
        }
        else {
            self.choke = OCTPauseFlagsFriend;
            self.state = OCTMessageFileStatePaused;
            DDLogInfo(@"OCTActiveFile: we're no longer pausing this file, but our friend still is.");
        }
        [self updateState];
    }

    return ok;
}

- (BOOL)pauseWithError:(NSError *__autoreleasing *)error
{
    BOOL ok = YES;
    if (error) {
        *error = nil;
    }

    ok = [[self.fileManager.dataSource managerGetTox] fileSendControlForFileNumber:self.fileNumber friendNumber:self.friendNumber control:OCTToxFileControlPause error:error];

    if (ok) {
        self.choke |= OCTPauseFlagsSelf;
        self.state = OCTMessageFileStatePaused;
        [self updateState];
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
        self.state = OCTMessageFileStateCanceled;
        [self updateState];
        return YES;
    }

    return ok;
}

@end

@implementation OCTActiveIncomingFile

- (void)completeFileTransferAndClose
{
    [self.conduit transferWillBecomeInactive:self];
    [self.conduit transferWillComplete:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.fileManager removeFile:self];
        [self markFileAsCompleted:self withFinalDestination:[self.receiver finalDestination]];
    });
}

- (void)receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p
{
    if (p != self.bytesMoved + 1) {
        if ([self.receiver respondsToSelector:@selector(moveToPosition:)]) {
            [self.receiver moveToPosition:p];
        }
        else {
            DDLogWarn(@"OCTActiveIncomingFile WARNING: receiver %@ does not support seeking, but we received out of order file chunk for position %llu."
                      "(I think the file position is %llu.) The file will be corrupted.", self.receiver, p, self.bytesMoved + 1);
        }
    }

    [self.receiver writeBytes:length fromBuffer:chunk];
    [self countBytes:length];
}

@end

@implementation OCTActiveOutgoingFile

- (void)completeFileTransferAndClose
{
    [self.conduit transferWillBecomeInactive:self];
    [self.conduit transferWillComplete:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.fileManager removeFile:self];
        [self markFileAsCompleted:self withFinalDestination:[self.sender path]];
    });
}

- (void)sendChunkForSize:(size_t)csize fromPosition:(OCTToxFileSize)p
{
    if (p != self.bytesMoved + 1) {
        if ([self.sender respondsToSelector:@selector(moveToPosition:)]) {
            [self.sender moveToPosition:p];
        }
        else {
            DDLogWarn(@"OCTActiveOutgoingFile WARNING: sender %@ does not support seeking, but we need to send out of order file chunk for position %llu."
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
