//
//  OCTActiveFile+Variants.h
//  objcTox
//
//  Created by stal on 9/7/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import "OCTSubmanagerFiles.h"
#import "OCTActiveFile.h"

@class OCTMessageFile;

@interface OCTActiveFile ()

@property (weak, atomic)   OCTSubmanagerFiles *fileManager;
// Observation: I'd rather not hold on to a Realm object. Who knows what could
//              happen.
@property (strong, atomic) OCTMessageFile     *fileMessage;
@property (atomic)         OCTToxFriendNumber friendNumber;
@property (atomic)         OCTToxFileSize fileSize;

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
