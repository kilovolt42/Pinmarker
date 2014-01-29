//
//  PMTagCell.h
//  Pinmark
//
//  Created by Kyle Stevens on 12/27/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMTagCVCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *label;

- (CGSize)suggestedSizeForCell;

@end