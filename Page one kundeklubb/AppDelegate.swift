//
//  AppDelegate.swift
//  Page one kundeklubb
//
//  Created by Service on 02/02/2025.
//

import Firebase
import FirebaseMessaging
import FirebaseAnalytics
import UserNotifications
import UIKit
import FirebaseInAppMessagingInternal

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        // Request Notification Permission
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        // Enable In-App Messaging
                InAppMessaging.inAppMessaging().messageDisplaySuppressed = false
        
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "No Token")")
        
        // You can send this token to Firestore to associate with a user
    }
}
