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

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	}
	return _dateFormatter;
}

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

@end
