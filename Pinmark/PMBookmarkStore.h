//
//  PMBookmarkStore.h
//  Pinmark
//
//  Created by Kyle Stevens on 3/5/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PMBookmark;

@interface PMBookmarkStore : NSObject

+ (instancetype)sharedStore;

- (PMBookmark *)createBookmark;
- (PMBookmark *)createBookmarkWithParameters:(NSDictionary *)parameters;
- (void)postBookmark:(PMBookmark *)bookmark success:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback;

@end
