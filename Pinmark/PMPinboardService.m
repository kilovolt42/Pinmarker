//
//  PMPinboardService.m
//  Pinmarker
//
//  Created by Kyle Stevens on 9/24/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMPinboardService.h"
#import <AFNetworking.h>
#import "NSString+Pinmark.h"

@implementation PMPinboardService

+ (void)requestAPITokenForAPIToken:(NSString *)token success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": token };
	
	[[self manager] GET:[NSString stringWithFormat:@"https://api.pinboard.in/v1/user/api_token"]
			 parameters:parameters
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					PMLog(@"Response Object: %@", responseObject);
					if (success) {
						success(token);
					}
				}
				failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					PMLog(@"Error: %@", error);
					if (failure) {
						failure(error);
					}
				}];
}

+ (void)requestAPITokenForUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {
	username = [username urlEncodeUsingEncoding:NSUTF8StringEncoding];
	password = [password urlEncodeUsingEncoding:NSUTF8StringEncoding];
	
	[[self manager] GET:[NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/user/api_token", username, password]
			 parameters:@{ @"format": @"json" }
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					PMLog(@"Response Object: %@", responseObject);
					if (success) {
						NSDictionary *response = (NSDictionary *)responseObject;
						NSString *token = [username stringByAppendingFormat:@":%@", response[@"result"]];
						success(token);
					}
				}
				failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					PMLog(@"Error: %@", error);
					if (failure) {
						failure(error);
					}
				}];
}

+ (void)requestTagsForAPIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": token };
	
	[[self manager] GET:@"https://api.pinboard.in/v1/tags/get"
			 parameters:parameters
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					PMLog(@"Response Object: %@", responseObject);
					if (success) {
						success(responseObject);
					}
				}
				failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					PMLog(@"Error: %@", error);
					if (failure) {
						failure(error);
					}
				}];
}

+ (void)requestPostForURL:(NSString *)url APIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSDictionary *parameters = @{@"url": url, @"format": @"json", @"auth_token": token };
	
	[[self manager] GET:@"https://api.pinboard.in/v1/posts/get"
			 parameters:parameters
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					PMLog(@"Response Object: %@", responseObject);
					if (success) {
						success(responseObject);
					}
				}
				failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					PMLog(@"Error: %@", error);
					if (failure) {
						failure(error);
					}
				}];
}

+ (void)postBookmarkParameters:(NSDictionary *)parameters APIToken:(NSString *)token success:(void (^)(id))success failure:(void (^)(NSError *, id))failure {
	NSMutableDictionary *mutableParameters = [parameters mutableCopy];
	mutableParameters[@"format"] = @"json";
	mutableParameters[@"auth_token"] = token;
	
	[[self manager] GET:@"https://api.pinboard.in/v1/posts/add"
			 parameters:mutableParameters
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					PMLog(@"Response Object: %@", responseObject);
					if ([responseObject[@"result_code"] isEqualToString:@"done"]) {
						if (success) {
							success(responseObject);
						}
					} else {
						if (failure) {
							failure(nil, responseObject);
						}
					}
				}
				failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					PMLog(@"Error: %@", error);
					if (failure) {
						failure(error, nil);
					}
				}];
}

#pragma mark -

+ (AFHTTPRequestOperationManager *)manager {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	return manager;
}

@end
