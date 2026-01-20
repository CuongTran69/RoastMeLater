//
//  RoastMeLaterWidgetBundle.swift
//  RoastMeLaterWidget
//
//  Created by Cường Trần on 16/1/26.
//

import WidgetKit
import SwiftUI

@main
struct RoastMeLaterWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Main roast widget with daily roast display
        RoastWidget()

        // Default template widget (can be removed if not needed)
        RoastMeLaterWidget()

        // Control widget for quick actions
        RoastMeLaterWidgetControl()

        // Live Activity widget
        RoastMeLaterWidgetLiveActivity()
    }
}
