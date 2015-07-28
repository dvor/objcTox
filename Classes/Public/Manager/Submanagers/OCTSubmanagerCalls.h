//
//  OCTSubmanagerCalls.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OCTChat.h"
#import "OCTToxAVConstants.h"
#import "OCTSubmanagerCallsDelegate.h"

@class OCTSubmanagerCalls;
@class OCTToxAV;
@class OCTCall;

@interface OCTSubmanagerCalls : NSObject

@property (weak, nonatomic) id<OCTSubmanagerCallDelegate> delegate;

/**
 * Set the property to YES to enable the microphone, otherwise NO.
 * Default value is YES at the start of every call;
 **/
@property (nonatomic, assign) BOOL enableMicrophone;

/**
 * This must be called once after initialization.
 * @param error Pointer to an error when setting up.
 * @return YES on success, otherwise NO.
 */
- (BOOL)setupWithError:(NSError **)error;

/**
 * This class is responsible for telling the end-user what calls we have available.
 * We can also initialize a call session from here.
 * @param chat The chat for which we would like to initiate a call.
 * @param enableAudio YES for Audio, otherwise NO.
 * @param enableVideo YES for Video, otherwise NO.
 * @param error Pointer to an error when attempting to answer a call
 * @return OCTCall session
 */
- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error;

/**
 * Answer a call
 * @param call The call session we would like to answer
 * @param enableAudio YES for Audio, otherwise NO.
 * @param enableVideo YES for Video, otherwise NO.
 * @param error Pointer to an error when attempting to answer a call
 * @return YES if we were able to succesfully answer the call, otherwise NO.
 */
- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError **)error;

/**
 * Send the audio to the speaker
 * @param speaker YES to send audio to speaker, NO to reset to default.
 * @param error Pointer to error object.
 * @return YES if successful, otherwise NO.
 */
- (BOOL)routeAudioToSpeaker:(BOOL)speaker error:(NSError **)error;

/**
 * Send call control to call.
 * @param control The control to send to call.
 * @param call The appopriate call to send to.
 * @param error Pointer to error object if there's an issue muting the call.
 * @return YES if succesful, NO otherwise.
 */
- (BOOL)sendCallControl:(OCTToxAVCallControl)control toCall:(OCTCall *)call error:(NSError **)error;

/**
 * The UIView that will have the video feed.
 * @param call The call that has the video feed.
 * @return UIView of the video feed. Nil if no video available.
 */
- (UIView *)videoFeedForCall:(OCTCall *)call;

/**
 * The preview video of the user.
 * You must be in a video call for this to show. Otherwise the layer will
 * just be black.
 * @return CALayer of the preview. Nil if not available.
 */
- (CALayer *)videoCallPreview;

/**
 * Set the Audio bit rate.
 * @param bitrate The bitrate to change to.
 * @param call The Call to set the bitrate for.
 * @param error Pointer to error object if there's an issue setting the bitrate.
 */
- (BOOL)setAudioBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error;

/**
 * Set the Video bit rate.
 * @param bitrate The bitrate to change to.
 * @param call The call to set the bitrate for.
 * @param error Pointer to error object if there's an issue setting the bitrate.
 */
- (BOOL)setVideoBitrate:(int)bitrate forCall:(OCTCall *)call error:(NSError **)error;

@end
