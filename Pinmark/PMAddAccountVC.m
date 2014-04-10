//
//  PMAddAccountVC.m
//  Pinmarker
//
//  Created by Kyle Stevens on 1/14/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMAddAccountVC.h"
#import "PMAccountStore.h"

@interface PMAddAccountVC () <UIActionSheetDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *tokenTextField;
@property (nonatomic, weak) UIView *activeField;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (nonatomic, weak) IBOutlet UIButton *search1PasswordButton;
@property (nonatomic, weak) IBOutlet UIButton *informationButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *welcomeLabel;
@property (nonatomic, weak) IBOutlet UILabel *instructionsLabel;
@property (nonatomic, weak) IBOutlet UIView *formView;
@property (nonatomic) BOOL updatingExistingAccount;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *instructionsLabelTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *formViewTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *deleteButtonTopConstraint;
@end

@implementation PMAddAccountVC

#pragma mark - Properties

- (void)setUpdatingExistingAccount:(BOOL)updatingExistingAccount {
	_updatingExistingAccount = updatingExistingAccount;
	if (_updatingExistingAccount) {
		self.title = @"Update";
		self.instructionsLabel.text = @"To update, enter the new API token or the account password:";
		self.usernameTextField.enabled = NO;
		[self.submitButton setTitle:@"Update Account" forState:UIControlStateNormal];
		self.deleteButton.hidden = NO;
	} else {
		self.title = @"Add";
		self.instructionsLabel.text = @"Add a Pinboard account:";
		self.usernameTextField.enabled = YES;
		[self.submitButton setTitle:@"Add Account" forState:UIControlStateNormal];
		self.deleteButton.hidden = YES;
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	if (self.username) {
		self.usernameTextField.text = self.username;
		self.updatingExistingAccount = YES;
	} else {
		self.updatingExistingAccount = NO;
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)keyboardWillShow:(NSNotification *)notification {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	[UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	self.instructionsLabel.alpha = 0.0;
	self.deleteButton.alpha = 0.0;
	
	CGFloat displacement = self.instructionsLabel.frame.size.height;
	self.formViewTopConstraint.constant = -displacement;
	self.deleteButtonTopConstraint.constant = 2.0 * (displacement + 8.0);
	[self.view layoutIfNeeded];
	
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
	[UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	self.instructionsLabel.alpha = 1.0;
	self.deleteButton.alpha = 1.0;
	self.formViewTopConstraint.constant = 20.0;
	self.deleteButtonTopConstraint.constant = 8.0;
	[self.view layoutIfNeeded];
	
	[UIView commitAnimations];
}

- (void)disableFields {
	self.tokenTextField.enabled = NO;
	self.usernameTextField.enabled = NO;
	self.passwordTextField.enabled = NO;
	self.submitButton.enabled = NO;
	self.deleteButton.enabled = NO;
	self.search1PasswordButton.enabled = NO;
	self.informationButton.enabled = NO;
}

- (void)enableFields {
	self.tokenTextField.enabled = YES;
	self.usernameTextField.enabled = YES;
	self.passwordTextField.enabled = YES;
	self.submitButton.enabled = YES;
	self.deleteButton.enabled = YES;
	self.search1PasswordButton.enabled = YES;
	self.informationButton.enabled = YES;
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
	
	self.instructionsLabel.hidden = YES;
	self.instructionsLabel.text = @" ";
	[self.activeField resignFirstResponder];
	[self disableFields];
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
			if (error.code == -1001) {
				self.instructionsLabel.text = @"The connection timed out, please try again later.";
			} else {
				self.instructionsLabel.text = @"Please try again.";
			}
			self.instructionsLabel.hidden = NO;
			[self enableFields];
		} else {
			[self enableFields];
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
				if (error.code == -1001) {
					self.instructionsLabel.text = @"The connection timed out, please try again later.";
				} else {
					self.instructionsLabel.text = @"Please try again.";
				}
				self.instructionsLabel.hidden = NO;
				[self enableFields];
			}
		} else {
			[self enableFields];
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
				if (error.code == -1001) {
					self.instructionsLabel.text = @"The connection timed out, please try again later.";
				} else {
					self.instructionsLabel.text = @"Please try again.";
				}
				self.instructionsLabel.hidden = NO;
				[self enableFields];
			}
		} else {
			[self enableFields];
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
			if (self.updatingExistingAccount) {
				self.instructionsLabel.text = [NSString stringWithFormat:@"An API token or a password is required to update %@:", username];
			} else {
				self.instructionsLabel.text = [NSString stringWithFormat:@"An API token or a password is required to add %@:", username];
			}
			self.instructionsLabel.hidden = NO;
			[self enableFields];
		}
	} else {
		[self deactiveActivityIndicator];
		self.instructionsLabel.text = @"An API token or a username/password pair is required to add an account:";
		self.instructionsLabel.hidden = NO;
		[self enableFields];
	}
}

- (IBAction)deleteButtonPressed {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Are you sure you want to delete %@?", self.username]
													   delegate:self
											  cancelButtonTitle:@"Cancel"
										 destructiveButtonTitle:@"Delete Account"
											  otherButtonTitles:nil];
	[sheet showInView:self.view.window];
}

- (IBAction)search1PasswordButtonPressed {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"onepassword://search/pinboard"]];
}

- (IBAction)informationButtonPressed {
	[[[UIAlertView alloc] initWithTitle:@"About Your Account"
								message:@"Pinmarker securely stores your Pinboard API Token. Your password is not stored by Pinmarker and is only used to obtain a copy of your API Token. If your Pinboard API Token changes in the future you will need to update Pinmarker to continue bookmarking."
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil] show];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
		[self.delegate didRequestToRemoveAccountForUsername:self.username];
	}
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
