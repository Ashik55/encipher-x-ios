//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct CreatePTTChannelSheet: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    let onChannelCreated: (PTTChannel) -> Void
    let onDismiss: () -> Void

    @State private var channelName: String = ""
    @State private var channelDescription: String = ""
    @State private var userIdsText: String = ""
    @State private var isCreating: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .navigationTitle("Create PTT Channel")
            .navigationBarItems(
                leading: cancelButton,
                trailing: createButton
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK") { showingError = false }
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.compound.iconAccentTertiary)
                    .frame(width: 80, height: 80)

                Image(systemName: "radio")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            Text("Create a new Push to Talk channel")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Channel Name")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("Enter channel name", text: $channelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("Enter channel description", text: $channelDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .autocapitalization(.sentences)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Add Users")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField("Enter user IDs (comma separated)", text: $userIdsText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Text("Enter user IDs separated by commas (e.g., user1, user2, user3)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var cancelButton: some View {
        Button("Cancel") {
            onDismiss()
        }
        .disabled(isCreating)
    }

    private var createButton: some View {
        Button(action: createChannel) {
            if isCreating {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Creating...")
                }
            } else {
                Text("Create")
                    .fontWeight(.semibold)
            }
        }
        .disabled(channelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
    }

    private func createChannel() {
        let trimmedName = channelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = channelDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showError("Channel name is required")
            return
        }

        let userIds = parseUserIds(from: userIdsText)

        guard !userIds.isEmpty else {
            showError("At least one user ID is required")
            return
        }

        isCreating = true

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let newChannel = PTTChannel(
                id: UUID().uuidString,
                name: trimmedName,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                avatarUrl: nil,
                memberCount: userIds.count,
                isActive: true,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                createdBy: "user_demo",
                members: userIds
            )

            self.isCreating = false
            self.onChannelCreated(newChannel)
            self.onDismiss()
        }
    }

    private func parseUserIds(from text: String) -> [String] {
        return text
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}
