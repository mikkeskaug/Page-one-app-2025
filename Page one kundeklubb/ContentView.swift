//
//  ContentView.swift
//  Page one kundeklubb
//
//  Created by Service on 30/01/2025.
//

import SwiftUI


struct ContentView: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        TabView{
            StoreView2()
                .tabItem{
                    Label("Butikk", systemImage: "house")
                }
            ContactView()
                .tabItem{
                    Label("Kontakt", systemImage: "phone")
                }
            ServiceStatusView()
                .tabItem{
                    Label("Status", systemImage: "gear.circle")
                }
            CartView()
                .tabItem{
                    Label("Handlekurv", systemImage: "cart")
                }
                .badge(cartManager.totalItems) // ✅ Adds dynamic badge for cart count
            KundeKlubbView()
                .tabItem{
                    Label("Profil", systemImage: "person.crop.circle")
                }
        }
    }
}
#Preview {
    ContentView()
}
