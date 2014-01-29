//
//  PMInputAccessoryView.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/27/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMInputAccessoryView.h"

@implementation PMInputAccessoryView

- (void)showSuggestedTags {
	self.hideKeyboardButton.hidden = YES;
	self.suggestedTagsCollectionView.hidden = NO;
}

- (void)hideSuggestedTags {
	self.suggestedTagsCollectionView.hidden = YES;
	self.hideKeyboardButton.hidden = NO;
}

@end
