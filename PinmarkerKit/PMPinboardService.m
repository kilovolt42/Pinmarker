//
//  PMPinboardService.m
//  Pinmarker
//
//  Created by Kyle Stevens on 9/24/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMPinboardService.h"
#import "NSURL+Pinmark.h"

static NSDictionary *PMPinboardAPIMethods;

@implementation PMPinboardService

+ (void)requestAPITokenForAPIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodTokenAuth];
	NSDictionary *parameters = @{ PMPinboardAPIFormatKey: @"json",
								  PMPinboardAPIAuthTokenKey: token };

	NSURL *url = [NSURL URLWithString:method queryParameters:parameters];
	[self requestWithURL:url success:success failure:failure];
}

+ (void)requestAPITokenForUsername:(NSString *)username password:(NSString *)password success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSString *methodFormat = PMPinboardAPIMethods[PMPinboardAPIMethodBasicAuth];
	username = [username stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLUserAllowedCharacterSet]];
	password = [password stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];
	
	NSString *method = [NSString stringWithFormat:methodFormat, username, password];
	NSDictionary *parameters = @{ PMPinboardAPIFormatKey: @"json" };

	NSURL *url = [NSURL URLWithString:method queryParameters:parameters];
	[self requestWithURL:url success:success failure:failure];
}

+ (void)requestTagsForAPIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodGetTags];
	NSDictionary *parameters = @{ PMPinboardAPIFormatKey: @"json",
								  PMPinboardAPIAuthTokenKey: token };

	NSURL *url = [NSURL URLWithString:method queryParameters:parameters];
	[self requestWithURL:url success:success failure:failure];
}

+ (void)requestPostForURL:(NSString *)url APIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodGetPosts];
	NSDictionary *parameters = @{ PMPinboardAPIURLKey: url,
								  PMPinboardAPIFormatKey: @"json",
								  PMPinboardAPIAuthTokenKey: token };
	
	NSURL *requestURL = [NSURL URLWithString:method queryParameters:parameters];
	[self requestWithURL:requestURL success:success failure:failure];
}

+ (void)postBookmarkParameters:(NSDictionary *)parameters APIToken:(NSString *)token success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSString *method = PMPinboardAPIMethods[PMPinboardAPIMethodAddPost];
	NSMutableDictionary *mutableParameters = [parameters mutableCopy];
	mutableParameters[PMPinboardAPIFormatKey] = @"json";
	mutableParameters[PMPinboardAPIAuthTokenKey] = token;
	
	NSURL *requestURL = [NSURL URLWithString:method queryParameters:mutableParameters];
	[self requestWithURL:requestURL success:success failure:failure];
}

#pragma mark -

+ (void)initialize {
	NSString *path = [[NSBundle mainBundle] pathForResource:PMPinboardAPIPlistFilename ofType:@"plist"];
	PMPinboardAPIMethods = [NSDictionary dictionaryWithContentsOfFile:path];
}

/**
 * Performs a JSON request for the given URL. If the request succeeds then pass
 * deserialized JSON to the success handler as a dictionary. Otherwise pass an
 * error back to the failure handler.
 *
 * @param url The URL used to make the request. This should include any required
 *   parameters in the query string.
 * @param success Used to handle a successful request followed by a successful
 *   deserialization of the JSON response.
 * @param failure Used to handle a failed request or a failed attempt at
 *   deserializing the JSON response.
 */
+ (void)requestWithURL:(NSURL *)url success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure {
	NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];

	void (^completion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
		if (error) {
			PMLog(@"Error: %@", error);
			dispatch_async(dispatch_get_main_queue(), ^{
				failure(error);
			});
		} else {
			NSError *jsonError;
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
			if (jsonError) {
				PMLog(@"Error: %@", jsonError);
				dispatch_async(dispatch_get_main_queue(), ^{
					failure(jsonError);
				});
			} else {
				PMLog(@"Response Object: %@", json);
				dispatch_async(dispatch_get_main_queue(), ^{
					success(json);
				});
			}
		}
	};

	NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:completion];
	[task resume];
}

@end
