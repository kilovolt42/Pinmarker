//
//  PMAccountStore.h
//  Pinmark
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

/*
 * About defaultUser and defaultToken:
 *
 * Methods that access Pinboard's API never call defaultToken or defaultUser. An API token parameter
 * must always be provided either as a method argument or as a key-value pair in a parameter dictionary,
 * otherwise the API request (not the method!) will fail. These request methods are just conveniences;
 * relevent parameters must always be passed in.
 */

#import <Foundation/Foundation.h>

@interface PMAccountStore : NSObject

@property (nonatomic, copy) NSString *defaultToken;
@property (nonatomic, readonly) NSArray *associatedTokens;

+ (instancetype)sharedStore;

- (void)addAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)addAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;

- (void)removeAccountForUsername:(NSString *)username;

- (NSString *)tokenNumberForUsername:(NSString *)username;
- (NSString *)authTokenForUsername:(NSString *)username;

@end
