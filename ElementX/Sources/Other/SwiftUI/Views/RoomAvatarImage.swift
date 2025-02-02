//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Information about a room avatar such as it's URL or the heroes to use as a fallback.
enum RoomAvatar: Equatable {
    /// An avatar generated from the room's details.
    case room(id: String, name: String?, avatarURL: URL?, isDirect: Bool?)
    /// An avatar generated from the room's heroes.
    case heroes([UserProfileProxy])
}

/// A view that shows the avatar for a room, or a cluster of heroes if provided.
///
/// This should be preferred over `LoadableAvatarImage` when displaying a
/// room avatar so that DMs have a consistent appearance throughout the app.
struct RoomAvatarImage: View {
    let avatar: RoomAvatar
    
    let avatarSize: Avatars.Size
    let mediaProvider: MediaProviderProtocol?
    
    private(set) var onAvatarTap: ((URL) -> Void)?
    
    var body: some View {
        switch avatar {
        case .room(let id, let name, let avatarURL, let isDirect):
            RoomLoadableAvatarImage(url: avatarURL,
                                name: name,
                                contentID: id,
                                isDirect: isDirect,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider,
                                onTap: onAvatarTap)
        case .heroes(let users):
            // We will expand upon this with more stack sizes in the future.
            if users.count == 0 {
                let _ = assertionFailure("We should never pass empty heroes here.")
                PlaceholderAvatarImage(name: nil, contentID: nil)
            }
            
            else if users.count == 2 {
                ZStack {
                    LoadableAvatarImage(url: users[1].avatarURL,
                                        name: users[1].displayName,
                                        contentID: users[1].userID,
                                        avatarSize: avatarSize,
                                        mediaProvider: mediaProvider,
                                        onTap: onAvatarTap)
                    
                    
                    // Add a margin to the left of this avatar
                     HStack {
                         Spacer().frame(width: avatarSize.value) // Adjust the width as needed
                         LoadableAvatarImage(
                             url: users[0].avatarURL,
                             name: users[0].displayName,
                             contentID: users[0].userID,
                             avatarSize: avatarSize,
                             mediaProvider: mediaProvider,
                             onTap: onAvatarTap
                         )
                     }
                    
                }
            }
            
            
            else {
                LoadableAvatarImage(url: users[0].avatarURL,
                                    name: users[0].displayName,
                                    contentID: users[0].userID,
                                    avatarSize: avatarSize,
                                    mediaProvider: mediaProvider,
                                    onTap: onAvatarTap)
            }
        }
    }
}

struct NewRoomAvatarImage: View {
    let avatar: RoomAvatar
    let isDirect: Bool?
    let avatarSize: Avatars.Size
    let mediaProvider: MediaProviderProtocol?
    
    private(set) var onAvatarTap: ((URL) -> Void)?
    
    var body: some View {
        switch avatar {
        case .room(let id, let name, let avatarURL,let isDirect):
            RoomLoadableAvatarImage(url: avatarURL,
                                name: name,
                                contentID: id,
                                isDirect: isDirect,
                                avatarSize: avatarSize,
                                mediaProvider: mediaProvider,
                                onTap: onAvatarTap)
        case .heroes(let users):
            // We will expand upon this with more stack sizes in the future.
            if users.count == 0 {
                let _ = assertionFailure("We should never pass empty heroes here.")
                PlaceholderAvatarImage(name: nil, contentID: nil)
            }
            
            else if users.count == 2 {
                ZStack {
                    LoadableAvatarImage(url: users[1].avatarURL,
                                        name: users[1].displayName,
                                        contentID: users[1].userID,
                                        avatarSize: avatarSize,
                                        mediaProvider: mediaProvider,
                                        onTap: onAvatarTap)
                    
                    
                    // Add a margin to the left of this avatar
                     HStack {
                         Spacer().frame(width: avatarSize.value) // Adjust the width as needed
                         LoadableAvatarImage(
                             url: users[0].avatarURL,
                             name: users[0].displayName,
                             contentID: users[0].userID,
                             avatarSize: avatarSize,
                             mediaProvider: mediaProvider,
                             onTap: onAvatarTap
                         )
                     }
                    
                }
            }
            
            
            else {
                LoadableAvatarImage(url: users[0].avatarURL,
                                    name: users[0].displayName,
                                    contentID: users[0].userID,
                                    avatarSize: avatarSize,
                                    mediaProvider: mediaProvider,
                                    onTap: onAvatarTap)
            }
        }
    }
}

//struct RoomAvatarImage_Previews: PreviewProvider, TestablePreview {
//    static var previews: some View {
//        HStack(spacing: 8) {
//            RoomAvatarImage(avatar: .room(id: "!1:server.com",
//                                          name: "Room",
//                                          avatarURL: nil),
//                            avatarSize: .room(on: .home),
//                            mediaProvider: MediaProviderMock(configuration: .init()))
//            
//            RoomAvatarImage(avatar: .room(id: "!2:server.com",
//                                          name: "Room",
//                                          avatarURL: .mockMXCAvatar),
//                            avatarSize: .room(on: .home),
//                            mediaProvider: MediaProviderMock(configuration: .init()))
//            
//            RoomAvatarImage(avatar: .heroes([.init(userID: "@user:server.com",
//                                                   displayName: "User",
//                                                   avatarURL: nil)]),
//            avatarSize: .room(on: .home),
//            mediaProvider: MediaProviderMock(configuration: .init()))
//            
//            RoomAvatarImage(avatar: .heroes([.init(userID: "@user:server.com",
//                                                   displayName: "User",
//                                                   avatarURL: .mockMXCAvatar)]),
//            avatarSize: .room(on: .home),
//            mediaProvider: MediaProviderMock(configuration: .init()))
//            
//            RoomAvatarImage(avatar: .heroes([.init(userID: "@alice:server.com", displayName: "Alice", avatarURL: nil),
//                                             .init(userID: "@bob:server.net", displayName: "Bob", avatarURL: nil)]),
//                            avatarSize: .room(on: .home),
//                            mediaProvider: MediaProviderMock(configuration: .init()))
//        }
//    }
//}
