//
//  OCTSubmanagerFiles+Private.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 24.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerFiles.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTToxDelegate.h"

@interface OCTSubmanagerFiles (Private) <OCTToxDelegate>

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

@end
