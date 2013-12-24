//
//  PMPinboardManager.h
//  Pinmark
//
//  Created by Kyle Stevens on 12/24/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface PMPinboardManager : NSObject

@property (strong, nonatomic, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *username;

- (void)addAccountForUsername:(NSString *)username password:(NSString *)password completionHandler:(void (^)(NSError *))completionHandler;
- (void)add:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCallback failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failureCallback;

@end
