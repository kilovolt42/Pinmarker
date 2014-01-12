//
//  PMTagsTVCell.h
//  Pinmark
//
//  Created by Kyle Stevens on 12/29/13.
//  Copyright (c) 2013 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMTagsTVCell : UITableViewCell

@property (strong, nonatomic) NSMutableArray *tags;

- (void)setup;
- (void)reloadData;

@end
