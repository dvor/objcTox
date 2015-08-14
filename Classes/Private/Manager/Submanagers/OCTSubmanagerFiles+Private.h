//
//  OCTSubmanagerFiles+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFiles.h"
#import "OCTSubmanagerProtocol.h"

@interface OCTSubmanagerFiles (Private) <OCTSubmanagerProtocol>

@property (weak, atomic) dispatch_queue_t queue;

- (void)sendProgressNotificationsNow;
- (void)scheduleProgressNotificationForFile:(OCTActiveFile *)f;

- (void)removeFile:(OCTActiveFile *)file;

@end
