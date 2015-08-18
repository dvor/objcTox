//
//  OCTSubmanagerFriends+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFriends.h"
#import "OCTSubmanagerProtocol.h"

/* object: OCTFriend whose status changed; userInfo: nil */
extern NSString *const kOCTFriendConnectionStatusChangeNotificationName;

@interface OCTSubmanagerFriends (Private) <OCTSubmanagerProtocol>

@end
