//
//  PMTagStore.h
//  Pinmarker
//
//  Created by Kyle Stevens on 3/8/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMTagStore : NSObject

+ (instancetype)sharedStore;

- (NSArray *)tagsForAuthToken:(NSString *)authToken;
- (void)markTagsDirtyForAuthToken:(NSString *)authToken;

@end
