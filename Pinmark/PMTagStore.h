//
//  PMTagStore.h
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

extern NSString * const PMTagStoreDidUpdateUserTagsNotification;
extern NSString * const PMTagStoreUsernameKey;

/**
 * Use this class to store tags to disk and retrieve them again. Tags
 * are accessed via their associated username - usernames are
 * effectively keys to arrays of tags.
 */
@interface PMTagStore : NSObject

+ (instancetype)sharedStore;

/**
 * Retrieve an array of tags for a particular username.
 *
 * @param The username for which to retrieve tags. 
 *
 * @return The tags associated with the given username.
 */
- (NSArray *)tagsForUsername:(NSString *)username;

/**
 * Add or update tags for a particular username.
 *
 * @param tags An array of tags.
 * @param username The username corresponding to the tags.
 */
- (void)updateTags:(NSArray *)tags username:(NSString *)username;

@end
