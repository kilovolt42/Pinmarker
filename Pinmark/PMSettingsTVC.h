//
//  PMSettingsTVC.h
//  Pinmark
//
//  Created by Kyle Stevens on 1/29/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMPinboardManager.h"

@protocol PMSettingsTVCDelegate
- (void)shouldCloseSettings;
@end

@interface PMSettingsTVC : UITableViewController

@property (nonatomic, weak) id<PMSettingsTVCDelegate> delegate;
@property (nonatomic) PMPinboardManager *manager;

@end
