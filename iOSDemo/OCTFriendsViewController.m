//
//  OCTFriendsViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>

#import "OCTFriendsViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTFriend.h"
#import "OCTFriendRequest.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerChats.h"
#import "OCTSubmanagerFriends.h"

typedef NS_ENUM(NSUInteger, SectionType) {
    SectionTypeFriends = 0,
    SectionTypeFriendRequests,
    SectionTypeCount,
};

@interface OCTFriendsViewController () <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) RBQFetchedResultsController *friendResultsController;
@property (strong, nonatomic) RBQFetchedResultsController *friendRequestResultsController;

@end

@implementation OCTFriendsViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    RBQFetchRequest *fetchRequest = [self.manager.objects fetchRequestForType:OCTFetchRequestTypeFriend withPredicate:nil];

    _friendResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];
    _friendResultsController.delegate = self;
    [_friendResultsController performFetch];

    fetchRequest = [self.manager.objects fetchRequestForType:OCTFetchRequestTypeFriendRequest withPredicate:nil];

    _friendRequestResultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                             sectionNameKeyPath:nil
                                                                                      cacheName:nil];
    _friendRequestResultsController.delegate = self;
    [_friendRequestResultsController performFetch];

    self.title = @"Friends";

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak OCTFriendsViewController *weakSelf = self;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id handler) {
        [weakSelf sendFriendRequest];
    }];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    SectionType type = indexPath.section;
    NSIndexPath *normalized = [self normalizeIndexPath:indexPath];

    switch (type) {
        case SectionTypeFriends:
            [self didSelectFriend:[self.friendResultsController objectAtIndexPath:normalized]];
            break;
        case SectionTypeFriendRequests:
            [self didSelectFriendRequest:[self.friendRequestResultsController objectAtIndexPath:normalized]];
            break;
        case SectionTypeCount:
            // nop
            break;
    }
}

#pragma mark -  UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionTypeCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    SectionType type = section;

    switch (type) {
        case SectionTypeFriends:
            return [self.friendResultsController numberOfRowsForSectionIndex:0];
        case SectionTypeFriendRequests:
            return [self.friendRequestResultsController numberOfRowsForSectionIndex:0];
        case SectionTypeCount:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    SectionType type = section;

    switch (type) {
        case SectionTypeFriends:
            return @"Friends";
        case SectionTypeFriendRequests:
            return @"FriendRequests";
        case SectionTypeCount:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SectionType type = indexPath.section;

    switch (type) {
        case SectionTypeFriends:
            return [self friendCellAtIndexPath:indexPath];
        case SectionTypeFriendRequests:
            return [self friendRequestCellAtIndexPath:indexPath];
        case SectionTypeCount:
            return nil;
    }
}

#pragma mark -  RBQFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void) controller:(RBQFetchedResultsController *)controller
    didChangeObject:(RBQSafeRealmObject *)anObject
        atIndexPath:(NSIndexPath *)indexPath
      forChangeType:(RBQFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath *)newIndexPath
{
    if ([controller isEqual:self.friendResultsController]) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:SectionTypeFriends];
        newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:SectionTypeFriends];
    }
    else if ([controller isEqual:self.friendRequestResultsController]) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:SectionTypeFriendRequests];
        newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:SectionTypeFriendRequests];
    }

    switch (type) {
        case RBQFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case RBQFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case RBQFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case RBQFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controllerDidChangeContent:(RBQFetchedResultsController *)controller
{
    @try {
        [self.tableView endUpdates];
    }
    @catch (NSException *ex) {
        [controller reset];
        [self.tableView reloadData];
    }
}


#pragma mark -  Private

- (UITableViewCell *)friendCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *normalized = [self normalizeIndexPath:indexPath];

    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    OCTFriend *friend = [self.friendResultsController objectAtIndexPath:normalized];

    cell.textLabel.text = [NSString stringWithFormat:@"Friend\n"
                           @"friendNumber %u\n"
                           @"publicKey %@\n"
                           @"name %@\n"
                           @"nickname %@\n"
                           @"statusMessage %@\n"
                           @"status %@\n"
                           @"isConnected %d\n"
                           @"connectionStatus %@\n"
                           @"lastSeenOnline %@\n"
                           @"isTyping %d",
                           friend.friendNumber,
                           friend.publicKey,
                           friend.name,
                           friend.nickname,
                           friend.statusMessage,
                           [self stringFromUserStatus:friend.status],
                           friend.isConnected,
                           [self stringFromConnectionStatus:friend.connectionStatus],
                           friend.lastSeenOnline,
                           friend.isTyping];

    return cell;
}

- (UITableViewCell *)friendRequestCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *normalized = [self normalizeIndexPath:indexPath];

    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    OCTFriendRequest *request = [self.friendRequestResultsController objectAtIndexPath:normalized];

    cell.textLabel.text = [NSString stringWithFormat:@"Friend request\n"
                           @"publicKey %@\n"
                           @"message %@\n",
                           request.publicKey, request.message];

    return cell;
}

- (void)didSelectFriend:(OCTFriend *)friend
{
    __weak OCTFriendsViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Create chat" handler:^{
            [weakSelf.manager.chats getOrCreateChatWithFriend:friend];
        }];

        [sheet bk_addButtonWithTitle:@"Remove" handler:^{
            [weakSelf.manager.friends removeFriend:friend error:nil];
        }];
    }];
}

- (void)didSelectFriendRequest:(OCTFriendRequest *)request
{
    __weak OCTFriendsViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Add" handler:^{
            [weakSelf.manager.friends approveFriendRequest:request error:nil];
        }];

        [sheet bk_addButtonWithTitle:@"Remove" handler:^{
            [weakSelf.manager.friends removeFriendRequest:request];
        }];
    }];
}

- (void)sendFriendRequest
{
    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Send friend request" message:nil];

    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    UITextField *addressField = [alert textFieldAtIndex:0];
    addressField.placeholder = @"Address";
    UITextField *messageField = [alert textFieldAtIndex:1];
    messageField.placeholder = @"Message";
    messageField.secureTextEntry = NO;

    __weak OCTFriendsViewController *weakSelf = self;
    [alert bk_addButtonWithTitle:@"OK" handler:^{
        [weakSelf.manager.friends sendFriendRequestToAddress:addressField.text message:messageField.text error:nil];
        [weakSelf.tableView reloadData];
    }];

    [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

    [alert show];
}

- (NSIndexPath *)normalizeIndexPath:(NSIndexPath *)indexPath
{
    return [NSIndexPath indexPathForRow:indexPath.row inSection:0];
}

@end
