//
//  PMAccountStoreTests.swift
//  Pinmarker
//
//  Created by Kyle Stevens on 5/11/18.
//  Copyright © 2018 kilovolt42. All rights reserved.
//

import XCTest
@testable import Pinmarker

class PMAccountStoreTests: XCTestCase {
    func testSetUnfamiliarUsernameAsDefault() {
        PMAccountStoreSwift.sharedStore.defaultUsername = "foobar"
        XCTAssertNil(PMAccountStoreSwift.sharedStore.defaultUsername, "defaultUsername should be nil after an attempt to set an unfamiliar username")
    }
}
