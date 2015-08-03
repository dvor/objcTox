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


- (nullable OCTActiveFile *)saveFileFromMessage:(nonnull OCTMessageAbstract *)msg
                                  usingReceiver:(nonnull id<OCTFileReceiving>)saver
                                          error:(NSError *_Nullable *_Nullable)error
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

- (nonnull OCTActiveFile *)_createSendingFileForFriend:(OCTFriend *)f message:(OCTMessageFile *)msg provider:(id<OCTFileSending>)prov
{
    OCTActiveOutboundFile *ret = [[OCTActiveOutboundFile alloc] init];
    ret.fileManager = self;
    ret.fileMessage = msg;
    ret.friendNumber = f.friendNumber;
    ret.sender = prov;
    return ret;
}

- (nonnull OCTActiveFile *)_createReceivingFileForMessage:(OCTMessageAbstract *)f
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

#pragma mark - OCTToxDelegate.

- (void)tox:(OCTTox *)tox fileChunkRequestForFileNumber:(OCTToxFileNumber)fileNumber friendNumber:(OCTToxFriendNumber)friendNumber position:(OCTToxFileSize)position length:(size_t)length {}

- (void)     tox:(OCTTox *)tox fileReceiveChunk:(const uint8_t *)chunk
          length:(size_t)length
      fileNumber:(OCTToxFileNumber)fileNumber
    friendNumber:(OCTToxFriendNumber)friendNumber
        position:(OCTToxFileSize)position
{
    OCTActiveInboundFile *inboundFile = (OCTActiveInboundFile *)[self activeFileForFriendNumber:friendNumber fileNumber:fileNumber];

    NSAssert([inboundFile isMemberOfClass:[OCTActiveInboundFile class]], @"Received a chunk for a bad file %@!", inboundFile);

    if (length == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [inboundFile _completeFileTransferAndClose];
            [self.activeFiles removeObjectForKey:_OCTPairFriendAndFileNumber(friendNumber, fileNumber)];
        });
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

    if (control == OCTToxFileControlCancel) {
        DDLogDebug(@"Going to deallocate %@ because of a cancel control from remote. Bye.", f);
        [self.activeFiles removeObjectForKey:key];
    }
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
