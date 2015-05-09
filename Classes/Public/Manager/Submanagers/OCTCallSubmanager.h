//
//  OCTCallSubmanager.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "OCTChat.h"
#include "OCTCall.h"
#include "OCTArray.h"

@class OCTCallSubmanager;

@protocol OCTCallSubmanagerDelegate <NSObject>

/**
 * Delegate for when we receive a call.
 **/
- (void)callSubmanager:(OCTCallSubmanager *)callSubmanager receiveCall:(OCTCall *)call audioEnabled:(BOOL)audioEnabled videoEnabled:(BOOL)videoEnabled;

@end

@interface OCTCallSubmanager : NSObject

/**
 * Call sessions that are active.
 */
@property (strong, nonatomic, readonly) OCTArray *calls;
/**
 * This class is responsible for telling the end-user what calls we have available.
 * We can also initialize a call session from here.
 * @param chat The chat for which we would like to initiate a call.
 * @param enableAudio YES for Audio, otherwise NO.
 * @param enableVideo YES for Video, otherwise NO.
 * @return OCTCall session
 */
- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo;

/**
 * Answer a call
 * @param call The call session we would like to answer
 * @param enableAudio YES for Audio, otherwise NO.
 * @param enableVideo YES for Video, otherwise NO.
 * @param error Pointer to an error when attempting to answer a call
 * @return YES if we were able to succesfully answer the call, otherwise NO.
 **/
- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError**)error;

@end
