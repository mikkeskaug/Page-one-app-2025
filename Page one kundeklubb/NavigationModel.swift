//
//  NavigationModel.swift
//  Page one kundeklubb
//
//  Created by Service on 19/02/2025.
//
import SwiftUI

class NavigationModel: ObservableObject {
    @Published var currentView: String = "cart"

    func goToCart() {
        DispatchQueue.main.async {
            self.currentView = "cart"
        }
    }
}
