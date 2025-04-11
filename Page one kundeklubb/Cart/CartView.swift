//
//  CartView.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartManager: CartManager  // ✅ Ensure cartManager is injected

    var totalPrice: Double {
        cartManager.items.reduce(0) { total, item in
            total + (Double(item.product.recommendedRetailPrice) / 100.0 * Double(item.quantity))
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if cartManager.items.isEmpty {
                    Text("Handlekurven er tom")
                        .font(.headline)
                        .padding()
                } else {
                    List {
                        ForEach(cartManager.items) { cartItem in
                            CartItemView(cartItem: cartItem)
                        }
                        .onDelete(perform: cartManager.removeFromCart)
                    }

                    // ✅ Summary & Checkout Section
                    VStack {
                        Divider()
                        
                        HStack {
                            Text("Total:")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Text("\(totalPrice, specifier: "%.2f") kr")
                                .font(.title2)
                        }
                        .padding()
                        
                        // ✅ "Proceed to Checkout" Button
                        NavigationLink(destination: CheckoutView()) {
                            Text("Gå til kassen")
                                .font(.headline)
                                .foregroundColor(Color.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }
                    .background(Color(UIColor.systemBackground)) // ✅ Follows Light/Dark Mode
                   
                    .padding()
                }
            }
            .navigationTitle("Handlekurv")
        }
    }
}

// MARK: - Cart Item View
struct CartItemView: View {
    @EnvironmentObject var cartManager: CartManager
    @State var cartItem: CartItem

    var body: some View {
        HStack {
            // ✅ Bigger Product Image
            if let imageUrlString = cartItem.product.coverImage?.mainUrl,
               let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fit)
                             .frame(width: 100, height: 100)  // 🔥 Increased size from 80x80 to 100x100
                             .cornerRadius(10)
                    } else {
                        Color.gray.frame(width: 100, height: 100)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(cartItem.product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                // ✅ Stock quantity
                if let stock = cartItem.product.storeProductDetails?.quantityStock {
                    Text("Lagerbeholdning: \(stock / 100)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // ✅ Quantity Picker
                HStack {
                    Text("Antall:")
                    Stepper(value: $cartItem.quantity, in: 1...100) {
                        Text("\(cartItem.quantity)")
                    }
                    .onChange(of: cartItem.quantity) { _, newValue in
                        cartManager.updateQuantity(for: cartItem, quantity: newValue)
                    }
                }
                .padding(.top, 4)
                
                // ✅ Price Calculation
                Text("Pris: \(Double(cartItem.product.recommendedRetailPrice) / 100.0 * Double(cartItem.quantity), specifier: "%.2f") kr")
                    .font(.subheadline)
                    .bold()
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }
}
