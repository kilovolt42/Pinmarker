//
//  Constants.m
//  Pinmarker
//
//  Created by Kyle Stevens on 1/24/16.
//  Copyright © 2016 kilovolt42. All rights reserved.
//

#import "Constants.h"

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
