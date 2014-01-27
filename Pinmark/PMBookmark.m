//
//  PMBookmark.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMBookmark.h"

@interface PMBookmark ()
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation PMBookmark

#pragma mark - Initializers

- (id)init {
	if (self = [super init]) {
		self.url = nil;
		self.description = nil;
		self.extended = nil;
		self.dt = nil;
		self.replace = YES;
		self.shared = YES;
		self.toread = NO;
		self.tags = nil;
	}
	return self;
}

- (id)initWithParameters:(NSDictionary *)parameters {
	if (self = [super init]) {
		self.url = parameters[@"url"];
		self.description = parameters[@"description"];
		self.extended = parameters[@"extended"];
		self.dt = parameters[@"dt"] ? [self.dateFormatter dateFromString:parameters[@"dt"]] : nil;
		self.replace = parameters[@"replace"] ? [[parameters[@"replace"] lowercaseString] isEqualToString:@"yes"] : YES;
		self.shared = parameters[@"shared"] ? [[parameters[@"shared"] lowercaseString] isEqualToString:@"yes"] : YES;
		self.toread = parameters[@"toread"] ? [[parameters[@"toread"] lowercaseString] isEqualToString:@"yes"] : NO;
		
		NSCharacterSet *commaSpaceSet = [NSCharacterSet characterSetWithCharactersInString:@", "];
		NSMutableArray *newTags = [NSMutableArray arrayWithArray:[parameters[@"tags"] componentsSeparatedByCharactersInSet:commaSpaceSet]];
		[newTags removeObject:@""];
		self.tags = [newTags copy];
	}
	return self;
}

#pragma mark - Methods

- (NSDictionary *)parameters {
	NSMutableDictionary *parameters = [NSMutableDictionary new];
	if (self.url) parameters[@"url"] = self.url;
	if (self.description) parameters[@"description"] = self.description;
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

#pragma mark -

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	}
	return _dateFormatter;
}

@end
