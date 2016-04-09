//
//  NSString+Pinmarker.h
//  Pinmarker
//
//  Created by Kyle Stevens on 2/11/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

@interface NSString (Pinmarker)

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

/**
 * Return the username portion of the string, assumed to be a Pinboard API token.
 *
 * @return The username portion of the string.
 */
- (NSString *)tokenUsername;

/**
 * Return the number portion of the string, assumed to be a Pinboard API token.
 *
 * @return The number portion of the token.
 */
- (NSString *)tokenNumber;

@end
