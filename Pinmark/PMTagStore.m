//
//  PMTagStore.m
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMTagStore.h"
#import <AFNetworking/AFNetworking.h>
#import "PMAccountStore.h"
#import "NSString+Pinmark.h"

@interface PMTagStore ()
@property (nonatomic) NSMutableDictionary *tags;
@property (nonatomic) NSMutableArray *tagsLoadingQueue;
@property (nonatomic) NSMutableDictionary *tagsCoherence;
@end

typedef NS_ENUM(NSUInteger, PMTagStoreCoherence) {
	PMTagStoreCoherenceValid,
	PMTagStoreCoherenceDirty
};

@implementation PMTagStore

#pragma mark - Properties

- (NSMutableDictionary *)tags {
	if (!_tags) _tags = [NSMutableDictionary new];
	return _tags;
}

- (NSMutableArray *)tagsLoadingQueue {
	if (!_tagsLoadingQueue) _tagsLoadingQueue = [NSMutableArray new];
	return _tagsLoadingQueue;
}

- (NSMutableDictionary *)tagCoherence {
	if (!_tagsCoherence) {
		_tagsCoherence = [NSMutableDictionary new];
		for (NSString *username in [self.tags allKeys]) {
			_tagsCoherence[username] = @(PMTagStoreCoherenceDirty);
		}
	}
	return _tagsCoherence;
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
		NSString *path = [self tagsArchivePath];
		_tags = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
		
		if (!_tags) {
			_tags = [NSMutableDictionary new];
		}
		
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(usernameAdded:) name:PMAccountStoreDidAddUsernameNotification object:nil];
		[center addObserver:self selector:@selector(usernameUpdated:) name:PMAccountStoreDidUpdateUsernameNotification object:nil];
		[center addObserver:self selector:@selector(usernameRemoved:) name:PMAccountStoreDidRemoveUsernameNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Methods

+ (instancetype)sharedStore {
	static PMTagStore *sharedStore = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedStore = [[PMTagStore alloc] initPrivate];
	});
	
	return sharedStore;
}

- (NSArray *)tagsForUsername:(NSString *)username {
	NSNumber *coherence = self.tagCoherence[username];
	
	if (!coherence || [coherence unsignedIntegerValue] == PMTagStoreCoherenceDirty) {
		[self loadTagsForUsername:username];
	}
	
	return self.tags[username];
}

- (void)markTagsDirtyForUsername:(NSString *)username {
	self.tagsCoherence[username] = @(PMTagStoreCoherenceDirty);
}

#pragma mark -

- (void)loadTagsForUsername:(NSString *)username {
	if (!username) return;
	if (![self.tagsLoadingQueue containsObject:username]) {
		[self.tagsLoadingQueue addObject:username];
		[self requestTagsWithUsername:username
							   success:^(NSDictionary *tags) {
								   if ([tags isKindOfClass:[NSDictionary class]]) {
									   self.tags[username] = [[[tags keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects];
									   [self.tagsLoadingQueue removeObject:username];
									   self.tagsCoherence[username] = @(PMTagStoreCoherenceValid);
									   [self saveTags];
								   }
							   }
							   failure:nil];
	}
}

- (void)requestTagsWithUsername:(NSString *)username success:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSString *authToken = [[PMAccountStore sharedStore] authTokenForUsername:username];
	NSDictionary *parameters = @{ @"format": @"json", @"auth_token": authToken };
	
	[manager GET:@"https://api.pinboard.in/v1/tags/get"
	  parameters:parameters
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 PMLog(@"Response Object: %@", responseObject);
			 if (successCallback) successCallback((NSDictionary *)responseObject);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 PMLog(@"Error: %@", error);
			 if (failureCallback) failureCallback(error);
		 }];
}

- (NSString *)tagsArchivePath {
	NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [documentDirectories firstObject];
	return [documentDirectory stringByAppendingPathComponent:@"tags.archive"];
}

- (BOOL)saveTags {
	// Filter out tags associated with a foreign API token from URL schemes
	NSMutableDictionary *tagsToSave = [NSMutableDictionary new];
	for (NSString *username in [PMAccountStore sharedStore].associatedUsernames) {
		NSArray *tagsForUsername = self.tags[username];
		tagsToSave[username] = tagsForUsername ? tagsForUsername : @[];
	}
	
	NSString *path = [self tagsArchivePath];
	return [NSKeyedArchiver archiveRootObject:tagsToSave toFile:path];
}

- (void)usernameAdded:(NSNotification *)notification {
	NSString *username = notification.userInfo[PMAccountStoreUsernameKey];
	[self loadTagsForUsername:username];
}

- (void)usernameUpdated:(NSNotification *)notification {
	NSString *oldUsername = notification.userInfo[PMAccountStoreOldUsernameKey];
	NSString *newUsername = notification.userInfo[PMAccountStoreUsernameKey];
	[self.tags removeObjectForKey:oldUsername];
	[self loadTagsForUsername:newUsername];
}

- (void)usernameRemoved:(NSNotification *)notification {
	NSString *username = notification.userInfo[PMAccountStoreUsernameKey];
	[self.tags removeObjectForKey:username];
	[self.tagCoherence removeObjectForKey:username];
	[self saveTags];
}

@end
