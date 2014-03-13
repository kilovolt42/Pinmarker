//
//  PMAddAccountVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/14/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMAddAccountVC.h"
#import "PMAccountStore.h"

@interface PMAddAccountVC () <UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *tokenTextField;
@property (nonatomic, weak) UIView *activeField;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;
@property (nonatomic, weak) IBOutlet UIButton *search1PasswordButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic) BOOL updatingExistingAccount;
@end

@implementation PMAddAccountVC

#pragma mark - Properties

- (void)setUpdatingExistingAccount:(BOOL)updatingExistingAccount {
	if (_updatingExistingAccount == updatingExistingAccount) {
		return;
	}
	
	_updatingExistingAccount = updatingExistingAccount;
	
	if (_updatingExistingAccount) {
		self.title = @"Update";
		self.usernameTextField.enabled = NO;
		[self.submitButton setTitle:@"Update Account" forState:UIControlStateNormal];
	} else {
		self.title = @"Add";
		self.usernameTextField.enabled = YES;
		[self.submitButton setTitle:@"Add Account" forState:UIControlStateNormal];
	}
}

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

- (void)viewWillAppear:(BOOL)animated {
	if (self.username) {
		self.usernameTextField.text = self.username;
		self.updatingExistingAccount = YES;
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

- (void)finish {
	if (self.updatingExistingAccount) {
		[self.delegate didFinishUpdatingAccount];
	} else {
		[self.delegate didFinishAddingAccount];
	}
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
	PMAccountStore *store = [PMAccountStore sharedStore];
	
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
	
	BOOL asDefault = [self.delegate shouldAddAccountAsDefault];
	
	void (^usernamePasswordCompletionHandler)(NSError *) = ^(NSError *error) {
		[self deactiveActivityIndicator];
		if (error) {
			self.statusLabel.text = @"Please try again";
		} else {
			[self finish];
		}
	};
	
	void (^usernameTokenCompletionHandler)(NSError *) = ^(NSError *error) {
		[self deactiveActivityIndicator];
		if (error) {
			if (password) {
				[self activateActivityIndicator];
				if (self.updatingExistingAccount) {
					[store updateAccountForUsername:username password:password asDefault:asDefault completionHandler:usernamePasswordCompletionHandler];
				} else {
					[store addAccountForUsername:username password:password asDefault:asDefault completionHandler:usernamePasswordCompletionHandler];
				}
			} else {
				self.statusLabel.text = @"Please try again";
			}
		} else {
			[self finish];
		}
	};
	
	void (^tokenCompletionHandler)(NSError *) = ^(NSError *error) {
		[self deactiveActivityIndicator];
		if (error) {
			if (username) {
				[self activateActivityIndicator];
				NSString *usernameToken = [username stringByAppendingFormat:@":%@", tokenComponents[1]];
				if (self.updatingExistingAccount) {
					[store updateAccountForAPIToken:usernameToken asDefault:asDefault completionHandler:usernameTokenCompletionHandler];
				} else {
					[store addAccountForAPIToken:usernameToken asDefault:asDefault completionHandler:usernameTokenCompletionHandler];
				}
			} else {
				self.statusLabel.text = @"Please try again";
			}
		} else {
			[self finish];
		}
	};
	
	if (didProvideTwoUsernames) {
		if (self.updatingExistingAccount) {
			[store updateAccountForAPIToken:token asDefault:asDefault completionHandler:tokenCompletionHandler];
		} else {
			[store addAccountForAPIToken:token asDefault:asDefault completionHandler:tokenCompletionHandler];
		}
	} else if (username) {
		if (token) {
			NSString *usernameToken = [username stringByAppendingFormat:@":%@", tokenComponents[0]];
			if (self.updatingExistingAccount) {
				[store updateAccountForAPIToken:username asDefault:asDefault completionHandler:usernameTokenCompletionHandler];
			} else {
				[store addAccountForAPIToken:usernameToken asDefault:asDefault completionHandler:usernameTokenCompletionHandler];
			}
		} else if (password) {
			if (self.updatingExistingAccount) {
				[store updateAccountForUsername:username password:password asDefault:asDefault completionHandler:usernamePasswordCompletionHandler];
			} else {
				[store addAccountForUsername:username password:password asDefault:asDefault completionHandler:usernamePasswordCompletionHandler];
			}
		} else {
			[self deactiveActivityIndicator];
			self.statusLabel.text = @"Password or API Token required";
		}
	} else {
		[self deactiveActivityIndicator];
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
