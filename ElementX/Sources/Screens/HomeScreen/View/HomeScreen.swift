//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI
import SwiftUIIntrospect

struct SettingsView: View {
    var body: some View {
        List {
            Text("Settings Content")
        }
        .navigationTitle("Settings")
    }
}

struct HomeScreen: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    @ObservedObject var settingsContext: SettingsScreenViewModel.Context
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    
    // Bloom components
    @State private var bloomView: UIView?
    @State private var leftBarButtonView: UIView?
    @State private var gradientView: UIView?
    @State private var navigationBarContainer: UIView?
    @State private var hairlineView: UIView?
    
    @State private var selectedTab = 0
    
    @State private var navigationTitle = "Chat" // Default title for Home tab

    
    
    var body: some View {
        VStack {
            HomeScreenContent(context: context, scrollViewAdapter: scrollViewAdapter)
                .alert(item: $context.alertInfo)
                .alert(item: $context.leaveRoomAlertItem,
                       actions: leaveRoomAlertActions,
                       message: leaveRoomAlertMessage)
                .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
                .toolbar { toolbar }
                .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                .track(screen: .Home)
                .sentryTrace("\(Self.self)")

            // Bottom Bar
            HStack {
                Spacer()
                
                Button(action: {
                    print("Chat button tapped") // Replace with your Chat action
                }) {
                    VStack {
                        Image(systemName: "message.fill")
                            .font(.title2)
                        Text("Chat")
                            .font(.caption)
                    }
                }
//                .padding()
                Spacer()
                Spacer()

                Button(action: {
                    context.send(viewAction: .showSettings)
                }) {
                    VStack {
                        Image(systemName: "gearshape")
                            .font(.title2)
                        Text("Settings")
                            .font(.caption)
                    }
                }
//                .padding()

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1)) // Background for the bottom bar
        }
    }

    private func handleSettingsTapped() {
        // Your function logic here
        print("Settings button tapped")
    }
    
    
//    var body: some View {
//        HomeScreenContent(context: context, scrollViewAdapter: scrollViewAdapter)
//                  .alert(item: $context.alertInfo)
//                  .alert(item: $context.leaveRoomAlertItem,
//                         actions: leaveRoomAlertActions,
//                         message: leaveRoomAlertMessage)
//                  .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
//                  .toolbar { toolbar }
//                  .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
//                  .track(screen: .Home)
//                  .sentryTrace("\(Self.self)")
//    }
    
    
    
    
//    var body: some View {
//    
//            TabView(selection: $selectedTab) {
//                HomeScreenContent(context: context, scrollViewAdapter: scrollViewAdapter)
//                    .onAppear {
//                        navigationTitle = "Chat" // Set title for Home tab
//                    }
//                    .alert(item: $context.alertInfo)
//                    .alert(item: $context.leaveRoomAlertItem,
//                           actions: leaveRoomAlertActions,
//                           message: leaveRoomAlertMessage)
//                    .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
//                    .track(screen: .Home)
//                 
//                    .sentryTrace("\(Self.self)")
//                    .tabItem {
//                        Image(systemName: "message.fill")
//                        Text("Chat")
//                    }
//                    .tag(0)
//                
//           
//                
//                // Settings tab
//                SettingsScreen(context: settingsContext, fromTab: true)
//                    .onAppear {
//                        navigationTitle = "Settings" // Set title for Settings tab
//                    }
//                    .tabItem {
//                        Image(systemName: "gear")
//                        Text("Settings")
//                    }
//                    .tag(1)
//            }
//            .onAppear {
//                configureTabBarAppearance()
//                  }
//            .navigationTitle(navigationTitle) // Use the bound navigation title
//            .toolbar {
//                toolbar
//            }
//            .toolbarBackground(Color.compound.bgCanvasDefault, for: .navigationBar) // Match tab bar background
//            .toolbarBackground(.visible, for: .navigationBar)
//          
//     
//
//    }
    
    
    // Configure Tab Bar Appearance
    private func configureTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor(Color.compound.bgCanvasDefault)
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
    }
    
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                context.send(viewAction: .showSettings)
//                selectedTab = 1
            } label: {
                LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                    name: context.viewState.userDisplayName,
                                    contentID: context.viewState.userID,
                                 
                                    avatarSize: .user(on: .home),
                                    mediaProvider: context.mediaProvider)
                    .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                    .overlayBadge(10, isBadged: context.viewState.requiresExtraAccountSetup)
                    .compositingGroup()
            }
            .accessibilityLabel(L10n.commonSettings)
        }
        
        ToolbarItem(placement: .primaryAction) {
            newRoomButton
        }
    }
    
    
    // MARK: - Private
    
    private var bloomGradient: some View {
        LinearGradient(colors: [.clear, .compound.bgCanvasDefault], startPoint: .top, endPoint: .bottom)
            .mask {
                LinearGradient(stops: [.init(color: .white, location: 0.75), .init(color: .clear, location: 1.0)],
                               startPoint: .leading,
                               endPoint: .trailing)
            }
            .ignoresSafeArea(edges: .all)
    }
            
    private func makeBloomView(controller: UIViewController) {
        guard let navigationBarContainer = controller.navigationController?.navigationBar.subviews.first,
              let leftBarButtonView = controller.navigationItem.leadingItemGroups.first?.barButtonItems.first?.customView else {
            return
        }
        
        let bloomController = UIHostingController(rootView: bloom)
        bloomController.view.translatesAutoresizingMaskIntoConstraints = true
        bloomController.view.backgroundColor = .clear
        navigationBarContainer.insertSubview(bloomController.view, at: 0)
        self.leftBarButtonView = leftBarButtonView
        bloomView = bloomController.view
        self.navigationBarContainer = navigationBarContainer
        updateBloomCenter()
        
        let gradientController = UIHostingController(rootView: bloomGradient)
        gradientController.view.backgroundColor = .clear
        gradientController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContainer.insertSubview(gradientController.view, aboveSubview: bloomController.view)
        
        let constraints = [gradientController.view.bottomAnchor.constraint(equalTo: navigationBarContainer.bottomAnchor),
                           gradientController.view.trailingAnchor.constraint(equalTo: navigationBarContainer.trailingAnchor),
                           gradientController.view.leadingAnchor.constraint(equalTo: navigationBarContainer.leadingAnchor),
                           gradientController.view.heightAnchor.constraint(equalToConstant: 40)]
        constraints.forEach { $0.isActive = true }
        gradientView = gradientController.view
        
        let dividerController = UIHostingController(rootView: Divider().ignoresSafeArea())
        dividerController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContainer.addSubview(dividerController.view)
        let dividerConstraints = [dividerController.view.bottomAnchor.constraint(equalTo: gradientController.view.bottomAnchor),
                                  dividerController.view.widthAnchor.constraint(equalTo: gradientController.view.widthAnchor),
                                  dividerController.view.leadingAnchor.constraint(equalTo: gradientController.view.leadingAnchor)]
        dividerConstraints.forEach { $0.isActive = true }
        hairlineView = dividerController.view
    }

    private func updateBloomCenter() {
        guard let leftBarButtonView,
              let bloomView,
              let navigationBarContainer = bloomView.superview else {
            return
        }
        
        let center = leftBarButtonView.convert(leftBarButtonView.center, to: navigationBarContainer.coordinateSpace)
        bloomView.center = center
    }
    
  
    private var bloom: some View {
        BloomView(context: context)
    }
    
    @ViewBuilder
    private var newRoomButton: some View {
        switch context.viewState.roomListMode {
        case .empty, .rooms:
            Button {
                context.send(viewAction: .startChat)
            } label: {
//                CompoundIcon(\.compose)
                Image(asset: ImageAsset(name: "add"))
                            .resizable() // Ensures the image is resizable
                            .frame(width: 32, height: 32) // Add size here
            }
            .accessibilityLabel(L10n.actionStartChat)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.startChat)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func leaveRoomAlertActions(_ item: LeaveRoomAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle, role: .destructive) {
            context.send(viewAction: .confirmLeaveRoom(roomIdentifier: item.roomID))
        }
    }
    
    private func leaveRoomAlertMessage(_ item: LeaveRoomAlertItem) -> some View {
        Text(item.subtitle)
    }
}

//// MARK: - Previews
//
//struct HomeScreen_Previews: PreviewProvider, TestablePreview {
//    static let loadingViewModel = viewModel(.skeletons)
//    static let emptyViewModel = viewModel(.empty)
//    static let loadedViewModel = viewModel(.rooms)
//    
//    static var previews: some View {
//        NavigationStack {
//            HomeScreen(context: loadingViewModel.context, settingsContext: loadingViewModel.context)
//        }
//        .snapshotPreferences(expect: loadedViewModel.context.$viewState.map { state in
//            state.roomListMode == .skeletons
//        })
//        .previewDisplayName("Loading")
//        
//        NavigationStack {
//            HomeScreen(context: emptyViewModel.context)
//        }
//        .snapshotPreferences(expect: emptyViewModel.context.$viewState.map { state in
//            state.roomListMode == .empty
//        })
//        .previewDisplayName("Empty")
//        
//        NavigationStack {
//            HomeScreen(context: loadedViewModel.context)
//        }
//        .snapshotPreferences(expect: loadedViewModel.context.$viewState.map { state in
//            state.roomListMode == .rooms
//        })
//        .previewDisplayName("Loaded")
//    }
//    
//    static func viewModel(_ mode: HomeScreenRoomListMode) -> HomeScreenViewModel {
//        let userID = "@alice:example.com"
//        
//        let roomSummaryProviderState: RoomSummaryProviderMockConfigurationState = switch mode {
//        case .skeletons:
//            .loading
//        case .empty:
//            .loaded([])
//        case .rooms:
//            .loaded(.mockRooms)
//        }
//        
//        let clientProxy = ClientProxyMock(.init(userID: userID,
//                                                roomSummaryProvider: RoomSummaryProviderMock(.init(state: roomSummaryProviderState))))
//        
//        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
//        
//        return HomeScreenViewModel(userSession: userSession,
//                                   analyticsService: ServiceLocator.shared.analytics,
//                                   appSettings: ServiceLocator.shared.settings,
//                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
//                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
//    }
//}
