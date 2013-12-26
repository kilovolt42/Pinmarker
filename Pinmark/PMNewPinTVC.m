//
//  PMNewPinTVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/16/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMNewPinTVC.h"
#import <AFNetworking/AFNetworking.h>
#import "PMLoginVC.h"
#import "PMPinboardManager.h"
#import "NSURL+Pinmark.h"

@interface PMNewPinTVC () <UITextFieldDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *URLTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@property (weak, nonatomic) IBOutlet UITextView *extendedTextView;
@property (weak, nonatomic) IBOutlet UISwitch *toReadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sharedSwitch;
@property (weak, nonatomic) id activeField;
@property (strong, nonatomic) PMPinboardManager *manager;
@property (strong, nonatomic) NSString *xCallbackSuccess;
@end

@implementation PMNewPinTVC

#pragma mark - Properties

- (PMPinboardManager *)manager {
	if (!_manager) _manager = [PMPinboardManager new];
	return _manager;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.URLTextField.delegate = self;
	self.descriptionTextField.delegate = self;
	self.tagsTextField.delegate = self;
	self.extendedTextView.delegate = self;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.view addGestureRecognizer:tap];
	[self.navigationController.view addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (!self.manager.authToken) [self login];
	self.title = self.manager.username;
}

#pragma mark - IBAction

- (IBAction)completeLogin:(UIStoryboardSegue *)segue {	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

- (IBAction)pin:(UIBarButtonItem *)sender {
	if (![self isReadyToPin]) return;
	
	UIActivityIndicatorView *indicatorButton = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[indicatorButton startAnimating];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorButton];
	
	NSDictionary *parameters = @{ @"url": self.URLTextField.text,
								  @"description": self.descriptionTextField.text,
								  @"extended": self.extendedTextView.text,
								  @"tags": self.tagsTextField.text,
								  @"shared": self.sharedSwitch.on ? @"no" : @"yes",
								  @"toread": self.toReadSwitch.on ? @"yes" : @"no" };
	
	__weak PMNewPinTVC *weakSelf = self;
	
	[self.manager add:parameters
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
				  weakSelf.navigationItem.rightBarButtonItem = sender;
				  NSString *resultCode = responseObject[@"result_code"];
				  if (resultCode) {
					  if ([resultCode isEqualToString:@"done"]) [weakSelf reportSuccess];
					  else if ([resultCode isEqualToString:@"missing url"]) [weakSelf reportErrorWithMessage:@"Missing URL"];
					  else if ([resultCode isEqualToString:@"must provide title"]) [weakSelf reportErrorWithMessage:@"Missing Title"];
					  else [weakSelf reportErrorWithMessage:nil];
				  }
			  }
			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				  weakSelf.navigationItem.rightBarButtonItem = sender;
				  [weakSelf reportErrorWithMessage:nil];
			  }];
}

#pragma mark - Methods

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	self.xCallbackSuccess = nil;
	
	NSMutableDictionary *parameters = [NSMutableDictionary new];
	for (NSString *parameter in [[url query] componentsSeparatedByString:@"&"]) {
		NSArray *fieldValuePair = [parameter componentsSeparatedByString:@"="];
		NSString *field = [fieldValuePair[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *value = [fieldValuePair[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		parameters[field] = value;
	}
	
	if ([[url lastPathComponent] isEqualToString:@"add"]) {
		if ([[url host] isEqualToString:@"x-callback-url"]) {
			self.xCallbackSuccess = parameters[@"x-success"];
			if ([parameters[@"fast"] isEqualToString:@"yes"]) {
				[self.manager add:@{ @"url": parameters[@"url"],
												   @"description": parameters[@"description"] }
						  success:nil
						  failure:nil];
				return;
			}
		}
		self.URLTextField.text = parameters[@"url"];
		self.descriptionTextField.text = parameters[@"description"];
		self.extendedTextView.text = parameters[@"extended"];
	}
}

#pragma mark -

- (void)login {
	[self.navigationController performSegueWithIdentifier:@"Login Segue" sender:self];
}

- (BOOL)isReadyToPin {
	if ([self.URLTextField.text isEqualToString:@""]) {
		[self reportErrorWithMessage:@"URL Required"];
		[self.URLTextField becomeFirstResponder];
		return NO;
	} else if ([self.descriptionTextField.text isEqualToString:@""]) {
		[self reportErrorWithMessage:@"Title Required"];
		[self.descriptionTextField becomeFirstResponder];
		return NO;
	}
	return YES;
}

- (void)reportSuccess {
	self.title = @"Success";
	self.navigationController.navigationBar.barTintColor = [UIColor greenColor];
	[self performSelector:@selector(resetNavigationBar) withObject:self afterDelay:2.0];
	[self clearFields];
}

- (void)reportErrorWithMessage:(NSString *)message {
	self.title = message ? message : @"Error";
	self.navigationController.navigationBar.barTintColor = [UIColor redColor];
	[self performSelector:@selector(resetNavigationBar) withObject:self afterDelay:2.0];
}

- (void)resetNavigationBar {
	self.title = self.manager.username;
	self.navigationController.navigationBar.barTintColor = nil;
}

- (void)clearFields {
	self.URLTextField.text = @"";
	self.descriptionTextField.text = @"";
	self.tagsTextField.text = @"";
	self.extendedTextView.text = @"";
	self.toReadSwitch.on = NO;
	self.sharedSwitch.on = NO;
	[self.activeField resignFirstResponder];
}

- (void)dismissKeyboard {
	[self.activeField resignFirstResponder];
	self.activeField = nil;
}

#pragma mark - UITableViewDataSource

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0.1;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.activeField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.URLTextField) [self.descriptionTextField becomeFirstResponder];
	else if (textField == self.descriptionTextField) [self.tagsTextField becomeFirstResponder];
	else if (textField == self.tagsTextField) [self.extendedTextView becomeFirstResponder];
	return NO;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
	self.activeField = textView;
}

@end
