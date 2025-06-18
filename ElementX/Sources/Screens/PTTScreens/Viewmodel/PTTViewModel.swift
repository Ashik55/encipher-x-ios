//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine
import SwiftUI

// MARK: - View Actions
enum PTTViewAction {
    case fetchNextPage
    case refresh
    case createChannel(PTTChannelCreateRequest)
}

// MARK: - View State
struct PTTViewState {
    var channels: [PTTChannel] = []
    var isLoading: Bool = false
    var hasMorePages: Bool = true
    var error: Error?
    var currentPage: Int = 0
}

struct PTTChannel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let avatarUrl: String?
    let memberCount: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let createdBy: String
    let members: [String]? // User IDs

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case avatarUrl = "avatar_url"
        case memberCount = "member_count"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case members
    }
}

struct PTTChannelCreateRequest: Codable {
    let name: String
    let description: String?
    let userIds: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case userIds = "user_ids"
    }
}

// MARK: - ViewModel
class PTTViewModel: ObservableObject {
    @Published private(set) var viewState = PTTViewState()
    @Published var selectedChannel: PTTChannel? = nil

    func selectChannel(_ channel: PTTChannel) {
        selectedChannel = channel
    }

    func addNewChannel(_ channel: PTTChannel) {
        viewState.channels.insert(channel, at: 0)
    }

    func send(viewAction: PTTViewAction) {
        switch viewAction {
        case .fetchNextPage:
            fetchChannels(page: viewState.currentPage + 1)
        case .refresh:
            refresh()
        case .createChannel(let request):
            createChannel(request: request)
        }
    }

    func onAppear() {
        refresh()
    }

    private func refresh() {
        viewState.channels = []
        viewState.currentPage = 0
        viewState.hasMorePages = true
        fetchChannels(page: 1)
    }

    private func fetchChannels(page: Int) {
        guard viewState.hasMorePages && !viewState.isLoading else { return }
        viewState.isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let dummyChannels = (1...10).map { index in
                PTTChannel(
                    id: UUID().uuidString,
                    name: "Channel \(index + (page - 1) * 10)",
                    description: "This is a demo channel description.",
                    avatarUrl: nil, // Replace with URL(string:) if needed
                    memberCount: Int.random(in: 2...20),
                    isActive: Bool.random(),
                    createdAt: "2025-06-17T12:00:00Z",
                    updatedAt: "2025-06-17T12:00:00Z",
                    createdBy: "user_demo",
                    members: []
                )
            }

            self.viewState.channels.append(contentsOf: dummyChannels)
            self.viewState.hasMorePages = page < 2 // Only 2 pages
            self.viewState.currentPage = page
            self.viewState.isLoading = false
            self.viewState.error = nil
        }
    }

    private func createChannel(request: PTTChannelCreateRequest) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let newChannel = PTTChannel(
                id: UUID().uuidString,
                name: request.name,
                description: request.description,
                avatarUrl: nil,
                memberCount: request.userIds.count,
                isActive: true,
                createdAt: "2025-06-17T12:00:00Z",
                updatedAt: "2025-06-17T12:00:00Z",
                createdBy: "user_demo",
                members: request.userIds
            )

            self.viewState.channels.insert(newChannel, at: 0)
        }
    }
}
