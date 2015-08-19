//
//  OCTConversationViewController.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 23.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTTableViewController.h"

@class OCTChat;

@interface OCTConversationViewController : OCTTableViewController

- (instancetype)initWithManager:(OCTManager *)manager chat:(OCTChat *)chat;

@end
