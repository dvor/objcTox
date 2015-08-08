//
//  OCTFileConduit.h
//  objcTox
//
//  Created by stal on 7/8/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTTox.h"
#import "OCTActiveFile.h"

@class OCTMessageAbstract;

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
 * Return the full path of the source file on disk if applicable.
 */
- (nullable NSString *)path;

@required
/**
 * Return the size in bytes of the file that is being offered.
 * This method may be called at any time (including before a call to
 * -transferWillBecomeActive:).
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

- (nonnull instancetype)initWithPath:(nonnull NSString *)path;

@end

@interface OCTFileOutput : NSObject <OCTFileReceiving, NSCoding>

@end
