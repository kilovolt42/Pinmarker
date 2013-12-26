//
//  PMLoginVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/19/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMLoginVC.h"
#import "PMPinboardManager.h"

@interface PMLoginVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) PMPinboardManager *manager;
@end

@implementation PMLoginVC

#pragma mark - Properties

- (PMPinboardManager *)manager {
	if (!_manager) _manager = [PMPinboardManager new];
	return _manager;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.activityIndicator.hidden = YES;
	self.usernameTextField.delegate = self;
	self.passwordTextField.delegate = self;
	[self.usernameTextField becomeFirstResponder];
}

#pragma mark - IBAction

- (IBAction)login {
	__weak PMLoginVC *weakSelf = self;
	[self activateActivityIndicator];
	
	[self.manager addAccountForUsername:self.usernameTextField.text password:self.passwordTextField.text completionHandler:^(NSError *error) {
		[weakSelf deactiveActivityIndicator];
		if (error) {
			weakSelf.statusLabel.text = @"Try again!";
			[weakSelf.statusLabel sizeToFit];
			weakSelf.passwordTextField.text = @"";
			[weakSelf.usernameTextField becomeFirstResponder];
		} else {
			[weakSelf performSegueWithIdentifier:@"Complete Login Segue" sender:weakSelf];
		}
	}];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.usernameTextField) [self.passwordTextField becomeFirstResponder];
	else if (textField == self.passwordTextField) {
		[self.passwordTextField resignFirstResponder];
		[self login];
	}
	return NO;
}

@end
