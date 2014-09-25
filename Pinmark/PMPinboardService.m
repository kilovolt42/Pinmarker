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
					success(token);
				}
				failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					failure(error);
				}];
}

+ (void)requestAPITokenForUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure {
	username = [username urlEncodeUsingEncoding:NSUTF8StringEncoding];
	password = [password urlEncodeUsingEncoding:NSUTF8StringEncoding];
	
	[[self manager] GET:[NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/user/api_token", username, password]
			 parameters:@{ @"format": @"json" }
				success:^(AFHTTPRequestOperation *operation, id responseObject) {
					NSDictionary *response = (NSDictionary *)responseObject;
					NSString *token = [username stringByAppendingFormat:@":%@", response[@"result"]];
					success(token);
				}
				failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					failure(error);
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
