//
//  RoastMeLaterApp.swift
//  RoastMeLater
//
//  Created by Cường Trần on 22/8/25.
//

import SwiftUI
import UserNotifications

@main
struct RoastMeApp: App {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var lifecycleManager = AppLifecycleManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showSplash = true

    init() {
        // Setup notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView()
                    .onAppear {
                        // Hide splash after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(notificationManager)
                    .environmentObject(lifecycleManager)
                    .environmentObject(localizationManager)
                    .onAppear {
                        // Check and request notification permission if needed
                        notificationManager.requestNotificationPermission()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .navigateToRoastGenerator)) { _ in
                        // Handle navigation from notification tap
                        // This would be handled in ContentView
                    }
            }
        }
    }
}

