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
- (id<OCTFileConduit>)_conduit;

- (void)_sendProgressUpdateNow;
- (void)_control:(OCTToxFileControl)ctl;

@end

@interface OCTActiveOutboundFile : OCTActiveFile

@property (strong) id<OCTFileSending> sender;

@end

@interface OCTActiveInboundFile : OCTActiveFile

@property (strong) id<OCTFileReceiving> receiver;

- (void)_completeFileTransferAndClose;
- (void)_receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p;

@end
