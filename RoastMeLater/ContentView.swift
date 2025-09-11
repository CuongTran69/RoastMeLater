//
//  ContentView.swift
//  RoastMeLater
//
//  Created by Cường Trần on 22/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            RoastGeneratorView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Roast")
                }
                .tag(0)

            RoastHistoryView(onNavigateToRoastGenerator: {
                selectedTab = 0
            })
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text(localizationManager.tabHistory)
                }
                .tag(1)

            FavoritesView(onNavigateToRoastGenerator: {
                selectedTab = 0
            })
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text(localizationManager.tabFavorites)
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text(localizationManager.tabSettings)
                }
                .tag(3)
        }
        .environmentObject(localizationManager)
        .accentColor(.orange)
    }
}

#Preview {
    ContentView()
}

