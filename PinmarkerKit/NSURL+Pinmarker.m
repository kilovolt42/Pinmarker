//
//  NSURL+Pinmarker.m
//  Pinmarker
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "NSURL+Pinmarker.h"

@implementation NSURL (Pinmarker)

+ (instancetype)URLWithString:(NSString *)URLString queryParameters:(NSDictionary *)parameters {
    if (parameters == nil || parameters.allKeys.count == 0) {
        return [NSURL URLWithString:URLString];
    }

    NSCharacterSet *queryCharacters = [NSCharacterSet URLQueryAllowedCharacterSet];

    NSMutableString *queryString = [NSMutableString stringWithString:@"?"];
    BOOL prependAmpersand = NO;
    for (NSString *key in parameters.allKeys) {
        if (prependAmpersand) {
            [queryString appendString:@"&"];
        }
        NSString *parameter = [parameters[key] stringByAddingPercentEncodingWithAllowedCharacters:queryCharacters];
        [queryString appendString:[NSString stringWithFormat:@"%@=%@", key, parameter]];
        prependAmpersand = YES;
    }

    return [NSURL URLWithString:[URLString stringByAppendingString:queryString]];
}

- (NSDictionary *)queryParameters {
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    for (NSString *parameter in [[self query] componentsSeparatedByString:@"&"]) {
        NSArray *fieldValuePair = [parameter componentsSeparatedByString:@"="];
        NSString *field = [fieldValuePair[0] stringByRemovingPercentEncoding];
        NSString *value = [fieldValuePair[1] stringByRemovingPercentEncoding];
        parameters[field] = value;
    }
    return [parameters copy];
}

@end
