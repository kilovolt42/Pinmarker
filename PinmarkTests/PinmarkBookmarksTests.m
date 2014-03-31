//
//  PinmarkBookmarksTests.m
//  Pinmarker
//
//  Created by Kyle Stevens on 2/25/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PMBookmark.h"

@interface PinmarkBookmarksTests : XCTestCase

@end

@implementation PinmarkBookmarksTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBookmarkEquality {
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	NSString *dateString = [dateFormatter stringFromDate:date];
	
	PMBookmark *bookmark1 = [[PMBookmark alloc] initWithParameters:@{ @"url": @"http://kilovolt42.com",
																	  @"description": @"Kyle Stevens",
																	  @"extended": @"iOS developer",
																	  @"dt": dateString,
																	  @"replace": @"yes",
																	  @"shared": @"yes",
																	  @"toread": @"yes",
																	  @"tags": @"ios developer" }];
	
	PMBookmark *bookmark2 = [PMBookmark new];
	bookmark2.url = @"http://kilovolt42.com";
	bookmark2.title = @"Kyle Stevens";
	bookmark2.extended = @"iOS developer";
	bookmark2.dt = [dateFormatter dateFromString:dateString];
	bookmark2.replace = YES;
	bookmark2.shared = YES;
	bookmark2.toread = YES;
	bookmark2.tags = @[@"ios", @"developer"];
	
	XCTAssertEqualObjects(bookmark1, bookmark2, @"Bookmarks should be equal");
}

- (void)testPostable {
	PMBookmark *bookmark = [PMBookmark new];
	XCTAssert(!bookmark.postable, @"Bookmark without URL and title should not be postable");
	
	// using accessors
	
	bookmark.url = @"http://kilovolt42.com";
	XCTAssert(!bookmark.postable, @"Bookmark with only URL should not be postable");
	
	bookmark.url = nil;
	bookmark.title = @"Kyle Stevens";
	XCTAssert(!bookmark.postable, @"Bookmark with only title should not be postable");
	
	bookmark.url = @"http://kilovolt42.com";
	XCTAssert(bookmark.postable, @"Bookmark with URL and title should not be postable");
	
	// using initWithParameters
	
	bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url": @"http://kilovolt42.com" }];
	XCTAssert(!bookmark.postable, @"Bookmark with only URL should not be postable");
	
	bookmark = [[PMBookmark alloc] initWithParameters:@{ @"title": @"Kyle Stevens" }];
	XCTAssert(!bookmark.postable, @"Bookmark with only title should not be postable");
	
	bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url": @"http://kilovolt42.com", @"description": @"Kyle Stevens" }];
	XCTAssert(bookmark.postable, @"Bookmark with URL and title should be postable");
}

- (void)testAddTags {
	PMBookmark *bookmark = [PMBookmark new];
	[bookmark addTags:@"   kyle, ios-developer,,,  , ,   coffee ,"];
	
	XCTAssert([bookmark.tags count] == 3, @"Bookmark should contain 3 tags");
	XCTAssert(![bookmark.tags containsObject:@""], @"Bookmarks should never contain empty words");
	XCTAssert(![bookmark.tags containsObject:@" "], @"Bookmarks should never contain the space character as a tag");
	XCTAssert(![bookmark.tags containsObject:@","], @"Bookmarks should never contain a comma as a tag");
	XCTAssert(![bookmark.tags containsObject:@"ios"] && [bookmark.tags containsObject:@"ios-developer"], @"Bookmarks should treat hyphen as a word character and not a separator");
	
	[bookmark removeTag:@"coffee"];
	XCTAssert([bookmark.tags count] == 2, @"Bookmark should contain 2 tags");
	XCTAssert(![bookmark.tags containsObject:@"coffee"], @"Bookmark should not contain the tag 'coffee'");
}

- (void)testGarbageIn {
	PMBookmark *bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url" : @[],
																	 @"description" : @{},
																	 @"replace" : [NSDate date],
																	 @"tags" : @42 }];
	
	XCTAssert([bookmark.url isEqualToString:@""], @"Bookmark should have a blank string URL");
	XCTAssert([bookmark.title isEqualToString:@""], @"Bookmark should have a blank string title");
	XCTAssert(bookmark.replace == YES, "Bookmark should have replace bool set to YES");
	XCTAssert([bookmark.tags isEqualToArray:@[]], @"Bookmark should have an empty tags array");
}

@end
