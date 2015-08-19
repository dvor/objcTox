//
//  OCTCAsserts.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 05.06.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#ifndef objcTox_OCTCAsserts_h
#define objcTox_OCTCAsserts_h

#import <XCTest/XCTest.h>

/**
 * Macros for testing to use in C functions.
 *
 * Define `void *refToSelf` in you test file. Set it to test object in setUp, to nil in tearDown.
 */

#define CCCAssert(expression, ...) \
    _XCTPrimitiveAssertTrue((__bridge id)refToSelf, expression, @#expression, __VA_ARGS__)

#define CCCAssertFalse(expression, ...) \
    _XCTPrimitiveAssertFalse((__bridge id)refToSelf, expression, @#expression, __VA_ARGS__)

#define CCCAssertTrue(expression, ...) \
    _XCTPrimitiveAssertTrue((__bridge id)refToSelf, expression, @#expression, __VA_ARGS__)

#define CCCAssertEqual(expression1, expression2, ...) \
    _XCTPrimitiveAssertEqual((__bridge id)refToSelf, expression1, @#expression1, expression2, @#expression2, __VA_ARGS__)

#define CCCAssertNotEqual(expression1, expression2, ...) \
    _XCTPrimitiveAssertNotEqual((__bridge id)refToSelf, expression1, @#expression1, expression2, @#expression2, __VA_ARGS__)

#endif
