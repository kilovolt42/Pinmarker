//
//  PMBookmarkStore.m
//  Pinmarker
//
//  Created by Kyle Stevens on 3/5/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMBookmarkStore.h"
#import "PMPinboardService.h"
#import "PMBookmark.h"
#import "PMAccountStore.h"
#import "NSString+Pinmark.h"

static void * PMBookmarkStoreContext = &PMBookmarkStoreContext;

@interface PMBookmarkStore ()

@property (nonatomic) NSMutableArray *bookmarks;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end

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
		NSString *path = [self bookmarksArchivePath];
		_bookmarks = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
		
		if (!_bookmarks) {
			_bookmarks = [NSMutableArray new];
		} else {
			for (PMBookmark *bookmark in self.bookmarks) {
				[bookmark addObserver:self forKeyPath:@"url" options:NSKeyValueObservingOptionInitial context:&PMBookmarkStoreContext];
			}
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddUsername:) name:PMAccountStoreDidAddUsernameNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveUsername:) name:PMAccountStoreDidRemoveUsernameNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	for (PMBookmark *bookmark in self.bookmarks) {
		[bookmark removeObserver:self forKeyPath:@"url" context:&PMBookmarkStoreContext];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	bookmark.username = [PMAccountStore sharedStore].defaultUsername;
	[bookmark addObserver:self forKeyPath:@"url" options:NSKeyValueObservingOptionInitial context:&PMBookmarkStoreContext];
	
	[self.bookmarks insertObject:bookmark atIndex:0];
	[self saveBookmarks];
	
	return bookmark;
}

- (PMBookmark *)createBookmarkWithParameters:(NSDictionary *)parameters {
	PMBookmark *bookmark = [[PMBookmark alloc] initWithParameters:parameters];
	
	if (!bookmark.username || [bookmark.username isEqualToString:@""]) {
		bookmark.username = [PMAccountStore sharedStore].defaultUsername;
	}
	
	[bookmark addObserver:self forKeyPath:@"url" options:NSKeyValueObservingOptionInitial context:&PMBookmarkStoreContext];
	
	[self.bookmarks insertObject:bookmark atIndex:0];
	[self saveBookmarks];
	
	return bookmark;
}

- (PMBookmark *)lastBookmark {
	PMBookmark *bookmark = [self.bookmarks lastObject];
	if (!bookmark) {
		bookmark = [self createBookmark];
	}
	return bookmark;
}

- (void)discardBookmark:(PMBookmark *)bookmark {
	[bookmark removeObserver:self forKeyPath:@"url"];
	[self.bookmarks removeObject:bookmark];
	[self saveBookmarks];
}

#pragma mark -

- (NSString *)bookmarksArchivePath {
	NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentDirectory = [documentDirectories firstObject];
	return [documentDirectory stringByAppendingPathComponent:@"bookmarks.archive"];
}

- (BOOL)saveBookmarks {
	NSString *path = [self bookmarksArchivePath];
	return [NSKeyedArchiver archiveRootObject:self.bookmarks toFile:path];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
	[self saveBookmarks];
}

- (void)didAddUsername:(NSNotification *)notification {
	NSString *newUsername = notification.userInfo[PMAccountStoreUsernameKey];
	for (PMBookmark *bookmark in self.bookmarks) {
		if (!bookmark.username || [bookmark.username isEqualToString:@""]) {
			bookmark.username = newUsername;
		}
	}
}

- (void)didRemoveUsername:(NSNotification *)notification {
	NSString *usernameRemoved = notification.userInfo[PMAccountStoreUsernameKey];
	for (PMBookmark *bookmark in self.bookmarks) {
		if ([bookmark.username isEqualToString:usernameRemoved]) {
			NSString *defaultUsername = [PMAccountStore sharedStore].defaultUsername;
			if (defaultUsername) {
				bookmark.username = defaultUsername;
			} else {
				bookmark.username = @"";
			}
		}
	}
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PMBookmarkStoreContext) {
		if ([keyPath isEqualToString:@"url"]) {
			PMBookmark *bookmark = (PMBookmark *)object;
			if (bookmark.url && [bookmark.url isPinboardPermittedURL]) {
				NSString *token = [[PMAccountStore sharedStore] authTokenForUsername:bookmark.username];
				if (token) {
					void (^success)(NSDictionary *) = ^(NSDictionary *responseDictionary) {
						NSArray *posts = responseDictionary[@"posts"];
						if ([posts count]) {
							NSString *dateString = responseDictionary[@"date"];
							NSDate *date = [self.dateFormatter dateFromString:dateString];
							bookmark.lastPosted = date;
						} else {
							bookmark.lastPosted = nil;
						}
					};
					
					void (^failure)(NSError *) = ^(NSError *error) {
						bookmark.lastPosted = nil;
					};
					
					[PMPinboardService requestPostForURL:bookmark.url APIToken:token success:success failure:failure];
				}
			} else {
				bookmark.lastPosted = nil;
			}
		}
	}
}

@end
