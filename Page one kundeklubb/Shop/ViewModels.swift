//
//  ViewModels.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//
import SwiftUI
import FirebaseFirestore

// MARK: - Category ViewModel
class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []

    private let db = Firestore.firestore()

    func fetchCategories() {
        db.collection("categories").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                return
            }
            self.categories = snapshot?.documents.compactMap { document in
                try? document.data(as: Category.self)
            } ?? []
        }
    }
}

// MARK: - Product Group ViewModel
class ProductGroupViewModel: ObservableObject {
    @Published var productGroups: [ProductGroup] = []

    private let db = Firestore.firestore()

    func fetchProductGroups(for categoryId: String) {
        db.collection("categories").document(categoryId).collection("productGroups").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching product groups: \(error)")
                return
            }
            self.productGroups = snapshot?.documents.compactMap { document in
                try? document.data(as: ProductGroup.self)
            } ?? []
        }
    }
}
