//
//  OCTBasicContainer.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 16.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTBasicContainer.h"
#import "OCTManagerConstants.h"

@interface OCTBasicContainer ()

@property (strong, nonatomic) NSMutableArray *array;

@property (copy, nonatomic) NSComparator comparator;

@end

@implementation OCTBasicContainer

#pragma mark -  Lifecycle

- (instancetype)initWithObjects:(NSArray *)objects
{
    self = [super init];

    if (! self) {
        return nil;
    }

    self.array = [NSMutableArray arrayWithArray:objects];

    return self;
}

#pragma mark -  Public

- (void)setComparatorForCurrentSort:(NSComparator)comparator
{
    self.comparator = comparator;

    if (! comparator) {
        return;
    }

    @synchronized(self.array) {
        if (self.array.count <= 1) {
            return;
        }

        [self.array sortUsingComparator:self.comparator];

        NSRange range = NSMakeRange(0, self.array.count);
        [self.delegate basicContainerUpdate:self
                                insertedSet:nil
                                 removedSet:nil
                                 updatedSet:[NSIndexSet indexSetWithIndexesInRange:range]];
    }
}

- (NSUInteger)count
{
    @synchronized(self.array) {
        return self.array.count;
    }
}

- (id)objectAtIndex:(NSUInteger)index
{
    @synchronized(self.array) {
        if (index < self.array.count) {
            return self.array[index];
        }

        return nil;
    }
}

- (void)addObject:(id)object
{
    NSParameterAssert(object);

    if (! object) {
        return;
    }

    @synchronized(self.array) {
        NSUInteger index = [self.array indexOfObject:object];

        if (index != NSNotFound) {
            NSAssert(NO, @"Cannot add object twice %@", object);
            return;
        }

        if (self.comparator) {
            index = [self.array indexOfObject:object
                                inSortedRange:NSMakeRange(0, self.array.count)
                                      options:NSBinarySearchingInsertionIndex
                              usingComparator:self.comparator];

            [self.array insertObject:object atIndex:index];
        }
        else {
            index = self.array.count;
            [self.array addObject:object];
        }

        [self.delegate basicContainerUpdate:self
                                insertedSet:[NSIndexSet indexSetWithIndex:index]
                                 removedSet:nil
                                 updatedSet:nil];
    }
}

- (void)removeObject:(id)object
{
    NSParameterAssert(object);

    if (! object) {
        return;
    }

    @synchronized(self.array) {
        NSUInteger index = [self.array indexOfObject:object];

        if (index == NSNotFound) {
            NSAssert(NO, @"Cannot remove object, object not found");
            return;
        }

        [self.array removeObjectAtIndex:index];

        [self.delegate basicContainerUpdate:self
                                insertedSet:nil
                                 removedSet:[NSIndexSet indexSetWithIndex:index]
                                 updatedSet:nil];
    }
}

- (void)updateObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))testBlock
                    updateBlock:(void (^)(id object))updateBlock
{
    NSParameterAssert(testBlock);
    NSParameterAssert(updateBlock);

    if (! testBlock || ! updateBlock) {
        return;
    }

    @synchronized(self.array) {
        NSUInteger index = NSNotFound;
        index = [self.array indexOfObjectPassingTest:testBlock];

        if (index == NSNotFound) {
            NSAssert(NO, @"Object to update not found");
            return;
        }

        id object = self.array[index];
        updateBlock(object);

        [self.array removeObjectAtIndex:index];

        NSUInteger newIndex;

        if (self.comparator) {
            newIndex = [self.array indexOfObject:object
                                   inSortedRange:NSMakeRange(0, self.array.count)
                                         options:NSBinarySearchingInsertionIndex
                                 usingComparator:self.comparator];
        }
        else {
            newIndex = self.array.count;
        }

        [self.array insertObject:object atIndex:index];

        NSIndexSet *inserted, *removed, *updated;

        if (index == newIndex) {
            updated = [NSIndexSet indexSetWithIndex:index];
        }
        else {
            inserted = [NSIndexSet indexSetWithIndex:newIndex];
            removed = [NSIndexSet indexSetWithIndex:index];
        }

        [self.delegate basicContainerUpdate:self insertedSet:inserted removedSet:removed updatedSet:updated];
        [self.delegate basicContainer:self objectUpdated:object];
    }
}

- (NSUInteger)indexOfObjectPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate
{
    NSParameterAssert(predicate);
    return [self.array indexOfObjectPassingTest:predicate];
}

@end
