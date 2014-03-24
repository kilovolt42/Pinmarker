//
//  PMTagStore.m
//  Pinmark
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMTagStore.h"
#import <AFNetworking/AFNetworking.h>
#import "PMAccountStore.h"

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
		for (NSString *token in [self.tags allKeys]) {
			_tagsCoherence[token] = @(PMTagStoreCoherenceDirty);
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
		[center addObserver:self selector:@selector(tokenAdded:) name:PMAccountStoreDidAddTokenNotification object:nil];
		[center addObserver:self selector:@selector(tokenUpdated:) name:PMAccountStoreDidUpdateTokenNotification object:nil];
		[center addObserver:self selector:@selector(tokenRemoved:) name:PMAccountStoreDidRemoveTokenNotification object:nil];
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

- (NSArray *)tagsForAuthToken:(NSString *)authToken {
	NSNumber *coherence = self.tagCoherence[authToken];
	
	if (!coherence || [coherence unsignedIntegerValue] == PMTagStoreCoherenceDirty) {
		[self loadTagsForAuthToken:authToken];
	}
	
	return self.tags[authToken];
}

- (void)markTagsDirtyForAuthToken:(NSString *)authToken {
	self.tagsCoherence[authToken] = @(PMTagStoreCoherenceDirty);
}

#pragma mark -

- (void)loadTagsForAuthToken:(NSString *)authToken {
	if (!authToken) return;
	if (![self.tagsLoadingQueue containsObject:authToken]) {
		[self.tagsLoadingQueue addObject:authToken];
		[self requestTagsWithAuthToken:authToken
							   success:^(NSDictionary *tags) {
								   self.tags[authToken] = [[[tags keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects];
								   [self.tagsLoadingQueue removeObject:authToken];
								   self.tagsCoherence[authToken] = @(PMTagStoreCoherenceValid);
								   [self saveTags];
							   }
							   failure:nil];
	}
}

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

- (NSString *)tagsArchivePath {
	NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [documentDirectories firstObject];
	return [documentDirectory stringByAppendingPathComponent:@"tags.archive"];
}

- (BOOL)saveTags {
	// Filter out tags associated with a foreign API token from URL schemes
	NSMutableDictionary *tagsToSave = [NSMutableDictionary new];
	for (NSString *token in [PMAccountStore sharedStore].associatedTokens) {
		tagsToSave[token] = self.tags[token];
	}
	
	NSString *path = [self tagsArchivePath];
	return [NSKeyedArchiver archiveRootObject:tagsToSave toFile:path];
}

- (void)tokenAdded:(NSNotification *)notificaiton {
	NSString *token = notificaiton.userInfo[PMAccountStoreTokenKey];
	[self loadTagsForAuthToken:token];
}

- (void)tokenUpdated:(NSNotification *)notificaiton {
	NSString *oldToken = notificaiton.userInfo[PMAccountStoreOldTokenKey];
	NSString *newToken = notificaiton.userInfo[PMAccountStoreTokenKey];
	[self.tags removeObjectForKey:oldToken];
	[self loadTagsForAuthToken:newToken];
}

- (void)tokenRemoved:(NSNotification *)notificaiton {
	NSString *token = notificaiton.userInfo[PMAccountStoreTokenKey];
	[self.tags removeObjectForKey:token];
	[self.tagCoherence removeObjectForKey:token];
	[self saveTags];
}

@end
