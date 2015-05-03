//
//  PMConstants.m
//  Pinmarker
//
//  Created by Kyle Stevens on 10/4/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMConstants.h"

NSString * const PMPinboardAPIDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";

// Request Keys
NSString * const PMPinboardAPIFormatKey = @"format";
NSString * const PMPinboardAPIAuthTokenKey = @"auth_token";

// Response Keys
NSString * const PMPinboardAPIResultCodeKey = @"result_code";
NSString * const PMPinboardAPIResultKey = @"result";

// Bookmark Keys
NSString * const PMPinboardAPIUsernameKey = @"username";
NSString * const PMPinboardAPIURLKey = @"url";
NSString * const PMPinboardAPITitleKey = @"description";
NSString * const PMPinboardAPIExtendedKey = @"extended";
NSString * const PMPinboardAPIDateTimeKey = @"dt";
NSString * const PMPinboardAPIReplaceKey = @"replace";
NSString * const PMPinboardAPISharedKey = @"shared";
NSString * const PMPinboardAPIToReadKey = @"toread";
NSString * const PMPinboardAPITagsKey = @"tags";
NSString * const PMPinboardAPILastPostedKey = @"lastPosted";

// Pinboard API Methods
NSString * const PMPinboardAPIPlistFilename = @"PinboardAPI";
NSString * const PMPinboardAPIMethodTokenAuth = @"token_authentification";
NSString * const PMPinboardAPIMethodBasicAuth = @"basic_authentification";
NSString * const PMPinboardAPIMethodGetTags = @"get_tags";
NSString * const PMPinboardAPIMethodGetPosts = @"get_posts";
NSString * const PMPinboardAPIMethodAddPost = @"add_post";
