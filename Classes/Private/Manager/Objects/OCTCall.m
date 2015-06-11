//
//  OCTCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall.h"
#import "OCTAudioEngine.h"
#import "OCTToxAV.h"

@interface OCTCall ()

@property (strong, nonatomic, readwrite) OCTChat *chat;
@property (nonatomic, assign, readwrite) OCTCallStatus status;
@property (nonatomic, assign, readwrite) NSTimeInterval callDuration;
@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation OCTCall

- (instancetype)initCallWithChat:(OCTChat *)chat
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _chat = chat;

    return self;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (! [object isKindOfClass:[OCTCall class]]) {
        return NO;
    }

    OCTCall *otherCall = object;

    return (self.chat.uniqueIdentifier == otherCall.chat.uniqueIdentifier);
}

- (NSUInteger)hash
{
    return [self.chat.uniqueIdentifier hash];
}

- (void)startTimer
{
    @synchronized(self) {
        if (self.timer) {
            return;
        }
    }
    dispatch_queue_t queue = dispatch_queue_create("me.dvor.objcTox.OCTCallQueue", DISPATCH_QUEUE_SERIAL);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    uint64_t interval = NSEC_PER_SEC;
    uint64_t leeway = NSEC_PER_SEC / 1000;
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, interval, leeway);

    __weak OCTCall *weakSelf = self;
    dispatch_source_set_event_handler(self.timer, ^{
        OCTCall *strongSelf = weakSelf;
        if (! strongSelf) {
            return;
        }
        strongSelf.callDuration += 1;
    });
    dispatch_resume(self.timer);
}

- (void)stopTimer
{
    @synchronized(self) {
        if (! self.timer) {
            return;
        }
    }
    dispatch_source_cancel(self.timer);
    self.timer = nil;
}
@end
