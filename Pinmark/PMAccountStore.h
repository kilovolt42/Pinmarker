//
//  PMAccountStore.h
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

/**
 * To add an account, use the -updateAccountForAPIToken:asDefault method.
 *
 * The store sends out notifications when tokens are added, updated, or removed. Each notification
 * sends the affected username in the userInfo dictionary with the key PMAccountStoreUsernameKey. For
 * example, the PMAccountStoreDidRemoveUsernameNotification passes along the deleted username with that
 * key.
 *
 * To be notified about changes to the default username, use KVO to observe the defaultUsername property.
 */

extern NSString * const PMAccountStoreDidAddUsernameNotification;
extern NSString * const PMAccountStoreDidUpdateUsernameNotification;
extern NSString * const PMAccountStoreDidRemoveUsernameNotification;
extern NSString * const PMAccountStoreUsernameKey;

@interface PMAccountStore : NSObject

@property (nonatomic, copy) NSString *defaultUsername;
@property (nonatomic, readonly) NSArray *associatedUsernames;

+ (instancetype)sharedStore;

/**
 * Adds or updates the given API token. This will update the default username if
 * asDefault is set to true, or if there is no default username.
 *
 * @param token The API token to add or update.
 * @param asDefault Sets the default username to the username of the provided API token.
 */
- (void)updateAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault;

/**
 * Removes the API token associated with the given username. If the username
 * corresponds to the default username, a new username is assigned.
 *
 * @param username The username of the API token to remove.
 */
- (void)removeAccountForUsername:(NSString *)username;

/**
 * Returns the full API token associated with the given username.
 *
 * @param username The username of the requested API token.
 *
 * @return An API token string, or nil if the username is unfamiliar.
 */
- (NSString *)authTokenForUsername:(NSString *)username;

@end
