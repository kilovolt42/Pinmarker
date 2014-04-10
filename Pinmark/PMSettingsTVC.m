//
//  PMSettingsTVC.m
//  Pinmarker
//
//  Created by Kyle Stevens on 1/29/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMSettingsTVC.h"
#import "PMAddAccountVC.h"
#import "PMAccountStore.h"

@interface PMSettingsTVC () <PMAddAccountVCDelegate>
@property (nonatomic, copy) NSArray *accounts;
@property (nonatomic, readonly) NSString *defaultAccount;
@end

@implementation PMSettingsTVC

#pragma mark - Properties

- (void)setAccounts:(NSArray *)accounts {
	_accounts = accounts;
	
	UIBarButtonItem *closeButton = self.navigationItem.leftBarButtonItem;
	if ([accounts count]) {
		closeButton.title = @"Close";
		closeButton.action = @selector(close:);
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	} else {
		closeButton.title = @"Login";
		closeButton.action = @selector(login:);
		self.navigationItem.rightBarButtonItem = nil;
	}
}

- (NSString *)defaultAccount {
	return [[[PMAccountStore sharedStore].defaultToken componentsSeparatedByString:@":"] firstObject];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Settings";
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadAccounts];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

#pragma mark - Methods

- (void)loadAccounts {
	NSArray *tokens = [PMAccountStore sharedStore].associatedTokens;
	NSMutableArray *accounts = [NSMutableArray new];
	for (NSString *token in tokens) {
		[accounts addObject:[[token componentsSeparatedByString:@":"] firstObject]];
	}
	self.accounts = [accounts copy];
}

- (void)addNewAccount {
	PMAddAccountVC *addAccountVC = [[PMAddAccountVC alloc] init];
	addAccountVC.delegate = self;
	[self.navigationController pushViewController:addAccountVC animated:YES];
}

#pragma mark - Actions

- (IBAction)close:(id)sender {
	[self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)login:(id)sender {
	[self addNewAccount];
}

#pragma mark - PMAddAccountVCDelegate

- (void)didFinishAddingAccount {
	[self.tableView reloadData];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)didFinishUpdatingAccount {
	[self.tableView reloadData];
	[self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldAddAccountAsDefault {
	return NO;
}

- (void)didRequestToRemoveAccountForUsername:(NSString *)username {
	[[PMAccountStore sharedStore] removeAccountForUsername:username];
	[self loadAccounts];
	[self.tableView reloadData];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	
	if (section == 0) {
		if (row == [self.accounts count]) {
			[self addNewAccount];
		} else {
			if (self.isEditing) {
				PMAccountStore *store = [PMAccountStore sharedStore];
				store.defaultToken = [store authTokenForUsername:self.accounts[row]];
				[tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
			} else {
				PMAddAccountVC *addAccountVC = [[PMAddAccountVC alloc] init];
				addAccountVC.delegate = self;
				addAccountVC.username = self.accounts[row];
				[self.navigationController pushViewController:addAccountVC animated:YES];
			}
		}
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) return [self.accounts count] + 1;
	if (section == 1) return 1;
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *accountCellID = @"Account Cell";
	static NSString *addAccountCellID = @"Add Account Cell";
	static NSString *aboutCellID = @"About Cell";
	
	UITableViewCell *cell;
	if (indexPath.section == 0) {
		if (indexPath.row == [self.accounts count]) {
			cell = [tableView dequeueReusableCellWithIdentifier:addAccountCellID forIndexPath:indexPath];
		} else {
			cell = [tableView dequeueReusableCellWithIdentifier:accountCellID forIndexPath:indexPath];
			cell.textLabel.text = self.accounts[indexPath.row];
			if ([self.accounts[indexPath.row] isEqualToString:self.defaultAccount]) {
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
			} else {
				cell.editingAccessoryType = UITableViewCellAccessoryNone;
			}
		}
	}
	else if (indexPath.section == 1) {
		cell = [tableView dequeueReusableCellWithIdentifier:aboutCellID];
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) return @"Accounts";
	return @"";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row != [self.accounts count]) return YES;
	return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[[PMAccountStore sharedStore] removeAccountForUsername:self.accounts[indexPath.row]];
		[self loadAccounts];
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		if ([self.accounts count] == 0) {
			[self setEditing:NO animated:YES];
			[tableView reloadData];
		} else {
			NSUInteger defaultUserIndex = [self.accounts indexOfObject:self.defaultAccount];
			if (defaultUserIndex != NSNotFound) {
				UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:defaultUserIndex inSection:0]];
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
			}
		}
	}
}

@end
