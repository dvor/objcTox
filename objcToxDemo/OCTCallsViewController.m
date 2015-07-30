//
//  OCTCallsViewController.m
//  objcTox
//
//  Created by Chuong Vu on 6/26/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIBarButtonItem+BlocksKit.h>

#import "OCTCallsViewController.h"
#import "RBQFetchedResultsController.h"
#import "OCTSubmanagerCalls.h"
#import "OCTCall.h"

@interface OCTCallsViewController () <RBQFetchedResultsControllerDelegate>

@property (strong, nonatomic) RBQFetchedResultsController *resultsController;
@property (strong, nonatomic) OCTCall *selectedCall;
@property (strong, nonatomic) UIView *previewVideoView;

@end

@implementation OCTCallsViewController

#pragma mark - Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super initWithManager:manager];

    if (! self) {
        return nil;
    }

    RBQFetchRequest *fetchRequest = [self.manager.objects fetchRequestForType:OCTFetchRequestTypeCall withPredicate:nil];

    _resultsController = [[RBQFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                sectionNameKeyPath:nil
                                                                         cacheName:nil];
    _resultsController.delegate = self;
    [_resultsController performFetch];

    self.title = @"Calls";

    return self;
}

#pragma mark -  UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCall = [self.resultsController objectAtIndexPath:indexPath];

    [self showActionDialog];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];

    OCTCall *call = [self.resultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = [NSString stringWithFormat:@"Call\n"
                           @"Chat identifier %@\n"
                           @"call status: %ld\n"
                           @"callDuration: %f\n"
                           @"friend sending audio: %d\n"
                           @"friend receiving audio: %d\n"
                           @"friend sending video: %d\n"
                           @"friend receiving Video: %d\n",
                           call.chat.uniqueIdentifier, call.status, call.callDuration, call.friendSendingAudio, call.friendAcceptingAudio,
                           call.friendSendingVideo, call.friendAcceptingVideo];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.resultsController numberOfRowsForSectionIndex:section];
}

#pragma mark -  RBQFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(RBQFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void) controller:(RBQFetchedResultsController *)controller
    didChangeObject:(RBQSafeRealmObject *)anObject
        atIndexPath:(NSIndexPath *)indexPath
      forChangeType:(NSFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            break;
        case NSFetchedResultsChangeMove:
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

#pragma mark - Private

- (void)showActionDialog
{
    __weak OCTCallsViewController *weakSelf = self;

    [self showActionSheet:^(UIActionSheet *sheet) {
        [sheet bk_addButtonWithTitle:@"Send call controls" handler:^{
            [weakSelf showSendControlDialog];
        }];

        [sheet bk_addButtonWithTitle:@"Mute/Unmute Mic" handler:^{
            [weakSelf toggleMuteMic];
        }];

        [sheet bk_addButtonWithTitle:@"Use speaker phone" handler:^{
            [weakSelf useSpeaker];
        }];

        [sheet bk_addButtonWithTitle:@"Use default speakers" handler:^{
            [weakSelf useDefaultSpeaker];
        }];

        [sheet bk_addButtonWithTitle:@"Video preview" handler:^{
            [weakSelf showVideoPreview];
        }];
    }];

}

- (void)showSendControlDialog
{
    __weak OCTCallsViewController *weakSelf = self;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Call control"
                                                                             message:@"Pick call control to send to friend"
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *pauseAction = [UIAlertAction actionWithTitle:@"Pause"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {[weakSelf pause];
    }];

    UIAlertAction *resumeAction = [UIAlertAction actionWithTitle:@"Resume"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {[weakSelf resume];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"End/Reject Call"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {[weakSelf cancel];
    }];

    UIAlertAction *muteAction = [UIAlertAction actionWithTitle:@"Mute Audio"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {[weakSelf muteFriend];
    }];

    UIAlertAction *unmuteAction = [UIAlertAction actionWithTitle:@"Unmute Audio"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {[weakSelf unmuteFriend];
    }];

    [alertController addAction:pauseAction];
    [alertController addAction:resumeAction];
    [alertController addAction:cancelAction];
    [alertController addAction:muteAction];
    [alertController addAction:unmuteAction];

    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Call methods

- (void)cancel
{
    NSError *error;
    if (! [self.manager.calls sendCallControl:OCTToxAVCallControlCancel toCall:self.selectedCall error:&error]) {
        NSLog(@"%@ Error %@", self, error.localizedDescription);
        NSLog(@"%@ Reason: %@", self, error.localizedFailureReason);
    }
}

- (void)useSpeaker
{
    [self.manager.calls routeAudioToSpeaker:YES error:nil];
}

- (void)useDefaultSpeaker
{
    [self.manager.calls routeAudioToSpeaker:NO error:nil];
}

- (void)toggleMuteMic
{
    BOOL currentStatus = self.manager.calls.enableMicrophone;
    self.manager.calls.enableMicrophone = ! currentStatus;
}

- (void)pause
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlPause toCall:self.selectedCall error:nil];
}

- (void)resume
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlResume toCall:self.selectedCall error:nil];
}

- (void)muteFriend
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlMuteAudio toCall:self.selectedCall error:nil];
}

- (void)unmuteFriend
{
    [self.manager.calls sendCallControl:OCTToxAVCallControlUnmuteAudio toCall:self.selectedCall error:nil];
}

- (void)showVideoPreview
{
    CALayer *layer = [self.manager.calls videoCallPreview];

    self.previewVideoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    self.previewVideoView.backgroundColor = [UIColor blackColor];

    layer.frame = self.previewVideoView.bounds;

    [self.previewVideoView.layer addSublayer:layer];

    [self.view addSubview:self.previewVideoView];
}

@end
