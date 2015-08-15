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
#import "OCTCAsserts.h"

void *refToSelf;

uint32_t mocked_toxav_version_major(void);
uint32_t mocked_toxav_version_minor(void);
uint32_t mocked_toxav_version_patch(void);
bool mocked_toxav_version_is_compatible(uint32_t major, uint32_t minor, uint32_t patch);

void mocked_toxav_iterate(ToxAV *toxAV);
uint32_t mocked_toxav_iteration_interval(const ToxAV *toxAV);
void mocked_toxav_kill(ToxAV *toxAV);

bool mocked_tox_av_call_success(ToxAV *toxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_CALL *error);
bool mocked_tox_av_answer_success(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_ANSWER *error);
bool mocked_tox_av_answer_fail(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_ANSWER *error);
bool mocked_tox_av_call_fail(ToxAV *toxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_CALL *error);

bool mocked_toxav_call_control_resume(ToxAV *toxAV, uint32_t friend_number, TOXAV_CALL_CONTROL control, TOXAV_ERR_CALL_CONTROL *error);
bool mocked_toxav_call_control_cancel(ToxAV *toxAV, uint32_t friend_number, TOXAV_CALL_CONTROL control, TOXAV_ERR_CALL_CONTROL *error);

bool mocked_toxav_audio_bit_rate_set(ToxAV *toxAV, uint32_t friend_number, uint32_t audio_bit_rate, bool force, TOXAV_ERR_SET_BIT_RATE *error);
bool mocked_toxav_video_bit_rate_set(ToxAV *toxAV, uint32_t friend_number, uint32_t audio_bit_rate, bool force, TOXAV_ERR_SET_BIT_RATE *error);

bool mocked_toxav_audio_send_frame(ToxAV *toxAV, uint32_t friend_number, const int16_t *pcm, size_t sample_count, uint8_t channels, uint32_t sampling_rate, TOXAV_ERR_SEND_FRAME *error);
bool mocked_toxav_video_send_frame(ToxAV *toxAV, uint32_t friend_number, uint16_t width, uint16_t height, const uint8_t *y, const uint8_t *u, const uint8_t *v, TOXAV_ERR_SEND_FRAME *error);

OCTToxAVPCMData pcmTestData [] = { 5, 6, 7, 8};
OCTToxAVPCMData *pcmPointer = pcmTestData;

OCTToxAVPlaneData yPlaneTestData [] = {2, 3, 4, 5};
OCTToxAVPlaneData *yPlanePointer = yPlaneTestData;
OCTToxAVPlaneData uPlaneTestData [] = {6, 7, 8, 9};
OCTToxAVPlaneData *uPlanePointer = uPlaneTestData;
OCTToxAVPlaneData vPlaneTestData [] = {10, 11, 12, 13};
OCTToxAVPlaneData *vPlanePointer = vPlaneTestData;
OCTToxAVPlaneData aPlaneTestData [] = {14, 15, 16, 17};
OCTToxAVPlaneData *aPlanePointer = aPlaneTestData;

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

    self.tox = nil;
    self.toxAV = nil;

    refToSelf = NULL;

    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.toxAV);
}

- (void)testVersionMethods
{
    _toxav_version_major = mocked_toxav_version_major;
    XCTAssertEqual(111, [OCTToxAV versionMajor]);

    _toxav_version_minor = mocked_toxav_version_minor;
    XCTAssertEqual(222, [OCTToxAV versionMinor]);

    _toxav_version_patch = mocked_toxav_version_patch;
    XCTAssertEqual(333, [OCTToxAV versionPatch]);

    XCTAssertEqualObjects(@"111.222.333", [OCTToxAV version]);

    _toxav_version_is_compatible = mocked_toxav_version_is_compatible;
    XCTAssertFalse([OCTToxAV versionIsCompatibleWith:999 minor:888 patch:777]);
}

- (void)testCallFriend
{
    _toxav_call = mocked_tox_av_call_success;
    XCTAssertTrue([self.toxAV callFriendNumber:1234 audioBitRate:5678 videoBitRate:9101112 error:nil]);

    _toxav_call = mocked_tox_av_call_fail;
    XCTAssertFalse([self.toxAV callFriendNumber:1234 audioBitRate:5678 videoBitRate:9101112 error:nil]);
}

- (void)testAnswerCall
{
    _toxav_answer = mocked_tox_av_answer_success;
    XCTAssertTrue([self.toxAV answerIncomingCallFromFriend:9876 audioBitRate:555 videoBitRate:666 error:nil]);

    _toxav_answer = mocked_tox_av_answer_fail;
    XCTAssertFalse([self.toxAV answerIncomingCallFromFriend:999 audioBitRate:888 videoBitRate:777 error:nil]);
}

- (void)testSendCallControl
{
    _toxav_call_control = mocked_toxav_call_control_resume;
    XCTAssertTrue([self.toxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:12345 error:nil]);

    _toxav_call_control = mocked_toxav_call_control_cancel;
    XCTAssertTrue([self.toxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:12345 error:nil]);
}

- (void)testStartandStop
{
    _toxav_iterate = mocked_toxav_iterate;
    _toxav_iteration_interval = mocked_toxav_iteration_interval;

    [self.toxAV start];
    [self.toxAV stop];

    _toxav_iterate = nil;
    _toxav_iteration_interval = nil;
}

- (void)testSetAudioBitRate
{

    _toxav_audio_bit_rate_set = mocked_toxav_audio_bit_rate_set;
    XCTAssertTrue([self.toxAV setAudioBitRate:1111 force:YES forFriend:5678 error:nil]);
}

- (void)testSetVideoBitRate
{
    _toxav_video_bit_rate_set = mocked_toxav_video_bit_rate_set;
    XCTAssertFalse([self.toxAV setVideoBitRate:10 force:NO forFriend:5 error:nil]);
}

- (void)testSendAudioFrame
{
    _toxav_audio_send_frame = mocked_toxav_audio_send_frame;
    XCTAssertTrue([self.toxAV sendAudioFrame:pcmPointer sampleCount:6 channels:7 sampleRate:8 toFriend:5 error:nil]);
}

- (void)testSendVideoFrame
{
    _toxav_video_send_frame = mocked_toxav_video_send_frame;
    XCTAssertFalse([self.toxAV sendVideoFrametoFriend:7 width:50 height:70
                                               yPlane:yPlanePointer
                                               uPlane:uPlanePointer
                                               vPlane:vPlanePointer
                                                error:nil]);
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

- (void)testFillErrorAnswer
{
    [self.toxAV fillError:nil withCErrorAnswer:TOXAV_ERR_ANSWER_OK];

    NSError *error;
    [self.toxAV fillError:&error withCErrorAnswer:TOXAV_ERR_ANSWER_CODEC_INITIALIZATION];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorAnswerCodecInitialization);

    error = nil;
    [self.toxAV fillError:&error withCErrorAnswer:TOXAV_ERR_ANSWER_FRIEND_NOT_CALLING];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorAnswerFriendNotCalling);

    error = nil;
    [self.toxAV fillError:&error withCErrorAnswer:TOXAV_ERR_ANSWER_FRIEND_NOT_FOUND];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorAnswerFriendNotFound);

    error = nil;
    [self.toxAV fillError:&error withCErrorAnswer:TOXAV_ERR_ANSWER_INVALID_BIT_RATE];
    XCTAssertNotNil(error);
    XCTAssertTrue(error.code == OCTToxAVErrorAnswerInvalidBitRate);
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
        callStateCallback(NULL, 1, TOXAV_FRIEND_CALL_STATE_ACCEPTING_A | TOXAV_FRIEND_CALL_STATE_SENDING_A, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVFriendCallStateAcceptingAudio | OCTToxAVFriendCallStateSendingAudio
                                friendNumber:friendNumber]);
    }];

    [self makeTestCallbackWithCallBlock:^{
        callStateCallback(NULL, 1, TOXAV_FRIEND_CALL_STATE_SENDING_A, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVFriendCallStateSendingAudio
                                friendNumber:friendNumber]);
    }];

    [self makeTestCallbackWithCallBlock:^{
        callStateCallback(NULL, 1, TOXAV_FRIEND_CALL_STATE_ERROR, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVFriendCallStateError
                                friendNumber:friendNumber]);
    }];

    [self makeTestCallbackWithCallBlock:^{
        callStateCallback(NULL, 1, TOXAV_FRIEND_CALL_STATE_ACCEPTING_A | TOXAV_FRIEND_CALL_STATE_SENDING_A | TOXAV_FRIEND_CALL_STATE_SENDING_V, (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCTToxFriendNumber friendNumber = 1;
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                            callStateChanged:OCTToxAVFriendCallStateAcceptingAudio | OCTToxAVFriendCallStateSendingAudio | OCTToxAVFriendCallStateSendingVideo
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

    self.toxAV.videoProcessingQueue = dispatch_get_main_queue();

    [self makeTestCallbackWithCallBlock:^{
        receiveVideoFrameCallback(NULL, 123,
                                  999, 888,
                                  yPointer, uPointer, vPointer,
                                  1, 2, 3,
                                  (__bridge void *)self.toxAV);
    } expectBlock:^(id<OCTToxAVDelegate> delegate) {
        OCMExpect([self.toxAV.delegate toxAV:self.toxAV
                   receiveVideoFrameWithWidth:999 height:888
                                       yPlane:yPointer uPlane:uPointer vPlane:vPointer
                                      yStride:1 uStride:2 vStride:3 friendNumber:123]);
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

uint32_t mocked_toxav_version_major(void)
{
    return 111;
}

uint32_t mocked_toxav_version_minor(void)
{
    return 222;
}

uint32_t mocked_toxav_version_patch(void)
{
    return 333;
}

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

bool mocked_tox_av_call_success(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_CALL *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(1234, friend_number);
    CCCAssertEqual(5678, audio_bit_rate);
    CCCAssertEqual(9101112, video_bit_rate);

    return true;
}

bool mocked_tox_av_call_fail(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_CALL *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(1234, friend_number);
    CCCAssertEqual(5678, audio_bit_rate);
    CCCAssertEqual(9101112, video_bit_rate);

    return false;
}

bool mocked_tox_av_answer_success(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_ANSWER *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];
    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(9876, friend_number);
    CCCAssertEqual(555, audio_bit_rate);
    CCCAssertEqual(666, video_bit_rate);

    return true;
}

bool mocked_tox_av_answer_fail(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, uint32_t video_bit_rate, TOXAV_ERR_ANSWER *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];
    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(999, friend_number);
    CCCAssertEqual(888, audio_bit_rate);
    CCCAssertEqual(777, video_bit_rate);

    return false;
}


bool mocked_toxav_call_control_resume(ToxAV *cToxAV, uint32_t friend_number, TOXAV_CALL_CONTROL control, TOXAV_ERR_CALL_CONTROL *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(friend_number, 12345);
    CCCAssertEqual(control, TOXAV_CALL_CONTROL_RESUME);

    return true;
}

bool mocked_toxav_call_control_cancel(ToxAV *cToxAV, uint32_t friend_number, TOXAV_CALL_CONTROL control, TOXAV_ERR_CALL_CONTROL *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(friend_number, 12345);
    CCCAssertEqual(control, TOXAV_CALL_CONTROL_CANCEL);

    return true;
}

bool mocked_toxav_audio_bit_rate_set(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, bool force, TOXAV_ERR_SET_BIT_RATE *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(5678, friend_number);
    CCCAssertEqual(1111, audio_bit_rate);
    CCCAssertTrue(force);
    return true;
}
bool mocked_toxav_video_bit_rate_set(ToxAV *cToxAV, uint32_t friend_number, uint32_t audio_bit_rate, bool force, TOXAV_ERR_SET_BIT_RATE *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(5, friend_number);
    CCCAssertEqual(10, audio_bit_rate);
    CCCAssertFalse(force);

    return false;
}

bool mocked_toxav_audio_send_frame(ToxAV *cToxAV, uint32_t friend_number, const int16_t *pcm, size_t sample_count, uint8_t channels, uint32_t sampling_rate, TOXAV_ERR_SEND_FRAME *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(pcmPointer, pcm);
    CCCAssertEqual(5, friend_number);
    CCCAssertEqual(6, sample_count);
    CCCAssertEqual(7, channels);
    CCCAssertEqual(8, sampling_rate);

    return true;
}

bool mocked_toxav_video_send_frame(ToxAV *cToxAV, uint32_t friend_number, uint16_t width, uint16_t height, const uint8_t *y, const uint8_t *u, const uint8_t *v, TOXAV_ERR_SEND_FRAME *error)
{
    OCTToxAV *toxAV = [(__bridge OCTToxAVTests *)refToSelf toxAV];

    CCCAssertTrue(toxAV.toxAV == cToxAV);

    CCCAssertEqual(50, width);
    CCCAssertEqual(70, height);
    CCCAssertEqual(yPlanePointer, y);
    CCCAssertEqual(uPlanePointer, u);
    CCCAssertEqual(vPlanePointer, v);
    CCCAssertEqual(7, friend_number);

    return false;
}

bool mocked_toxav_version_is_compatible(uint32_t major, uint32_t minor, uint32_t patch)
{
    CCCAssertEqual(999, major);
    CCCAssertEqual(888, minor);
    CCCAssertEqual(777, patch);
    return false;
}
