//
//  CartManager.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//

import SwiftUI

class CartManager: ObservableObject {
    @Published var items: [CartItem] = []  // ✅ Ensure it's @Published

    func addToCart(product: FlowProductDetail, quantity: Int) {
        if let index = items.firstIndex(where: { $0.product.productUid == product.productUid }) {
            items[index].quantity += quantity
        } else {
            let cartItem = CartItem(product: product, quantity: quantity)
            items.append(cartItem)
        }
    }

    func removeFromCart(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    // ✅ Clear Entire Cart (🔥 NEW FUNCTION)
        func clearCart() {
            items.removeAll()
        }

    func updateQuantity(for cartItem: CartItem, quantity: Int) {
        if let index = items.firstIndex(where: { $0.product.productUid == cartItem.product.productUid }) {
            items[index].quantity = quantity
        }
    }

    // ✅ Ensure it's a computed property (not a function)
        var totalItems: Int {
            items.reduce(0) { $0 + $1.quantity }
        }
    
    func totalPrice() -> Double {
        return items.reduce(0) { $0 + (Double($1.product.recommendedRetailPrice) / 100 * Double($1.quantity)) }
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: FlowProductDetail
    var quantity: Int
}
