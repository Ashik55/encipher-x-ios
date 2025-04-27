//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//


import Combine
import SwiftUI


enum CallLogViewAction {
    case fetchNextPage
    case fetchRoomCallHistory(roomID: String)
    case refresh
}

struct CallLogViewState {
    var callLogs: [CallInfo] = []
    var isLoading: Bool = false
    var hasMorePages: Bool = true
    var error: Error?
    var currentPage: Int = 0
    
    
    //Call Log Details
    var roomCallHistory: [CallInfo] = []
    var isRoomCallHistoryLoading: Bool = false
    var roomHistoryError: Error?
    
}



// MARK: - ViewModel
class CallLogViewModel: ObservableObject {
    @Published private(set) var viewState = CallLogViewState()
    @Published var selectedCallInfo: CallInfo? = nil
    
    private let userID: String
    
    init(userID: String) {
        self.userID = userID
    }
    
    


    func selectCall(_ callInfo: CallInfo) {
        selectedCallInfo = callInfo
        send(viewAction: .fetchRoomCallHistory(roomID: callInfo.roomId))
    }
    
    
    func send(viewAction: CallLogViewAction) {
        switch viewAction {
        case .fetchNextPage:
            fetchCallLogs(page: viewState.currentPage + 1)
        case .refresh:
            refresh()
        case .fetchRoomCallHistory(roomID: let roomID):
            fetchRoomCallHistory(roomId: roomID)
        }
    }
    
    func onAppear() {
        // Reset and fetch new data whenever the screen appears
        refresh()
    }
    
    private func refresh() {
        viewState.callLogs = []
        viewState.currentPage = 0
        viewState.hasMorePages = true
        fetchCallLogs(page: 1)
    }
    
    
    private func fetchCallLogs(page: Int) {
        guard viewState.hasMorePages && !viewState.isLoading else { return }
        viewState.isLoading = true
        // Calculate pagination parameters
        let pageSize = 20
        let limit = pageSize
        
        Task {
            do {
                // Call your API method
                let response: CallLogResponse = try await APIClient.request(
                    path: "call/\(userID)?limit=\(limit)&page=\(page)",
                    method: .GET
                )
                // Update the UI on the main thread
                await MainActor.run {
                    // Append new call logs to existing ones
                    self.viewState.callLogs.append(contentsOf: response.calls)
                    self.viewState.hasMorePages = response.nextPage != nil
                    self.viewState.currentPage = page
                    self.viewState.error = nil
                    self.viewState.isLoading = false
                }
            } catch {
                // Handle errors on the main thread
                await MainActor.run {
                    self.viewState.error = error
                    self.viewState.isLoading = false
                    print("Error fetching call logs: \(error)")
                }
            }
        }
    }
    
    
    
    private func fetchRoomCallHistory(roomId: String) {
    
        print("fetchRoomCallHistory Running")
        
        viewState.isRoomCallHistoryLoading = true
        // Calculate pagination parameters
        let pageSize = 20
        let limit = pageSize
        
        Task {
            do {
              
             
                
                
                // Call your API method
                let response: CallLogResponse = try await APIClient.request(
                    path: "call/\(userID)?room_id=\(roomId)",
                    method: .GET
                )
                
                print("fetchRoomCallHistory Response==>>\(response)")
                
                // Update the UI on the main thread
                await MainActor.run {
                    // Append new call logs to existing ones
                    self.viewState.roomCallHistory = response.calls
                    self.viewState.isRoomCallHistoryLoading = false
                }
            } catch {
                // Handle errors on the main thread
                await MainActor.run {
                    self.viewState.roomHistoryError = error
                    self.viewState.isRoomCallHistoryLoading = false
                    print("Error fetching call History: \(error)")
                }
            }
        }
    }
    
    
 
}

