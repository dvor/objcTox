//
//  OCTDBCall.h
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Realm/Realm.h>
#import "OCTDBFriend.h"
#import "OCTDBMessageAbstract.h"

@interface OCTDBCall : RLMObject

/**
 * If no uniqueIdentifier is specified on call creation, random one will be used.
 */
@property NSString *uniqueIdentifier;

@property RLMArray<OCTDBFriend> *friends;
@property OCTDBMessageAbstract *lastCall;

@property NSTimeInterval callDuration;

@end
