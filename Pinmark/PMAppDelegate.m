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

- (void)initializeDefaults {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:PMPasteboardPreferenceKey];
	[userDefaults setBool:YES forKey:PMDidInitializeDefaults];
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:PMDidInitializeDefaults]) {
		[self initializeDefaults];
	}
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[TestFlight takeOff:@"b04f90cd-6ff4-4fea-a5f8-52493618c772"];
	[BugshotKit enableWithNumberOfTouches:1 performingGestures:BSKInvocationGestureSwipeFromRightEdge feedbackEmailAddress:@"kyle@kilovolt42.com"];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	UIViewController *viewController = self.window.rootViewController;
	if ([viewController isKindOfClass:[PMNavigationVC class]]) {
		PMNavigationVC *navigationVC = (PMNavigationVC *)viewController;
		[navigationVC openURL:url sourceApplication:sourceApplication annotation:annotation];
	}
	return YES;
}

@end
