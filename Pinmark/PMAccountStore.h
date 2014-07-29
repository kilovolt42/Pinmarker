//
//  PMAccountStore.h
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

/**
 * Methods of this class that access Pinboard's API never use defaultUser. An API token parameter
 * must always be provided either as a method argument or as a key-value pair in a parameter dictionary,
 * otherwise the API request (not the method!) will fail. These request methods are just conveniences;
 * relevent parameters must always be passed in.
 *
 * The store sends out notifications when tokens are added, updated, or removed. Each notification
 * sends the affected username in the userInfo dictionary with the key PMAccountStoreUsernameKey. For
 * example, the PMAccountStoreDidRemoveUsernameNotification passes along the deleted username with that
 * key. The PMAccountStoreOldUsernameKey is only used with PMAccountStoreDidUpdateUsernameNotification to
 * pass along the username being replaced.
 *
 * To be notified about changes to the default username, use KVO to observe the defaultUsername property.
 */

extern NSString * const PMAccountStoreDidAddUsernameNotification;
extern NSString * const PMAccountStoreDidUpdateUsernameNotification;
extern NSString * const PMAccountStoreDidRemoveUsernameNotification;

extern NSString * const PMAccountStoreUsernameKey;
extern NSString * const PMAccountStoreOldUsernameKey;

@interface PMAccountStore : NSObject

@property (nonatomic, copy) NSString *defaultUsername;
@property (nonatomic, readonly) NSArray *associatedUsernames;

+ (instancetype)sharedStore;

- (void)addAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)addAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;

- (void)updateAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)updateAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;

- (void)removeAccountForUsername:(NSString *)username;

- (NSString *)authTokenForUsername:(NSString *)username;

@end
