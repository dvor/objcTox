//
//  OCTToxTests.m
//  objcTox
//
//  Created by Dmytro Vorobiov on 04.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>

#import "OCTTox+Private.h"
#import "OCTCAsserts.h"

void *refToSelf;

void mocked_tox_self_get_public_key(const Tox *tox, uint8_t *public_key);

@interface OCTToxTests : XCTestCase

@property (strong, nonatomic) OCTTox *tox;

@end

@implementation OCTToxTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    refToSelf = (__bridge void *)(self);

    self.tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:nil error:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    refToSelf = NULL;

    self.tox = nil;

    [super tearDown];
}

// - (void)testInit
// {
//     XCTAssertNotNil(self.tox);
// }

// - (void)testSavingAndLoading
// {
//     NSData *data = [self.tox save];
//     XCTAssertNotNil(data);

//     OCTTox *tox = [[OCTTox alloc] initWithOptions:[OCTToxOptions new] savedData:data error:nil];
//     XCTAssertNotNil(tox);

//     NSData *data2 = [tox save];

//     XCTAssertTrue(data.length == data2.length);
// }

// - (void)testPublicKey
// {
//     _tox_self_get_public_key = mocked_tox_self_get_public_key;

//     NSString *publicKey = [self.tox publicKey];

//     XCTAssertEqualObjects(publicKey, @"000102030405060708090A0B0C0D0E0F" @"000102030405060708090A0B0C0D0E0F");
// }

// #pragma mark -  Private methods

// - (void)testUserStatusFromCUserStatus
// {
//     XCTAssertTrue(OCTToxUserStatusNone == [self.tox userStatusFromCUserStatus:TOX_USER_STATUS_NONE]);
//     XCTAssertTrue(OCTToxUserStatusAway == [self.tox userStatusFromCUserStatus:TOX_USER_STATUS_AWAY]);
//     XCTAssertTrue(OCTToxUserStatusBusy == [self.tox userStatusFromCUserStatus:TOX_USER_STATUS_BUSY]);
// }

// - (void)testUserConnectionStatusFromCUserStatus
// {
//     XCTAssertTrue(OCTToxConnectionStatusNone == [self.tox userConnectionStatusFromCUserStatus:TOX_CONNECTION_NONE]);
//     XCTAssertTrue(OCTToxConnectionStatusTCP  == [self.tox userConnectionStatusFromCUserStatus:TOX_CONNECTION_TCP]);
//     XCTAssertTrue(OCTToxConnectionStatusUDP  == [self.tox userConnectionStatusFromCUserStatus:TOX_CONNECTION_UDP]);
// }

// - (void)testMessageTypeFromCMessageType
// {
//     XCTAssertTrue(OCTToxMessageTypeNormal == [self.tox messageTypeFromCMessageType:TOX_MESSAGE_TYPE_NORMAL]);
//     XCTAssertTrue(OCTToxMessageTypeAction == [self.tox messageTypeFromCMessageType:TOX_MESSAGE_TYPE_ACTION]);
// }

// - (void)testFileControlFromCFileControl
// {
//     XCTAssertTrue(OCTToxFileControlResume == [self.tox fileControlFromCFileControl:TOX_FILE_CONTROL_RESUME]);
//     XCTAssertTrue(OCTToxFileControlPause  == [self.tox fileControlFromCFileControl:TOX_FILE_CONTROL_PAUSE]);
//     XCTAssertTrue(OCTToxFileControlCancel == [self.tox fileControlFromCFileControl:TOX_FILE_CONTROL_CANCEL]);
// }

// - (void)testFillErrorInit
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorInit:TOX_ERR_NEW_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_MALLOC];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeMemoryError);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_PORT_ALLOC];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodePortAlloc);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_PROXY_BAD_TYPE];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeProxyBadType);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_PROXY_BAD_HOST];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeProxyBadHost);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_PROXY_BAD_PORT];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeProxyBadPort);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_PROXY_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeProxyNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_LOAD_ENCRYPTED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeEncrypted);

//     error = nil;
//     [self.tox fillError:&error withCErrorInit:TOX_ERR_NEW_LOAD_BAD_FORMAT];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorInitCodeLoadBadFormat);
// }

// - (void)testFillErrorBootstrap
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorBootstrap:TOX_ERR_BOOTSTRAP_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorBootstrap:TOX_ERR_BOOTSTRAP_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorBootstrap:TOX_ERR_BOOTSTRAP_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorBootstrapCodeUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorBootstrap:TOX_ERR_BOOTSTRAP_BAD_HOST];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorBootstrapCodeBadHost);

//     error = nil;
//     [self.tox fillError:&error withCErrorBootstrap:TOX_ERR_BOOTSTRAP_BAD_PORT];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorBootstrapCodeBadPort);
// }

// - (void)testFillErrorFriendAdd
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_TOO_LONG];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddTooLong);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_NO_MESSAGE];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddNoMessage);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_OWN_KEY];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddOwnKey);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_ALREADY_SENT];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddAlreadySent);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_BAD_CHECKSUM];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddBadChecksum);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_SET_NEW_NOSPAM];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddSetNewNospam);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendAdd:TOX_ERR_FRIEND_ADD_MALLOC];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendAddMalloc);
// }

// - (void)testFillErrorFriendDelete
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFriendDelete:TOX_ERR_FRIEND_DELETE_FRIEND_NOT_FOUND];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFriendDelete:TOX_ERR_FRIEND_DELETE_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendDelete:TOX_ERR_FRIEND_DELETE_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendDeleteNotFound);
// }

// - (void)testFillErrorFriendByPublicKey
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFriendByPublicKey:TOX_ERR_FRIEND_BY_PUBLIC_KEY_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFriendByPublicKey:TOX_ERR_FRIEND_BY_PUBLIC_KEY_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendByPublicKey:TOX_ERR_FRIEND_BY_PUBLIC_KEY_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendByPublicKeyUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendByPublicKey:TOX_ERR_FRIEND_BY_PUBLIC_KEY_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendByPublicKeyNotFound);
// }

// - (void)testFillErrorFriendGetPublicKey
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFriendGetPublicKey:TOX_ERR_FRIEND_GET_PUBLIC_KEY_FRIEND_NOT_FOUND];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFriendGetPublicKey:TOX_ERR_FRIEND_GET_PUBLIC_KEY_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendGetPublicKey:TOX_ERR_FRIEND_GET_PUBLIC_KEY_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendGetPublicKeyFriendNotFound);
// }

// - (void)testFillErrorSetInfo
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorSetInfo:TOX_ERR_SET_INFO_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorSetInfo:TOX_ERR_SET_INFO_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorSetInfo:TOX_ERR_SET_INFO_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorSetInfoCodeUnknow);

//     error = nil;
//     [self.tox fillError:&error withCErrorSetInfo:TOX_ERR_SET_INFO_TOO_LONG];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorSetInfoCodeTooLong);
// }

// - (void)testFillErrorFriendGetLastOnline
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFriendGetLastOnline:TOX_ERR_FRIEND_GET_LAST_ONLINE_FRIEND_NOT_FOUND];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFriendGetLastOnline:TOX_ERR_FRIEND_GET_LAST_ONLINE_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendGetLastOnline:TOX_ERR_FRIEND_GET_LAST_ONLINE_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendGetLastOnlineFriendNotFound);
// }

// - (void)testFillErrorFriendQuery
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFriendQuery:TOX_ERR_FRIEND_QUERY_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFriendQuery:TOX_ERR_FRIEND_QUERY_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendQuery:TOX_ERR_FRIEND_QUERY_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendQueryUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendQuery:TOX_ERR_FRIEND_QUERY_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendQueryFriendNotFound);
// }

// - (void)testFillErrorSetTyping
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorSetTyping:TOX_ERR_SET_TYPING_FRIEND_NOT_FOUND];

//     NSError *error;
//     [self.tox fillError:&error withCErrorSetTyping:TOX_ERR_SET_TYPING_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorSetTyping:TOX_ERR_SET_TYPING_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorSetTypingFriendNotFound);
// }

// - (void)testFillErrorFriendSendMessage
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendSendMessageUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendSendMessageFriendNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_FRIEND_NOT_CONNECTED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendSendMessageFriendNotConnected);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_SENDQ];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendSendMessageAlloc);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_TOO_LONG];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendSendMessageTooLong);

//     error = nil;
//     [self.tox fillError:&error withCErrorFriendSendMessage:TOX_ERR_FRIEND_SEND_MESSAGE_EMPTY];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFriendSendMessageEmpty);
// }

// - (void)testFillErrorFileControl
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFileControl:TOX_ERR_FILE_CONTROL_FRIEND_NOT_FOUND];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileControlFriendNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_FRIEND_NOT_CONNECTED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileControlFriendNotConnected);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileControlNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_NOT_PAUSED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileControlNotPaused);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_DENIED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileControlDenied);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_ALREADY_PAUSED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileControlAlreadyPaused);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileControl:TOX_ERR_FILE_CONTROL_SENDQ];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileControlSendq);
// }

// - (void)testFillErrorFileSeek
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFileSeek:TOX_ERR_FILE_SEEK_FRIEND_NOT_FOUND];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFileSeek:TOX_ERR_FILE_SEEK_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSeek:TOX_ERR_FILE_SEEK_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSeekFriendNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSeek:TOX_ERR_FILE_SEEK_FRIEND_NOT_CONNECTED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSeekFriendNotConnected);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSeek:TOX_ERR_FILE_SEEK_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSeekNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSeek:TOX_ERR_FILE_SEEK_DENIED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSeekDenied);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSeek:TOX_ERR_FILE_SEEK_INVALID_POSITION];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSeekInvalidPosition);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSeek:TOX_ERR_FILE_SEEK_SENDQ];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSeekSendq);
// }

// - (void)testFillErrorFileGet
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFileGet:TOX_ERR_FILE_GET_FRIEND_NOT_FOUND];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFileGet:TOX_ERR_FILE_GET_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileGet:TOX_ERR_FILE_GET_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileGetInternal);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileGet:TOX_ERR_FILE_GET_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileGetFriendNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileGet:TOX_ERR_FILE_GET_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileGetNotFound);
// }

// - (void)testFillErrorFileSend
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFileSend:TOX_ERR_FILE_SEND_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFileSend:TOX_ERR_FILE_SEND_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSend:TOX_ERR_FILE_SEND_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSend:TOX_ERR_FILE_SEND_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendFriendNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSend:TOX_ERR_FILE_SEND_FRIEND_NOT_CONNECTED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendFriendNotConnected);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSend:TOX_ERR_FILE_SEND_NAME_TOO_LONG];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendNameTooLong);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSend:TOX_ERR_FILE_SEND_TOO_MANY];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendTooMany);
// }

// - (void)testFillErrorFileSendChunk
// {
//     // test nil error
//     [self.tox fillError:nil withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_NULL];

//     NSError *error;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_OK];
//     XCTAssertNil(error);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_NULL];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkUnknown);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_FRIEND_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkFriendNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_FRIEND_NOT_CONNECTED];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkFriendNotConnected);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_NOT_FOUND];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkNotFound);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_NOT_TRANSFERRING];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkNotTransferring);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_INVALID_LENGTH];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkInvalidLength);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_SENDQ];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkSendq);

//     error = nil;
//     [self.tox fillError:&error withCErrorFileSendChunk:TOX_ERR_FILE_SEND_CHUNK_WRONG_POSITION];
//     XCTAssertNotNil(error);
//     XCTAssertTrue(error.code == OCTToxErrorFileSendChunkWrongPosition);
// }

// - (void)testCToxOptionsFromOptions
// {
//     OCTToxOptions *options = [OCTToxOptions new];
//     options.IPv6Enabled = YES;
//     options.UDPEnabled = YES;
//     options.startPort = 10;
//     options.endPort = 20;
//     options.proxyType = OCTToxProxyTypeHTTP;
//     options.proxyHost = @"host";
//     options.proxyPort = 30;
//     options.tcpPort = 40;

//     struct Tox_Options cOptions = [self.tox cToxOptionsFromOptions:options];

//     XCTAssertTrue(cOptions.ipv6_enabled);
//     XCTAssertTrue(cOptions.udp_enabled);
//     XCTAssertTrue(cOptions.start_port == 10);
//     XCTAssertTrue(cOptions.end_port == 20);
//     XCTAssertTrue(cOptions.proxy_type == TOX_PROXY_TYPE_HTTP);
//     XCTAssertTrue(strcmp(cOptions.proxy_host, "host") == 0);
//     XCTAssertTrue(cOptions.proxy_port == 30);
//     XCTAssertTrue(cOptions.tcp_port == 40);
// }

// - (void)testBinToHexString
// {
//     uint8_t bin[16] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
//     NSString *string = [OCTTox binToHexString:bin length:16];

//     XCTAssertTrue([@"000102030405060708090A0B0C0D0E0F" isEqualToString:string]);
// }

// - (void)testHexStringToBin
// {
//     uint8_t *bin = [OCTTox hexStringToBin:@"000102030405060708090A0B0C0D0E0F"];

//     for (NSUInteger i = 0; i < 16; i++) {
//         XCTAssertTrue(bin[i] == i);
//     }
// }

// #pragma mark -  Callbacks

// - (void)testConnectionStatusCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         connectionStatusCallback(NULL, TOX_CONNECTION_UDP, (__bridge void *)self.tox);
//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox connectionStatus:OCTToxConnectionStatusUDP]);
//     }];
// }

// - (void)testFriendNameCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         friendNameCallback(NULL, 5, (const uint8_t *)"name", 4, (__bridge void *)self.tox);
//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox friendNameUpdate:[OCMArg isEqual:@"name"] friendNumber:5]);
//     }];
// }

// - (void)testFriendStatusMessageCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         friendStatusMessageCallback(NULL, 5, (const uint8_t *)"message", 7, (__bridge void *)self.tox);
//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox friendStatusMessageUpdate:[OCMArg isEqual:@"message"] friendNumber:5]);
//     }];
// }

// - (void)testFriendStatusCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         friendStatusCallback(NULL, 5, TOX_USER_STATUS_BUSY, (__bridge void *)self.tox);
//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox friendStatusUpdate:OCTToxUserStatusBusy friendNumber:5]);
//     }];
// }

// - (void)testFriendConnectionStatusCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         friendConnectionStatusCallback(NULL, 5, TOX_CONNECTION_UDP, (__bridge void *)self.tox);
//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox friendConnectionStatusChanged:OCTToxConnectionStatusUDP friendNumber:5]);
//     }];
// }

// - (void)testFriendTypingCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         friendTypingCallback(NULL, 5, true, (__bridge void *)self.tox);
//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox friendIsTypingUpdate:YES friendNumber:5]);
//     }];
// }

// - (void)testFriendReadReceiptCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         friendReadReceiptCallback(NULL, 5, 7, (__bridge void *)self.tox);
//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox messageDelivered:7 friendNumber:5]);
//     }];
// }

// - (void)testFriendRequestCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         uint8_t bin[32] = {
//             0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
//             0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
//         };

//         friendRequestCallback(NULL, bin, (const uint8_t *)"message", 7, (__bridge void *)self.tox);

//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         NSString *publicKey =
//             @"000102030405060708090A0B0C0D0E0F"
//             @"000102030405060708090A0B0C0D0E0F";

//         OCMExpect([self.tox.delegate tox:self.tox friendRequestWithMessage:[OCMArg isEqual:@"message"] publicKey:publicKey]);
//     }];
// }

// - (void)testFriendMessageCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         friendMessageCallback(NULL, 5, TOX_MESSAGE_TYPE_ACTION, (const uint8_t *)"message", 7, (__bridge void *)self.tox);

//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox
//                            friendMessage:[OCMArg isEqual:@"message"]
//                                     type:OCTToxMessageTypeAction
//                             friendNumber:5]);
//     }];
// }

// - (void)testFileReceiveControlCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         fileReceiveControlCallback(NULL, 5, 4, TOX_FILE_CONTROL_PAUSE, (__bridge void *)self.tox);

//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox fileReceiveControl:OCTToxFileControlPause friendNumber:5 fileNumber:4]);
//     }];
// }

// - (void)testFileChunkRequestCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         fileChunkRequestCallback(NULL, 5, 4, 300, 150, (__bridge void *)self.tox);

//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox fileChunkRequestForFileNumber:4 friendNumber:5 position:300 length:150]);
//     }];
// }

// - (void)testFileReceiveCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         fileReceiveCallback(NULL, 5, 4, TOX_FILE_KIND_DATA, 500, (const uint8_t *)"filename", 8, (__bridge void *)self.tox);

//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         OCMExpect([self.tox.delegate tox:self.tox
//                    fileReceiveForFileNumber:4
//                                friendNumber:5
//                                        kind:OCTToxFileKindData
//                                    fileSize:500
//                                    fileName:[OCMArg isEqual:@"filename"]]);
//     }];
// }

// - (void)testFileReceiveChunkCallback
// {
//     [self makeTestCallbackWithCallBlock:^{
//         fileReceiveChunkCallback(NULL, 5, 4, 250, (const uint8_t *)"data", 4, (__bridge void *)self.tox);

//     } expectBlock:^(id<OCTToxDelegate> delegate) {
//         NSData *data = [NSData dataWithBytes:"data" length:4];

//         OCMExpect([self.tox.delegate tox:self.tox
//                         fileReceiveChunk:[OCMArg isEqual:data]
//                               fileNumber:4
//                             friendNumber:5
//                                 position:250]);
//     }];
// }

// - (void)makeTestCallbackWithCallBlock:(void (^)())callBlock expectBlock:(void (^)(id<OCTToxDelegate> delegate))expectBlock
// {
//     NSParameterAssert(callBlock);
//     NSParameterAssert(expectBlock);

//     self.tox.delegate = OCMProtocolMock(@protocol(OCTToxDelegate));
//     expectBlock(self.tox.delegate);

//     XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];

//     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//         callBlock();
//         [expectation fulfill];
//     });

//     [self waitForExpectationsWithTimeout:1.0 handler:nil];
//     OCMVerifyAll((id)self.tox.delegate);
// }

// void mocked_tox_self_get_public_key(const Tox *cTox, uint8_t *public_key)
// {
//     OCTTox *tox = [(__bridge OCTToxTests *)refToSelf tox];

//     CCCAssertTrue(cTox == tox.tox);

//     uint8_t bin[32] = {
//         0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
//         0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
//     };

//     memcpy(public_key, bin, TOX_PUBLIC_KEY_SIZE);
// }

@end
