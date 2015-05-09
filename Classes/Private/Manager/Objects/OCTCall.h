//
//  OCTCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OCTChat.h"

@interface OCTCall : NSObject

/**
 * OCTChat related session with the call.
 **/
@property (strong, nonatomic, readonly) OCTChat *chatSession;

/**
 * Friend related to the call.
 **/
@property (strong, nonatomic, readonly) OCTFriend *caller;

/**
 * Pause the call
 * @param pause YES to pause, NO otherwise.
 * @return YES if successful, NO otherwise.
 **/
- (BOOL)togglePauseCall:(BOOL)pause error:(NSError **)error;

/**
 * End the call. Call be ringing or in session.
 * @param error Pointer to error object if there's an issue with ending the call.
 * @return YES if successful, no otherwise.
 **/
- (BOOL)endCall:(NSError **)error;

/**
 * Mutes the call
 * @param mute YES to mute, NO otherwise.
 * @param error Pointer to error object if there's an issue muting the call.
 * @return YES if successful, NO otherwise.
 **/
- (BOOL)toggleMuteCall:(BOOL)mute error:(NSError **)error;

/**
 * The UIView that will have the video feed.
 * @return UIView of the video feed. Nil if no video available.
 **/
- (UIView *)videoFeed;


/**
 * Set the Audio bit rate.
 */
- (void)setAudioBitrate:(int)bitrate;

/**
 * Set the Video bit rate.
 */
- (void)setVideoBitrate:(int)bitrate;

@end
