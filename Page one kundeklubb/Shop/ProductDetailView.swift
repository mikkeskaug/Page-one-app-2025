//
//  ProductDetailView.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//

import SwiftUI

struct ProductDetailView2: View {
    let productUid: String
    @StateObject var viewModel = FlowProductDetailViewModel()
    @EnvironmentObject var cartManager: CartManager
    @State private var quantity: Int = 1
    @State private var showToast = false // ✅ State for showing toast
    @Environment(\.presentationMode) var presentationMode // ✅ Helps with navigation

    var body: some View {
        Group {
            if let detail = viewModel.productDetail {
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let imageUrlString = detail.coverImage?.mainUrl,
                           let url = URL(string: imageUrlString) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                         .aspectRatio(contentMode: .fit)
                                } else {
                                    Color.gray
                                }
                            }
                        }
                        
                        Text(detail.name)
                            .font(.title)
                            .bold()
                        
                        Text("Pris fra: \(detail.recommendedRetailPrice / 100, specifier: "%.2f") kr")
                            .font(.title2)
                        
                        // Stock and SKU
                        if let stock = detail.storeProductDetails?.quantityStock {
                            Text("Lagerbeholdning: \(stock / 100)")
                                .font(.subheadline)
                        }
                        if let sku = detail.sku {
                            Text("SKU: \(sku)")
                                .font(.subheadline)
                        }

                        // Quantity Picker
                        HStack {
                            Text("Antall:")
                            Stepper(value: $quantity, in: 1...100) {
                                Text("\(quantity)")
                            }
                        }
                        .padding(.vertical)

                        // Toast Notification
                        if showToast {
                            Text("\(detail.name) lagt til i handlekurven! 🛒")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green.opacity(0.9))
                                .cornerRadius(10)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Add to Cart Button
                        Button(action: {
                            cartManager.addToCart(product: detail, quantity: quantity)
                            withAnimation {
                                showToast = true
                            }
                            
                            // ✅ Delay navigation update slightly
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showToast = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    presentationMode.wrappedValue.dismiss() // ✅ Now dismisses AFTER toast
                                }
                            }
                        }) {
                            Text("Legg til i handlekurv")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                    }
                    .padding()
                }
                .navigationTitle(detail.name)
            } else {
                ProgressView()
                    .navigationTitle("Loading...")
            }
        }
        .onAppear {
            viewModel.fetchProductDetail(for: productUid)
        }
    }
}
