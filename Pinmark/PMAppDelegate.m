//
//  PMAppDelegate.m
//  Pinmarker
//
//  Created by Kyle Stevens on 12/13/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMAppDelegate.h"
#import "PMNavigationVC.h"
#import "PMAccountStore.h"
#import "PMAddAccountVC.h"
#import "PMTagStore.h"
#import "PMBookmarkStore.h"

#if defined(DEBUG) || defined(ADHOC)
#import "BugshotKit.h"
#endif

NSString * const PMAssociatedTokensKey = @"PMAssociatedTokensKey";
NSString * const PMDefaultTokenKey = @"PMDefaultTokenKey";

@interface PMAppDelegate () <PMAddAccountVCDelegate>

@end

@implementation PMAppDelegate

#pragma mark - Launch Cycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (application.applicationState == UIApplicationStateInactive) {
		[PMAccountStore sharedStore];
		[PMTagStore sharedStore];
		[PMBookmarkStore sharedStore];
	}
	
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (application.applicationState == UIApplicationStateInactive) {
#if defined(DEBUG) || defined(ADHOC)
		[BugshotKit enableWithNumberOfTouches:1 performingGestures:BSKInvocationGestureSwipeFromRightEdge feedbackEmailAddress:@"kyle@kilovolt42.com"];
#endif
		
		NSString *token = [PMAccountStore sharedStore].defaultToken;
		if (!token || [token isEqualToString:@""]) {
			PMAddAccountVC *addVC = [[PMAddAccountVC alloc] init];
			addVC.delegate = self;
			self.window.rootViewController = addVC;
		}
	}
	
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	UIViewController *viewController = self.window.rootViewController;
	if ([viewController isKindOfClass:[PMNavigationVC class]]) {
		PMNavigationVC *navigationVC = (PMNavigationVC *)viewController;
		[navigationVC openURL:url sourceApplication:sourceApplication annotation:annotation];
	}
	return YES;
}

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	return nil;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
	return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
	return YES;
}

#pragma mark - PMAddAccountVCDelegate

- (void)didFinishAddingAccount {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Pinmark" bundle:nil];
	self.window.rootViewController = [storyboard instantiateInitialViewController];
}

- (void)didFinishUpdatingAccount {
	[self didFinishAddingAccount];
}

- (BOOL)shouldAddAccountAsDefault {
	return YES;
}

@end
