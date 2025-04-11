//
//  PaymentService.swift
//  Testing Dintero API
//
//  Created by Service on 10/02/2025.
//

import Foundation

class PaymentService {
    private let sessionURL = "https://api.dintero.com/v1/accounts/T11112502/sessions"
    private let token: String

    init(token: String) {
        self.token = token
    }

    func createPaymentSession(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: sessionURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session: [String: Any] = [
            "order": [
                "amount": 10000,
                "currency": "NOK",
                "reference": "order-12345",
                "items": [
                    [
                        "id": "item-1",
                        "line_id": "1",
                        "description": "Test Item",
                        "amount": 10000,
                        "quantity": 1
                    ]
                ]
            ],
            "merchant": [
                "reference": "merchant-12345"
            ],
            "urls": [
                "return_url": "https://yourwebsite.com/return",
                "callback_url": "https://yourwebsite.com/callback",
                "terms_url": "https://yourwebsite.com/terms"
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: session)
        } catch {
            completion(.failure(error))
            return
        }

        // Log Request Details
        print("📤 Request URL: \(request.url?.absoluteString ?? "No URL")")
        print("📤 Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("📤 Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "No Body")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ No HTTP Response")
                completion(.failure(NSError(domain: "No HTTP Response", code: -1, userInfo: nil)))
                return
            }

            print("📡 Response Code: \(httpResponse.statusCode)")

            guard let data = data else {
                print("❌ No data received")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }

            print("📜 Raw Response: \(String(data: data, encoding: .utf8) ?? "No Response Data")")

            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let checkoutURL = jsonObject["checkout_url"] as? String {
                        print("✅ Checkout URL: \(checkoutURL)")
                        completion(.success(checkoutURL))
                    } else if let errorObject = jsonObject["error"] as? [String: Any] {
                        let errorMessage = errorObject["message"] as? String ?? "Unknown error"
                        print("❌ Error Response: \(errorMessage)")
                        completion(.failure(NSError(domain: errorMessage, code: -1, userInfo: nil)))
                    } else {
                        print("❌ Unexpected response format")
                        completion(.failure(NSError(domain: "Unexpected response format", code: -1, userInfo: nil)))
                    }
                } else {
                    print("❌ Invalid JSON structure")
                    completion(.failure(NSError(domain: "Invalid JSON structure", code: -1, userInfo: nil)))
                }
            } catch {
                print("❌ JSON Parsing Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }.resume()
    }
}
