//
//  PMPinboardManager.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMPinboardManager.h"

NSString * const PMAssociatedTokensKey = @"PMAssociatedTokensKey";

@implementation PMPinboardManager

#pragma mark - Properties

@synthesize authToken = _authToken;
@synthesize username = _username;

- (NSString *)authToken {
	if (!_authToken) {
		id associatedTokens = [[NSUserDefaults standardUserDefaults] valueForKey:PMAssociatedTokensKey];
		if ([associatedTokens isKindOfClass:[NSArray class]]) {
			_authToken = [(NSArray *)associatedTokens firstObject];
		}
	}
	return _authToken;
}

- (NSString *)username {
	if (!_username) _username = [[self.authToken componentsSeparatedByString:@":"] firstObject];
	return _username;
}

#pragma mark - Methods

+ (NSDictionary *)pinboardSpecificParametersFromParameters:(NSDictionary *)parameters {
	NSMutableDictionary *pinboardParameters = [NSMutableDictionary new];
	for (NSString *key in @[@"url", @"description", @"extended", @"tags", @"dt", @"replace", @"shared", @"toread", @"auth_token"]) {
		if (parameters[key]) pinboardParameters[key] = parameters[key];
		else pinboardParameters[key] = @"";
	}
	return [pinboardParameters copy];
}

- (void)addAccountForAPIToken:(NSString *)token completionHandler:(void (^)(NSError *))completionHandler {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": token };
	
	[manager GET:[NSString stringWithFormat:@"https://api.pinboard.in/v1/user/api_token"]
	  parameters:parameters
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 [self associateToken:token];
			 completionHandler(nil);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Error: %@", error);
			 completionHandler(error);
		 }];
}

- (void)addAccountForUsername:(NSString *)username password:(NSString *)password completionHandler:(void (^)(NSError *))completionHandler {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	[manager GET:[NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/user/api_token", username, password]
	  parameters:@{ @"format": @"json" }
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 [self associateToken:[NSString stringWithFormat:@"%@:%@", username, responseObject[@"result"]]];
			 completionHandler(nil);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Error: %@", error);
			 completionHandler(error);
		 }];
}

- (void)add:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *, id))successCallback failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSMutableDictionary *mutableParameters = [parameters mutableCopy];
	[mutableParameters addEntriesFromDictionary:@{ @"format": @"json" }];
	if (!mutableParameters[@"auth_token"]) mutableParameters[@"auth_token"] = self.authToken;
	
	[manager GET:@"https://api.pinboard.in/v1/posts/add"
	  parameters:mutableParameters
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 if (successCallback) successCallback(operation, responseObject);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Error: %@", error);
			 if (failureCallback) failureCallback(operation, error);
		 }];
}

- (void)requestTags:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": self.authToken };
	
	[manager GET:@"https://api.pinboard.in/v1/tags/get"
	  parameters:parameters
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 if (successCallback) successCallback((NSDictionary *)responseObject);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Error: %@", error);
			 if (failureCallback) failureCallback(error);
		 }];
}

- (void)requestRecommendedTags:(NSDictionary *)parameters success:(void (^)(NSArray *))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSMutableDictionary *mutableParameters = [parameters mutableCopy];
	[mutableParameters addEntriesFromDictionary:@{ @"format": @"json" }];
	if (!mutableParameters[@"auth_token"]) mutableParameters[@"auth_token"] = self.authToken;
	
	[manager GET:@"https://api.pinboard.in/v1/posts/suggest"
	  parameters:mutableParameters
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 if (successCallback) successCallback(((NSArray *)responseObject)[1][@"recommended"]);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Error: %@", error);
			 if (failureCallback) failureCallback(error);
		 }];
}

#pragma mark -

- (void)associateToken:(NSString *)token {
	NSArray *tokens = [[NSUserDefaults standardUserDefaults] objectForKey:PMAssociatedTokensKey];
	if (tokens) {
		if (![tokens containsObject:token]) {
			NSMutableArray *newTokens = [NSMutableArray arrayWithArray:tokens];
			[newTokens addObject:token];
			[[NSUserDefaults standardUserDefaults] setObject:newTokens forKey:PMAssociatedTokensKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:@[token] forKey:PMAssociatedTokensKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end
