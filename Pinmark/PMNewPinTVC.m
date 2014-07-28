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

#import "PMTagCVCell.h"
#import "PMTagsDataSource.h"
#import "PMInputAccessoryView.h"

#import "PMBookmark.h"

#import "PMBookmarkStore.h"
#import "PMTagStore.h"
#import "PMAccountStore.h"

#import "PMSettingsTVC.h"

#import "PMAppDelegate.h"
#import <TextExpander/SMTEDelegateController.h>

@interface PMNewPinTVC () <UINavigationControllerDelegate, PMSettingsTVCDelegate, UITextFieldDelegate, UICollectionViewDelegate, UIActionSheetDelegate, SMTEFillDelegate>
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
@property (nonatomic, copy) void (^xFailure)(NSError *, id);
@property (nonatomic) PMBookmark *bookmark;
@property (nonatomic) PMTagsDataSource *tagsDataSource;
@property (nonatomic) PMTagsDataSource *suggestedTagsDataSource;
@property (nonatomic) PMTagCVCell *sizingCell;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *postButton;
@property (nonatomic) NSDateFormatter *dateFormatter;
@property (nonatomic, readonly) SMTEDelegateController *textExpander;
@end

static NSString *tagCellIdentifier = @"Tag Cell";
static void * PMNewPinTVCContext = &PMNewPinTVCContext;

#define URL_CELL_INDEX 0
#define TITLE_CELL_INDEX 1
#define TAGS_CELL_INDEX 2
#define DESCRIPTION_CELL_INDEX 3
#define READLATER_CELL_INDEX 4
#define PRIVATE_CELL_INDEX 5

@implementation PMNewPinTVC

#pragma mark - Properties

- (void)setBookmark:(PMBookmark *)bookmark {
	if (_bookmark) {
		[self removeBookmarkObservers];
	}
	
	_bookmark = bookmark;
	
	if (_bookmark) {
		[self addBookmarkObservers];
		[self updateFields];
	}
	
	[[PMTagStore sharedStore] markTagsDirtyForUsername:_bookmark.username];
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
	self.tagsTextField.inputAccessoryView = _keyboardAccessory;
}

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateStyle = NSDateFormatterLongStyle;
	}
	return _dateFormatter;
}

@synthesize textExpander = _textExpander;

- (SMTEDelegateController *)textExpander {
	if (!_textExpander) {
		PMAppDelegate *app = [UIApplication sharedApplication].delegate;
		_textExpander = app.textExpander;
	}
	return _textExpander;
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
	[notificationCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	
	if (self.textExpander) {
		self.textExpander.nextDelegate = self;
		self.URLTextField.delegate = self.textExpander;
		self.titleTextField.delegate = self.textExpander;
		self.tagsTextField.delegate = self.textExpander;
        self.extendedTextField.delegate = self.textExpander;
	} else {
		self.URLTextField.delegate = self;
		self.titleTextField.delegate = self;
		self.tagsTextField.delegate = self;
        self.extendedTextField.delegate = self;
	}
	
	self.keyboardAccessory = [[[NSBundle mainBundle] loadNibNamed:@"PMInputAccessoryView" owner:self options:nil] firstObject];
	
	UIMenuController *menuController = [UIMenuController sharedMenuController];
	UIMenuItem *deleteTagMenuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteTag:)];
	[menuController setMenuItems:@[deleteTagMenuItem]];
	
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
	
	self.textExpander.nextDelegate = self;
	self.textExpander.fillDelegate = self;
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
	[_bookmark addObserver:self forKeyPath:@"username" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"lastPosted" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
	[_bookmark addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionInitial context:&PMNewPinTVCContext];
}

- (void)removeBookmarkObservers {
	[self.bookmark removeObserver:self forKeyPath:@"postable" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"username" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"lastPosted" context:&PMNewPinTVCContext];
	[self.bookmark removeObserver:self forKeyPath:@"title" context:&PMNewPinTVCContext];
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
					[self reportSuccess];
					self.bookmark = [store lastBookmark];
					if (self.xSuccess) {
						self.xSuccess(responseObject);
					}
				}
				failure:^(NSError *error, id responseObject) {
					self.navigationItem.rightBarButtonItem = sender;
					[self enableFields];
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

- (IBAction)tagsTextFieldEditingChanged:(UITextField *)textField {
	[self updateSuggestedTagsForTag:textField.text];
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
	self.tagsDataSource.tags = self.bookmark.tags;
	[self.tagsCollectionView reloadData];
    self.extendedTextField.text = self.bookmark.extended;
	self.toReadSwitch.on = self.bookmark.toread;
	self.sharedSwitch.on = !self.bookmark.shared;
	
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
	
	if (self.activeField == self.tagsTextField) {
		[self updateSuggestedTagsForTag:self.tagsTextField.text];
	}
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
	[self updateRowHeights];
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:TAGS_CELL_INDEX inSection:0]];
	[self.tableView scrollRectToVisible:cell.frame animated:YES];
}

- (void)updateRowHeights {
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
	NSArray *tags = [[PMTagStore sharedStore] tagsForUsername:self.bookmark.username];
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
	self.tagsCollectionView.allowsSelection = NO;
	self.tagsTextField.enabled = NO;
    self.extendedTextField.enabled = NO;
	self.toReadSwitch.enabled = NO;
	self.sharedSwitch.enabled = NO;
	self.navigationItem.leftBarButtonItem.enabled = NO;
	
	UIButton *titleButton = (UIButton *)self.navigationItem.titleView;
	titleButton.enabled = NO;
}

- (void)enableFields {
	self.URLTextField.enabled = YES;
	self.titleTextField.enabled = YES;
	self.tagsCollectionView.allowsSelection = YES;
	self.tagsTextField.enabled = YES;
    self.extendedTextField.enabled = YES;
	self.toReadSwitch.enabled = YES;
	self.sharedSwitch.enabled = YES;
	self.navigationItem.leftBarButtonItem.enabled = YES;
	
	UIButton *titleButton = (UIButton *)self.navigationItem.titleView;
	titleButton.enabled = YES;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == URL_CELL_INDEX) {
		if (self.bookmark.lastPosted) {
			return 67.0;
		}
		return 44.0;
	}
	else if (indexPath.row == TAGS_CELL_INDEX) {
		if ([self.tagsDataSource.tags count]) {
			self.tagsCVHeightConstraint.constant = 44.0;
		} else {
			self.tagsCVHeightConstraint.constant = 0.0;
		}
		return self.tagsTextField.frame.size.height + self.tagsCVHeightConstraint.constant;
	}
	return 44.0;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self deselectAllTagCells];
	self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.URLTextField) {
		self.bookmark.url = textField.text;
	} else if (textField == self.tagsTextField) {
		if (![textField.text isEqualToString:@""]) {
			[self addTags:textField.text];
		}
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.URLTextField) {
        [self.titleTextField becomeFirstResponder];
    } else if (textField == self.titleTextField) {
        [self.tagsTextField becomeFirstResponder];
    } else if (textField == self.tagsTextField) {
		if ([textField.text isEqualToString:@""]) {
			[self.extendedTextField becomeFirstResponder];
		} else {
			[self addTags:textField.text];
		}
	} else {
        [textField resignFirstResponder];
    }
	return NO;
}

#pragma mark - SMTEFillDelegate

- (NSString *)identifierForTextArea:(id)textArea {
	NSString *identifier = nil;
	if (textArea == self.URLTextField) {
		identifier = @"URLTextField";
	} else if (textArea == self.titleTextField) {
		identifier = @"titleTextField";
	} else if (textArea == self.tagsTextField) {
		identifier = @"tagsTextField";
	} else if (textArea == self.extendedTextField) {
        identifier = @"extendedTextField";
    }
	return identifier;
}

- (id)makeIdentifiedTextObjectFirstResponder:(NSString *)textIdentifier fillWasCanceled:(BOOL)userCanceled cursorPosition:(NSInteger *)insertionLocation {
	UITextField *textField = nil;
	if ([textIdentifier isEqualToString:@"URLTextField"]) {
		textField = self.URLTextField;
	} else if ([textIdentifier isEqualToString:@"titleTextField"]) {
		textField = self.titleTextField;
	} else if ([textIdentifier isEqualToString:@"tagsTextField"]) {
		textField = self.tagsTextField;
	} else if ([textIdentifier isEqualToString:@"extendedTextField"]) {
        textField = self.extendedTextField;
    }
	
	[textField becomeFirstResponder];
	
	UITextPosition *location = [textField positionFromPosition:textField.beginningOfDocument offset:*insertionLocation];
	if (location) {
		textField.selectedTextRange = [textField textRangeFromPosition:location toPosition:location];
	} else {
		return nil;
	}
	
	return textField;
}

@end
