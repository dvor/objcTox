//
//  OCTActiveFile+Variants.h
//  objcTox
//
//  Created by stal on 9/7/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import "OCTSubmanagerFiles.h"
#import "OCTActiveFile.h"

#define AVERAGE_SECONDS 10

@class OCTMessageFile;

@interface OCTActiveFile ()

@property (weak)      OCTSubmanagerFiles *fileManager;
// Observation: I'd rather not hold on to a Realm object. Who knows what could
//              happen.
@property (strong)    OCTMessageFile     *fileMessage;
@property             OCTToxFriendNumber friendNumber;
@property             OCTToxFileSize fileSize;
@property (readwrite) OCTToxFileSize bytesMoved;
@property             BOOL isConduitOpen;

@property             time_t lastCountedTime;
@property             OCTToxFileSize     *transferRateCounters;
@property             long rollingIndex;

@property (strong)    OCTFileNotificationBlock notificationBlock;

/* Helpful if a bit unclean. */
- (id<OCTFileConduit>)conduit;

- (void)sendProgressUpdateNow;
- (void)control:(OCTToxFileControl)ctl;
- (void)interrupt;

@end

@interface OCTActiveOutboundFile : OCTActiveFile

@property (strong) id<OCTFileSending> sender;

- (void)completeFileTransferAndClose;
- (void)sendChunkForSize:(size_t)csize fromPosition:(OCTToxFileSize)p;

@end

@interface OCTActiveInboundFile : OCTActiveFile

@property (strong) id<OCTFileReceiving> receiver;

- (void)completeFileTransferAndClose;
- (void)receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p;

@end
