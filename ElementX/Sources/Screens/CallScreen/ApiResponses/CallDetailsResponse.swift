//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Call Model
struct Call: Codable, Identifiable {
    let callId: Int
    let callerUserId: String
    let roomId: String
    let callType: String
    let createdTs: String
    let endedTs: String?

    var id: Int { callId }

    enum CodingKeys: String, CodingKey {
        case callId = "call_id"
        case callerUserId = "caller_user_id"
        case roomId = "room_id"
        case callType = "call_type"
        case createdTs = "created_ts"
        case endedTs = "ended_ts"
    }
}

// MARK: - Call Details Response
struct CallDetailsResponse: Codable {
    let calls: [Call]
    let nextPage: String?
    let prevPage: String?

    enum CodingKeys: String, CodingKey {
        case calls
        case nextPage = "next_page"
        case prevPage = "prev_page"
    }
}

// MARK: - Create Call Response (Alias)
typealias CreateCallResponse = Call
