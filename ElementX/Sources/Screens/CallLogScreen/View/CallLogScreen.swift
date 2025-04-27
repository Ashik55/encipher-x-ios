//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI
import SwiftUIIntrospect


struct CallLogScreen: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    @StateObject private var viewModel: CallLogViewModel
    @State private var selectedCall: CallInfo? = nil
    @State private var showingCallActionModal = false
    
    init(userID: String = "current-user-id" , context: HomeScreenViewModel.Context) {
        _viewModel = StateObject(wrappedValue: CallLogViewModel(userID: userID))
        self.context = context
    }
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Call Log")
                .onAppear {
                    viewModel.onAppear()
                }
                .sheet(item: $viewModel.selectedCallInfo) { callInfo in
                    CallDetailsSheet(
                        callInfo: callInfo,
                        roomCallHistory: viewModel.viewState.roomCallHistory,
                        isLoading : viewModel.viewState.isRoomCallHistoryLoading,
                        context: context)
                }
                
        }
    }
    
    // Break down the main content into a separate computed property
    private var contentView: some View {
        ZStack {
            Color.compound.bgCanvasDefault.ignoresSafeArea()
            
            if viewModel.viewState.callLogs.isEmpty {
                emptyStateView
            } else {
                callListView
            }
        }
    }
    
    // Handle empty states
    private var emptyStateView: some View {
        Group {
            if viewModel.viewState.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else if viewModel.viewState.error != nil {
                VStack(spacing: 16) {
                    Text("Unable to load call history")
                        .font(.headline)
                    
                    Button("Retry") {
                        viewModel.send(viewAction: .refresh)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                Text("No call history found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    
    private var callListView: some View {
        List {
            callsSection
                .listRowSeparator(.hidden, edges: .top)  // Hides the divider at the top of first item


            if viewModel.viewState.isLoading && !viewModel.viewState.callLogs.isEmpty {
                loadingIndicator
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.send(viewAction: .refresh)
        }
    }

    
    private var callsSection: some View {
        ForEach(viewModel.viewState.callLogs) { call in
            CallLogEntryRow(call: call, context: context,
            onAudioCallTapped: {
                context.send(viewAction: .makeAudioCallScreen(roomID: call.roomId))
            },
            onVideoCallTapped: {
                context.send(viewAction: .makeVideoCallScreen(roomID: call.roomId))
            },
            onRowTapped: {
                viewModel.selectCall(call)
            })

            .onAppear {
                checkForPagination(call: call)
            }
        }
    }
    
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding(.vertical)
        .listRowSeparator(.hidden)
    }
    
    private func checkForPagination(call: CallInfo) {
        // Load more when reaching the end of the list
        if call.id == viewModel.viewState.callLogs.last?.id && viewModel.viewState.hasMorePages {
            viewModel.send(viewAction: .fetchNextPage)
        }
    }
}




//
//
//    .sheet(isPresented: $showingCallActionModal) {
//                   if let call = selectedCall {
//                       CallActionModal(
//                           call: call,
//                           context: context,
//                           onDismiss: {
//                               showingCallActionModal = false
//                           },
//                           onAudioCallTapped: {
//                               showingCallActionModal = false
//                               context.send(viewAction: .makeAudioCallScreen(roomID: call.roomId))
//                           },
//                           onVideoCallTapped: {
//                               showingCallActionModal = false
//                               context.send(viewAction: .makeVideoCallScreen(roomID: call.roomId))
//                           },
//                           onMessageTapped: {
//                               showingCallActionModal = false
//                               // Navigate to message screen with this user
////                                           context.send(viewAction: .navigateToChat(roomID: call.roomId))
//                           }
//                       )
//                       .presentationDetents([.height(350)])
//                   }
//               }
