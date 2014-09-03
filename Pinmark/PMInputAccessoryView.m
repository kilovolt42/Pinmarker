//
//  PMInputAccessoryView.m
//  Pinmarker
//
//  Created by Kyle Stevens on 1/27/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMInputAccessoryView.h"

static void * PMInputAccessoryContext = &PMInputAccessoryContext;

@implementation PMInputAccessoryView

- (void)awakeFromNib {
	[_collectionView addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionInitial context:&PMInputAccessoryContext];
}

- (void)dealloc {
	[_collectionView removeObserver:self forKeyPath:@"hidden"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PMInputAccessoryContext) {
		if ([keyPath isEqualToString:@"hidden"]) {
			self.hideButton.hidden = !self.collectionView.hidden;
		}
	}
}

@end
