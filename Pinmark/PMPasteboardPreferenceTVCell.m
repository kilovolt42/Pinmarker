//
//  PMURLFromClipboardTVCell.m
//  Pinmark
//
//  Created by Kyle Stevens on 2/16/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMPasteboardPreferenceTVCell.h"
#import "PMAppDelegate.h"

@interface PMPasteboardPreferenceTVCell ()
@property (nonatomic, weak) IBOutlet UISwitch *preferenceSwitch;
@end

@implementation PMPasteboardPreferenceTVCell

- (void)setup {
	NSNumber *pasteboardPreferenceWrapper = [[NSUserDefaults standardUserDefaults] objectForKey:PMPasteboardPreferenceKey];
	self.preferenceSwitch.on = [pasteboardPreferenceWrapper boolValue];
	self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (IBAction)toggledSwitch:(UISwitch *)sender {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[NSNumber numberWithBool:sender.on] forKey:PMPasteboardPreferenceKey];
	[userDefaults synchronize];
}

@end
