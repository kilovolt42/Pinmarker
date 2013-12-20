//
//  PMLoginVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/19/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMLoginVC.h"
#import <AFNetworking/AFNetworking.h>

@interface PMLoginVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end

@implementation PMLoginVC

- (void)viewDidLoad {
	[super viewDidLoad];
	self.activityIndicator.hidden = YES;
	self.usernameTextField.delegate = self;
	self.passwordTextField.delegate = self;
	[self.usernameTextField becomeFirstResponder];
}

- (void)activateActivityIndicator {
	[self.activityIndicator startAnimating];
	self.activityIndicator.hidden = NO;
}

- (void)deactiveActivityIndicator {
	self.activityIndicator.hidden = YES;
	[self.activityIndicator stopAnimating];
}

- (IBAction)login {
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.requestSerializer = [AFHTTPRequestSerializer serializer];
	manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
	__weak PMLoginVC *weakSelf = self;
	[self activateActivityIndicator];
	[manager GET:[NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/user/api_token", self.usernameTextField.text, self.passwordTextField.text]
	  parameters:@{ @"format": @"json" }
		 success:^(AFHTTPRequestOperation *operation, id responseObject) {
			 [weakSelf deactiveActivityIndicator];
			 NSLog(@"Response Object: %@", responseObject);
			 weakSelf.authToken = [NSString stringWithFormat:@"%@:%@", weakSelf.usernameTextField.text, responseObject[@"result"]];
			 [weakSelf performSegueWithIdentifier:@"Complete Login Segue" sender:weakSelf];
		 }
		 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			 [weakSelf deactiveActivityIndicator];
			 NSLog(@"Error: %@", error);
			 weakSelf.statusLabel.text = @"Try again!";
			 [weakSelf.statusLabel sizeToFit];
			 weakSelf.passwordTextField.text = @"";
			 [weakSelf.usernameTextField becomeFirstResponder];
		 }];
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
