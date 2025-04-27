//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Call Model
struct CallInfo: Codable, Identifiable {
    let callId: Int
    let callerUserId: String
    let roomId: String
    let callType: String
    let createdTs: String
    let endedTs: String?
    let callerDisplayName: String
    let roomName: String?
    let roomAvatar: String?
    let callerAvatar: String?
    let isCaller: Bool?
    let receiverUserIds: [String]
    let receiverDisplayNames: [String: String]
    let receiverAvatars: [String: String]

    var id: Int { callId }

    enum CodingKeys: String, CodingKey {
        case callId = "call_id"
        case callerUserId = "caller_user_id"
        case roomId = "room_id"
        case callType = "call_type"
        case createdTs = "created_ts"
        case endedTs = "ended_ts"
        case callerDisplayName = "caller_display_name"
        case roomName = "room_name"
        case roomAvatar = "room_avatar"
        case callerAvatar = "caller_avatar"
        case isCaller = "is_caller"
        case receiverUserIds = "receiver_user_ids"
        case receiverDisplayNames = "receiver_display_names"
        case receiverAvatars = "receiver_avatars"
    }
}

// MARK: - Call Log Response
struct CallLogResponse: Codable {
    let calls: [CallInfo]
    let nextPage: Int?
    let prevPage: Int?

    enum CodingKeys: String, CodingKey {
        case calls
        case nextPage = "next_page"
        case prevPage = "prev_page"
    }
}
