//
//  StoreView2.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//


import SwiftUI

//
//  StoreView2.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//
import SwiftUI

struct StoreView2: View {
    @StateObject var categoryViewModel = CategoryViewModel()
    @State private var refreshTrigger = UUID() // Used to force a view update
    @EnvironmentObject var cartManager: CartManager // ✅ Inject CartManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(categoryViewModel.categories) { category in
                        ProductGroupRowView(category: category) // ✅ Displays horizontally scrolling boxes
                    }
                }
                .padding()
            }
            .id(refreshTrigger) // ✅ Changing this triggers a full reload
            .navigationTitle("Butikk")
            .navigationBarItems(
                leading: Button(action: {
                    refreshTrigger = UUID()
                    categoryViewModel.fetchCategories()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            )
            .onAppear {
                categoryViewModel.fetchCategories()
            }
        }
    }
}

// MARK: - Horizontally Scrolling Product Groups
struct ProductGroupRowView: View {
    let category: Category
    @StateObject var viewModel = ProductGroupViewModel()

    init(category: Category) {
        self.category = category
        _viewModel = StateObject(wrappedValue: ProductGroupViewModel())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.name) // ✅ Keep category name only here
                .font(.title2)
                .bold()
                .padding(.leading, 16)
                .padding(.bottom, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.productGroups) { productGroup in
                        NavigationLink(destination: ProductListView(productGroupUid: productGroup.productGroupUid, productGroupName: productGroup.name)) {
                            ProductGroupCardView(productGroup: productGroup)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 260)
        }
        .onAppear {
            if let categoryId = category.id {
                viewModel.fetchProductGroups(for: categoryId)
            }
        }
    }
}

struct ProductGroupCardView: View {
    let productGroup: ProductGroup

    var body: some View {
        VStack {
            if let url = URL(string: productGroup.imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fit)
                             .frame(height: 180)  // 🔥 Increased image size
                             .cornerRadius(12)
                    } else {
                        Color.white.frame(height: 180)
                    }
                }
            }
            Text(productGroup.name)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 12)
        }
        .frame(width: 250, height: 250)  // 🔥 Increased box size
        .background(Color.white)
        .cornerRadius(18)  // 🔥 More rounded corners for a softer look
        .shadow(radius: 5)  // ✅ Stronger shadow for a modern feel
        .padding(.vertical, 10)  // ✅ Prevents shadow from being cut off
        .background(Color.clear)
    }
}
