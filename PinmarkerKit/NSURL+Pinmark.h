//
//  NSURL+Pinmark.h
//  Pinmarker
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

@interface NSURL (Pinmark)

/**
 * Creates and returns an NSURL object initialized with a provided URL string
 * and query parameters.
 *
 * @param URLString A string representation of the desired URL.
 & @param queryParameters Query parameters to be appended to the URL.
 *
 * @return An NSURL object created from the URL string and query parameters.
 */
+ (instancetype)URLWithString:(NSString *)URLString queryParameters:(NSDictionary *)parameters;

/**
 * Creates a dictionary of the query parameters in which fields are keys for the corresponding values.
 * Does not support array parameters at this time.
 *
 * @return A dictionary of query parameters.
 */
- (NSDictionary *)queryParameters;

@end
