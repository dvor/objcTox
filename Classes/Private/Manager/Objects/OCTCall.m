//
//  OCTCall.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall+Private.h"

@interface OCTCall ()

@end

@implementation OCTCall

- (instancetype)initWithCallWithFriend:(OCTFriend *)friend
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _friends = @[friend];

    return self;
}

@end
