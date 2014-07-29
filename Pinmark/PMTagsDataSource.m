//
//  PMTagsDataSource.m
//  Pinmarker
//
//  Created by Kyle Stevens on 1/23/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMTagsDataSource.h"
#import "PMTagCVCell.h"

static NSString *tagCellIdentifier = @"Tag Cell";

@implementation PMTagsDataSource

#pragma mark - Properties

- (NSArray *)tags {
	if (!_tags) _tags = @[];
	return _tags;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self.tags count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:tagCellIdentifier forIndexPath:indexPath];
	((PMTagCVCell *)cell).label.text = self.tags[[indexPath item]];
	return cell;
}

@end
