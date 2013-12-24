//
//  NSURL+Pinmark.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "NSURL+Pinmark.h"

@implementation NSURL (Pinmark)

- (NSDictionary *)queryParameters {
	NSMutableDictionary *parameters = [NSMutableDictionary new];
	for (NSString *parameter in [[self query] componentsSeparatedByString:@"&"]) {
		NSArray *fieldValuePair = [parameter componentsSeparatedByString:@"="];
		NSString *field = [fieldValuePair[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *value = [fieldValuePair[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		parameters[field] = value;
	}
	return [parameters copy];
}

@end
