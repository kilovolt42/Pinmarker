//
//  NSString+Pinmark.m
//  Pinmark
//
//  Created by Kyle Stevens on 2/11/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "NSString+Pinmark.h"

@implementation NSString (Pinmark)

-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
																				 (CFStringRef)self,
																				 NULL,
																				 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
																				 CFStringConvertNSStringEncodingToEncoding(encoding)));
}

@end
