//
//  DinteroPaymentService.swift
//  Testing Dintero API
//
//  Created by Service on 10/02/2025.
//

import Foundation

class DinteroPaymentService {
    private let tokenURL = "https://api.dintero.com/v1/accounts/T11112502/auth/token"
    private let sessionURL = "https://checkout.dintero.com/v1/sessions"
    private let clientId = "1022f484-197c-4437-9817-7f900ae96593"
    private let clientSecret = "f0c6dc27-403e-4eb8-8334-7687a71876a4"

    func fetchAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: tokenURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let credentials = "\(clientId):\(clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8)?.base64EncodedString() else { return }
        request.setValue("Basic \(credentialsData)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "grant_type": "client_credentials",
            "audience": "https://api.dintero.com/v1/accounts/T11112502"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["access_token"] as? String {
                    completion(.success(token))
                } else {
                    print("❌ Invalid response for token request: \(String(data: data, encoding: .utf8) ?? "No Data")")
                    completion(.failure(NSError(domain: "Invalid token response", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func createPaymentSession(order: [String: Any], token: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: sessionURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: order, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let checkoutURL = json["url"] as? String {
                    completion(.success(checkoutURL))
                } else {
                    print("❌ Invalid response for payment session: \(String(data: data, encoding: .utf8) ?? "No Data")")
                    completion(.failure(NSError(domain: "Invalid payment session response", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
