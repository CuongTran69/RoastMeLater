//
//  ContentView.swift
//  RoastMeLater
//
//  Created by Cường Trần on 22/8/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
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
                    Text("History")
                }
                .tag(1)
            
            FavoritesView(onNavigateToRoastGenerator: {
                selectedTab = 0
            })
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.orange)
    }
}

#Preview {
    ContentView()
}

