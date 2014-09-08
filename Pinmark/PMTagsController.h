//
//  PMTagsController.h
//  Pinmarker
//
//  Created by Kyle Stevens on 9/3/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

@class PMBookmark;

@interface PMTagsController : UIResponder

@property (nonatomic, weak) PMBookmark *bookmark;

@property (nonatomic, weak) IBOutlet UITextField *tagsTextField;
@property (nonatomic, weak) IBOutlet UIResponder *nextResponder; // next element to become responder when tagsTextField returns
@property (nonatomic, weak) IBOutlet UICollectionView *aggregatedTagsCollectionView;
@property (nonatomic, weak) UICollectionView *suggestedTagsCollectionView;

- (void)updateFields;
- (void)fieldsEnabled:(BOOL)enabled;

@end
