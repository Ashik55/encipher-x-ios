//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//


import Combine
import SwiftUI

// MARK: - Row Component
struct CallLogEntryRow: View {

    let call: CallInfo
    let context:  HomeScreenViewModel.Context
    let onAudioCallTapped: () -> Void
    let onVideoCallTapped: () -> Void
    let onRowTapped: () -> Void
    
    private var callDisplayName: String {
        if !call.roomName.isNilOrEmpty {
            return call.roomName!
        } else {
            return call.isCaller == true ? call.receiverDisplayNames.values.first ?? "Unknown" : call.callerDisplayName
        }
    }
    
    private var avatarURL: URL? {
        let urlString: String?
        
        if !call.roomAvatar.isNilOrEmpty {
            urlString = call.roomAvatar
        } else if call.isCaller == true {
            urlString = call.receiverAvatars.values.first
        } else {
            urlString = call.callerAvatar
        }
        
        let finalUrl = urlString != nil ? URL(string: urlString!) : nil
        return finalUrl
    }
    
    private var formattedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        if let date = dateFormatter.date(from: call.createdTs) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "d MMM yyyy, h:mm a"
            displayFormatter.locale = Locale(identifier: "en_US_POSIX")
            return displayFormatter.string(from: date)
        } else {
            print("Date Parse Failed ==> \(call.createdTs)")
            return call.createdTs
        }
    }
    
    private var callDuration: String {
        guard let endedTs = call.endedTs else {
            return "Missed"
        }
        
        // Parse timestamps
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let startDate = isoFormatter.date(from: call.createdTs),
              let endDate = isoFormatter.date(from: endedTs) else {
            return "Unknown duration"
        }
        
        let duration = endDate.timeIntervalSince(startDate)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    var body: some View {
          Button(action: onRowTapped) {
              HStack(spacing: 12) {
                  // Avatar
                  LoadableAvatarImage(url: avatarURL,
                      name: callDisplayName,
                      contentID: "\(call.callId)",
                      avatarSize: .user(on: .settings),
                      mediaProvider: context.mediaProvider)
                  
                  // Call info
                  VStack(alignment: .leading, spacing: 2) {
                      Text(callDisplayName)
                          .font(.headline)
                          .lineLimit(1)
                      
                      HStack(spacing: 4) {
                          // Incoming/outgoing indicator
                          Image(systemName: call.isCaller == true ? "arrow.up.right" : "arrow.down.left")
                              .font(.subheadline)
                              .foregroundColor(call.isCaller == true  ? .blue : .green)
                          
                          Text("\(formattedTime)")
                              .font(.subheadline)
                              .foregroundColor(.secondary)
                      }
                  }
                  
                  Spacer()
                  
                  // These buttons will capture their own taps and prevent propagation
                  Group {
                      if call.callType == "audio" {
                          Button(action: onAudioCallTapped) {
                              Image(systemName: "phone")
                                  .resizable()
                                  .frame(width: 17, height: 17)
                          }
                          .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
                          .buttonStyle(BorderlessButtonStyle()) // Important to prevent tap propagation
                      } else {
                          Button(action: onVideoCallTapped) {
                              Image(systemName: "video")
                                  .resizable()
                                  .frame(width: 22, height: 17)
                          }
                          .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
                          .buttonStyle(BorderlessButtonStyle()) // Important to prevent tap propagation
                      }
                  }
              }
              .padding(.vertical, 8)
          }
          .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle for the row button
      }
}

// MARK: - Utility Extensions
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self == nil || self!.isEmpty
    }
}
