//
//  ProductListView.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//
import SwiftUI

struct ProductListView: View {
    let productGroupUid: String
    let productGroupName: String
    @StateObject var viewModel = FlowProductViewModel()
    @EnvironmentObject var cartManager: CartManager // ✅ Inject CartManager
    
    var filteredProducts: [FlowProduct] {
        viewModel.products
            .filter { $0.productGroupUid == productGroupUid && $0.availableForWeb }
            .sorted { $0.recommendedRetailPrice < $1.recommendedRetailPrice }
    }

    var body: some View {
        List(filteredProducts) { product in
            NavigationLink(destination: ProductDetailView2(productUid: product.productUid)) {
                HStack {
                    if let imageUrlString = product.coverImage?.mainUrl,
                       let url = URL(string: imageUrlString) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable()
                                     .aspectRatio(contentMode: .fit)
                                     .frame(width: 100, height: 100)
                                     .cornerRadius(4)
                            } else {
                                Color.white.frame(width: 100, height: 100)
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.headline)
                        Text("Pris fra: \(product.recommendedRetailPrice / 100, specifier: "%.2f") kr")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(productGroupName)
        .onAppear {
            print("Fetching products for ProductGroupUid: \(productGroupUid)")  // ✅ Debugging

            viewModel.fetchProducts()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {  // ✅ Debug Delay to check API response
                print("Filtered Products Count: \(filteredProducts.count)")
                for product in filteredProducts {
                    print("✅ Product: \(product.name) - GroupUid: \(product.productGroupUid)")
                }
            }
        }
    }
}
