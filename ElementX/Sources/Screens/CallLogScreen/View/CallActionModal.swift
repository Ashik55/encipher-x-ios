//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
import Combine
import SwiftUI


struct CallActionModal: View {
    let call: CallInfo
    let onDismiss: () -> Void
    let onAudioCallTapped: () -> Void
    let onVideoCallTapped: () -> Void
    let onMessageTapped: () -> Void
    let context: HomeScreenViewModel.Context
    

    
    init(call: CallInfo, context: HomeScreenViewModel.Context, onDismiss: @escaping () -> Void,
         onAudioCallTapped: @escaping () -> Void, onVideoCallTapped: @escaping () -> Void,
         onMessageTapped: @escaping () -> Void) {
        self.call = call
        self.context = context
        self.onDismiss = onDismiss
        self.onAudioCallTapped = onAudioCallTapped
        self.onVideoCallTapped = onVideoCallTapped
        self.onMessageTapped = onMessageTapped
    }
    
    
    
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
        VStack(spacing: 24) {
            // Close button at top-right
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title)
                }
            }
            .padding(.bottom, 8)
            
            LoadableAvatarImage(url: avatarURL,
                name: callDisplayName,
                contentID: "\(call.callId)",
                avatarSize: .user(on: .settings),
                mediaProvider: context.mediaProvider)
            
            // User name
            Text(callDisplayName)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 16)
            
            // Call action buttons
            HStack(spacing: 36) {
                // Audio call button
                VStack {
                    Button(action: onAudioCallTapped) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    Text("Audio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                // Video call button
                VStack {
                    Button(action: onVideoCallTapped) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "video.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    Text("Video")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                // Message button
                VStack {
                    Button(action: onMessageTapped) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "message.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            )
                    }
                    Text("Message")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.compound.bgCanvasDefault)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .frame(maxWidth: 320)
        .onAppear {
//            // You can add any additional loading logic here if needed
//            if let userID = call.userID {
//                // Example: Load user avatar URL from a user service
//                // context.userService.getUserAvatar(userID: userID) { url in
//                //     self.avatarURL = url
//                // }
//            }
        }
    }
}
