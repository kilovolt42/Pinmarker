//
//  PMAppDelegate.m
//  Pinmarker
//
//  Created by Kyle Stevens on 12/13/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMAppDelegate.h"
#import "PMNavigationVC.h"
#import "BugshotKit.h"
#import "TestFlight.h"
#import "PMAccountStore.h"
#import "PMAddAccountVC.h"
#import "PMTagStore.h"
#import "PMBookmarkStore.h"

NSString * const PMDidInitializeDefaults = @"PMDidInitializeDefaults";
NSString * const PMAssociatedTokensKey = @"PMAssociatedTokensKey";
NSString * const PMDefaultTokenKey = @"PMDefaultTokenKey";
NSString * const PMPasteboardPreferenceKey = @"PMPasteboardPreferenceKey";

@interface PMAppDelegate () <PMAddAccountVCDelegate>

@end

@implementation PMAppDelegate

#pragma mark - Launch Cycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (application.applicationState == UIApplicationStateInactive) {
		if (![[NSUserDefaults standardUserDefaults] boolForKey:PMDidInitializeDefaults]) {
			[self initializeDefaults];
			
			[PMAccountStore sharedStore];
			[PMTagStore sharedStore];
			[PMBookmarkStore sharedStore];
		}
	}
	
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (application.applicationState == UIApplicationStateInactive) {
		[TestFlight takeOff:@"b04f90cd-6ff4-4fea-a5f8-52493618c772"];
		[BugshotKit enableWithNumberOfTouches:1 performingGestures:BSKInvocationGestureSwipeFromRightEdge feedbackEmailAddress:@"kyle@kilovolt42.com"];
		
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

#pragma mark - Methods

- (void)initializeDefaults {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:PMPasteboardPreferenceKey];
	[userDefaults setBool:YES forKey:PMDidInitializeDefaults];
	[userDefaults synchronize];
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
