//
//  OCTDBCall.m
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTDBCall.h"

@implementation OCTDBCall

+ (NSString *)primaryKey
{
    return @"uniqueIdentifier";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{
               @"uniqueIdentifier" : [[NSUUID UUID] UUIDString],
    };
}

@end
