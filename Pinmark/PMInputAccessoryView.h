//
//  PMInputAccessoryView.h
//  Pinmarker
//
//  Created by Kyle Stevens on 1/27/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

@interface PMInputAccessoryView : UIInputView

@property (nonatomic, weak) IBOutlet UIButton *hideKeyboardButton;
@property (nonatomic, weak) IBOutlet UICollectionView *suggestedTagsCollectionView;

- (void)showSuggestedTags;
- (void)hideSuggestedTags;

@end
