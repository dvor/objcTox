//
//  OCTCallsContainer.h
//  objcTox
//
//  Created by Chuong Vu on 6/10/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTCall.h"
#import "OCTFriend.h"

@class OCTCallsContainer;
@protocol OCTCallsContainerDelegate <NSObject>

@optional

/**
 * Method called on any call update (call added, status changed or called removed).
 * @param container Container that was updated.
 * @param inserted NSIndexSet with index of calls that were inserted.
 * @param removed NSIndexSet with indexes of calls that were removed.
 * @param updated NSIndexSet with indexes of calls that were updated.
 */

- (void)callsContainerUpdate:(OCTCallsContainer *)container
                 insertedSet:(NSIndexSet *)inserted
                  removedSet:(NSIndexSet *)removed
                  updatedSet:(NSIndexSet *)updated;

/**
 * Method that gets called when a call status is changed
 *
 * @param container Container that was updated.
 * @param call Call that was updated.
 */
- (void)callsContainer:(OCTCallsContainer *)container
           callUpdated:(OCTCall *)call;

@end

@interface OCTCallsContainer : NSObject

@property (weak, nonatomic) id<OCTCallsContainerDelegate> delegate;

/**
 * @return Number of calls
 */
- (NSUInteger)numberOfCalls;

/**
 * Returns call at specified index.
 * @param index Index to get call.
 * @return Call object at index. Nil if out of bounds.
 */
- (OCTCall *)callAtIndex:(NSUInteger)index;

/**
 * Returns call for specified friend.
 * @param friend Friend to look for call
 * @return Call object of that contains friend. Nil if not found.
 */
- (OCTCall *)callWithFriend:(OCTFriend *)friend;

@end
