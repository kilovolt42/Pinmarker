//
//  PMPinboardService.h
//  Pinmarker
//
//  Created by Kyle Stevens on 9/24/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

@interface PMPinboardService : NSObject

+ (void)requestAPITokenForAPIToken:(NSString *)token success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure;
+ (void)requestAPITokenForUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure;
+ (void)requestTagsForAPIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
+ (void)requestPostForURL:(NSString *)url APIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
+ (void)postBookmarkParameters:(NSDictionary *)parameters APIToken:(NSString *)token success:(void (^)(id))success failure:(void (^)(NSError *, id))failure;

@end
