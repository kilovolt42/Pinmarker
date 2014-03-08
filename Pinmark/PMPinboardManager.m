//
//  PMPinboardManager.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMPinboardManager.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString+Pinmark.h"
#import "PMAppDelegate.h"

@interface PMPinboardManager ()
@property (nonatomic, readwrite) NSArray *associatedTokens;
@end

@implementation PMPinboardManager

#pragma mark - Properties

@synthesize defaultToken = _defaultToken;

- (NSString *)defaultToken {
	if (!_defaultToken) {
		_defaultToken = [self.associatedTokens firstObject];
	}
	return _defaultToken;
}

- (void)setDefaultToken:(NSString *)defaultToken {
	BOOL isAssociatedToken = [self.associatedTokens containsObject:defaultToken];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if (isAssociatedToken) {
		_defaultToken = defaultToken;
		[userDefaults setObject:defaultToken forKey:PMDefaultTokenKey];
		[userDefaults synchronize];
	}
	
	else if (!defaultToken) {
		_defaultToken = nil;
		[userDefaults removeObjectForKey:PMDefaultTokenKey];
		[userDefaults synchronize];
	}
}

#pragma mark - Initializers

- (instancetype)init {
	@throw [NSException exceptionWithName:@"Singleton"
								   reason:@"Use +sharedManager"
								 userInfo:nil];
	return nil;
}

- (instancetype)initPrivate {
	self = [super init];
	if (self) {
		_associatedTokens = [[NSUserDefaults standardUserDefaults] valueForKey:PMAssociatedTokensKey];
		_defaultToken = [[NSUserDefaults standardUserDefaults] valueForKey:PMDefaultTokenKey];
	}
	return self;
}

#pragma mark - Methods

+ (instancetype)sharedManager {
	static PMPinboardManager *sharedManager = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self alloc] initPrivate];
	});
	
	return sharedManager;
}

+ (NSDictionary *)pinboardSpecificParametersFromParameters:(NSDictionary *)parameters {
	NSMutableDictionary *pinboardParameters = [NSMutableDictionary new];
	for (NSString *key in @[@"url", @"description", @"extended", @"tags", @"dt", @"replace", @"shared", @"toread", @"auth_token"]) {
		if (parameters[key]) pinboardParameters[key] = parameters[key];
		else pinboardParameters[key] = @"";
	}
	return [pinboardParameters copy];
}

#pragma mark Manage Users

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
	
	username = [username urlEncodeUsingEncoding:NSUTF8StringEncoding];
	password = [password urlEncodeUsingEncoding:NSUTF8StringEncoding];
	
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

- (void)removeAccountForUsername:(NSString *)username {
	NSString *token = [username stringByAppendingFormat:@":%@", [self tokenNumberForUsername:username]];
	[self dissociateToken:token];
}

- (NSString *)tokenNumberForUsername:(NSString *)username {
	for (NSString *token in self.associatedTokens) {
		NSArray *tokenComponents = [token componentsSeparatedByString:@":"];
		if ([[tokenComponents firstObject] isEqualToString:username]) return [tokenComponents lastObject];
	}
	return nil;
}

- (NSString *)authTokenForUsername:(NSString *)username {
	return [username stringByAppendingFormat:@":%@", [self tokenNumberForUsername:username]];
}

#pragma mark Post

- (void)add:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *, id))successCallback failure:(void (^)(AFHTTPRequestOperation *, NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSMutableDictionary *mutableParameters = [parameters mutableCopy];
	mutableParameters[@"format"] = @"json";
	
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

#pragma mark Request

- (void)requestTagsWithAuthToken:(NSString *)authToken success:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": authToken };
	
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
	mutableParameters[@"format"] = @"json";
	
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

- (void)requestPostForURL:(NSString *)url withAuthToken:(NSString *)authToken success:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{@"url": url, @"format": @"json", @"auth_token": authToken };
	
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

#pragma mark -

- (void)associateToken:(NSString *)token asDefault:(BOOL)asDefault {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if (self.associatedTokens) {
		if (![self.associatedTokens containsObject:token]) {
			NSMutableArray *newTokens = [NSMutableArray arrayWithArray:self.associatedTokens];
			[newTokens addObject:token];
			self.associatedTokens = [newTokens copy];
			[userDefaults setObject:newTokens forKey:PMAssociatedTokensKey];
			[userDefaults synchronize];
		}
	} else {
		self.associatedTokens = @[token];
		[userDefaults setObject:@[token] forKey:PMAssociatedTokensKey];
		[userDefaults synchronize];
	}
	
	if (asDefault || !self.defaultToken) {
		self.defaultToken = token;
	}
}

- (void)dissociateToken:(NSString *)token {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableArray *newTokens = [NSMutableArray arrayWithArray:self.associatedTokens];
	[newTokens removeObject:token];
	
	if ([newTokens count]) {
		self.associatedTokens = [newTokens copy];
		[userDefaults setObject:newTokens forKey:PMAssociatedTokensKey];
		[userDefaults synchronize];
	} else {
		self.associatedTokens = nil;
		[userDefaults removeObjectForKey:PMAssociatedTokensKey];
		[userDefaults synchronize];
	}
	
	if ([token isEqualToString:self.defaultToken]) {
		self.defaultToken = [self.associatedTokens firstObject];
	}
}

@end
