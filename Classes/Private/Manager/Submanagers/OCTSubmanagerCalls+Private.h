//
//  OCTSubmanagerCalls+Private.h
//  objcTox
//
//  Created by Chuong Vu on 6/4/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTSubmanagerCalls.h"
#import "OCTSubmanagerDataSource.h"
#import "OCTToxAV.h"
#import "OCTManagerConstants.h"
#import "OCTAudioEngine.h"
#import "OCTVideoEngine.h"
#import "OCTRealmManager.h"
#import "RBQFetchRequest.h"
#import "OCTCall.h"
#import "OCTCallTimer.h"

@class OCTTox;

@interface OCTSubmanagerCalls (Private)

@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

/**
 * Initialize the OCTSubmanagerCall
 *
 */
- (instancetype)initWithTox:(OCTTox *)tox;

@end
