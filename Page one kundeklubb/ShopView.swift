//
//  ShopView.swift
//  Page one kundeklubb
//
//  Created by Service on 14/02/2025.
//

import SwiftUI

// MARK: - Constants

let tenantUid = "a91d948d-51ff-4aa4-85f3-c9bd4cfa83f6"
let storeUid = "22cd65b2-c85b-4f3c-bda7-6845b72a8c69"  // Store UID for product details.
let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwNTQ5MjExNDYsImlzcyI6ImFwaS5mbG93cmV0YWlsLmNvbSIsInN1YiI6ImZyaTphcHBpbnRlZ3Jhc2pvbiIsInRpZCI6M30.STIuOVfiMHywaRpJVJYs0TVZKezBzLlvZR8k4P2zynE"

// The target product group UID we want to show.
let targetProductGroupUid = "85ccc764-e0c8-496e-a0cd-f8ce6e97c493"

// MARK: - Models

struct FlowProduct: Identifiable, Decodable {
    // Use productUid as the unique identifier.
    var id: String { productUid }
    let productUid: String
    let name: String
    let recommendedRetailPrice: Double
    let coverImage: FlowProductCoverImage?
    let availableForWeb: Bool
    let productGroupUid: String // Field used for filtering.
}

struct FlowProductCoverImage: Decodable {
    let mainUrl: String
    let thumbnailUrl: String?
}

// Wrap the response so that we decode the top-level "items" array.
struct FlowProductResponse: Decodable {
    let items: [FlowProduct]
}

// Product detail model now includes nested storeProductDetails.
struct FlowProductDetail: Identifiable, Decodable {
    var id: String { productUid }
    let productUid: String
    let name: String
    let recommendedRetailPrice: Double
    let coverImage: FlowProductCoverImage?
    let description: String?
    let shortDescription: String?
    let sku: String?
    let storeProductDetails: StoreProductDetails?
}

struct StoreProductDetails: Decodable {
    let quantityStock: Int
}

// MARK: - ViewModel for List

class FlowProductViewModel: ObservableObject {
    @Published var products: [FlowProduct] = []

    func fetchProducts() {
        products.removeAll() // Clear previous data before new fetch
        fetchPage(pageNumber: 1, pageSize: 1000) // Start fetching from page 1
    }

    private func fetchPage(pageNumber: Int, pageSize: Int) {
        let urlString = "https://api.flowretail.com/v2/tenants/\(tenantUid)/products?pageNumber=\(pageNumber)&pageSize=\(pageSize)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Error fetching Flow products: \(error)")
                return
            }
            guard let data = data else {
                print("❌ No data returned")
                return
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(FlowProductResponse.self, from: data)

                DispatchQueue.main.async {
                    self.products.append(contentsOf: response.items) // Append new data

                    print("✅ Successfully fetched \(response.items.count) products from page \(pageNumber)")

                    // If we received the max pageSize, fetch the next page (more products exist)
                    if response.items.count == pageSize {
                        self.fetchPage(pageNumber: pageNumber + 1, pageSize: pageSize)
                    } else {
                        print("✅ Finished fetching all pages, total products: \(self.products.count)")
                    }
                }
            } catch {
                print("❌ Error decoding Flow products: \(error)")
            }
        }.resume()
    }
}

// MARK: - ViewModel for Detail

class FlowProductDetailViewModel: ObservableObject {
    @Published var productDetail: FlowProductDetail?
    
    func fetchProductDetail(for productUid: String) {
        let urlString = "https://api.flowretail.com/v2/tenants/\(tenantUid)/stores/\(storeUid)/products/\(productUid)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for product detail")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error fetching product detail: \(error)")
                return
            }
            guard let data = data else {
                print("No data in product detail response")
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let detail = try decoder.decode(FlowProductDetail.self, from: data)
                DispatchQueue.main.async {
                    self.productDetail = detail
                }
            } catch {
                print("Error decoding product detail: \(error)")
            }
        }.resume()
    }
}

// MARK: - Views

struct ShopView: View {
    @StateObject var viewModel = FlowProductViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.products) { product in
                NavigationLink(destination: FlowProductDetailView(productUid: product.productUid)) {
                    HStack {
                        if let imageUrlString = product.coverImage?.mainUrl,
                           let url = URL(string: imageUrlString) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                         .aspectRatio(contentMode: .fit)
                                         .frame(width: 50, height: 50)
                                         .cornerRadius(4)
                                } else if phase.error != nil {
                                    Color.red.frame(width: 50, height: 50)
                                } else {
                                    ProgressView().frame(width: 50, height: 50)
                                }
                            }
                        }
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                            Text("Pris fra: \((product.recommendedRetailPrice / 100), specifier: "%.2f")")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Flow Store")
            .onAppear {
                viewModel.fetchProducts()
            }
        }
    }
}

struct FlowProductDetailView: View {
    let productUid: String
    @StateObject var viewModel = FlowProductDetailViewModel()
    @State private var quantity: Int = 1
    
    var body: some View {
        Group {
            if let detail = viewModel.productDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Cover image
                        if let imageUrlString = detail.coverImage?.mainUrl,
                           let url = URL(string: imageUrlString) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                         .aspectRatio(contentMode: .fit)
                                } else if phase.error != nil {
                                    Color.red
                                } else {
                                    ProgressView()
                                }
                            }
                        }
                        
                        Text(detail.name)
                            .font(.title)
                            .bold()
                        
                        Text("Pris fra: \((detail.recommendedRetailPrice / 100), specifier: "%.2f")")
                            .font(.title2)
                        
                        // Short description above the buy button.
                        if let shortDescription = detail.shortDescription {
                            Text(shortDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quantity picker.
                        HStack {
                            Text("Antall:")
                            Stepper(value: $quantity, in: 1...100) {
                                Text("\(quantity)")
                            }
                        }
                        .padding(.vertical)
                        
                        // Buy button.
                        Button(action: {
                            print("Kjøper \(detail.name), quantity: \(quantity)")
                        }) {
                            Text("Kjøp")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                        
                        // Stock and SKU info below the buy button.
                        if let storeDetails = detail.storeProductDetails {
                            // Divide quantityStock by 100 to remove extra zeroes.
                            let stock = Double(storeDetails.quantityStock) / 100.0
                            Text("Lagerbeholdning: \(stock, specifier: "%.0f")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let sku = detail.sku {
                            Text("SKU: \(sku)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Full description below stock/SKU info.
                        if let description = detail.description {
                            Text(description)
                                .font(.body)
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

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
