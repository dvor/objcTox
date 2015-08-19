//
//  OCTConversationViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 23.05.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>

#import "OCTConversationViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTChat.h"
#import "OCTMessageAbstract.h"
#import "OCTSubmanagerObjects.h"
#import "OCTSubmanagerChats.h"

@interface OCTConversationViewController () <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) OCTChat *chat;
@property (strong, nonatomic) RBQFetchedResultsController *resultsController;

@end

@implementation OCTConversationViewController

- (instancetype)initWithManager:(OCTManager *)manager chat:(OCTChat *)chat
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    _chat = chat;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"chat.uniqueIdentifier == %@", chat.uniqueIdentifier];
    RBQFetchRequest *fetchRequest = [self.manager.objects fetchRequestForType:OCTFetchRequestTypeMessageAbstract withPredicate:predicate];

    _resultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                sectionNameKeyPath:nil
                                                                         cacheName:nil];
    _resultsController.delegate = self;
    [_resultsController performFetch];

    self.title = [NSString stringWithFormat:@"%@", chat.uniqueIdentifier];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    __weak OCTConversationViewController *weakSelf = self;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              bk_initWithBarButtonSystemItem:UIBarButtonSystemItemAdd handler:^(id handler) {
        [weakSelf showSendDialog];
    }];
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.resultsController numberOfRowsForSectionIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTMessageAbstract *message = [self.resultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = [message description];

    return cell;
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
        [self.resultsController reset];
        [self.tableView reloadData];
    }
}

#pragma mark -  Private

- (void)showSendDialog
{
    __weak OCTConversationViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Send message" handler:^{
            [weakSelf sendMessage];
        }];
    }];
}

- (void)sendMessage
{
    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Send friend request" message:nil];

    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *messageField = [alert textFieldAtIndex:0];
    messageField.placeholder = @"Message";

    __weak OCTConversationViewController *weakSelf = self;
    [alert bk_addButtonWithTitle:@"OK" handler:^{
        [weakSelf.manager.chats sendMessageToChat:weakSelf.chat text:messageField.text type:OCTToxMessageTypeNormal error:nil];
        [weakSelf.tableView reloadData];
    }];

    [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

    [alert show];
}

@end
