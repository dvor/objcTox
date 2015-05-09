//
//  OCTCallSubmanager.m
//  objcTox
//
//  Created by Chuong Vu on 5/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTCallSubmanager.h"

@implementation OCTCallSubmanager : NSObject

- (OCTCall *)callToChat:(OCTChat *)chat enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo
{
    return nil;
}

- (BOOL)answerCall:(OCTCall *)call enableAudio:(BOOL)enableAudio enableVideo:(BOOL)enableVideo error:(NSError**)error
{
    return NO;
}

@end
