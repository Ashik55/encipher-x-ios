//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum AppDelegateCallback {
    case registeredNotifications(deviceToken: Data)
    case failedToRegisteredNotifications(error: Error)
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    let callbacks = PassthroughSubject<AppDelegateCallback, Never>()
    var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Add a SceneDelegate to the SwiftUI scene so that we can connect up the WindowManager.
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NSTextAttachment.registerViewProviderClass(PillAttachmentViewProvider.self, forFileType: InfoPlistReader.main.pillsUTType)
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert the device token to a string representation
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("Device_Token==>: \(tokenString)")
        
        ///check bundle-id
        ///
        /// var environmentMessage: String {
        #if DEBUG
        print("Environment==>: Development (Debug)")
        #else
        print( "Environment==>: Production (Release)")
        #endif

    
        if let bundleID = Bundle.main.bundleIdentifier {
                            print("Bundle ID==>: \(bundleID)")
                        } else {
                            print("Bundle ID not found")
                        }
        
        callbacks.send(.registeredNotifications(deviceToken: deviceToken))
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications==>: \(error)")
        callbacks.send(.failedToRegisteredNotifications(error: error))
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        orientationLock
    }
}
