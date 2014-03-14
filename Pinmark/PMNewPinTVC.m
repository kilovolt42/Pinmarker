//
//  PMNewPinTVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/16/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMNewPinTVC.h"
#import "PMAppDelegate.h"

#import "NSURL+Pinmark.h"
#import "NSString+Pinmark.h"

#import "PMTagCVCell.h"
#import "PMTagsDataSource.h"
#import "PMInputAccessoryView.h"

#import "PMBookmark.h"
#import "PMBookmarkStore.h"

#import "PMTagStore.h"

#import "PMAccountStore.h"

@interface PMNewPinTVC () <UITextFieldDelegate, UICollectionViewDelegate, UIActionSheetDelegate>
@property (nonatomic, weak) IBOutlet UITextField *URLTextField;
@property (weak, nonatomic) IBOutlet UILabel *datePostedLabel;
@property (nonatomic, weak) IBOutlet UITextField *titleTextField;
@property (nonatomic, weak) IBOutlet UITextField *extendedTextField;
@property (nonatomic, weak) IBOutlet UITextField *tagsTextField;
@property (nonatomic, weak) IBOutlet UICollectionView *tagsCollectionView;
@property (nonatomic, weak) UICollectionView *suggestedTagsCollectionView;
@property (nonatomic, weak) IBOutlet UISwitch *toReadSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *sharedSwitch;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tagsCVHeightConstraint;
@property (nonatomic, weak) PMInputAccessoryView *keyboardAccessory;
@property (nonatomic, weak) id activeField;
@property (nonatomic, copy) void (^xSuccess)(id);
@property (nonatomic, copy) void (^xFailure)(NSError *);
@property (nonatomic) PMBookmark *bookmark;
@property (nonatomic) PMTagsDataSource *tagsDataSource;
@property (nonatomic) PMTagsDataSource *suggestedTagsDataSource;
@property (nonatomic) PMTagCVCell *sizingCell;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *postButton;
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

static NSString *tagCellIdentifier = @"Tag Cell";
static void * PMNewPinTVCContext = &PMNewPinTVCContext;

@implementation PMNewPinTVC

#pragma mark - Properties

- (void)setBookmark:(PMBookmark *)bookmark {
	if (_bookmark) {
		[self removeBookmarkObservers];
	}
	
	_bookmark = bookmark;
	
	if (_bookmark) {
		[[PMTagStore sharedStore] loadTagsForAuthToken:_bookmark.authToken];
		[self addBookmarkObservers];
		[self updateFields];
	}
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

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateStyle = NSDateFormatterLongStyle;
	}
	return _dateFormatter;
}

#pragma mark - Life Cycle

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
	
	self.bookmark = [[PMBookmarkStore sharedStore] createBookmark];
}

- (void)dealloc {
	[self removeBookmarkObservers];
}

#pragma mark -

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

- (void)addBookmarkObservers {
	[_bookmark addObserver:self forKeyPath:@"postable" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"authToken" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"lastPosted" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
}

- (void)removeBookmarkObservers {
	[self.bookmark removeObserver:self forKeyPath:@"postable" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"authToken" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"lastPosted" context:&PMNewPinTVCContext];
}

#pragma mark - Actions

- (IBAction)pin:(UIBarButtonItem *)sender {
	[self dismissKeyboard]; // makes sure text field ends editing and saves text to bookmark
	
	[self disableFields];
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
					[self enableFields];
					NSString *resultCode = responseObject[@"result_code"];
					if (resultCode) {
						if ([resultCode isEqualToString:@"done"]) {
							[self reportSuccess];
							self.bookmark = [store createBookmark];
							if (self.xSuccess) self.xSuccess(responseObject);
						} else {
							NSString *report = responseDictionary[resultCode];
							[self reportErrorWithMessage:report];
						}
					}
				}
				failure:^(NSError *error) {
					self.navigationItem.rightBarButtonItem = sender;
					[self enableFields];
					[self reportErrorWithMessage:nil];
					if (self.xFailure) self.xFailure(error);
				}];
}

- (IBAction)toggledToReadSwitch:(UISwitch *)sender {
	self.bookmark.toread = sender.on;
}

- (IBAction)toggledSharedSwitch:(UISwitch *)sender {
	self.bookmark.shared = !sender.on;
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

- (void)showUsernameSheet:(id)sender {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
													   delegate:self
											  cancelButtonTitle:nil
										 destructiveButtonTitle:nil
											  otherButtonTitles:nil];
	
	NSArray *tokens = [PMAccountStore sharedStore].associatedTokens;
	
	for (NSString *title in tokens) {
		[sheet addButtonWithTitle:[[title componentsSeparatedByString:@":"] firstObject]];
	}
	
	[sheet addButtonWithTitle:@"Cancel"];
	sheet.cancelButtonIndex = [tokens count];
	
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
	
	if ([host isEqualToString:@"x-callback-url"]) {
		if (parameters[@"x-success"]) {
			self.xSuccess = ^void(id responseObject) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[parameters[@"x-success"] urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
			};
		}
		if (parameters[@"x-error"]) {
			self.xFailure = ^void(NSError *error) {
				NSString *xError = [NSString stringWithFormat:@"%@?errorCode=%ld&errorMessage=%@", parameters[@"x-error"], (long)[error code], [error domain]];
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[xError urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
			};
		}
	} else {
		self.xSuccess = nil;
		self.xFailure = nil;
	}
	
	if (parameters[@"wait"] && [parameters[@"wait"] isEqualToString:@"no"]) {
		[[PMBookmarkStore sharedStore] postBookmark:self.bookmark success:self.xSuccess failure:self.xFailure];
	} else {
		self.bookmark = [[PMBookmarkStore sharedStore] createBookmarkWithParameters:parameters];
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

- (void)updateTagsRowHeight {
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:0]];
	[self.tableView scrollRectToVisible:cell.frame animated:YES];
}

- (void)updateURLRowHeight {
	[self.tableView beginUpdates];
	[self.tableView endUpdates];
}

- (void)keyboardDidHide:(NSNotification *)notification {
	NSArray *selectedItems = [self.tagsCollectionView indexPathsForSelectedItems];
	if ([selectedItems count]) {
		[self showMenuForTagAtIndexPath:[selectedItems firstObject]];
	}
}

- (void)updateSuggestedTagsForTag:(NSString *)tag {
	NSArray *tags = [[PMTagStore sharedStore] tagsForAuthToken:self.bookmark.authToken];
	if (tags) {
		NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", tag];
		NSMutableArray *results = [NSMutableArray arrayWithArray:[tags filteredArrayUsingPredicate:searchPredicate]];
		[results removeObjectsInArray:self.bookmark.tags];
		self.suggestedTagsDataSource.tags = [results copy];
		[self.suggestedTagsCollectionView reloadData];
		if ([results count]) {
			[self.keyboardAccessory showSuggestedTags];
		} else {
			[self.keyboardAccessory hideSuggestedTags];
		}
	} else {
		[self.keyboardAccessory hideSuggestedTags];
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

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PMNewPinTVCContext) {
		if ([keyPath isEqualToString:@"postable"]) {
			self.postButton.enabled = self.bookmark.postable;
		}
		else if ([keyPath isEqualToString:@"authToken"]) {
			NSString *username = [[self.bookmark.authToken componentsSeparatedByString:@":"] firstObject];
			UIButton *titleButton = (UIButton *)self.navigationItem.titleView;
			[titleButton setTitle:username forState:UIControlStateNormal];
			[titleButton addTarget:self action:@selector(showUsernameSheet:) forControlEvents:UIControlEventTouchUpInside];
			if (self.activeField == self.tagsTextField) {
				[self updateSuggestedTagsForTag:self.tagsTextField.text];
			}
		}
		else if ([keyPath isEqualToString:@"lastPosted"]) {
			if (self.bookmark.lastPosted) {
				self.datePostedLabel.text = [NSString stringWithFormat:@"Last posted %@", [self.dateFormatter stringFromDate:self.bookmark.lastPosted]];
				[self updateURLRowHeight];
			} else {
				self.datePostedLabel.text = @"";
				[self updateURLRowHeight];
			}
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

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray *tokens = [PMAccountStore sharedStore].associatedTokens;
	
	if (buttonIndex < [tokens count]) {
		self.bookmark.authToken = tokens[buttonIndex];
	}
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
		[self addTags:self.suggestedTagsDataSource.tags[indexPath.item]];
		self.suggestedTagsDataSource.tags = nil;
		[self.suggestedTagsCollectionView reloadData];
		self.tagsTextField.text = @"";
		[self updateTagsRowHeight];
	}
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (collectionView == self.tagsCollectionView) {
		self.sizingCell.label.text = self.tagsDataSource.tags[indexPath.item];
	} else {
		self.sizingCell.label.text = self.suggestedTagsDataSource.tags[indexPath.item];
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
	if (textField == self.titleTextField) {
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
	if (indexPath.row == 0) {
		if (self.bookmark.lastPosted) {
			return 67.0;
		}
		return 44.0;
	}
	if (indexPath.row == 3) {
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
