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
#import "PMTagsTVCell.h"

@interface PMNewPinTVC () <UITextFieldDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *URLTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@property (weak, nonatomic) IBOutlet UITextView *extendedTextView;
@property (weak, nonatomic) IBOutlet UISwitch *toReadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sharedSwitch;
@property (weak, nonatomic) id activeField;
@property (strong, nonatomic) PMPinboardManager *manager;
@property (nonatomic, copy) void (^xSuccess)(AFHTTPRequestOperation *, id);
@property (nonatomic, copy) void (^xFailure)(AFHTTPRequestOperation *, NSError *);
@property (strong, nonatomic) NSString *dt;
@property (strong, nonatomic) NSString *replace;
@property (weak, nonatomic) IBOutlet PMTagsTVCell *tagsTVCell;
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
	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"url": self.URLTextField.text,
																					   @"description": self.descriptionTextField.text,
																					   @"extended": self.extendedTextView.text,
																					   @"tags": self.tagsTextField.text,
																					   @"shared": self.sharedSwitch.on ? @"no" : @"yes",
																					   @"toread": self.toReadSwitch.on ? @"yes" : @"no" }];
	if (self.dt) parameters[@"dt"] = self.dt;
	if (self.replace) parameters[@"replace"] = self.replace;
	
	__weak PMNewPinTVC *weakSelf = self;
	
	[self.manager add:parameters
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
				  weakSelf.navigationItem.rightBarButtonItem = sender;
				  NSString *resultCode = responseObject[@"result_code"];
				  if (resultCode) {
					  if ([resultCode isEqualToString:@"done"]) {
						  [weakSelf reportSuccess];
						  if (weakSelf.xSuccess) weakSelf.xSuccess(operation, responseObject);
					  }
					  else if ([resultCode isEqualToString:@"missing url"]) [weakSelf reportErrorWithMessage:@"Missing URL"];
					  else if ([resultCode isEqualToString:@"must provide title"]) [weakSelf reportErrorWithMessage:@"Missing Title"];
					  else if ([resultCode isEqualToString:@"item already exists"]) [weakSelf reportErrorWithMessage:@"Already Bookmarked"];
					  else [weakSelf reportErrorWithMessage:nil];
				  }
			  }
			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				  weakSelf.navigationItem.rightBarButtonItem = sender;
				  [weakSelf reportErrorWithMessage:nil];
				  if (weakSelf.xFailure) weakSelf.xFailure(operation, error);
			  }];
}

#pragma mark - Methods

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	NSString *command = [url lastPathComponent];
	NSString *host = [url host];
	NSDictionary *parameters = [url queryParameters];
	NSDictionary *pinboardParameters = [PMPinboardManager pinboardSpecificParametersFromParameters:parameters];
	
	if (![command isEqualToString:@"add"]) {
		return;
	}
	
	if (!pinboardParameters[@"auth_token"] && !self.manager.authToken) {
		[self login];
	}
	
	if ([host isEqualToString:@"x-callback-url"]) {
		if (parameters[@"x-success"]) {
			self.xSuccess = ^void(AFHTTPRequestOperation *operation, id responseObject) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[parameters[@"x-success"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
			};
		}
		if (parameters[@"x-error"]) {
			self.xFailure = ^void(AFHTTPRequestOperation *operation, NSError *error) {
				NSString *xError = [NSString stringWithFormat:@"%@?errorCode=%ld&errorMessage=%@", parameters[@"x-error"], (long)[error code], [error domain]];
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[xError stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
			};
		}
	} else {
		self.xSuccess = nil;
		self.xFailure = nil;
	}
	
	if (parameters[@"wait"] && [parameters[@"wait"] isEqualToString:@"no"]) {
		[self.manager add:pinboardParameters success:self.xSuccess failure:self.xFailure];
	} else {
		self.URLTextField.text = pinboardParameters[@"url"];
		self.descriptionTextField.text = pinboardParameters[@"description"];
		self.tagsTextField.text = pinboardParameters[@"tags"];
		[self updateSuggestedTagsForURL:pinboardParameters[@"url"]];
		self.extendedTextView.text = pinboardParameters[@"extended"];
		if ([pinboardParameters[@"toread"] isEqualToString:@"yes"]) self.toReadSwitch.on = YES;
		else self.toReadSwitch.on = NO;
		if ([pinboardParameters[@"shared"] isEqualToString:@"no"]) self.sharedSwitch.on = YES;
		else self.sharedSwitch.on = NO;
		self.dt = pinboardParameters[@"dt"];
		self.replace = pinboardParameters[@"replace"];
	}
}

#pragma mark -

- (void)updateSuggestedTagsForURL:(NSString *)url {
	__weak PMNewPinTVC *weakSelf = self;
	[self.manager requestRecommendedTags:@{ @"url": url }
								 success:^(NSArray *recommendedTags) { weakSelf.tagsTVCell.tags = recommendedTags; }
								 failure:nil];
}

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
	self.dt = nil;
	self.replace = nil;
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
	if (self.activeField == self.URLTextField) [self updateSuggestedTagsForURL:self.URLTextField.text];
	self.activeField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.URLTextField) {
		[self.descriptionTextField becomeFirstResponder];
		[self updateSuggestedTagsForURL:self.URLTextField.text];
	} else if (textField == self.descriptionTextField) [self.tagsTextField becomeFirstResponder];
	else if (textField == self.tagsTextField) [self.extendedTextView becomeFirstResponder];
	return NO;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
	self.activeField = textView;
}

@end
