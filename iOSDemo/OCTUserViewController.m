//
//  OCTUserViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/UIActionSheet+BlocksKit.h>

#import "OCTUserViewController.h"
#import "OCTStartDemoViewController.h"
#import "AppDelegate.h"
#import "OCTSubmanagerUser.h"

typedef NS_ENUM(NSUInteger, Row) {
    RowConnectionStatus,
    RowAddress,
    RowPublicKey,
    RowNospam,
    RowStatus,
    RowName,
    RowStatusMessage,
    RowLogOut,
};

@interface OCTUserViewController () <OCTSubmanagerUserDelegate>

@property (strong, nonatomic) NSArray *userData;

@end

@implementation OCTUserViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    manager.user.delegate = self;

    _userData = @[
        @(RowConnectionStatus),
        @(RowAddress),
        @(RowPublicKey),
        @(RowNospam),
        @(RowStatus),
        @(RowName),
        @(RowStatusMessage),
        @(RowLogOut),
    ];

    self.title = @"User";

    return self;
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    __weak OCTUserViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        switch (indexPath.row) {
            case RowConnectionStatus:
                // nop
                break;
            case RowAddress:
                [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.userAddress];
                break;
            case RowPublicKey:
                [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.publicKey];
                break;
            case RowNospam:
                {
                    [weakSelf addToSheet:sheet copyButtonWithValue:@(weakSelf.manager.user.nospam)];
                    [weakSelf addToSheet:sheet textEditButtonWithValue:@(weakSelf.manager.user.nospam) block:^(NSString *string) {
                    weakSelf.manager.user.nospam = (OCTToxNoSpam)[string integerValue];
                }];
                    break;
                }
            case RowStatus:
                {
                    [weakSelf addToSheet:sheet multiEditButtonWithOptions:@[
                         [weakSelf stringFromUserStatus:0],
                         [weakSelf stringFromUserStatus:1],
                         [weakSelf stringFromUserStatus:2],

                     ] block:^(NSUInteger index) {
                    weakSelf.manager.user.userStatus = index;
                }];
                    break;
                }
            case RowName:
                {
                    [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.userName];
                    [weakSelf addToSheet:sheet textEditButtonWithValue:weakSelf.manager.user.userName block:^(NSString *string) {
                    NSError *error;
                    [weakSelf.manager.user setUserName:string error:&error];
                    [self maybeShowError:error];
                }];
                    break;
                }
            case RowStatusMessage:
                {
                    [weakSelf addToSheet:sheet copyButtonWithValue:weakSelf.manager.user.userStatusMessage];
                    [weakSelf addToSheet:sheet textEditButtonWithValue:weakSelf.manager.user.userStatusMessage block:^(NSString *string) {
                    NSError *error;
                    [weakSelf.manager.user setUserStatusMessage:string error:&error];
                    [self maybeShowError:error];
                }];
                    break;
                }
            case RowLogOut:
                {
                    [sheet bk_addButtonWithTitle:@"Log out" handler:^{
                    [weakSelf logOut];
                }];
                    break;
                }
        }
    }];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.userData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    Row row = indexPath.row;

    switch (row) {
        case RowConnectionStatus:
            cell.textLabel.text = [NSString stringWithFormat:@"connectionStatus: %@",
                                   [self stringFromConnectionStatus:self.manager.user.connectionStatus]];
            break;
        case RowAddress:
            cell.textLabel.text = [NSString stringWithFormat:@"userAddress: %@", self.manager.user.userAddress];
            break;
        case RowPublicKey:
            cell.textLabel.text = [NSString stringWithFormat:@"publicKey: %@", self.manager.user.publicKey];
            break;
        case RowNospam:
            cell.textLabel.text = [NSString stringWithFormat:@"nospam: %u", self.manager.user.nospam];
            break;
        case RowStatus:
            cell.textLabel.text = [NSString stringWithFormat:@"userStatus: %@",
                                   [self stringFromUserStatus:self.manager.user.userStatus]];
            break;
        case RowName:
            cell.textLabel.text = [NSString stringWithFormat:@"userName: %@", self.manager.user.userName];
            break;
        case RowStatusMessage:
            cell.textLabel.text = [NSString stringWithFormat:@"userStatusMessage: %@", self.manager.user.userStatusMessage];
            break;
        case RowLogOut:
            cell.textLabel.text = @"Log Out";
            break;
    }

    return cell;
}

#pragma mark -  OCTSubmanagerUserDelegate

- (void)OCTSubmanagerUser:(OCTSubmanagerUser *)submanager connectionStatusUpdate:(OCTToxConnectionStatus)connectionStatus
{
    [self.tableView reloadData];
}

#pragma mark -  Private

- (void)logOut
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.window.rootViewController = [OCTStartDemoViewController new];
}

@end
