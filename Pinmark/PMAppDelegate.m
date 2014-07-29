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
#import <TextExpander/SMTEDelegateController.h>

NSString * const PMTextExpanderEnabled = @"PMTextExpanderEnabled";
NSString * const PMTextExpanderRefreshDate = @"PMTextExpanderRefreshDate";
NSString * const PMTextExpanderRefreshCount = @"PMTextExpanderRefreshCount";

NSString * const PMTextExpanderGetSnippetsScheme = @"pinmarker-te-get-snippets";
NSString * const PMTextExpanderFillScheme = @"pinmarker-te-fill";

@interface PMAppDelegate () <PMAddAccountVCDelegate>

@end

@implementation PMAppDelegate

#pragma mark - Properties

@synthesize textExpander = _textExpander;

- (SMTEDelegateController *)textExpander {
	if (!_textExpander && [SMTEDelegateController isTextExpanderTouchInstalled]) {
		_textExpander = [[SMTEDelegateController alloc] init];
		_textExpander.clientAppName = @"Pinmarker";
		_textExpander.getSnippetsScheme = PMTextExpanderGetSnippetsScheme;
		_textExpander.fillCompletionScheme = PMTextExpanderFillScheme;
		_textExpander.expandPlainTextOnly = YES;
	}
	return _textExpander;
}

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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	BOOL result = YES;
	NSString *scheme = [url scheme];
	
	if ([scheme isEqualToString:PMTextExpanderGetSnippetsScheme]) {
		NSError *error = nil;
		BOOL cancelFlag = NO;
		
		result = [self.textExpander handleGetSnippetsURL:url error:&error cancelFlag:&cancelFlag];
		
		if (!error && !cancelFlag) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setBool:YES forKey:PMTextExpanderEnabled];
			
			NSUInteger snippetCount = 0;
			NSDate *loadDate = nil;
			
			BOOL enabled = [SMTEDelegateController expansionStatusForceLoad:NO snippetCount:&snippetCount loadDate:&loadDate error:nil];
			
			if (enabled) {
				if (snippetCount > 0 && loadDate) {
					[defaults setInteger:snippetCount forKey:PMTextExpanderRefreshCount];
					[defaults setObject:loadDate forKey:PMTextExpanderRefreshDate];
				}
			}
			
			[defaults synchronize];
			[SMTEDelegateController setExpansionEnabled:YES];
		}
	}
	
	if ([SMTEDelegateController textExpanderTouchSupportsFillins] && [scheme isEqualToString:PMTextExpanderFillScheme]) {
		[self.textExpander handleFillCompletionURL:url];
	}
	
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
