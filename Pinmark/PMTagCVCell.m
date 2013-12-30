//
//  PMTagCell.m
//  Pinmark
//
//  Created by Kyle Stevens on 12/27/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import "PMTagCVCell.h"

@implementation PMTagCVCell

- (void)drawRect:(CGRect)rect {
	CGRect insetRect = CGRectInset(rect, 0.5, 0.5);
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:insetRect cornerRadius:rect.size.height/2.0];
	
	[self.tintColor setFill];
	[path fill];
}

@end
