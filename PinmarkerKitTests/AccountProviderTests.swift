//
//  AccountProviderTests.swift
//  PinmarkerKitTests
//
//  Created by Kyle Stevens on 8/12/18.
//  Copyright © 2018 kilovolt42. All rights reserved.
//

import XCTest
@testable import PinmarkerKit

class AccountProviderTests: XCTestCase {
    let accountProvider = AccountProvider()

    func testSetUnfamiliarUsernameAsDefault() {
        accountProvider.defaultUsername = "foobar"
        XCTAssertNil(accountProvider.defaultUsername, "defaultUsername should be nil after an attempt to set an unfamiliar username")
    }
}
