//
//  OCTTox.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 02.03.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCTToxDelegate.h"
#import "OCTToxOptions.h"
#import "OCTToxConstants.h"

extern NSString *const kOCTToxErrorDomain;

/**
 * Length of address. Address is hex string, has following format:
 * [public_key (32 bytes, 64 characters)][nospam number (4 bytes, 8 characters)][checksum (2 bytes, 4 characters)]
 */
extern const NSUInteger kOCTToxAddressLength;

/**
 * Length of public key. It is hex string, 32 bytes, 64 characters.
 */
extern const NSUInteger kOCTToxPublicKeyLength;

@interface OCTTox : NSObject

@property (weak, nonatomic) id<OCTToxDelegate> delegate;

/**
 * Indicates if we are connected to the DHT.
 */
@property (assign, nonatomic, readonly) BOOL isConnected;

/**
 * Our address
 *
 * Address for Tox as a hex string. Address is kOCTToxAddressLength length and has following format:
 * [public_key (32 bytes, 64 characters)][nospam number (4 bytes, 8 characters)][checksum (2 bytes, 4 characters)]
 */
@property (strong, nonatomic, readonly) NSString *userAddress;

#pragma mark -  Lifecycle

/**
 * Creates new Tox object with configuration options.
 *
 * @param options Configuration options
 *
 * @return New instance of Tox.
 */
- (instancetype)initWithOptions:(OCTToxOptions *)options;

/**
 * Load saved Tox from NSData.
 *
 * @param data Data load Tox from.
 *
 * @return Return status of load.
 *
 * @warning The Tox save format isn't stable yet meaning this function sometimes returns -1 when loading
 * older saves. This however does not mean nothing was loaded from the save.
 */
- (OCTToxLoadStatus)loadFromData:(NSData *)data;

/**
 * Saves Tox into NSData.
 *
 * @return NSData with Tox save.
 */
- (NSData *)save;

/**
 * Starts the main loop of the Tox.
 *
 * @warning Tox won't do anything without calling this method.
 */
- (void)start;

/**
 * Stops the main loop of the Tox.
 */
- (void)stop;

#pragma mark -  Methods

/**
 * Resolves address into an IP address. If successful, sends a "get nodes" request to the given node with ip,
 * port (in host byte order) and publicKey to setup connections.
 *
 * @param address Address can be a hostname or an IP address (IPv4 or IPv6).
 * @param port Port in host byte order.
 * @param publicKey Public key of the node.
 *
 * @return YES if address could be converted info an IP address, NO otherwise.
 */
- (BOOL)bootstrapFromAddress:(NSString *)address port:(uint16_t)port publicKey:(NSString *)publicKey;

/**
 * Like `bootstrapFromAddress` but for TCP relays only.
 *
 * @param address Address can be a hostname or an IP address (IPv4 or IPv6).
 * @param port Port in host byte order.
 * @param publicKey Public key of the node.
 *
 * @return YES if address could be converted info an IP address, NO otherwise.
 */
- (BOOL)addTCPRelayWithAddress:(NSString *)address port:(uint16_t)port publicKey:(NSString *)publicKey;

/**
 * Add a friend.
 *
 * @param address Address of a friend to add. Must be exactry kOCTToxAddressLength length.
 * @param message Message that would be send with friend request. Minimum length - 1 byte.
 * @param error Error with OCTToxAddFriendError code.
 *
 * @return On success returns friend number. On failure returns -1 and fills `error` parameter.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeFriendRequest type. If message will be too big it will be cropped to fit the length.
 */
- (int32_t)addFriendWithAddress:(NSString *)address message:(NSString *)message error:(NSError **)error;

/**
 * Add a friend without sending friend request.
 *
 * @param publicKey Public key of a friend to add. Public key is hex string, must be exactry kOCTToxPublicKeyLength length.
 *
 * @return On success returns friend number. On failure returns -1.
 */
- (int32_t)addFriendWithNoRequestWithPublicKey:(NSString *)publicKey;

/**
 * Get associated friend number from public key.
 *
 * @param publicKey Public key of a friend. Public key is hex string, must be exactry kOCTToxPublicKeyLength length.
 *
 * @return On success returns friend number. If there is no such friend returns -1.
 */
- (int32_t)friendNumberWithPublicKey:(NSString *)publicKey;

/**
 * Get public key from associated friend number.
 *
 * @param friendNumber Associated friend number
 *
 * @return Public key of a friend. Public key is hex string, must be exactry kOCTToxPublicKeyLength length. If there is no such friend returns nil.
 */
- (NSString *)publicKeyFromFriendNumber:(int32_t)friendNumber;

/**
 * Remove a friend
 *
 * @param friendNumber Friend number to remove.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)deleteFriendWithFriendNumber:(int32_t)friendNumber;

/**
 * Get friend connection status.
 *
 * @param friendNumber Friend number to check status.
 *
 * @return Returns connection status or OCTToxAddFriendErrorUnknown in case of failure.
 */
- (OCTToxConnectionStatus)friendConnectionStatusWithFriendNumber:(int32_t)friendNumber;

/**
 * Checks if there exists a friend with given friendNumber.
 *
 * @param friendNumber Friend number to check.
 *
 * @return YES if friend exists, NO otherwise.
 */
- (BOOL)friendExistsWithFriendNumber:(int32_t)friendNumber;

/**
 * Send a text chat message to an online friend.
 *
 * @param friendNumber Friend number to send a message.
 * @param message Message that would be send.
 *
 * @return The message id if packet was successfully put into the send queue, 0 if it was not. You can use id later to check if message has been delivered.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeSendMessage type. If message will be too big it will be cropped to fit the length.
 */
- (uint32_t)sendMessageWithFriendNumber:(int32_t)friendNumber message:(NSString *)message;

/**
 * Send an action to an online friend.
 *
 * @param friendNumber Friend number to send a action.
 * @param action Action that would be send.
 *
 * @return The message id if packet was successfully put into the send queue, 0 if it was not.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeSendMessage type. If message will be too big it will be cropped to fit the length.
 */
- (uint32_t)friendNumber:(int32_t)friendNumber action:(NSString *)action;

/**
 * Set our nickname.
 *
 * @param name Name to be set. Minimum length of name is 1 byte.
 *
 * @return YES on success, NO on failure.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeName type. If message will be too big it will be cropped to fit the length.
 */
- (BOOL)setUserName:(NSString *)name;

/**
 * Get your nickname.
 *
 * @return Your nickname or nil in case of error.
 */
- (NSString *)userName;

/**
 * Get name of friendNumber.
 *
 * @param friendNumber Friend number to get name.
 *
 * @return Name of friend or nil in case of error.
 */
- (NSString *)friendNameWithFriendNumber:(int32_t)friendNumber;

/**
 * Set our status message.
 *
 * @param statusMessage Status message to be set.
 *
 * @return YES on success, NO on failure.
 *
 * @warning You can check maximum length of message with `-checkLengthOfString:withCheckType:` method with
 * OCTToxCheckLengthTypeStatusMessage type. If message will be too big it will be cropped to fit the length.
 */
- (BOOL)setUserStatusMessage:(NSString *)statusMessage;

/**
 * Get our status message.
 *
 * @return Our status message.
 */
- (NSString *)userStatusMessage;

/**
 * Set our status.
 *
 * @param status Status to be set.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)setUserStatus:(OCTToxUserStatus)status;

/**
 * Get status message of a friend.
 *
 * @param friendNumber Friend number to get status message.
 *
 * @return Status message of a friend.
 */
- (NSString *)friendStatusMessageWithFriendNumber:(int32_t)friendNumber;

/**
 * Get date of last time friendNumber was seen online.
 *
 * @param friendNumber Friend number to get last online.
 *
 * @return Date of last time friend was seen online.
 */
- (NSDate *)lastOnlineWithFriendNumber:(int32_t)friendNumber;

/**
 * Set our typing status for a friend. You are responsible for turning it on or off.
 *
 * @param isTyping Status showing whether user is typing or not.
 * @param friendNumber Friend number to set typing status.
 *
 * @return YES on success, NO on failure.
 */
- (BOOL)setUserIsTyping:(BOOL)isTyping forFriendNumber:(int32_t)friendNumber;

/**
 * Get the typing status of a friend.
 *
 * @param friendNumber Friend number to get typing status.
 *
 * @return YES if friend is typing, otherwise NO.
 */
- (BOOL)isFriendTypingWithFriendNumber:(int32_t)friendNumber;

/**
 * Return the number of friends.
 *
 * @return Return the number of friends.
 */
- (NSUInteger)friendsCount;

/**
 * Return the number of friends online.
 *
 * @return Return the number of friends online.
 */
- (NSUInteger)friendsOnlineCount;

/**
 * Return an array of valid friend IDs.
 *
 * @return Return an array of valid friend IDs. Array contain NSNumbers with IDs.
 */
- (NSArray *)friendsArray;

/**
 * Set avatar for current user.
 * This should be made before connecting, so we will not announce that the user have no avatar
 * before setting and announcing a new one, forcing the peers to re-download it.
 *
 * @param data Avatar data. Data should be <= that length `-getMaximumDataLengthForType:` with
 * OCTToxDataLengthTypeAvatar type. You can pass nil to remove avatar. Avatar should be PNG representation of image.
 *
 * @return YES on success, otherwise NO.
 *
 * @warning Data should be <= that length `-maximumDataLengthForType:` with OCTToxDataLengthTypeAvatar type.
 * @warning Avatar should be PNG representation of image
 */
- (BOOL)setAvatar:(NSData *)data;

/**
 * Generates a cryptographic hash of the given data.
 * This function may be used by clients for any purpose, but is provided primarily for
 * validating cached avatars. This use is highly recommended to avoid unnecessary avatar
 * updates.
 *
 * @param data Data to be hashed
 *
 * @return Hash generated from data.
 */
- (NSData *)hashData:(NSData *)data;

/**
 * Request avatar information from a friend.
 * Asks a friend to provide their avatar information (hash). The friend may or may not answer this request and,
 * if answered, the information will be provided through the delegate method `tox:friendAvatarHashUpdate:friendNumber:`.
 *
 * @param friendNumber Friend number to request avatar info.
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)requestAvatarHashWithFriendNumber:(int32_t)friendNumber;

/**
 * Request avatar data from a friend.
 * Ask a friend to send their avatar data. The friend may or may not answer this request and,
 * if answered, the data will be provided through the delegate method `tox:friendAvatarUpdate:hash:friendNumber:`.
 *
 * @param friendNumber Friend number to request avatar data.
 *
 * @return YES on success, otherwise NO.
 */
- (BOOL)requestAvatarDataWithFriendNumber:(int32_t)friendNumber;

#pragma mark -  Helper methods

/**
 * Checks length of string against maximum length  for specified type.
 *
 * @param string String to check.
 * @param type Type used to check string. Different types have different maximun length.
 *
 * @return YES, if string <= maximum length, NO otherwise.
 */
- (BOOL)checkLengthOfString:(NSString *)string withCheckType:(OCTToxCheckLengthType)type;

/**
 * Crops string to fit maximum length for specified type.
 *
 * @param string String to crop.
 * @param type Type used to check string. Different types have different maximun length.
 *
 * @return The new cropped string.
 */
- (NSString *)cropString:(NSString *)string toFitType:(OCTToxCheckLengthType)type;


/**
 * Maximum length of data for certain type.
 *
 * @param type Type of data.
 *
 * @return Maximum length of data.
 */

- (NSUInteger)maximumDataLengthForType:(OCTToxDataLengthType)type;

@end
