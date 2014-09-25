//
//  PMAccountStore.m
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMAccountStore.h"
#import "NSString+Pinmark.h"
#import "Lockbox.h"

NSString * const PMAccountStoreDidAddUsernameNotification = @"PMAccountStoreDidAddUsernameNotification";
NSString * const PMAccountStoreDidUpdateUsernameNotification = @"PMAccountStoreDidUpdateUsernameNotification";
NSString * const PMAccountStoreDidRemoveUsernameNotification = @"PMAccountStoreDidRemoveUsernameNotification";
NSString * const PMAccountStoreUsernameKey = @"PMAccountStoreUsernameKey";

NSString * const PMAssociatedTokensKey = @"PMAssociatedTokensKey";
NSString * const PMDefaultUsernameKey = @"PMDefaultUsernameKey";

@interface PMAccountStore ()

@property (nonatomic) NSArray *associatedTokens;

@end

@implementation PMAccountStore

#pragma mark - Properties

- (void)setDefaultUsername:(NSString *)defaultUsername {
	if ([self.associatedUsernames containsObject:defaultUsername]) {
		_defaultUsername = defaultUsername;
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:defaultUsername forKey:PMDefaultUsernameKey];
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

- (void)updateAccountForAPIToken:(NSString *)token asDefault:(BOOL)asDefault {
	if (self.associatedTokens) {
		if ([self.associatedUsernames containsObject:[token tokenUsername]]) { // replace existing token
			NSUInteger tokenIndex = [self.associatedUsernames indexOfObject:[token tokenUsername]];
			
			NSMutableArray *mutableTokens = [self.associatedTokens mutableCopy];
			[mutableTokens replaceObjectAtIndex:tokenIndex withObject:token];
			self.associatedTokens = [mutableTokens copy];
			
			[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
			[self postDidUpdateNotificationWithUsername:[token tokenUsername]];
		} else { // add to existing tokens
			self.associatedTokens = [self.associatedTokens arrayByAddingObject:token];
			[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
			[self postDidAddNotificationWithUsername:[token tokenUsername]];
		}
	} else { // add as only token
		self.associatedTokens = @[token];
		[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
		[self postDidAddNotificationWithUsername:[token tokenUsername]];
	}
	
	if (asDefault || !self.defaultUsername) {
		self.defaultUsername = [token tokenUsername];
	}
}

- (void)removeAccountForUsername:(NSString *)username {
	NSString *token = [self authTokenForUsername:username];
	
	if (token && [self.associatedTokens containsObject:token]) {
		NSMutableArray *mutableTokens = [NSMutableArray arrayWithArray:self.associatedTokens];
		[mutableTokens removeObject:token];
		
		if ([mutableTokens count]) {
			self.associatedTokens = [mutableTokens copy];
			[Lockbox setArray:self.associatedTokens forKey:PMAssociatedTokensKey];
		} else {
			self.associatedTokens = nil;
			[Lockbox setArray:nil forKey:PMAssociatedTokensKey];
		}
		
		if ([self.defaultUsername isEqualToString:username]) {
			self.defaultUsername = [[self.associatedTokens firstObject] tokenUsername];
		}
		
		[self postDidRemoveNotificationWithUsername:[token tokenUsername]];
	}
}

- (NSString *)authTokenForUsername:(NSString *)username {
	for (NSString *token in self.associatedTokens) {
		if ([[token tokenUsername] isEqualToString:username]) {
			return token;
		}
	}
	return nil;
}

#pragma mark -

- (void)postDidAddNotificationWithUsername:(NSString *)username {
	[[NSNotificationCenter defaultCenter] postNotificationName:PMAccountStoreDidAddUsernameNotification
														object:self
													  userInfo:@{ PMAccountStoreUsernameKey : username }];
}

- (void)postDidUpdateNotificationWithUsername:(NSString *)username {
	[[NSNotificationCenter defaultCenter] postNotificationName:PMAccountStoreDidUpdateUsernameNotification
														object:self
													  userInfo:@{ PMAccountStoreUsernameKey : username }];
}

- (void)postDidRemoveNotificationWithUsername:(NSString *)username {
	[[NSNotificationCenter defaultCenter] postNotificationName:PMAccountStoreDidRemoveUsernameNotification
														object:self
													  userInfo:@{ PMAccountStoreUsernameKey : username }];
}

@end
