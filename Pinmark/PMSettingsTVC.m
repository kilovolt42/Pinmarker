//
//  PMSettingsTVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/29/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMSettingsTVC.h"
#import "PMAddAccountVC.h"

@interface PMSettingsTVC ()
@property (strong, nonatomic) NSArray *accounts;
@end

@implementation PMSettingsTVC

#pragma mark - Properties

- (void)setManager:(PMPinboardManager *)manager {
	_manager = manager;
	self.accounts = manager.associatedUsers;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Settings";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Login Segue"]) {
		UIViewController *destinationVC = segue.destinationViewController;
		PMAddAccountVC *addAccountVC = (PMAddAccountVC *)destinationVC;
		addAccountVC.manager = self.manager;
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.accounts count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *accountCellID = @"Account Cell";
	static NSString *addAccountCellID = @"Add Account Cell";
	
	UITableViewCell *cell;
	if ([indexPath item] == [self.accounts count]) {
		cell = [tableView dequeueReusableCellWithIdentifier:addAccountCellID forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:accountCellID forIndexPath:indexPath];
		cell.textLabel.text = self.accounts[[indexPath item]];
		if ([self.accounts[[indexPath item]] isEqualToString:self.manager.defaultUser]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return @"Accounts";
}

@end
