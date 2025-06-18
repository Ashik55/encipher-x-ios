//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - ViewModel

class PTTDetailsViewModel: ObservableObject {
    @Published var isHoldingPTT = false

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?

    private let recordingUrl: URL = {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("ptt_recording.m4a")
    }()

    func startRecording() {
        // Haptic feedback on start
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingUrl, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isHoldingPTT = true
        } catch {
            print("Failed to start recording:", error)
            isHoldingPTT = false
        }
    }

    func stopRecordingAndPlay() {
        audioRecorder?.stop()
        isHoldingPTT = false

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordingUrl)
            audioPlayer?.play()
        } catch {
            print("Failed to play recording:", error)
        }
    }
}
