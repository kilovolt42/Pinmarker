//
//  NSString+Pinmark.h
//  Pinmark
//
//  Created by Kyle Stevens on 2/11/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Pinmark)

/**
 * Encode a string for URLs. Apple's -stringByAddingPercentEscapesUsingEncoding: does not encode characters
 * such as ampersand or slash.
 *
 * @return URL encoded representation of the string.
 */
- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;

/**
 * Determines whether the string qualifies as a URL based on John Gruber's Liberal Regex Pattern
 * for all URLs: https://gist.github.com/gruber/249502
 *
 * @return YES if valid URL, otherwise NO.
 */
- (BOOL)isValidURL;

/**
 * Determines whether the string qualifies as a URL using isValidURL: and whether its scheme matches those
 * allowed by Pinboard's API. Permitted schemes include http, https, javascript, mailto, ftp, file, and feed.
 *
 * @return YES if permitted by Pinboard, otherwise NO.
 */
- (BOOL)isPinboardPermittedURL;

@end
