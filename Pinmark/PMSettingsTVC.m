//
//  PMSettingsTVC.m
//  Pinmarker
//
//  Created by Kyle Stevens on 1/29/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMSettingsTVC.h"
#import "PMAppDelegate.h"
#import "PMAddAccountVC.h"
#import "PMAccountStore.h"

NSString * const PMAccountsSectionLabel = @"Accounts";
NSString * const PMAddAccountSectionLabel = @"Add Account";
NSString * const PMInformationSectionLabel = @"Information";

@interface PMSettingsTVC () <PMAddAccountVCDelegate>

@property (nonatomic, copy) NSArray *accounts;
@property (nonatomic, copy) NSDictionary *tableSections;
@property (nonatomic) NSDateFormatter *dateFormatter;

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

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [NSDateFormatter new];
		_dateFormatter.dateStyle = NSDateFormatterLongStyle;
	}
	return _dateFormatter;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Settings";
	
	self.tableSections = @{ @0 : PMAccountsSectionLabel,
							@1 : PMAddAccountSectionLabel,
							@2 : PMInformationSectionLabel };
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self loadAccounts];
	[self.tableView reloadData];
}

#pragma mark - Methods

- (void)loadAccounts {
	self.accounts = [PMAccountStore sharedStore].associatedUsernames;
}

- (void)addNewAccount {
	PMAddAccountVC *addAccountVC = [[PMAddAccountVC alloc] init];
	addAccountVC.delegate = self;
	[self.navigationController pushViewController:addAccountVC animated:YES];
}

#pragma mark - Actions

- (IBAction)close:(id)sender {
	[self.delegate didRequestToPostWithUsername:[PMAccountStore sharedStore].defaultUsername];
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
	
	NSString *sectionLabel = self.tableSections[@(indexPath.section)];
	NSInteger row = indexPath.row;
	
	if ([sectionLabel isEqualToString:PMAccountsSectionLabel]) {
		if (self.isEditing || [self.accounts count] == 1) {
			PMAddAccountVC *addAccountVC = [[PMAddAccountVC alloc] init];
			addAccountVC.delegate = self;
			addAccountVC.username = self.accounts[row];
			[self.navigationController pushViewController:addAccountVC animated:YES];
		} else {
			PMAccountStore *store = [PMAccountStore sharedStore];
			store.defaultUsername = self.accounts[row];
			[tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
	else if ([sectionLabel isEqualToString:PMAddAccountSectionLabel]) {
		[self addNewAccount];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.tableSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSString *sectionLabel = self.tableSections[@(section)];
	
	if ([sectionLabel isEqualToString:PMAccountsSectionLabel]) {
		return [self.accounts count];
	}
	else if ([sectionLabel isEqualToString:PMAddAccountSectionLabel]) {
		return 1;
	}
	else if ([sectionLabel isEqualToString:PMInformationSectionLabel]) {
		return 1;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *accountCellID = @"Account Cell";
	static NSString *addAccountCellID = @"Add Account Cell";
	static NSString *aboutCellID = @"About Cell";
	
	NSString *sectionLabel = self.tableSections[@(indexPath.section)];
	
	UITableViewCell *cell;
	if ([sectionLabel isEqualToString:PMAccountsSectionLabel]) {
		cell = [tableView dequeueReusableCellWithIdentifier:accountCellID forIndexPath:indexPath];
		cell.textLabel.text = self.accounts[indexPath.row];
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		if ([self.accounts count] > 1) {
			if ([self.accounts[indexPath.row] isEqualToString:[PMAccountStore sharedStore].defaultUsername]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
		} else {
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
	}
	else if ([sectionLabel isEqualToString:PMAddAccountSectionLabel]) {
		cell = [tableView dequeueReusableCellWithIdentifier:addAccountCellID forIndexPath:indexPath];
	}
	else if ([sectionLabel isEqualToString:PMInformationSectionLabel]) {
		cell = [tableView dequeueReusableCellWithIdentifier:aboutCellID];
	}
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *sectionLabel = self.tableSections[@(section)];
	if ([sectionLabel isEqualToString:PMAddAccountSectionLabel]) {
		return nil;
	}
	return sectionLabel;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	NSString *sectionLabel = self.tableSections[@(section)];
	if ([sectionLabel isEqualToString:PMAccountsSectionLabel] && [[PMAccountStore sharedStore].associatedUsernames count] > 1) {
		return @"Select which account to bookmark with. To update an account, tap Edit and select an account to update.";
	}
	return @"";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *sectionLabel = self.tableSections[@(indexPath.section)];
	if ([sectionLabel isEqualToString:PMAccountsSectionLabel]) {
		return YES;
	}
	return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSArray *accountsKeys = [self.tableSections allKeysForObject:PMAccountsSectionLabel];
		NSNumber *accountsKey = self.tableSections[[accountsKeys firstObject]];
		NSInteger accountsSection = [accountsKey integerValue];
		
		[[PMAccountStore sharedStore] removeAccountForUsername:self.accounts[indexPath.row]];
		[self loadAccounts];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:accountsSection] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		if ([self.accounts count] == 0) {
			[self setEditing:NO animated:YES];
			[tableView reloadData];
		} else if ([self.accounts count] == 1) {
			[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:accountsSection inSection:0]].accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else {
			NSUInteger defaultUserIndex = [self.accounts indexOfObject:[PMAccountStore sharedStore].defaultUsername];
			if (defaultUserIndex != NSNotFound) {
				[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:defaultUserIndex inSection:accountsSection]].editingAccessoryType = UITableViewCellAccessoryCheckmark;
			}
		}
	}
}

@end
