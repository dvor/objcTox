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
#import "DDLog.h"

static NSString *_OCTSanitizeFilename(NSString *filename)
{
    // TODO: maybe get rid of nulls too
    NSMutableString *mut = filename.mutableCopy;
    [mut replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, mut.length)];
    if ([mut characterAtIndex:0] == '.') {
        [mut replaceCharactersInRange:NSMakeRange(0, 1) withString:@"_"];
    }
    return mut;
}

static OCTFileUsage _OCTToxFileKindToFileUsage(OCTToxFileKind k)
{
    switch (k) {
        case OCTToxFileKindAvatar:
            NSCAssert(0, @"Grave error: OCTFileKindAvatar passed to _OCTToxFileKindToFileUsage."
                      " Please report this on GitHub.");
            return 0;
        case OCTToxFileKindData:
            return OCTFileUsageData;
            /*case 5413 OCTToxFileKindSticker:
             *  return OCTFileUsageUnimplementedAlso; */
    }
}

static NSString *_OCTPairFriendAndFileNumber(OCTToxFriendNumber friend, OCTToxFileNumber file)
{
    return [NSString stringWithFormat:@"OCTFilePair%d,%u", friend, file];
}

void _OCTExceptFileNotMessageFile(void)
{
    @throw [NSException exceptionWithName:@"OCTFileNotMessageFileException"
                                   reason:@"The OCTMessageAbstract passed to saveFileFromMessage:... was not "
            "a file transfer. Break on _OCTExceptFileNotMessageFile to debug."
                                 userInfo:nil];
}

void _OCTExceptFileNotWaitingConfirmation(void)
{
    @throw [NSException exceptionWithName:@"OCTFileNotWaitingConfirmationException"
                                   reason:@"saveFileFromMessage: should only be used on new files. "
            "For existing files, use activeFileForMessage: and then "
            "resume that with resumeWithError:."
            "Break on _OCTExceptFileNotWaitingConfirmation to debug."
            userInfo:nil];
}

void _OCTExceptFileNotInbound(void)
{
    @throw [NSException exceptionWithName:@"OCTFileNotInboundException"
                                   reason:@"The OCTMessageAbstract passed to saveFileFromMessage:... was not "
            "an incoming file transfer. Break on _OCTExceptFileNotInbound to debug."
                                 userInfo:nil];
}

@interface OCTSubmanagerFiles ()

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;
@property (weak) dispatch_queue_t queue;

@property (strong) NSMutableDictionary<NSString *, OCTActiveFile *> *activeFiles;

@property (strong) NSMutableSet<OCTActiveFile *> *pendingNotifications;

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
    self.pendingNotifications = [[NSMutableSet alloc] init];

    return self;
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
    OCTToxFileNumber n = [[self.dataSource managerGetTox] fileSendWithFriendNumber:f.friendNumber kind:OCTToxFileKindData fileSize:file.fileSize fileId:nil fileName:name error:&err];

    if (err) {
        if (error) {
            *error = err;
        }

        DDLogError(@"%@", err);

        return nil;
    }

    OCTMessageFile *newFileMessage = [[OCTMessageFile alloc] init];
    newFileMessage.fileNumber = n;
    newFileMessage.fileSize = file.fileSize;
    newFileMessage.fileName = name;
    newFileMessage.fileUsage = type;
    newFileMessage.fileState = OCTMessageFileStatePaused;
    newFileMessage.pauseFlags = OCTPauseFlagsOther;
    newFileMessage.filePath = @"";
    newFileMessage.fileUTI = @"";
    newFileMessage.filePosition = 0;
    newFileMessage.restorationTag = [NSData data];
    newFileMessage.fileTag = [[self.dataSource managerGetTox] fileGetFileIdForFileNumber:n friendNumber:f.friendNumber error:nil];

    OCTMessageAbstract *newAbstractMessage = [[OCTMessageAbstract alloc] init];
    newAbstractMessage.dateInterval = [NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
    newAbstractMessage.sender = nil;
    newAbstractMessage.chat = chat;
    newAbstractMessage.messageFile = newFileMessage;

    OCTActiveOutboundFile *send = [self _createSendingFileForFriend:f message:newFileMessage provider:file];
    self.activeFiles[_OCTPairFriendAndFileNumber(f.friendNumber, n)] = send;

    [[self.dataSource managerGetRealmManager] addObject:newAbstractMessage];
    [[self.dataSource managerGetRealmManager] updateObject:chat withBlock:^(OCTChat *theChat) {
        theChat.lastMessage = newAbstractMessage;
        theChat.lastActivityDateInterval = newAbstractMessage.dateInterval;
    }];

    if (msgout) {
        *msgout = newAbstractMessage;
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
        _OCTExceptFileNotMessageFile();
        return nil;
    }

    if (msg.messageFile.fileState != OCTMessageFileStateWaitingConfirmation) {
        _OCTExceptFileNotWaitingConfirmation();
        return nil;
    }

    OCTActiveInboundFile *f = (OCTActiveInboundFile *)[self activeFileForMessage:msg];
    if (! [f isKindOfClass:[OCTActiveInboundFile class]]) {
        _OCTExceptFileNotInbound();
        return nil;
    }

    f.receiver = saver;
    [f resumeWithError:error];
    return f;
}

- (nullable OCTActiveFile *)activeFileForMessage:(OCTMessageAbstract *)file
{
    NSParameterAssert(file);

    if (file.sender) {
        return self.activeFiles[_OCTPairFriendAndFileNumber(file.sender.friendNumber, (OCTToxFileNumber)file.messageFile.fileNumber)];
    }
    else {
        // groupchats?
        OCTFriend *friend = [file.chat.friends firstObject];
        return self.activeFiles[_OCTPairFriendAndFileNumber(friend.friendNumber, (OCTToxFileNumber)file.messageFile.fileNumber)];
    }
}

- (nonnull id<OCTFileReceiving>)newDefaultReceiver
{
    return [[OCTFileOutput alloc] _initWithConfigurator:[self.dataSource managerGetFileStorage]];
}

#pragma mark - Private

- (nullable OCTActiveFile *)activeFileForFriendNumber:(OCTToxFriendNumber)fn fileNumber:(OCTToxFileNumber)file
{
    return self.activeFiles[_OCTPairFriendAndFileNumber(fn, file)];
}

- (nonnull OCTActiveOutboundFile *)_createSendingFileForFriend:(OCTFriend *)f message:(OCTMessageFile *)msg provider:(id<OCTFileSending>)prov
{
    OCTActiveOutboundFile *ret = [[OCTActiveOutboundFile alloc] init];
    ret.fileManager = self;
    ret.fileMessage = msg;
    ret.friendNumber = f.friendNumber;
    ret.fileSize = prov.fileSize;
    ret.sender = prov;
    return ret;
}

- (nonnull OCTActiveInboundFile *)_createReceivingFileForMessage:(OCTMessageAbstract *)f
{
    OCTActiveInboundFile *ret = [[OCTActiveInboundFile alloc] init];
    ret.fileManager = self;
    ret.fileMessage = f.messageFile;
    ret.friendNumber = f.sender.friendNumber;
    ret.fileSize = f.messageFile.fileSize;
    return ret;
}

- (void)scheduleProgressNotificationForFile:(OCTActiveFile *)f
{
    [self.pendingNotifications addObject:f];
}

- (void)sendProgressNotificationsNow
{
    [self.pendingNotifications makeObjectsPerformSelector:@selector(_sendProgressUpdateNow)];
    [self.pendingNotifications removeAllObjects];
}

- (void)removeFile:(OCTActiveFile *)file
{
    [self.pendingNotifications removeObject:file];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshorten-64-to-32"

    NSString *k = _OCTPairFriendAndFileNumber(file.friendNumber, file.fileMessage.fileNumber);

#pragma clang diagnostic pop
    [self.activeFiles removeObjectForKey:k];
}

#pragma mark - OCTToxDelegate.

- (void)     tox:(OCTTox *)tox fileChunkRequestForFileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
          length:(size_t)length
{
    OCTActiveOutboundFile *outboundFile = (OCTActiveOutboundFile *)[self activeFileForFriendNumber:friendNumber fileNumber:fileNumber];

    NSAssert([outboundFile isMemberOfClass:[OCTActiveOutboundFile class]],
             @"Chunk requested for a bad file %@!", outboundFile);

    if (length == 0) {
        [outboundFile _completeFileTransferAndClose];
    }
    else {
        [outboundFile _sendChunkForSize:length fromPosition:position];
    }
}

- (void)     tox:(OCTTox *)tox fileReceiveChunk:(const uint8_t *)chunk
          length:(size_t)length
      fileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
{
    OCTActiveInboundFile *inboundFile = (OCTActiveInboundFile *)[self activeFileForFriendNumber:friendNumber fileNumber:fileNumber];

    NSAssert([inboundFile isMemberOfClass:[OCTActiveInboundFile class]], @"Received a chunk for a bad file %@!", inboundFile);

    if (length == 0) {
        [inboundFile _completeFileTransferAndClose];
    }
    else {
        [inboundFile _receiveChunkNow:chunk length:length atPosition:position];
    }
}

- (void)     tox:(OCTTox *)tox fileReceiveControl:(OCTToxFileControl)control
    friendNumber:(OCTToxFriendNumber)friendNumber
      fileNumber:(OCTToxFileNumber)fileNumber
{
    NSString *key = _OCTPairFriendAndFileNumber(friendNumber, fileNumber);
    OCTActiveFile *f = self.activeFiles[key];

    NSAssert(f, @"Anomaly: received a control for which we don't have an OCTActiveFile on record for.");

    [f _control:control];
}

- (void)     tox:(OCTTox *)tox fileReceiveForFileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
            kind:(OCTToxFileKind)kind
        fileSize:(OCTToxFileSize)fileSize
        fileName:(NSString *)fileName
{
    NSData *tag = [tox fileGetFileIdForFileNumber:fileNumber friendNumber:friendNumber error:nil];

    NSAssert(tag.length != 0, @"Anomaly: this file (%u#%u) has no tag. Please report a bug.", friendNumber, fileNumber);

    if (kind == OCTToxFileKindAvatar) {}
    else {
        OCTMessageFile *newFileMessage = [[OCTMessageFile alloc] init];
        newFileMessage.fileNumber = fileNumber;
        newFileMessage.fileSize = fileSize;
        newFileMessage.fileName = _OCTSanitizeFilename(fileName);
        newFileMessage.fileUsage = _OCTToxFileKindToFileUsage(kind);
        newFileMessage.fileState = OCTMessageFileStateWaitingConfirmation;
        newFileMessage.filePath = @"";
        newFileMessage.fileUTI = @"";
        newFileMessage.filePosition = 0;
        newFileMessage.fileTag = tag;
        newFileMessage.restorationTag = [NSData data];

        OCTFriend *f = [[self.dataSource managerGetRealmManager] friendWithFriendNumber:friendNumber];
        OCTChat *c = [[self.dataSource managerGetRealmManager] getOrCreateChatWithFriend:f];

        OCTMessageAbstract *newAbstractMessage = [[OCTMessageAbstract alloc] init];
        newAbstractMessage.dateInterval = [NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970;
        newAbstractMessage.sender = f;
        newAbstractMessage.chat = c;
        newAbstractMessage.messageFile = newFileMessage;

        self.activeFiles[_OCTPairFriendAndFileNumber(friendNumber, fileNumber)] = [self _createReceivingFileForMessage:newAbstractMessage];

        [[self.dataSource managerGetRealmManager] addObject:newAbstractMessage];
        [[self.dataSource managerGetRealmManager] updateObject:c withBlock:^(OCTChat *theChat) {
            theChat.lastMessage = newAbstractMessage;
            theChat.lastActivityDateInterval = newAbstractMessage.dateInterval;
        }];
    }
}

@end
