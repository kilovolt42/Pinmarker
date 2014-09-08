//
//  PMTagsController.m
//  Pinmarker
//
//  Created by Kyle Stevens on 9/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMTagsController.h"
#import "PMBookmark.h"
#import "PMTagCVCell.h"
#import "PMTagStore.h"
#import "PMInputAccessoryView.h"

static NSString *tagCellIdentifier = @"Tag Cell";

@interface PMTagsController () <UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PMTagCVCellDelegate>

@property (nonatomic, copy) NSArray *aggregatedTags;
@property (nonatomic, copy) NSArray *suggestedTags;
@property (nonatomic) PMTagCVCell *sizingCell;
@property (nonatomic) PMInputAccessoryView *keyboardAccessory;

@end

@implementation PMTagsController

#pragma mark - Properties

- (void)setAggregatedTagsCollectionView:(UICollectionView *)collectionView {
	__weak UICollectionView *weakCollectionView = collectionView;
	_aggregatedTagsCollectionView = weakCollectionView;
	_aggregatedTagsCollectionView.allowsMultipleSelection = NO;
	
	UINib *cellNib = [UINib nibWithNibName:@"PMTagCVCell" bundle:nil];
	[_aggregatedTagsCollectionView registerNib:cellNib forCellWithReuseIdentifier:tagCellIdentifier];
	self.sizingCell = [[cellNib instantiateWithOwner:nil options:nil] objectAtIndex:0];
}

- (void)setSuggestedTagsCollectionView:(UICollectionView *)collectionView {
	__weak UICollectionView *weakCollectionView = collectionView;
	_suggestedTagsCollectionView = weakCollectionView;
	_suggestedTagsCollectionView.allowsMultipleSelection = NO;
	
	_suggestedTagsCollectionView.dataSource = self;
	_suggestedTagsCollectionView.delegate = self;
	
	UINib *cellNib = [UINib nibWithNibName:@"PMTagCVCell" bundle:nil];
	[_suggestedTagsCollectionView registerNib:cellNib forCellWithReuseIdentifier:tagCellIdentifier];
}

- (void)setAggregatedTags:(NSArray *)aggregatedTags {
	_aggregatedTags = [aggregatedTags copy];
	[self.aggregatedTagsCollectionView reloadData];
}

- (void)setSuggestedTags:(NSArray *)suggestedTags {
	_suggestedTags = [suggestedTags copy];
	
	if ([_suggestedTags count]) {
		[self.suggestedTagsCollectionView reloadData];
		self.tagsTextField.inputAccessoryView = self.keyboardAccessory;
		[self.tagsTextField reloadInputViews];
	} else {
		self.tagsTextField.inputAccessoryView = nil;
		[self.tagsTextField reloadInputViews];
	}
}

- (PMInputAccessoryView *)keyboardAccessory {
	if (!_keyboardAccessory) {
		_keyboardAccessory = [[[NSBundle mainBundle] loadNibNamed:@"PMInputAccessoryView" owner:self options:nil] firstObject];
		self.suggestedTagsCollectionView = _keyboardAccessory.collectionView;
	}
	return _keyboardAccessory;
}

#pragma mark - Life Cycle

- (instancetype)init {
	self = [super init];
	if (self) {
		UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteTag)];
		[[UIMenuController sharedMenuController] setMenuItems:@[menuItem]];
	}
	return self;
}

#pragma mark - Actions

- (IBAction)tagsTextFieldEditingChanged:(UITextField *)textField {
	[self updateSuggestedTags];
}

#pragma mark - Methods

- (void)updateFields {
	self.aggregatedTags = self.bookmark.tags;
	[self updateSuggestedTags];
}

- (void)fieldsEnabled:(BOOL)enabled {
	self.aggregatedTagsCollectionView.allowsSelection = enabled;
	self.tagsTextField.enabled = enabled;
}

#pragma mark -

- (void)addTagsFromString:(NSString *)tagsString {
	[self.bookmark addTags:tagsString];
	
	self.aggregatedTags = self.bookmark.tags;
	self.suggestedTags = nil;
	self.tagsTextField.text = @"";
	
	NSIndexPath *lastTagIndexPath = [NSIndexPath indexPathForItem:[self.bookmark.tags count] - 1 inSection:0];
	[self.aggregatedTagsCollectionView scrollToItemAtIndexPath:lastTagIndexPath atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
}

- (void)updateSuggestedTags {
	NSString *tag = self.tagsTextField.text;
	NSArray *tags = [[PMTagStore sharedStore] tagsForUsername:self.bookmark.username];
	if (tags) {
		NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", tag];
		NSMutableArray *results = [NSMutableArray arrayWithArray:[tags filteredArrayUsingPredicate:searchPredicate]];
		[results removeObjectsInArray:self.bookmark.tags];
		self.suggestedTags = results;
	}
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (![textField.text isEqualToString:@""]) {
		[self addTagsFromString:textField.text];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ([textField.text isEqualToString:@""]) {
		if (self.nextResponder) {
			[self.nextResponder becomeFirstResponder];
		} else {
			[textField resignFirstResponder];
		}
	} else {
		[self addTagsFromString:textField.text];
	}
	return NO;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if (collectionView == self.aggregatedTagsCollectionView) {
		return [self.aggregatedTags count];
	} else if (collectionView == self.suggestedTagsCollectionView) {
		return [self.suggestedTags count];
	}
	
	return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:tagCellIdentifier forIndexPath:indexPath];
	PMTagCVCell *tagCell = (PMTagCVCell *)cell;
	
	if (collectionView == self.aggregatedTagsCollectionView) {
		tagCell.label.text = self.aggregatedTags[indexPath.item];
		tagCell.delegate = self;
	} else if (collectionView == self.suggestedTagsCollectionView) {
		tagCell.label.text = self.suggestedTags[indexPath.item];
	}
	
	return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (collectionView == self.suggestedTagsCollectionView) {
		[self addTagsFromString:self.suggestedTags[indexPath.item]];
		self.suggestedTags = nil;
		self.tagsTextField.text = @"";
	}
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (collectionView == self.aggregatedTagsCollectionView) {
		return YES;
	}
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if (collectionView == self.aggregatedTagsCollectionView && action == @selector(deleteTag)) {
		return YES;
	}
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	// This method is here to make the menu controller work
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (collectionView == self.aggregatedTagsCollectionView) {
		self.sizingCell.label.text = self.aggregatedTags[indexPath.item];
	} else if (collectionView == self.suggestedTagsCollectionView) {
		self.sizingCell.label.text = self.suggestedTags[indexPath.item];
	}
	
	return [self.sizingCell suggestedSizeForCell];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake(0, 15, 0, 15);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 1.0;
}

#pragma mark - PMTagCVCellDelegate

- (void)deleteTagForCell:(PMTagCVCell *)cell {
	NSIndexPath *indexPath = [self.aggregatedTagsCollectionView indexPathForCell:cell];
	if (indexPath) {
		NSString *tag = self.aggregatedTags[indexPath.item];
		[self.bookmark removeTag:tag];
		self.aggregatedTags = self.bookmark.tags;
		[self updateSuggestedTags];
	}
}

@end
