//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A prompt that asks the user whether they would like to enable Analytics or not.
struct NotificationPermissionsScreen: View {
    @ObservedObject var context: NotificationPermissionsScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            mainContent
        } bottomContent: {
            buttons
        }
//        .background {
//            AuthenticationStartScreenBackgroundImage()
//        }

        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 8) {
            Text("Allow Notifications")
                .font(.compound.headingLGBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .padding(.top, 24)
            
            Text(L10n.screenNotificationOptinTitle)
                .font(.compound.bodyLG)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(L10n.screenNotificationOptinSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
                .padding(.bottom, 24)
            
            Asset.Images.notificationsPromptGraphic.swiftUIImage.resizable().aspectRatio(contentMode: .fit)
        }
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            Button("Allow Notification") { context.send(viewAction: .enable) }
                .buttonStyle(.compound(.primary))
            
            Button { context.send(viewAction: .notNow) } label: {
                Text(L10n.actionNotNow)
                    .font(.compound.bodyLGSemibold)
           
            }    .buttonStyle(.compound(.secondary))
        }
    }
}

// MARK: - Previews

struct NotificationPermissionsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = NotificationPermissionsScreenViewModel(notificationManager: NotificationManagerMock())
    static var previews: some View {
        NotificationPermissionsScreen(context: viewModel.context)
    }
}
