//
//  PMTagsTVCell.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/29/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMTagsTVCell.h"
#import "PMTagCVCell.h"

@interface PMTagsTVCell () <UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, readonly) UICollectionView *collectionView;
@property (strong, nonatomic) PMTagCVCell *sizingCell;
@end

@implementation PMTagsTVCell

#pragma mark - Properties

- (void)setTags:(NSArray *)tags {
	_tags = tags;
	[self.collectionView reloadData];
}

#pragma mark - Initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
		layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		_collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
		[self.contentView addSubview:_collectionView];
		[self configureCollectionView:_collectionView];
		
		UINib *cellNib = [UINib nibWithNibName:@"PMTagCVCell" bundle:nil];
		[self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Tag Cell"];
		self.sizingCell = [[cellNib instantiateWithOwner:nil options:nil] objectAtIndex:0];
	}
	return self;
}

#pragma mark - Methods

- (void)configureCollectionView:(UICollectionView *)collectionView {
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	
	[self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
	NSArray *constraints = @[[NSLayoutConstraint constraintWithItem:self.collectionView
														  attribute:NSLayoutAttributeLeft
														  relatedBy:NSLayoutRelationEqual
															 toItem:_collectionView.superview
														  attribute:NSLayoutAttributeLeft
														 multiplier:1.0
														   constant:0.0],
							 [NSLayoutConstraint constraintWithItem:self.collectionView
														  attribute:NSLayoutAttributeRight
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.collectionView.superview
														  attribute:NSLayoutAttributeRight
														 multiplier:1.0
														   constant:0.0],
							 [NSLayoutConstraint constraintWithItem:self.collectionView
														  attribute:NSLayoutAttributeTop
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.collectionView.superview
														  attribute:NSLayoutAttributeTop
														 multiplier:1.0
														   constant:0.0],
							 [NSLayoutConstraint constraintWithItem:self.collectionView
														  attribute:NSLayoutAttributeBottom
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.collectionView.superview
														  attribute:NSLayoutAttributeBottom
														 multiplier:1.0
														   constant:0.0]];
	[self.contentView addConstraints:constraints];
	
	self.collectionView.backgroundColor = [UIColor whiteColor];
	self.collectionView.showsHorizontalScrollIndicator = NO;
}

- (void)configureTagCell:(PMTagCVCell *)cell forIndexPath:(NSIndexPath *)indexPath {
	cell.tagLabel.text = self.tags[indexPath.item];
}

#pragma mark - UICollectionViewDelegate

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	[self configureTagCell:self.sizingCell forIndexPath:indexPath];
	return [self.sizingCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
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
	UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"Tag Cell" forIndexPath:indexPath];
	if ([cell isKindOfClass:[PMTagCVCell class]]) {
		[self configureTagCell:(PMTagCVCell *)cell forIndexPath:indexPath];
	}
	return cell;
}

@end
