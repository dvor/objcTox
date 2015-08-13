//
//  OCTManager.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 06.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <objc/runtime.h>

#import "OCTManager.h"
#import "OCTTox.h"
#import "OCTManagerConfiguration.h"
#import "OCTSubmanagerAvatars+Private.h"
#import "OCTSubmanagerBootstrap+Private.h"
#import "OCTSubmanagerChats+Private.h"
#import "OCTSubmanagerFiles+Private.h"
#import "OCTSubmanagerFriends+Private.h"
#import "OCTSubmanagerObjects+Private.h"
#import "OCTSubmanagerUser+Private.h"
#import "OCTRealmManager.h"

@interface OCTManager () <OCTToxDelegate, OCTSubmanagerDataSource>

@property (strong, nonatomic, readonly) OCTTox *tox;
@property (copy, nonatomic, readonly) OCTManagerConfiguration *configuration;

@property (strong, nonatomic, readwrite) OCTSubmanagerAvatars *avatars;
@property (strong, nonatomic, readwrite) OCTSubmanagerBootstrap *bootstrap;
@property (strong, nonatomic, readwrite) OCTSubmanagerChats *chats;
@property (strong, nonatomic, readwrite) OCTSubmanagerFiles *files;
@property (strong, nonatomic, readwrite) OCTSubmanagerFriends *friends;
@property (strong, nonatomic, readwrite) OCTSubmanagerObjects *objects;
@property (strong, nonatomic, readwrite) OCTSubmanagerUser *user;

@property (strong, nonatomic) OCTRealmManager *realmManager;

@property (strong, nonatomic, readonly) NSObject *toxSaveFileLock;

@end

@implementation OCTManager

#pragma mark -  Lifecycle

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration error:(NSError **)error
{
    return [self initWithConfiguration:configuration loadToxSaveFilePath:nil error:error];
}

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                  loadToxSaveFilePath:(NSString *)toxSaveFilePath
                                error:(NSError **)error
{
    self = [super init];

    if (! self) {
        return nil;
    }

    [self validateConfiguration:configuration];

    NSString *savedDataPath = configuration.fileStorage.pathForToxSaveFile;

    if (toxSaveFilePath && [[NSFileManager defaultManager] fileExistsAtPath:toxSaveFilePath]) {
        [[NSFileManager defaultManager] moveItemAtPath:toxSaveFilePath toPath:savedDataPath error:nil];
    }

    _configuration = [configuration copy];

    NSData *savedData = nil;

    if ([[NSFileManager defaultManager] fileExistsAtPath:savedDataPath]) {
        savedData = [NSData dataWithContentsOfFile:savedDataPath];
    }

    _tox = [[OCTTox alloc] initWithOptions:configuration.options savedData:savedData error:error];

    if (! _tox) {
        return nil;
    }

    _tox.delegate = self;
    [_tox start];

    if (! savedData) {
        [self saveTox];
    }

    _realmManager = [[OCTRealmManager alloc] initWithDatabasePath:configuration.fileStorage.pathForDatabase];

    _avatars = [self createSubmanagerWithClass:[OCTSubmanagerAvatars class]];
    _bootstrap = [self createSubmanagerWithClass:[OCTSubmanagerBootstrap class]];
    _chats = [self createSubmanagerWithClass:[OCTSubmanagerChats class]];
    _files = [self createSubmanagerWithClass:[OCTSubmanagerFiles class]];
    _friends = [self createSubmanagerWithClass:[OCTSubmanagerFriends class]];
    _objects = [self createSubmanagerWithClass:[OCTSubmanagerObjects class]];
    _user = [self createSubmanagerWithClass:[OCTSubmanagerUser class]];

    _toxSaveFileLock = [NSObject new];

    return self;
}

- (void)dealloc
{
    [self.tox stop];
}

#pragma mark -  Public

- (NSString *)exportToxSaveFile:(NSError **)error
{
    @synchronized(self.toxSaveFileLock) {
        NSString *savedDataPath = self.configuration.fileStorage.pathForToxSaveFile;
        NSString *tempPath = self.configuration.fileStorage.pathForTemporaryFilesDirectory;
        tempPath = [tempPath stringByAppendingPathComponent:[savedDataPath lastPathComponent]];

        if (! [[NSFileManager defaultManager] copyItemAtPath:savedDataPath toPath:tempPath error:error]) {
            return nil;
        }

        return tempPath;
    }
}

#pragma mark -  OCTSubmanagerDataSource

- (OCTTox *)managerGetTox
{
    return self.tox;
}

- (BOOL)managerIsToxConnected
{
    return (self.user.connectionStatus != OCTToxConnectionStatusNone);
}

- (void)managerSaveTox
{
    return [self saveTox];
}

- (OCTRealmManager *)managerGetRealmManager
{
    return self.realmManager;
}

- (id<OCTSettingsStorageProtocol>)managerGetSettingsStorage
{
    return self.configuration.settingsStorage;
}

- (id<OCTFileStorageProtocol>)managerGetFileStorage
{
    return self.configuration.fileStorage;
}

#pragma mark -  Private

- (void)validateConfiguration:(OCTManagerConfiguration *)configuration
{
    NSParameterAssert(configuration.settingsStorage);

    NSParameterAssert(configuration.fileStorage);
    NSParameterAssert(configuration.fileStorage.pathForDownloadedFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForUploadedFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForTemporaryFilesDirectory);
    NSParameterAssert(configuration.fileStorage.pathForAvatarsDirectory);

    NSParameterAssert(configuration.options);
}

- (id<OCTSubmanagerProtocol>)createSubmanagerWithClass:(Class)class
{
    id<OCTSubmanagerProtocol> submanager = [class new];
    submanager.dataSource = self;

    if ([submanager respondsToSelector:@selector(configure)]) {
        [submanager configure];
    }

    return submanager;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    id submanager = [self forwardingTargetForSelector:aSelector];

    if (submanager) {
        return YES;
    }

    return [super respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    struct objc_method_description description = protocol_getMethodDescription(@protocol(OCTToxDelegate), aSelector, NO, YES);

    if (description.name == NULL) {
        // We forward methods only from OCTToxDelegate protocol.
        return nil;
    }

    NSArray *submanagers = @[
        self.avatars,
        self.bootstrap,
        self.chats,
        self.files,
        self.friends,
        self.objects,
        self.user,
    ];

    for (id delegate in submanagers) {
        if ([delegate respondsToSelector:aSelector]) {
            return delegate;
        }
    }

    return nil;
}

- (void)saveTox
{
    @synchronized(self.toxSaveFileLock) {
        NSString *savedDataPath = self.configuration.fileStorage.pathForToxSaveFile;

        NSData *data = [self.tox save];

        NSError *error;

        if (! [data writeToFile:savedDataPath options:NSDataWritingAtomic error:&error]) {
            NSDictionary *userInfo = nil;

            if (error) {
                userInfo = @{ @"NSError" : error };
            }

            @throw [NSException exceptionWithName:@"saveToxException" reason:error.debugDescription userInfo:userInfo];
        }
    }
}

#pragma mark -  Deprecated

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
{
    return [self initWithConfiguration:configuration error:nil];
}

- (instancetype)initWithConfiguration:(OCTManagerConfiguration *)configuration
                  loadToxSaveFilePath:(NSString *)toxSaveFilePath
{
    return [self initWithConfiguration:configuration loadToxSaveFilePath:toxSaveFilePath error:nil];
}

- (BOOL)bootstrapFromHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey error:(NSError **)error
{
    return [self.tox bootstrapFromHost:host port:port publicKey:publicKey error:error];
}

- (BOOL)addTCPRelayWithHost:(NSString *)host port:(OCTToxPort)port publicKey:(NSString *)publicKey error:(NSError **)error
{
    return [self.tox addTCPRelayWithHost:host port:port publicKey:publicKey error:error];
}

@end
