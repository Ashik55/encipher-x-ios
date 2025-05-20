//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import Foundation

enum CallScreenViewModelAction {
    case pictureInPictureIsAvailable(AVPictureInPictureController)
    case pictureInPictureStarted
    case pictureInPictureStopped
    case dismiss
}



struct CallScreenViewState: BindableState {
    let messageHandler: String
    let script: String?
    var url: URL?
    
    let certificateValidator: CertificateValidatorHookProtocol
    
    var bindings = Bindings()
    
    // New properties to store extracted values
    var roomId: String?
    var displayName: String?
    var isAudioCall: Bool?
    var callId: Int?
    var urlUserId: String?
    
    
    
  
    var userId: String?
    var theme: String?
    var language: String?
    var baseUrl: String?
    var widgetId: String?
    var clientId: String?
    var deviceId: String?
    var parentUrl: String?
    var skipLobby: Bool?
    var confineToRoom: Bool?
    var appPrompt: Bool?
    var hideHeader: Bool?
    var preload: Bool?
    var perParticipantE2EE: Bool?
}

struct Bindings {
    var javaScriptMessageHandler: ((Any) -> Void)?
    var javaScriptEvaluator: ((String) async throws -> Any)?
    var requestPictureInPictureHandler: (() async -> Result<Void, CallScreenError>)?
    
    var alertInfo: AlertInfo<UUID>?
}

enum CallScreenViewAction {
    case urlChanged(URL?)
    case pictureInPictureIsAvailable(AVPictureInPictureController)
    case navigateBack
    case pictureInPictureWillStop
    case endCall
}

enum CallScreenError: Error {
    case pictureInPictureNotAvailable
}
