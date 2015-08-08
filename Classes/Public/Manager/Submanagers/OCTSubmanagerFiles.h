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
#import "OCTFileConduit.h"

@class OCTMessageAbstract, OCTChat;

@interface OCTSubmanagerFiles : NSObject

/**
 * This controls whether objcTox will try to resume files transfers for you.
 * If this is NO, transfers can still be resumed on a case-by-case basis, by
 * doing...
 */
@property BOOL resumesFiles;

/**
 * Allocate a default file receiver conduit that just writes chunks to disk.
 * @return OCTFileReceiving-conforming object configured to deposit data at a location
 *         specified by your OCTManagerConfiguration.
 */
- (nonnull id<OCTFileReceiving>)newDefaultReceiver;

/**
 * Send a file to `chat`.
 * @param name The basename of the file
 * @param file The data source
 * @param chat The chat.
 * @param type A hint to the receiver on how to display the file. See `enum OCTFileUsage` for options.
 * @param msgout An output pointer where the created OCTMessageAbstract will be put if this method succeeds.
 *               Can be nil if you don't need it.
 * @param error An output pointer to NSError *. Check this if the method returns nil.
 * @return OCTActiveFile for the created transfer. It starts in the Paused state, and must be
 *         resumed by the receiver.
 */
- (nullable OCTActiveFile *)sendFile:(nonnull NSString *)name
                         usingSender:(nonnull id<OCTFileSending>)file
                              toChat:(nonnull OCTChat *)chat
                                type:(OCTFileUsage)type
                             message:(OCTMessageAbstract *__nonnull *__nullable)msgout
                               error:(NSError *__nullable *__nullable)error;

/**
 * Begin downloading the file from `msg`.
 * This will also unpause the underlying file transfer.
 * It will fail if the file message's state is not WaitingConfirmation.
 * @param msg An OCTAbstractMessage with a non-null messageFile.
 * @param saver An <OCTFileReceiving> that file data will be sent to.
 *              To get one that saves file data to the configured download folder,
 *              use -newDefaultReceiver.
 * @param error An error out pointer. Check this if I return nil.
 */
- (nullable OCTActiveFile *)saveFileFromMessage:(nonnull OCTMessageAbstract *)msg
                                  usingReceiver:(nonnull id<OCTFileReceiving>)saver
                                          error:(NSError *__nullable *__nullable)error;

/**
 * Get the OCTActiveFile for a file transfer. It can be used to pause/resume/cancel
 * the transfer.
 * To get a file that's WaitingConfirmation, use -saveFileFromMessage:... .
 * @param file An OCTAbstractMessage with a non-null messageFile.
 * @return nil if the file's state is not Paused or Loading, otherwise, an OCTActiveFile.
 */
- (nullable OCTActiveFile *)activeFileForMessage:(nonnull OCTMessageAbstract *)file;

@end
