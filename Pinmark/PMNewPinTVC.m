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

@interface PMNewPinTVC () <UITextFieldDelegate, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *URLTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *extendedTextField;
@property (weak, nonatomic) IBOutlet UITextField *tagsTextField;
@property (weak, nonatomic) IBOutlet UICollectionView *tagsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *suggestedTagsCollectionView;
@property (weak, nonatomic) IBOutlet UISwitch *toReadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sharedSwitch;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tagsCVHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *suggestedTagsCVHeightConstraint;
@property (weak, nonatomic) id activeField;
@property (strong, nonatomic) PMPinboardManager *manager;
@property (nonatomic, copy) void (^xSuccess)(AFHTTPRequestOperation *, id);
@property (nonatomic, copy) void (^xFailure)(AFHTTPRequestOperation *, NSError *);
@property (strong, nonatomic) PMBookmark *bookmark;
@property (strong, nonatomic) PMTagsDataSource *tagsDataSource;
@property (strong, nonatomic) PMTagsDataSource *suggestedTagsDataSource;
@property (strong, nonatomic) PMTagCVCell *sizingCell;
@end

static NSString *tagCellIdentifier = @"Tag Cell";

@implementation PMNewPinTVC

#pragma mark - Properties

- (PMPinboardManager *)manager {
	if (!_manager) _manager = [PMPinboardManager new];
	return _manager;
}

- (void)setBookmark:(PMBookmark *)bookmark {
	_bookmark = bookmark;
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

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.URLTextField.delegate = self;
	self.descriptionTextField.delegate = self;
	self.tagsTextField.delegate = self;
	self.extendedTextField.delegate = self;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.navigationController.navigationBar addGestureRecognizer:tap];
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

// TODO: model should be updated constantly
- (void)updateBookmark {
	self.bookmark = [[PMBookmark alloc] initWithParameters:@{ @"url": self.URLTextField.text,
															  @"description": self.descriptionTextField.text,
															  @"extended": self.extendedTextField.text,
															  @"tags": [[self.tagsDataSource.tags copy] componentsJoinedByString:@" "],
															  @"toread": self.toReadSwitch.on ? @"yes" : @"no",
															  @"shared": self.sharedSwitch.on ? @"no" : @"yes" }];
}

- (IBAction)pin:(UIBarButtonItem *)sender {
	if (![self isReadyToPin]) return;
	[self.activeField resignFirstResponder];
	[self updateBookmark];
	
	UIActivityIndicatorView *indicatorButton = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[indicatorButton startAnimating];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorButton];
	
	__weak PMNewPinTVC *weakSelf = self;
	
	[self.manager add:[self.bookmark parameters]
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
				  weakSelf.navigationItem.rightBarButtonItem = sender;
				  NSString *resultCode = responseObject[@"result_code"];
				  if (resultCode) {
					  if ([resultCode isEqualToString:@"done"]) {
						  [weakSelf reportSuccess];
						  weakSelf.bookmark = [[PMBookmark alloc] initWithParameters:nil];
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
	
	if (![command isEqualToString:@"add"]) {
		return;
	}
	
	if (!parameters[@"auth_token"] && !self.manager.authToken) {
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
		[self.manager add:[PMPinboardManager pinboardSpecificParametersFromParameters:parameters] success:self.xSuccess failure:self.xFailure];
	} else {
		self.bookmark = [[PMBookmark alloc] initWithParameters:parameters];
	}
}

#pragma mark -

- (void)updateFields {
	self.URLTextField.text = self.bookmark.url;
	self.descriptionTextField.text = self.bookmark.description;
	self.extendedTextField.text = self.bookmark.extended;
	self.tagsDataSource.tags = [self.bookmark.tags mutableCopy];
	self.toReadSwitch.on = self.bookmark.toread;
	self.sharedSwitch.on = !self.bookmark.shared;
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

- (void)dismissKeyboard {
	[self.activeField resignFirstResponder];
	self.activeField = nil;
}

- (void)addTags:(NSString *)tags {
	NSCharacterSet *commaSpaceSet = [NSCharacterSet characterSetWithCharactersInString:@", "];
	NSMutableArray *newTags = [NSMutableArray arrayWithArray:[tags componentsSeparatedByCharactersInSet:commaSpaceSet]];
	[newTags removeObject:@""];
	for (NSString *newTag in newTags) {
		[self.tagsDataSource.tags removeObject:newTag];
		[self.tagsDataSource.tags addObject:newTag];
	}
	[self.tagsCollectionView reloadData];
	[self scrollToLastTag];
	[self updateTagsRowHeight];
}

- (void)scrollToLastTag {
	NSIndexPath *lastTag = [NSIndexPath indexPathForItem:[self.tagsDataSource.tags count] - 1 inSection:0];
	[self.tagsCollectionView scrollToItemAtIndexPath:lastTag atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
	CGPoint contentOffset = self.tagsCollectionView.contentOffset;
	contentOffset.x += 15.0;
	self.tagsCollectionView.contentOffset = contentOffset;
}

- (void)deleteTag:(id)sender {
	NSArray *selectedItems = [self.tagsCollectionView indexPathsForSelectedItems];
	if ([selectedItems count]) {
		NSIndexPath *selectedItem = [selectedItems firstObject];
		[self.tagsDataSource.tags removeObjectAtIndex:[selectedItem item]];
		[self.tagsCollectionView deleteItemsAtIndexPaths:@[selectedItem]];
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

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	return self.isFirstResponder && action == @selector(deleteTag:);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (collectionView == self.tagsCollectionView) {
		[self becomeFirstResponder];
		UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
		UIMenuController *menuController = [UIMenuController sharedMenuController];
		UIMenuItem *deleteTag = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteTag:)];
		[menuController setMenuItems:@[deleteTag]];
		[menuController setTargetRect:cell.frame inView:collectionView];
		[menuController setMenuVisible:YES animated:YES];
	} else {
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
	self.activeField = textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField == self.tagsTextField) {
		if (self.manager.userTags) {
			NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
			NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", newString];
			NSArray *results = [self.manager.userTags filteredArrayUsingPredicate:searchPredicate];
			self.suggestedTagsDataSource.tags = [NSMutableArray arrayWithArray:results];
			[self.suggestedTagsCollectionView reloadData];
			[self updateTagsRowHeight];
		}
	}
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.URLTextField) [self.descriptionTextField becomeFirstResponder];
	else if (textField == self.descriptionTextField) [self.extendedTextField becomeFirstResponder];
	else if (textField == self.extendedTextField) [self.tagsTextField becomeFirstResponder];
	else if (textField == self.tagsTextField) {
		if ([textField.text isEqualToString:@""]) {
			[textField resignFirstResponder];
		} else {
			[self addTags:textField.text];
			textField.text = @"";
		}
	}
	return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.item == 3) {
		if ([self.tagsCollectionView numberOfItemsInSection:0]) {
			self.tagsCVHeightConstraint.constant = 44.0;
		} else {
			self.tagsCVHeightConstraint.constant = 0.0;
		}
		
		if ([self.suggestedTagsCollectionView numberOfItemsInSection:0]) {
			self.suggestedTagsCVHeightConstraint.constant = 44.0;
		} else {
			self.suggestedTagsCVHeightConstraint.constant = 0.0;
		}
		
		return self.tagsTextField.frame.size.height + self.tagsCVHeightConstraint.constant + self.suggestedTagsCVHeightConstraint.constant;
	}
	return 44.0;
}

@end
