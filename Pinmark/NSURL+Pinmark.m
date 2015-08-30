//
//  NSURL+Pinmark.m
//  Pinmarker
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "NSURL+Pinmark.h"

@implementation NSURL (Pinmark)

+ (instancetype)URLWithString:(NSString *)URLString queryParameters:(NSDictionary *)parameters {
	if (parameters == nil || parameters.allKeys.count == 0) {
		return [NSURL URLWithString:URLString];
	}

	NSMutableDictionary *encodedParameters = [NSMutableDictionary new];
	for (NSString *key in parameters.allKeys) {
		encodedParameters[key] = [parameters[key] urlEncodeUsingEncoding:NSUTF8StringEncoding];
	}

	NSMutableString *queryString = [NSMutableString stringWithString:@"?"];
	BOOL prependAmpersand = NO;
	for (NSString *key in encodedParameters.allKeys) {
		if (prependAmpersand) {
			[queryString appendString:@"&"];
		}
		[queryString appendString:[NSString stringWithFormat:@"%@=%@", key, encodedParameters[key]]];
		prependAmpersand = YES;
	}

	return [NSURL URLWithString:[URLString stringByAppendingString:queryString]];
}

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
