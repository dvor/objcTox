//
//  OCTSubmanagerFiles.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTTox.h"
#import "OCTManagerConstants.h"
#import "OCTActiveFile.h"

@class OCTMessageAbstract, OCTChat;

/**
 * The OCTFileSending and OCTFileReceiving protocols act as a go-between
 * for Tox file transfers and the filesystem (or whatever you want to do
 * with the files.
 * Resuming for file transfers are automatically available on two conditions:
 * - The conforming class also conforms to NSCoding.
 * - You have implemented the optional method -moveToPosition:.
 */

/* Makes it easier for OCTActiveFile's implementation ;) */
@protocol OCTFileConduit <NSObject>

@optional
/**
 * Instructs the sender to seek the underlying file to `offset` from
 * the start of the file.
 * Implementation of this method is optional. If a sender does not support
 * seeking, attempts to resume the file transfer from the other side will fail.
 * @param offset The position to move to from the beginning of the file.
 */
- (BOOL)moveToPosition:(OCTToxFileSize)offset;

@required
/* Lifetime management */
/**
 * Notifies the conduit that it will be imminently used as a data source.
 * This is a good place to open the file and populate fileSize.
 */
- (BOOL)transferWillBecomeActive:(nonnull OCTActiveFile *)file;
/**
 * Notifies the conduit that it will not be seeing activity for an indefinite
 * amount of time.
 * I'll try not to deallocate you before this is called.
 */
- (void)transferWillBecomeInactive:(nonnull OCTActiveFile *)file;
/**
 * The last chunk has been sent/received
 */
- (void)transferWillComplete:(nonnull OCTActiveFile *)file;

@end

@protocol OCTFileSending <OCTFileConduit>

@required
/**
 * Return the size in bytes of the file that is being offered.
 * This method will be called any time AFTER transferWillBecomeActive:,
 * and any time BEFORE transferWillBecomeInactive:, so you can
 * prepare.
 */
- (OCTToxFileSize)fileSize;

@required
/**
 * Read at most chunk_size bytes from the underlying file and store them in
 * `buffer`. The number of bytes actually read should be returned.
 * @param chunk_size The maximum number of bytes that should be read.
 * @param buffer The target of the bytes of the read operation. Do not save this value.
 */
- (size_t)readBytes:(OCTToxFileSize)chunk_size
         intoBuffer:(nonnull uint8_t *)buffer;

@end

@protocol OCTFileReceiving <OCTFileConduit>

@required
/**
 * For OCTFileReceiving:
 * Return the full path of the received file on disk if applicable.
 * If you return nil, the file will be displayed as received, but inaccessible.
 */
- (nullable NSString *)finalDestination;

@required
/**
 * Read at most chunk_size bytes from the underlying file and store them in
 * `buffer`. The number of bytes actually read should be returned.
 * @param chunk_size The maximum number of bytes that should be read.
 * @param buffer The target of the bytes of the read operation. Do not save this value.
 */
- (void)writeBytes:(OCTToxFileSize)chunk_size
        fromBuffer:(nonnull const uint8_t *)buffer;

@end

@interface OCTFileInput : NSObject <OCTFileSending, NSCoding>

@end

@interface OCTFileOutput : NSObject <OCTFileReceiving, NSCoding>

@end

@interface OCTSubmanagerFiles : NSObject

/**
 * Allocate a default file receiver conduit that just writes chunks to disk.
 */
- (nonnull id<OCTFileReceiving>)newDefaultReceiver;

/**
 * Send a file to `chat`.
 * @param name The basename of the file
 * @param file The data source
 * ...
 */

/*
 * Implementation note: this returns OCTActiveFile for consistency reasons with
 * -saveFileFromMessage:usingReceiver:error: . I also figured you would be
 * getting the message from callbacks on RBQFetchedResultsController, etc.
 */
- (nullable OCTActiveFile *)sendFile:(nonnull NSString *)name
                         usingSender:(nonnull id<OCTFileSending>)file
                              toChat:(nonnull OCTChat *)chat
                                type:(OCTFileUsage)type
                             message:(OCTMessageAbstract *__nonnull *__nullable)msgout
                               error:(NSError *__nullable *__nullable)error;

- (nullable OCTActiveFile *)saveFileFromMessage:(nonnull OCTMessageAbstract *)msg
                                  usingReceiver:(nonnull id<OCTFileReceiving>)saver
                                          error:(NSError *__nullable *__nullable)error;

- (nullable OCTActiveFile *)activeFileForMessage:(nonnull OCTMessageAbstract *)file;

@end
