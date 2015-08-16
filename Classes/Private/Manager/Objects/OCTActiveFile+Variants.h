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
// Realm identifier
@property (copy, atomic)   NSString           *fileIdentifier;
@property (atomic)         OCTToxFriendNumber friendNumber;
@property (atomic)         OCTToxFileNumber fileNumber;
@property (atomic)         OCTToxFileSize fileSize;

- (NSData *)archiveConduit;
- (void)control:(OCTToxFileControl)ctl;
- (void)interrupt;

@end

@interface OCTActiveOutgoingFile : OCTActiveFile

@property (strong, atomic) id<OCTFileSending> sender;

- (void)completeFileTransferAndClose;
- (void)sendChunkForSize:(size_t)csize fromPosition:(OCTToxFileSize)p;

@end

@interface OCTActiveIncomingFile : OCTActiveFile

@property (strong, atomic) id<OCTFileReceiving> receiver;

- (void)completeFileTransferAndClose;
- (void)receiveChunkNow:(const uint8_t *)chunk length:(size_t)length atPosition:(OCTToxFileSize)p;

@end
