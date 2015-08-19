//
//  RLMObject+Utilities.h
//  RealmUtilities
//
//  Created by Adam Fish on 1/9/15.
//  Copyright (c) 2015 Roobiq. All rights reserved.
//

#import <Realm/Realm.h>
/**
 *  This utility category provides convenience methods to retrieve the primary key and original
 *  class name for an RLMObject.
 */
@interface RLMObject (Utilities)

/**
 *  Retrieve the primary key for a given RLMObject
 *
 *  @param object RLMObject with a primary key
 *
 *  @return Primary key value (NSInteger or NSString only)
 */
+ (id)primaryKeyValueForObject:(RLMObject *)object;

/**
 *  Retrieve the original class name for a generic RLMObject. Realm dynamically changes the class at
 *  run-time, whereas this method returns the programatic class name.
 *
 *  @warning This method returns the class name to be used programatically (such as with NSClassFromString()). Class names within Swift follow the pattern: "AppName.ClassName" whereas Obj-C it is simply "ClassName". See Apple docs for more info: http://apple.co/1HMPGjg
 *
 *  @param object A RLMObject
 *
 *  @return Original programatic class name
 */
+ (NSString *)classNameForObject:(RLMObject *)object;

/**
 *  Checks to see if this object exist in the passed in RLMRealm by doing a primary key look up.
 *
 *  @param realm RLMRealm to checked for existance of the current object
 *
 *  @return BOOL value for if an object with the same primary key exists in realm or not.
 */
- (BOOL)isContainedInRealm:(RLMRealm *)realm;

@end
