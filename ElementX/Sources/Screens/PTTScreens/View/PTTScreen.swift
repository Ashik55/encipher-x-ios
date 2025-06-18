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
import Combine
import Compound
import SwiftUI
import SwiftUIIntrospect

struct PTTScreen: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    @StateObject private var viewModel: PTTViewModel
    @State private var showingCreateChannelSheet = false
    @State private var selectedChannel: PTTChannel?

    init(context: HomeScreenViewModel.Context) {
        _viewModel = StateObject(wrappedValue: PTTViewModel())
        self.context = context
    }

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Push to Talk")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        createChannelButton
                    }
                }
                .onAppear {
                    viewModel.onAppear()
                }
                .sheet(isPresented: $showingCreateChannelSheet) {
                    CreatePTTChannelSheet(
                        context: context,
                        onChannelCreated: { channel in
                            viewModel.addNewChannel(channel)
                        },
                        onDismiss: {
                            showingCreateChannelSheet = false
                        }
                    )
                }
                .navigationDestination(item: $selectedChannel) { channel in
                    PTTDetailsScreen(channel: channel, context: context)
                }
        }
    }

    private var createChannelButton: some View {
        Button(action: {
            showingCreateChannelSheet = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
        }
    }

    private var contentView: some View {
        ZStack {
            Color.compound.bgCanvasDefault.ignoresSafeArea()

            if viewModel.viewState.channels.isEmpty {
                emptyStateView
            } else {
                channelGridView
            }
        }
    }

    private var emptyStateView: some View {
        Group {
            if viewModel.viewState.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else if viewModel.viewState.error != nil {
                VStack(spacing: 16) {
                    Text("Unable to load PTT channels")
                        .font(.headline)

                    Button("Retry") {
                        viewModel.send(viewAction: .refresh)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "radio")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    VStack(spacing: 8) {
                        Text("No PTT Channels")
                            .font(.headline)

                        Text("Create your first channel to start communicating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button("Create Channel") {
                        showingCreateChannelSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    private var channelGridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.viewState.channels) { channel in
                    PTTChannelGridItem(
                        channel: channel,
                        onTapped: {
                            selectedChannel = channel
                        }
                    )
                    .onAppear {
                        checkForPagination(channel: channel)
                    }
                }

                if viewModel.viewState.isLoading && !viewModel.viewState.channels.isEmpty {
                    loadingGridItem
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .refreshable {
            viewModel.send(viewAction: .refresh)
        }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private var loadingGridItem: some View {
        VStack {
            ProgressView()
                .padding()
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(12)
    }

    private func checkForPagination(channel: PTTChannel) {
        if channel.id == viewModel.viewState.channels.last?.id && viewModel.viewState.hasMorePages {
            viewModel.send(viewAction: .fetchNextPage)
        }
    }
}

// MARK: - PTT Channel Grid Item

struct PTTChannelGridItem: View {
    let channel: PTTChannel
    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.compound.iconAccentTertiary)
                        .frame(width: 50, height: 50)

                    if let avatarUrl = channel.avatarUrl, !avatarUrl.isEmpty {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "radio")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "radio")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }

                VStack(spacing: 4) {
                    Text(channel.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(channel.memberCount) members")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if channel.isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color.compound.bgSubtleSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(channel.isActive ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
