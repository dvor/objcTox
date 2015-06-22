//
//  OCTSubmanagerCallsTests.m
//  objcTox
//
//  Created by Chuong Vu on 6/4/15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OCTSubmanagerCalls+Private.h"
#import "OCTAudioEngine.h"
#import "OCTToxAV.h"
#import "OCTTox.h"
#import "OCTCall+Private.h"
#import "OCTFriend+Private.h"
#import "OCTChat+Private.h"
#import "OCTConverterChat.h"
#import <OCMock/OCMock.h>

@interface OCTSubmanagerCalls (Tests)

@property (strong, nonatomic) OCTToxAV *toxAV;
@property (strong, nonatomic) OCTAudioEngine *audioEngine;
@property (strong, nonatomic) OCTConverterChat *chatConverter;
@property (strong, nonatomic, readwrite) OCTCallsContainer *calls;
@property (weak, nonatomic) id<OCTSubmanagerDataSource> dataSource;

- (OCTCall *)callFromFriend:(OCTToxFriendNumber)friendNumber;

- (void)toxAV:(OCTToxAV *)toxAV receiveCallAudioEnabled:(BOOL)audio videoEnabled:(BOOL)video friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV callStateChanged:(OCTToxAVCallState)state friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)toxAV:(OCTToxAV *)toxAV audioBitRateChanged:(OCTToxAVAudioBitRate)bitrate stable:(BOOL)stable friendNumber:(OCTToxFriendNumber)friendNumber;
- (void)   toxAV:(OCTToxAV *)toxAV
    receiveAudio:(OCTToxAVPCMData *)pcm
     sampleCount:(OCTToxAVSampleCount)sampleCount
        channels:(OCTToxAVChannels)channels
      sampleRate:(OCTToxAVSampleRate)sampleRate
    friendNumber:(OCTToxFriendNumber)friendNumber;

@end

@interface OCTSubmanagerCallsTests : XCTestCase

@property (strong, nonatomic) OCTTox *tox;
@property (strong, nonatomic) OCTSubmanagerCalls *callManager;

@end

@implementation OCTSubmanagerCallsTests

- (void)setUp
{
    [super setUp];

    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
    self.callManager = [[OCTSubmanagerCalls alloc] initWithTox:self.tox];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.callManager = nil;
    self.tox = nil;
    [super tearDown];
}

- (void)testInit
{
    XCTAssertNotNil(self.callManager);
    XCTAssertNotNil(self.callManager.calls);
    XCTAssertNotNil(self.callManager.audioEngine);
    XCTAssertEqual(0, self.callManager.calls.numberOfCalls);
}

- (void)testCallToChat
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    [OCMStub([toxAV callFriendNumber:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    self.callManager.toxAV = toxAV;

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    OCTCall *callResult = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    XCTAssertEqualObjects(call, callResult);
    XCTAssertEqual(self.callManager.calls.numberOfCalls, 1);
}

- (void)testEndCall
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    [OCMStub([toxAV callFriendNumber:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES) ignoringNonObjectArgs];
    OCMStub([toxAV sendCallControl:OCTToxAVCallControlCancel toFriendNumber:1234 error:[OCMArg anyObjectRef]]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    OCMStub([audioEngine stopAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);
    self.callManager.audioEngine = audioEngine;

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [self.callManager callToChat:chat enableAudio:YES enableVideo:NO error:nil];

    XCTAssertEqual(self.callManager.calls.numberOfCalls, 1);

    NSError *error;
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlCancel toCall:call error:&error]);

    XCTAssertEqual(0, self.callManager.calls.numberOfCalls);
}

- (void)testAnswerCallFail
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusIncoming;
    [self.callManager.calls addCall:call];

    XCTAssertFalse([self.callManager answerCall:call enableAudio:YES enableVideo:YES error:nil]);
    [OCMExpect([toxAV answerIncomingCallFromFriend:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]) ignoringNonObjectArgs];
}

- (void)testAnswerCallSuccess
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;

    id audioEngine = OCMPartialMock(self.callManager.audioEngine);
    OCMStub([audioEngine startAudioFlow:[OCMArg anyObjectRef]]).andReturn(YES);

    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusIncoming;
    [self.callManager.calls addCall:call];

    OCMStub([toxAV answerIncomingCallFromFriend:1234 audioBitRate:0 videoBitRate:0 error:[OCMArg anyObjectRef]]).andReturn(YES);

    XCTAssertTrue([self.callManager answerCall:call enableAudio:NO enableVideo:NO error:nil]);
    XCTAssertEqual(self.callManager.audioEngine.friendNumber, 1234);
}

- (void)testRouteAudioToSpeaker
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    [self.callManager routeAudioToSpeaker:YES error:nil];

    OCMVerify([audioEngine routeAudioToSpeaker:YES error:nil]);
}

- (void)testEnableMicrophone
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    [self.callManager setEnableMicrophone:NO];

    OCMVerify([audioEngine setEnableMicrophone:NO]);
}

- (void)testTogglePauseForCall
{
    id toxAV = OCMClassMock([OCTToxAV class]);
    self.callManager.toxAV = toxAV;
    OCMStub([toxAV sendCallControl:OCTToxAVCallControlPause toFriendNumber:1234 error:nil]).andReturn(YES);
    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    call.status = OCTCallStatusActive;
    [self.callManager.calls addCall:call];

    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlPause toCall:call error:nil]);
    XCTAssertEqual([self.callManager.calls callAtIndex:0].status, OCTCallStatusPaused);

    OCMStub([toxAV sendCallControl:OCTToxAVCallControlResume toFriendNumber:1234 error:nil]).andReturn(YES);
    XCTAssertTrue([self.callManager sendCallControl:OCTToxAVCallControlResume toCall:call error:nil]);
    XCTAssertEqual([self.callManager.calls callAtIndex:0].status, OCTCallStatusActive);
}

- (void)testSetAudioBitRate
{
    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setAudioBitRate:5555 force:NO forFriend:1234 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setAudioBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setAudioBitRate:5555 force:NO forFriend:1234 error:nil]);
}

- (void)testSetVideoBitRate
{
    OCTChat *chat = [OCTChat new];
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];

    id toxAV = OCMClassMock([OCTToxAV class]);
    OCMStub([toxAV setVideoBitRate:5555 force:NO forFriend:1234 error:nil]).andReturn(YES);
    self.callManager.toxAV = toxAV;

    XCTAssertTrue([self.callManager setVideoBitrate:5555 forCall:call error:nil]);
    OCMVerify([toxAV setVideoBitRate:5555 force:NO forFriend:1234 error:nil]);

}
#pragma mark - Delegates

- (void)testReceiveCalls
{
    id delegate = OCMProtocolMock(@protocol(OCTSubmanagerCallDelegate));
    OCMStub([delegate respondsToSelector:[OCMArg anySelector]]).andReturn(YES);
    self.callManager.delegate = delegate;

    id calls = OCMClassMock([OCTCallsContainer class]);
    self.callManager.calls = calls;

    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"test";

    id chatConverter = OCMClassMock([OCTConverterChat class]);
    self.callManager.chatConverter = chatConverter;
    OCMStub([chatConverter objectFromRLMObject:[OCMArg any]]).andReturn(chat);

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    id mockedCall = OCMClassMock([OCTCall class]);
    OCMStub([mockedCall alloc]).andReturn(call);

    [self.callManager toxAV:nil receiveCallAudioEnabled:YES videoEnabled:NO friendNumber:1234];
    OCMVerify([delegate callSubmanager:self.callManager receiveCall:call audioEnabled:YES videoEnabled:NO]);
    OCMVerify([calls addCall:call]);
}

- (void)testCallStateChanged
{
    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"test";
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 1234;

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    OCTToxAVCallState state;

    state |= OCTToxAVCallStateReceivingAudio;
    state |= OCTToxAVCallStateReceivingVideo;
    call.state = state;

    [self.callManager.calls addCall:call];
    XCTAssertEqual(state, [self.callManager.calls callAtIndex:0].state);

    XCTAssertEqual(call.state, state);
    id chatConverter = OCMClassMock([OCTConverterChat class]);
    self.callManager.chatConverter = chatConverter;
    OCMStub([chatConverter objectFromRLMObject:[OCMArg any]]).andReturn(chat);

    state |= OCTToxAVCallStateSendingAudio;
    [self.callManager toxAV:nil callStateChanged:state friendNumber:1234];

    XCTAssertEqual(state, [self.callManager.calls callAtIndex:0].state);
}

- (void)testAudioBitRateChanged
{
    id callManager = OCMPartialMock(self.callManager);
    self.callManager = callManager;

    id delegate = OCMProtocolMock(@protocol(OCTSubmanagerCallDelegate));
    OCMStub([delegate respondsToSelector:[OCMArg anySelector]]).andReturn(YES);
    self.callManager.delegate = delegate;

    OCTChat *chat = [OCTChat new];
    chat.uniqueIdentifier = @"test";
    OCTFriend *friend = [OCTFriend new];
    friend.friendNumber = 123;
    chat.friends = @[friend];

    OCTCall *call = [[OCTCall alloc] initCallWithChat:chat];
    [self.callManager.calls addCall:call];

    OCMStub([callManager callFromFriend:123]).andReturn(call);

    [self.callManager toxAV:nil audioBitRateChanged:999 stable:NO friendNumber:123];
    OCMVerify([delegate callSubmanager:[OCMArg any] audioBitRateChanged:999 stable:NO forCall:call]);
}

- (void)testReceiveAudio
{
    id audioEngine = OCMClassMock([OCTAudioEngine class]);
    self.callManager.audioEngine = audioEngine;

    OCTToxAVPCMData pcm[] = { 1, 2, 3, 4};

    [self.callManager toxAV:nil receiveAudio:pcm sampleCount:4 channels:2 sampleRate:55 friendNumber:123];

    OCMVerify([audioEngine provideAudioFrames:pcm sampleCount:4 channels:2 sampleRate:55]);
}

@end
