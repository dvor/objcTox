//
//  OCTTableViewController.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 22/05/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OCTManager.h"

@interface OCTTableViewController : UIViewController

@property (strong, nonatomic, readonly) UITableView *tableView;
@property (strong, nonatomic, readonly) OCTManager *manager;

- (instancetype)initWithManager:(OCTManager *)manager;

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath;

- (void)showActionSheet:(void (^)(UIActionSheet *sheet))block;
- (void)addToSheet:(UIActionSheet *)sheet copyButtonWithValue:(id)value;
- (void)addToSheet:(UIActionSheet *)sheet textEditButtonWithValue:(id)value block:(void (^)(NSString *string))block;
- (void)            addToSheet:(UIActionSheet *)sheet
    multiEditButtonWithOptions:(NSArray *)options
                         block:(void (^)(NSUInteger index))block;

// Value can be NSString or NSNumber
- (NSString *)stringFromValue:(id)value;
- (NSString *)stringFromUserStatus:(OCTToxUserStatus)status;
- (NSString *)stringFromConnectionStatus:(OCTToxConnectionStatus)status;

// Shows error if it isn't nil.
- (void)maybeShowError:(NSError *)error;

@end
