//
//  OCTSubmanagerCallsTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/4/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTRealmTests.h"

#import "OCTSubmanagerCalls+Private.h"
#import "OCTRealmManager.h"
#import "OCTAudioEngine.h"
#import "OCTMessageCall.h"
#import "OCTMessageAbstract.h"
#import "OCTToxAV.h"
#import "OCTTox.h"
#import <OCMock/OCMock.h>

@interface OCTSubmanagerCalls (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) OCTVideoEngine *videoEngine;
@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;
@property (strong, nonatomic) OCTCallTimer *timer;

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)   toxAV:(OCTToxAV *)toxAV
    receiveAudio:(OCTToxAVPCMData *)pcm
     sampleCount:(OCTToxAVSampleCount)sampleCount
        channels:(OCTToxAVChannels)channels
      sampleRate:(OCTToxAVSampleRate)sampleRate
    friendNumber:(OCTToxFriendNumber)friendNumber;

- (OCTCall *)createCallWithFriendNumber:(OCTToxFriendNumber)friendNumber status:(OCTCallStatus)status;
- (OCTCall *)getCurrentCallForFriendNumber:(OCTToxFriendNumber)friendNumber;

@end

@interface OCTSubmanagerCallsTests : OCTRealmTests

@property (strong, nonatomic) id dataSource;
@property (strong, nonatomic) OCTSubmanagerCalls *callManager;
@property (strong, nonatomic) OCTTox *tox;
@property (strong, nonatomic) id mockedAudioEngine;
@property (strong, nonatomic) id mockedVideoEngine;
@property (strong, nonatomic) id mockedToxAV;

@end

@implementation OCTSubmanagerCallsTests

- (void)setUp
{
    [super setUp];
    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.callManager = [[OCTSubmanagerCalls alloc] initWithTox:self.tox];

    self.dataSource = OCMProtocolMock(@protocol(OCTSubmanagerDataSource));
    OCMStub([self.dataSource managerGetRealmManager]).andReturn(self.realmManager);

    OCTAudioEngine *audioEngine = [OCTAudioEngine new];
    self.mockedAudioEngine = OCMPartialMock(audioEngine);
    self.callManager.audioEngine = self.mockedAudioEngine;

    OCTVideoEngine *videoEngine = [OCTVideoEngine new];
    self.mockedVideoEngine = OCMPartialMock(videoEngine);
    self.callManager.videoEngine = self.mockedVideoEngine;

    self.mockedToxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = self.mockedToxAV;

    self.callManager.dataSource = self.dataSource;
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.dataSource = nil;
    self.callManager = nil;
    self.tox = nil;
    self.mockedAudioEngine = nil;
    self.mockedToxAV = nil;
    self.mockedVideoEngine = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.callManager);
}

- (void)testSetup
{
    OCMStub([self.mockedAudioEngine new]).andReturn(self.mockedAudioEngine);
    OCMStub([self.mockedAudioEngine setupWithError:[OCMArg anyObjectRef]]).andReturn(YES);

    OCMStub([self.mockedVideoEngine new]).andReturn(self.mockedVideoEngine);
    OCMStub([self.mockedVideoEngine setupWithError:[OCMArg anyObjectRef]]).andReturn(YES);

    XCTAssertTrue([self.callManager setupWithError:nil]);
}

- (void)testCallToChat
{
    [OCMStub([self.mockedToxAV callFriendNumber:1
                                   audioBitRate:0
                                   videoBitRate:0
                                          error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];

    OCTFriend *friend = [self createFriend];
    friend.friendNumber = 1;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    XCTAssertNotNil(call.chat);

    XCTAssertEqualObjects(call.chat, chat);
    XCTAssertEqual(call.status, OCTCallStatusDialing);
    XCTAssertNil(call.caller);
    XCTAssertTrue([call isOutgoing]);
}

- (void)testEndCall
{
    OCMStub([self.mockedToxAV callFriendNumber:12 audioBitRate:48 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:12 error:[OCMArg anyObjectRef]]).andReturn(YES);
    OCMStub([self.mockedAudioEngine stopAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    OCTFriend *friend = [self createFriendWithFriendNumber:12];
    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    NSError *error;
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlCancel toCall:call error:&error]);

    OCMVerify([self.realmManager deleteObject:call]);

    XCTAssertNotNil(chat.lastMessage.messageCall);
    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventUnanswered);
    XCTAssertTrue(chat.lastMessage.isOutgoing);
}

- (void)testAnswerCallFail
{
    [self createFriendWithFriendNumber:123];

    OCTCall *call = [self.callManager createCallWithFriendNumber:123 status:OCTCallStatusRinging];

    XCTAssertFalse([self.callManager answerCall:call enableAudio:YES enableVideo:NO error:nil]);

    OCMVerify([self.mockedToxAV answerIncomingCallFromFriend:123 audioBitRate:48 videoBitRate:0 error:[OCMArg anyObjectRef]]);
}

- (void)testAnswerCallSuccess
{
    OCMStub([self.mockedAudioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    [self createFriendWithFriendNumber:1234];

    OCTCall *call = [self.callManager createCallWithFriendNumber:1234 status:OCTCallStatusRinging];

    OCMStub([self.mockedToxAV answerIncomingCallFromFriend:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES);

    XCTAssertTrue([self.callManager answerCall:call enableAudio:NO enableVideo:NO error:nil]);
    XCTAssertEqual(self.callManager.audioEngine.friendNumber, 1234);
}

- (void)testCallStateReceiveFinished
{
    OCMStub([self.mockedAudioEngine isAudioRunning:nil]).andReturn(NO);
    OCMStub([self.mockedAudioEngine friendNumber]).andReturn(89);

    OCTFriend *friend = [self createFriendWithFriendNumber:89];

    OCTCall *call = [self.callManager createCallWithFriendNumber:89 status:OCTCallStatusDialing];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = OCTCallStatusRinging;
    }];

    OCTToxAVCallState state;
    state |= OCTToxAVFriendCallStateFinished;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:89];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    XCTAssertNotNil(chat.lastMessage.messageCall);
    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventUnanswered);

    call = [self.callManager createCallWithFriendNumber:89 status:OCTCallStatusRinging];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        call.status = OCTCallStatusActive;
    }];

    [self.callManager toxAV:nil callStateChanged:state friendNumber:89];

    XCTAssertEqual(chat.lastMessage.messageCall.callEvent, OCTMessageCallEventAnswered);
}

- (void)testFriendAnsweredCall
{
    id timer = OCMClassMock([OCTCallTimer class]);
    self.callManager.timer = timer;

    [self createFriendWithFriendNumber:92];

    OCTCall *call = [self.callManager createCallWithFriendNumber:92 status:OCTCallStatusRinging];
    [self.realmManager updateObject:call withBlock:^(OCTCall *callToUpdate) {
        callToUpdate.status = OCTCallStatusDialing;
    }];

    OCTToxAVCallState state;
    state |= OCTToxAVFriendCallStateAcceptingVideo;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:92];

    OCMVerify([self.mockedAudioEngine startAudioFlow:nil]);
    OCMVerify([self.mockedAudioEngine setFriendNumber:92]);
    OCMVerify([timer startTimerForCall:call]);

    XCTAssertEqual(call.status, OCTCallStatusActive);
    XCTAssertTrue(call.friendAcceptingVideo);
}

- (void)testRouteAudioToSpeaker
{
    [self.callManager routeAudioToSpeaker:YES error:nil];

    OCMVerify([self.mockedAudioEngine routeAudioToSpeaker:YES error:nil]);
}

- (void)testEnableMicrophone
{
    [self.callManager setEnableMicrophone:NO];

    OCMVerify([self.mockedAudioEngine setEnableMicrophone:NO]);

    XCTAssertFalse(self.callManager.enableMicrophone);
}

- (void)testTogglePauseForCall
{
    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:12345 error:nil]).andReturn(YES);

    [self createFriendWithFriendNumber:12345];

    OCTCall *call = [self.callManager createCallWithFriendNumber:12345 status:OCTCallStatusActive];

    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil]);

    OCMStub([self.mockedAudioEngine isAudioRunning:nil]).andReturn(NO);

    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:12345 error:nil]).andReturn(YES);
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil]);
}

- (void)testSetAudioBitRate
{
    [self createFriendWithFriendNumber:123456];

    OCTCall *call = [self.callManager createCallWithFriendNumber:123456 status:OCTCallStatusActive];

    OCMStub([self.mockedToxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]).andReturn(YES);

    XCTAssertTrue([self.callManager setAudioBitrate:5555 forCall:call error:nil]);
    OCMVerify([self.mockedToxAV setAudioBitRate:5555 force:NO forFriend:123456 error:nil]);
}

- (void)testSetVideoBitRate
{
    [self createFriendWithFriendNumber:321];

    OCTCall *call = [self.callManager createCallWithFriendNumber:321 status:OCTCallStatusActive];

    OCMStub([self.mockedToxAV setVideoBitRate:5555 force:NO forFriend:321 error:nil]).andReturn(YES);

    XCTAssertTrue([self.callManager setVideoBitrate:5555 forCall:call error:nil]);
    OCMVerify([self.mockedToxAV setVideoBitRate:5555 force:NO forFriend:321 error:nil]);
}

#pragma mark - Pause Scenarios

- (void)testAnsweringAnotherCallWhileActive
{
    [OCMStub([self.mockedToxAV sendCallControl:123 toFriendNumber:123 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    [OCMStub([self.mockedToxAV answerIncomingCallFromFriend:123 audioBitRate:48 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    [self.mockedToxAV setExpectationOrderMatters:YES];
    OCMExpect([self.mockedToxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:4 error:[OCMArg anyObjectRef]]);
    OCMExpect([self.mockedToxAV answerIncomingCallFromFriend:5 audioBitRate:48 videoBitRate:0 error:[OCMArg anyObjectRef]]);

    OCMStub([self.callManager.audioEngine isAudioRunning:nil]).andReturn(YES);
    OCMStub([self.callManager.audioEngine stopAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    [self createFriendWithFriendNumber:4];
    [self createFriendWithFriendNumber:5];
    OCTCall *firstCall = [self.callManager createCallWithFriendNumber:4 status:OCTCallStatusActive];
    self.callManager.audioEngine.friendNumber = 4;

    // create incoming call
    OCTCall *secondCall = [self.callManager createCallWithFriendNumber:5 status:OCTCallStatusRinging];

    // mock call timer
    id mockedTimer = OCMClassMock([OCTCallTimer class]);
    [mockedTimer setExpectationOrderMatters:YES];
    OCMExpect([mockedTimer stopTimer]);
    OCMExpect([mockedTimer startTimerForCall:secondCall]);
    self.callManager.timer = mockedTimer;

    [self.callManager answerCall:secondCall enableAudio:YES enableVideo:NO error:nil];

    XCTAssertEqual(secondCall.status, OCTCallStatusActive);
    XCTAssertEqual(secondCall.pausedStatus, OCTCallPausedStatusNone);
    XCTAssertEqual(self.callManager.audioEngine.friendNumber, 5);

    XCTAssertEqual(firstCall.status, OCTCallStatusActive);
    XCTAssertEqual(firstCall.pausedStatus, OCTCallPausedStatusByUser);

    OCMVerifyAll(mockedTimer);
    OCMVerifyAll(self.mockedAudioEngine);
}

- (void)testPauseControlPermissions
{
    [self createFriendWithFriendNumber:11];

    OCTCall *call = [self.callManager createCallWithFriendNumber:11 status:OCTCallStatusActive];

    id mockedTimer = OCMClassMock([OCTCallTimer class]);
    [mockedTimer setExpectationOrderMatters:YES];
    self.callManager.timer = mockedTimer;
    OCMExpect([mockedTimer stopTimer]);
    OCMExpect([mockedTimer startTimerForCall:call]);

    [self.callManager toxAV:nil callStateChanged:OCTToxAVFriendCallStatePaused friendNumber:11];

    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByFriend);
    XCTAssertEqual(call.status, OCTCallStatusActive);

    id strictMockedTimer = OCMStrictClassMock([OCTCallTimer class]);
    self.callManager.timer = strictMockedTimer;

    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:11 error:[OCMArg anyObjectRef]]).andReturn(YES);
    [self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil];

    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByFriend);

    OCMStub([self.mockedToxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:11 error:[OCMArg anyObjectRef]]).andReturn(YES);
    [self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil];

    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByFriend | OCTCallPausedStatusByUser);

    [self.callManager toxAV:nil callStateChanged:OCTToxAVFriendCallStateAcceptingAudio friendNumber:11];
    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusByUser);

    self.callManager.timer = mockedTimer;

    [self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil];
    XCTAssertEqual(call.pausedStatus, OCTCallPausedStatusNone);

    OCMVerifyAll(mockedTimer);
}

#pragma mark - Private
- (void)testGetOrCreateCallWithFriend
{
    OCTFriend *friend = [self createFriendWithFriendNumber:222];

    OCTChat *chat = [self.realmManager getOrCreateChatWithFriend:friend];

    OCTCall *call = [self.callManager createCallWithFriendNumber:222 status:OCTCallStatusActive];
    OCTCall *sameCall = [self.callManager getCurrentCallForFriendNumber:222];

    XCTAssertNotNil(call.chat);
    XCTAssertEqualObjects(call.chat, chat);
    XCTAssertEqualObjects(sameCall, call);
}

 #pragma mark - Delegates

- (void)testReceiveCalls
{
    id delegate = OCMProtocolMock(@protocol(OCTSubmanagerCallDelegate));
    OCMStub([delegate respondsToSelector:[OCMArg anySelector]]).andReturn(YES);
    self.callManager.delegate = delegate;

    OCTFriend *friend = [self createFriendWithFriendNumber:221];

    OCTCall *call = [self.callManager createCallWithFriendNumber:221 status:OCTCallStatusActive];

    [self.callManager toxAV:nil receiveCallAudioEnabled:YES videoEnabled:NO friendNumber:221];
    OCMVerify([delegate callSubmanager:self.callManager receiveCall:call audioEnabled:YES videoEnabled:NO]);
    XCTAssertEqualObjects(friend, call.caller);
    XCTAssertFalse([call isOutgoing]);
}

- (void)testCallStateChanged
{
    [self createFriendWithFriendNumber:111];

    OCTCall *call = [self.callManager createCallWithFriendNumber:111 status:OCTCallStatusActive];

    OCTToxAVCallState state;

    state |= OCTToxAVFriendCallStateAcceptingAudio;
    state |= OCTToxAVFriendCallStateAcceptingVideo;

    [self.callManager toxAV:nil callStateChanged:state friendNumber:111];

    call = [self.callManager getCurrentCallForFriendNumber:111];

    XCTAssertTrue(call.friendAcceptingAudio);
    XCTAssertTrue(call.friendAcceptingVideo);
    XCTAssertFalse(call.friendSendingAudio);
    XCTAssertFalse(call.friendSendingVideo);
}

- (void)testReceiveAudio
{
    OCTToxAVPCMData pcm[] = { 1, 2, 3, 4};

    [self.callManager toxAV:nil receiveAudio:pcm sampleCount:4 channels:2 sampleRate:55 friendNumber:123];

    OCMVerify([self.mockedAudioEngine provideAudioFrames:pcm sampleCount:4 channels:2 sampleRate:55 fromFriend:123]);
}

- (void)testReceiveUnstableBitrate
{
    [self.callManager toxAV:self.mockedToxAV audioBitRateChanged:48 stable:NO friendNumber:1234];
    OCMVerify([self.mockedToxAV setAudioBitRate:32 force:NO forFriend:1234 error:nil]);

    [self.callManager toxAV:self.mockedToxAV audioBitRateChanged:32 stable:NO friendNumber:1234];
    OCMVerify([self.mockedToxAV setAudioBitRate:24 force:NO forFriend:1234 error:nil]);

    [self.callManager toxAV:self.mockedToxAV audioBitRateChanged:24 stable:NO friendNumber:1234];
    OCMVerify([self.mockedToxAV setAudioBitRate:16 force:NO forFriend:1234 error:nil]);

    [self.callManager toxAV:self.mockedToxAV audioBitRateChanged:16 stable:NO friendNumber:1234];
    OCMVerify([self.mockedToxAV setAudioBitRate:8 force:NO forFriend:1234 error:nil]);
}

#pragma mark Test helper methods
- (OCTFriend *)createFriendWithFriendNumber:(OCTToxFriendNumber)friendNumber
{
    OCTFriend *friend = [self createFriend];
    friend.friendNumber = friendNumber;

    [self.realmManager.realm beginWriteTransaction];
    [self.realmManager.realm addObject:friend];
    [self.realmManager.realm commitWriteTransaction];

    return friend;
}

@end
