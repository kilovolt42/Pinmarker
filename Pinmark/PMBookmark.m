//
//  PMBookmark.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMBookmark.h"
#import "NSString+Pinmark.h"
#import "PMAccountStore.h"

@interface PMBookmark ()
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation PMBookmark

#pragma mark - Properties

- (BOOL)isPostable {
	if ([self.url isPinboardPermittedURL] && [self.title length] && [self.authToken length]) {
		return YES;
	} else {
		return NO;
	}
}

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	}
	return _dateFormatter;
}

#pragma mark - Initializers

- (instancetype)init {
	if (self = [super init]) {
		_authToken = @"";
		_url = @"";
		_title = @"";
		_extended = @"";
		_dt = [NSDate new];
		_replace = YES;
		_shared = YES;
		_toread = NO;
		_tags = @[];
		_lastPosted = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddToken:) name:PMAccountStoreDidAddTokenNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateToken:) name:PMAccountStoreDidUpdateTokenNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveToken:) name:PMAccountStoreDidRemoveTokenNotification object:nil];
	}
	return self;
}

- (instancetype)initWithParameters:(NSDictionary *)parameters {
	if (self = [self init]) {
		for (id parameter in [parameters allValues]) {
			if (![parameter isKindOfClass:[NSString class]]) return self;
		}
		
		NSString *authToken = parameters[@"auth_token"];
		if (authToken) _authToken = [authToken copy];
		
		NSString *url = parameters[@"url"];
		if (url) _url = [url copy];
		
		NSString *title = parameters[@"description"];
		if (title) _title = [title copy];
		
		NSString *extended = parameters[@"extended"];
		if (extended) _extended = [extended copy];
		
		NSString *dt = parameters[@"dt"];
		if (dt) _dt = [self.dateFormatter dateFromString:dt];
		
		NSString *replace = parameters[@"replace"];
		if (replace) _replace = [[replace lowercaseString] isEqualToString:@"yes"];
		
		NSString *shared = parameters[@"shared"];
		if (shared) _shared = [[shared lowercaseString] isEqualToString:@"yes"];
		
		NSString *toread = parameters[@"toread"];
		if (toread) _toread = [[toread lowercaseString] isEqualToString:@"yes"];
		
		NSString *tags = parameters[@"tags"];
		if (tags) {
			NSCharacterSet *commaSpaceSet = [NSCharacterSet characterSetWithCharactersInString:@", "];
			NSMutableArray *tagsArray = [NSMutableArray arrayWithArray:[tags componentsSeparatedByCharactersInSet:commaSpaceSet]];
			[tagsArray removeObject:@""];
			_tags = [tagsArray copy];
		}
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Methods

- (NSDictionary *)parameters {
	return @{ @"auth_token"  : self.authToken,
			  @"url"		 : self.url,
			  @"description" : self.title,
			  @"extended"	 : self.extended,
			  @"tags"		 : [self.tags componentsJoinedByString:@" "],
			  @"dt"			 : [self.dateFormatter stringFromDate:self.dt],
			  @"replace"	 : self.replace ? @"yes" : @"no",
			  @"shared"		 : self.shared ? @"yes" : @"no",
			  @"toread"		 : self.toread ? @"yes" : @"no" };
}

- (void)addTags:(NSString *)tags {
	NSCharacterSet *commaSpaceSet = [NSCharacterSet characterSetWithCharactersInString:@", "];
	NSMutableArray *newTags = [NSMutableArray arrayWithArray:[tags componentsSeparatedByCharactersInSet:commaSpaceSet]];
	[newTags removeObject:@""];
	for (NSString *newTag in newTags) {
		NSMutableArray *tempTags = [NSMutableArray arrayWithArray:self.tags];
		[tempTags removeObject:newTag];
		[tempTags addObject:newTag];
		self.tags = [tempTags copy];
	}
}

- (void)removeTag:(NSString *)tag {
	NSMutableArray *tempTags = [NSMutableArray arrayWithArray:self.tags];
	[tempTags removeObject:tag];
	self.tags = [tempTags copy];
}

- (void)didAddToken:(NSNotification *)notification {
	if ([self.authToken isEqualToString:@""] || !self.authToken) {
		self.authToken = notification.userInfo[PMAccountStoreTokenKey];
	}
}

- (void)didUpdateToken:(NSNotification *)notification {
	NSString *oldToken = notification.userInfo[PMAccountStoreOldTokenKey];
	if ([self.authToken isEqualToString:oldToken]) {
		NSString *newToken = notification.userInfo[PMAccountStoreTokenKey];
		self.authToken = newToken;
	}
}

- (void)didRemoveToken:(NSNotification *)notification {
	NSString *removedToken = notification.userInfo[PMAccountStoreTokenKey];
	if ([self.authToken isEqualToString:removedToken]) {
		self.authToken = [PMAccountStore sharedStore].defaultToken;
	}
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[PMBookmark class]]) return NO;
	
	PMBookmark *other = (PMBookmark *)object;
	
	return (self.url == other.url || [self.url isEqual:other.url]) &&
		   (self.title == other.title || [self.title isEqual:other.title]) &&
		   (self.extended == other.extended || [self.extended isEqual:other.extended]) &&
		   (self.dt == other.dt || [self.dt isEqualToDate:other.dt]) &&
		   (self.replace == other.replace) &&
		   (self.shared == other.shared) &&
		   (self.toread == other.toread) &&
		   (self.tags == other.tags || [self.tags isEqualToArray:other.tags]);
}

- (NSUInteger)hash {
	return self.url.hash ^ self.title.hash ^ self.extended.hash ^ self.dt.hash ^ self.replace * 13 ^ self.shared * 17 ^ self.toread * 19 ^ self.tags.hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
	return [[PMBookmark allocWithZone:zone] initWithParameters:[self parameters]];
}

#pragma mark - NSCoding / NSSecureCoding

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		_authToken = [decoder decodeObjectOfClass:[NSString class] forKey:@"authToken"];
		_url = [decoder decodeObjectOfClass:[NSString class] forKey:@"url"];
		_title = [decoder decodeObjectOfClass:[NSString class] forKey:@"title"];
		_extended = [decoder decodeObjectOfClass:[NSString class] forKey:@"extended"];
		_dt = [decoder decodeObjectOfClass:[NSDate class] forKey:@"dt"];
		_replace = [decoder decodeBoolForKey:@"replace"];
		_shared = [decoder decodeBoolForKey:@"shared"];
		_toread = [decoder decodeBoolForKey:@"toread"];
		_tags = [decoder decodeObjectOfClass:[NSArray class] forKey:@"tags"];
		_lastPosted = [decoder decodeObjectOfClass:[NSDate class] forKey:@"lastPosted"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.authToken forKey:@"authToken"];
	[encoder encodeObject:self.url forKey:@"url"];
	[encoder encodeObject:self.title forKey:@"title"];
	[encoder encodeObject:self.extended forKey:@"extended"];
	[encoder encodeObject:self.dt forKey:@"dt"];
	[encoder encodeBool:self.replace forKey:@"replace"];
	[encoder encodeBool:self.shared forKey:@"shared"];
	[encoder encodeBool:self.toread forKey:@"toread"];
	[encoder encodeObject:self.tags forKey:@"tags"];
	[encoder encodeObject:self.lastPosted forKey:@"lastPosted"];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

#pragma mark - KVC / KVO

+ (NSSet *)keyPathsForValuesAffectingPostable {
	return [NSSet setWithArray:@[@"authToken", @"url", @"title"]];
}

@end
