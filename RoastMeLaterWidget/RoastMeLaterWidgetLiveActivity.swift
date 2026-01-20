//
//  RoastMeLaterWidgetLiveActivity.swift
//  RoastMeLaterWidget
//
//  Created by Cường Trần on 16/1/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RoastMeLaterWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RoastMeLaterWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoastMeLaterWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RoastMeLaterWidgetAttributes {
    fileprivate static var preview: RoastMeLaterWidgetAttributes {
        RoastMeLaterWidgetAttributes(name: "World")
    }
}

extension RoastMeLaterWidgetAttributes.ContentState {
    fileprivate static var smiley: RoastMeLaterWidgetAttributes.ContentState {
        RoastMeLaterWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RoastMeLaterWidgetAttributes.ContentState {
         RoastMeLaterWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RoastMeLaterWidgetAttributes.preview) {
   RoastMeLaterWidgetLiveActivity()
} contentStates: {
    RoastMeLaterWidgetAttributes.ContentState.smiley
    RoastMeLaterWidgetAttributes.ContentState.starEyes
}
