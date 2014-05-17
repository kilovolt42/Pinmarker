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

- (void)testInit {
	PMBookmark *bookmark = [[PMBookmark alloc] init];
	XCTAssertNotNil(bookmark, @"bookmark was not created");
}

- (void)testInitSetsDefaultValues {
	PMBookmark *bookmark = [[PMBookmark alloc] init];
	XCTAssertNotNil(bookmark, @"Bookmark not created");
	XCTAssert([bookmark.username isEqualToString:@""], @"username was not blank");
	XCTAssert([bookmark.url isEqualToString:@""], @"url was not blank");
	XCTAssert([bookmark.title isEqualToString:@""], @"title was not blank");
	XCTAssert([bookmark.extended isEqualToString:@""], @"extended was not blank");
	XCTAssertNil(bookmark.dt, @"dt was not nil");
	XCTAssert(bookmark.replace, @"replace was not YES");
	XCTAssert(bookmark.shared, @"shared was not YES");
	XCTAssertFalse(bookmark.toread, @"toread was not NO");
	XCTAssertEqualObjects(bookmark.tags, @[], @"tags was not empty");
	XCTAssertNil(bookmark.lastPosted, @"lastPosted was not nil");
}

- (void)testInitWithParameters {
	PMBookmark *bookmark = [[PMBookmark alloc] initWithParameters:nil];
	XCTAssert([bookmark isEqual:[[PMBookmark alloc] init]], @"bookmark was not set with default values");
	
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	NSString *dateString = [dateFormatter stringFromDate:date];
	
	NSDictionary *parameters = @{ @"username": @"kilovolt42",
								  @"url": @"http://kilovolt42.com",
								  @"description": @"Kyle Stevens",
								  @"extended": @"iOS developer",
								  @"dt": dateString,
								  @"replace": @"no",
								  @"shared": @"no",
								  @"toread": @"yes",
								  @"tags": @"ios developer" };
	
	bookmark = [[PMBookmark alloc] initWithParameters:parameters];
	
	XCTAssert([bookmark.username isEqualToString:parameters[@"username"]], @"username was different");
	XCTAssert([bookmark.url isEqualToString:parameters[@"url"]], @"url was different");
	XCTAssert([bookmark.title isEqualToString:parameters[@"description"]], @"title was different");
	XCTAssert([bookmark.extended isEqualToString:parameters[@"extended"]], @"extended was different");
	XCTAssert([bookmark.dt isEqualToDate:[dateFormatter dateFromString:parameters[@"dt"]]], @"dt was different");
	XCTAssertFalse(bookmark.replace, @"replace was not NO");
	XCTAssertFalse(bookmark.shared, @"shared was not NO");
	XCTAssert(bookmark.toread, @"toread was not YES");
	XCTAssert([bookmark.tags count] == 2, @"tag count was not 2");
	XCTAssert([bookmark.tags containsObject:@"ios"], @"tags did not contain ios");
	XCTAssert([bookmark.tags containsObject:@"developer"], @"tags did not contain developer");
}

- (void)testInitWithParametersHandlesGarbage {
	PMBookmark *bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url" : @[],
																	 @"description" : @{},
																	 @"replace" : [NSDate date],
																	 @"tags" : @42 }];
	
	XCTAssert([bookmark.url isEqualToString:@""], @"url was not blank");
	XCTAssert([bookmark.title isEqualToString:@""], @"title was not blank");
	XCTAssert(bookmark.replace, @"replace was not YES");
	XCTAssertEqualObjects(bookmark.tags, @[], @"tags was not empty");
}

- (void)testParameters {
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	NSString *dateString = [dateFormatter stringFromDate:date];
	
	NSDictionary *parameters = @{ @"url": @"http://kilovolt42.com",
								  @"description": @"Kyle Stevens",
								  @"extended": @"iOS developer",
								  @"dt": dateString,
								  @"replace": @"no",
								  @"shared": @"no",
								  @"toread": @"yes",
								  @"tags": @"ios developer" };
	
	PMBookmark *bookmark = [[PMBookmark alloc] initWithParameters:parameters];
	
	XCTAssertEqualObjects(parameters, [bookmark parameters], @"parameters passed in were different from those returned");
}

- (void)testPostable {
	PMBookmark *bookmark = [[PMBookmark alloc] init];
	XCTAssertFalse(bookmark.postable, @"blank bookmark was postable");
	
	// using accessors
	
	bookmark.url = @"http://kilovolt42.com";
	XCTAssertFalse(bookmark.postable, @"bookmark with only URL was postable");
	
	bookmark.url = nil;
	bookmark.title = @"Kyle Stevens";
	XCTAssertFalse(bookmark.postable, @"bookmark with only title was postable");
	
	bookmark.url = @"http://kilovolt42.com";
	XCTAssertFalse(bookmark.postable, @"bookmark with only URL and title was postable");
	
	bookmark.username = @"example";
	XCTAssert(bookmark.postable, @"bookmark with URL, title, and username was not postable");
	
	// using initWithParameters
	
	bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url": @"http://kilovolt42.com" }];
	XCTAssertFalse(bookmark.postable, @"bookmark with only URL was postable");
	
	bookmark = [[PMBookmark alloc] initWithParameters:@{ @"title": @"Kyle Stevens" }];
	XCTAssertFalse(bookmark.postable, @"bookmark with only title was postable");
	
	bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url": @"http://kilovolt42.com",
														 @"description": @"Kyle Stevens" }];
	XCTAssertFalse(bookmark.postable, @"bookmark with only URL and title was postable");
	
	bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url": @"http://kilovolt42.com",
														 @"description": @"Kyle Stevens",
														 @"username": @"example" }];
	XCTAssert(bookmark.postable, @"bookmark with URL, title, and username was not postable");
}

- (void)testAddTags {
	PMBookmark *bookmark = [[PMBookmark alloc] init];
	[bookmark addTags:@"   kyle, ios-developer,,,  , ,   coffee ,"];
	
	XCTAssert([bookmark.tags count] == 3, @"tag count was not 3");
	XCTAssertFalse([bookmark.tags containsObject:@""], @"tags contained empty words");
	XCTAssertFalse([bookmark.tags containsObject:@" "], @"tags contained a space character");
	XCTAssertFalse([bookmark.tags containsObject:@","], @"tags contained a comma");
	XCTAssertFalse([bookmark.tags containsObject:@"ios"], @"tags contained ios instead of ios-developer");
	XCTAssert([bookmark.tags containsObject:@"kyle"], @"tags did not contain kyle");
	XCTAssert([bookmark.tags containsObject:@"ios-developer"], @"tags did not contain ios-developer");
	XCTAssert([bookmark.tags containsObject:@"coffee"], @"tags did not contain coffee");
}

- (void)testRemoveTag {
	PMBookmark *bookmark = [[PMBookmark alloc] init];
	[bookmark addTags:@"kyle coffee"];
	
	XCTAssert([bookmark.tags count] == 2, @"tag count was not 2");
	XCTAssert([bookmark.tags containsObject:@"kyle"], @"tags did not initially contain kyle");
	XCTAssert([bookmark.tags containsObject:@"coffee"], @"tags did not initially contain coffee");
	
	[bookmark removeTag:@"coffee"];
	
	XCTAssert([bookmark.tags count] == 1, @"tag count was not 1");
	XCTAssertFalse([bookmark.tags containsObject:@"coffee"], @"tags still contained coffee");
}

- (void)testIsEqual {
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
	NSString *dateString = [dateFormatter stringFromDate:date];
	
	NSDictionary *parameters = @{ @"username": @"kilovolt42",
								  @"url": @"http://kilovolt42.com",
								  @"description": @"Kyle Stevens",
								  @"extended": @"iOS developer",
								  @"dt": dateString,
								  @"replace": @"no",
								  @"shared": @"no",
								  @"toread": @"yes",
								  @"tags": @"ios developer" };
	
	PMBookmark *bookmark1 = [[PMBookmark alloc] initWithParameters:parameters];
	
	PMBookmark *bookmark2 = [[PMBookmark alloc] init];
	bookmark2.username = @"kilovolt42";
	bookmark2.url = @"http://kilovolt42.com";
	bookmark2.title = @"Kyle Stevens";
	bookmark2.extended = @"iOS developer";
	bookmark2.dt = [dateFormatter dateFromString:dateString];
	bookmark2.replace = NO;
	bookmark2.shared = NO;
	bookmark2.toread = YES;
	bookmark2.tags = @[@"ios", @"developer"];
	
	XCTAssertEqualObjects(bookmark1, bookmark2, @"bookmarks were not equal");
}

@end
