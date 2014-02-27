//
//  PMBookmark.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMBookmark.h"
#import "NSString+Pinmark.h"

@interface PMBookmark ()
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

#define DEFAULT_REPLACE_VALUE YES
#define DEFAULT_SHARED_VALUE YES
#define DEFAULT_TOREAD_VALUE NO

@implementation PMBookmark

#pragma mark - Properties

- (BOOL)isPostable {
	if ([self.url isPinboardPermittedURL] && [self.title length]) {
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

- (id)init {
	if (self = [super init]) {
		_url = nil;
		_title = nil;
		_extended = nil;
		_dt = nil;
		_replace = DEFAULT_REPLACE_VALUE;
		_shared = DEFAULT_SHARED_VALUE;
		_toread = DEFAULT_TOREAD_VALUE;
		_tags = nil;
	}
	return self;
}

- (id)initWithParameters:(NSDictionary *)parameters {
	if (self = [self init]) {
		NSString *url = parameters[@"url"];
		if ([url isKindOfClass:[NSString class]]) {
			_url = [url copy];
		}
		
		NSString *title = parameters[@"description"];
		if ([title isKindOfClass:[NSString class]]) {
			_title = [title copy];
		}
		
		NSString *extended = parameters[@"extended"];
		if ([extended isKindOfClass:[NSString class]]) {
			_extended = [extended copy];
		}
		
		NSString *dt = parameters[@"dt"];
		if ([dt isKindOfClass:[NSString class]]) {
			_dt = [self.dateFormatter dateFromString:dt];
		}
		
		NSString *replace = parameters[@"replace"];
		if ([replace isKindOfClass:[NSString class]]) {
			_replace = [[replace lowercaseString] isEqualToString:@"yes"];
		} else {
			_replace = DEFAULT_REPLACE_VALUE;
		}
		
		NSString *shared = parameters[@"shared"];
		if ([shared isKindOfClass:[NSString class]]) {
			_shared = [[shared lowercaseString] isEqualToString:@"yes"];
		} else {
			_shared = DEFAULT_SHARED_VALUE;
		}
		
		NSString *toread = parameters[@"toread"];
		if ([toread isKindOfClass:[NSString class]]) {
			_toread = [[toread lowercaseString] isEqualToString:@"yes"];
		} else {
			_toread = DEFAULT_TOREAD_VALUE;
		}
		
		NSString *tagsString = parameters[@"tags"];
		if ([tagsString isKindOfClass:[NSString class]]) {
			NSCharacterSet *commaSpaceSet = [NSCharacterSet characterSetWithCharactersInString:@", "];
			NSMutableArray *tagsArray = [NSMutableArray arrayWithArray:[tagsString componentsSeparatedByCharactersInSet:commaSpaceSet]];
			[tagsArray removeObject:@""];
			_tags = [tagsArray copy];
		}
	}
	return self;
}

#pragma mark - Methods

- (NSDictionary *)parameters {
	NSMutableDictionary *parameters = [NSMutableDictionary new];
	if (self.url) parameters[@"url"] = self.url;
	if (self.title) parameters[@"description"] = self.title;
	if (self.extended) parameters[@"extended"] = self.extended;
	if (self.tags) parameters[@"tags"] = [self.tags componentsJoinedByString:@" "];
	if (self.dt) parameters[@"dt"] = [self.dateFormatter stringFromDate:self.dt];
	parameters[@"replace"] = self.replace ? @"yes" : @"no";
	parameters[@"shared"] = self.shared ? @"yes" : @"no";
	parameters[@"toread"] = self.toread ? @"yes" : @"no";
	return [parameters copy];
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
		_url = [decoder decodeObjectOfClass:[NSString class] forKey:@"url"];
		_title = [decoder decodeObjectOfClass:[NSString class] forKey:@"title"];
		_extended = [decoder decodeObjectOfClass:[NSString class] forKey:@"extended"];
		_dt = [decoder decodeObjectOfClass:[NSDate class] forKey:@"dt"];
		_replace = [decoder decodeBoolForKey:@"replace"];
		_shared = [decoder decodeBoolForKey:@"shared"];
		_toread = [decoder decodeBoolForKey:@"toread"];
		_tags = [decoder decodeObjectOfClass:[NSArray class] forKey:@"tags"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:self.url forKey:@"url"];
	[encoder encodeObject:self.title forKey:@"title"];
	[encoder encodeObject:self.extended forKey:@"extended"];
	[encoder encodeObject:self.dt forKey:@"dt"];
	[encoder encodeBool:self.replace forKey:@"replace"];
	[encoder encodeBool:self.shared forKey:@"shared"];
	[encoder encodeBool:self.toread forKey:@"toread"];
	[encoder encodeObject:self.tags forKey:@"tags"];
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

#pragma mark - KVC / KVO

+ (NSSet *)keyPathsForValuesAffectingPostable {
	return [NSSet setWithArray:@[@"url", @"title"]];
}

@end
