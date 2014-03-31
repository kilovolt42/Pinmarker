//
//  PMBookmarkStore.h
//  Pinmarker
//
//  Created by Kyle Stevens on 3/5/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PMBookmark;

/**
 * Right now the bookmark store does not have any sense of a bookmark stack. When a new
 * bookmark is created, the previously stored bookmark is over written if one existed.
 * Users should still call -lastBookmark to obtain the previously stored bookmark or a
 * blank bookmark if no bookmark is stored.
 */
@interface PMBookmarkStore : NSObject

+ (instancetype)sharedStore;

/**
 * Creates a new blank bookmark.
 *
 * @return A new blank bookmark.
 */
- (PMBookmark *)createBookmark;

/**
 * Creates a new bookmark using the provided Pinboard complient parameters.
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
- (void)postBookmark:(PMBookmark *)bookmark success:(void (^)(id))successCallback failure:(void (^)(NSError *, id))failureCallback;

/**
 * Remove a bookmark.
 *
 * @param bookmark Bookmark to remove.
 */
- (void)discardBookmark:(PMBookmark *)bookmark;

@end
