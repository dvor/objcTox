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
 * This method will return nil if the file's state is not Paused or Loading.
 * To get a file that's WaitingConfirmation, use -saveFileFromMessage:... .
 * @param file An OCTAbstractMessage with a non-null messageFile.
 */
- (nullable OCTActiveFile *)activeFileForMessage:(nonnull OCTMessageAbstract *)file;

@end
