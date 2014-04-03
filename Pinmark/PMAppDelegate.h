//
//  PMAppDelegate.h
//  Pinmarker
//
//  Created by Kyle Stevens on 12/13/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const PMDidInitializeDefaults;
extern NSString * const PMAssociatedTokensKey;
extern NSString * const PMDefaultTokenKey;

@interface PMAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;

@end
