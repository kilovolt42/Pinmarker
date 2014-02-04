//
//  PMTagsTextField.m
//  Pinmark
//
//  Created by Kyle Stevens on 2/4/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMTagsTextField.h"

@implementation PMTagsTextField

#pragma mark - Properties

- (void)setTarget:(id)target {
	if ([_target respondsToSelector:@selector(deleteTag:)]) {
		_target = target;
	}
}

#pragma mark - UIResponder

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (self.shouldShowTagMenu) {
		if (action == @selector(deleteTag:)) {
			if (self.target) return YES;
		}
		return NO;
	}
	return [super canPerformAction:action withSender:sender];
}

#pragma mark - Methods

- (void)deleteTag:(id)sender {
	[self.target performSelector:@selector(deleteTag:) withObject:sender];
}

@end
