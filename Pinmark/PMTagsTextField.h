//
//  PMTagsTextField.h
//  Pinmark
//
//  Created by Kyle Stevens on 2/4/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMTagsTextField : UITextField

@property (weak, nonatomic) id target;
@property (assign, nonatomic, getter=shouldShowTagMenu) BOOL showTagMenu;

@end
