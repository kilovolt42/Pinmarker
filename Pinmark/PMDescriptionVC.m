//
//  PMDescriptionVC.m
//  Pinmarker
//
//  Created by Kyle Stevens on 4/21/14.
//  Copyright (c) 2014 kilovolt42. All rights reserved.
//

#import "PMDescriptionVC.h"
#import "PMBookmark.h"
#import "PMInputAccessoryView.h"
#import "PSPDFTextView.h"
#import "PMAppDelegate.h"
#import <TextExpander/SMTEDelegateController.h>

@interface PMDescriptionVC () <UITextViewDelegate, SMTEFillDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) PMInputAccessoryView *keyboardAccessory;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textViewBottomConstraint;
@property (nonatomic, readonly) SMTEDelegateController *textExpander;

@end

@implementation PMDescriptionVC

@synthesize textExpander = _textExpander;

#pragma mark - Properties

- (void)setKeyboardAccessory:(PMInputAccessoryView *)keyboardAccessory {
	_keyboardAccessory = keyboardAccessory;
	[_keyboardAccessory.hideKeyboardButton addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
	self.textView.inputAccessoryView = _keyboardAccessory;
}

- (SMTEDelegateController *)textExpander {
	if (!_textExpander) {
		PMAppDelegate *app = [UIApplication sharedApplication].delegate;
		_textExpander = app.textExpander;
	}
	return _textExpander;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (self.textExpander) {
		self.textExpander.nextDelegate = self;
		self.textView.delegate = self.textExpander;
	} else {
		self.textView.delegate = self;
	}
	
	self.textView.text = self.bookmark.extended;
	self.keyboardAccessory = [[[NSBundle mainBundle] loadNibNamed:@"PMInputAccessoryView" owner:self options:nil] firstObject];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if ([self.textView.text length] != 0) {
		[(PSPDFTextView *)self.textView scrollRangeToVisibleConsideringInsets:NSMakeRange(0, 1) animated:NO];
	}
	
	self.textExpander.nextDelegate = self;
	self.textExpander.fillDelegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if ([self.textView.text length] == 0) {
		[self.textView becomeFirstResponder];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[self.textView resignFirstResponder];
	self.bookmark.extended = self.textView.text;
}

- (void)dismissKeyboard {
	[self.textView resignFirstResponder];
}

#pragma mark - Methods

- (void)keyboardWillShow:(NSNotification *)notification {
	CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardFrame = [self.textView convertRect:keyboardFrame fromView:nil];
	
	NSTimeInterval animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	NSInteger animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView animateWithDuration:animationDuration
						  delay:0.0
						options:animationCurve << 16
					 animations:^{
						 CGRect textFrame = self.textView.frame;
						 textFrame.size.height -= keyboardFrame.size.height;
						 self.textView.frame = textFrame;
					 }
					 completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardFrame = [self.textView convertRect:keyboardFrame fromView:nil];
	
	CGRect frame = self.textView.frame;
	frame.size.height += keyboardFrame.size.height;
	self.textView.frame = frame;
}

- (void)textViewDidChange:(UITextView *)textView {
	[self.textView.textStorage edited:NSTextStorageEditedCharacters range:NSMakeRange(0, textView.textStorage.length) changeInLength:0];
}

#pragma mark - SMTEFillDelegate

- (NSString *)identifierForTextArea:(id)textArea {
	NSString *identifier = nil;
	if (textArea == self.textView) {
		identifier = @"descriptionTextView";
	}
	return identifier;
}

- (id)makeIdentifiedTextObjectFirstResponder:(NSString *)textIdentifier fillWasCanceled:(BOOL)userCanceled cursorPosition:(NSInteger *)insertionLocation {
	[self.textView becomeFirstResponder];
	
	UITextPosition *location = [self.textView positionFromPosition:self.textView.beginningOfDocument offset:*insertionLocation];
	if (location) {
		self.textView.selectedTextRange = [self.textView textRangeFromPosition:location toPosition:location];
	} else {
		return nil;
	}
	
	return self.textView;
}

@end
