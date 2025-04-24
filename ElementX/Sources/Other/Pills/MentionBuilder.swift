//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct MentionBuilder: MentionBuilderProtocol {
    
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String, userDisplayName: String?) {
        print("---- Mention Debug Info ==>>")
        print("URL: \(url)")
        print("UserID: \(userID)")
        print("UserDisplayName: \(userDisplayName ?? "nil")")
        print("Range: \(range)")
        print("Attributed String (before): \(attributedString)")
        
        let attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: range)
        let font = attributes[.font] as? UIFont ?? .preferredFont(forTextStyle: .body)
        let blockquote = attributes[.MatrixBlockquote]
        let foregroundColor = attributes[.foregroundColor] as? UIColor ?? .compound.textPrimary
        
        // Create attributes for the formatted mention
        var linkAttributes: [NSAttributedString.Key: Any] = [
            .link: url,
            .MatrixUserID: userID,
            .font: font,
            .foregroundColor: foregroundColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        if let blockquote {
            linkAttributes[.MatrixBlockquote] = blockquote
        }
        
        // Create a new string with the display name or user ID fullname
//        let displayText = userDisplayName ?? userID
        let displayText = userDisplayName ?? (userID.components(separatedBy: ":").first ?? userID)
        let mentionString = NSMutableAttributedString(string: displayText)
        mentionString.addAttributes(linkAttributes, range: NSRange(location: 0, length: mentionString.length))
        
        if let userDisplayName {
            mentionString.addAttribute(.MatrixUserDisplayName, value: userDisplayName, range: NSRange(location: 0, length: mentionString.length))
        }
        
        // Replace the range with the formatted mention text
        attributedString.replaceCharacters(in: range, with: mentionString)
    }
    
//    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String, userDisplayName: String?) {
//        
//        print("---- Mention Debug Info ==>>")
//         print("URL: \(url)")
//         print("UserID: \(userID)")
//         print("UserDisplayName: \(userDisplayName ?? "nil")")
//         print("Range: \(range)")
//         print("Attributed String (before): \(attributedString)")
//        
//        let attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: range)
//        let font = attributes[.font] as? UIFont ?? .preferredFont(forTextStyle: .body)
//        let blockquote = attributes[.MatrixBlockquote]
//        let foregroundColor = attributes[.foregroundColor] as? UIColor ?? .compound.textPrimary
//        
//        // Instead of creating a pill attachment, just apply attributes to the existing text
//        var linkAttributes: [NSAttributedString.Key: Any] = [
//            .link: url,
//            .MatrixUserID: userID,
//            .font: font,
//            .foregroundColor: foregroundColor,
//            .underlineStyle: NSUnderlineStyle.single.rawValue
//        ]
//        
//        if let userDisplayName {
//            linkAttributes[.MatrixUserDisplayName] = userDisplayName
//        }
//        
//        if let blockquote {
//            linkAttributes[.MatrixBlockquote] = blockquote
//        }
//        
//        // Apply these attributes to the existing text
//        attributedString.setAttributes(linkAttributes, range: range)
//    }
    
    
//    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String, userDisplayName: String?) {
//        let attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: range)
//        let font = attributes[.font] as? UIFont ?? .preferredFont(forTextStyle: .body)
//        let blockquote = attributes[.MatrixBlockquote]
//        let foregroundColor = attributes[.foregroundColor] as? UIColor ?? .compound.textPrimary
//        
//        let attachmentData = PillTextAttachmentData(type: .user(userID: userID), font: font)
//        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
//            attributedString.addAttribute(.MatrixUserID, value: userID, range: range)
//            
//            if let userDisplayName {
//                attributedString.addAttribute(.MatrixUserDisplayName, value: userDisplayName, range: range)
//            }
//            
//            return
//        }
//        
//        var attachmentAttributes: [NSAttributedString.Key: Any] = [.link: url, .MatrixUserID: userID, .font: font, .foregroundColor: foregroundColor]
//        if let blockquote {
//            // mentions can be in blockquotes, so if the replaced string was in one, we keep the attribute
//            attachmentAttributes[.MatrixBlockquote] = blockquote
//        }
//        let attachmentString = NSMutableAttributedString(attachment: attachment)
//        attachmentString.addAttributes(attachmentAttributes, range: NSRange(location: 0, length: attachmentString.length))
//        attributedString.replaceCharacters(in: range, with: attachmentString)
//    }
//    
//    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange) {
//        let attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: range)
//        let font = attributes[.font] as? UIFont ?? .preferredFont(forTextStyle: .body)
//        let blockquote = attributes[.MatrixBlockquote]
//        let foregroundColor = attributes[.foregroundColor] as? UIColor ?? .compound.textPrimary
//        
//        let attachmentData = PillTextAttachmentData(type: .allUsers, font: font)
//        guard let attachment = PillTextAttachment(attachmentData: attachmentData) else {
//            return
//        }
//        
//        var attachmentAttributes: [NSAttributedString.Key: Any] = [.font: font, .MatrixAllUsersMention: true, .foregroundColor: foregroundColor]
//        if let blockquote {
//            // mentions can be in blockquotes, so if the replaced string was in one, we keep the attribute
//            attachmentAttributes[.MatrixBlockquote] = blockquote
//        }
//        let attachmentString = NSMutableAttributedString(attachment: attachment)
//        attachmentString.addAttributes(attachmentAttributes, range: NSRange(location: 0, length: attachmentString.length))
//        attributedString.replaceCharacters(in: range, with: attachmentString)
//    }
    
    
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange) {
        let attributes = attributedString.attributes(at: 0, longestEffectiveRange: nil, in: range)
        let font = attributes[.font] as? UIFont ?? .preferredFont(forTextStyle: .body)
        let blockquote = attributes[.MatrixBlockquote]
        
        // Create the mention string "@everyone"
        let displayText = "@everyone"
        let mentionString = NSMutableAttributedString(string: displayText)

        // Apply the desired mention styling
        var mentionAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.systemBlue,  // 👈 Blue color here
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .MatrixAllUsersMention: true
        ]

        if let blockquote {
            mentionAttributes[.MatrixBlockquote] = blockquote
        }

        mentionString.addAttributes(mentionAttributes, range: NSRange(location: 0, length: mentionString.length))
        attributedString.replaceCharacters(in: range, with: mentionString)
    }
    
}
