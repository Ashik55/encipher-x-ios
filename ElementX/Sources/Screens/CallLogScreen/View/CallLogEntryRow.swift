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
    
    var body: some View {
          Button(action: onRowTapped) {
              HStack(spacing: 12) {
                  // Avatar
                  LoadableAvatarImage(url: call.avatarUrl,
                                      name: call.displayName,
                      contentID: "\(call.callId)",
                      avatarSize: .user(on: .settings),
                      mediaProvider: context.mediaProvider)
                  
                  // Call info
                  VStack(alignment: .leading, spacing: 2) {
                      Text(call.displayName)
                          .font(.headline)
                          .lineLimit(1)
                      
                      HStack(spacing: 4) {
                          // Incoming/outgoing indicator
                          Image(systemName: call.isCaller == true ? "arrow.up.right" : "arrow.down.left")
                              .font(.subheadline)
                              .foregroundColor(call.isCaller == true  ? .blue : .green)
                          
                          Text("\(call.formattedTime)")
                              .font(.subheadline)
                              .foregroundColor(.secondary)

                           Text(" • \(call.getCallDuration)")
                               .font(.subheadline)
                               .foregroundColor(call.endedTs == nil ? .red : .secondary)
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
