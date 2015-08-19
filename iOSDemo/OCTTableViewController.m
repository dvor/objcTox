//
//  OCTTableViewController.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <Masonry/Masonry.h>

#import "OCTTableViewController.h"

static NSString *const kUITableViewCellIdentifier = @"kUITableViewCellIdentifier";

@interface OCTTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) OCTManager *manager;

@end

@implementation OCTTableViewController

#pragma mark -  Lifecycle

- (instancetype)initWithManager:(OCTManager *)manager
{
    self = [super init];

    if (! self) {
        return nil;
    }

    _manager = manager;

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kUITableViewCellIdentifier];
    [self.view addSubview:self.tableView];

    [self installConstraints];
}

#pragma mark -  Public

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kUITableViewCellIdentifier
                                                                 forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;

    return cell;
}

- (void)showActionSheet:(void (^)(UIActionSheet *sheet))block
{
    if (! block) {
        return;
    }

    UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:@"Select action"];
    [sheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

    block(sheet);

    [sheet showInView:self.view];
}

- (void)addToSheet:(UIActionSheet *)sheet copyButtonWithValue:(id)value
{
    [sheet bk_addButtonWithTitle:@"Copy" handler:^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [self stringFromValue:value];
    }];
}

- (void)addToSheet:(UIActionSheet *)sheet textEditButtonWithValue:(id)value block:(void (^)(NSString *string))block
{
    NSParameterAssert(block);

    __weak OCTTableViewController *weakSelf = self;

    [sheet bk_addButtonWithTitle:@"Edit" handler:^{
        UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"" message:nil];

        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] setText:[self stringFromValue:value]];

        [alert bk_addButtonWithTitle:@"OK" handler:^{
            block([alert textFieldAtIndex:0].text);

            [weakSelf.tableView reloadData];
        }];

        [alert bk_setCancelButtonWithTitle:@"Cancel" handler:nil];

        [alert show];
    }];
}

- (void)            addToSheet:(UIActionSheet *)sheet
    multiEditButtonWithOptions:(NSArray *)options
                         block:(void (^)(NSUInteger index))block
{
    NSParameterAssert(block);

    __weak OCTTableViewController *weakSelf = self;

    [sheet bk_addButtonWithTitle:@"Edit" handler:^{
        UIActionSheet *editSheet = [UIActionSheet bk_actionSheetWithTitle:@"Select action"];

        for (NSUInteger index = 0; index < options.count; index++) {
            [editSheet bk_addButtonWithTitle:options[index] handler:^{
                block(index);
                [weakSelf.tableView reloadData];
            }];
        }

        [editSheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [editSheet showInView:weakSelf.view];
    }];
}
- (NSString *)stringFromValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }

    if ([value isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@", value];
    }

    return nil;
}

- (NSString *)stringFromUserStatus:(OCTToxUserStatus)status
{
    switch (status) {
        case OCTToxUserStatusNone:
            return @"None";
        case OCTToxUserStatusAway:
            return @"Away";
        case OCTToxUserStatusBusy:
            return @"Busy";
    }
}

- (NSString *)stringFromConnectionStatus:(OCTToxConnectionStatus)status
{
    switch (status) {
        case OCTToxConnectionStatusNone:
            return @"None";
        case OCTToxConnectionStatusTCP:
            return @"TCP";
        case OCTToxConnectionStatusUDP:
            return @"UDP";
    }
}

- (void)maybeShowError:(NSError *)error
{
    if (! error) {
        return;
    }

    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:error.localizedDescription
                                                    message:error.localizedFailureReason];
    [alert bk_setCancelButtonWithTitle:@"OK" handler:nil];
    [alert show];
}

#pragma mark -  UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSAssert(NO, @"Implement in subclass");
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSAssert(NO, @"Implement in subclass");
    return nil;
}

#pragma mark -  Private

- (void)installConstraints
{
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

@end
