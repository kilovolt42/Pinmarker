//
//  PMAddAccountVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/14/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMAddAccountVC.h"
#import "PMPinboardManager.h"

@interface PMAddAccountVC () <UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *tokenTextField;
@property (nonatomic, weak) UIView *activeField;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;
@property (nonatomic, weak) IBOutlet UIButton *search1PasswordButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@end

@implementation PMAddAccountVC

#pragma mark - Life Cycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self deactiveActivityIndicator];
	self.usernameTextField.delegate = self;
	self.passwordTextField.delegate = self;
	self.tokenTextField.delegate = self;
	
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"onepassword://search"]]) {
		self.search1PasswordButton.hidden = NO;
	} else {
		self.search1PasswordButton.hidden = YES;
	}
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
		[self.view addGestureRecognizer:tap];
	}
}

- (BOOL)disablesAutomaticKeyboardDismissal {
	return NO;
}

#pragma mark - Methods

- (void)activateActivityIndicator {
	[self.activityIndicator startAnimating];
	self.activityIndicator.hidden = NO;
}

- (void)deactiveActivityIndicator {
	self.activityIndicator.hidden = YES;
	[self.activityIndicator stopAnimating];
}

- (void)dismissKeyboard {
	[self.activeField resignFirstResponder];
	self.activeField = nil;
}

#pragma mark - Actions

/*
 *  It is possible for the user to input multiple usernames, one in the username text field and one
 *  as part of the API Token text field with the format username:key. For the provided user input,
 *  this method attempts to login in the following order:
 *
 *  1) Using only the API Token text
 *  2) Using the username text concatenated with the API Token text
 *  3) Using the username and password text
 *
 *  If none of these attempts are successful the user is notified to try again.
 */
- (IBAction)submitButtonPressed {
	PMPinboardManager *manager = [PMPinboardManager sharedManager];
	
	self.statusLabel.text = @"";
	[self.activeField resignFirstResponder];
	[self activateActivityIndicator];
	
	NSString *username = self.usernameTextField.text;
	NSString *password = self.passwordTextField.text;
	NSString *token = self.tokenTextField.text;
	BOOL didProvideTwoUsernames = NO;
	
	if ([username isEqualToString:@""]) username = nil;
	if ([password isEqualToString:@""]) password = nil;
	if ([token isEqualToString:@""]) token = nil;
	
	NSArray *tokenComponents = [token componentsSeparatedByString:@":"];
	if ([tokenComponents count] > 2) {
		token = nil;
	} else if ([tokenComponents count] == 2) {
		didProvideTwoUsernames = YES;
	} else if (token) {
		token = [username stringByAppendingFormat:@":%@", token];
	}
	
	__weak PMAddAccountVC *weakSelf = self;
	
	void (^usernamePasswordCompletionHandler)(NSError *) = ^(NSError *error) {
		[weakSelf deactiveActivityIndicator];
		if (error) {
			weakSelf.statusLabel.text = @"Please try again";
		} else {
			[self.delegate didFinishAddingAccount];
		}
	};
	
	void (^usernameTokenCompletionHandler)(NSError *) = ^(NSError *error) {
		[weakSelf deactiveActivityIndicator];
		if (error) {
			if (password) {
				[self activateActivityIndicator];
				[manager addAccountForUsername:username
									  password:password
									 asDefault:[self.delegate shouldAddAccountAsDefault]
							 completionHandler:usernamePasswordCompletionHandler];
			} else {
				weakSelf.statusLabel.text = @"Please try again";
			}
		} else {
			[self.delegate didFinishAddingAccount];
		}
	};
	
	void (^tokenCompletionHandler)(NSError *) = ^(NSError *error) {
		[weakSelf deactiveActivityIndicator];
		if (error) {
			if (username) {
				[self activateActivityIndicator];
				NSString *usernameToken = [username stringByAppendingFormat:@":%@", tokenComponents[1]];
				[manager addAccountForAPIToken:usernameToken
									 asDefault:[self.delegate shouldAddAccountAsDefault]
							 completionHandler:usernameTokenCompletionHandler];
			} else {
				weakSelf.statusLabel.text = @"Please try again";
			}
		} else {
			[self.delegate didFinishAddingAccount];
		}
	};
	
	if (didProvideTwoUsernames) {
		[manager addAccountForAPIToken:token asDefault:YES completionHandler:tokenCompletionHandler];
	} else if (username) {
		if (token) {
			NSString *usernameToken = [username stringByAppendingFormat:@":%@", tokenComponents[0]];
			[manager addAccountForAPIToken:usernameToken asDefault:YES completionHandler:usernameTokenCompletionHandler];
		} else if (password) {
			[manager addAccountForUsername:username
								  password:password
								 asDefault:[self.delegate shouldAddAccountAsDefault]
						 completionHandler:usernamePasswordCompletionHandler];
		} else {
			[weakSelf deactiveActivityIndicator];
			self.statusLabel.text = @"Password or API Token required";
		}
	} else {
		[weakSelf deactiveActivityIndicator];
		self.statusLabel.text = @"Username or API Token required";
	}
}

- (IBAction)search1PasswordButtonPressed {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"onepassword://search/pinboard"]];
}

- (IBAction)informationButtonPressed {
	[[[UIAlertView alloc] initWithTitle:@"About Your Account"
							   message:@"Pinmark uses your password to obtain your API token. Pinmark only keeps a copy of your API token, not your password. If you change your API token you will need to login again to continue using Pinmark."
							  delegate:nil
					 cancelButtonTitle:@"OK"
					 otherButtonTitles:nil] show];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.activeField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.usernameTextField) {
		[self.passwordTextField becomeFirstResponder];
	}
	if (textField == self.passwordTextField) {
		[textField resignFirstResponder];
		if ([textField.text length]) {
			[self submitButtonPressed];
		}
	}
	if (textField == self.tokenTextField) {
		[textField resignFirstResponder];
		if ([textField.text length]) {
			[self submitButtonPressed];
		}
	}
	return YES;
}

@end
