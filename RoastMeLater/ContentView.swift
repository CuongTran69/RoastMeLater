//
//  ContentView.swift
//  RoastMeLater
//
//  Created by Cường Trần on 22/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 0: Roast Generator
            RoastGeneratorView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text(localizationManager.tabRoast)
                }
                .tag(0)

            // Tab 1: Library (merged History + Favorites)
            LibraryView(onNavigateToRoastGenerator: {
                selectedTab = 0
            })
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text(localizationManager.tabLibrary)
                }
                .tag(1)

            // Tab 2: Settings
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(localizationManager.tabSettings)
                }
                .tag(2)
        }
        .accentColor(Constants.UI.Colors.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager.shared)
}

