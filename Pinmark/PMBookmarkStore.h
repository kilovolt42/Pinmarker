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

/**
 * Creates a new blank bookmark and adds it to the bookmark stack.
 *
 * @return A new blank bookmark.
 */
- (PMBookmark *)createBookmark;

/**
 * Creates a new bookmark using the provided Pinboard complient parameters and
 * adds it to the bookmark stack.
 *
 * @param parameters Pinboard complient parameters.
 *
 * @return A new bookmark with provided parameters.
 */
- (PMBookmark *)createBookmarkWithParameters:(NSDictionary *)parameters;

/**
 * Returns the latest bookmark from a stack of created bookmarks.
 *
 * @return Latest bookmark or a blank bookmark if no bookmarks were on the bookmark stack.
 */
- (PMBookmark *)lastBookmark;

/**
 * Posts a bookmark to Pinboard and pops the bookmark off the bookmark stack.
 *
 * @param bookmark        Bookmark to post to Pinboard.
 * @param successCallback Callback block called when posting was successful.
 * @param failureCallback Callback block called when posting was unsuccessful.
 */
- (void)postBookmark:(PMBookmark *)bookmark success:(void (^)(id))successCallback failure:(void (^)(NSError *))failureCallback;

/**
 * Remove a bookmark from the bookmark stack.
 *
 * @param bookmark Bookmark to remove.
 */
- (void)discardBookmark:(PMBookmark *)bookmark;

@end
