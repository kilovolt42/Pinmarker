//
//  PMAddAccountVC.m
//  Pinmarker
//
//  Created by Kyle Stevens on 1/14/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMAddAccountVC.h"
#import "PMAccountStore.h"

@interface PMAddAccountVC () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *tokenTextField;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (nonatomic, weak) IBOutlet UIButton *search1PasswordButton;
@property (nonatomic, weak) IBOutlet UIButton *informationButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *welcomeLabel;
@property (nonatomic, weak) IBOutlet UILabel *instructionsLabel;
@property (nonatomic, weak) IBOutlet UIView *formView;
@property (nonatomic) BOOL updatingExistingAccount;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *instructionsLabelTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *formViewTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *deleteButtonTopConstraint;

@end

@implementation PMAddAccountVC

#pragma mark - Properties

- (void)setUpdatingExistingAccount:(BOOL)updatingExistingAccount {
    _updatingExistingAccount = updatingExistingAccount;
    if (_updatingExistingAccount) {
        self.title = @"Update";
        self.instructionsLabel.text = @"To update, enter the new API token or the account password:";
        self.usernameTextField.enabled = NO;
        [self.submitButton setTitle:@"Update Account" forState:UIControlStateNormal];
        self.deleteButton.hidden = NO;
    } else {
        self.title = @"Add";
        self.instructionsLabel.text = @"Add a Pinboard account:";
        self.usernameTextField.enabled = YES;
        [self.submitButton setTitle:@"Add Account" forState:UIControlStateNormal];
        self.deleteButton.hidden = YES;
    }
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self deactiveActivityIndicator];

    self.search1PasswordButton.hidden = YES;

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
        [self.view addGestureRecognizer:tap];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.username) {
        self.usernameTextField.text = self.username;
        self.updatingExistingAccount = YES;
    } else {
        self.updatingExistingAccount = NO;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

#pragma mark - Methods

- (void)activateActivityIndicator {
    [self.activityIndicator startAnimating];
    self.activityIndicator.hidden = NO;
}

- (void)deactiveActivityIndicator {
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

- (void)dismissKeyboard {
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.tokenTextField resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];

    self.instructionsLabel.alpha = 0.0;
    self.deleteButton.alpha = 0.0;

    CGFloat displacement = self.instructionsLabel.frame.size.height;
    self.formViewTopConstraint.constant = -displacement;
    self.deleteButtonTopConstraint.constant = 2.0 * (displacement + 8.0);
    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];

    self.instructionsLabel.alpha = 1.0;
    self.deleteButton.alpha = 1.0;
    self.formViewTopConstraint.constant = 20.0;
    self.deleteButtonTopConstraint.constant = 8.0;
    [self.view layoutIfNeeded];

    [UIView commitAnimations];
}

- (void)disableFields {
    self.tokenTextField.enabled = NO;
    self.usernameTextField.enabled = NO;
    self.passwordTextField.enabled = NO;
    self.submitButton.enabled = NO;
    self.deleteButton.enabled = NO;
    self.search1PasswordButton.enabled = NO;
    self.informationButton.enabled = NO;
}

- (void)enableFields {
    self.tokenTextField.enabled = YES;
    self.usernameTextField.enabled = YES;
    self.passwordTextField.enabled = YES;
    self.submitButton.enabled = YES;
    self.deleteButton.enabled = YES;
    self.search1PasswordButton.enabled = YES;
    self.informationButton.enabled = YES;
}

#pragma mark - Actions

- (IBAction)submitButtonPressed {
    PMAccountStore *store = [PMAccountStore sharedStore];

    self.instructionsLabel.hidden = YES;
    self.instructionsLabel.text = @" ";
    [self dismissKeyboard];
    [self disableFields];
    [self activateActivityIndicator];

    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordTextField.text;
    NSString *token = self.tokenTextField.text;

    BOOL hasUsernamePassword = username && password && ![username isEqualToString:@""] && ![password isEqualToString:@""];
    BOOL hasAPIToken = token && ![token isEqualToString:@""];

    /*
     * This value should be YES if the request was made using the API token, or
     * NO if the request was made using the username and password.
     */
    __block BOOL requestWithAPIToken = NO;

    BOOL asDefault = [self.delegate shouldAddAccountAsDefault];

    void (^success)(NSDictionary *) = ^(NSDictionary *responseDictionary) {
        [self deactiveActivityIndicator];

        /*
         * We need to store the full token in the format `username:number`.
         * However, the Pinboard API only returns the `number` part. In order
         * for this call to succeed we must either pass in a complete
         * `username:number` token or the username and password. Either way we
         * have enough information to store the full token.
         */
        if (requestWithAPIToken) {
            [store updateAccountForAPIToken:token asDefault:asDefault];
        } else {
            NSString *tokenNumber = responseDictionary[PMPinboardAPIResultKey];
            NSString *fullToken = [username stringByAppendingString:[NSString stringWithFormat:@":%@", tokenNumber]];
            [store updateAccountForAPIToken:fullToken asDefault:asDefault];
        }

        if (self.updatingExistingAccount) {
            [self.delegate didFinishUpdatingAccount];
        } else {
            [self.delegate didFinishAddingAccount];
        }
    };

    void (^failure)(NSError *) = ^(NSError *error) {
        PMLog(@"%@", error);
        [self deactiveActivityIndicator];

        switch (error.code) {
            case -1001:
                self.instructionsLabel.text = @"The connection timed out. Please try again later.";
                break;
            case -1005:
                self.instructionsLabel.text = @"The network connection was lost. Please try again later.";
                break;
            default:
                self.instructionsLabel.text = @"Please try again.";
                break;
        }

        self.instructionsLabel.hidden = NO;
        [self enableFields];
    };

    void (^usernamePasswordFailure)(NSError *) = ^(NSError *error) {
        if (token && ![token isEqualToString:@""]) {
            requestWithAPIToken = YES;
            [PMPinboardService requestAPITokenForAPIToken:token success:success failure:failure];
        } else {
            failure(error);
        }
    };

    if (hasUsernamePassword) {
        [PMPinboardService requestAPITokenForUsername:username password:password success:success failure:usernamePasswordFailure];
    } else if (hasAPIToken) {
        requestWithAPIToken = YES;
        [PMPinboardService requestAPITokenForAPIToken:token success:success failure:failure];
    } else {
        [self deactiveActivityIndicator];
        self.instructionsLabel.text = @"An API token or a username/password pair is required.";
        self.instructionsLabel.hidden = NO;
        [self enableFields];
    }
}

- (IBAction)deleteButtonPressed {
    NSString *title = [NSString stringWithFormat:@"Are you sure you want to delete %@?", self.username];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Delete Account" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.delegate didRequestToRemoveAccountForUsername:self.username];
    }]];

    [self presentViewController:sheet animated:YES completion:nil];
}

- (IBAction)search1PasswordButtonPressed {
}

- (IBAction)informationButtonPressed {
    NSString *message = @"Pinmarker securely stores your Pinboard API Token. Your password is not stored by Pinmarker and is only used to obtain a copy of your API Token. If your Pinboard API Token changes in the future you will need to update Pinmarker to continue bookmarking.";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"About Your Account" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    if (textField == self.passwordTextField) {
        [textField resignFirstResponder];
        if ([textField.text length]) {
            [self submitButtonPressed];
        }
    }
    if (textField == self.tokenTextField) {
        [textField resignFirstResponder];
        if ([textField.text length]) {
            [self submitButtonPressed];
        }
    }
    return YES;
}

@end
