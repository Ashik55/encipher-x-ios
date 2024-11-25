//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// The background gradient shown on the launch, splash and onboarding screens.
struct AuthenticationStartScreenBackgroundImage: View {
    var body: some View {
//        // Background image placed using absolute positioning
//           Image("ic_lock")
//               .resizable()
//               .scaledToFit()
//               .frame(height:UIScreen.main.bounds.height - 250)
//               .position(x: UIScreen.main.bounds.width - 160, y: UIScreen.main.bounds.height - 300) // Fixed position based on screen bounds
//               .ignoresSafeArea() // To allow the image to go beyond safe areas if needed
//
        Image(asset:  ImageAsset(name: "auth-background-grad"))
            .resizable()
            .scaledToFill()
//            .frame(width: UIScreen.main.bounds.width - 100, height: UIScreen.main.bounds.height - 250)
         
            .ignoresSafeArea()
//            .accessibilityHidden(true)
        
//        Image(asset: Asset.Images.launchBackground)
//            .resizable()
//            .scaledToFill()
//            .ignoresSafeArea()
//            .accessibilityHidden(true)
    }
}


struct HomeScreenBackgroundImage: View {
    var body: some View {
        Image(asset:  ImageAsset(name: "home-bg"))
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()


    }
}
