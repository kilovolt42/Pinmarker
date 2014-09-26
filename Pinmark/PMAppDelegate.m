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
#import "PMPinboardService.h"

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
		NSString *username = [PMAccountStore sharedStore].defaultUsername;
		if (!username || [username isEqualToString:@""]) {
			PMAddAccountVC *addVC = [[PMAddAccountVC alloc] init];
			addVC.delegate = self;
			self.window.rootViewController = addVC;
		}
	}
	
	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	NSArray *usernames = [PMAccountStore sharedStore].associatedUsernames;
	for (NSString *username in usernames) {
		NSString *token = [[PMAccountStore sharedStore] authTokenForUsername:username];
		if (token) {
			void (^success)(NSDictionary *) = ^(NSDictionary *tags) {
				NSArray *sortedTags = [[[tags keysSortedByValueUsingSelector:@selector(compare:)] reverseObjectEnumerator] allObjects];
				[[PMTagStore sharedStore] updateTags:sortedTags username:username];
			};
			
			[PMPinboardService requestTagsForAPIToken:token success:success failure:nil];
		}
	}
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	BOOL result = YES;
	UIViewController *viewController = self.window.rootViewController;
	if ([viewController isKindOfClass:[PMNavigationVC class]]) {
		PMNavigationVC *navigationVC = (PMNavigationVC *)viewController;
		[navigationVC openURL:url sourceApplication:sourceApplication annotation:annotation];
	}
	
	return result;
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
