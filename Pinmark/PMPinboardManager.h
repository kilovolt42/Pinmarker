//
//  PMPinboardManager.h
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface PMPinboardManager : NSObject

@property (nonatomic, copy) NSString *defaultUser; // setter does nothing if new value is not in allUsers
@property (nonatomic, readonly) NSArray *associatedUsers;
@property (nonatomic, readonly) NSArray *userTags;

+ (NSDictionary *)pinboardSpecificParametersFromParameters:(NSDictionary *)parameters;
- (void)addAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)addAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler;
- (void)removeAccountForUsername:(NSString *)username;
- (void)add:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCallback failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureCallback;
- (void)requestTags:(void(^)(NSDictionary *))successCallback failure:(void(^)(NSError *))failureCallback;
- (void)requestRecommendedTags:(NSDictionary *)parameters success:(void (^)(NSArray *))successCallback failure:(void (^)(NSError *))failureCallback;
- (void)requestPostForURL:(NSString *)url success:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback;
- (NSString *)tokenNumberForUser:(NSString *)user;

@end
