//
//  OCTCall+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/6/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCall.h"

@interface OCTCall (Private)

- (instancetype)initWithCallWithFriend:(OCTFriend *)friend;

@property (copy, nonatomic, readwrite) NSString *uniqueIdentifier;

@property (strong, nonatomic, readwrite) NSArray *friends;
@property (strong, nonatomic, readwrite) OCTMessageAbstract *lastCall;
@property (nonatomic, assign, readwrite) OCTCallStatus status;

@end
