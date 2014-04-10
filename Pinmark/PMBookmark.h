//
//  PMBookmark.h
//  Pinmarker
//
//  Created by Kyle Stevens on 1/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMBookmark : NSObject <NSCopying, NSCoding, NSSecureCoding>

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *extended;
@property (nonatomic, copy) NSArray *tags;
@property (nonatomic) NSDate *dt;
@property (nonatomic) BOOL replace;
@property (nonatomic) BOOL shared;
@property (nonatomic) BOOL toread;
@property (nonatomic, readonly, getter=isPostable) BOOL postable;
@property (nonatomic) NSDate *lastPosted;

/**
 * Create a bookmark from string parameters using keys matching the Pinboard API. All values
 * must be NSString objects, otherwise a blank bookmark is returned.
 *
 * @param parameters Dictionary of string values with Pinboard parameter keys.
 *
 * @return Bookmark initialized using Pinboard API compatible string parameters.
 */
- (instancetype)initWithParameters:(NSDictionary *)parameters;

- (NSDictionary *)parameters;
- (void)addTags:(NSString *)tags;
- (void)removeTag:(NSString *)tag;

@end
