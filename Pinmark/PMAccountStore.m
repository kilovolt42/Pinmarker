//
//  PMAccountStore.m
//  Pinmark
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMAccountStore.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString+Pinmark.h"
#import "PMAppDelegate.h"

@interface PMAccountStore ()
@property (nonatomic, readwrite) NSArray *associatedTokens;
@end

@implementation PMAccountStore

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
								   reason:@"Use +sharedStore"
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

+ (instancetype)sharedStore {
	static PMAccountStore *sharedStore = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedStore = [[PMAccountStore alloc] initPrivate];
	});
	
	return sharedStore;
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

- (NSString *)authTokenForUsername:(NSString *)username {
	return [username stringByAppendingFormat:@":%@", [self tokenNumberForUsername:username]];
}

#pragma mark -

- (NSString *)tokenNumberForUsername:(NSString *)username {
	for (NSString *token in self.associatedTokens) {
		NSArray *tokenComponents = [token componentsSeparatedByString:@":"];
		if ([[tokenComponents firstObject] isEqualToString:username]) return [tokenComponents lastObject];
	}
	return nil;
}

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
