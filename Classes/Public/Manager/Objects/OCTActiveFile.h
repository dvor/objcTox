//
//  OCTHotFile.h
//  objcTox
//
//  Created by stal on 6/7/2015.
//  Copyright © 2015 Zodiac Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCTActiveFile;

typedef void (^OCTFileNotificationBlock)(OCTActiveFile *__nonnull);

/**
 * OCTActiveFile is the part of OCTMessageFile not backed by Realm.
 */

@interface OCTActiveFile : NSObject

/**
 * How many bytes have been downloaded/uploaded so far.
 * Used in calculations for @progress and @estimatedTimeRemaining.
 */
@property (nonatomic, readonly) OCTToxFileSize bytesMoved;

/**
 * How much of transfer has been completed, on a scale from 0.0 to 1.0.
 */
@property (readonly) double progress;

/**
 * The seconds it would take to finish the download.
 * It is calculated using the average transfer speed (observed by us)
 * over the last ten seconds.
 * -1 means an indefinite amount of time.
 */
@property (readonly) NSTimeInterval estimatedTimeRemaining;

/**
 * Current speed of the file transfer.
 */
@property (readonly) OCTToxFileSize bytesPerSecond;

- (BOOL)pauseWithError:(NSError *_Nullable *_Nullable)error;
- (BOOL)resumeWithError:(NSError *_Nullable *_Nullable)error;
- (BOOL)cancelWithError:(NSError *_Nullable *_Nullable)error;

- (void)beginReceivingLiveUpdatesWithBlock:(nullable OCTFileNotificationBlock)blk;

@end
