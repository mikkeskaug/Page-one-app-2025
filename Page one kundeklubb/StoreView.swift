//
//  StoreView.swift
//  YourApp
//
//  Created by Your Name on [Date].
//

import SwiftUI

// MARK: - Models

struct Product: Identifiable, Decodable {
    let id: Int
    let name: String
    let price: String
    let images: [ProductImage]?
}

struct ProductImage: Decodable {
    let src: String
}

// ProductDetail model using camelCase properties.
// The API’s snake_case keys will be converted using the decoder’s keyDecodingStrategy.
struct ProductDetail: Identifiable, Decodable {
    let id: Int
    let name: String
    let price: String
    let stockQuantity: Int?
    let description: String
    let shortDescription: String
    let images: [ProductImage]
    let attributes: [ProductAttribute]?
    let permalink: String
}

struct ProductAttribute: Decodable, Identifiable {
    let id: Int
    let name: String
    let options: [String]
}

// MARK: - Cart

class Cart: ObservableObject {
    @Published var items: [Product] = []
    
    func addToCart(_ product: Product) {
        items.append(product)
        print("Added product \(product.name) to cart. Total items: \(items.count)")
    }
}

// MARK: - Network Manager

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    // WooCommerce credentials.
    private let username = "ck_0b8e854656850f88a5c009e92fce4b86f455820f"
    private let password = "cs_746801f8ca71f57c5b6aa9a95cb7e042d13bed12"
    
    /// Fetches products from a given URL string.
    func fetchProducts(from urlString: String, completion: @escaping (Result<[Product], Error>) -> Void) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let products = try decoder.decode([Product].self, from: data)
                DispatchQueue.main.async {
                    completion(.success(products))
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}

// MARK: - ViewModels

/// View model to fetch products for a specific category.
class CategoryRowViewModel: ObservableObject {
    @Published var products: [Product] = []
    let categoryID: String
    
    init(categoryID: String) {
        self.categoryID = categoryID
        fetchProducts()
    }
    
    func fetchProducts() {
        let urlString = "https://pageone.no/wp-json/wc/v3/products?per_page=30&orderby=price&category=" + categoryID
        NetworkManager.shared.fetchProducts(from: urlString) { result in
            switch result {
            case .success(let products):
                self.products = products
            case .failure(let error):
                print("Error fetching products for category \(self.categoryID): \(error)")
            }
        }
    }
}

/// View model for fetching full product details.
class ProductDetailViewModel: ObservableObject {
    @Published var productDetail: ProductDetail?
    let productId: Int
    private let username = "ck_0b8e854656850f88a5c009e92fce4b86f455820f"
    private let password = "cs_746801f8ca71f57c5b6aa9a95cb7e042d13bed12"
    
    init(productId: Int) {
        self.productId = productId
        fetchProductDetail()
    }
    
    func fetchProductDetail() {
        let urlString = "https://pageone.no/wp-json/wc/v3/products/\(productId)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for product detail")
            return
        }
        var request = URLRequest(url: url)
        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error fetching product detail: \(error)")
                return
            }
            guard let data = data else {
                print("No data received in product detail request")
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let detail = try decoder.decode(ProductDetail.self, from: data)
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

/// A view showing a single product in a “card” style.
/// The product name and price labels have increased left padding.
struct ProductCardView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(product.name)
                .font(.title3)
                .bold()
                .foregroundColor(.black)
                .lineLimit(2)
                .padding(.top, 8)
                .padding(.leading, 16)
            Spacer()
            if let imageUrlString = product.images?.first?.src,
               let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                             .clipped()
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        ProgressView()
                    }
                }
                .frame(height: 240) // Reduced image height from 260 to 240
            } else {
                Color.gray.frame(height: 240)
            }
            Spacer()
            Text("Pris fra: \(product.price)")
                .font(.subheadline)
                .bold()
                .foregroundColor(.black)
                .padding(.bottom, 8)
                .padding(.leading, 16)
        }
        .frame(width: UIScreen.main.bounds.width * 0.85, height: 420)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(4)
    }
}

/// A horizontally scrolling row for one category using a TabView for snapping.
struct CategoryRowView: View {
    let categoryID: String
    let categoryTitle: String
    
    @StateObject private var viewModel: CategoryRowViewModel
    
    init(categoryID: String, categoryTitle: String) {
        self.categoryID = categoryID
        self.categoryTitle = categoryTitle
        _viewModel = StateObject(wrappedValue: CategoryRowViewModel(categoryID: categoryID))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(categoryTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal)
            // Use TabView for snapping behavior (no pagination dots).
            TabView {
                ForEach(viewModel.products) { product in
                    NavigationLink(destination: ProductDetailView(productId: product.id)) {
                        ProductCardView(product: product)
                            .scrollTargetLayout() // Mark as a snap target.
                    }
                    .id(product.id)
                }
            }
            .frame(height: 440)  // Slightly larger than the card height for a peek effect.
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .padding(.vertical)
    }
}

/// The main store view with categories, a refresh button, and a search button.
struct StoreView: View {
    
    // A state variable that forces a view refresh when changed.
    @State private var refreshTrigger = UUID()
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Use system background so that it adapts to light/dark mode.
        appearance.backgroundColor = UIColor.systemBackground
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // Updated categories order: Mac now comes after iPad.
    let categories: [(id: String, title: String)] = [
        ("305", "iPhone"),
        ("282", "iPad"),
        ("274", "Mac"),
        ("290", "Apple Watch"),
        ("277", "AirPods"),
        ("2642", "TV og Hjem"),
        ("1396", "AirTag"),
        ("2319", "Tilbehør")
    ]
    
    @StateObject var cart = Cart()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(categories, id: \.id) { category in
                        CategoryRowView(categoryID: category.id, categoryTitle: category.title)
                    }
                }
            }
            .id(refreshTrigger)  // Changing this ID forces a refresh.
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Butikk")
            .navigationBarItems(
                // Left: Refresh button.
                leading: Button(action: {
                    refreshTrigger = UUID()
                }) {
                    Image(systemName: "arrow.clockwise")
                },
                // Right: Search button.
                trailing: NavigationLink(destination: SearchView()) {
                    Image(systemName: "magnifyingglass")
                }
            )
        }
        .environmentObject(cart)
    }
}

/// Product Detail View that fetches additional information based on product ID.
/// This view shows the photo gallery, price, stock (if available), attributes,
/// and a "Kjøp" button that opens the product’s permalink in Safari.
struct ProductDetailView: View {
    let productId: Int
    @StateObject private var viewModel: ProductDetailViewModel
    
    init(productId: Int) {
        self.productId = productId
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(productId: productId))
    }
    
    var body: some View {
        Group {
            if let detail = viewModel.productDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Photo gallery using a TabView.
                        TabView {
                            ForEach(detail.images, id: \.src) { image in
                                AsyncImage(url: URL(string: image.src)) { phase in
                                    if let img = phase.image {
                                        img.resizable()
                                           .aspectRatio(contentMode: .fit)
                                    } else if phase.error != nil {
                                        Color.red
                                    } else {
                                        ProgressView()
                                    }
                                }
                            }
                        }
                        .frame(height: 300)
                        .tabViewStyle(PageTabViewStyle())
                        
                        Text("Pris fra: \(detail.price)")
                            .font(.title2)
                            .bold()
                        
                        if let stock = detail.stockQuantity {
                            Text("På lager: \(stock)")
                        }
                        
                        // "Kjøp" button opens the product permalink in Safari.
                        if let url = URL(string: detail.permalink) {
                            Link("Kjøp", destination: url)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                        
                        // Show attributes if available.
                        if let attributes = detail.attributes {
                            ForEach(attributes) { attribute in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(attribute.name)
                                        .font(.headline)
                                    Text(attribute.options.joined(separator: ", "))
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 4)
                            }
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
    }
}

/// The search view which lets users search products from WooCommerce.
struct SearchView: View {
    @State private var searchText = ""
    @State private var products: [Product] = []
    
    private let username = "ck_0b8e854656850f88a5c009e92fce4b86f455820f"
    private let password = "cs_746801f8ca71f57c5b6aa9a95cb7e042d13bed12"
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search products", text: $searchText, onCommit: {
                    searchProducts()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                
                Button(action: {
                    searchProducts()
                }) {
                    Image(systemName: "magnifyingglass")
                        .padding(.trailing)
                }
            }
            
            List(products) { product in
                NavigationLink(destination: ProductDetailView(productId: product.id)) {
                    HStack {
                        if let imageUrlString = product.images?.first?.src,
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
                            .frame(width: 50, height: 50)
                            .cornerRadius(4)
                        }
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.title3)
                                .bold()
                                .lineLimit(2)
                            Text("Pris fra: \(product.price)")
                                .font(.subheadline)
                                .bold()
                        }
                    }
                }
            }
        }
        .navigationTitle("Search")
    }
    
    func searchProducts() {
        guard !searchText.isEmpty else { return }
        let searchQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://pageone.no/wp-json/wc/v3/products?search=" + searchQuery + "&per_page=25&orderby=price"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Search error: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let results = try decoder.decode([Product].self, from: data)
                DispatchQueue.main.async {
                    self.products = results
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }
}



// MARK: - Preview

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView()
    }
}
