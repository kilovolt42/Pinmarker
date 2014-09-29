//
//  PMBookmarkStore.m
//  Pinmarker
//
//  Created by Kyle Stevens on 3/5/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMBookmarkStore.h"
#import "PMBookmark.h"
#import "PMAccountStore.h"
#import "NSString+Pinmark.h"

@interface PMBookmarkStore ()

@property (nonatomic) NSMutableArray *bookmarks;

@end

@implementation PMBookmarkStore

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
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddUsername:) name:PMAccountStoreDidAddUsernameNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveUsername:) name:PMAccountStoreDidRemoveUsernameNotification object:nil];
	}
	return self;
}

- (void)dealloc {
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
	
	[self.bookmarks insertObject:bookmark atIndex:0];
	[self saveBookmarks];
	
	return bookmark;
}

- (PMBookmark *)createBookmarkWithParameters:(NSDictionary *)parameters {
	PMBookmark *bookmark = [[PMBookmark alloc] initWithParameters:parameters];
	
	if (!bookmark.username || [bookmark.username isEqualToString:@""]) {
		bookmark.username = [PMAccountStore sharedStore].defaultUsername;
	}
	
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

@end
