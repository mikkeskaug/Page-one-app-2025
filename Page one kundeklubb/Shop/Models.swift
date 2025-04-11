//
//  Models.swift
//  Page one kundeklubb
//
//  Created by Service on 18/02/2025.
//

import Foundation
import FirebaseFirestore


// MARK: - Category Model
struct Category: Identifiable, Decodable {
    @DocumentID var id: String?
    let name: String
}

// MARK: - Product Group Model
struct ProductGroup: Identifiable, Decodable {
    @DocumentID var id: String?
    let name: String
    let imageUrl: String
    let productGroupUid: String
}
