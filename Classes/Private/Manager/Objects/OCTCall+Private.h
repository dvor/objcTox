//
//  OCTCall+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/6/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall.h"

@interface OCTCall (Private)

- (instancetype)initCallWithChat:(OCTChat *)chat;

@property (nonatomic, assign, readwrite) OCTCallStatus status;

- (void)startTimer;
- (void)stopTimer;

@end
