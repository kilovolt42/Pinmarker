//
//  AccountProviderTests.swift
//  PinmarkerKitTests
//
//  Created by Kyle Stevens on 8/12/18.
//  Copyright © 2018 kilovolt42. All rights reserved.
//

import XCTest
import TinyKeychain
@testable import PinmarkerKit

private extension Keychain {
    static var mock: Keychain {
        return Keychain(group: nil, accessibilityLevel: .afterFirstUnlock)
    }
}

class AccountProviderTests: XCTestCase {
    let accountProvider = AccountProvider(keychain: .mock)

    func testSetUnfamiliarUsernameAsDefault() {
        accountProvider.defaultUsername = "foobar"
        XCTAssertNil(accountProvider.defaultUsername, "defaultUsername should be nil after an attempt to set an unfamiliar username")
    }
}
