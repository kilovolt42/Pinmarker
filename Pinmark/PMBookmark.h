//
//  PMBookmark.h
//  Pinmark
//
//  Created by Kyle Stevens on 1/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMBookmark : NSObject

@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) NSString *description;
@property (strong, nonatomic) NSString *extended;
@property (strong, nonatomic) NSMutableArray *tags;
@property (strong, nonatomic) NSDate *dt;
@property (assign, nonatomic) BOOL replace;
@property (assign, nonatomic) BOOL shared;
@property (assign, nonatomic) BOOL toread;

- (id)initWithParameters:(NSDictionary *)parameters;
- (NSDictionary *)parameters;

@end
