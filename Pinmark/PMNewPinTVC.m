//
//  PMNewPinTVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/16/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMNewPinTVC.h"
#import <AFNetworking/AFNetworking.h>
#import "PMPinboardManager.h"
#import "NSURL+Pinmark.h"
#import "PMBookmark.h"
#import "PMTagCVCell.h"
#import "PMTagsDataSource.h"
#import "PMInputAccessoryView.h"
#import "PMSettingsTVC.h"
#import "PMAddAccountVC.h"
#import "NSString+Pinmark.h"
#import "PMAppDelegate.h"

@interface PMNewPinTVC () <PMAddAccountVCDelegate, PMSettingsTVCDelegate, UITextFieldDelegate, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *URLTextField;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *extendedTextField;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *tagsCollectionView;
@property (weak, nonatomic) UICollectionView *suggestedTagsCollectionView;
@property (weak, nonatomic) IBOutlet UISwitch *toReadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sharedSwitch;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tagsCVHeightConstraint;
@property (weak, nonatomic) PMInputAccessoryView *keyboardAccessory;
@property (weak, nonatomic) id activeField;
@property (strong, nonatomic) PMPinboardManager *manager;
@property (nonatomic, copy) void (^xSuccess)(AFHTTPRequestOperation *, id);
@property (nonatomic, copy) void (^xFailure)(AFHTTPRequestOperation *, NSError *);
@property (strong, nonatomic) PMBookmark *bookmark;
@property (strong, nonatomic) PMTagsDataSource *tagsDataSource;
@property (strong, nonatomic) PMTagsDataSource *suggestedTagsDataSource;
@property (strong, nonatomic) PMTagCVCell *sizingCell;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *postButton;
@end

static NSString *tagCellIdentifier = @"Tag Cell";
static void * PMNewPinTVCContext = &PMNewPinTVCContext;

@implementation PMNewPinTVC

#pragma mark - Properties

@synthesize bookmark = _bookmark;

- (PMPinboardManager *)manager {
	if (!_manager) _manager = [PMPinboardManager new];
	return _manager;
}

- (PMBookmark *)bookmark {
	if (!_bookmark) {
		_bookmark = [PMBookmark new];
		[_bookmark addObserver:self forKeyPath:@"postable" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	}
	return _bookmark;
}

- (void)setBookmark:(PMBookmark *)bookmark {
	if (_bookmark) [_bookmark removeObserver:self forKeyPath:@"postable" context:&PMNewPinTVCContext];
	_bookmark = bookmark;
	[_bookmark addObserver:self forKeyPath:@"postable" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[self updateFields];
}

- (PMTagsDataSource *)tagsDataSource {
	if (!_tagsDataSource) _tagsDataSource = [PMTagsDataSource new];
	return _tagsDataSource;
}

- (PMTagsDataSource *)suggestedTagsDataSource {
	if (!_suggestedTagsDataSource) _suggestedTagsDataSource = [PMTagsDataSource new];
	return _suggestedTagsDataSource;
}

- (void)setTagsCollectionView:(UICollectionView *)collectionView {
	_tagsCollectionView = collectionView;
	_tagsCollectionView.dataSource = self.tagsDataSource;
	_tagsCollectionView.delegate = self;
	_tagsCollectionView.allowsMultipleSelection = NO;
	
	UINib *cellNib = [UINib nibWithNibName:@"PMTagCVCell" bundle:nil];
	[_tagsCollectionView registerNib:cellNib forCellWithReuseIdentifier:tagCellIdentifier];
	self.sizingCell = [[cellNib instantiateWithOwner:nil options:nil] objectAtIndex:0];
}

- (void)setSuggestedTagsCollectionView:(UICollectionView *)suggestedTagsCollectionView {
	_suggestedTagsCollectionView = suggestedTagsCollectionView;
	_suggestedTagsCollectionView.dataSource = self.suggestedTagsDataSource;
	_suggestedTagsCollectionView.delegate = self;
	_suggestedTagsCollectionView.allowsMultipleSelection = NO;
	
	UINib *cellNib = [UINib nibWithNibName:@"PMTagCVCell" bundle:nil];
	[_suggestedTagsCollectionView registerNib:cellNib forCellWithReuseIdentifier:tagCellIdentifier];
}

- (void)setKeyboardAccessory:(PMInputAccessoryView *)keyboardAccessory {
	_keyboardAccessory = keyboardAccessory;
	[_keyboardAccessory.hideKeyboardButton addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
	self.suggestedTagsCollectionView = _keyboardAccessory.suggestedTagsCollectionView;
	self.URLTextField.inputAccessoryView = _keyboardAccessory;
	self.titleTextField.inputAccessoryView = _keyboardAccessory;
	self.extendedTextField.inputAccessoryView = _keyboardAccessory;
	self.tagsTextField.inputAccessoryView = _keyboardAccessory;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	
	self.URLTextField.delegate = self;
	self.titleTextField.delegate = self;
	self.tagsTextField.delegate = self;
	self.extendedTextField.delegate = self;
	self.keyboardAccessory = [[[NSBundle mainBundle] loadNibNamed:@"PMInputAccessoryView" owner:self options:nil] firstObject];
	
	UIMenuController *menuController = [UIMenuController sharedMenuController];
	UIMenuItem *deleteTagMenuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteTag:)];
	[menuController setMenuItems:@[deleteTagMenuItem]];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (!self.manager.defaultUser) [self login];
	self.title = self.manager.defaultUser;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Login Segue"]) {
		UINavigationController *navigationController = segue.destinationViewController;
		PMAddAccountVC *addAccountVC = [navigationController.viewControllers firstObject];
		addAccountVC.delegate = self;
		addAccountVC.manager = self.manager;
	} else if ([segue.identifier isEqualToString:@"Settings"]) {
		UINavigationController *navigationController = segue.destinationViewController;
		PMSettingsTVC *settingsTVC = [navigationController.viewControllers firstObject];
		settingsTVC.delegate = self;
		settingsTVC.manager = self.manager;
	}
}

#pragma mark - IBAction

- (IBAction)pin:(UIBarButtonItem *)sender {
	[self dismissKeyboard]; // makes sure text field ends editing and saves text to bookmark
	
	[self disableFields];
	UIActivityIndicatorView *indicatorButton = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[indicatorButton startAnimating];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorButton];
	
	__weak PMNewPinTVC *weakSelf = self;
	
	[self.manager add:[self.bookmark parameters]
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
				  weakSelf.navigationItem.rightBarButtonItem = sender;
				  [weakSelf enableFields];
				  NSString *resultCode = responseObject[@"result_code"];
				  if (resultCode) {
					  if ([resultCode isEqualToString:@"done"]) {
						  [weakSelf reportSuccess];
						  weakSelf.bookmark = [PMBookmark new];
						  if (weakSelf.xSuccess) weakSelf.xSuccess(operation, responseObject);
					  }
					  else if ([resultCode isEqualToString:@"missing url"]) [weakSelf reportErrorWithMessage:@"Invalid URL"];
					  else if ([resultCode isEqualToString:@"must provide title"]) [weakSelf reportErrorWithMessage:@"Missing Title"];
					  else if ([resultCode isEqualToString:@"item already exists"]) [weakSelf reportErrorWithMessage:@"Already Bookmarked"];
					  else [weakSelf reportErrorWithMessage:nil];
				  }
			  }
			  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				  weakSelf.navigationItem.rightBarButtonItem = sender;
				  [weakSelf enableFields];
				  [weakSelf reportErrorWithMessage:nil];
				  if (weakSelf.xFailure) weakSelf.xFailure(operation, error);
			  }];
}

- (IBAction)toggledToReadSwitch:(UISwitch *)sender {
	self.bookmark.toread = sender.on;
}

- (IBAction)toggledSharedSwitch:(UISwitch *)sender {
	self.bookmark.shared = !sender.on;
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
	
	if (!parameters[@"auth_token"] && !self.manager.defaultUser) {
		[self login];
	}
	
	if ([host isEqualToString:@"x-callback-url"]) {
		if (parameters[@"x-success"]) {
			self.xSuccess = ^void(AFHTTPRequestOperation *operation, id responseObject) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[parameters[@"x-success"] urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
			};
		}
		if (parameters[@"x-error"]) {
			self.xFailure = ^void(AFHTTPRequestOperation *operation, NSError *error) {
				NSString *xError = [NSString stringWithFormat:@"%@?errorCode=%ld&errorMessage=%@", parameters[@"x-error"], (long)[error code], [error domain]];
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[xError urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
			};
		}
	} else {
		self.xSuccess = nil;
		self.xFailure = nil;
	}
	
	if (parameters[@"wait"] && [parameters[@"wait"] isEqualToString:@"no"]) {
		[self.manager add:[PMPinboardManager pinboardSpecificParametersFromParameters:parameters] success:self.xSuccess failure:self.xFailure];
	} else {
		self.bookmark = [[PMBookmark alloc] initWithParameters:parameters];
	}
}

#pragma mark -

- (void)updateFields {
	self.URLTextField.text = self.bookmark.url;
	self.titleTextField.text = self.bookmark.title;
	self.extendedTextField.text = self.bookmark.extended;
	self.tagsDataSource.tags = self.bookmark.tags;
	[self.tagsCollectionView reloadData];
	self.toReadSwitch.on = self.bookmark.toread;
	self.sharedSwitch.on = !self.bookmark.shared;
	[self updateTagsRowHeight];
}

- (void)login {
	[self performSegueWithIdentifier:@"Login Segue" sender:self];
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
	[self.activeField resignFirstResponder];
	self.activeField = nil;
	[self.tableView scrollsToTop];
}

- (void)addTags:(NSString *)tags {
	[self.bookmark addTags:tags];
	
	self.tagsDataSource.tags = self.bookmark.tags;
	[self.tagsCollectionView reloadData];
	
	self.suggestedTagsDataSource.tags = nil;
	[self.suggestedTagsCollectionView reloadData];
	
	self.tagsTextField.text = @"";
	NSIndexPath *lastTagIndexPath = [NSIndexPath indexPathForItem:[self.bookmark.tags count]-1 inSection:0];
	[self.tagsCollectionView scrollToItemAtIndexPath:lastTagIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
	[self updateTagsRowHeight];
	[self.keyboardAccessory hideSuggestedTags];
}

- (void)deleteTag:(id)sender {
	NSArray *selectedItems = [self.tagsCollectionView indexPathsForSelectedItems];
	if ([selectedItems count]) {
		NSIndexPath *selectedIndexPath = [selectedItems firstObject];
		PMTagCVCell *cell = (PMTagCVCell *)[self.tagsCollectionView cellForItemAtIndexPath:selectedIndexPath];
		[self.bookmark removeTag:cell.label.text];
		self.tagsDataSource.tags = self.bookmark.tags;
		[self.tagsCollectionView reloadData];
		[self updateTagsRowHeight];
	}
}

- (void)updateTagsRowHeight {
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:0]];
	[self.tableView scrollRectToVisible:cell.frame animated:YES];
}

- (void)keyboardDidHide:(NSNotification *)notification {
	NSArray *selectedItems = [self.tagsCollectionView indexPathsForSelectedItems];
	if ([selectedItems count]) {
		[self showMenuForTagAtIndexPath:[selectedItems firstObject]];
	}
}

- (void)updateSuggestedTagsForTag:(NSString *)tag {
	if (self.manager.userTags) {
		NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", tag];
		NSMutableArray *results = [NSMutableArray arrayWithArray:[self.manager.userTags filteredArrayUsingPredicate:searchPredicate]];
		[results removeObjectsInArray:self.bookmark.tags];
		self.suggestedTagsDataSource.tags = [results copy];
		[self.suggestedTagsCollectionView reloadData];
		if ([results count]) {
			[self.keyboardAccessory showSuggestedTags];
		} else {
			[self.keyboardAccessory hideSuggestedTags];
		}
	}
}

- (void)deselectAllTagCells {
	NSArray *selectedCells = [self.tagsCollectionView indexPathsForSelectedItems];
	for (NSIndexPath *indexPath in selectedCells) {
		[self.tagsCollectionView deselectItemAtIndexPath:indexPath animated:NO];
	}
}

- (void)showMenuForTagAtIndexPath:(NSIndexPath *)indexPath {
	[self becomeFirstResponder];
	UICollectionViewCell *cell = [self.tagsCollectionView cellForItemAtIndexPath:indexPath];
	UIMenuController *menuController = [UIMenuController sharedMenuController];
	[menuController setTargetRect:cell.frame inView:self.tagsCollectionView];
	[menuController setMenuVisible:YES animated:YES];
}

- (void)disableFields {
	self.URLTextField.enabled = NO;
	self.titleTextField.enabled = NO;
	self.extendedTextField.enabled = NO;
	self.tagsCollectionView.allowsSelection = NO;
	self.tagsTextField.enabled = NO;
	self.toReadSwitch.enabled = NO;
	self.sharedSwitch.enabled = NO;
}

- (void)enableFields {
	self.URLTextField.enabled = YES;
	self.titleTextField.enabled = YES;
	self.extendedTextField.enabled = YES;
	self.tagsCollectionView.allowsSelection = YES;
	self.tagsTextField.enabled = YES;
	self.toReadSwitch.enabled = YES;
	self.sharedSwitch.enabled = YES;
}

- (void)attemptToPasteURLFromPasteboard {
	if ([self.URLTextField.text isEqualToString:@""]) {
		NSNumber *pasteboardPreferenceWrapper = [[NSUserDefaults standardUserDefaults] objectForKey:PMPasteboardPreferenceKey];
		if (pasteboardPreferenceWrapper && [pasteboardPreferenceWrapper boolValue]) {
			NSString *pasteboardString = [UIPasteboard generalPasteboard].string;
			if ([pasteboardString isPinboardPermittedURL]) {
				self.URLTextField.text = pasteboardString;
				self.bookmark.url = pasteboardString;
			}
		}
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	[self attemptToPasteURLFromPasteboard];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
	if (self.activeField == self.tagsTextField) {
		NSString *tagsText = self.tagsTextField.text;
		self.tagsTextField.text = @"";
		[self dismissKeyboard];
		self.tagsTextField.text = tagsText;
	} else {
		[self dismissKeyboard];
	}
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PMNewPinTVCContext) {
		if ([keyPath isEqualToString:@"postable"]) {
			self.postButton.enabled = self.bookmark.postable;
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	return self.isFirstResponder && action == @selector(deleteTag:);
}

- (BOOL)becomeFirstResponder {
	self.activeField = nil;
	return [super becomeFirstResponder];
}

#pragma mark - PMAddAccountVCDelegate

- (void)didAddAccount {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PMSettingsTVCDelegate

- (void)shouldCloseSettings {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (collectionView == self.tagsCollectionView) {
		if (self.activeField == nil) {
			[self showMenuForTagAtIndexPath:indexPath];
		} else {
			[self dismissKeyboard];
		}
	} else if (collectionView == self.suggestedTagsCollectionView) {
		[self addTags:self.suggestedTagsDataSource.tags[[indexPath item]]];
		self.suggestedTagsDataSource.tags = nil;
		[self.suggestedTagsCollectionView reloadData];
		self.tagsTextField.text = @"";
		[self updateTagsRowHeight];
	}
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (collectionView == self.tagsCollectionView) {
		self.sizingCell.label.text = self.tagsDataSource.tags[[indexPath item]];
	} else {
		self.sizingCell.label.text = self.suggestedTagsDataSource.tags[[indexPath item]];
	}
	return [self.sizingCell suggestedSizeForCell];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake(0, 15, 0, 15);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 1.0;
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
	[self deselectAllTagCells];
	self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.URLTextField) {
		self.bookmark.url = textField.text;
	} else if (textField == self.titleTextField) {
		self.bookmark.title = textField.text;
	} else if (textField == self.extendedTextField) {
		self.bookmark.extended = textField.text;
	} else if (textField == self.tagsTextField) {
		if (![textField.text isEqualToString:@""]) {
			[self addTags:textField.text];
		}
	}
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	if (textField == self.URLTextField) {
		self.bookmark.url = @"";
	} else if (textField == self.titleTextField) {
		self.bookmark.title = @"";
	} else if (textField == self.extendedTextField) {
		self.bookmark.extended = @"";
	} else if (textField == self.tagsTextField) {
		[self updateSuggestedTagsForTag:@""];
	}
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
	if (textField == self.URLTextField) {
		self.bookmark.url = newString;
	} else if (textField == self.titleTextField) {
		self.bookmark.title = newString;
	} else if (textField == self.extendedTextField) {
		self.bookmark.extended = newString;
	} else if (textField == self.tagsTextField) {
		[self updateSuggestedTagsForTag:newString];
	}
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.URLTextField) [self.titleTextField becomeFirstResponder];
	else if (textField == self.titleTextField) [self.extendedTextField becomeFirstResponder];
	else if (textField == self.extendedTextField) [self.tagsTextField becomeFirstResponder];
	else if (textField == self.tagsTextField) {
		if ([textField.text isEqualToString:@""]) {
			[textField resignFirstResponder];
		} else {
			[self addTags:textField.text];
		}
	}
	return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.item == 3) {
		if ([self.tagsDataSource.tags count]) {
			self.tagsCVHeightConstraint.constant = 44.0;
		} else {
			self.tagsCVHeightConstraint.constant = 0.0;
		}
		return self.tagsTextField.frame.size.height + self.tagsCVHeightConstraint.constant;
	}
	return 44.0;
}

@end
