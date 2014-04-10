//
//  NSString+Pinmark.m
//  Pinmarker
//
//  Created by Kyle Stevens on 2/11/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "NSString+Pinmark.h"

NSString * const PMAnyURLRegex = @"(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))";

@implementation NSString (Pinmark)

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
																				 (CFStringRef)self,
																				 NULL,
																				 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
																				 CFStringConvertNSStringEncodingToEncoding(encoding)));
}

- (BOOL)isValidURL {
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:PMAnyURLRegex options:NSRegularExpressionCaseInsensitive error:&error];
	NSRange range = [regex rangeOfFirstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
	return range.length > 0;
}

- (BOOL)isPinboardPermittedURL {
	NSArray *schemes = @[@"http", @"https", @"javascript", @"mailto", @"ftp", @"file", @"feed"];
	NSURL *url = [NSURL URLWithString:self];
	return [schemes containsObject:[url scheme]] && [self isValidURL];
}

- (NSString *)tokenUsername {
	return [[self componentsSeparatedByString:@":"] firstObject];
}

- (NSString *)tokenNumber {
	return [[self componentsSeparatedByString:@":"] lastObject];
}

@end
