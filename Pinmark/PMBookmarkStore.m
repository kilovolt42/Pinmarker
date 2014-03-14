//
//  PMBookmarkStore.m
//  Pinmark
//
//  Created by Kyle Stevens on 3/5/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMBookmarkStore.h"
#import <AFNetworking/AFNetworking.h>
#import "PMBookmark.h"
#import "PMAccountStore.h"
#import "NSString+Pinmark.h"

@interface PMBookmarkStore ()
@property (nonatomic) NSMutableArray *bookmarks;
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

static void * PMBookmarkStoreContext = &PMBookmarkStoreContext;

@implementation PMBookmarkStore

#pragma mark - Properties

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	}
	return _dateFormatter;
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
		
	}
	return self;
}

- (void)dealloc {
	for (PMBookmark *bookmark in self.bookmarks) {
		[bookmark removeObserver:self forKeyPath:@"url" context:&PMBookmarkStoreContext];
	}
}

#pragma mark - Methods

+ (instancetype)sharedStore {
	static PMBookmarkStore *sharedStore = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedStore = [[PMBookmarkStore alloc] initPrivate];
	});
	
	return sharedStore;
}

- (PMBookmark *)createBookmark {
	PMBookmark *bookmark = [PMBookmark new];
	bookmark.authToken = [PMAccountStore sharedStore].defaultToken;
	
	[self.bookmarks addObject:bookmark];
	[bookmark addObserver:self forKeyPath:@"url" options:NSKeyValueObservingOptionInitial context:&PMBookmarkStoreContext];
	
	return bookmark;
}

- (PMBookmark *)createBookmarkWithParameters:(NSDictionary *)parameters {
	PMBookmark *bookmark = [[PMBookmark alloc] initWithParameters:parameters];
	
	if (!bookmark.authToken || [bookmark.authToken isEqualToString:@""]) {
		bookmark.authToken = [PMAccountStore sharedStore].defaultToken;
	}
	
	[self.bookmarks addObject:bookmark];
	[bookmark addObserver:self forKeyPath:@"url" options:NSKeyValueObservingOptionInitial context:&PMBookmarkStoreContext];
	
	return bookmark;
}

- (void)postBookmark:(PMBookmark *)bookmark success:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSMutableDictionary *mutableParameters = [[bookmark parameters] mutableCopy];
	mutableParameters[@"format"] = @"json";
	
	[manager GET:@"https://api.pinboard.in/v1/posts/add"
	  parameters:mutableParameters
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 NSLog(@"Response Object: %@", responseObject);
			 [bookmark removeObserver:self forKeyPath:@"url" context:&PMBookmarkStoreContext];
			 [self.bookmarks removeObject:bookmark];
			 if (successCallback) successCallback(responseObject);
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 NSLog(@"Error: %@", error);
			 if (failureCallback) failureCallback(error);
		 }];
}

#pragma mark -

- (void)requestPostForBookmark:(PMBookmark *)bookmark success:(void (^)(NSDictionary *))successCallback failure:(void (^)(NSError *))failureCallback {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	
	NSDictionary *parameters = @{@"url": bookmark.url, @"format": @"json", @"auth_token": bookmark.authToken };
	
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

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PMBookmarkStoreContext) {
		if ([keyPath isEqualToString:@"url"]) {
			PMBookmark *bookmark = (PMBookmark *)object;
			if (bookmark.url && [bookmark.url isPinboardPermittedURL]) {
				[self requestPostForBookmark:bookmark
									 success:^(NSDictionary *responseDictionary) {
										 NSArray *posts = responseDictionary[@"posts"];
										 if ([posts count]) {
											 NSString *dateString = responseDictionary[@"date"];
											 NSDate *date = [self.dateFormatter dateFromString:dateString];
											 bookmark.lastPosted = date;
										 } else {
											 bookmark.lastPosted = nil;
										 }
									 }
									 failure:^(NSError *error) {
										 bookmark.lastPosted = nil;
									 }];
			} else {
				bookmark.lastPosted = nil;
			}
		}
	}
}

@end
