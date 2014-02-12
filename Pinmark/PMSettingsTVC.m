//
//  PMSettingsTVC.m
//  Pinmark
//
//  Created by Kyle Stevens on 1/29/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMSettingsTVC.h"
#import "PMAddAccountVC.h"

@interface PMSettingsTVC () <PMAddAccountVCDelegate>
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
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"Login Segue"]) {
		[self setEditing:NO animated:YES];
		UIViewController *destinationVC = segue.destinationViewController;
		PMAddAccountVC *addAccountVC = (PMAddAccountVC *)destinationVC;
		addAccountVC.delegate = self;
		addAccountVC.manager = self.manager;
	}
}

#pragma mark - IBAction

- (IBAction)close:(id)sender {
	[self.delegate shouldCloseSettings];
}

#pragma mark - PMAddAccountVCDelegate

- (void)didAddAccount {
	[self.navigationController popViewControllerAnimated:YES];
	self.accounts = self.manager.associatedUsers;
	[self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	if (section == 0 && row != [self.accounts count]) {
		NSString *account = self.accounts[row];
		[self.manager setDefaultUser:account];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
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
	if (indexPath.row == [self.accounts count]) {
		cell = [tableView dequeueReusableCellWithIdentifier:addAccountCellID forIndexPath:indexPath];
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:accountCellID forIndexPath:indexPath];
		cell.textLabel.text = self.accounts[indexPath.row];
		if ([self.accounts[indexPath.row] isEqualToString:self.manager.defaultUser]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
		} else {
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) return @"Accounts";
	return @"";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == [self.accounts count]) return NO;
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.manager removeAccountForUsername:self.accounts[indexPath.row]];
		self.accounts = self.manager.associatedUsers;
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		if ([self.accounts count] == 0) {
			[self setEditing:NO animated:YES];
		} else {
			NSUInteger defaultUserIndex = [self.accounts indexOfObject:self.manager.defaultUser];
			if (defaultUserIndex != NSNotFound) {
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:defaultUserIndex inSection:0]];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
			}
		}
	}
}

@end
