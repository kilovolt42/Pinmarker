//
//  PMAccountStore.m
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMAccountStore.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString+Pinmark.h"
#import "PMAppDelegate.h"
#import "Lockbox.h"

NSString * const PMAccountStoreDidAddUsernameNotification = @"PMAccountStoreDidAddUsernameNotification";
NSString * const PMAccountStoreDidUpdateUsernameNotification = @"PMAccountStoreDidUpdateUsernameNotification";
NSString * const PMAccountStoreDidRemoveUsernameNotification = @"PMAccountStoreDidRemoveUsernameNotification";

NSString * const PMAccountStoreUsernameKey = @"PMAccountStoreUsernameKey";
NSString * const PMAccountStoreOldUsernameKey = @"PMAccountStoreOldUsernameKey";

NSString * const PMAssociatedTokensKey = @"PMAssociatedTokensKey";
NSString * const PMDefaultUsernameKey = @"PMDefaultUsernameKey";

@interface PMAccountStore ()
@property (nonatomic) NSArray *associatedTokens;
@end

@implementation PMAccountStore

#pragma mark - Properties

@synthesize defaultUsername = _defaultUsername;

- (NSString *)defaultUsername {
	if (!_defaultUsername) {
		_defaultUsername = [self.associatedUsernames firstObject];
	}
	return _defaultUsername;
}

- (void)setDefaultUsername:(NSString *)defaultUsername {
	BOOL isAssociatedToken = [self.associatedUsernames containsObject:defaultUsername];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	if (isAssociatedToken) {
		_defaultUsername = defaultUsername;
		[userDefaults setObject:defaultUsername forKey:PMDefaultUsernameKey];
		[userDefaults synchronize];
	}
	
	else if (!defaultUsername) {
		_defaultUsername = nil;
		[userDefaults removeObjectForKey:PMDefaultUsernameKey];
		[userDefaults synchronize];
	}
}

- (NSArray *)associatedUsernames {
	NSMutableArray *usernames = [NSMutableArray new];
	for (NSString *token in self.associatedTokens) {
		[usernames addObject:[token tokenUsername]];
	}
	return [usernames copy];
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
		_associatedTokens = [Lockbox arrayForKey:PMAssociatedTokensKey];
		_defaultUsername = [[NSUserDefaults standardUserDefaults] valueForKey:PMDefaultUsernameKey];
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
	[self requestAPITokenForAPIToken:token
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 PMLog(@"Response Object: %@", responseObject);
								 [self associateToken:token asDefault:(BOOL)asDefault];
								 completionHandler(nil);
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 PMLog(@"Error: %@", error);
								 completionHandler(error);
							 }];
}

- (void)addAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler {
	[self requestAPITokenForUsername:username
							password:password
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 PMLog(@"Response Object: %@", responseObject);
								 [self associateToken:[NSString stringWithFormat:@"%@:%@", username, responseObject[@"result"]] asDefault:(BOOL)asDefault];
								 completionHandler(nil);
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 PMLog(@"Error: %@", error);
								 completionHandler(error);
							 }];
}

- (void)updateAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler {
	[self requestAPITokenForAPIToken:token
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 PMLog(@"Response Object: %@", responseObject);
								 [self updateToken:token asDefault:(BOOL)asDefault];
								 completionHandler(nil);
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 PMLog(@"Error: %@", error);
								 completionHandler(error);
							 }];
}

- (void)updateAccountForUsername:(NSString *)username password:(NSString *)password asDefault:(BOOL)asDefault completionHandler:(void (^)(NSError *))completionHandler {
	[self requestAPITokenForUsername:username
							password:password
							 success:^(AFHTTPRequestOperation *operation, id responseObject) {
								 PMLog(@"Response Object: %@", responseObject);
								 [self updateToken:[NSString stringWithFormat:@"%@:%@", username, responseObject[@"result"]] asDefault:(BOOL)asDefault];
								 completionHandler(nil);
							 }
							 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
								 PMLog(@"Error: %@", error);
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

- (void)requestAPITokenForAPIToken:(NSString *)token success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": token };
	
	[manager GET:[NSString stringWithFormat:@"https://api.pinboard.in/v1/user/api_token"]
	  parameters:parameters
		 success:success
		 failure:failure];
}

- (void)requestAPITokenForUsername:(NSString *)username password:(NSString *)password success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	username = [username urlEncodeUsingEncoding:NSUTF8StringEncoding];
	password = [password urlEncodeUsingEncoding:NSUTF8StringEncoding];
	
	[manager GET:[NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/user/api_token", username, password]
	  parameters:@{ @"format": @"json" }
		 success:success
		 failure:failure];
}

- (NSString *)tokenNumberForUsername:(NSString *)username {
	for (NSString *token in self.associatedTokens) {
		if ([[token tokenUsername] isEqualToString:username]) {
			return [token tokenNumber];
		}
	}
	return nil;
}

- (void)associateToken:(NSString *)token asDefault:(BOOL)asDefault {
	if (self.associatedTokens) {
		if (![self.associatedTokens containsObject:token]) {
			NSMutableArray *newTokens = [NSMutableArray arrayWithArray:self.associatedTokens];
			[newTokens addObject:token];
			self.associatedTokens = [newTokens copy];
			[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
		}
	} else {
		self.associatedTokens = @[token];
		[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
	}
	
	if (asDefault || !self.defaultUsername) {
		self.defaultUsername = [token tokenUsername];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:PMAccountStoreDidAddUsernameNotification
														object:self
													  userInfo:@{ PMAccountStoreUsernameKey : [token tokenUsername] }];
}

- (void)updateToken:(NSString *)token asDefault:(BOOL)asDefault {
	NSString *usernameToUpdate = [token tokenUsername];
	NSString *oldToken;
	NSUInteger oldTokenIndex;
	
	for (NSString *associatedToken in self.associatedTokens) {
		NSString *associatedUsername = [associatedToken tokenUsername];
		if ([associatedUsername isEqualToString:usernameToUpdate]) {
			oldToken = associatedToken;
			oldTokenIndex = [self.associatedTokens indexOfObject:oldToken];
			break;
		}
	}
	
	if (oldTokenIndex != NSNotFound) {
		NSMutableArray *newTokens = [NSMutableArray arrayWithArray:self.associatedTokens];
		[newTokens replaceObjectAtIndex:oldTokenIndex withObject:token];
		
		self.associatedTokens = [newTokens copy];
		[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
		
		if (asDefault || !self.defaultUsername) {
			self.defaultUsername = usernameToUpdate;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PMAccountStoreDidUpdateUsernameNotification
															object:self
														  userInfo:@{ PMAccountStoreUsernameKey : [token tokenUsername],
																	  PMAccountStoreOldUsernameKey : [oldToken tokenUsername] }];
	}
}

- (void)dissociateToken:(NSString *)token {
	if ([self.associatedTokens containsObject:token]) {
		NSMutableArray *newTokens = [NSMutableArray arrayWithArray:self.associatedTokens];
		[newTokens removeObject:token];
		
		if ([newTokens count]) {
			self.associatedTokens = [newTokens copy];
			[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
		} else {
			self.associatedTokens = nil;
			[Lockbox setArray:nil forKey:PMAssociatedTokensKey];
		}
		
		if ([[token tokenUsername] isEqualToString:self.defaultUsername]) {
			self.defaultUsername = [[self.associatedTokens firstObject] tokenUsername];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:PMAccountStoreDidRemoveUsernameNotification
															object:self
														  userInfo:@{ PMAccountStoreUsernameKey : [token tokenUsername] }];
	}
}

@end
