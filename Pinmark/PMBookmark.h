//
//  PMBookmark.h
//  Pinmark
//
//  Created by Kyle Stevens on 1/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMBookmark : NSObject <NSCopying, NSCoding, NSSecureCoding>

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *extended;
@property (nonatomic, copy) NSArray *tags;
@property (nonatomic, copy) NSDate *dt;
@property (nonatomic) BOOL replace;
@property (nonatomic) BOOL shared;
@property (nonatomic) BOOL toread;
@property (nonatomic, readonly, getter=isPostable) BOOL postable;

- (instancetype)initWithParameters:(NSDictionary *)parameters;
- (NSDictionary *)parameters;
- (void)addTags:(NSString *)tags;
- (void)removeTag:(NSString *)tag;

@end
