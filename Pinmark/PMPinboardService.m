//
//  PMPinboardService.m
//  Pinmarker
//
//  Created by Kyle Stevens on 9/24/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMPinboardService.h"
#import <AFNetworking.h>

static NSDictionary *PMPinboardAPIMethods;

@implementation PMPinboardService

+ (void)requestAPITokenForAPIToken:(NSString *)token success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodTokenAuth];
	NSDictionary *parameters = @{ PMPinboardAPIFormatKey: @"json",
								  PMPinboardAPIAuthTokenKey: token };
	
	[[self manager] GET:method
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
	NSString *methodFormat = PMPinboardAPIMethods[PMPinboardAPIMethodBasicAuth];
	username = [username urlEncodeUsingEncoding:NSUTF8StringEncoding];
	password = [password urlEncodeUsingEncoding:NSUTF8StringEncoding];
	
	NSString *method = [NSString stringWithFormat:methodFormat, username, password];
	NSDictionary *parameters = @{ PMPinboardAPIFormatKey: @"json" };
	
	[[self manager] GET:method
			 parameters:parameters
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					PMLog(@"Response Object: %@", responseObject);
					if (success) {
						NSDictionary *response = (NSDictionary *)responseObject;
						NSString *token = [username stringByAppendingFormat:@":%@", response[PMPinboardAPIResultKey]];
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
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodGetTags];
	NSDictionary *parameters = @{ PMPinboardAPIFormatKey: @"json",
								  PMPinboardAPIAuthTokenKey: token };
	
	[[self manager] GET:method
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
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodGetPosts];
	NSDictionary *parameters = @{PMPinboardAPIURLKey: url,
								 PMPinboardAPIFormatKey: @"json",
								 PMPinboardAPIAuthTokenKey: token };
	
	[[self manager] GET:method
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
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodAddPost];
	NSMutableDictionary *mutableParameters = [parameters mutableCopy];
	mutableParameters[PMPinboardAPIFormatKey] = @"json";
	mutableParameters[PMPinboardAPIAuthTokenKey] = token;
	
	[[self manager] GET:method
			 parameters:mutableParameters
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					PMLog(@"Response Object: %@", responseObject);
					if ([responseObject[PMPinboardAPIResultCodeKey] isEqualToString:@"done"]) {
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

+ (void)initialize {
	NSString *path = [[NSBundle mainBundle] pathForResource:PMPinboardAPIPlistFilename ofType:@"plist"];
	PMPinboardAPIMethods = [NSDictionary dictionaryWithContentsOfFile:path];
}

+ (AFHTTPRequestOperationManager *)manager {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	return manager;
}

@end
