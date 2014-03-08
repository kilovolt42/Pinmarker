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

- (void)didFinishAddingAccount;
- (BOOL)shouldAddAccountAsDefault;

@end

@interface PMAddAccountVC : UIViewController

@property (nonatomic, weak) id<PMAddAccountVCDelegate> delegate;

@end
