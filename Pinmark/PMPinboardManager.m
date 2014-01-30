//
//  PMPinboardManager.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMPinboardManager.h"

@interface PMPinboardManager ()
@property (strong, nonatomic) NSString *defaultToken;
@property (strong, nonatomic) NSArray *associatedTokens;
@property (strong, nonatomic, readwrite) NSArray *userTags;
@end

NSString * const PMAssociatedTokensKey = @"PMAssociatedTokensKey";
NSString * const PMDefaultTokenKey = @"PMDefaultTokenKey";

@implementation PMPinboardManager

#pragma mark - Properties

// subsequently sets associatedUsers
- (void)setAssociatedTokens:(NSArray *)associatedTokens {
	if (associatedTokens) {
		_associatedTokens = associatedTokens;
		NSMutableArray *associatedUsers = [NSMutableArray new];
		for (NSString *token in self.associatedTokens) {
			[associatedUsers addObject:[[token componentsSeparatedByString:@":"] firstObject]];
		}
		_associatedUsers = [associatedUsers copy];
	}
}

// subsequently sets defaultUser and userTags
- (void)setDefaultToken:(NSString *)defaultToken {
	if (defaultToken) {
		_defaultToken = defaultToken;
		_defaultUser = [[defaultToken componentsSeparatedByString:@":"] firstObject];
		__weak PMPinboardManager *weakSelf = self;
		[self requestTags:^(NSDictionary *tags) {
			weakSelf.userTags = [tags keysSortedByValueUsingComparator:^NSComparisonResult(id num1, id num2) {
				if ([num1 integerValue] > [num2 integerValue]) {
					return (NSComparisonResult)NSOrderedAscending;
				} else if ([num1 integerValue] < [num2 integerValue]) {
					return (NSComparisonResult)NSOrderedDescending;
				} else {
					return (NSComparisonResult)NSOrderedSame;
				}
			}];
		} failure:nil];
	}
}

// subsequently sets defaultToken
- (void)setDefaultUser:(NSString *)defaultUser {
	NSString *tokenNumber = [self tokenNumberForUser:defaultUser];
	if (tokenNumber) {
		_defaultToken = [NSString stringWithFormat:@"%@:%@", defaultUser, tokenNumber];
	}
}

#pragma mark - Initializers

- (id)init {
	if (self = [super init]) {
		self.associatedTokens = [[NSUserDefaults standardUserDefaults] valueForKey:PMAssociatedTokensKey];
		if (self.associatedTokens) {
			self.defaultToken = [[NSUserDefaults standardUserDefaults] valueForKey:PMDefaultTokenKey];
			if (!self.defaultToken) self.defaultToken = [_associatedTokens firstObject];
		}
	}
	return self;
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

- (void)addAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": token };
	
	[manager GET:[NSString stringWithFormat:@"https://api.pinboard.in/v1/user/api_token"]
	  parameters:parameters
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 [self associateToken:token asDefault:(BOOL)asDefault];
			 completionHandler(nil);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Error: %@", error);
			 completionHandler(error);
		 }];
}

- (void)addAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	[manager GET:[NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/user/api_token", username, password]
	  parameters:@{ @"format": @"json" }
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 [self associateToken:[NSString stringWithFormat:@"%@:%@", username, responseObject[@"result"]] asDefault:(BOOL)asDefault];
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
	if (!mutableParameters[@"auth_token"]) mutableParameters[@"auth_token"] = self.defaultToken;
	
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
	
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": self.defaultToken };
	
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
	if (!mutableParameters[@"auth_token"]) mutableParameters[@"auth_token"] = self.defaultToken;
	
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

- (void)requestPostForURL:(NSString *)url success:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{@"url": url, @"format": @"json", @"auth_token": self.defaultToken };
	
	[manager GET:@"https://api.pinboard.in/v1/posts/get"
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

- (NSString *)tokenNumberForUser:(NSString *)user {
	for (NSString *token in self.associatedTokens) {
		NSArray *tokenComponents = [token componentsSeparatedByString:@":"];
		if ([[tokenComponents firstObject] isEqualToString:user]) return [tokenComponents lastObject];
	}
	return nil;
}

#pragma mark -

- (void)associateToken:(NSString *)token asDefault:(BOOL)asDefault {
	if (self.associatedTokens) {
		if (![self.associatedTokens containsObject:token]) {
			NSMutableArray *newTokens = [NSMutableArray arrayWithArray:self.associatedTokens];
			[newTokens addObject:token];
			[[NSUserDefaults standardUserDefaults] setObject:newTokens forKey:PMAssociatedTokensKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
			self.associatedTokens = newTokens;
		}
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:@[token] forKey:PMAssociatedTokensKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
		self.associatedTokens = @[token];
	}
	
	if (asDefault || !self.defaultToken) {
		self.defaultToken = token;
		[[NSUserDefaults standardUserDefaults] setObject:token forKey:PMDefaultTokenKey];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

@end
