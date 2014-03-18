//
//  PMAddAccountVC.h
//  Pinmark
//
//  Created by Kyle Stevens on 1/14/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PMAddAccountVCDelegate

- (void)didFinishAddingAccount;
- (void)didFinishUpdatingAccount;
- (BOOL)shouldAddAccountAsDefault;

@optional

- (void)didRequestToRemoveAccountForUsername:(NSString *)username;

@end

@interface PMAddAccountVC : UIViewController

@property (nonatomic, weak) id<PMAddAccountVCDelegate> delegate;
@property (nonatomic) NSString *username;

@end
