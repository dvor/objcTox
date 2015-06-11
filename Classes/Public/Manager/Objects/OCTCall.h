//
//  OCTCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTChat.h"
#import "OCTFriend.h"

typedef NS_ENUM(NSUInteger, OCTCallStatus) {
    OCTCallStatusInactive = 0,
    OCTCallStatusDialing,
    OCTCallStatusIncoming,
    OCTCallStatusPaused,
    OCTCallStatusActive,
};

@interface OCTCall : NSObject

/**
 * OCTChat related session with the call.
 **/
@property (strong, nonatomic, readonly) OCTChat *chat;

/**
 * Call status
 **/
@property (nonatomic, assign, readonly) OCTCallStatus status;

/**
 * Call duration
 **/
@property (nonatomic, assign, readonly) NSTimeInterval callDuration;

@end
