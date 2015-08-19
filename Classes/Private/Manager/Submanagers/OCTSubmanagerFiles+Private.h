//
//  OCTSubmanagerFiles+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFiles.h"
#import "OCTSubmanagerProtocol.h"

@class OCTMessageFile;
@interface OCTSubmanagerFiles (Private) <OCTSubmanagerProtocol>

@property (weak, atomic) dispatch_queue_t queue;

- (void)setState:(OCTMessageFileState)state forFile:(OCTActiveFile *)file cleanInternals:(BOOL)clean andRunBlock:(void (^)(OCTMessageFile *theObject))extraBlock;
- (void)setState:(OCTMessageFileState)state andArchiveConduitForFile:(OCTActiveFile *)file withPauseFlags:(OCTPauseFlags)flag;
- (void)removeFile:(OCTBaseActiveFile *)file;

@end
