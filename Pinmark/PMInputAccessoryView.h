//
//  PMInputAccessoryView.h
//  Pinmark
//
//  Created by Kyle Stevens on 1/27/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMInputAccessoryView : UIInputView

@property (weak, nonatomic) IBOutlet UIButton *hideKeyboardButton;
@property (weak, nonatomic) IBOutlet UICollectionView *suggestedTagsCollectionView;

- (void)showSuggestedTags;
- (void)hideSuggestedTags;

@end
