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

- (void)addURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
	UIViewController *viewController = self.viewControllers[0];
	if ([viewController isKindOfClass:[PMNewPinTVC class]]) {
		PMNewPinTVC *newPinTVC = (PMNewPinTVC *)viewController;
		[newPinTVC addURL:url sourceApplication:sourceApplication];
	}
}

@end