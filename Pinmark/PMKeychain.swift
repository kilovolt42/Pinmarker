//
//  PMKeychain.swift
//  Pinmarker
//
//  Created by Kyle Stevens on 5/13/18.
//  Copyright © 2018 kilovolt42. All rights reserved.
//

import TinyKeychain

extension Keychain {
    static var pinmarker: Keychain {
        return Keychain(group: nil, accessibilityLevel: .afterFirstUnlock)
    }
}
