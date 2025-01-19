//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum ShareExtensionConstants {
    static let urlPath = "share"
}

enum ShareExtensionPayload: Hashable, Codable {
    case mediaFile(roomID: String?, mediaFile: ShareExtensionMediaFile)
    case text(roomID: String?, text: String)
    
    var roomID: String? {
        switch self {
        case .mediaFile(let roomID, _),
             .text(let roomID, _):
            roomID
        }
    }
}

struct ShareExtensionMediaFile: Hashable, Codable {
    let url: URL
    let suggestedName: String?
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }

        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
