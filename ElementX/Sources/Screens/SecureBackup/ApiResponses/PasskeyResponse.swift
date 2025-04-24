//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct CreatePasskeyResponse: Codable {
    let requester: String
    let passkey: String
    let passphrase: String
    let encryptedPasskey: String?

    enum CodingKeys: String, CodingKey {
        case requester
        case passkey
        case passphrase
        case encryptedPasskey = "encrypted_passkey"
    }
}

struct GetPasskeyResponse: Codable {
    let passkey: String
}

struct checkPassKeyResponse: Codable {
    let user_id: String?
    let has_passkey: Bool?
}

