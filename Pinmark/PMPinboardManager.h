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

@property (strong, nonatomic, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *username;

+ (NSDictionary *)pinboardSpecificParametersFromParameters:(NSDictionary *)parameters;
- (void)addAccountForAPIToken:(NSString *)token completionHandler:(void (^)(NSError *))completionHandler;
- (void)addAccountForUsername:(NSString *)username password:(NSString *)password completionHandler:(void (^)(NSError *))completionHandler;
- (void)add:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCallback failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureCallback;
- (void)requestTags:(void(^)(NSDictionary *))successCallback failure:(void(^)(NSError *))failureCallback;
- (void)requestRecommendedTags:(NSDictionary *)parameters success:(void (^)(NSArray *))successCallback failure:(void (^)(NSError *))failureCallback;

@end
