//
//  ItemViewModel.swift
//  Page one kundeklubb
//
//  Created by Service on 05/02/2025.
//

import FirebaseFirestore
import SwiftUI

struct Item: Identifiable, Hashable {
    var id: String
    var name: String  // Only storing name

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

class ItemViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    func fetchItems() {
        let db = Firestore.firestore()
        db.collection("items").addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Error fetching items: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                self.items = snapshot?.documents.flatMap { doc in
                    let data = doc.data()
                    
                    var fetchedItems: [Item] = []
                    
                    // ✅ Check if "name" exists (single item per document)
                    if let singleItem = data["name"] as? String {
                        fetchedItems.append(Item(id: doc.documentID, name: singleItem))
                    }
                    
                    // ✅ Check if "items" exists as an array (multiple items in one document)
                    if let itemArray = data["items"] as? [String] {
                        let arrayItems = itemArray.map { Item(id: UUID().uuidString, name: $0) }
                        fetchedItems.append(contentsOf: arrayItems)
                    }
                    
                    return fetchedItems
                } ?? []
                
                print("✅ List updated in real-time: \(self.items)")
            }
        }
    }
}


