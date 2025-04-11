//
//  Page_one_kundeklubbApp.swift
//  Page one kundeklubb
//
//  Created by Service on 30/01/2025.
//

import SwiftUI
import Firebase

@main

struct Page_one_kundeklubbApp:  App {
    @StateObject var cartManager = CartManager() // ✅ Create a single instance
    @StateObject var userManager = UserManager()  // ✅ Create UserManager instance
    @StateObject var navigationModel = NavigationModel()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        
        }

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(cartManager) // ✅ Inject into environment
                    .environmentObject(userManager)  // ✅ Inject UserManager
                    .environmentObject(navigationModel)  // ✅ Inject NavigationModel
                            
            }
        }
    }
