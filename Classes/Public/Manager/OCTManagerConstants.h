//
//  OCTManagerConstants.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

typedef NS_ENUM(NSUInteger, OCTFetchRequestType) {
    OCTFetchRequestTypeFriend,
    OCTFetchRequestTypeFriendRequest,
    OCTFetchRequestTypeChat,
    OCTFetchRequestTypeCall,
    OCTFetchRequestTypeMessageAbstract,
};

typedef NS_ENUM(NSInteger, OCTMessageFileType) {
    /**
     * File is incoming and is waiting confirmation of user to be downloaded.
     * Please start loading or cancel it with <<placeholder>> method.
     */
    OCTMessageFileTypeWaitingConfirmation,

    /**
     * File is downloading or uploading.
     */
    OCTMessageFileTypeLoading,

    /**
     * Downloading or uploading of file is paused.
     */
    OCTMessageFileTypePaused,

    /**
     * Downloading or uploading of file was canceled.
     */
    OCTMessageFileTypeCanceled,

    /**
     * File is fully loaded.
     * In case of incoming file now it can be shown to user.
     */
    OCTMessageFileTypeReady,
};

typedef NS_ENUM(NSInteger, OCTMessageCallEvent) {
    /**
     * Call was answered.
     */
    OCTMessageCallEventAnswered,

    /**
     * Call was unanswered.
     */
    OCTMessageCallEventUnanswered,
};

typedef NS_ENUM(NSInteger, OCTCallStatus) {
    /**
     * Call is currently ringing.
     */
    OCTCallStatusRinging,

    /**
     * Call is currently dialing a chat.
     */
    OCTCallStatusDialing,

    /**
     * Call is currently active in session.
     */
    OCTCallStatusActive,
};

typedef NS_OPTIONS(NSInteger, OCTCallPausedStatus) {
    /**
     * Call is not paused
     */
    OCTCallPausedStatusNone = 0,

    /**
     * Call is paused by the user
     */
    OCTCallPausedStatusByUser = 1 << 0,

        /**
         * Call is paused by friend
         */
        OCTCallPausedStatusByFriend = 1 << 1,
};
