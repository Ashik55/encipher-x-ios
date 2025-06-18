//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//




import SwiftUI
import Compound
import AVFoundation
import UIKit

struct PTTDetailsScreen: View {
    let channel: PTTChannel
    @ObservedObject var context: HomeScreenViewModel.Context
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isPTTActive: Bool = false
    @State private var isHoldingPTT: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordingURL: URL?
    @State private var hasRecordingPermission: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                channelHeaderSection
                channelInfoSection
                pttControlSection
                membersSection
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(channel.name)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            setupAudio()
        }
    }
    
    private var channelHeaderSection: some View {
        VStack(spacing: 16) {
            // Channel avatar
            ZStack {
                Circle()
                    .fill(channel.isActive ? Color.green.opacity(0.2) : Color.compound.iconAccentTertiary)
                    .frame(width: 100, height: 100)
                
                if let avatarUrl = channel.avatarUrl, !avatarUrl.isEmpty {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "radio")
                            .foregroundColor(.white)
                            .font(.system(size: 40))
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "radio")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                }
                
                // Active indicator
                if channel.isActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            
            // Channel status
            HStack(spacing: 8) {
                Circle()
                    .fill(channel.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(channel.isActive ? "Active Channel" : "Inactive Channel")
                    .font(.subheadline)
                    .foregroundColor(channel.isActive ? Color.green : Color.secondary)
            }
        }
    }
    
    private var channelInfoSection: some View {
        VStack(spacing: 16) {
            if let description = channel.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Members")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(channel.memberCount) participants")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Created")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(formatDate(channel.createdAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var pttControlSection: some View {
        VStack(spacing: 20) {
            Text("Push to Talk")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // PTT Button
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(isHoldingPTT ? Color.red : Color.compound.iconAccentTertiary)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isHoldingPTT ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isHoldingPTT)
                    
                    VStack(spacing: 8) {
                        Image(systemName: isHoldingPTT ? "mic.fill" : "mic")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                        
                        Text(isHoldingPTT ? "TALKING" : "HOLD TO TALK")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PTTButtonStyle(
                isPressed: $isHoldingPTT,
                onPressStart: startRecording,
                onPressEnd: stopRecording
            ))
            .disabled(!channel.isActive || !hasRecordingPermission)
            
            if !channel.isActive {
                Text("Channel is currently inactive")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !hasRecordingPermission {
                Text("Microphone permission required")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Channel Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // View Members Button
                Button(action: {
                    // TODO: Navigate to members list
                }) {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.compound.iconAccentTertiary)
                        Text("View Members")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.compound.bgSubtleSecondary)
                    .cornerRadius(8)
                }
                
                // Leave Channel Button
                Button(action: {
                    // TODO: Leave channel action
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Text("Leave Channel")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.compound.bgSubtleSecondary)
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Audio Setup and Recording Functions
    
    private func setupAudio() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.hasRecordingPermission = granted
            }
        }
        
        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func startRecording() {
        guard hasRecordingPermission else { return }
        
        // Haptic feedback on press start
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Create recording URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("ptt_recording_\(Date().timeIntervalSince1970).m4a")
        
        guard let url = recordingURL else { return }
        
        // Recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            print("Started recording")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        // Haptic feedback on release
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        // Auto-play the recorded audio
        playRecordedAudio()
        print("Stopped recording")
    }
    
    private func playRecordedAudio() {
        guard let url = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            print("Playing recorded audio")
        } catch {
            print("Failed to play recorded audio: \(error)")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Simple date formatting - you might want to use a proper DateFormatter
        return dateString.components(separatedBy: "T").first ?? dateString
    }
}

// MARK: - PTT Button Style
struct PTTButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let onPressStart: () -> Void
    let onPressEnd: () -> Void
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                if pressed && !isPressed {
                    // Button just got pressed
                    isPressed = true
                    onPressStart()
                } else if !pressed && isPressed {
                    // Button just got released
                    isPressed = false
                    onPressEnd()
                }
            }
    }
}


//
//import SwiftUI
//import Compound
//
//struct PTTDetailsScreen: View {
//    let channel: PTTChannel
//    @ObservedObject var context: HomeScreenViewModel.Context
//    @Environment(\.presentationMode) var presentationMode
//    
//    @State private var isPTTActive: Bool = false
//    @State private var isHoldingPTT: Bool = false
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 24) {
//                channelHeaderSection
//                channelInfoSection
//                pttControlSection
//                membersSection
//                Spacer(minLength: 32)
//            }
//            .padding(.horizontal, 20)
//            .padding(.top, 20)
//        }
//        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
//        .navigationTitle(channel.name)
//        .navigationBarBackButtonHidden(false)
//    }
//    
//    private var channelHeaderSection: some View {
//        VStack(spacing: 16) {
//            // Channel avatar
//            ZStack {
//                Circle()
//                    .fill(channel.isActive ? Color.green.opacity(0.2) : Color.compound.iconAccentTertiary)
//                    .frame(width: 100, height: 100)
//                
//                if let avatarUrl = channel.avatarUrl, !avatarUrl.isEmpty {
//                    AsyncImage(url: URL(string: avatarUrl)) { image in
//                        image
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                    } placeholder: {
//                        Image(systemName: "radio")
//                            .foregroundColor(.white)
//                            .font(.system(size: 40))
//                    }
//                    .frame(width: 100, height: 100)
//                    .clipShape(Circle())
//                } else {
//                    Image(systemName: "radio")
//                        .foregroundColor(.white)
//                        .font(.system(size: 40))
//                }
//                
//                // Active indicator
//                if channel.isActive {
//                    VStack {
//                        Spacer()
//                        HStack {
//                            Spacer()
//                            Circle()
//                                .fill(Color.green)
//                                .frame(width: 20, height: 20)
//                                .overlay(
//                                    Circle()
//                                        .stroke(Color.white, lineWidth: 3)
//                                )
//                        }
//                    }
//                    .frame(width: 100, height: 100)
//                }
//            }
//            
//            // Channel status
//            HStack(spacing: 8) {
//                Circle()
//                    .fill(channel.isActive ? Color.green : Color.gray)
//                    .frame(width: 8, height: 8)
//                
//                Text(channel.isActive ? "Active Channel" : "Inactive Channel")
//                    .font(.subheadline)
//                    .foregroundColor(channel.isActive ? Color.green : Color.secondary)
//            }
//        }
//    }
//    
//    private var channelInfoSection: some View {
//        VStack(spacing: 16) {
//            if let description = channel.description, !description.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Description")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    Text(description)
//                        .font(.body)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.leading)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            
//            HStack {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Members")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    Text("\(channel.memberCount) participants")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//                
//                VStack(alignment: .trailing, spacing: 4) {
//                    Text("Created")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    Text(formatDate(channel.createdAt))
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//    }
//    
//    private var pttControlSection: some View {
//        VStack(spacing: 20) {
//            Text("Push to Talk")
//                .font(.title2)
//                .fontWeight(.semibold)
//                .foregroundColor(.primary)
//            
//            // PTT Button
//            Button(action: {}) {
//                ZStack {
//                    Circle()
//                        .fill(isHoldingPTT ? Color.red : Color.compound.iconAccentTertiary)
//                        .frame(width: 120, height: 120)
//                        .scaleEffect(isHoldingPTT ? 1.1 : 1.0)
//                        .animation(.easeInOut(duration: 0.1), value: isHoldingPTT)
//                    
//                    VStack(spacing: 8) {
//                        Image(systemName: isHoldingPTT ? "mic.fill" : "mic")
//                            .font(.system(size: 36))
//                            .foregroundColor(.white)
//                        
//                        Text(isHoldingPTT ? "TALKING" : "HOLD TO TALK")
//                            .font(.caption)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                    }
//                }
//            }
//            .buttonStyle(PTTButtonStyle(isPressed: $isHoldingPTT))
//            .disabled(!channel.isActive)
//            
//            if !channel.isActive {
//                Text("Channel is currently inactive")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//        }
//    }
//    
//    private var membersSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Channel Actions")
//                .font(.headline)
//                .foregroundColor(.primary)
//            
//            VStack(spacing: 12) {
//                // View Members Button
//                Button(action: {
//                    // TODO: Navigate to members list
//                }) {
//                    HStack {
//                        Image(systemName: "person.2")
//                            .foregroundColor(.compound.iconAccentTertiary)
//                        Text("View Members")
//                            .foregroundColor(.primary)
//                        Spacer()
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(.secondary)
//                            .font(.caption)
//                    }
//                    .padding(.vertical, 12)
//                    .padding(.horizontal, 16)
//                    .background(Color.compound.bgSubtleSecondary)
//                    .cornerRadius(8)
//                }
//                
//                // Leave Channel Button
//                Button(action: {
//                    // TODO: Leave channel action
//                }) {
//                    HStack {
//                        Image(systemName: "rectangle.portrait.and.arrow.right")
//                            .foregroundColor(.red)
//                        Text("Leave Channel")
//                            .foregroundColor(.red)
//                        Spacer()
//                    }
//                    .padding(.vertical, 12)
//                    .padding(.horizontal, 16)
//                    .background(Color.compound.bgSubtleSecondary)
//                    .cornerRadius(8)
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//    
//    private func formatDate(_ dateString: String) -> String {
//        // Simple date formatting - you might want to use a proper DateFormatter
//        return dateString.components(separatedBy: "T").first ?? dateString
//    }
//}
//
//// MARK: - PTT Button Style
//struct PTTButtonStyle: ButtonStyle {
//    @Binding var isPressed: Bool
//    
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .onChange(of: configuration.isPressed) { pressed in
//                isPressed = pressed
//            }
//    }
//}
