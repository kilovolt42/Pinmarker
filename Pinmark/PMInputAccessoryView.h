//
//  PMInputAccessoryView.h
//  Pinmarker
//
//  Created by Kyle Stevens on 1/27/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

/**
 * The hide button and collection view are intended to mutually
 * exclusively visible. Setting the hidden property of the collection
 * view will automatically set the hide button's hidden property to
 * the inverse. The collection view is hidden by default.
 */
@interface PMInputAccessoryView : UIInputView

@property (nonatomic, weak) IBOutlet UIButton *hideButton;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end
