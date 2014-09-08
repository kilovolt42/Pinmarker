//
//  PMNewPinTVC.m
//  Pinmarker
//
//  Created by Kyle Stevens on 12/16/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMNewPinTVC.h"
#import "NSURL+Pinmark.h"
#import "NSString+Pinmark.h"
#import "PMTagsController.h"
#import "PMBookmark.h"
#import "PMBookmarkStore.h"
#import "PMTagStore.h"
#import "PMAccountStore.h"
#import "PMSettingsTVC.h"
#import "PMAppDelegate.h"

static void * PMNewPinTVCContext = &PMNewPinTVCContext;

static const NSUInteger PMURLCellIndex = 0;
static const NSUInteger PMTagsCellIndex = 2;

@interface PMNewPinTVC () <UINavigationControllerDelegate, PMSettingsTVCDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UITextField *URLTextField;
@property (weak, nonatomic) IBOutlet UILabel *datePostedLabel;
@property (nonatomic, weak) IBOutlet UITextField *titleTextField;
@property (nonatomic, weak) IBOutlet UITextField *extendedTextField;
@property (nonatomic) IBOutlet PMTagsController *tagsController;
@property (nonatomic, weak) IBOutlet UISwitch *toReadSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *sharedSwitch;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tagsVerticalConstraint;
@property (nonatomic, weak) id activeField;
@property (nonatomic, copy) void (^xSuccess)(id);
@property (nonatomic, copy) void (^xFailure)(NSError *, id);
@property (nonatomic) PMBookmark *bookmark;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *postButton;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation PMNewPinTVC

#pragma mark - Properties

- (void)setBookmark:(PMBookmark *)bookmark {
	if (_bookmark) {
		[self removeBookmarkObservers];
	}
	
	_bookmark = bookmark;
	self.tagsController.bookmark = _bookmark;
	
	if (_bookmark) {
		[self addBookmarkObservers];
		[self updateFields];
	}
	
	[[PMTagStore sharedStore] markTagsDirtyForUsername:_bookmark.username];
}

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateStyle = NSDateFormatterLongStyle;
	}
	return _dateFormatter;
}

#pragma mark - Life Cycle

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	UIViewController *vc = nil;
	
	UIStoryboard *storyboard = [coder decodeObjectForKey:UIStateRestorationViewControllerStoryboardKey];
	if (storyboard) {
		vc = (PMNewPinTVC *)[storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
		vc.restorationClass = [self class];
	}
	
	return vc;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.restorationClass = [self class];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	
	self.URLTextField.delegate = self;
	self.titleTextField.delegate = self;
	self.extendedTextField.delegate = self;
	
	self.bookmark = [[PMBookmarkStore sharedStore] lastBookmark];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
	if (selected) {
		[self.tableView deselectRowAtIndexPath:selected animated:YES];
	}
	
	[self.tableView reloadData];
	[self updateFields];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self updateTitleButton];
}

- (void)dealloc {
	[self removeBookmarkObservers];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[self dismissKeyboard];
	if ([segue.identifier isEqualToString:@"Settings"]) {
		UINavigationController *nc = (UINavigationController *)segue.destinationViewController;
		PMSettingsTVC *stvc = [nc.viewControllers firstObject];
		stvc.delegate = self;
	}
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	[self updateFields];
}

#pragma mark -

- (void)applicationWillResignActive:(NSNotification *)notification {
	[self dismissKeyboard];
}

- (void)addBookmarkObservers {
	[_bookmark addObserver:self forKeyPath:@"postable" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"username" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"lastPosted" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"tags" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
}

- (void)removeBookmarkObservers {
	[self.bookmark removeObserver:self forKeyPath:@"postable" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"username" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"lastPosted" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"title" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"tags"];
}

#pragma mark - Actions

- (IBAction)pin:(UIBarButtonItem *)sender {
	[self dismissKeyboard]; // makes sure text field ends editing and saves text to bookmark
	
	[self fieldsEnabled:NO];
	UIActivityIndicatorView *indicatorButton = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[indicatorButton startAnimating];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorButton];
	
	NSDictionary *responseDictionary = @{ @"missing url" : @"Invalid URL",
										  @"must provide title" : @"Missing Title",
										  @"item already exists" : @"Already Bookmarked" };
	
	PMBookmarkStore *store = [PMBookmarkStore sharedStore];
	[store postBookmark:self.bookmark
				success:^(id responseObject) {
					self.navigationItem.rightBarButtonItem = sender;
					[self fieldsEnabled:YES];
					[self reportSuccess];
					self.bookmark = [store lastBookmark];
					if (self.xSuccess) {
						self.xSuccess(responseObject);
					}
				}
				failure:^(NSError *error, id responseObject) {
					self.navigationItem.rightBarButtonItem = sender;
					[self fieldsEnabled:YES];
					if (responseObject) {
						NSString *resultCode = responseObject[@"result_code"];
						[self reportErrorWithMessage:responseDictionary[resultCode]];
					} else {
						[self reportErrorWithMessage:nil];
					}
					if (self.xFailure) self.xFailure(error, responseObject);
				}];
}

- (IBAction)URLTextFieldEditingChanged:(UITextField *)textField {
	if ([textField.text isEqualToString:@""]) {
		self.bookmark.url = @"";
	}
}

- (IBAction)titleTextFieldEditingChanged:(UITextField *)textField {
	self.bookmark.title = textField.text;
}

- (IBAction)extendedTextFieldEditingChanged:(UITextField *)textField {
	self.bookmark.extended = textField.text;
}

- (IBAction)toggledToReadSwitch:(UISwitch *)sender {
	self.bookmark.toread = sender.on;
}

- (IBAction)toggledSharedSwitch:(UISwitch *)sender {
	self.bookmark.shared = !sender.on;
}

- (void)showUsernameSheet:(id)sender {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
													   delegate:self
											  cancelButtonTitle:nil
										 destructiveButtonTitle:nil
											  otherButtonTitles:nil];
	
	NSArray *usernames = [PMAccountStore sharedStore].associatedUsernames;
	
	for (NSString *username in usernames) {
		[sheet addButtonWithTitle:username];
	}
	
	[sheet addButtonWithTitle:@"Cancel"];
	sheet.cancelButtonIndex = [usernames count];
	
	[sheet showInView:self.view.window];
}

#pragma mark - Methods

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	NSString *host = [url host];
	NSString *command;
	
	if ([[url path] isEqualToString:@""]) {
		command = host;
	} else {
		command = [url lastPathComponent];
	}
	
	if (![command isEqualToString:@"add"]) {
		return;
	}
	
	NSDictionary *parameters = [url queryParameters];
	
	__weak PMNewPinTVC *weakSelf = self;
	PMBookmarkStore *bookmarkStore = [PMBookmarkStore sharedStore];
	
	if ([host isEqualToString:@"x-callback-url"]) {
		if (parameters[@"x-success"]) {
			self.xSuccess = ^void(id responseObject) {
				weakSelf.bookmark = [bookmarkStore lastBookmark];
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:parameters[@"x-success"]]];
			};
		}
		if (parameters[@"x-error"]) {
			self.xFailure = ^void(NSError *error, id responseObject) {
				NSString *xError = [NSString stringWithFormat:@"%@?errorCode=%ld&errorMessage=%@", parameters[@"x-error"], (long)[error code], [error domain]];
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:xError]];
			};
		}
	} else {
		self.xSuccess = nil;
		self.xFailure = nil;
	}
	
	self.bookmark = [[PMBookmarkStore sharedStore] createBookmarkWithParameters:parameters];
	
	if (parameters[@"wait"] && [parameters[@"wait"] isEqualToString:@"no"]) {
		[[PMBookmarkStore sharedStore] postBookmark:self.bookmark success:self.xSuccess failure:self.xFailure];
	}
}

#pragma mark -

- (void)updateFields {
	self.URLTextField.text = self.bookmark.url;
	self.titleTextField.text = self.bookmark.title;
	self.extendedTextField.text = self.bookmark.extended;
	self.toReadSwitch.on = self.bookmark.toread;
	self.sharedSwitch.on = !self.bookmark.shared;
	
	[self.tagsController updateFields];
	[self updateTagsRowHeight];
}

- (void)updateTitleButton {
	BOOL buttonEnabled;
	NSString *buttonTitle;
	NSArray *usernames = [PMAccountStore sharedStore].associatedUsernames;
	if ([usernames count] > 1) {
		buttonEnabled = YES;
		buttonTitle = [self.bookmark.username stringByAppendingString:@" ▾"];
	} else {
		buttonEnabled = NO;
		buttonTitle = self.bookmark.username;
	}
	
	UIButton *titleButton = (UIButton *)self.navigationItem.titleView;
	[titleButton addTarget:self action:@selector(showUsernameSheet:) forControlEvents:UIControlEventTouchUpInside];
	titleButton.enabled = buttonEnabled;
	[titleButton setTitle:buttonTitle forState:UIControlStateNormal];
	
	[self.tagsController updateFields];
}

- (void)reportSuccess {
	self.navigationItem.prompt = @"Success";
	[self performSelector:@selector(resetNavigationBar) withObject:self afterDelay:2.0];
}

- (void)reportErrorWithMessage:(NSString *)message {
	self.navigationItem.prompt = message ? message : @"Error";
	[self performSelector:@selector(resetNavigationBar) withObject:self afterDelay:2.0];
}

- (void)resetNavigationBar {
	self.navigationItem.prompt = nil;
}

- (void)dismissKeyboard {
	[self.tagsController.tagsTextField resignFirstResponder];
	[self.activeField resignFirstResponder];
	self.activeField = nil;
	[self.tableView scrollsToTop];
}

- (void)updateTagsRowHeight {
	[self updateRowHeights];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:PMTagsCellIndex inSection:0]];
	[self.tableView scrollRectToVisible:cell.frame animated:YES];
}

- (void)updateRowHeights {
	[self.tableView beginUpdates];
	
	if ([self.bookmark.tags count]) {
		self.tagsVerticalConstraint.constant = 0.0;
	} else {
		self.tagsVerticalConstraint.constant = -44.0;
	}
	
	[self.tableView endUpdates];
}

- (void)fieldsEnabled:(BOOL)enabled {
	self.URLTextField.enabled = enabled;
	self.titleTextField.enabled = enabled;
	self.extendedTextField.enabled = enabled;
	self.toReadSwitch.enabled = enabled;
	self.sharedSwitch.enabled = enabled;
	self.navigationItem.leftBarButtonItem.enabled = enabled;
	
	UIButton *titleButton = (UIButton *)self.navigationItem.titleView;
	titleButton.enabled = enabled;
	
	[self.tagsController fieldsEnabled:enabled];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PMNewPinTVCContext) {
		if ([keyPath isEqualToString:@"postable"]) {
			self.postButton.enabled = self.bookmark.postable;
		}
		else if ([keyPath isEqualToString:@"username"]) {
			[self updateTitleButton];
		}
		else if ([keyPath isEqualToString:@"lastPosted"]) {
			if (self.bookmark.lastPosted) {
				self.datePostedLabel.text = [NSString stringWithFormat:@"Last posted %@", [self.dateFormatter stringFromDate:self.bookmark.lastPosted]];
				[self updateRowHeights];
			} else {
				self.datePostedLabel.text = @"";
				[self updateRowHeights];
			}
		}
		else if ([keyPath isEqualToString:@"title"]) {
			self.titleTextField.text = self.bookmark.title;
		}
		else if ([keyPath isEqualToString:@"tags"]) {
			[self updateTagsRowHeight];
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - PMSettingsTVCDelegate

- (void)didRequestToPostWithUsername:(NSString *)username {
	self.bookmark.username = username;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray *usernames = [PMAccountStore sharedStore].associatedUsernames;
	
	if (buttonIndex < [usernames count]) {
		self.bookmark.username = usernames[buttonIndex];
		[PMAccountStore sharedStore].defaultUsername = usernames[buttonIndex];
	}
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == PMURLCellIndex) {
		if (self.bookmark.lastPosted) {
			return 67.0;
		}
		return 44.0;
	}
	else if (indexPath.row == PMTagsCellIndex) {
		if ([self.bookmark.tags count]) {
			return 88.0;
		} else {
			return 44.0;
		}
	}
	return 44.0;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.URLTextField) {
		self.bookmark.url = textField.text;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.URLTextField) {
		[self.titleTextField becomeFirstResponder];
	} else {
		[textField resignFirstResponder];
	}
	return NO;
}

@end
