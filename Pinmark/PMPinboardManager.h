//
//  PMPinboardManager.h
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
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

@class AFHTTPRequestOperation;

@interface PMPinboardManager : NSObject

@property (nonatomic, copy) NSString *defaultToken;
@property (nonatomic, readonly) NSArray *associatedTokens;

+ (instancetype)sharedManager;
+ (NSDictionary *)pinboardSpecificParametersFromParameters:(NSDictionary *)parameters;

#pragma mark - Manage Users

- (void)addAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)addAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)removeAccountForUsername:(NSString *)username;
- (NSString *)tokenNumberForUsername:(NSString *)username;
- (NSString *)authTokenForUsername:(NSString *)username;

#pragma mark - Post

- (void)add:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *, id))successCallback failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureCallback;

#pragma mark - Request

- (void)requestTagsWithAuthToken:(NSString *)authToken success:(void(^)(NSDictionary *))successCallback failure:(void(^)(NSError *))failureCallback;
- (void)requestRecommendedTags:(NSDictionary *)parameters success:(void (^)(NSArray *))successCallback failure:(void (^)(NSError *))failureCallback;
- (void)requestPostForURL:(NSString *)url withAuthToken:(NSString *)authToken success:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback;

@end
