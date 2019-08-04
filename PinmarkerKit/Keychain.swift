//
//  Keychain.swift
//  Pinmarker
//
//  Created by Kyle Stevens on 5/13/18.
//  Copyright © 2018 kilovolt42. All rights reserved.
//

import TinyKeychain

public extension Keychain {
    static var pinmarker: Keychain {
        return Keychain(group: nil, accessibilityLevel: .afterFirstUnlock)
    }
}

public extension Keychain.Key {
    static var associatedTokens: Keychain.Key<[String]> {
        return Keychain.Key<[String]>(rawValue: "PMAssociatedTokensKey", synchronize: true)
    }
}
