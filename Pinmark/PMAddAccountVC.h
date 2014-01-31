//
//  PMAddAccountVC.h
//  Pinmark
//
//  Created by Kyle Stevens on 1/14/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PMPinboardManager.h"

@protocol PMAddAccountVCDelegate
- (void)didAddAccount;
@end

@interface PMAddAccountVC : UIViewController

@property (weak, nonatomic) id<PMAddAccountVCDelegate> delegate;
@property (strong, nonatomic) PMPinboardManager *manager;

@end
