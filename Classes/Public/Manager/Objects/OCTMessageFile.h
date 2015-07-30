//
//  OCTMessageFile.h
//  objcTox
//
//  Created by Dmytro Vorobiov on 15.04.15.
//  Copyright (c) 2015 dvor. All rights reserved.
//

#import "OCTObject.h"
#import "OCTToxConstants.h"
#import "OCTManagerConstants.h"

/**
 * Message that contains file, that has been send/received. Represents pending, canceled and loaded files.
 *
 * Please note that all properties of this object are readonly.
 * You can change some of them only with appropriate method in OCTSubmanagerObjects.
 */
@interface OCTMessageFile : OCTObject

/**
 * The current state of file. Only in case if it is OCTMessageFileTypeReady
 * the file can be shown to user.
 */
@property OCTMessageFileState fileState;

/**
 * Who is holding up this file transfer.
 * Can be .Self, .Other, .Both, or .Nobody,
 * but it's undefined until fileState is OCTMessageFileStatePaused.
 */
@property OCTPauseFlags pauseFlags;

/**
 * How the file should be displayed, if you so choose to support that.
 * Make sure to check fileType before using.
 */
@property OCTFileUsage fileUsage;

/**
 * Size of file in bytes.
 */
@property OCTToxFileSize fileSize;

/**
 * Tox core file number for internal use only.
 * Do not use or save this value.
 */
@property long fileNumber;

/**
 * Name of the file as specified by sender. Note that actual fileName in path
 * may differ from this fileName.
 */
@property NSString *fileName;

/**
 * Path of file on disk. If you need fileName to show to user please use
 * `fileName` property. filePath has it's own random fileName.
 * For incoming [sender != nil] files, this property is not available until
 * fileType is OCTMessageFileTypeReady.
 */
@property NSString *filePath;

/**
 * Uniform Type Identifier of file.
 * For incoming [sender != nil] files, this property is not available until
 * fileState is OCTMessageFileTypeReady.
 */
@property NSString *fileUTI;

/**
 * NSCoded data for this file's tag (file ID, in toxcore). objcTox uses this
 * internally for resumption purposes. Do not access or modify this property.
 */
@property NSData *fileTag;

/**
 * NSCoded data for this file's conduit. objcTox uses this internally for
 * resumption purposes. Do not access or modify this property.
 */
@property NSData *restorationTag;

/**
 * How many bytes we got up to. objcTox uses this internally for
 * resumption purposes. Do not access or modify this property.
 */
@property OCTToxFileSize filePosition;

@end

RLM_ARRAY_TYPE(OCTMessageFile)
