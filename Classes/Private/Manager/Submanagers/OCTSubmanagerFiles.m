//
//  OCTSubmanagerFiles.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTTox+Private.h"
#import "OCTRealmManager.h"
#import "OCTToxConstants.h"
#import "OCTMessageAbstract.h"
#import "OCTMessageFile.h"
#import "OCTFriend.h"
#import "OCTChat.h"
#import "OCTActiveFile+Variants.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTFileIO+Private.h"
#import "RBQFetchRequest.h"
#import "DDLog.h"

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF LOG_LEVEL_DEBUG

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

static NSString *OCTSanitizeFilename(NSString *filename)
{
    // TODO: maybe get rid of nulls too
    NSMutableString *mut = filename.mutableCopy;
    [mut replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, mut.length)];
    if ([mut characterAtIndex:0] == '.') {
        [mut replaceCharactersInRange:NSMakeRange(0, 1) withString:@"_"];
    }
    return [mut copy];
}

static OCTFileUsage OCTToxFileKindToFileUsage(OCTToxFileKind k)
{
    switch (k) {
        case OCTToxFileKindAvatar:
            NSCAssert(0, @"Grave error: OCTFileKindAvatar passed to OCTToxFileKindToFileUsage."
                      " Please report this on GitHub.");
            return 0;
        case OCTToxFileKindData:
            return OCTFileUsageData;
            /*case 5413 OCTToxFileKindSticker:
             *  return OCTFileUsageUnimplementedAlso; */
    }
}

static OCTToxFileKind OCTFileUsageToToxFileKind(OCTFileUsage k)
{
    switch (k) {
        // when the sticker PR gets merged, uncomment this.
        // case OCTFileUsageSticker:
        //     return 5413;
        default:
            return OCTToxFileKindData;
    }
}

void OCTExceptFileNotMessageFile(void)
{
    @throw [NSException exceptionWithName:@"OCTFileNotMessageFileException"
                                   reason:@"The OCTMessageAbstract passed to saveFileFromMessage:... was not "
            "a file transfer. Break on OCTExceptFileNotMessageFile to debug."
                                 userInfo:nil];
}

void OCTExceptFileNotWaitingConfirmation(void)
{
    @throw [NSException exceptionWithName:@"OCTFileNotWaitingConfirmationException"
                                   reason:@"saveFileFromMessage: should only be used on new files. "
            "For existing files, use activeFileForMessage: and then "
            "resume that with resumeWithError:."
            "Break on OCTExceptFileNotWaitingConfirmation to debug."
            userInfo:nil];
}

void OCTExceptFileNotInbound(void)
{
    @throw [NSException exceptionWithName:@"OCTFileNotInboundException"
                                   reason:@"The OCTMessageAbstract passed to saveFileFromMessage:... was not "
            "an incoming file transfer. Break on OCTExceptFileNotInbound to debug."
                                 userInfo:nil];
}

@interface OCTSubmanagerFiles ()

@property (weak, atomic) dispatch_queue_t queue;

@property (strong, atomic) NSMutableDictionary /* <NSNumber *, NSMutableDictionary<NSNumber *, OCTActiveFile *> *> */ *activeFiles;

@end

@implementation OCTSubmanagerFiles
@synthesize dataSource = _dataSource;

#pragma mark -  Lifecycle

- (instancetype)init
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.activeFiles = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)configure
{
    self.queue = [self.dataSource managerGetToxQueue];
    [[self.dataSource managerGetRealmManager] updateObjectsOfClass:[OCTMessageFile class] withoutNotificationUsingBlock:^(OCTMessageFile *theObject) {
        if ((theObject.fileState != OCTMessageFileStateCanceled)
            && (theObject.fileState != OCTMessageFileStateReady)) {
            theObject.fileState = OCTMessageFileStateInterrupted;
        }
    }];
}

#pragma mark - Public API

- (nullable OCTActiveFile *)sendFile:(nonnull NSString *)name
                         usingSender:(nonnull id<OCTFileSending>)file
                              toChat:(nonnull OCTChat *)chat
                                type:(OCTFileUsage)type
                             message:(OCTMessageAbstract *__nonnull *__nullable)msgout
                               error:(NSError *__nullable *__nullable)error
{
    NSParameterAssert(name);
    NSParameterAssert(file);
    NSParameterAssert(chat);

    NSError *err = nil;

    OCTFriend *f = chat.friends.firstObject;
    OCTToxFileNumber n = [[self.dataSource managerGetTox] fileSendWithFriendNumber:f.friendNumber kind:OCTFileUsageToToxFileKind(type) fileSize:file.fileSize fileId:nil fileName:name error:&err];

    if (err) {
        if (error) {
            *error = err;
        }

        DDLogError(@"%@", err);

        return nil;
    }

    OCTMessageAbstract *msg = [self createBlankMessage];
    OCTMessageFile *fmsg = msg.messageFile;

    fmsg.fileNumber = n;
    fmsg.fileSize = file.fileSize;
    fmsg.fileName = name;
    fmsg.fileUsage = type;
    fmsg.pauseFlags = OCTPauseFlagsFriend;
    fmsg.fileTag = [[self.dataSource managerGetTox] fileGetFileIdForFileNumber:n friendNumber:f.friendNumber error:nil];

    msg.sender = nil;
    msg.chat = chat;
    msg.messageFile = fmsg;

    OCTActiveOutgoingFile *send = (OCTActiveOutgoingFile *)[self createActiveFileForFriend:f message:fmsg provider:file isOutgoing:YES];
    [self setActiveFile:send forFriendNumber:f.friendNumber fileNumber:n];
    self.activeFiles[@(f.friendNumber)][@(n)] = send;

    [[self.dataSource managerGetRealmManager] addObject:msg];
    [[self.dataSource managerGetRealmManager] updateObject:chat withBlock:^(OCTChat *theChat) {
        theChat.lastMessage = msg;
        theChat.lastActivityDateInterval = msg.dateInterval;
    }];

    if (msgout) {
        *msgout = msg;
    }

    // [send resumeWithError:error];
    return send;
}

- (nullable OCTActiveFile *)saveFileFromMessage:(nonnull OCTMessageAbstract *)msg
                                  usingReceiver:(nonnull id<OCTFileReceiving>)saver
                                          error:(NSError *__nullable *__nullable)error
{
    NSParameterAssert(msg);
    NSParameterAssert(saver);

    if (! msg.messageFile) {
        OCTExceptFileNotMessageFile();
        return nil;
    }

    if (msg.messageFile.fileState != OCTMessageFileStateWaitingConfirmation) {
        OCTExceptFileNotWaitingConfirmation();
        return nil;
    }

    OCTActiveIncomingFile *f = (OCTActiveIncomingFile *)[self realActiveFileForMessage:msg];
    if (! [f isKindOfClass:[OCTActiveIncomingFile class]]) {
        OCTExceptFileNotInbound();
        return nil;
    }

    f.receiver = saver;
    [f resumeWithError:error];
    return f;
}

- (nullable OCTActiveFile *)activeFileForMessage:(OCTMessageAbstract *)file
{
    NSParameterAssert(file);

    if (file.messageFile.fileState == OCTMessageFileStateWaitingConfirmation) {
        DDLogWarn(@"warning: activeFileForMessage: is useless when the file's state is WaitingConfirmation. Returning nil");
        return nil;
    }

    return [self realActiveFileForMessage:file];
}

- (nullable OCTActiveFile *)realActiveFileForMessage:(OCTMessageAbstract *)file
{
    if (file.sender) {
        return [self activeFileForFriendNumber:file.sender.friendNumber fileNumber:file.messageFile.fileNumber];
    }
    else {
        // groupchats?
        OCTFriend *friend = [file.chat.friends firstObject];
        return [self activeFileForFriendNumber:friend.friendNumber fileNumber:file.messageFile.fileNumber];
    }
}

- (nonnull id<OCTFileReceiving>)newDefaultReceiver
{
    return [[OCTFileOutput alloc] initWithConfigurator:[self.dataSource managerGetFileStorage]];
}

#pragma mark - Private

- (void)  setState:(OCTMessageFileState)state
           forFile:(OCTActiveFile *)file
    cleanInternals:(BOOL)clean
       andRunBlock:(void (^)(OCTMessageFile *theObject))extraBlock
{
    OCTMessageFile *mf = (OCTMessageFile *)[[self.dataSource managerGetRealmManager]
                                            objectWithUniqueIdentifier:file.fileIdentifier class:[OCTMessageFile class]];
    [[self.dataSource managerGetRealmManager] updateObject:mf withBlock:^(OCTMessageFile *theObject) {
        theObject.fileState = state;

        if (clean) {
            theObject.filePosition = 0;
            theObject.restorationTag = nil;
            theObject.fileTag = nil;
            theObject.filePath = nil;
        }

        if (extraBlock) {
            extraBlock(theObject);
        }
    }];
    [[self.dataSource managerGetRealmManager] noteMessageFileChanged:mf];
}

- (void)setState:(OCTMessageFileState)state andArchiveConduitForFile:(OCTActiveFile *)file withPauseFlags:(OCTPauseFlags)flag
{
    NSData *conduitData = [file archiveConduit];
    OCTToxFileSize bytesMoved = file.bytesMoved;

    [self setState:state forFile:file cleanInternals:NO andRunBlock:^(OCTMessageFile *theObject) {
        theObject.pauseFlags = flag;
        theObject.filePosition = bytesMoved;
        theObject.restorationTag = conduitData;
    }];
}

- (void)setActiveFile:(nullable OCTActiveFile *)file forFriendNumber:(OCTToxFriendNumber)fn fileNumber:(OCTToxFileNumber)filen
{
    NSMutableDictionary *d = self.activeFiles[@(fn)];
    if (! d) {
        d = [[NSMutableDictionary alloc] init];
        self.activeFiles[@(fn)] = d;
    }

    if (file) {
        d[@(filen)] = file;
    }
    else {
        [d removeObjectForKey:@(filen)];
    }
}

- (nullable OCTActiveFile *)activeFileForFriendNumber:(OCTToxFriendNumber)fn fileNumber:(OCTToxFileNumber)file
{
    return self.activeFiles[@(fn)][@(file)];
}

- (nonnull OCTActiveFile *)createActiveFileForFriend:(OCTFriend *)f message:(OCTMessageFile *)msg provider:(id<OCTFileConduit>)prov isOutgoing:(BOOL)outgoing
{
    OCTActiveFile *ret;

    if (outgoing) {
        OCTActiveOutgoingFile *outf = [[OCTActiveOutgoingFile alloc] init];
        outf.sender = (id<OCTFileSending>)prov;
        outf.fileSize = outf.sender.fileSize;
        ret = outf;
    }
    else {
        OCTActiveIncomingFile *inf = [[OCTActiveIncomingFile alloc] init];
        inf.receiver = (id<OCTFileReceiving>)prov;
        inf.fileSize = msg.fileSize;
        ret = inf;
    }

    ret.fileManager = self;
    ret.fileIdentifier = msg.uniqueIdentifier;
    ret.fileNumber = msg.fileNumber;
    ret.friendNumber = f.friendNumber;
    return ret;
}

- (void)removeFile:(OCTActiveFile *)file
{
    [self setActiveFile:nil forFriendNumber:file.friendNumber fileNumber:file.fileNumber];
}

/* Sending file */
- (BOOL)tryToResumeFile:(OCTMessageAbstract *)msga
{
    if (msga.messageFile.restorationTag.length == 0) {
        return NO;
    }

    id<OCTFileSending> sender = [NSKeyedUnarchiver unarchiveObjectWithData:msga.messageFile.restorationTag];
    if (! sender) {
        DDLogWarn(@"OCTSubmanagerFiles WARNING: while trying to resume outgoing file %@, I decoded a nil conduit.", msga);
        return NO;
    }
    if (! [sender conformsToProtocol:@protocol(OCTFileSending)]) {
        DDLogWarn(@"OCTSubmanagerFiles WARNING: while trying to resume outgoing file %@, I decoded a conduit (%@) that did not conform to OCTFileSending.", msga, sender);
        return NO;
    }

    if (! sender.canBeResumedNow) {
        DDLogDebug(@"OCTSubmanagerFiles: sender said NO for resuming file %@", msga);
        return NO;
    }

    // then ok, we can resume

    OCTMessageFile *mf = msga.messageFile;
    OCTFriend *f = [msga.chat.friends firstObject];
    NSError *error = nil;

    OCTToxFileNumber n = [[self.dataSource managerGetTox] fileSendWithFriendNumber:f.friendNumber
                                                                              kind:OCTFileUsageToToxFileKind(mf.fileUsage)
                                                                          fileSize:sender.fileSize
                                                                            fileId:mf.fileTag
                                                                          fileName:mf.fileName
                                                                             error:&error];

    if (error) {
        DDLogError(@"toxcore rejected file send: %@", error);
        return NO;
    }

    [[self.dataSource managerGetRealmManager] updateObject:msga withBlock:^(OCTMessageAbstract *msga_) {
        msga_.dateInterval = [NSDate date].timeIntervalSince1970;
        msga_.messageFile.fileNumber = n;
        msga_.messageFile.pauseFlags = OCTPauseFlagsFriend;
    }];

    OCTActiveOutgoingFile *outf = (OCTActiveOutgoingFile *)[self createActiveFileForFriend:f message:mf provider:sender isOutgoing:YES];
    [self setActiveFile:outf forFriendNumber:outf.friendNumber fileNumber:n];
    return YES;
}

/* Resuming file */
- (BOOL)tryToResumeFile:(OCTMessageAbstract *)msga
      withNewFileNumber:(OCTToxFileNumber)fileNumber
                   kind:(OCTFileUsage)kind
               fileSize:(OCTToxFileSize)fileSize
               fileName:(NSString *)fileName
{
    OCTMessageFile *fileMsg = msga.messageFile;

    if (fileMsg.restorationTag.length == 0) {
        return NO;
    }

    id<OCTFileReceiving> rcvr = [NSKeyedUnarchiver unarchiveObjectWithData:fileMsg.restorationTag];
    if (! rcvr) {
        DDLogWarn(@"OCTSubmanagerFiles WARNING: while trying to resume incoming file %@, I decoded a nil conduit.", msga);
        return NO;
    }

    if (! [rcvr conformsToProtocol:@protocol(OCTFileReceiving)]) {
        DDLogWarn(@"OCTSubmanagerFiles WARNING: while trying to resume incoming file %@, I decoded a conduit (%@) that did not conform to OCTFileReceiving.", msga, rcvr);
        return NO;
    }

    if (! rcvr.canBeResumedNow) {
        DDLogDebug(@"OCTSubmanagerFiles: receiver said NO for resuming file %@", msga);
        return NO;
    }

    // now it can be resumed

    NSError *error = nil;
    [[self.dataSource managerGetTox] fileSeekForFileNumber:fileNumber friendNumber:msga.sender.friendNumber position:fileMsg.filePosition error:&error];

    if (error) {
        DDLogError(@"toxcore failed seeking the file to position %lld", fileMsg.filePosition);
        [[self.dataSource managerGetTox] fileSendControlForFileNumber:fileNumber friendNumber:msga.sender.friendNumber control:OCTToxFileControlCancel error:&error];
        return NO;
    }

    [[self.dataSource managerGetRealmManager] updateObject:msga withBlock:^(OCTMessageAbstract *msga_) {
        msga_.dateInterval = [NSDate date].timeIntervalSince1970;
        msga_.messageFile.fileNumber = fileNumber;
        msga_.messageFile.fileState = OCTMessageFileStatePaused;
        msga_.messageFile.pauseFlags = OCTPauseFlagsSelf;
    }];

    OCTActiveIncomingFile *inf = (OCTActiveIncomingFile *)[self createActiveFileForFriend:msga.sender message:msga.messageFile provider:rcvr isOutgoing:NO];
    [self setActiveFile:inf forFriendNumber:msga.sender.friendNumber fileNumber:fileNumber];
    return YES;
}

- (OCTMessageAbstract *)createBlankMessage
{
    OCTMessageFile *newFileMessage = [[OCTMessageFile alloc] init];
    newFileMessage.fileState = OCTMessageFileStateWaitingConfirmation;
    newFileMessage.filePath = @"";
    newFileMessage.filePosition = 0;
    newFileMessage.restorationTag = [NSData data];

    OCTMessageAbstract *newAbstractMessage = [[OCTMessageAbstract alloc] init];
    newAbstractMessage.dateInterval = [NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    newAbstractMessage.messageFile = newFileMessage;

    return newAbstractMessage;
}

#pragma mark - OCTToxDelegate.

- (void)     tox:(OCTTox *)tox friendConnectionStatusChanged:(OCTToxConnectionStatus)status
    friendNumber:(OCTToxFriendNumber)friendNumber
{
    if (status == OCTToxConnectionStatusNone) {
        NSArray *files = [self.activeFiles[@(friendNumber)] allValues];
        if (! files) {
            return;
        }

        for (OCTActiveFile *f in files) {
            [f interrupt];
        }
    }
    else {
        RBQFetchRequest *get = [[self.dataSource managerGetRealmManager] fetchRequestForClass:[OCTMessageAbstract class]
                                                                                withPredicate:[NSPredicate predicateWithFormat:@"messageFile.fileState == %d && sender == nil", OCTMessageFileStateInterrupted]];
        RLMResults *objs = [get fetchObjects];

        for (OCTMessageAbstract *msga in objs) {
            [self tryToResumeFile:msga];
        }
    }
}

- (void)     tox:(OCTTox *)tox fileChunkRequestForFileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
          length:(size_t)length
{
    OCTActiveOutgoingFile *outboundFile = (OCTActiveOutgoingFile *)[self activeFileForFriendNumber:friendNumber fileNumber:fileNumber];

    NSAssert([outboundFile isMemberOfClass:[OCTActiveOutgoingFile class]],
             @"Chunk requested for a bad file %@!", outboundFile);

    if (length == 0) {
        [[self.dataSource managerGetTox] fileSendChunk:NULL forFileNumber:fileNumber friendNumber:friendNumber position:position length:0 error:nil];
        [outboundFile completeFileTransferAndClose];
    }
    else {
        [outboundFile sendChunkForSize:length fromPosition:position];
    }
}

- (void)     tox:(OCTTox *)tox fileReceiveChunk:(const uint8_t *)chunk
          length:(size_t)length
      fileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
{
    OCTActiveIncomingFile *inboundFile = (OCTActiveIncomingFile *)[self activeFileForFriendNumber:friendNumber fileNumber:fileNumber];

    NSAssert([inboundFile isMemberOfClass:[OCTActiveIncomingFile class]], @"Received a chunk for a bad file %@!", inboundFile);

    if (length == 0) {
        [inboundFile completeFileTransferAndClose];
    }
    else {
        [inboundFile receiveChunkNow:chunk length:length atPosition:position];
    }
}

- (void)     tox:(OCTTox *)tox fileReceiveControl:(OCTToxFileControl)control
    friendNumber:(OCTToxFriendNumber)friendNumber
      fileNumber:(OCTToxFileNumber)fileNumber
{
    OCTActiveFile *f = [self activeFileForFriendNumber:friendNumber fileNumber:fileNumber];

    NSAssert(f, @"Anomaly: received a control for which we don't have an OCTActiveFile on record for.");

    [f control:control];
}

- (void)     tox:(OCTTox *)tox fileReceiveForFileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
            kind:(OCTToxFileKind)kind
        fileSize:(OCTToxFileSize)fileSize
        fileName:(NSString *)fileName
{
    NSData *tag = [tox fileGetFileIdForFileNumber:fileNumber friendNumber:friendNumber error:nil];

    NSAssert(tag.length != 0, @"Anomaly: this file (%u#%u) has no tag. Please report a bug.", friendNumber, fileNumber);

    if (kind > OCTToxFileKindAvatar) {
        DDLogInfo(@"received a non-enumed file kind (outdated toxcore?); cancelling it");

        NSError *error = nil;
        [[self.dataSource managerGetTox] fileSendControlForFileNumber:fileNumber friendNumber:friendNumber control:OCTToxFileControlCancel error:&error];

        if (error) {
            DDLogError(@"nevermind, got error %@ and now the client is screwed", error);
        }

        return;
    }

    if (kind == OCTToxFileKindAvatar) {}
    else {
        RBQFetchRequest *get = [[self.dataSource managerGetRealmManager] fetchRequestForClass:[OCTMessageAbstract class]
                                                                                withPredicate:[NSPredicate predicateWithFormat:@"sender.friendNumber == %d && messageFile.fileState == %d", friendNumber, OCTMessageFileStateInterrupted]];
        for (OCTMessageAbstract *msga in [get fetchObjects]) {
            if ([msga.messageFile.fileTag isEqualToData:tag]) {
                BOOL yes = [self tryToResumeFile:msga withNewFileNumber:fileNumber kind:OCTToxFileKindToFileUsage(kind) fileSize:fileSize fileName:fileName];
                if (yes) {
                    return;
                }
                break;
            }
        }

        OCTMessageAbstract *msg = [self createBlankMessage];
        OCTMessageFile *fmsg = msg.messageFile;

        fmsg.fileNumber = fileNumber;
        fmsg.fileSize = fileSize;
        fmsg.fileName = OCTSanitizeFilename(fileName);
        fmsg.fileUsage = OCTToxFileKindToFileUsage(kind);

#ifdef OBJCTOX_SHOULD_BE_COMPATIBLE_WITH_UTOX_INLINE_IMAGES
        if ([fileName isEqualToString:@"utox-inline.png"]) {
            fmsg.fileUsage = OCTFileUsageInlinePhoto;
        }
#endif

        fmsg.pauseFlags = OCTPauseFlagsSelf;
        fmsg.fileTag = tag;
        fmsg.restorationTag = [NSData data];

        OCTFriend *f = [[self.dataSource managerGetRealmManager] friendWithFriendNumber:friendNumber];
        OCTChat *c = [[self.dataSource managerGetRealmManager] getOrCreateChatWithFriend:f];

        msg.sender = f;
        msg.chat = c;

        [self setActiveFile:[self createActiveFileForFriend:f message:fmsg provider:nil isOutgoing:NO] forFriendNumber:friendNumber fileNumber:fileNumber];

        [[self.dataSource managerGetRealmManager] addObject:msg];
        [[self.dataSource managerGetRealmManager] updateObject:c withBlock:^(OCTChat *theChat) {
            theChat.lastMessage = msg;
            theChat.lastActivityDateInterval = msg.dateInterval;
        }];
    }
}

@end

#pragma clang diagnostic pop
