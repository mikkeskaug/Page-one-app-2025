//
//  ProductGroupListView.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//

import SwiftUI

struct ProductGroupListView: View {
    let category: Category
    @StateObject var viewModel = ProductGroupViewModel()

    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.productGroups) { productGroup in
                    NavigationLink(destination: ProductListView(productGroupUid: productGroup.productGroupUid, productGroupName: productGroup.name)) {
                        ProductGroupCardView(productGroup: productGroup)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .navigationTitle(category.name)
        .onAppear {
            if let categoryId = category.id {
                viewModel.fetchProductGroups(for: categoryId)
            }
        }
    }
}

