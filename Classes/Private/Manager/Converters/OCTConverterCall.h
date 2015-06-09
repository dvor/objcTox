//
//  OCTConverterCall.h
//  objcTox
//
//  Created by Chuong Vu on 6/8/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCTConverterProtocol.h"
#import "OCTConverterMessage.h"
#import "OCTConverterFriend.h"

@interface OCTConverterCall : NSObject <OCTConverterProtocol>

@property (strong, nonatomic) OCTConverterMessage *converterMessage;
@property (strong, nonatomic) OCTConverterFriend *converterFriend;

@end
