import Combine
import SwiftUI

struct CallDetailsSheet: View {
    let call: CallInfo
    let roomCallHistory: [CallInfo]
    let isLoading: Bool
    @ObservedObject var context: HomeScreenViewModel.Context
    let onAudioCallTapped: () -> Void
    let onVideoCallTapped: () -> Void
    let onMessageTapped: () -> Void
    @Environment(\.dismiss) private var dismiss // to dismiss the sheet
    


    var body: some View {
        VStack(spacing: 0) {
            // Top Section (Avatar + Name + Close Button)
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        LoadableAvatarImage(url: call.avatarUrl,
                                            name: call.displayName,
                            contentID: "\(call.callId)",
                            avatarSize: .user(on: .editUserDetails),
                            mediaProvider: context.mediaProvider)

                        Text(call.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                   
                }
            }
            .padding(.top, 30)

            // Action Buttons
            HStack(spacing: 40) {
                HStack(spacing: 40) {
                    actionButton(icon: "phone.fill", title: "Audio") {
                        dismiss()
                        onAudioCallTapped()
                    }
                    actionButton(icon: "video.fill", title: "Video") {
                        dismiss()
                        onVideoCallTapped()
                    }
                    actionButton(icon: "message.fill", title: "Message") {
                        dismiss()
                        onMessageTapped()
                    }
                }
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
                            
                            HStack(spacing: 4) {
                                // Incoming/outgoing indicator
                                Image(systemName: history.isCaller == true ? "arrow.up.right" : "arrow.down.left")
                                    .font(.subheadline)
                                    .foregroundColor(history.isCaller == true  ? .blue : .green)
                                
                                Text("\(history.formattedTime)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                 Text(" • \(history.getCallDuration)")
                                     .font(.subheadline)
                                     .foregroundColor(history.endedTs == nil ? .red : .secondary)
                            }
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

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        VStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                )
                .onTapGesture {
                    action()
                }

            Text(title)
                .font(.footnote)
        }
    }
}
