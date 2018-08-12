//
//  AccountProvider.swift
//  PinmarkerKit
//
//  Created by Kyle Stevens on 8/12/18.
//  Copyright © 2018 kilovolt42. All rights reserved.
//

import Foundation

extension UserDefaults {
    struct Keys {
        static let defaultUsername = "PMDefaultUsernameKey"
    }
}

/**
 Provides account usernames and tokens.

 Notifications are posted when tokens are added, updated, or removed. Each
 notification sends the affected username in the `userInfo` dictionary for the
 key `PMAccountStoreUsernameKey`.

 To be notified about changes to the default username use KVO to observe the
 `defaultUsername` property.
 */
class AccountProvider {
    var defaultUsername: String?
    private(set) var associatedUsernames = [String]()

    /**
     Adds or updates the given API token. This will update the default username
     if `asDefault` is set to `true` or if there is no default username.

     - parameter token: The API token to add or update.
     - parameter asDefault: Sets the username as the default.
     */
    func updateAccount(forAPIToken token: String, asDefault: Bool) {

    }

    /**
     Removes the API token associated with the username. If the username
     corresponds to the default username then a new default will be assigned.

     - parameter username: The username of the API token to remove.
     */
    func removeAccount(forUsername username: String) {

    }

    /**
     Returns the full API token associated with the username.

     - parameter username: The username of the requested API token.
     - returns: A full API token or `nil` if the username is unfamiliar.
     */
    func authToken(forUsername username: String) -> String? {
        return nil
    }
}
