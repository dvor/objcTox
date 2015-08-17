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
    OCTFetchRequestTypeMessageAbstract,
};

typedef NS_ENUM(NSInteger, OCTMessageFileState) {
    /**
     * The file is waiting for either you or your friend to accept it.
     * This is similar to the Paused state, so check the pauseFlags to figure
     * out who you are waiting for.
     */
    OCTMessageFileStateWaitingConfirmation,

    /**
     * File is downloading or uploading.
     * Resumable.
     */
    OCTMessageFileStateLoading,

    /**
     * Downloading or uploading of file is paused by us.
     * Resumable.
     */
    OCTMessageFileStatePaused,

    /**
     * Downloading or uploading of file was canceled.
     * Not resumable.
     */
    OCTMessageFileStateCanceled,

    /**
     * File is fully loaded.
     * In case of incoming file now it can be shown to user.
     * Not resumable.
     */
    OCTMessageFileStateReady,

    /**
     * File was interrupted, possibly by the friend going offline,
     * we crashed, etc.
     */
    OCTMessageFileStateInterrupted
};

/* Roughly corresponds to TOX_FILE_KIND in toxcore
 * You should not trust this property as file data is not checked for
 * valid image/video/whatever data. */
typedef NS_ENUM(NSInteger, OCTFileUsage) {
    /**
     * Standard type of file transfer.
     */
    OCTFileUsageData,
    /**
     * The file is an image that should be displayed inline, without
     * the ability for user interaction. (Unimplemented)
     */
    OCTFileUsageSticker,
    /**
     * Unimplemented.
     */
    OCTFileUsageInlinePhoto,
    /**
     * Unimplemented.
     */
    OCTFileUsageInlineVideo,
};

/* note: signed type is being used because of Realm. */
typedef NS_OPTIONS(NSInteger, OCTPauseFlags) {
    OCTPauseFlagsSelf = 1,
    OCTPauseFlagsFriend = 1 << 1,

        /* These are for convenience. */
        OCTPauseFlagsNobody = 0,
        OCTPauseFlagsBoth = OCTPauseFlagsSelf | OCTPauseFlagsFriend,
};

extern NSString *__nonnull const kOCTFileErrorDomain;

typedef NS_ENUM(NSInteger, OCTFileErrorCode) {
    /**
     * The file conduit could not be opened.
     */
    OCTFileErrorCodeBadConduit,
};
