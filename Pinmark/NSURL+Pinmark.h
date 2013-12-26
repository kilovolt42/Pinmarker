//
//  NSURL+Pinmark.h
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Pinmark)

/**
 * Creates a dictionary of the query parameters in which fields are keys for the corresponding values.
 * Does not support array parameters at this time.
 *
 * @return A dictionary of query parameters.
 */
- (NSDictionary *)queryParameters;

@end
