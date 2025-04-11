//
//  DinteroAuthService.swift
//  Testing Dintero API
//
//  Created by Service on 10/02/2025.
//

import Foundation

class DinteroAuthService {
    private let authURL = "https://api.dintero.com/v1/accounts/T11112502/auth/token"
    private let clientId = "1022f484-197c-4437-9817-7f900ae96593"
    private let clientSecret = "f0c6dc27-403e-4eb8-8334-7687a71876a4"

    func getToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: authURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let credentials = "\(clientId):\(clientSecret)"
        guard let base64Credentials = credentials.data(using: .utf8)?.base64EncodedString() else {
            completion(.failure(NSError(domain: "Invalid Credentials", code: -1, userInfo: nil)))
            return
        }
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        let body = [
            "grant_type": "client_credentials",
            "audience": "https://api.dintero.com/v1/accounts/T11112502"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -1, userInfo: nil)))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let accessToken = json?["access_token"] as? String {
                    completion(.success(accessToken))
                } else {
                    let errorMessage = json?["error_description"] as? String ?? "Invalid response"
                    completion(.failure(NSError(domain: errorMessage, code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
