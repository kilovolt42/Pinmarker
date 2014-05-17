//
//  PMAppDelegate.h
//  Pinmarker
//
//  Created by Kyle Stevens on 12/13/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMTEDelegateController;

extern NSString * const PMTextExpanderEnabled;

@interface PMAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic, readonly) SMTEDelegateController *textExpander;

@end
