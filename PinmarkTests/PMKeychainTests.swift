//
//  PMKeychainTests.swift
//  Pinmarker
//
//  Created by Kyle Stevens on 5/13/18.
//  Copyright © 2018 kilovolt42. All rights reserved.
//

import XCTest
import TinyKeychain
@testable import Pinmarker

class PMKeychainTests: XCTestCase {
    func testKeychainExists() {
        XCTAssertNotNil(Keychain.pinmarker, "Pinmarker keychain should exist")
    }
}
