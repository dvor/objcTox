//
//  OCTCall.h
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OCTMessageCall.h"
#import "OCTFriend.h"

typedef NS_ENUM(NSUInteger, OCTCallStatus) {
    OCTCallStatusInactive = 0,
    OCTCallStatusPaused,
    OCTCallStatusActive,
};

@interface OCTCall : NSObject

/**
 * Friends related to the call.
 **/
@property (strong, nonatomic, readonly) NSArray *friends;

/**
 * Call status.
 **/
@property (nonatomic, assign, readonly) OCTCallStatus status;

/**
 * Last call that was made.
 **/
@property (nonatomic, assign, readonly) OCTMessageCall *lastCall;
@end
