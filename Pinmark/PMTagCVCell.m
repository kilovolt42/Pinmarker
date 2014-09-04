//
//  PMTagCVCell.m
//  Pinmarker
//
//  Created by Kyle Stevens on 12/27/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMTagCVCell.h"

@implementation PMTagCVCell

#pragma mark - UICollectionViewCell

- (void)drawRect:(CGRect)rect {
	CGRect insetRect = CGRectInset(rect, 0.5, 0.5);
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:insetRect cornerRadius:rect.size.height/2.0];
	
	[self.tintColor setFill];
	[path fill];
}

#pragma mark - Methods

- (CGSize)suggestedSizeForCell {
	[self.label sizeToFit];
	CGSize size = self.label.frame.size;
	size.height = self.frame.size.height;
	size.width += size.height;
	return size;
}

- (void)deleteTag {
	[self.delegate deleteTagForCell:self];
}

@end
