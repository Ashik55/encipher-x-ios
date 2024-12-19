//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SeparatorRoomTimelineView: View {
    let timelineItem: SeparatorRoomTimelineItem
    
    var body: some View {
        Text(timelineItem.timestamp.formatted(date: .complete, time: .omitted))
            .font(.compound.bodySMSemibold)
            .foregroundColor(.compound.textPrimary)
            .padding(.horizontal, 36.0)
            .padding(.vertical, 8.0)
            .background(
                RoundedRectangle(cornerRadius: 12) // Apply corner radius
                    .fill(Color.compound._bgBubbleIncoming) // Set background color
            )
        
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
          
            .padding(.horizontal, 36.0)
            .padding(.vertical, 8.0)
    }
}

struct SeparatorRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let item = SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init(id: "Separator")),
                                             timestamp: .mock)
        SeparatorRoomTimelineView(timelineItem: item)
    }
}
