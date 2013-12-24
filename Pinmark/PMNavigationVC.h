//
//  PMNavigationVC.h
//  Pinmark
//
//  Created by Kyle Stevens on 12/17/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMNavigationVC : UINavigationController

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end
