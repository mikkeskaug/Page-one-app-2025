import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CheckoutView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var address = ""
    @State private var postcode = ""
    @State private var postPlace = ""
    @State private var shippingMethod: String = "pickup"
    @State private var paymentURL: URL?
    @State private var showWebView = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false  // ✅ NEW: Show confirmation screen
    @State private var orderId: String = ""
    
    private let paymentService = DinteroPaymentService()
    
    var totalAmount: Double {
        let subtotal = cartManager.items.reduce(0) { $0 + (Double($1.product.recommendedRetailPrice) / 100 * Double($1.quantity)) }
        let shippingCost = (shippingMethod == "shipping" && subtotal < 1500) ? 199.0 : 0.0
        return subtotal + shippingCost
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // ✅ Title
                    Text("Kasse")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 10)
                    
                    // ✅ Customer Info
                    Text("Kundeinformasjon")
                        .font(.headline)
                    
                    VStack {
                        TextField("Navn", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Telefonnummer", text: $phoneNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                        TextField("E-post", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                        TextField("Adresse", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Postnummer", text: $postcode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        TextField("Poststed", text: $postPlace)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // ✅ Delivery Method
                    Text("Leveringsmetode")
                        .font(.headline)
                    
                    Picker("Levering", selection: $shippingMethod) {
                        Text("Hent i butikk (Gratis)").tag("pickup")
                        Text("Hjemlevering (\(totalAmount >= 1500 ? "Gratis" : "199 kr"))").tag("shipping")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
            }
            
            // ✅ Summary & Checkout Section (Perfectly Aligned)
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    Text("Total:")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text("\(totalAmount, specifier: "%.2f") kr")
                        .font(.title2)
                }
                .padding()
                
                // ✅ "Proceed to Payment" Button
                Button(action: startPayment) {
                    Text("Gå til betaling")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                if let errorMessage = errorMessage {
                    Text("Feil: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            prefillCustomerData()
        }
        .sheet(isPresented: $showWebView) {
            if let paymentURL = paymentURL {
                WebView(url: paymentURL) { isSuccess in
                    showWebView = false
                    if isSuccess {
                        completeOrder()  // ✅ Handle success properly
                    } else {
                        errorMessage = "Betaling mislyktes ❌"
                    }
                }
            } else {
                Text("Betalingsside kunne ikke lastes")
            }
        }
        .fullScreenCover(isPresented: $showConfirmation) {
            OrderConfirmationView(
                orderId: orderId,
                name: name,
                totalAmount: totalAmount  // ✅ Now passes the final total
            )
            
        }
    }
    
    private func prefillCustomerData() {
        name = userManager.name
        phoneNumber = userManager.phoneNumber
        email = userManager.email
        address = userManager.address
        postcode = userManager.postcode
        postPlace = userManager.postPlace
    }
    
    private func startPayment() {
        guard !name.isEmpty, !phoneNumber.isEmpty, !email.isEmpty, !postcode.isEmpty, !postPlace.isEmpty else {
            errorMessage = "Vennligst fyll ut alle feltene"
            return
        }
        
        errorMessage = nil
        let totalAmountInt = Int(totalAmount * 100)
        
        let payload: [String: Any] = [
            "url": [
                "return_url": "https://example.com/accept?status=success",
                "callback_url": "https://example.com/callback?method=GET",
                "merchant_terms_url": "https://example.com/terms.html"
            ],
            "customer": [
                "customer_id": "customer123",
                "email": email,
                "phone_number": phoneNumber
            ],
            "order": [
                "amount": totalAmountInt,
                "currency": "NOK",
                "vat_amount": 0,
                "merchant_reference": UUID().uuidString,
                "items": cartManager.items.map { item in
                    [
                        "amount": Int(Double(item.product.recommendedRetailPrice) * Double(item.quantity)),
                        "quantity": item.quantity,
                        "line_id": UUID().uuidString,
                        "description": item.product.name,
                        "vat": 25,
                        "id": item.product.productUid
                    ]
                }
            ],
            "configuration": [
                "active_payment_types": [
                    "enabled": true,
                    "bambora.applepay": ["enabled": true],
                    "bambora.creditcard": ["enabled": true]
                ]
            ]
        ]
        
        paymentService.fetchAccessToken { result in
            switch result {
            case .success(let token):
                paymentService.createPaymentSession(order: payload, token: token) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let checkoutURL):
                            if let url = URL(string: checkoutURL) {
                                self.paymentURL = url
                                self.showWebView = true
                            } else {
                                self.errorMessage = "Ugyldig betalings-URL"
                            }
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func completeOrder() {
   

        let orderId = UUID().uuidString  // Generate a unique order ID

            sendOrderToFlowRetail(
                orderId: orderId,
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                address: address,
                postCode: postcode,
                postPlace: postPlace,
                totalAmount: totalAmount, cartItems: cartManager.items
            )

        DispatchQueue.main.async {
          
            showConfirmation = true  // ✅ Shows order confirmation
            
            let orderSummary: [String: Any] = [
                    "orderId": orderId,
                    "amount": totalAmount * 100,  // Convert to øre
                    "currency": "NOK",
                    "customer_email": email,
                    "customer_name": name,
                    "items": cartManager.items.map { item in
                        [
                            "description": item.product.name,
                            "amount": Int(Double(item.product.recommendedRetailPrice) * Double(item.quantity)), // ✅ Ensure price is correct
                            "quantity": item.quantity
                        ]
                    }
                ]

                // ✅ Send notification email to store
                notifyStore(orderSummary: orderSummary)
            
        }
    }
    
    func notifyStore(orderSummary: [String: Any]) {
        guard let url = URL(string: "https://api.sendgrid.com/v3/mail/send") else {
            print("❌ Invalid SendGrid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer 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", forHTTPHeaderField: "Authorization") // ✅ Ensure Bearer Token format

        let emailPayload: [String: Any] = [
            "personalizations": [["to": [["email": "mikkeskaug@icloud.com"]], "subject": "New Order Notification"]],
            "from": ["email": "butikk@pageone.no"],
            "content": [["type": "text/plain", "value": "New Order Received: \(orderSummary)"]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: emailPayload, options: [])
        } catch {
            print("❌ Failed to serialize email payload: \(error.localizedDescription)")
            return
        }

        print("📧 Sending Order Notification Email...")
        print("📩 Email Payload: \(emailPayload)")  // ✅ Debug the request payload

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Failed to send email: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ SendGrid Response Status Code: \(httpResponse.statusCode)")

                if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                    print("📨 SendGrid Response: \(responseBody)")
                }

                if httpResponse.statusCode == 202 {
                    print("✅ Email successfully sent to store!")
                } else {
                    print("⚠️ Email request may have failed. Check SendGrid dashboard.")
                }
            } else {
                print("❌ No valid HTTP response received from SendGrid.")
            }
        }.resume()
    }



    func sendOrderToFlowRetail(
        orderId: String,
        name: String,
        email: String,
        phoneNumber: String,
        address: String,
        postCode: String,
        postPlace: String,
        totalAmount: Double,
        cartItems: [CartItem]
    ) {
        let tenantUid = "a91d948d-51ff-4aa4-85f3-c9bd4cfa83f6"
        let storeUid = "22cd65b2-c85b-4f3c-bda7-6845b72a8c69"
        let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwNTQ5MjExNDYsImlzcyI6ImFwaS5mbG93cmV0YWlsLmNvbSIsInN1YiI6ImZyaTphcHBpbnRlZ3Jhc2pvbiIsInRpZCI6M30.STIuOVfiMHywaRpJVJYs0TVZKezBzLlvZR8k4P2zynE"

        /// ✅ **Step 1: Check if UserManager has a saved flowUID**
        if !userManager.flowUID.isEmpty {
            print("✅ Using existing FlowRetail customer UID: \(userManager.flowUID)")
            createOrderInFlowRetail(
                customerUid: userManager.flowUID,
                orderId: orderId,
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                address: address,
                postCode: postCode,
                postPlace: postPlace,
                totalAmount: totalAmount,
                cartItems: cartItems
            )
        } else {
            /// ✅ **Step 2: Create a new customer if flowUID is missing**
            print("⚠️ No FlowRetail customer UID found, creating new customer...")

            createFlowRetailCustomer(
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                address: address,
                postCode: postCode,
                postPlace: postPlace
            ) { customerUid in
                guard let customerUid = customerUid else {
                    print("❌ Failed to create customer, cannot proceed with order creation.")
                    return
                }

                print("✅ Created new FlowRetail customer UID: \(customerUid)")

                /// ✅ **Step 3: Save the new customer UID in Firestore and UserManager**
                self.updateUserFlowUID(customerUid: customerUid)

                /// ✅ **Step 4: Create the order using the newly created customer UID**
                self.createOrderInFlowRetail(
                    customerUid: customerUid,
                    orderId: orderId,
                    name: name,
                    email: email,
                    phoneNumber: phoneNumber,
                    address: address,
                    postCode: postCode,
                    postPlace: postPlace,
                    totalAmount: totalAmount,
                    cartItems: cartItems
                )
            }
        }
    }
    
    func addItemsToFlowRetailOrder(orderUid: String, cartItems: [CartItem], shippingMethod: String, totalAmount: Double) {
        let tenantUid = "a91d948d-51ff-4aa4-85f3-c9bd4cfa83f6"
        let storeUid = "22cd65b2-c85b-4f3c-bda7-6845b72a8c69"
        let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwNTQ5MjExNDYsImlzcyI6ImFwaS5mbG93cmV0YWlsLmNvbSIsInN1YiI6ImZyaTphcHBpbnRlZ3Jhc2pvbiIsInRpZCI6M30.STIuOVfiMHywaRpJVJYs0TVZKezBzLlvZR8k4P2zynE"

        var itemsToSend: [[String: Any]] = cartItems.map { item in
            return [
                "productUid": item.product.productUid,
                "quantityOrdered": Int(item.quantity) * 100, // ✅ Fix potential quantity issue
                "unitPrice": item.product.recommendedRetailPrice
            ]
        }

        // ✅ Add frakt (199kr) if order is below 1500kr
        if shippingMethod == "shipping" {
            let shippingPrice: Double = totalAmount < 1500 ? 19900 : 0 // ✅ Multiply by 100
            let shippingItem: [String: Any] = [
                "productUid": "b14d9d30-049d-465a-8902-1615db6eb886", // ✅ Frakt UID
                "quantityOrdered": 100, // ✅ Always 1
                "unitPrice": shippingPrice
            ]
            itemsToSend.append(shippingItem)
        }

        for item in itemsToSend {
            do {
                let postData = try JSONSerialization.data(withJSONObject: item, options: .prettyPrinted)

                var request = URLRequest(url: URL(string: "https://api.flowretail.com/v2/tenants/\(tenantUid)/stores/\(storeUid)/orders/\(orderUid)/items")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = postData

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("❌ Error adding item to order: \(error.localizedDescription)")
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse {
                        print("✅ FlowRetail Add Item Response Status Code: \(httpResponse.statusCode)")

                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("✅ FlowRetail Add Item Response: \(responseString)")

                            // ✅ Change Order State to PARKED after adding all items
                            updateFlowRetailOrderStatus(orderUid: orderUid)
                        }
                    }
                }.resume()
            } catch {
                print("❌ JSON Serialization Error: \(error)")
            }
        }
    }
    
    // ✅ Function to Send Item to FlowRetail
    private func sendItemToFlowRetail(orderUid: String, parameters: [String: Any]) {
        let tenantUid = "a91d948d-51ff-4aa4-85f3-c9bd4cfa83f6"
        let storeUid = "22cd65b2-c85b-4f3c-bda7-6845b72a8c69"
        let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwNTQ5MjExNDYsImlzcyI6ImFwaS5mbG93cmV0YWlsLmNvbSIsInN1YiI6ImZyaTphcHBpbnRlZ3Jhc2pvbiIsInRpZCI6M30.STIuOVfiMHywaRpJVJYs0TVZKezBzLlvZR8k4P2zynE"

        do {
            let postData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

            var request = URLRequest(url: URL(string: "https://api.flowretail.com/v2/tenants/\(tenantUid)/stores/\(storeUid)/orders/\(orderUid)/items")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = postData

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Error adding item to order: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ FlowRetail Add Item Response Status Code: \(httpResponse.statusCode)")

                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("✅ FlowRetail Add Item Response: \(responseString)")

                        // 🔥 STEP 2: Change Order State to PARKED (only after last item is added)
                        updateFlowRetailOrderStatus(orderUid: orderUid)
                    }
                }
            }.resume()
        } catch {
            print("❌ JSON Serialization Error: \(error)")
        }
    }
    
    func updateFlowRetailOrderStatus(orderUid: String) {
        let tenantUid = "a91d948d-51ff-4aa4-85f3-c9bd4cfa83f6"
        let storeUid = "22cd65b2-c85b-4f3c-bda7-6845b72a8c69"
        let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwNTQ5MjExNDYsImlzcyI6ImFwaS5mbG93cmV0YWlsLmNvbSIsInN1YiI6ImZyaTphcHBpbnRlZ3Jhc2pvbiIsInRpZCI6M30.STIuOVfiMHywaRpJVJYs0TVZKezBzLlvZR8k4P2zynE"

        let urlString = "https://api.flowretail.com/v2/tenants/\(tenantUid)/stores/\(storeUid)/orders/\(orderUid)/status"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for updating order status")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let parameters: [String: Any] = [
            "status": "PARKED"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("❌ Failed to encode parameters: \(error)")
            return
        }

        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error updating order status: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Order State Updated to PARKED: Status Code \(httpResponse.statusCode)")
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("✅ FlowRetail Order Update Response: \(responseString)")
            }
        }.resume()
    }
    
    func createFlowRetailCustomer(name: String, email: String, phoneNumber: String, address: String, postCode: String, postPlace: String, completion: @escaping (String?) -> Void) {
        let fullAddress = "\(address), \(postPlace), \(postCode), NO"

        // ✅ Ensure first and last name exist
        let nameParts = name.split(separator: " ")
        let firstName = nameParts.first.map(String.init) ?? "Unknown"
        let lastName = nameParts.dropFirst().joined(separator: " ") // Get everything after the first name

        let fixedLastName = lastName.isEmpty ? "Unknown" : lastName  // ✅ Prevent empty last name

        let customerPayload: [String: Any] = [
            "firstname": firstName,
            "lastname": fixedLastName, // ✅ Ensures last name exists
            "email": email,
            "mobile": phoneNumber,
            "address": fullAddress,
            "customerType": "PERSON"  // ✅ Required field
        ]

        print("📦 FlowRetail Customer Payload:", customerPayload)

        let url = URL(string: "https://api.flowretail.com/v2/tenants/\(tenantUid)/customers")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: customerPayload, options: [])
        } catch {
            print("❌ JSON Encoding Error:", error.localizedDescription)
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error Sending Request:", error.localizedDescription)
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ FlowRetail Customer Response Status Code:", httpResponse.statusCode)

                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📨 FlowRetail Customer Response:", responseString)
                }

                if httpResponse.statusCode == 201 {
                    do {
                        if let data = data,
                           let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let customerUid = json["customerUid"] as? String {
                            
                            print("✅ Successfully Created FlowRetail Customer: \(customerUid)")
                            
                            // ✅ Save to Firestore & Update UserManager
                            saveFlowRetailCustomerUidToFirestore(email: email, customerUid: customerUid)
                            
                            DispatchQueue.main.async {
                                userManager.flowUID = customerUid  // ✅ Update UserManager
                            }

                            completion(customerUid)
                            return
                        }
                    } catch {
                        print("❌ JSON Parsing Error:", error.localizedDescription)
                    }
                } else {
                    print("❌ Customer Creation Failed. Status Code: \(httpResponse.statusCode)")
                }
            }

            completion(nil)
        }

        task.resume()
    }
    
    func createOrderInFlowRetail(
        customerUid: String,
        orderId: String,
        name: String,
        email: String,
        phoneNumber: String,
        address: String,
        postCode: String,
        postPlace: String,
        totalAmount: Double,
        cartItems: [CartItem]
    ) {
        let tenantUid = "a91d948d-51ff-4aa4-85f3-c9bd4cfa83f6"
        let storeUid = "22cd65b2-c85b-4f3c-bda7-6845b72a8c69"
        let bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwNTQ5MjExNDYsImlzcyI6ImFwaS5mbG93cmV0YWlsLmNvbSIsInN1YiI6ImZyaTphcHBpbnRlZ3Jhc2pvbiIsInRpZCI6M30.STIuOVfiMHywaRpJVJYs0TVZKezBzLlvZR8k4P2zynE"

        let orderPayload: [String: Any] = [
            "customerAddress": [
                "firstname": name,
                "lastname": "",
                "email": email,
                "mobile": phoneNumber,
                "address": address,
                "postalCode": postCode,
                "city": postPlace,
                "countryCode": "NO"
            ],
            "customerUid": customerUid,  // ✅ Ensure customer exists
            "externalOrderNumber": orderId,
            "note": "Online order via app",
            "type": "ORDER",
            "systemOrigin": "APP"
        ]

        // ✅ DEBUG: Print JSON payload before sending
        if let jsonData = try? JSONSerialization.data(withJSONObject: orderPayload, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("🚀 Sending Order to FlowRetail: \(jsonString)")
        } else {
            print("❌ Failed to encode JSON")
            return
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: orderPayload, options: []) else {
            print("❌ Failed to encode JSON for order creation")
            return
        }

        let url = URL(string: "https://api.flowretail.com/v2/tenants/\(tenantUid)/stores/\(storeUid)/orders")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ FlowRetail Order Creation Error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ FlowRetail Order Response Status Code: \(httpResponse.statusCode)")

                // ✅ Print response body for debugging
                if let data = data,
                   let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print("✅ FlowRetail Order Response: \(jsonResponse)")
                }

                // ✅ Check if order was created successfully
                if let data = data,
                   let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let orderUid = jsonResponse["orderUid"] as? String {
                    print("✅ Created Order UID: \(orderUid)")

                    // ✅ Add items to the order first
                    addItemsToFlowRetailOrder(orderUid: orderUid, cartItems: cartItems, shippingMethod: shippingMethod, totalAmount: totalAmount)
                    // ✅ Update Order Status to PARKED (Directly without waiting for addItems)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        updateFlowRetailOrderStatus(orderUid: orderUid)
                    }
                }
            }
        }.resume()
    }
    
    func updateUserFlowUID(customerUid: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()

        let userRef = db.collection("users").document(user.email ?? user.uid)
        userRef.updateData(["flowUID": customerUid]) { error in
            if let error = error {
                print("❌ Failed to save FlowRetail customer UID to Firestore: \(error.localizedDescription)")
            } else {
                print("✅ FlowRetail customer UID saved to Firestore: \(customerUid)")
                DispatchQueue.main.async {
                    self.userManager.flowUID = customerUid // ✅ Update UserManager
                }
            }
        }
    }
    
    func saveFlowRetailCustomerUidToFirestore(email: String, customerUid: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(email)

        userRef.updateData(["flowUID": customerUid]) { error in
            if let error = error {
                print("❌ Firestore Error Saving FlowRetail UID: \(error.localizedDescription)")
            } else {
                print("✅ Successfully saved FlowRetail UID to Firestore: \(customerUid)")
            }
        }
    }
    
    struct OrderConfirmationView: View {
        let orderId: String
        let name: String
        let totalAmount: Double

        @EnvironmentObject var cartManager: CartManager  // ✅ Ensures cart is cleared
        @EnvironmentObject var navigationModel: NavigationModel // ✅ Controls navigation
        @Environment(\.dismiss) var dismiss  // ✅ Allows dismissing the view

        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.green)

                Text("Takk for bestillingen, \(name)!")
                    .font(.title)
                    .bold()

                Text("Ordrenummer: \(orderId)")
                    .font(.headline)
                    .foregroundColor(.gray)

                Text("Totalt betalt: \(totalAmount, specifier: "%.2f") kr")  // ✅ Ensures correct formatting
                    .font(.title2)
                    .bold()

                Text("Du vil motta en e-postbekreftelse snart.")
                    .multilineTextAlignment(.center)
                    .padding()

                // ✅ Back to Cart Button
                Button(action: {
                    cartManager.clearCart()  // ✅ Clears the cart
                    navigationModel.goToCart() // ✅ Redirects user to CartView
                    dismiss()  // ✅ Dismiss the confirmation view
                }) {
                    Text("Tilbake til Handlekurv")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .onAppear {
                print("✅ Order Confirmation Appeared - Order ID: \(orderId)")
            }
        }
    }
}
