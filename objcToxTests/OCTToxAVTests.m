//
//  OCTToxAVTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/2/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OCMock/OCMock.h>
#import "OCTToxAV+Private.h"
#import "OCTTox+Private.h"
#import "toxav.h"
#import "OCTCAsserts.h"

void *refToSelf;

void mocked_toxav_iterate(ToxAV *toxAV);
uint32_t mocked_toxav_iteration_interval(const ToxAV *toxAV);
void mocked_toxav_kill(ToxAV *toxAV);

bool mocked_tox_av_call(ToxAV *toxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_CALL *error);
bool mocked_toxav_call_control(ToxAV *toxAV, uint32_t friend_number, TOXAV_CALL_CONTROL control, TOXAV_ERR_CALL_CONTROL *error);


@interface OCTToxAVTests : XCTestCase

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTTox *tox;

@end

@implementation OCTToxAVTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    refToSelf = (__bridge void *)(self);

    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.toxAV = [[OCTToxAV alloc] initWithTox:self.tox error:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.

    refToSelf = NULL;

    self.tox = nil;
    self.toxAV = nil;

    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.toxAV);
}

- (void)testCallFriend
{
    _toxav_call = mocked_tox_av_call;
    XCTAssertTrue([self.toxAV callFriendNumber:1234 audioBitRate:5678 videoBitRate:9101112 error:nil]);
}

- (void)testSendCallControl
{
    _toxav_call_control = mocked_toxav_call_control;
    XCTAssertTrue([self.toxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:12345 error:nil]);
}

- (void)testStart
{
    _toxav_iterate = mocked_toxav_iterate;
    _toxav_iteration_interval = mocked_toxav_iteration_interval;

    [self.tox start];
}

#pragma mark Private methods

- (void)testFillErrorInit
{
    [self.toxAV fillError:nil withCErrorInit:TOXAV_ERR_NEW_NULL];

    NSError *error;
    [self.toxAV fillError:&error withCErrorInit:TOXAV_ERR_NEW_NULL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorInitNULL);

    error = nil;
    [self.toxAV fillError:&error withCErrorInit:TOXAV_ERR_NEW_MALLOC];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorInitCodeMemoryError);

    error = nil;
    [self.toxAV fillError:&error withCErrorInit:TOXAV_ERR_NEW_MULTIPLE];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorInitMultiple);
}

- (void)testFillErrorCall
{
    [self.toxAV fillError:nil withCErrorCall:TOXAV_ERR_CALL_MALLOC];

    NSError *error;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_MALLOC];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallMalloc);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_FRIEND_NOT_FOUND];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallFriendNotFound);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_FRIEND_NOT_CONNECTED];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallFriendNotConnected);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_FRIEND_ALREADY_IN_CALL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallAlreadyInCall);

    error = nil;
    [self.toxAV fillError:&error withCErrorCall:TOXAV_ERR_CALL_INVALID_BIT_RATE];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorCallInvalidBitRate);
}

- (void)testFillErrorControl
{
    [self.toxAV fillError:nil withCErrorControl:TOXAV_ERR_CALL_CONTROL_INVALID_TRANSITION];

    NSError *error;
    [self.toxAV fillError:&error withCErrorControl:TOXAV_ERR_CALL_CONTROL_FRIEND_NOT_FOUND];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorControlFriendNotFound);

    error = nil;
    [self.toxAV fillError:&error withCErrorControl:TOXAV_ERR_CALL_CONTROL_FRIEND_NOT_IN_CALL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorControlFriendNotInCall);

    error = nil;
    [self.toxAV fillError:&error withCErrorControl:TOXAV_ERR_CALL_CONTROL_INVALID_TRANSITION];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorControlInvaldTransition);
}
- (void)testFillErrorSetBitRate
{
    [self.toxAV fillError:nil withCErrorSetBitRate:TOXAV_ERR_SET_BIT_RATE_FRIEND_NOT_IN_CALL];

    NSError *error;
    [self.toxAV fillError:&error withCErrorSetBitRate:TOXAV_ERR_SET_BIT_RATE_INVALID];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSetBitRateInvalid);

    error = nil;
    [self.toxAV fillError:&error withCErrorSetBitRate:TOXAV_ERR_SET_BIT_RATE_FRIEND_NOT_FOUND];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSetBitRateFriendNotFound);

    error = nil;
    [self.toxAV fillError:&error withCErrorSetBitRate:TOXAV_ERR_SET_BIT_RATE_FRIEND_NOT_IN_CALL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSetBitRateFriendNotInCall);
}

- (void)testFillErrorSendFrame
{
    [self.toxAV fillError:nil withCErrorSendFrame:TOXAV_ERR_SEND_FRAME_NULL];

    NSError *error;
    [self.toxAV fillError:&error withCErrorSendFrame:TOXAV_ERR_SEND_FRAME_NULL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSendFrameNull);

    error = nil;
    [self.toxAV fillError:&error withCErrorSendFrame:TOXAV_ERR_SEND_FRAME_FRIEND_NOT_FOUND];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSendFrameFriendNotFound);

    error = nil;
    [self.toxAV fillError:&error withCErrorSendFrame:TOXAV_ERR_SEND_FRAME_FRIEND_NOT_IN_CALL];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSendFrameFriendNotInCall);

    error = nil;
    [self.toxAV fillError:&error withCErrorSendFrame:TOXAV_ERR_SEND_FRAME_INVALID];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSendFrameInvalid);

    error = nil;
    [self.toxAV fillError:&error withCErrorSendFrame:TOXAV_ERR_SEND_FRAME_RTP_FAILED];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorSendFrameRTPFailed);
}

#pragma mark Callbacks

- (void)testReceiveCallback
{
    [self makeTestCallbackWithCallBlock:^{
        callIncomingCallback(NULL, 1, true, false, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                     receiveCallAudioEnabled:YES
                                videoEnabled:NO
                                friendNumber:1]);
    }];
}

- (void)testCallStateCallback
{
    [self makeTestCallbackWithCallBlock:^{
        callStateCallback(NULL, 1, TOXAV_CALL_STATE_RECEIVING_A | TOXAV_CALL_STATE_SENDING_A, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVCallStateReceivingAudio | OCTToxAVCallStateSendingAudio
                                friendNumber:friendNumber]);
    }];

    [self makeTestCallbackWithCallBlock:^{
        callStateCallback(NULL, 1, TOXAV_CALL_STATE_SENDING_A, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVCallStateSendingAudio
                                friendNumber:friendNumber]);
    }];

    [self makeTestCallbackWithCallBlock:^{
        callStateCallback(NULL, 1, TOXAV_CALL_STATE_ERROR, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVCallStateError
                                friendNumber:friendNumber]);
    }];

    [self makeTestCallbackWithCallBlock:^{
        callStateCallback(NULL, 1, TOXAV_CALL_STATE_RECEIVING_A | TOXAV_CALL_STATE_SENDING_A | TOXAV_CALL_STATE_SENDING_V, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVCallStateReceivingAudio | OCTToxAVCallStateSendingAudio | OCTToxAVCallStateSendingVideo
                                friendNumber:friendNumber]);
    }];
}

- (void)testAudioBitRateCallback
{
    [self makeTestCallbackWithCallBlock:^{
        audioBitRateStatusCallback(NULL, 33, true, 33000, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                         audioBitRateChanged:33000
                                      stable:YES
                                friendNumber:33]);
    }];
}

- (void)testVideoBitRateCallback
{
    [self makeTestCallbackWithCallBlock:^{
        videoBitRateStatusCallback(NULL, 5, false, 10, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                         videoBitRateChanged:10
                                friendNumber:5
                                      stable:NO]);
    }];
}

- (void)testReceiveAudioCallback
{
    const int16_t pcm[] = {5, 9, 5};
    const int16_t *pointerToData = pcm;

    [self makeTestCallbackWithCallBlock:^{
        receiveAudioFrameCallback(NULL, 20, pointerToData, 4, 0, 6, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                                receiveAudio:pointerToData
                                 sampleCount:4
                                    channels:0
                                  sampleRate:6
                                friendNumber:20]);
    }];
}

- (void)testReceiveVideoFrameCallback
{
    const OCTToxAVPlaneData yPlane[] = {1, 2, 3, 4, 5};
    const OCTToxAVPlaneData *yPointer = yPlane;
    const OCTToxAVPlaneData uPlane[] = {4, 3, 3, 4, 5};
    const OCTToxAVPlaneData *uPointer = uPlane;
    const OCTToxAVPlaneData vPlane[] = {1, 2, 5, 4, 5};
    const OCTToxAVPlaneData *vPointer = vPlane;
    const OCTToxAVPlaneData aPlane[] = {1, 2, 11, 4, 5};
    const OCTToxAVPlaneData *aPointer = aPlane;

    [self makeTestCallbackWithCallBlock:^{
        receiveVideoFrameCallback(NULL, 123,
                                  999, 888,
                                  yPointer, uPointer, vPointer, aPointer,
                                  1, 2, 3, 4,
                                  (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                   receiveVideoFrameWithWidth:999 height:888
                                       yPlane:yPointer uPlane:uPointer vPlane:vPointer aPlane:aPointer
                                      yStride:1 uStride:2 vStride:3 aStride:4 friendNumber:123]);
    }];
}

- (void)makeTestCallbackWithCallBlock:(void (^)())callBlock expectBlock:(void (^)(id<OCTToxAVDelegate> delegate))expectBlock
{
    NSParameterAssert(callBlock);
    NSParameterAssert(expectBlock);

    self.toxAV.delegate = OCMProtocolMock(@protocol(OCTToxAVDelegate));
    expectBlock(self.toxAV.delegate);

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        callBlock();
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    OCMVerifyAll((id)self.toxAV.delegate);
}

@end

#pragma mark - Mocked toxav methods
void mocked_toxav_iterate(ToxAV *cToxAV)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);
}

uint32_t mocked_toxav_iteration_interval(const ToxAV *cToxAV)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    return 200;
}

void mocked_toxav_kill(ToxAV *cToxAV)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);
}

bool mocked_tox_av_call(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_CALL *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(1234, friend_number);
    CCCAssertEqual(5678, audio_bit_rate);
    CCCAssertEqual(9101112, video_bit_rate);

    return true;
}

bool mocked_toxav_call_control(ToxAV *cToxAV, uint32_t friend_number, TOXAV_CALL_CONTROL control, TOXAV_ERR_CALL_CONTROL *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(friend_number, 12345);
    CCCAssertEqual(control, TOXAV_CALL_CONTROL_RESUME);

    return true;
}