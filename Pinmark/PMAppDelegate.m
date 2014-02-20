//
//  PMAppDelegate.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/13/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMAppDelegate.h"
#import "PMNavigationVC.h"
#import "BugshotKit.h"
#import "TestFlight.h"

NSString * const PMDidInitializeDefaults = @"PMDidInitializeDefaults";
NSString * const PMAssociatedTokensKey = @"PMAssociatedTokensKey";
NSString * const PMDefaultTokenKey = @"PMDefaultTokenKey";
NSString * const PMPasteboardPreferenceKey = @"PMPasteboardPreferenceKey";

@implementation PMAppDelegate

#pragma mark - Launch Cycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (application.applicationState == UIApplicationStateInactive) {
		if (![[NSUserDefaults standardUserDefaults] boolForKey:PMDidInitializeDefaults]) {
			[self initializeDefaults];
		}
	}
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (application.applicationState == UIApplicationStateInactive) {
		[TestFlight takeOff:@"b04f90cd-6ff4-4fea-a5f8-52493618c772"];
		[BugshotKit enableWithNumberOfTouches:1 performingGestures:BSKInvocationGestureSwipeFromRightEdge feedbackEmailAddress:@"kyle@kilovolt42.com"];
	}
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	UIViewController *viewController = self.window.rootViewController;
	if ([viewController isKindOfClass:[PMNavigationVC class]]) {
		PMNavigationVC *navigationVC = (PMNavigationVC *)viewController;
		[navigationVC openURL:url sourceApplication:sourceApplication annotation:annotation];
	}
	return YES;
}

#pragma mark - Methods

- (void)initializeDefaults {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:PMPasteboardPreferenceKey];
	[userDefaults setBool:YES forKey:PMDidInitializeDefaults];
}

@end
