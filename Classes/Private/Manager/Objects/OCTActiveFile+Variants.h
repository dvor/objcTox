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

@interface OCTBaseActiveFile ()

@property (assign, readwrite) OCTToxFileSize bytesMoved;
@property (weak, atomic)      OCTSubmanagerFiles *fileManager;
@property (assign, atomic)    OCTToxFriendNumber friendNumber;
@property (assign, atomic)    OCTToxFileNumber fileNumber;
@property (assign, atomic)    OCTToxFileSize fileSize;

- (NSData *)archiveConduit;
- (void)control:(OCTToxFileControl)ctl;
- (void)completeFileTransferAndClose;
- (void)interrupt;

- (void)sendChunkForSize:(size_t)csize fromPosition:(OCTToxFileSize)p;
- (void)receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p;

/* Handy subclassing things */
- (void)resumeControl;
- (void)pauseControl;
- (void)cancelControl;
- (void)stopFileNow;

@end

@interface OCTActiveFile ()

// Realm identifier
@property (copy, atomic)   NSString           *fileIdentifier;

- (void)updateStateAndChokeFromMessage;

@end

@interface OCTActiveOutgoingFile : OCTActiveFile

@property (strong, atomic) id<OCTFileSending> sender;

@end

@interface OCTActiveIncomingFile : OCTActiveFile

@property (strong, atomic) id<OCTFileReceiving> receiver;

@end
