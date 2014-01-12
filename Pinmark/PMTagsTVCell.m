//
//  PMTagsTVCell.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/29/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMTagsTVCell.h"
#import "PMTagCVCell.h"

@interface PMTagsTVCell () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) PMTagCVCell *sizingCell;
@end

static NSString *tagCellIdentifier = @"Tag Cell";

@implementation PMTagsTVCell

#pragma mark - Properties

@synthesize tags = _tags;

- (NSMutableArray *)tags {
	if (!_tags) _tags = [NSMutableArray new];
	return _tags;
}

- (void)setTags:(NSMutableArray *)tags {
	_tags = tags;
	[self.collectionView reloadData];
}

- (void)setCollectionView:(UICollectionView *)collectionView {
	_collectionView = collectionView;
	_collectionView.dataSource = self;
	_collectionView.delegate = self;
}

#pragma mark - Methods

- (void)setup {
	self.collectionView.allowsMultipleSelection = NO;
	// TODO: this is hacky, is there a better way?
	for (UIView *subview in self.contentView.subviews) {
		if ([subview isKindOfClass:[UICollectionView class]]) {
			self.collectionView = (UICollectionView *)subview;
			break;
		}
	}
	UINib *cellNib = [UINib nibWithNibName:@"PMTagCVCell" bundle:nil];
	[self.collectionView registerNib:cellNib forCellWithReuseIdentifier:tagCellIdentifier];
	self.sizingCell = [[cellNib instantiateWithOwner:nil options:nil] objectAtIndex:0];
}

- (void)reloadData {
	[self.collectionView reloadData];
}

- (void)deleteTag:(id)sender {
	NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
	if ([selectedItems count]) {
		NSIndexPath *selectedItem = selectedItems[0];
		[self.tags removeObjectAtIndex:[selectedItem item]];
		[self.collectionView deleteItemsAtIndexPaths:@[selectedItem]];
	}
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
	[self becomeFirstResponder];
	UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
	
	UIMenuController *menuController = [UIMenuController sharedMenuController];
	UIMenuItem *deleteTag = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteTag:)];
	[menuController setMenuItems:@[deleteTag]];
	[menuController setTargetRect:cell.frame inView:collectionView];
	[menuController setMenuVisible:YES animated:YES];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	self.sizingCell.label.text = self.tags[[indexPath item]];
	return [self.sizingCell suggestedSizeForCell];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake(0, 15, 0, 15);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 1.0;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self.tags count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:tagCellIdentifier forIndexPath:indexPath];
	((PMTagCVCell *)cell).label.text = self.tags[indexPath.item];
	return cell;
}

@end
