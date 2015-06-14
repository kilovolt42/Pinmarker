//
//  UIView+Inspectables.swift
//  Pinmarker
//
//  Created by Kyle Stevens on 5/31/15.
//  Copyright (c) 2015 kilovolt42. All rights reserved.
//

import UIKit

extension UIView {
	@IBInspectable var accessibilityID: String? {
		get { return accessibilityIdentifier }
		set { accessibilityIdentifier = newValue }
	}
}
