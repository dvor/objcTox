//
//  OCTConverterCall.m
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTConverterCall.h"
#import "OCTConverterFriend.h"
#import "OCTConverterMessage.h"
#import "OCTDBCall.h"
#import "OCTCall+Private.h"
#import "OCTMessageCall+Private.h"

@implementation OCTConverterCall

#pragma mark -  OCTConverterProtocol

- (NSString *)objectClassName
{
    return NSStringFromClass([OCTCall class]);
}

- (NSString *)dbObjectClassName
{
    return NSStringFromClass([OCTDBCall class]);
}

- (id)objectFromRLMObject:(OCTDBCall *)rlmObject
{
    NSParameterAssert(rlmObject);
    NSParameterAssert(self.converterMessage);
    NSParameterAssert(self.converterFriend);

    OCTCall *call = [OCTCall new];
    call.uniqueIdentifier = rlmObject.uniqueIdentifier;

    NSMutableArray *friends = [NSMutableArray new];

    for (OCTDBFriend *dbFriend in rlmObject.friends) {
        OCTFriend *friend = (OCTFriend *)[self.converterFriend objectFromRLMObject:dbFriend];
        [friends addObject:friend];
    }

    call.friends = [friends copy];
    if (rlmObject.lastCall) {
        // avoiding retain cycle
        call.lastCall = (OCTMessageAbstract *)[self.converterMessage objectFromRLMObjectWithoutChat:rlmObject.lastCall];
    }

    return call;
}

- (RLMSortDescriptor *)rlmSortDescriptorFromDescriptor:(OCTSortDescriptor *)descriptor
{
    NSParameterAssert(descriptor);

    NSDictionary *mapping = @{
        NSStringFromSelector(@selector(date)) : NSStringFromSelector(@selector(dateInterval)),
    };

    NSString *rlmProperty = mapping[descriptor.property];

    if (! rlmProperty) {
        return nil;
    }

    return [RLMSortDescriptor sortDescriptorWithProperty:rlmProperty ascending:descriptor.ascending];
}


@end
