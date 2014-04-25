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

@interface PMDescriptionVC () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) PMInputAccessoryView *keyboardAccessory;

@end

@implementation PMDescriptionVC

- (void)setKeyboardAccessory:(PMInputAccessoryView *)keyboardAccessory {
	_keyboardAccessory = keyboardAccessory;
	[_keyboardAccessory.hideKeyboardButton addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventTouchUpInside];
	self.textView.inputAccessoryView = _keyboardAccessory;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.textView.delegate = self;
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

@end
