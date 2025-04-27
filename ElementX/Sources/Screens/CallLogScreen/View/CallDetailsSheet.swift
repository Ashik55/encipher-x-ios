import Combine
import SwiftUI

struct CallDetailsSheet: View {
    let callInfo: CallInfo
    let roomCallHistory: [CallInfo]
    let isLoading: Bool
    @ObservedObject var context: HomeScreenViewModel.Context
    @Environment(\.dismiss) private var dismiss // to dismiss the sheet
    
    private var callDisplayName: String {
        if !callInfo.roomName.isNilOrEmpty {
            return callInfo.roomName!
        } else {
            return callInfo.isCaller == true ? callInfo.receiverDisplayNames.values.first ?? "Unknown" : callInfo.callerDisplayName
        }
    }
    
    private var avatarURL: URL? {
        let urlString: String?
        
        if !callInfo.roomAvatar.isNilOrEmpty {
            urlString = callInfo.roomAvatar
        } else if callInfo.isCaller == true {
            urlString = callInfo.receiverAvatars.values.first
        } else {
            urlString = callInfo.callerAvatar
        }
        
        return urlString.flatMap(URL.init(string:))
    }
    
    private func formattedTime(for history: CallInfo) -> String {
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
         dateFormatter.locale = Locale(identifier: "en_US_POSIX")
         dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

         if let date = dateFormatter.date(from: history.createdTs) {
             let displayFormatter = DateFormatter()
             displayFormatter.dateFormat = "d MMM yyyy, h:mm a"
             displayFormatter.locale = Locale(identifier: "en_US_POSIX")
             return displayFormatter.string(from: date)
         } else {
             print("Date Parse Failed ==> \(history.createdTs)")
             return history.createdTs
         }
     }
    
    private var callDuration: String {
        guard let endedTs = callInfo.endedTs else {
            return "Missed"
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let startDate = isoFormatter.date(from: callInfo.createdTs),
              let endDate = isoFormatter.date(from: endedTs) else {
            return "Unknown duration"
        }
        
        let duration = endDate.timeIntervalSince(startDate)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Section (Avatar + Name + Close Button)
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        LoadableAvatarImage(url: avatarURL,
                            name: callDisplayName,
                            contentID: "\(callInfo.callId)",
                            avatarSize: .user(on: .editUserDetails),
                            mediaProvider: context.mediaProvider)

                        Text(callDisplayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                   
                }
            }
            .padding(.top, 30)

            // Action Buttons
            HStack(spacing: 40) {
                actionButton(icon: "phone.fill", title: "Audio")
                actionButton(icon: "video.fill", title: "Video")
                actionButton(icon: "message.fill", title: "Message")
            }
            .padding()

            Divider()
            
            // Room Call History
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading call history...")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
            } else if roomCallHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No call history found.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
            } else {
                List {
                    ForEach(roomCallHistory) { history in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(history.callType.capitalized)
                                .font(.headline)
                            Text(formattedTime(for: history))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func actionButton(icon: String, title: String) -> some View {
        VStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                )

            Text(title)
                .font(.footnote)
        }
    }
}
