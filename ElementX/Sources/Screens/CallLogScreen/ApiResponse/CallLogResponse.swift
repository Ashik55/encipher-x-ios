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
    let callerDisplayName: String?
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

extension CallInfo {
    var displayName: String {
        if !roomName.isNilOrEmpty {
            return roomName!
        } else {
            return isCaller == true ? receiverDisplayNames.values.first ?? "Unknown" : callerDisplayName ?? "N/A"
        }
    }
    
    var avatarUrl: URL? {
        let urlString: String?
        
        if !roomAvatar.isNilOrEmpty {
            urlString = roomAvatar
        } else if isCaller == true {
            urlString = receiverAvatars.values.first
        } else {
            urlString = callerAvatar
        }
        
        return urlString.flatMap { URL(string: $0) }
    }
    
     var formattedTime: String {
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = isoFormatter.date(from: createdTs) else {
            print("Date Parse Failed ==> \(createdTs)")
            return createdTs
        }

        let calendar = Calendar.current
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if calendar.isDateInToday(date) {
            if timeInterval < 60 {
                return "Now"
            } else if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
            } else if timeInterval < 21600 {
                let hours = Int(timeInterval / 3600)
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "'Today,' h:mm a"
                return formatter.string(from: date)
            }
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "'Yesterday,' h:mm a"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    var callDurationText: String {
        guard let endedTs = endedTs else {
            return "Missed"
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let startDate = isoFormatter.date(from: createdTs),
              let endDate = isoFormatter.date(from: endedTs) else {
            return "Unknown duration"
        }
        
        let duration = endDate.timeIntervalSince(startDate)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    var getCallDuration: String {
        guard let endedTs = endedTs else {
            return "Missed"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let startDate = formatter.date(from: createdTs),
              let endDate = formatter.date(from: endedTs) else {
            print("Date parsing failed for createdTs: \(createdTs), endedTs: \(endedTs)")
            return "Unknown"
        }

        let duration = Int(endDate.timeIntervalSince(startDate))

        if duration < 60 {
            return "\(duration) sec"
        } else if duration < 3600 {
            let minutes = duration / 60
            let seconds = duration % 60
            return seconds > 0 ? "\(minutes) min \(seconds) sec" : "\(minutes) min"
        } else {
            let hours = duration / 3600
            let minutes = (duration % 3600) / 60
            return minutes > 0 ? "\(hours) hr \(minutes) min" : "\(hours) hr"
        }
    }
    
    
}
