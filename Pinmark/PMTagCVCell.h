//
//  PMTagCVCell.h
//  Pinmarker
//
//  Created by Kyle Stevens on 12/27/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

@class PMTagCVCell;

@protocol PMTagCVCellDelegate <NSObject>

- (void)deleteTagForCell:(PMTagCVCell *)cell;

@end

@interface PMTagCVCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) id<PMTagCVCellDelegate> delegate;

- (CGSize)suggestedSizeForCell;
- (void)deleteTag;

@end
