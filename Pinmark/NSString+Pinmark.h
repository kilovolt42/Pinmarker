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
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;

@end
