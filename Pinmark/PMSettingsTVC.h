//
//  PMSettingsTVC.h
//  Pinmarker
//
//  Created by Kyle Stevens on 1/29/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

@protocol PMSettingsTVCDelegate

- (void)didRequestToPostWithUsername:(NSString *)username;

@end

@interface PMSettingsTVC : UITableViewController

@property (nonatomic, weak) id<PMSettingsTVCDelegate> delegate;

@end
