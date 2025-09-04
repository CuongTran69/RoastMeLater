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

    init() {
        // Setup notification categories
        NotificationScheduler.shared.setupNotificationCategories()

        // Request notification permissions on app launch
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .environmentObject(lifecycleManager)
                .onAppear {
                    // Schedule initial notifications
                    notificationManager.scheduleHourlyNotifications()
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToRoastGenerator)) { _ in
                    // Handle navigation from notification tap
                    // This would be handled in ContentView
                }
        }
    }
}

