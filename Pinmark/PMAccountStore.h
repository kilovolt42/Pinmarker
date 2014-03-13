//
//  PMAccountStore.h
//  Pinmark
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

/**
 * Methods that access Pinboard's API never call defaultToken or defaultUser. An API token parameter
 * must always be provided either as a method argument or as a key-value pair in a parameter dictionary,
 * otherwise the API request (not the method!) will fail. These request methods are just conveniences;
 * relevent parameters must always be passed in.
 *
 * The store sends out notifications when tokens are added, updated, or removed. Each notification
 * sends the significant token in the userInfo dictionary with the key PMAccountStoreTokenKey. For
 * example, the PMAccountStoreDidRemoveTokenNotification passes along the deleted token with that
 * key. The PMAccountStoreOldTokenKey is only used with PMAccountStoreDidUpdateTokenNotification to
 * pass along the token being replaced.
 *
 * To be notified about changes to the default token, use KVO to observe the defaultToken property.
 */

#import <Foundation/Foundation.h>

extern NSString * const PMAccountStoreDidAddTokenNotification;
extern NSString * const PMAccountStoreDidUpdateTokenNotification;
extern NSString * const PMAccountStoreDidRemoveTokenNotification;

extern NSString * const PMAccountStoreTokenKey;
extern NSString * const PMAccountStoreOldTokenKey;

@interface PMAccountStore : NSObject

@property (nonatomic, copy) NSString *defaultToken;
@property (nonatomic, readonly) NSArray *associatedTokens;

+ (instancetype)sharedStore;

- (void)addAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)addAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;

- (void)updateAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)updateAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;

- (void)removeAccountForUsername:(NSString *)username;

- (NSString *)authTokenForUsername:(NSString *)username;

@end
