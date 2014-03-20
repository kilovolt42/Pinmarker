//
//  PMNavigationVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/17/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMNavigationVC.h"
#import "PMNewPinTVC.h"

@interface PMNavigationVC ()

@end

@implementation PMNavigationVC

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	UIViewController *viewController = self.viewControllers[0];
	if ([viewController isKindOfClass:[PMNewPinTVC class]]) {
		PMNewPinTVC *newPinTVC = (PMNewPinTVC *)viewController;
		[newPinTVC openURL:url sourceApplication:sourceApplication annotation:annotation];
	}
}

@end